import 'package:flutter/material.dart';
import '../models/certification.dart';

/// 인증 이미지 위젯
class CertificationImage extends StatelessWidget {
  final String? imageUrl;
  final ReviewStatus reviewStatus;

  const CertificationImage({
    super.key,
    this.imageUrl,
    required this.reviewStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 210 / 297, // A4 비율
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: reviewStatus == ReviewStatus.approved
                    ? Colors.green.shade100
                    : reviewStatus == ReviewStatus.rejected
                        ? Colors.red.shade100
                        : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                reviewStatus == ReviewStatus.approved
                    ? Icons.check
                    : reviewStatus == ReviewStatus.rejected
                        ? Icons.close
                        : Icons.pending,
                color: reviewStatus == ReviewStatus.approved
                    ? Colors.green
                    : reviewStatus == ReviewStatus.rejected
                        ? Colors.red
                        : Colors.orange,
                size: 80,
              ),
            );
          },
        ),
      ),
    );
  }
}

