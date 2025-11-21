import 'package:flutter/material.dart';

// === 각 기능 모듈의 화면 import ===
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/common/screens/home_screen.dart';
import '../features/board/screens/board_tabs_screen.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/board/screens/post_list_screen.dart';

class AppRoutes {
  // 첫 화면: 로그인 화면으로 지정
  static const String initial = '/board';

  // 모든 라우트 등록
  static final Map<String, WidgetBuilder> routes = {
    //'/login': (context) => const LoginScreen(),
    //'/signup': (context) => const SignupScreen(),
    '/home': (context) => const HomeScreen(),
    '/board': (context) => const BoardTabsScreen(),
    //'/calendar': (context) => const CalendarScreen(),
    //'/chat': (context) => const ChatListScreen(),

    // ✅ 게시판 글 목록
    '/board/list': (context) {
      final args =
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return PostListScreen(
        boardId: args['boardId'] as String,
        title:   (args['title'] as String?) ?? '게시판',
      );
    },
  };
}