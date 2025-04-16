import 'dart:convert';

class JsonHelper {
  static Map<String, dynamic> decode(String json) {
    return jsonDecode(json) as Map<String, dynamic>;
  }

  static String encode(Map<String, dynamic> data) {
    return jsonEncode(data);
  }
}
