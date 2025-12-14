import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: size,
          child: AspectRatio(
            aspectRatio: 210 / 297, // A4 비율 (가로:세로)
            child: CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              memCacheWidth: (size * MediaQuery.of(context).devicePixelRatio).round(),
              placeholder: (context, url) => _buildPlaceholder(),
              errorWidget: (context, url, error) => _buildPlaceholder(),
            ),
          ),
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size * (297 / 210), // A4 비율
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

