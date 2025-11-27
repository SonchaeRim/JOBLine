import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../home/screens/home_screen.dart';
import '../../board/screens/board_tabs_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../settings/screens/setting_screen.dart';

/// 메인 화면 - 하단 네비게이션 바와 탭 전환을 관리하는 화면
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  // 탭 index에 따라 보여줄 화면 5개
  // 0: 홈, 1: 캘린더, 2: 게시판, 3: 채팅, 4: 설정
  late final List<Widget> _screens = [
    HomeScreen(onTabChanged: _onTab),
    const CalendarScreen(),
    const BoardTabsScreen(),
    const ChatListScreen(),
    const SettingScreen(),
  ];

  // BottomNavBar에서 탭 누르면 이 함수가 실행돼서 index가 변화되어 UI 갱신
  void _onTab(int i) {
    setState(() {
      _index = i;
    });
  }

  // AppBar 제목
  String get _title {
    switch (_index) {
      case 0:
        return "홈";
      case 1:
        return "캘린더";
      case 2:
        return "게시판";
      case 3:
        return "채팅";
      case 4:
        return "설정";
      default:
        return "JOB LINE";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김
      ),
      // body: 중상단에 탭 화면들을 띄우는 영역
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      // bottomNavigationBar: 하단 네비게이션 바
      bottomNavigationBar: BottomNavBar(
        currentIndex: _index,
        onTap: _onTab,
      ),
    );
  }
}

