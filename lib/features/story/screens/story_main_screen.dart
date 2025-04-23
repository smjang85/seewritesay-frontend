import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_write_say/core/presentation/components/common/common_empty_message.dart';
import 'package:see_write_say/features/story/providers/story_main_provider.dart';
import 'package:see_write_say/core/helpers/system/navigation_helpers.dart';
import 'package:see_write_say/core/presentation/components/common/common_image_viewer.dart'; // ✅ import

class StoryMainScreen extends StatelessWidget {
  const StoryMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StoryMainProvider()..fetchStories(),
      child: const _StoryMainContent(),
    );
  }
}

class _StoryMainContent extends StatelessWidget {
  const _StoryMainContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoryMainProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('아이들을 위한 스토리')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
          ? Center(child: Text(provider.errorMessage!))
          : provider.stories.isEmpty
          ? const CommonEmptyMessage(
        message: '스토리가 아직 없어요!',
        icon: Icons.menu_book_outlined,
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.stories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final story = provider.stories[index];
          return GestureDetector(
            onTap: () => NavigationHelpers.goToStoryReadingScreen(
              context,
              story,
            ),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: story.imagePath != null &&
                        story.imagePath!.isNotEmpty
                        ? CommonImageViewer(
                      imagePath: story.imagePath!,
                      height: double.infinity,
                    )
                        : const Icon(
                      Icons.image_not_supported,
                      size: 48,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      story.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
