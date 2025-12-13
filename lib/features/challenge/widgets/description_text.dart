import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 설명 텍스트 위젯
class DescriptionText extends StatelessWidget {
  const DescriptionText({super.key});

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}

