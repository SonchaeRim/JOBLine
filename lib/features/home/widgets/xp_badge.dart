import 'package:flutter/material.dart';
import '../../xp/models/rank.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/route_names.dart';

/// XP 배지 위젯 (홈 화면용) - 더미 데이터로 프론트 테스트
class XpBadge extends StatelessWidget {
  final String userId;
  final VoidCallback? onChallengeRegisterPressed;

  const XpBadge({
    super.key,
    required this.userId,
    this.onChallengeRegisterPressed,
  });

  @override
  Widget build(BuildContext context) {
    // 더미 데이터 (프론트 테스트용)
    const totalXp = 150; // SILVER 등급 (200 필요)
    final currentRank = RankUtil.getRank(totalXp);
    final ranks = Rank.values;
    final currentIndex = ranks.indexOf(currentRank);
    final nextRank = currentIndex < ranks.length - 1 
        ? ranks[currentIndex + 1] 
        : null;
    
    // 현재 등급에서 다음 등급까지의 XP 계산
    final currentRankXp = currentRank.requiredXp;
    final nextRankXp = nextRank?.requiredXp ?? currentRankXp;
    final xpInCurrentRank = totalXp - currentRankXp;
    final xpNeededForNextRank = nextRankXp - currentRankXp;
    final progress = xpNeededForNextRank > 0 
        ? (xpInCurrentRank / xpNeededForNextRank).clamp(0.0, 1.0)
        : 1.0;

    return Column(
      children: [
        // 등급 카드
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.primary, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // JL 아바타
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'JL',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 등급 표시
              Text(
                currentRank.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              // 진행 바
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              // 다음 등급 및 XP 정보
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nextRank != null 
                        ? '다음 등급 : ${nextRank.name}'
                        : '최고 등급',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$xpInCurrentRank / $xpNeededForNextRank Exp',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 챌린지 등록 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onChallengeRegisterPressed ?? () {
              Navigator.pushNamed(context, RouteNames.challenge);
            },
            icon: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            label: const Text(
              '챌린지 등록',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
