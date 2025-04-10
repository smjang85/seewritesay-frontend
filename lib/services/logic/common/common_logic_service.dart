import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class CommonLogicService {
  static Future<SharedPreferences> prefs() => SharedPreferences.getInstance();

  // 🔑 JWT 토큰 가져오기
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwt_token');
    if (jwtToken == null) throw Exception("❌ JWT 토큰 없음. 로그인 필요");

    debugPrint("getToken jwt_token : $jwtToken");
    return jwtToken;
  }

  // ✅ 외부 URL 열기 (예: Google 로그인)
  static Future<void> launchUrlExternal(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception("❌ URL 실행 실패: $url");
    }
  }

  static Map<String, dynamic> decodeJson(String json) {
    return jsonDecode(json) as Map<String, dynamic>;
  }

  static String encodeJson(Map<String, dynamic> data) {
    return jsonEncode(data);
  }


  static void dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }


  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<void> savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else {
      throw Exception("❌ 지원하지 않는 SharedPreferences 타입");
    }
  }

  static Future<void> removePreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> removePreferences(List<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }


  /// ❗ 기본 다이얼로그 방식 오류 처리
  static void showErrorDialog(BuildContext context, Object error) {
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("⚠️ 오류 발생"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  /// ✅ SnackBar(토스트) 방식 오류 처리
  static void showErrorSnackBar(BuildContext context, Object error) {
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Future<void> showConfirmAndNavigate({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("아니요"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm(); // 확인 시 콜백 실행
            },
            child: const Text("네"),
          ),
        ],
      ),
    );
  }
  static String formatReadableTime(String fileName) {
    try {
      final parts = fileName.trim().split('_');
      if (parts.length < 3) return fileName;

      final date = parts[2]; // 20250410
      final time = parts[3]; // 151231

      final formatted = '${date.substring(0, 4)}-${date.substring(4, 6)}-${date.substring(6, 8)} '
          '${time.substring(0, 2)}:${time.substring(2, 4)}:${time.substring(4, 6)}';

      return formatted;
    } catch (e) {
      debugPrint('📛 수동 포맷 실패: $e');
      return fileName;
    }
  }


}
