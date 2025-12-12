import 'package:flutter/material.dart';
import '../models/certification.dart';

/// 인증 썸네일 위젯
class CertificationThumbnail extends StatelessWidget {
  final String? imageUrl;
  final ReviewStatus reviewStatus;
  final double size;

  const CertificationThumbnail({
    super.key,
    this.imageUrl,
    required this.reviewStatus,
    this.size = 90,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: size,
          child: AspectRatio(
            aspectRatio: 210 / 297, // A4 비율 (가로:세로)
            child: Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder();
              },
            ),
          ),
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: reviewStatus == ReviewStatus.approved
          ? Colors.green.shade100
          : reviewStatus == ReviewStatus.rejected
              ? Colors.red.shade100
              : Colors.orange.shade100,
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
        size: size * 0.44, // 40 / 90
      ),
    );
  }
}

