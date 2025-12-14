import 'package:flutter/material.dart';
import '../models/certification.dart';
import 'detail_item.dart';

/// 인증 상세 정보 카드 위젯
class CertificationDetailInfo extends StatelessWidget {
  final Certification certification;

  const CertificationDetailInfo({
    super.key,
    required this.certification,
  });

  Widget _buildDetailItem(String label, String value) {
    return DetailItem(label: label, value: value);
  }

  @override
  Widget build(BuildContext context) {
    if (certification.certificationDetails == null || 
        certification.certificationDetails!.isEmpty) {
      return const SizedBox.shrink();
    }

    final details = certification.certificationDetails!;
    final widgets = <Widget>[];

    if (certification.certificationType == CertificationType.license) {
      final licenseType = details['licenseType'] as String?;
      if (licenseType != null) {
        String licenseTypeLabel = '';
        switch (licenseType) {
          case 'national':
            licenseTypeLabel = '국가자격증';
            break;
          case 'national_professional':
            licenseTypeLabel = '국가전문자격';
            break;
          case 'private':
            licenseTypeLabel = '민간자격증';
            break;
        }
        widgets.add(_buildDetailItem('자격증 종류', licenseTypeLabel));

        if (licenseType == 'national') {
          final category = details['category'] as String?;
          if (category != null) {
            widgets.add(_buildDetailItem(
              '분야',
              category == 'technical' ? '기술·기능 분야' : '서비스 분야',
            ));
          }
        }

        if (licenseType == 'private') {
          final privateType = details['privateType'] as String?;
          if (privateType != null) {
            widgets.add(_buildDetailItem(
              '민간자격 유형',
              privateType == 'national_approved' ? '국가공인' : '등록민간자격',
            ));
          }
        }

        final grade = details['grade'] as String?;
        if (grade != null) {
          widgets.add(_buildDetailItem('등급', grade));
        }
      }
    } else if (certification.certificationType == CertificationType.publicServiceExam) {
      final examType = details['examType'] as String?;
      if (examType != null) {
        widgets.add(_buildDetailItem('시험 종류', examType));
      }
    } else if (certification.certificationType == CertificationType.languageExam) {
      final examType = details['examType'] as String?;
      if (examType != null) {
        widgets.add(_buildDetailItem('시험 종류', examType));
      }
      final score = details['score'] ?? details['grade'];
      if (score != null) {
        widgets.add(_buildDetailItem(
          examType == '한국사' ? '등급' : '점수',
          score.toString(),
        ));
      }
    } else if (certification.certificationType == CertificationType.contest) {
      final scale = details['scale'] as String?;
      if (scale != null) {
        String scaleLabel = '';
        switch (scale) {
          case 'international':
            scaleLabel = '국제';
            break;
          case 'national':
            scaleLabel = '전국';
            break;
          case 'local':
            scaleLabel = '시·도';
            break;
        }
        widgets.add(_buildDetailItem('규모', scaleLabel));
      }
      final result = details['result'] as String?;
      if (result != null) {
        widgets.add(_buildDetailItem('결과', result));
      }
    }

    if (widgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상세 정보',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widgets,
          ],
        ),
      ),
    );
  }
}

