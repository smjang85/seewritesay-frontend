import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';

class CommonImageViewer extends StatelessWidget {
  final String imagePath;
  final bool showCheck;
  final double height;
  final double borderRadius;

  const CommonImageViewer({
    super.key,
    required this.imagePath,
    this.showCheck = false,
    this.height = 200, // 기본값: 작문 화면 크기
    this.borderRadius = 12, // 기본 라운드 정도
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
              fit: BoxFit.cover,
              placeholder: (context, url) =>
              const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
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
