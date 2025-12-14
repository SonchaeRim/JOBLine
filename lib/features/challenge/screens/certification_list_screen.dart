import 'package:flutter/material.dart';
import '../models/certification.dart';
import '../services/proof_service.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/certification_list_item.dart';
import '../widgets/empty_certification_list.dart';

/// 인증 내역 확인 화면
class CertificationListScreen extends StatelessWidget {
  final String userId;
  final ProofService _proofService = ProofService();

  CertificationListScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('인증 내역'),
      ),
      body: StreamBuilder<List<Certification>>(
        stream: _proofService.getUserCertifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('오류: ${snapshot.error}'),
            );
          }

          final certifications = snapshot.data ?? [];

          if (certifications.isEmpty) {
            return const EmptyCertificationList();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: certifications.length,
            itemBuilder: (context, index) {
              return CertificationListItem(
                certification: certifications[index],
              );
            },
          );
        },
      ),
    );
  }
}

