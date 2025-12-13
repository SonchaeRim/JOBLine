import 'package:flutter/material.dart';
import '../../challenge/models/certification.dart';
import '../../challenge/services/proof_service.dart';
import '../../../../routes/route_names.dart';
import 'certification_card.dart';

/// 인증 섹션 위젯 (승인된 인증 표시)
class CertificationSection extends StatelessWidget {
  final String userId;

  const CertificationSection({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final ProofService proofService = ProofService();

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '인증 내역',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      RouteNames.proofList,
                      arguments: {'userId': userId} as Map<String, dynamic>,
                    );
                  },
                  child: const Text('전체보기'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Certification>>(
            stream: proofService.getUserCertifications(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 140,
                  child: Center(
                    child: Text(
                      '인증을 불러올 수 없습니다.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              final certifications = snapshot.data ?? [];
              
              // 승인된 인증만 필터링하고 최대 10개까지
              final approvedCertifications = certifications
                  .where((cert) => cert.reviewStatus == ReviewStatus.approved)
                  .take(10)
                  .toList();

              if (approvedCertifications.isEmpty) {
                return Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(
                      '승인된 인증이 없습니다.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 8.0, right: 20.0),
                  itemCount: approvedCertifications.length,
                  itemBuilder: (context, index) {
                    final certification = approvedCertifications[index];
                    return CertificationCard(certification: certification);
                  },
                ),
              );
            },
          ),
        ],
    );
  }
}