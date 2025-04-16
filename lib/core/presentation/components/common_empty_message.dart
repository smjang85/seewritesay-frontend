// lib/widgets/common_empty_message.dart
import 'package:flutter/material.dart';

class CommonEmptyMessage extends StatelessWidget {
  final String message;
  final IconData? icon;
  final double iconSize;
  final Color iconColor;

  const CommonEmptyMessage({
    super.key,
    required this.message,
    this.icon,
    this.iconSize = 80,
    this.iconColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: iconColor),
            const SizedBox(height: 16),
          ],
          Text(
            message,
            style: const TextStyle(fontSize: 18, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
