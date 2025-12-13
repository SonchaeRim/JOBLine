import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/certification.dart';
import 'detail_item.dart';
import '../../../core/theme/app_colors.dart';

/// 인증 기본 정보 카드 위젯
class CertificationBasicInfo extends StatelessWidget {
  final Certification certification;

  const CertificationBasicInfo({
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

  String _getReviewStatusLabel(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.approved:
        return '인증 완료';
      case ReviewStatus.rejected:
        return '인증 실패';
      case ReviewStatus.pending:
        return '검토 중';
    }
  }

  Color _getReviewStatusColor(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.approved:
        return Colors.green;
      case ReviewStatus.rejected:
        return Colors.red;
      case ReviewStatus.pending:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailItem(
              label: '인증 이름',
              value: certification.description ?? '인증 내역',
            ),
            const Divider(),
            DetailItem(
              label: '인증 유형',
              value: _getCertificationTypeLabel(certification.certificationType),
            ),
            const Divider(),
            DetailItem(
              label: '인증 날짜',
              value: DateFormat('yyyy년 M월 d일', 'ko_KR').format(certification.proofDate),
            ),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '검토 상태',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _getReviewStatusLabel(certification.reviewStatus),
                    style: TextStyle(
                      fontSize: 14,
                      color: _getReviewStatusColor(certification.reviewStatus),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (certification.xpEarned > 0) ...[
              const Divider(),
              DetailItem(
                label: '획득 XP',
                value: '+${certification.xpEarned} XP',
                valueColor: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

