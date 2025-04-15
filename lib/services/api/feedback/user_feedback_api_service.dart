import 'dart:convert';
import 'package:SeeWriteSay/constants/api_constants.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:SeeWriteSay/utils/dialog_popup_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserFeedbackApiService {
  static Future<({int readingRemainingCount, int writingRemainingCount})> fetchRemainingCounts(
      int imageId,
      ) async {


      final token = await CommonLogicService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConstants.userFeedbackUrl}?imageId=$imageId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final data = json['data'] as Map<String, dynamic>;

        return (
        readingRemainingCount: (data['readingRemainingCount'] ?? 0) as int,
        writingRemainingCount: (data['writingRemainingCount'] ?? 0) as int,
        );
      } else {
        throw Exception("❌ 피드백 횟수 조회 실패: ${response.statusCode} ${response.body}");
      }
  }

  static Future<void> decreaseWritingFeedbackCount(
      BuildContext context,
      int imageId,
      ) async {
    DialogPopupHelper.showLoadingDialog(context);

    try {
      final token = await CommonLogicService.getToken();

      final response = await http.post(
        Uri.parse(ApiConstants.userFeedbackWritingDecrementUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'imageId': imageId}),
      );

      if (response.statusCode != 204) {
        throw Exception("❌ 피드백 감소 실패: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      DialogPopupHelper.showErrorDialog(context, e);
      rethrow;
    } finally {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  static Future<void> decreaseReadingFeedbackCount(
      BuildContext context,
      int imageId,
      ) async {
    DialogPopupHelper.showLoadingDialog(context);

    try {
      final token = await CommonLogicService.getToken();

      final response = await http.post(
        Uri.parse(ApiConstants.userFeedbackReadingDecrementUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'imageId': imageId}),
      );

      if (response.statusCode != 204) {
        throw Exception("❌ 피드백 감소 실패: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      DialogPopupHelper.showErrorDialog(context, e);
      rethrow;
    } finally {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
