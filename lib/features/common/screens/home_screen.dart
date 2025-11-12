
import 'package:flutter/material.dart';

/// 홈 화면: 앱의 메인 콘텐츠가 표시되는 공간
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        // 홈 화면에서는 뒤로가기 버튼을 자동으로 표시하지 않음
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Home Screen',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              // 다른 화면으로 이동하는 예시 버튼들
              ElevatedButton(
                onPressed: () {
                  // TODO: 게시판 화면으로 이동하는 로직 추가
                  // Navigator.pushNamed(context, '/board');
                },
                child: const Text('게시판 가기'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  // TODO: 캘린더 화면으로 이동하는 로직 추가
                  // Navigator.pushNamed(context, '/calendar');
                },
                child: const Text('캘린더 가기'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  // TODO: 채팅 화면으로 이동하는 로직 추가
                  // Navigator.pushNamed(context, '/chat');
                },
                child: const Text('채팅 목록 가기'),
              ),
              const SizedBox(height: 20),
              // 로그아웃 버튼
              TextButton(
                onPressed: () {
                  // 로그인 화면으로 돌아가기 (이전 화면 기록 모두 삭제)
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
                },
                child: const Text('로그아웃'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

