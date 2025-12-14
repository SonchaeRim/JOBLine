import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/certification.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/route_names.dart';
import 'certification_thumbnail.dart';

/// 인증 내역 리스트 아이템 위젯
class CertificationListItem extends StatelessWidget {
  final Certification certification;

  const CertificationListItem({
    super.key,
    required this.certification,
  });

  String _getReviewStatusLabel(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.approved:
        return '인증 완료';
      case ReviewStatus.rejected:
        return '반려';
      case ReviewStatus.pending:
        return '검토 중';
    }
  }

  Color _getReviewStatusColor(ReviewStatus status) {
    switch (status) {
      case ReviewStatus.approved:
        return Colors.green.shade700;
      case ReviewStatus.rejected:
        return Colors.red.shade700;
      case ReviewStatus.pending:
        return Colors.orange.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            RouteNames.proofDetail,
            arguments: {
              'certificationId': certification.id,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 썸네일
              CertificationThumbnail(
                imageUrl: certification.imageUrl,
                reviewStatus: certification.reviewStatus,
              ),
              const SizedBox(width: 16),
              // 텍스트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      certification.description ?? '인증 내역',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          DateFormat('yyyy년 M월 d일', 'ko_KR').format(certification.proofDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: certification.reviewStatus == ReviewStatus.approved
                                ? Colors.green.shade50
                                : certification.reviewStatus == ReviewStatus.rejected
                                    ? Colors.red.shade50
                                    : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getReviewStatusLabel(certification.reviewStatus),
                            style: TextStyle(
                              fontSize: 11,
                              color: _getReviewStatusColor(certification.reviewStatus),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // XP 표시 (줄바꿈 방지)
              if (certification.xpEarned > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    '+${certification.xpEarned} XP',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

