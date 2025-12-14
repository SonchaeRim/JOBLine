/// FCM 푸시 알림 서비스 - 일정 알림 예약, 취소 및 포그라운드/백그라운드 알림 처리
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/schedule.dart';

class FcmNotificationService {
  static final FcmNotificationService _instance = FcmNotificationService._internal();
  factory FcmNotificationService() => _instance;
  FcmNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance; // FCM 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore 인스턴스
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin(); // 로컬 알림 플러그인
  String? _fcmToken; // FCM 토큰

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

    _fcmToken = await _messaging.getToken();

    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
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
    // 알림 탭 시 해당 화면으로 이동
  }

  /// FCM 토큰을 Firestore에 저장
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      await _firestore.collection('users').doc(userId).update({
        'pushToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // 토큰 저장 실패는 무시
    }
  }

  /// 포그라운드 알림 처리 및 로컬 알림 표시
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
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
    }
  }

  /// 백그라운드 알림 탭 처리
  void _handleBackgroundMessageTap(RemoteMessage message) {
    // 알림 데이터에서 일정 ID 추출하여 해당 화면으로 이동
  }

  /// 일정 알림 예약 요청 생성
  Future<void> scheduleScheduleNotification(Schedule schedule) async {
    if (_fcmToken == null) {
      return;
    }

    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      if (currentUser == null) {
        try {
          await auth.signInAnonymously();
        } catch (authError) {
          throw Exception('Firebase Auth 인증 실패: $authError');
        }
      }

      await _cleanupDuplicateRequests(schedule.id);
      await _cleanupDuplicateJobs(schedule.id);
      await _firestore.runTransaction((transaction) async {
        final checkRequests = await _firestore
            .collection('notification_requests')
            .where('scheduleId', isEqualTo: schedule.id)
            .where('status', whereIn: ['pending', 'processing'])
            .limit(1)
            .get();

        for (var doc in checkRequests.docs) {
          transaction.delete(doc.reference);
        }

        final newRequestRef = _firestore.collection('notification_requests').doc();
        transaction.set(newRequestRef, {
          'scheduleId': schedule.id,
          'userId': schedule.ownerId,
          'fcmToken': _fcmToken,
          'title': schedule.title,
          'scheduledTime': schedule.startDate,
          'notificationTimes': [
            schedule.startDate.subtract(const Duration(days: 1)),
            schedule.startDate.subtract(const Duration(hours: 1)),
            schedule.startDate.subtract(const Duration(minutes: 5)),
          ],
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 일정 알림 취소 요청
  Future<void> cancelScheduleNotification(String scheduleId) async {
    try {
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
    } catch (e) {
      // 에러를 다시 throw하지 않고 로그만 남김 (앱이 크래시되지 않도록)
    }
  }

  /// FCM 토큰 조회
  String? getFcmToken() => _fcmToken;

  /// 일정 삭제 시 관련 알림 요청 및 작업 삭제
  Future<void> deleteScheduleNotifications(String scheduleId) async {
    try {
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
      }

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
      }
    } catch (e) {
      // 에러를 다시 throw하지 않음 (일정 삭제는 계속 진행되어야 함)
    }
  }

  /// 중복 알림 요청 정리
  Future<void> _cleanupDuplicateRequests(String scheduleId) async {
    try {
      final allRequests = await _firestore
          .collection('notification_requests')
          .where('scheduleId', isEqualTo: scheduleId)
          .get();

      if (allRequests.docs.isEmpty) {
        return;
      }

      final activeRequests = allRequests.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status == 'pending' || status == 'processing';
      }).toList();

      if (activeRequests.isEmpty) {
        return;
      }

      activeRequests.sort((a, b) {
        final aTime = a.data()['createdAt'] as Timestamp?;
        final bTime = b.data()['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      final batch = _firestore.batch();
      for (int i = 1; i < activeRequests.length; i++) {
        batch.delete(activeRequests[i].reference);
      }

      if (activeRequests.length > 1) {
        await batch.commit();
      }
    } catch (e) {
      // 중복 요청 정리 실패는 무시
    }
  }

  /// 중복 알림 작업 정리
  Future<void> _cleanupDuplicateJobs(String scheduleId) async {
    try {
      final allJobs = await _firestore
          .collection('notification_jobs')
          .where('scheduleId', isEqualTo: scheduleId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (allJobs.docs.isEmpty) {
        return;
      }

      final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> jobsByTime = {};
      
      for (var doc in allJobs.docs) {
        final notificationTime = doc.data()['notificationTime'] as Timestamp?;
        if (notificationTime == null) continue;
        
        final timeKey = notificationTime.millisecondsSinceEpoch.toString();
        jobsByTime.putIfAbsent(timeKey, () => []).add(doc);
      }

      final batch = _firestore.batch();

      for (var jobs in jobsByTime.values) {
        if (jobs.length <= 1) continue;

        jobs.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        for (int i = 1; i < jobs.length; i++) {
          batch.delete(jobs[i].reference);
        }
      }

      if (jobsByTime.values.any((jobs) => jobs.length > 1)) {
        await batch.commit();
      }
    } catch (e) {
      // 중복 작업 정리 실패는 무시
    }
  }

}

/// 백그라운드 메시지 핸들러 (최상위 함수)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM 메시지에 notification 필드가 있으면 FCM이 자동으로 알림을 표시합니다.
}





