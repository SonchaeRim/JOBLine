import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 빈 인증 내역 리스트 위젯
class EmptyCertificationList extends StatelessWidget {
  const EmptyCertificationList({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '인증 내역이 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

