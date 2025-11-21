import 'dart:async';
import 'package:flutter/material.dart';
import '../services/challenge_service.dart';
import '../../../routes/app_routes.dart';
import '../../xp/models/rank.dart';
import '../../xp/services/xp_service.dart';
import '../../../core/theme/app_colors.dart';

/// 챌린지 화면 (디자인 기반)
class ChallengeListScreen extends StatefulWidget {
  const ChallengeListScreen({super.key});

  @override
  State<ChallengeListScreen> createState() => _ChallengeListScreenState();
}

class _ChallengeListScreenState extends State<ChallengeListScreen> {
  final ChallengeService _challengeService = ChallengeService();
  final XpService _xpService = XpService();
  String? _currentUserId; // TODO: 실제 사용자 ID로 교체 (B 담당과 협업)

  @override
  void initState() {
    super.initState();
    // TODO: 실제 사용자 인증 연동 (B 담당과 협업)
    _currentUserId = 'test_user_12345'; // 테스트용
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('챌린지'),
        ),
        body: const Center(
          child: Text('로그인이 필요합니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('챌린지'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 챌린지 카드
            _buildChallengeCard(),
            const SizedBox(height: 16),
            // 검토 상태
            _buildReviewStatus(),
            const SizedBox(height: 16),
            // 액션 버튼들
            _buildActionButtons(),
            const SizedBox(height: 24),
            // 등급 시스템
            _buildRankSystem(),
            const SizedBox(height: 24),
            // 설명 텍스트
            _buildDescriptionText(),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '챌린지',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: 심사기준 확인 화면 (나중에 구현)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('심사기준 확인 기능은 준비 중입니다.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text(
                  '> 심사기준 확인하기',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '사진을 촬영해 업로드하세요. 심사 기준에 따른 검토 이후, 완료되면 기준에 따라 경험치가 지급됩니다.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStatus() {
    return FutureBuilder<int>(
      future: _getPendingReviewCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('🤨'),
              const SizedBox(width: 8),
              Text(
                count == 0
                    ? '검토할 사진이 없습니다 🤨'
                    : '검토 대기 중인 사진: $count개',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<int> _getPendingReviewCount() async {
    if (_currentUserId == null) return 0;
    try {
      // TODO: 검토 대기 중인 인증 개수 가져오기
      // 현재는 간단히 0으로 반환
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.camera_alt,
              label: '사진 인증하기',
              onTap: () => _navigateToPhotoCertification(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.list,
              label: '인증 내역 확인하기',
              onTap: () => _navigateToCertificationHistory(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankSystem() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _xpService.getUserXpStream(_currentUserId!),
      builder: (context, snapshot) {
        final totalXp = (snapshot.data?['totalXp'] as int?) ?? 0;
        final currentRank = RankUtil.getRank(totalXp);
        final ranks = RankUtil.getAllRanks();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '등급 시스템',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ranks.asMap().entries.map((entry) {
                  final rank = entry.value;
                  final index = entry.key;
                  final isCurrentRank = rank == currentRank;
                  final height = 40.0 + (index * 10.0);

                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: height,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isCurrentRank
                                ? Colors.grey.shade300
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrentRank
                                  ? rank.color
                                  : Colors.grey.shade300,
                              width: isCurrentRank ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: rank.color,
                              child: const Text(
                                'JL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rank.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isCurrentRank
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          '-${rank.requiredXp} Exp',
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescriptionText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '사용자가 등록한 자격증, 대회 참가 이력, 수료증, 면허증 등은 내부 심사 기준에 따라 각각 경험치(Exp)로 환산됩니다.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '누적된 경험치가 100 Exp를 달성할 때마다 다음 등급으로 자동 승급됩니다.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '** 등급은 매일 자정(24시)에 한 번씩 업데이트됩니다.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPhotoCertification() {
    // TODO: 챌린지 선택 화면 추가 (현재는 첫 번째 활성 챌린지 사용)
    // Stream의 첫 번째 값을 가져와서 사용
    StreamSubscription<List<dynamic>>? subscription;
    subscription = _challengeService.getActiveChallenges().listen(
          (challenges) {
        subscription?.cancel(); // 첫 번째 값만 받고 구독 취소
        if (challenges.isNotEmpty && mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.proofCamera,
            arguments: {
              'challengeId': challenges.first.id,
              'userId': _currentUserId!,
            },
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('진행 중인 챌린지가 없습니다.')),
          );
        }
      },
      onError: (error) {
        subscription?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $error')),
          );
        }
      },
    );
  }

  void _navigateToCertificationHistory() {
    Navigator.pushNamed(
      context,
      AppRoutes.certificationHistory,
      arguments: {
        'userId': _currentUserId!,
      },
    );
  }
}