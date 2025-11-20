import 'package:flutter/material.dart';
import 'package:jobline/features/auth/screens/profile_screen.dart';

// === 각 기능 모듈의 화면 import ===
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/common/screens/home_screen.dart';
import '../features/board/screens/board_tabs_screen.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';

class AppRoutes {
  // 첫 화면: 로그인 화면으로 지정
  static const String initial = '/profile';

  // 모든 라우트 등록
  static final Map<String, WidgetBuilder> routes = {
    //'/login': (context) => const LoginScreen(),
    //'/signup': (context) => const SignUpScreen(),
    //'/home': (context) => const HomeScreen(),
    '/profile': (context) => const ProfileScreen(),
    //'/board': (context) => const BoardTabsScreen(),
    //'/calendar': (context) => const CalendarScreen(),
    //'/chat': (context) => const ChatListScreen(),
  };
}