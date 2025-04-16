import 'package:see_write_say/core/helpers/system/keyboard_helper.dart';
import 'package:flutter/material.dart';
import 'package:see_write_say/features/history/api/history_writing_api_service.dart';

class WritingLogicService {
  static Future<void> saveHistory(String sentence, String grade,
      int imageId) async {
    try {
      await HistoryWritingApiService.saveHistory(
        imageId: imageId,
        sentence: sentence,
        grade: grade,
      );
    } catch (e) {
      debugPrint("❌ 서버 저장 실패: $e");
    }
  }

  static Future<bool> hasHistory({int? imageId}) async {
    debugPrint('hasHistory imageId : $imageId');
    try {
      final list = await HistoryWritingApiService.fetchHistory(
          imageId: imageId);
      return list.isNotEmpty;
    } catch (e) {
      debugPrint("❌ 서버 히스토리 확인 실패: $e");
      return false;
    }
  }

  static String cleanCorrection(String correctedText) {
    return correctedText.replaceAll(RegExp(r'^\d+\.\s*'), '');
  }

  static bool isValidInput(String text, int maxLength) {
    final trimmed = text.trim();
    return trimmed.isNotEmpty && trimmed.length <= maxLength;
  }

  static Future<bool> confirmOverwriteDialog(BuildContext context) async {
    KeyboardHelper.dismiss(context);
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text("기록을 저장할까요?"),
            content: Text("이전 작성 내용은 덮어쓰여요. 계속 진행할까요?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                  KeyboardHelper.dismiss(context);
                },
                child: Text("취소"),
              ),
              ElevatedButton(
                onPressed: () {
                  KeyboardHelper.dismiss(context);
                  Navigator.pop(context, true);
                },
                child: Text("저장하기"),
              ),
            ],
          ),
    );
    KeyboardHelper.dismiss(context);

    if(shouldSave == true){
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("작문 기록이 저장되었습니다.")));
    }

    return shouldSave ?? false;
  }
}