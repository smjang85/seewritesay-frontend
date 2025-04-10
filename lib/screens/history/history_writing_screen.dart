import 'package:flutter/material.dart';
import 'package:SeeWriteSay/models/image_model.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:SeeWriteSay/providers/history/history_writing_provider.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
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
      create: (_) => HistoryWritingProvider(
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

    debugPrint('📦 드롭다운 category 목록: ${provider.history.map((e) => e.categoryName).toSet().toList()}');
    debugPrint('📦 history.length: ${provider.history.length}');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.edit_note,
            ),
            const SizedBox(width: 8), // 아이콘과 텍스트 사이 간격
            const Text(
              "진행한 작문",
              style: TextStyle(
                fontSize: 20, // 텍스트 크기 맞추기
              ),
            ),
          ],
        ),
        bottom: provider.categories.length > 1 && provider.imageId == null
            ? PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: DropdownButton<String>(
              isExpanded: true,
              value: provider.selectedCategory,
              onChanged: (value) {
                if (value != null) {
                  provider.setSelectedCategory(value);
                }
              },
              items: provider.categories
                  .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat, style: const TextStyle(fontSize: 14)),
              ))
                  .toList(),
            ),
          ),
        )
            : null, // ✅ 드롭다운 숨기기
      ),
      body: historyList.isEmpty
          ? const Center(child: CircularProgressIndicator()) // 로딩 중일 때 표시
          : ListView.separated(
        itemCount: historyList.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = historyList[index];
          final thumbnail = entry.imagePath;
          final description = entry.imageDescription ?? '';
          final shortDesc = description.length > 30
              ? '${description.substring(0, 30)}...'
              : description;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: '${ApiConstants.baseUrl}$thumbnail',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox(
                  width: 60,
                  height: 60,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported, size: 48),
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
                if (shortDesc.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      shortDesc,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textScaleFactor: 1.0,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    CommonLogicService.formatReadableTime(entry.createdAt?.toString() ?? ''),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("삭제하시겠어요?"),
                    content: const Text("이 작문 기록을 삭제할까요?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("취소"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
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
                builder: (context) => AlertDialog(
                  title: const Text("작문하기로 이동"),
                  content: const Text("이 작문을 불러와서 수정하거나 이어서 작성할까요?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("아니오"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("예"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                Navigator.pop(context);
                NavigationHelpers.goToWritingScreen(
                  context,
                  ImageModel(
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
    );
  }
}
