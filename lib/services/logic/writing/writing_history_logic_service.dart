import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:flutter/material.dart';

class WritingHistoryLogicService {
  static const String _key = 'writingHistory';

  static Future<List<Map<String, dynamic>>> loadHistory({String? filterPath}) async {
    debugPrint("WritingHistoryLogicService loadHistory called");

    final prefs = await CommonLogicService.prefs();
    final rawList = prefs.getStringList(_key) ?? [];

    final history = rawList.map((e) => CommonLogicService.decodeJson(e)).toList();

    if (filterPath != null) {
      return history.where((e) => e['image'] == filterPath).toList();
    }
    return history;
  }

  static Future<void> deleteHistoryItemAt(int index) async {
    final prefs = await CommonLogicService.prefs();
    final rawList = prefs.getStringList(_key) ?? [];

    if (index >= 0 && index < rawList.length) {
      rawList.removeAt(index);
      await prefs.setStringList(_key, rawList);
    }
  }

}
