import 'package:flutter/material.dart';
import '../../../../routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';

/// 관리자 인증 관리 버튼 위젯
class AdminButton extends StatelessWidget {
  const AdminButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, RouteNames.adminUserList);
          },
          icon: const Icon(Icons.admin_panel_settings),
          label: const Text('인증 관리'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

