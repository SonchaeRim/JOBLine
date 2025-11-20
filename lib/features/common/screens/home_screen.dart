import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';
import '../../board/screens/board_tabs_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../settings/screens/setting_screen.dart';

// HomeShell이 전체 탭 이동 로직을 관리
// HomeShell이 현재 어떤 탭이 선택됐는지 index 저장
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // 탭 index에 따라 보여줄 화면 5개
  // 0: 홈, 1: 게시판, 2: 캘린더, 3: 채팅, 4: 설정
  final List<Widget> _screens = const [
    HomeScreen(),
    BoardTabsScreen(),
    CalendarScreen(),
    ChatListScreen(),
    SettingScreen(),
  ];

  // BottomNavBar에서 탭 누르면 이 함수가 실행돼서 index가 변화되어 UI 갱신
  void _onTab(int i) {
    setState(() {
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    // AppScaffold는 화면 틀만 제공
    return AppScaffold(
      currentIndex: _index,
      onTabSelected: _onTab,
      // 여러 화면을 겹쳐두고 index에 해당하는 것만 보이게
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
    );
  }
}

// 홈 탭에서 보여줄 화면만 담당 (더 자세하게 짜면 됨)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('홈 탭 (레벨/챌린지 등 배치 예정)'),
    );
  }
}
