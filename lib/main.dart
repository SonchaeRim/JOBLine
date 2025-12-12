import 'package:flutter/material.dart';
import 'routes/app_routes.dart';             // 라우팅 설정
import 'routes/route_names.dart';            // 라우트 이름 상수
import 'core/theme/app_colors.dart';        // 색상 테마
import 'core/theme/app_text_styles.dart';   // 텍스트 스타일
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/calendar/services/fcm_notification_service.dart' show FcmNotificationService, firebaseMessagingBackgroundHandler;

// Flutter 앱 실행 진입점
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ★ Firebase 준비
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ★ Firebase Auth 익명 인증 (개발용 - 실제 로그인 기능 구현 시 제거)
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      print('✅ Firebase Auth 익명 인증 완료: ${auth.currentUser?.uid}');
    } else {
      print('✅ Firebase Auth 이미 인증됨: ${auth.currentUser?.uid}');
    }
  } catch (e) {
    print('⚠️ Firebase Auth 익명 인증 실패: $e');
    print('⚠️ Firestore 보안 규칙을 확인하세요.');
  }

  // ★ intl 패키지 로케일 데이터 초기화 (한국어)
  await initializeDateFormatting('ko_KR', null);

  // ★ FCM 백그라운드 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ★ FCM 알림 서비스 초기화
  await FcmNotificationService().initialize();

  runApp(const MyApp());
}

// 앱 전체를 감싸는 루트 위젯
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Line',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        textTheme: AppTextStyles.textTheme,
      ),
      initialRoute: RouteNames.splash, // 시작 화면 (스플래시 화면)
      routes: AppRoutes.routes,          // 라우트 매핑
      onGenerateRoute: AppRoutes.onGenerateRoute, // 동적 라우트 처리
    );
  }
}