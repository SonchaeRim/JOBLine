// lib/features/common/screens/home_screen.dart
// 플러터의 기본 UI 위젯들을 쓰기 위해 가져오는 패키지
import 'package:flutter/material.dart';

import '../../board/screens/board_tabs_screen.dart'; // 게시판 탭
import '../../calendar/screens/calendar_screen.dart'; // 캘린더 탭
import '../../chat/screens/chat_list_screen.dart'; // 채팅 탭
import '../../settings/screens/setting_screen.dart'; // 설정 탭

// 탭 이동에 따라 상태가 변하므로 StatefulWidget이 필요함.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState(); // 실제 상태를 관리
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 현재 어떤 탭이 눌린 상태인지 0~4 값으로 저장

  late final List<Widget> _tabs; // 5개의 탭에서 보여줄 화면을 저장하는 리스트

  // 탭 화면 초기화 (앱을 시작할 때 _tabs 리스트를 준비해놓음)
  @override
  void initState() {
    super.initState();
    // 0: 홈, 1: 게시판, 2: 캘린더, 3: 채팅, 4: 설정
    _tabs = const [
      _HomeTabScreen(),
      BoardTabsScreen(),
      CalendarScreen(),
      ChatListScreen(),
      SettingScreen(),
    ];
  }

  // 탭을 이동하면 _selectedIndex 값이 바뀜. 그에 따라 AppBar 제목을 바꿈.
  String get _appBarTitle {
    switch (_selectedIndex) {
      case 0:
        return '홈';
      case 1:
        return '게시판';
      case 2:
        return '캘린더';
      case 3:
        return '채팅';
      case 4:
        return '설정';
      default:
        return 'JOB LINE';
    }
  }

  // 탭을 클릭했을 때 index를 바꾸고 화면 전환됨.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // 탭에 따라 화면 제목 변경
      appBar: AppBar(
        title: Text(_appBarTitle),
      ),

      // 여러 화면을 겹쳐놓고 _selectedIndex에 해당하는 화면만 보여줌.
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),

      // 하단 탭바
      // 눌리면 _onItemTapped() 호출 → index 변경 → 화면 전환
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
          BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined), label: '게시판'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined), label: '캘린더'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), label: '설정'),
        ],
      ),
    );
  }
}

/// 홈 탭 더미 화면 (나중에 챌린지, 레벨, 피드 넣기)
class _HomeTabScreen extends StatelessWidget {
  const _HomeTabScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('홈 탭 (레벨/챌린지 등 배치 예정)'),
    );
  }
}
