import 'dart:convert';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';

class FeedbackApiService {
  // ✅ GPT 피드백 저장 API (예정)
  static Future<void> saveFeedback(
    String sentence,
    String correction,
    String feedback,
  ) async {
    final token = await CommonLogicService.getToken();
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
    final token = await CommonLogicService.getToken();
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

  static Future<Map<String, String>> fetchFeedback(
    String userText,
    String imageId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception("❌ JWT 토큰이 없습니다. 로그인 필요.");
    }

    final response = await http.post(
      Uri.parse(ApiConstants.feedbackUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'sentence': userText, 'imageId': imageId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'correction': data['correction'] ?? userText,
        'feedback': data['feedback'] ?? '',
      };
    } else {
      throw Exception(
        "❌ GPT 피드백 요청 실패: ${response.statusCode} ${response.body}",
      );
    }
  }
}
