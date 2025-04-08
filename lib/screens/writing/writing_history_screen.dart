import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:SeeWriteSay/providers/writing/writing_history_provider.dart';
import 'package:SeeWriteSay/models/image_model.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WritingHistoryScreen extends StatelessWidget {
  final int? imageId;

  const WritingHistoryScreen({super.key, this.imageId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
      WritingHistoryProvider(imageId: imageId)
        ..loadHistory(),
      child: const WritingHistoryContent(),
    );
  }
}


class WritingHistoryContent extends StatelessWidget {
  const WritingHistoryContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WritingHistoryProvider>();
    final writingHistory = provider.history;

    return Scaffold(
      appBar: AppBar(title: const Text("✍️ 작문 히스토리")),
      body: writingHistory.isEmpty
          ? const Center(child: Text("저장된 작문이 없어요."))
          : ListView.separated(
        itemCount: writingHistory.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = writingHistory[index];
          final thumbnail = entry['imagePath'] ?? '';
          final description = entry['imageDescription'] ?? '';
          final shortDesc = description.length > 30
              ? '${description.substring(0, 30)}...'
              : description;

          return ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: '${ApiConstants.baseUrl}$thumbnail',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) =>
                const Icon(Icons.image_not_supported, size: 48),
              ),
            ),
            title: Text(
              entry['sentence'] ?? '',
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
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    CommonLogicService.formatDateTime(entry['timestamp'] ?? ''),
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
                  builder: (context) =>
                      AlertDialog(
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
                builder: (context) =>
                    AlertDialog(
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
                    id: entry['imageId'],
                    path: entry['imagePath'],
                    name: entry['imageName'],
                    description: entry['imageDescription'],
                  ),
                  sentence: entry['sentence'],
                );
              }
            },
          );
        },
      ),
    );
  }
}
