import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../challenge/models/certification.dart';
import '../../../../core/theme/app_colors.dart';

/// 인증 카드 위젯
class CertificationCard extends StatelessWidget {
  final Certification certification;

  const CertificationCard({
    super.key,
    required this.certification,
  });

  String _getCertificationTypeLabel(CertificationType? type) {
    if (type == null) return '기타';
    switch (type) {
      case CertificationType.license:
        return '자격증';
      case CertificationType.publicServiceExam:
        return '공무원 시험';
      case CertificationType.languageExam:
        return '외국어 시험';
      case CertificationType.contest:
        return '공모전·대회';
      case CertificationType.exhibition:
        return '전시회·공연';
      case CertificationType.otherActivity:
        return '기타 활동';
    }
  }

  @override
  Widget build(BuildContext context) {
    final proofDate = certification.proofDate.toLocal();
    
    // 날짜 포맷: yyyy.M.d
    final dateFormat = DateFormat('yyyy.M.d', 'ko_KR');
    final formattedDate = dateFormat.format(proofDate);

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getCertificationTypeLabel(certification.certificationType),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  certification.description ?? '인증 내역',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (certification.xpEarned > 0) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '+${certification.xpEarned} XP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

