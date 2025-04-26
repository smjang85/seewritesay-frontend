import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:see_write_say/core/logic/session_manager.dart';
import 'package:see_write_say/features/image/dto/image_dto.dart';
import 'package:see_write_say/features/story/dto/story_dto.dart';
import 'package:see_write_say/features/story/dto/chapter_dto.dart';
import 'package:see_write_say/features/story/enum/story_type.dart';

class NavigationHelpers {
  // 📝 글쓰기 화면
  static void goToWritingScreen(
      BuildContext context,
      ImageDto image, {
        String? sentence,
      }) {
    context.pushNamed(
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

  // 📚 읽기 화면 (이미지 + 문장 기반)
  static void goToReadingScreen(
      BuildContext context, {
        String? sentence,
        required ImageDto imageDto,
      }) {
    debugPrint("goToReadingScreen - imageDto : $imageDto , sentence : $sentence");

    context.pushNamed(
      'reading',
      extra: {
        'sentence': sentence?.trim(),
        'imageDto': imageDto,
      },
    );
  }

  // 📖 스토리 읽기 (단편 or 장편 - 통합형)
  static void goToStoryReadingScreen(
      BuildContext context, {
        StoryDto? story,
        ChapterDto? chapter,
      }) {
    assert(story != null || chapter != null, 'story 또는 chapter 중 하나는 반드시 필요합니다.');

    context.pushNamed(
      'storyReading',
      extra: {
        'story': story,
        'chapter': chapter,
      },
    );
  }

  // 📑 챕터 선택 화면 (장편일 경우)
  static void goToChapterSelectionScreen(BuildContext context, StoryDto story) {
    context.pushNamed(
      'chapterSelection',
      extra: story,
    );
  }

  // 🧑 프로필 설정 화면
  static void goToProfileSetupScreen(BuildContext context) {
    context.goNamed('profileSetup');
  }

  static void pushToProfileSetupScreen(BuildContext context) {
    context.pushNamed('profileSetup', queryParameters: {'fromDrawer': 'true'});
  }

  // 🖼 그림 선택 화면
  static void goToPictureScreen(BuildContext context) {
    context.goNamed('picture');
  }

  // 🕘 작성 히스토리 (글쓰기 히스토리)
  static void goToHistoryWritingScreen(BuildContext context, {bool withCategory = false}) {
    final uri = Uri(path: '/historyWriting', queryParameters: {
      'initialWithCategory': withCategory.toString(),
    });
    context.push(uri.toString());
  }

  // 📖 읽기 히스토리
  static void goToHistoryReadingScreen(BuildContext context) {
    context.push('/historyReading');
  }

  // 🔓 로그인 화면
  static void goToLoginScreen(BuildContext context) {
    final sessionManager = context.read<SessionManager>();
    sessionManager.disposeSession();
    context.goNamed('login');
  }


  /// 📘 단편 vs 장편 자동 분기
  static void goToStoryByType(BuildContext context, StoryDto story) {
    final type = StoryType.fromCode(story.type);
    if (type == StoryType.short) {
      goToStoryReadingScreen(context, story: story);
    } else {
      goToChapterSelectionScreen(context, story);
    }
  }

  // 📘 스토리 메인 (단편/장편 리스트)
  static void goToStoryMainScreen(BuildContext context) {
    context.pushNamed('storyMain');
  }

  // 📥 히스토리 쓰기 결과 반환
  static Future<Map<String, dynamic>?> openHistoryWritingAndReturn(
      BuildContext context, {
        int? imageId,
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

  // ⬅️ 뒤로 + 결과 반환
  static void popWithResult(BuildContext context, Map<String, dynamic> result) {
    context.pop(result);
  }
}
