import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 검토 상태 카드 위젯
class ReviewStatusCard extends StatelessWidget {
  final int pendingCount;

  const ReviewStatusCard({
    super.key,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('📄'),
          const SizedBox(width: 8),
          Text(
            pendingCount == 0
                ? '검토할 사진이 없습니다.'
                : '$pendingCount건의 검토 진행 중\n검토는 1주일 이내에 완료됩니다.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

