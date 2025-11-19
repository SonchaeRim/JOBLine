import 'package:flutter/material.dart';

// === 각 기능 모듈의 화면 import ===
import '../features/common/screens/home_screen.dart';
// D 담당 테스트용 (임시)
import '../features/calendar/screens/calendar_test_screen.dart';
// D 담당 기능 화면
import '../features/calendar/screens/calendar_screen.dart';
import '../features/calendar/screens/schedule_detail_screen.dart';
import '../features/challenge/screens/challenge_list_screen.dart';
import '../features/challenge/screens/challenge_detail_screen.dart';
import '../features/challenge/screens/proof_camera_screen.dart';
import '../features/challenge/screens/certification_history_screen.dart';
import '../features/calendar/services/calendar_service.dart';
import '../features/challenge/models/challenge.dart';
// import '../features/auth/screens/login_screen.dart';
// import '../features/auth/screens/signup_screen.dart';
// import '../features/board/screens/board_tabs_screen.dart';
// import '../features/chat/screens/chat_list_screen.dart';

class AppRoutes {
  // 첫 화면: 테스트 화면으로 임시 변경 (D 담당 테스트용)
  static const String initial = '/test'; // 테스트 후 '/home'으로 변경

  // 라우트 이름 상수
  static const String home = '/home';
  static const String test = '/test';
  static const String calendar = '/calendar';
  static const String scheduleDetail = '/schedule-detail';
  static const String challenge = '/challenge';
  static const String challengeDetail = '/challenge-detail';
  static const String proofCamera = '/proof-camera';
  static const String certificationHistory = '/certification-history';

  // 모든 라우트 등록
  static final Map<String, WidgetBuilder> routes = {
    home: (context) => const HomeScreen(),
    test: (context) => const CalendarTestScreen(), // D 담당 테스트용 (임시)
    calendar: (context) => const CalendarScreen(), // D 담당: 캘린더 화면
    challenge: (context) => const ChallengeListScreen(), // D 담당: 챌린지 화면
    
    // 파라미터가 필요한 화면들은 arguments로 전달
    scheduleDetail: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
      return ScheduleDetailScreen(
        userId: args['userId'] as String,
        calendarService: args['calendarService'] as CalendarService,
        schedule: args['schedule'] as dynamic,
        selectedDate: args['selectedDate'] as DateTime?,
      );
    },
    
    challengeDetail: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
      return ChallengeDetailScreen(
        challenge: args['challenge'] as Challenge,
        userId: args['userId'] as String,
      );
    },
    
    proofCamera: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
      return ProofCameraScreen(
        challengeId: args['challengeId'] as String,
        userId: args['userId'] as String,
      );
    },
    
    certificationHistory: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
      return CertificationHistoryScreen(
        userId: args['userId'] as String,
      );
    },
  };
}