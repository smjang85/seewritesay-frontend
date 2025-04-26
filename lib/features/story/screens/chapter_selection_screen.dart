import 'package:flutter/material.dart';
import 'package:see_write_say/app/constants/api_constants.dart';
import 'package:see_write_say/core/presentation/theme/text_styles.dart';
import 'package:see_write_say/features/story/api/story_api_service.dart';
import 'package:see_write_say/features/story/dto/chapter_dto.dart';
import 'package:see_write_say/features/story/dto/story_dto.dart';
import 'package:see_write_say/core/helpers/system/navigation_helpers.dart';

class ChapterSelectionScreen extends StatefulWidget {
  final StoryDto story;

  const ChapterSelectionScreen({super.key, required this.story});

  @override
  State<ChapterSelectionScreen> createState() => _ChapterSelectionScreenState();
}

class _ChapterSelectionScreenState extends State<ChapterSelectionScreen> {
  late Future<List<ChapterDto>> _chaptersFuture;

  @override
  void initState() {
    super.initState();
    _chaptersFuture = StoryApiService.fetchChapters(widget.story.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: '챕터 목록', style: kHeadingTextStyle),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<ChapterDto>>(
        future: _chaptersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('챕터 불러오기 실패: ${snapshot.error}'));
          }

          final chapters = snapshot.data ?? [];
          if (chapters.isEmpty) {
            return const Center(child: Text('등록된 챕터가 없습니다.'));
          }

          // ✅ id 기준 중복 제거
          final uniqueChapters = { for (var c in chapters) c.id : c }.values.toList();

          // ✅ chapterOrder 기준 내림차순 정렬
          uniqueChapters.sort((a, b) => b.chapterOrder.compareTo(a.chapterOrder));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Story 제목 크게 표시
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.story.title,
                  style: kHeadingTextStyle.copyWith(fontSize: 24),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: uniqueChapters.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final chapter = uniqueChapters[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                      leading: widget.story.imagePath != null
                          ? SizedBox(
                        width: 56,
                        height: 56,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '${ApiConstants.baseUrl}${widget.story.imagePath!}',
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                          : const SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(Icons.image_not_supported),
                      ),
                      title: Text(
                        '${chapter.chapterOrder}화',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          NavigationHelpers.goToStoryReadingScreen(
                            context,
                            story: widget.story,
                            chapter: chapter,
                          );
                        },
                        child: const Text('보기'),
                      ),
                    );

                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
