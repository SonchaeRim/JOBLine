import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

/**
 * 알림 예약 요청이 생성되면 Cloud Scheduler를 통해 알림을 스케줄링합니다.
 * 
 * 실제 구현은 Cloud Scheduler를 사용하여 주기적으로 실행되는 함수로 처리하는 것이 좋습니다.
 * 여기서는 간단한 예시로 Firestore 트리거를 사용합니다.
 */
export const onNotificationRequestCreated = functions.firestore
  .document('notification_requests/{requestId}')
  .onCreate(async (snap, context) => {
    const request = snap.data();
    const requestId = context.params.requestId;

    console.log('알림 예약 요청 생성됨:', requestId);
    console.log('일정 ID:', request.scheduleId);
    console.log('FCM 토큰:', request.fcmToken);

    if (request.status !== 'pending') {
      console.log('상태가 pending이 아니므로 스킵:', request.status);
      return null;
    }

    const notificationTimes: admin.firestore.Timestamp[] = request.notificationTimes || [];
    const fcmToken = request.fcmToken;
    const title = request.title || '일정';
    const scheduleId = request.scheduleId;

    if (!fcmToken) {
      console.error('FCM 토큰이 없습니다.');
      await snap.ref.update({ status: 'failed', error: 'FCM token missing' });
      return null;
    }

    // ★ 같은 scheduleId의 기존 notification_jobs 취소 (중복 방지)
    const existingJobsSnapshot = await admin.firestore()
      .collection('notification_jobs')
      .where('scheduleId', '==', scheduleId)
      .where('status', '==', 'pending')
      .get();

    if (existingJobsSnapshot.size > 0) {
      console.log(`기존 알림 작업 ${existingJobsSnapshot.size}개 발견. 삭제 처리합니다.`);
      const batch = admin.firestore().batch();
      existingJobsSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log(`기존 알림 작업 ${existingJobsSnapshot.size}개 삭제 완료`);
    }

    // 각 알림 시간에 대해 Firestore에 알림 작업 문서 생성
    // Cloud Scheduler가 주기적으로 실행하여 알림을 전송합니다.
    const notificationJobs: Promise<admin.firestore.WriteResult>[] = [];

    for (let i = 0; i < notificationTimes.length; i++) {
      const notificationTime = notificationTimes[i];
      const notificationDate = notificationTime.toDate();
      const now = new Date();

      // 이미 지난 시간이면 스킵
      if (notificationDate <= now) {
        console.log('이미 지난 알림 시간 스킵:', notificationDate);
        continue;
      }

      // 알림 작업 문서 생성
      const jobRef = admin.firestore().collection('notification_jobs').doc();
      const jobPromise = jobRef.set({
        requestId: requestId,
        scheduleId: scheduleId,
        fcmToken: fcmToken,
        title: title,
        notificationTime: notificationTime,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      notificationJobs.push(jobPromise);
      console.log(`알림 작업 생성: ${jobRef.id}, 시간: ${notificationDate}`);
    }

    await Promise.all(notificationJobs);

    // 요청 상태를 processing으로 변경
    await snap.ref.update({ 
      status: 'processing',
      jobCount: notificationJobs.length,
    });

    console.log(`알림 작업 ${notificationJobs.length}개 생성 완료`);
    return null;
  });

/**
 * 알림 취소 요청 처리
 */
export const onNotificationRequestUpdated = functions.firestore
  .document('notification_requests/{requestId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const requestId = context.params.requestId;

    // status가 pending에서 cancelled로 변경된 경우
    if (before.status === 'pending' && after.status === 'cancelled') {
      console.log('알림 취소 요청:', requestId);

      // 관련된 모든 알림 작업을 취소 상태로 변경
      const jobsSnapshot = await admin.firestore()
        .collection('notification_jobs')
        .where('requestId', '==', requestId)
        .where('status', '==', 'pending')
        .get();

      // 취소된 작업들도 삭제
      const batch = admin.firestore().batch();
      jobsSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`알림 작업 ${jobsSnapshot.size}개 삭제 완료`);
    }

    return null;
  });

/**
 * 주기적으로 실행되어 알림 시간이 된 작업을 처리하는 함수
 * Cloud Scheduler에서 1분마다 호출하도록 설정해야 합니다.
 */
