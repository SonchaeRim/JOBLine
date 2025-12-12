import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../xp/models/rank.dart';

/// 등급 시스템 위젯
class RankSystem extends StatelessWidget {
  final int totalXp;
  final String? rankString; // Firestore에 저장된 등급 (선택적)
  final bool isLoading; // 데이터 로딩 중인지 여부

  const RankSystem({
    super.key,
    required this.totalXp,
    this.rankString,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Firestore에 저장된 등급만 사용 (totalXp로 계산하지 않음)
    Rank? currentRank;
    if (!isLoading && rankString != null) {
      try {
        currentRank = Rank.values.firstWhere(
          (r) => r.name == rankString,
        );
      } catch (e) {
        // rankString이 유효하지 않으면 null (하이라이트 안 함)
        currentRank = null;
      }
    }
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: ranks.asMap().entries.map((entry) {
              final rank = entry.value;
              final index = entry.key;
              final isCurrentRank = !isLoading && rank == currentRank;
              // 높이를 더 높게 조정 (기본 60 + 인덱스당 15)
              final height = 60.0 + (index * 15.0);
              
              // 현재 등급인 경우: 뱃지 색의 명도를 20% 낮춘 색 계산
              Color backgroundColor;
              if (isCurrentRank) {
                final hsl = HSLColor.fromColor(rank.color);
                backgroundColor = hsl.withLightness((hsl.lightness * 0.8).clamp(0.0, 1.0)).toColor();
              } else {
                backgroundColor = Colors.white;
              }

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: height,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: backgroundColor,
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
                      '${rank.requiredXp} Exp',
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
  }
}

