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

  static String formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return "${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)} "
          "${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}:${_twoDigits(dt.second)}";
    } catch (_) {
      return raw;
    }
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');

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
}