export const processScheduledNotifications = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async (context) => {
    console.log('스케줄된 알림 처리 시작:', new Date().toISOString());

    const now = admin.firestore.Timestamp.now();

    // 알림 시간이 지난 작업들을 찾기 (5분 이내)
    const fiveMinutesAgo = admin.firestore.Timestamp.fromMillis(
      now.toMillis() - 5 * 60 * 1000
    );
    
    const jobsSnapshot = await admin.firestore()
      .collection('notification_jobs')
      .where('status', '==', 'pending')
      .where('notificationTime', '<=', now)
      .where('notificationTime', '>', fiveMinutesAgo)
      .get();

    console.log(`처리할 알림 작업 수: ${jobsSnapshot.size}`);
    console.log(`현재 시간: ${new Date().toISOString()}`);

    const sendPromises = jobsSnapshot.docs.map(async (doc) => {
      const job = doc.data();
      const notificationTime = job.notificationTime.toDate();
      const nowDate = new Date();
      const timeDiff = notificationTime.getTime() - nowDate.getTime();

      console.log(`알림 작업 확인: ID=${doc.id}, 예약 시간=${notificationTime.toISOString()}, 현재 시간=${nowDate.toISOString()}, 차이=${timeDiff}ms`);

      // 알림 시간이 지났는지 확인 (5분 이내면 전송)
      if (timeDiff > 0) {
        console.log(`아직 시간이 안 됨: ${timeDiff}ms 남음`);
        return;
      }
      
      if (timeDiff < -300000) { // 5분 이상 지났으면 삭제
        console.log(`너무 오래 지남: ${-timeDiff}ms 전, 작업 삭제`);
        await doc.ref.delete();
        return;
      }

      try {
        const message = {
          notification: {
            title: '일정 알림',
            body: `${job.title} 일정이 곧 시작됩니다.`,
          },
          data: {
            scheduleId: job.scheduleId || '',
            type: 'schedule_reminder',
            requestId: job.requestId || '',
          },
          token: job.fcmToken,
        };

        await admin.messaging().send(message);
        console.log('알림 전송 완료:', doc.id, notificationTime);

        // 알림 전송 완료 후 작업 문서 삭제
        await doc.ref.delete();
        console.log('작업 문서 삭제 완료:', doc.id);
      } catch (error: any) {
        console.error('알림 전송 실패:', doc.id, error);

        // 실패한 작업도 삭제 (재시도는 하지 않음)
        await doc.ref.delete();
        console.log('실패한 작업 문서 삭제 완료:', doc.id);
      }
    });

    await Promise.all(sendPromises);
    console.log('스케줄된 알림 처리 완료');
    return null;
  });

/**
 * 일정(schedule) 문서가 삭제되면 관련된 모든 알림 요청과 작업을 삭제합니다.
 */
export const onScheduleDeleted = functions.firestore
  .document('schedules/{scheduleId}')
  .onDelete(async (snap, context) => {
    const scheduleId = context.params.scheduleId;
    console.log('일정 삭제 감지:', scheduleId);

    try {
      // 1. notification_requests 삭제
      const requestsSnapshot = await admin.firestore()
        .collection('notification_requests')
        .where('scheduleId', '==', scheduleId)
        .get();

      if (requestsSnapshot.size > 0) {
        const batch = admin.firestore().batch();
        requestsSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });
        await batch.commit();
        console.log(`알림 요청 ${requestsSnapshot.size}개 삭제 완료`);
      }

      // 2. notification_jobs 삭제
      const jobsSnapshot = await admin.firestore()
        .collection('notification_jobs')
        .where('scheduleId', '==', scheduleId)
        .get();

      if (jobsSnapshot.size > 0) {
        const batch = admin.firestore().batch();
        jobsSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });
        await batch.commit();
        console.log(`알림 작업 ${jobsSnapshot.size}개 삭제 완료`);
      }

      console.log(`일정 삭제로 인한 알림 정리 완료: 일정 ID=${scheduleId}`);
    } catch (error: any) {
      console.error('일정 삭제로 인한 알림 정리 실패:', error);
    }

    return null;
  });

