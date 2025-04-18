import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:see_write_say/app/constants/api_constants.dart';

class CommonImageViewer extends StatelessWidget {
  final String imagePath;
  final bool showCheck;
  final double height;
  final double borderRadius;
  final BoxFit fit; // ✅ 추가

  const CommonImageViewer({
    super.key,
    required this.imagePath,
    this.showCheck = false,
    this.height = 200,
    this.borderRadius = 12,
    this.fit = BoxFit.cover, // ✅ 기본값 설정
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: CachedNetworkImage(
              imageUrl: '${ApiConstants.baseUrl}$imagePath',
              height: height,
              width: double.infinity,
              fit: fit, // ✅ 적용
              placeholder: (context, url) => SizedBox(
                height: height,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image, size: 100),
            ),
          ),
        ),
        if (showCheck)
          const Positioned(
            right: 10,
            top: 10,
            child: Icon(Icons.check_circle, color: Colors.green, size: 30),
          ),
      ],
    );
  }
}
