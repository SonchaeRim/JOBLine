// lib/features/common/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import '../../../routes/route_names.dart';

/// 앱 첫 실행 시 잠깐 보여줄 스플래시 화면
/// 몇 초 후 항상 로그인 화면으로 이동 (자동 로그인 없음)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _splashDuration = Duration(seconds: 2); // 필요하면 시간 조절

  @override
  void initState() {
    super.initState();
    // 화면이 그려진 뒤에 타이머 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(_splashDuration, () {
        if (!mounted) return;
        // 스택에서 스플래시를 제거하고 로그인으로 교체
        Navigator.of(context).pushReplacementNamed(RouteNames.login);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _SplashBody(),
      ),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 가운데 로고 영역
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                // 상단 작은 텍스트: "취준생 커뮤니티"
                Text(
                  '취준생 커뮤니티',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 8),
                // 메인 타이틀: "JOB LINE"
                Text(
                  'JOB LINE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 하단 "JL" 텍스트
        Padding(
          padding: EdgeInsets.only(bottom: 32),
          child: Text(
            'JL',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 4.0,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
