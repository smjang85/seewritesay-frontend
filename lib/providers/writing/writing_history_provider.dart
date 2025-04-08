import 'package:flutter/material.dart';
import 'package:SeeWriteSay/services/api/writing/writing_history_api_service.dart';

class WritingHistoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> history = [];
  final int? imageId;

  WritingHistoryProvider({this.imageId});

  Future<void> loadHistory() async {
    debugPrint("WritingHistoryProvider loadHistory called");
    try {
      final loaded = await WritingHistoryApiService.fetchHistory(
        imageId: imageId,
      );
      loaded.sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));

      debugPrint("WritingHistoryProvider loaded :$loaded");

      history = loaded;
    } catch (e) {
      debugPrint("❌ 서버 히스토리 불러오기 실패: $e");
      history = [];
    }
    notifyListeners();
  }



  Future<void> deleteHistoryItem(int index) async {
    // 서버 API에 삭제 기능이 없다면 이건 구현 보류
    debugPrint("❌ 서버 기반에서는 삭제 기능이 아직 미구현 상태예요.");
  }
}
