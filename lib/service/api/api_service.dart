import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';


class ApiService {

  // 🔑 JWT 토큰 가져오기
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // ✅ 보호된 API 호출 (예시: 로그인 테스트용)
  static Future<String> fetchProtectedMessage() async {
    final token = await _getToken();
    if (token == null) throw Exception("❌ JWT 토큰이 없습니다. 로그인 필요.");

    final response = await http.get(
      Uri.parse(ApiConstants.protectedHello),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception("❌ API 호출 실패: ${response.statusCode} ${response.body}");
    }
  }

  // ✅ 사용자 설정값 불러오기
  static Future<Map<String, dynamic>> fetchUserSettings() async {
    final token = await _getToken();
    if (token == null) throw Exception("❌ JWT 토큰 없음");

    final response = await http.get(
      Uri.parse(ApiConstants.userSettings),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ 설정값 불러오기 실패: ${response.statusCode}");
    }
  }

  // ✅ GPT 피드백 저장 API (예정)
  static Future<void> saveFeedback(
    String sentence,
    String correction,
    String feedback,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception("❌ JWT 토큰이 없습니다.");

    final response = await http.post(
      Uri.parse(ApiConstants.feedbackUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'sentence': sentence,
        'correction': correction,
        'feedback': feedback,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("❌ 피드백 저장 실패: ${response.statusCode} ${response.body}");
    }
  }

  // ✅ GPT 피드백 히스토리 조회 API
  static Future<List<Map<String, dynamic>>> fetchFeedbackHistory() async {
    final token = await _getToken();
    if (token == null) throw Exception("❌ JWT 토큰이 없습니다.");

    final response = await http.get(
      Uri.parse(ApiConstants.feedbackUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("❌ 히스토리 조회 실패: ${response.statusCode} ${response.body}");
    }
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
}
