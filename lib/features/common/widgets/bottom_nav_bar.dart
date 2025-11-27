import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 탭 누르면 onTap() 실행 → MainScreen으로 전달됨
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // 5개 아이템일 때 fixed 타입 사용
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          label: '캘린더',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.article_outlined),
          label: '게시판',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: '채팅',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: '설정',
        ),
      ],
    );
  }
}
