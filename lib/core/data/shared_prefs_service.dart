import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) {
      throw Exception("❌ JWT 토큰 없음 또는 비어 있음. 다시 로그인해주세요.");
    }
    return token;
  }

  static Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<void> save(String key, dynamic value) async {
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

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> removeAll(List<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static Future<void> removeMultiple(List<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  static Future<List<String>> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }

  static Future<void> setStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }
}
