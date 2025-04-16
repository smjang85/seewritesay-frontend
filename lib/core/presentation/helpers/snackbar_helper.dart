import 'dart:convert';
import 'package:flutter/material.dart';

class SnackbarHelper {
  /// 일반 메시지 스낵바 (기본 2초)
  static void show(BuildContext context, String message, {int seconds = 2}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: seconds),
        ),
      );
  }

  /// 에러 객체 처리 후 보여주는 스낵바
  static void showError(BuildContext context, Object error, {int seconds = 3}) {
    String raw = error.toString().replaceAll('Exception: ', '');
    String msg = raw;

    try {
      final jsonStart = raw.indexOf('{');
      if (jsonStart != -1) {
        final jsonPart = raw.substring(jsonStart);
        final decoded = jsonDecode(jsonPart);
        if (decoded is Map<String, dynamic>) {
          msg = decoded['message'] ?? decoded['errorCode'] ?? raw;
        }
      }
    } catch (_) {
      msg = raw;
    }

    show(context, msg, seconds: seconds);
  }
}
