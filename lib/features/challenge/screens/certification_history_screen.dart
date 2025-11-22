import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/certification.dart';
import '../services/proof_service.dart';
import '../../../core/theme/app_colors.dart';

/// 인증 내역 확인 화면
class CertificationHistoryScreen extends StatelessWidget {
  final String userId;
  final ProofService _proofService = ProofService();

  CertificationHistoryScreen({
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: certifications.length,
            itemBuilder: (context, index) {
              final cert = certifications[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cert.isApproved
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    child: Icon(
                      cert.isApproved ? Icons.check : Icons.pending,
                      color: cert.isApproved ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text(
                    DateFormat('yyyy년 M월 d일', 'ko_KR').format(cert.proofDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: cert.description != null
                      ? Text(cert.description!)
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${cert.xpEarned} XP',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        cert.isApproved ? '승인됨' : '대기중',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}