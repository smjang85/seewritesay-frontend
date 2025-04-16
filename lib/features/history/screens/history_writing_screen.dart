import 'package:see_write_say/core/helpers/format/format_helper.dart';
import 'package:see_write_say/features/image/dto/image_dto.dart';
import 'package:see_write_say/core/presentation/components/common_dropdown.dart';
import 'package:see_write_say/core/presentation/components/common_empty_message.dart';
import 'package:see_write_say/features/history/providers/history_writing_provider.dart';
import 'package:flutter/material.dart';
import 'package:see_write_say/core/helpers/system/navigation_helpers.dart';
import 'package:see_write_say/app/constants/api_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

class HistoryWritingScreen extends StatelessWidget {
  final int? imageId;
  final bool initialWithCategory;

  const HistoryWritingScreen({
    super.key,
    this.imageId,
    this.initialWithCategory = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => HistoryWritingProvider(
            imageId: imageId,
            loadWithCategory: initialWithCategory,
          ),
      child: const HistoryWritingContent(),
    );
  }
}

class HistoryWritingContent extends StatelessWidget {
  const HistoryWritingContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryWritingProvider>();
    final historyList = provider.history;

    debugPrint(
      '📦 드롭다운 category 목록: ${provider.history.map((e) => e.categoryName).toSet().toList()}',
    );
    debugPrint('📦 history.length: ${provider.history.length}');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.edit_note),
            SizedBox(width: 8),
            Text("이전 작문내역"),
          ],
        ),
      ),

      body: Column(
        children: [
          if (provider.categories.length > 1 && provider.imageId == null)
            SizedBox(
              width: 380,
              child: CommonDropdown(
                label: "카테고리",
                value: provider.selectedCategory,
                items: provider.categories,
                onChanged: (value) {
                  if (value != null) {
                    provider.setSelectedCategory(value);
                  }
                },
              ),
            ),
          Expanded(
            child:
                historyList.isEmpty
                    ? const CommonEmptyMessage(message: '진행한 작문이 없습니다.')
                    : ListView.separated(
                      itemCount: historyList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = historyList[index];
                        final thumbnail = entry.imagePath;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: '${ApiConstants.baseUrl}$thumbnail',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder:
                                  (_, __) => const SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (_, __, ___) => const Icon(
                                    Icons.image_not_supported,
                                    size: 48,
                                  ),
                            ),
                          ),
                          title: Text(
                            entry.sentence,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  FormatHelper.formatReadableTime(
                                    entry.createdAt?.toString() ?? '',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text("삭제하시겠어요?"),
                                      content: const Text("이 작문 기록을 삭제할까요?"),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text("취소"),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text("삭제"),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm ?? false) {
                                await provider.deleteHistoryItem(index);
                              }
                            },
                          ),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text("작문하기로 이동"),
                                    content: const Text(
                                      "이 작문을 불러와서 수정하거나 이어서 작성할까요?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text("아니오"),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text("예"),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm == true) {
                              Navigator.pop(context);
                              NavigationHelpers.goToWritingScreen(
                                context,
                                ImageDto(
                                  id: entry.imageId,
                                  path: entry.imagePath,
                                  name: entry.imageName,
                                  description: entry.imageDescription,
                                ),
                                sentence: entry.sentence,
                              );
                            }
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
