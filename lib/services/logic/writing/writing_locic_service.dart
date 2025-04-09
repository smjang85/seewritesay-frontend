import 'package:flutter/material.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:SeeWriteSay/services/api/history/history_writing_api_service.dart';

class WritingLogicService {
  static Future<void> saveHistory(String sentence, int imageId) async {
    try {
      await HistoryWritingApiService.saveHistory(
        imageId: imageId,
        sentence: sentence,
      );
    } catch (e) {
      debugPrint("❌ 서버 저장 실패: $e");
    }
  }

  static Future<bool> hasHistory({int? imageId}) async {
    debugPrint('hasHistory imageId : $imageId');
    try {
      final list = await HistoryWritingApiService.fetchHistory(imageId: imageId);
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
    CommonLogicService.dismissKeyboard(context);
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("기록을 저장할까요?"),
        content: Text("이전 작성 내용은 덮어쓰여요. 계속 진행할까요?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              CommonLogicService.dismissKeyboard(context);
            },
            child: Text("취소"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text("저장하기"),
          ),
        ],
      ),
    ) ??
        false;
  }
}
