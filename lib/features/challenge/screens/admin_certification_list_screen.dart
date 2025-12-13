import 'package:flutter/material.dart';
import '../models/certification.dart';
import '../services/proof_service.dart';
import '../widgets/certification_list_item.dart';
import '../widgets/empty_certification_list.dart';

/// 관리자용 인증 내역 화면 (특정 유저의 인증 목록)
class AdminCertificationListScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final ProofService _proofService = ProofService();

  AdminCertificationListScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$userName님의 인증 내역'),
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

          // 검토 중인 항목을 먼저 표시하고, 그 다음 날짜순 정렬
          final sortedCertifications = List<Certification>.from(certifications);
          sortedCertifications.sort((a, b) {
            // pending을 먼저, 그 다음 날짜순
            if (a.reviewStatus == ReviewStatus.pending &&
                b.reviewStatus != ReviewStatus.pending) {
              return -1;
            }
            if (a.reviewStatus != ReviewStatus.pending &&
                b.reviewStatus == ReviewStatus.pending) {
              return 1;
            }
            return b.proofDate.compareTo(a.proofDate);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedCertifications.length,
            itemBuilder: (context, index) {
              final cert = sortedCertifications[index];
              return CertificationListItem(
                certification: cert,
              );
            },
          );
        },
      ),
    );
  }
}

