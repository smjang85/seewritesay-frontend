import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WritingHistoryLogicService {
  static Future<void> save(String sentence, String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = {
      'sentence': sentence,
      'image': imagePath,
      'timestamp': DateTime.now().toIso8601String(),
    };

    List<String> history = prefs.getStringList('writingHistory') ?? [];

    // 🔥 기존 동일 이미지 기록 제거
    history.removeWhere((item) {
      final decoded = jsonDecode(item);
      return decoded['image'] == imagePath;
    });

    // 🔄 새 기록 추가
    history.add(jsonEncode(entry));

    await prefs.setStringList('writingHistory', history);
  }
}
