import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';

// 앱의 공통 틀
class AppScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final Widget body;

  const AppScaffold({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.body,
  });

  // AppBar 제목
  String get _title {
    switch (currentIndex) {
      case 0: return "홈";
      case 1: return "게시판";
      case 2: return "캘린더";
      case 3: return "채팅";
      case 4: return "설정";
      default: return "JOB LINE";
    }
  }

  @override
  Widget build(BuildContext context) {

    // Scaffold를 만들고 상단 AppBar + 중간 body + 하단 BottomNavBar 배치
    // => AppScaffold은 앱 전체의 공통 프레임
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: body,
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: onTabSelected,
      ),
    );
  }
}
