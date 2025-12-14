import 'package:flutter/material.dart';
import 'action_button.dart';

/// 액션 버튼들 위젯
class ActionButtons extends StatelessWidget {
  final VoidCallback onPhotoCertificationTap;
  final VoidCallback onProofListTap;

  const ActionButtons({
    super.key,
    required this.onPhotoCertificationTap,
    required this.onProofListTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ActionButton(
              icon: Icons.camera_alt,
              label: '사진 인증하기',
              onTap: onPhotoCertificationTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ActionButton(
              icon: Icons.list,
              label: '인증 내역 확인하기',
              onTap: onProofListTap,
            ),
          ),
        ],
      ),
    );
  }
}

