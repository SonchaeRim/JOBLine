import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import '../../challenge/screens/challenge_list_screen.dart';
import '../../home/widgets/xp_badge.dart';

/// D 담당 기능 테스트용 화면 (임시)
/// 이 화면은 테스트용이므로 나중에 삭제 가능
class CalendarTestScreen extends StatelessWidget {
  const CalendarTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('D 담당 기능 테스트'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'D 담당 기능 테스트',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // XP 배지 테스트
            const XpBadge(userId: 'test_user_12345'),
            const SizedBox(height: 24),
            // 캘린더 화면 이동
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalendarScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('캘린더 화면 테스트'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            // 챌린지 화면 이동
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChallengeListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.emoji_events),
              label: const Text('챌린지 화면 테스트'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              '테스트 안내',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                '1. Firestore 인덱스 생성 필요\n'
                '2. 테스트 챌린지 데이터 추가 필요\n'
                '3. 자세한 내용은 TEST_GUIDE.md 참고',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

