import 'package:see_write_say/features/image/dto/image_dto.dart';
import 'package:see_write_say/core/logic/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class NavigationHelpers {
  static void goToWritingScreen(
      BuildContext context,
      ImageDto image, {
        String? sentence,
      }) {
    context.pushNamed( // ✅ pushNamed → goNamed
      'writing',
      queryParameters: {
        'imageId': image.id.toString(),
        'imagePath': image.path,
        'imageName': image.name,
        'imageDescription': image.description,
        if (sentence != null) 'sentence': sentence,
      },
    );
  }
  static void goToHistoryWritingScreen(BuildContext context, {bool withCategory = false}) {
    final uri = Uri(path: '/historyWriting', queryParameters: {
      'initialWithCategory': withCategory.toString(),
    });

    context.push(uri.toString()); // ✅ GoRouter 기반으로 이동
  }

  static void goToHistoryReadingScreen(BuildContext context) {
    context.push('/historyReading');
  }

  static void goToLoginScreen(BuildContext context) {
    final sessionManager = context.read<SessionManager>();
    sessionManager.disposeSession();
    context.goNamed('login'); // GoRouter에서 name이 'login'인 라우트로 이동
  }

  static Future<Map<String, dynamic>?> openHistoryWritingAndReturn(
      BuildContext context, {
        int? imageId, // 타입을 int?로 변경
      }) async {
    final result = await GoRouter.of(context).pushNamed(
      'historyWriting',
      queryParameters: {
        if (imageId != null) 'imageId': imageId.toString(),
      },
    );

    if (!context.mounted) return null;

    if (result is Map<String, dynamic>) {
      return result;
    }
    return null;
  }

  static void goToReadingScreen(
      BuildContext context, {
        String? sentence,
        required ImageDto imageDto,
      }) {
    debugPrint("goToReadingScreen - imageDto : $imageDto , sentence : $sentence");

    context.pushNamed( // ✅ pushNamed → goNamed
      'reading',
      extra: {
        'sentence': sentence?.trim(),
        'imageDto': imageDto,
      },
    );
  }
  static void goToPictureScreen(BuildContext context) {
    context.goNamed('picture');
  }

  static void popWithResult(BuildContext context, Map<String, dynamic> result) {
    context.pop(result);
  }

  static void goToProfileSetupScreen(BuildContext context) {
    context.goNamed('profileSetup');
  }

  static void pushToProfileSetupScreen(BuildContext context) {
    context.pushNamed('profileSetup', queryParameters: {'fromDrawer': 'true'});
  }
}