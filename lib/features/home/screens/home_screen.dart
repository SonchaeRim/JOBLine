import 'package:flutter/material.dart';
import '../../../routes/route_names.dart';
import '../widgets/xp_badge.dart';
import '../../../core/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 홈 탭 화면
class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onTabChanged;

  const HomeScreen({super.key, this.onTabChanged});

  // 현재 사용자 ID 가져오기
  String? get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    // 사용자 ID가 없으면 임시 ID 사용 (개발용)
    final userId = _currentUserId ?? 'temp_user_id';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 헤더: 로고 + 커뮤니티
          _buildHeader(context),

          const SizedBox(height: 24),

          // XP Badge 섹션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: XpBadge(
              userId: userId,
              onChallengeRegisterPressed: () {
                Navigator.pushNamed(context, RouteNames.challenge);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 상단 헤더 (로고 + 커뮤니티 정보)
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽: JL 로고
          const Text(
            'JL',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          // 오른쪽: 커뮤니티 정보 (더미 데이터)
          Text(
            'IT개발 • 데이터',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}