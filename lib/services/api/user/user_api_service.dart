import 'dart:convert';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:http/http.dart' as http;
import 'package:SeeWriteSay/constants/api_constants.dart';


class UserApiService {

  // ✅ 사용자 설정값 불러오기
  static Future<Map<String, dynamic>> fetchUserSettings() async {
    final token = await CommonLogicService.getToken();
    if (token == null) throw Exception("❌ JWT 토큰 없음");

    final response = await http.get(
      Uri.parse(ApiConstants.userSettingsUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("❌ 설정값 불러오기 실패: ${response.statusCode}");
    }
  }
}
