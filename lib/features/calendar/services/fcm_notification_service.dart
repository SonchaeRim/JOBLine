import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/schedule.dart';

/// FCM 푸시 알림 서비스
class FcmNotificationService {
  static final FcmNotificationService _instance = FcmNotificationService._internal();
  factory FcmNotificationService() => _instance;
  FcmNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  String? _fcmToken;

  /// FCM 초기화 및 토큰 관리
  Future<void> initialize() async {
    // 로컬 알림 초기화 (포그라운드 알림 표시용)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 알림 채널 생성
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // 알림 권한 요청 (Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ FCM 알림 권한 허용됨');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ FCM 알림 권한 임시 허용됨');
    } else {
      print('❌ FCM 알림 권한 거부됨');
    }

    // FCM 토큰 가져오기
    _fcmToken = await _messaging.getToken();
    print('📱 FCM 토큰: $_fcmToken');

    // 토큰 갱신 리스너
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('🔄 FCM 토큰 갱신됨: $newToken');
      _saveTokenToFirestore(newToken);
    });

    // 포그라운드 알림 핸들러
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 백그라운드 알림 핸들러 (앱이 종료된 상태에서 알림 탭)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // 앱이 종료된 상태에서 알림을 탭해서 열었는지 확인
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessageTap(initialMessage);
    }

    // 토큰을 Firestore에 저장
    if (_fcmToken != null) {
      await _saveTokenToFirestore(_fcmToken!);
    }
  }

  /// 로컬 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 로컬 알림 탭됨: ${response.payload}');
    // TODO: 알림 탭 시 해당 화면으로 이동
  }

  /// Firestore에 FCM 토큰 저장
  Future<void> _saveTokenToFirestore(String token) async {
    // TODO: 현재 사용자 ID를 가져와서 users/{userId} 문서에 pushToken 업데이트
    // 예시:
    // final userId = await getCurrentUserId();
    // await _firestore.collection('users').doc(userId).update({
    //   'pushToken': token,
    //   'updatedAt': FieldValue.serverTimestamp(),
    // });
    print('💾 FCM 토큰을 Firestore에 저장해야 합니다.');
  }

  /// 포그라운드 알림 처리
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📬 포그라운드 알림 수신:');
    print('   제목: ${message.notification?.title}');
    print('   본문: ${message.notification?.body}');
    print('   데이터: ${message.data}');

    // 포그라운드에서는 FCM이 자동으로 알림을 표시하지 않으므로 로컬 알림으로 표시
    if (message.notification != null) {
      final notification = message.notification!;
      final androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title ?? '일정 알림',
        notification.body ?? '',
        details,
        payload: message.data.toString(),
      );

      print('✅ 포그라운드 알림 표시 완료');
    }
  }

  /// 백그라운드 알림 탭 처리
  void _handleBackgroundMessageTap(RemoteMessage message) {
    print('🔔 백그라운드 알림 탭됨:');
    print('   제목: ${message.notification?.title}');
    print('   본문: ${message.notification?.body}');
    print('   데이터: ${message.data}');

    // 알림 데이터에서 일정 ID 추출하여 해당 화면으로 이동
    // 예시:
    // final scheduleId = message.data['scheduleId'];
    // if (scheduleId != null) {
    //   Navigator.pushNamed(context, RouteNames.scheduleDetail, arguments: scheduleId);
    // }
  }

  /// 일정 알림 예약 요청 (Firebase Functions 또는 서버에 요청)
  /// 실제 알림 스케줄링은 백엔드에서 처리해야 합니다.
  /// 같은 scheduleId의 기존 요청이 있으면 취소하고 새로 생성합니다.
  Future<void> scheduleScheduleNotification(Schedule schedule) async {
    if (_fcmToken == null) {
      print('⚠️ FCM 토큰이 없습니다. 알림을 예약할 수 없습니다.');
      return;
    }

    try {
      // Firebase Auth 현재 사용자 확인
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      if (currentUser == null) {
        print('⚠️ Firebase Auth 사용자가 없습니다. 익명 인증을 시도합니다...');
        try {
          await auth.signInAnonymously();
          print('✅ Firebase Auth 익명 인증 완료: ${auth.currentUser?.uid}');
        } catch (authError) {
          print('❌ Firebase Auth 익명 인증 실패: $authError');
          print('⚠️ Firebase Console → Authentication → Sign-in method → Anonymous 활성화 필요');
          throw Exception('Firebase Auth 인증 실패: $authError');
        }
      } else {
        print('✅ Firebase Auth 사용자 확인됨: ${currentUser.uid}');
      }

      // 1단계: 같은 scheduleId의 모든 중복 요청 정리
      await _cleanupDuplicateRequests(schedule.id);

      // 2단계: 같은 scheduleId의 모든 중복 작업 정리 (notification_jobs)
      await _cleanupDuplicateJobs(schedule.id);

      // 2단계: 새 요청 생성 (트랜잭션으로 원자적 처리)
      await _firestore.runTransaction((transaction) async {
        // 트랜잭션 내에서 다시 확인 (동시성 문제 방지)
        final checkRequests = await _firestore
            .collection('notification_requests')
            .where('scheduleId', isEqualTo: schedule.id)
            .where('status', whereIn: ['pending', 'processing'])
            .limit(1)
            .get();

        // 아직 pending/processing 상태인 요청이 있으면 삭제
        for (var doc in checkRequests.docs) {
          transaction.delete(doc.reference);
        }

        // 새로운 알림 예약 요청 생성
        final newRequestRef = _firestore.collection('notification_requests').doc();
        transaction.set(newRequestRef, {
          'scheduleId': schedule.id,
          'userId': schedule.ownerId,
          'fcmToken': _fcmToken,
          'title': schedule.title,
          'scheduledTime': schedule.startDate,
          'notificationTimes': [
            // 하루 전
            schedule.startDate.subtract(const Duration(days: 1)),
            // 1시간 전
            schedule.startDate.subtract(const Duration(hours: 1)),
            // 5분 전
            schedule.startDate.subtract(const Duration(minutes: 5)),
          ],
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        print('✅ 새 알림 예약 요청 생성: 일정 ID=${schedule.id}, 요청 ID=${newRequestRef.id}');
      });

      print('✅ 알림 예약 요청 저장 완료: 일정 ID=${schedule.id}');
      print('⚠️ 실제 알림은 Firebase Functions 또는 서버에서 스케줄링됩니다.');
    } catch (e) {
      print('❌ 알림 예약 요청 저장 실패: $e');
      print('⚠️ Firebase Console에서 다음을 확인하세요:');
      print('   1. Authentication → Sign-in method → Anonymous 활성화');
      print('   2. Firestore Database → Rules → notification_requests 규칙 확인');
      print('   3. 규칙 예시: match /notification_requests/{requestId} { allow read, write: if request.auth != null; }');
      rethrow; // 호출자에게 에러 전달
    }
  }

  /// 일정 알림 취소 요청
  Future<void> cancelScheduleNotification(String scheduleId) async {
    try {
      // 알림 예약 요청 삭제
      final requests = await _firestore
          .collection('notification_requests')
          .where('scheduleId', isEqualTo: scheduleId)
          .get();

      if (requests.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in requests.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // 관련 알림 작업도 삭제
      final jobs = await _firestore
          .collection('notification_jobs')
          .where('scheduleId', isEqualTo: scheduleId)
          .get();

      if (jobs.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in jobs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      print('✅ 알림 취소 요청 완료: 일정 ID=$scheduleId');
    } catch (e) {
      print('⚠️ 알림 취소 요청 실패: $e');
      print('⚠️ Firebase Console에서 notification_requests 컬렉션에 대한 보안 규칙을 확인하세요.');
      print('⚠️ 규칙 예시: match /notification_requests/{requestId} { allow read, write: if request.auth != null; }');
      // 에러를 다시 throw하지 않고 로그만 남김 (앱이 크래시되지 않도록)
    }
  }

  /// FCM 토큰 가져오기
  String? getFcmToken() => _fcmToken;

  /// 일정 삭제 시 관련된 모든 알림 요청과 작업 삭제
  Future<void> deleteScheduleNotifications(String scheduleId) async {
    try {
      print('🗑️ 일정 삭제로 인한 알림 정리 시작: 일정 ID=$scheduleId');

      // 1. notification_requests 삭제
      final requestsSnapshot = await _firestore
          .collection('notification_requests')
          .where('scheduleId', isEqualTo: scheduleId)
          .get();

      if (requestsSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in requestsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('✅ 알림 요청 ${requestsSnapshot.docs.length}개 삭제 완료');
      }

      // 2. notification_jobs 삭제
      final jobsSnapshot = await _firestore
          .collection('notification_jobs')
          .where('scheduleId', isEqualTo: scheduleId)
          .get();

      if (jobsSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in jobsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('✅ 알림 작업 ${jobsSnapshot.docs.length}개 삭제 완료');
      }

      print('✅ 일정 삭제로 인한 알림 정리 완료: 일정 ID=$scheduleId');
    } catch (e) {
      print('❌ 일정 삭제로 인한 알림 정리 실패: $e');
      // 에러를 다시 throw하지 않음 (일정 삭제는 계속 진행되어야 함)
    }
  }

  /// 같은 scheduleId의 중복 notification_requests 정리
  /// 가장 최근 요청만 남기고 나머지는 cancelled로 변경
  Future<void> _cleanupDuplicateRequests(String scheduleId) async {
    try {
      // 같은 scheduleId의 모든 요청 조회
      final allRequests = await _firestore
          .collection('notification_requests')
          .where('scheduleId', isEqualTo: scheduleId)
          .get();

      if (allRequests.docs.isEmpty) {
        return;
      }

      // 활성 상태인 요청들만 필터링 (pending, processing)
      final activeRequests = allRequests.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status == 'pending' || status == 'processing';
      }).toList();

      if (activeRequests.isEmpty) {
        print('✅ 중복 요청 없음: 일정 ID=$scheduleId');
        return;
      }

      // createdAt 기준으로 정렬 (가장 최근 것만 남김)
      activeRequests.sort((a, b) {
        final aTime = a.data()['createdAt'] as Timestamp?;
        final bTime = b.data()['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime); // 내림차순 (최신이 먼저)
      });

      // 가장 최근 요청을 제외한 나머지 모두 삭제
      final batch = _firestore.batch();
      int deletedCount = 0;

      for (int i = 1; i < activeRequests.length; i++) {
        batch.delete(activeRequests[i].reference);
        deletedCount++;
      }

      if (deletedCount > 0) {
        await batch.commit();
        print('🧹 중복 알림 요청 $deletedCount개 삭제 완료: 일정 ID=$scheduleId');
      }
    } catch (e) {
      print('⚠️ 중복 요청 정리 실패: $e');
    }
  }

  /// 같은 scheduleId의 중복 notification_jobs 정리
  /// 가장 최근 작업만 남기고 나머지는 cancelled로 변경
  Future<void> _cleanupDuplicateJobs(String scheduleId) async {
    try {
      // 같은 scheduleId의 모든 작업 조회
      final allJobs = await _firestore
          .collection('notification_jobs')
          .where('scheduleId', isEqualTo: scheduleId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (allJobs.docs.isEmpty) {
        return;
      }

      // notificationTime별로 그룹화하여 각 시간당 하나만 남김
      final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> jobsByTime = {};
      
      for (var doc in allJobs.docs) {
        final notificationTime = doc.data()['notificationTime'] as Timestamp?;
        if (notificationTime == null) continue;
        
        final timeKey = notificationTime.millisecondsSinceEpoch.toString();
        jobsByTime.putIfAbsent(timeKey, () => []).add(doc);
      }

      final batch = _firestore.batch();
      int cancelledCount = 0;

      // 각 시간별로 가장 최근 작업만 남기고 나머지 취소
      for (var jobs in jobsByTime.values) {
        if (jobs.length <= 1) continue;

        // createdAt 기준으로 정렬 (가장 최근 것만 남김)
        jobs.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // 내림차순 (최신이 먼저)
        });

        // 가장 최근 작업을 제외한 나머지 모두 삭제
        for (int i = 1; i < jobs.length; i++) {
          batch.delete(jobs[i].reference);
          cancelledCount++;
        }
      }

      if (cancelledCount > 0) {
        await batch.commit();
        print('🧹 중복 알림 작업 $cancelledCount개 삭제 완료: 일정 ID=$scheduleId');
      }
    } catch (e) {
      print('⚠️ 중복 작업 정리 실패: $e');
    }
  }

}

/// 백그라운드 메시지 핸들러 (최상위 함수)
/// 별도의 isolate에서 실행됩니다.
/// 
/// 주의: FCM 메시지에 `notification` 필드가 있으면 FCM이 자동으로 알림을 표시하므로
/// 여기서는 로컬 알림을 표시하지 않습니다. (중복 방지)
/// `data` 필드만 있는 경우에만 로컬 알림을 표시해야 합니다.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📬 백그라운드 알림 수신:');
  print('   제목: ${message.notification?.title}');
  print('   본문: ${message.notification?.body}');
  print('   데이터: ${message.data}');

  // FCM 메시지에 `notification` 필드가 있으면 FCM이 자동으로 알림을 표시합니다.
  // 따라서 여기서는 로컬 알림을 표시하지 않아 중복을 방지합니다.
  // 
  // 만약 `data` 필드만 있는 경우에만 로컬 알림을 표시해야 한다면:
  // if (message.notification == null && message.data.isNotEmpty) {
  //   // 로컬 알림 표시 로직
  // }
  
  print('✅ 백그라운드 알림 처리 완료 (FCM이 자동으로 알림 표시)');
}

