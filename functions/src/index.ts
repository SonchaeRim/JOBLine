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

      // 같은 scheduleId와 notificationTime 조합이 이미 있는지 확인 (중복 방지)
      const duplicateJobsSnapshot = await admin.firestore()
        .collection('notification_jobs')
        .where('scheduleId', '==', scheduleId)
        .where('notificationTime', '==', notificationTime)
        .where('status', '==', 'pending')
        .limit(1)
        .get();

      if (duplicateJobsSnapshot.size > 0) {
        console.log(`중복 알림 작업 발견 (스킵): scheduleId=${scheduleId}, time=${notificationDate}`);
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
    
    // 중복 방지: 'pending' 상태만 조회 (이미 'processing'인 것은 제외)
    const jobsSnapshot = await admin.firestore()
      .collection('notification_jobs')
      .where('status', '==', 'pending')
      .where('notificationTime', '<=', now)
      .where('notificationTime', '>', fiveMinutesAgo)
      .get();

    console.log(`처리할 알림 작업 수: ${jobsSnapshot.size}`);
    console.log(`현재 시간: ${new Date().toISOString()}`);

    const processedRequestIds = new Set<string>();

    const sendPromises = jobsSnapshot.docs.map(async (doc) => {
      const job = doc.data();
      const requestId = job.requestId || '';
      const notificationTime = job.notificationTime.toDate();
      const nowDate = new Date();
      const timeDiff = notificationTime.getTime() - nowDate.getTime();

      console.log(`알림 작업 확인: ID=${doc.id}, 예약 시간=${notificationTime.toISOString()}, 현재 시간=${nowDate.toISOString()}, 차이=${timeDiff}ms`);

      // 알림 시간이 지났는지 확인 (5분 이내면 전송)
      if (timeDiff > 0) {
        console.log(`아직 시간이 안 됨: ${timeDiff}ms 남음`);
        return null;
      }
      
      if (timeDiff < -300000) { // 5분 이상 지났으면 삭제
        console.log(`너무 오래 지남: ${-timeDiff}ms 전, 작업 삭제`);
        await doc.ref.delete();
        if (requestId) {
          processedRequestIds.add(requestId);
        }
        return null;
      }

      try {
        // 중복 처리 방지: 상태를 'processing'으로 변경 (트랜잭션 사용)
        // 트랜잭션 내에서 다시 한 번 상태를 확인하여 race condition 방지
        const updateResult = await admin.firestore().runTransaction(async (transaction) => {
          const jobDoc = await transaction.get(doc.ref);
          if (!jobDoc.exists) {
            return { success: false, reason: 'job_not_found' };
          }
          
          const currentJob = jobDoc.data();
          // 'pending' 상태가 아니면 이미 처리 중이거나 완료된 것
          if (currentJob.status !== 'pending') {
            return { success: false, reason: 'already_processed', status: currentJob.status };
          }
          
          // 상태를 'processing'으로 변경하여 중복 처리 방지
          transaction.update(doc.ref, { 
            status: 'processing',
            processingStartedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          return { success: true };
        });

        if (!updateResult.success) {
          if (updateResult.reason === 'already_processed') {
            console.log(`알림 작업 이미 처리됨: ID=${doc.id}, 상태=${updateResult.status}`);
          } else {
            console.log(`알림 작업 처리 불가: ID=${doc.id}, 이유=${updateResult.reason}`);
          }
          return null;
        }
        
        // 트랜잭션으로 상태를 'processing'으로 변경했으므로
        // 다른 인스턴스는 이 작업을 처리할 수 없음 (쿼리에서 'pending'만 조회)

        // 일정 정보 가져오기 (startDate 확인용)
        let notificationBody = `${job.title} 일정이 곧 시작됩니다.`;
        
        try {
          const scheduleDoc = await admin.firestore()
            .collection('schedules')
            .doc(job.scheduleId)
            .get();
          
          if (scheduleDoc.exists) {
            const scheduleData = scheduleDoc.data();
            const startDate = scheduleData?.startDate?.toDate();
            
            if (startDate) {
              // 알림 시간과 일정 시작 시간의 차이 계산
              const timeDiffMs = startDate.getTime() - notificationTime.getTime();
              const timeDiffHours = timeDiffMs / (1000 * 60 * 60);
              const timeDiffDays = timeDiffMs / (1000 * 60 * 60 * 24);
              
              // 시간 포맷팅 함수 (사용자 디바이스 타임존으로 변환)
              // TODO: 향후 사용자 프로필에서 타임존 정보를 가져와서 사용
              // 현재는 한국 시간대(Asia/Seoul)를 기본값으로 사용
              const formatTime = (date: Date): string => {
                // date는 UTC로 저장된 시간
                // 사용자 디바이스 타임존으로 변환하여 시간/분 추출
                // TODO: 사용자 타임존을 동적으로 가져오기 (예: userProfile.timezone)
                const userTimezone = 'Asia/Seoul'; // 기본값: 한국 시간대
                const formatter = new Intl.DateTimeFormat('en-US', {
                  timeZone: userTimezone,
                  hour: 'numeric',
                  minute: '2-digit',
                  hour12: true
                });
                
                const parts = formatter.formatToParts(date);
                let hours = 0;
                let minutes = 0;
                let isPM = false;
                
                for (const part of parts) {
                  if (part.type === 'hour') {
                    hours = parseInt(part.value, 10);
                  } else if (part.type === 'minute') {
                    minutes = parseInt(part.value, 10);
                  } else if (part.type === 'dayPeriod') {
                    isPM = part.value === 'PM';
                  }
                }
                
                // 오전/오후 결정
                const period = isPM ? '오후' : '오전';
                // 12시간 형식으로 변환
                const displayHours = hours === 0 ? 12 : (hours > 12 ? hours - 12 : hours);
                return `${period} ${displayHours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
              };
              
              // 알림 타입에 따라 메시지 변경
              if (timeDiffDays >= 0.9 && timeDiffDays <= 1.1) {
                // 하루 전 (약 24시간 전)
                notificationBody = `내일 ${formatTime(startDate)}에 ${job.title} 일정이 있습니다.`;
              } else if (timeDiffHours >= 0.9 && timeDiffHours <= 1.1) {
                // 한시간 전 (약 1시간 전)
                notificationBody = `한시간 후에 ${job.title} 일정이 있습니다.`;
              } else if (timeDiffMs >= 4 * 60 * 1000 && timeDiffMs <= 6 * 60 * 1000) {
                // 5분 전 (4~6분 전)
                notificationBody = `곧 ${job.title} 일정이 시작됩니다.`;
              }
            }
          }
        } catch (scheduleError) {
          console.error('일정 정보 가져오기 실패:', scheduleError);
          // 일정 정보를 가져오지 못해도 기본 메시지로 전송
        }
        
        const message = {
          notification: {
            title: '일정 알림',
            body: notificationBody,
          },
          data: {
            scheduleId: job.scheduleId || '',
            type: 'schedule_reminder',
            requestId: requestId,
          },
          token: job.fcmToken,
        };

        await admin.messaging().send(message);
        console.log('알림 전송 완료:', doc.id, notificationTime, '메시지:', notificationBody);

        // 알림 전송 성공 후 작업 문서 삭제
        await doc.ref.delete();
        console.log('작업 문서 삭제 완료:', doc.id);
        if (requestId) {
          processedRequestIds.add(requestId);
        }
        return null;
      } catch (error: any) {
        console.error('알림 전송 실패:', doc.id, error);
        
        // 작업 문서는 이미 삭제되었으므로 여기서는 로그만 남김
        // (트랜잭션에서 이미 삭제했으므로 중복 삭제 시도하지 않음)
        if (requestId) {
          processedRequestIds.add(requestId);
        }
        return null;
      }
    });

    await Promise.all(sendPromises);
    
    // 모든 작업이 완료된 notification_requests 삭제
    // 각 requestId에 대해 남은 notification_jobs가 없는지 확인
    if (processedRequestIds.size > 0) {
      console.log(`처리된 알림 요청 ${processedRequestIds.size}개 확인 시작`);
      const deletePromises = Array.from(processedRequestIds).map(async (requestId) => {
        try {
          // 해당 requestId의 남은 notification_jobs 확인
          const remainingJobs = await admin.firestore()
            .collection('notification_jobs')
            .where('requestId', '==', requestId)
            .get();
          
          if (remainingJobs.size === 0) {
            // 모든 작업이 완료되었으므로 notification_requests 삭제
            const requestRef = admin.firestore().collection('notification_requests').doc(requestId);
            const requestDoc = await requestRef.get();
            
            if (requestDoc.exists) {
              await requestRef.delete();
              console.log(`알림 요청 삭제 완료: ${requestId} (모든 작업 완료)`);
            }
          } else {
            console.log(`알림 요청 유지: ${requestId} (남은 작업 ${remainingJobs.size}개)`);
          }
        } catch (error: any) {
          console.error(`알림 요청 확인 실패: ${requestId}`, error);
        }
      });
      
      await Promise.all(deletePromises);
      console.log(`알림 요청 확인 완료`);
    }
    
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

