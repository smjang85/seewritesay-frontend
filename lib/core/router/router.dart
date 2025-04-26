import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:see_write_say/features/image/dto/image_dto.dart';
import 'package:see_write_say/features/history/screens/history_reading_screen.dart';
import 'package:see_write_say/features/history/screens/history_writing_screen.dart';
import 'package:see_write_say/features/story/dto/chapter_dto.dart';
import 'package:see_write_say/features/story/dto/story_dto.dart';
import 'package:see_write_say/features/story/screens/chapter_selection_screen.dart';
import 'package:see_write_say/features/story/screens/story_main_screen.dart';
import 'package:see_write_say/features/story/screens/story_reading_screen.dart';
import 'package:see_write_say/features/user/screens/user_profile_screen.dart';
import 'package:see_write_say/features/login/screens/login_screen.dart';
import 'package:see_write_say/features/picture/screens/picture_screen.dart';
import 'package:see_write_say/features/reading/screens/reading_screen.dart';
import 'package:see_write_say/features/writing/screens/writing_screen.dart';
import 'package:see_write_say/features/login/screens/auth_callback_screen.dart';

final GoRouter appRouter = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/login',
  errorBuilder: (context, state) => const Scaffold(
    body: Center(child: Text('🚫 페이지를 찾을 수 없습니다.')),
  ),
  routes: [
    GoRoute(
      name: 'login',
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      name: 'profileSetup',
      path: '/profileSetup',
      builder: (context, state) => const UserProfileScreen(),
    ),
    GoRoute(
      name: 'picture',
      path: '/picture',
      builder: (context, state) => const PictureScreen(),
    ),
    GoRoute(
      name: 'writing',
      path: '/writing',
      builder: (context, state) {
        final imageId = int.tryParse(state.uri.queryParameters['imageId'] ?? '0') ?? 0;
        final imagePath = state.uri.queryParameters['imagePath'] ?? '';
        final imageName = state.uri.queryParameters['imageName'] ?? 'Untitled';
        final imageDescription = state.uri.queryParameters['imageDescription'] ?? '';
        final sentence = state.uri.queryParameters['sentence'];

        final imageDto = ImageDto(
          id: imageId,
          path: imagePath,
          name: imageName,
          description: imageDescription,
        );

        return WritingScreen(
          imageDto: imageDto,
          initialSentence: sentence,
        );
      },
    ),
    GoRoute(
      name: 'reading',
      path: '/reading',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final sentence = extra?['sentence'] as String?;
        final imageDto = extra?['imageDto'] as ImageDto?;

        return MaterialPage(
          child: ReadingScreen(
            sentence: sentence,
            imageDto: imageDto,
          ),
        );
      },
    ),
    GoRoute(
      name: 'historyWriting',
      path: '/historyWriting',
      builder: (context, state) {
        final initialWithCategory = state.uri.queryParameters['initialWithCategory'] == 'true';
        final imageIdParam = state.uri.queryParameters['imageId'];
        final imageId = imageIdParam != null ? int.tryParse(imageIdParam) : null;

        return HistoryWritingScreen(
          initialWithCategory: initialWithCategory,
          imageId: imageId,
        );
      },
    ),
    GoRoute(
      name: 'historyReading',
      path: '/historyReading',
      builder: (context, state) => const HistoryReadingScreen(),
    ),
    GoRoute(
      name: 'googleAuthCallback',
      path: '/googleAuth/callback',
      builder: (context, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        debugPrint("✅ token from query: $token");
        return AuthCallbackScreen(token: token);
      },
    ),
    GoRoute(
      name: 'storyMain',
      path: '/storyMain',
      builder: (context, state) => const StoryMainScreen(),
    ),
    GoRoute(
      name: 'storyReading',
      path: '/storyReading',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;

        final story = extra?['story'] as StoryDto?;
        final chapter = extra?['chapter'] as ChapterDto?;

        assert(story != null || chapter != null, 'story 또는 chapter 중 하나는 필수입니다.');

        return MaterialPage(
          child: StoryReadingScreen(
            story: story,
            chapter: chapter,
          ),
        );
      },
    ),
    GoRoute(
      name: 'chapterSelection',
      path: '/chapterSelection',
      builder: (context, state) {
        final extra = state.extra;
        assert(extra is StoryDto, 'chapterSelection 경로에는 StoryDto가 필요합니다');
        return ChapterSelectionScreen(story: extra as StoryDto);
      },
    ),
  ],
  redirect: (context, state) {
    // 로그인 관련 리디렉션 필요 시 여기에 작성
    return null;
  },
);
