import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 210 / 297, // A4 비율
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) => _buildLoadingIndicator(),
          errorWidget: (context, url, error) => _buildLoadingIndicator(),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
        ),
      ),
    );
  }
}

