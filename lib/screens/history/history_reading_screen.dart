import 'package:SeeWriteSay/constants/api_constants.dart';
import 'package:SeeWriteSay/providers/history/history_reading_provider.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:SeeWriteSay/providers/image/image_list_provider.dart';

class HistoryReadingScreen extends StatelessWidget {
  const HistoryReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageListProvider>(
      builder: (context, imageListProvider, _) {
        return ChangeNotifierProvider(
          create: (_) {
            final provider = HistoryReadingProvider();
            provider.initializeHistoryView(imageListProvider.images);
            return provider;
          },
          child: Consumer<HistoryReadingProvider>(
            builder: (context, provider, _) {
              final recordings = provider.groupedRecordings;
              final imageNames = recordings.keys.toList();

              // `selectedImageGroup`이 빈 문자열일 경우 자동으로 첫 번째 항목을 설정
              if (provider.selectedImageGroup.isEmpty &&
                  recordings.isNotEmpty) {
                provider.setSelectedImageGroup(imageNames.first);
              }

              return Scaffold(
                // 두 번째 AppBar
                appBar: AppBar(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.record_voice_over,

                      ),
                      const SizedBox(width: 8), // 아이콘과 텍스트 사이 간격
                      const Text(
                        "녹음 히스토리",
                        style: TextStyle(
                          fontSize: 20, // 텍스트 크기 맞추기
                        ),
                      ),
                    ],
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed:
                        () => NavigationHelpers.goToPictureScreen(context),
                  ),
                ),

                body:
                    recordings.isEmpty
                        ? const Center(child: Text("저장된 녹음이 없어요"))
                        : Column(
                          children: [
                            // 카테고리 드롭다운
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8,
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: provider.selectedCategory,
                                onChanged: (value) {
                                  if (value != null) {
                                    provider.setSelectedCategory(value);
                                  }
                                },
                                items:
                                    provider.categories
                                        .map(
                                          (cat) => DropdownMenuItem(
                                            value: cat,
                                            child: Text(
                                              cat,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),

                            // 이미지 그룹 드롭다운
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8,
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: provider.selectedImageGroup,
                                onChanged: (value) {
                                  if (value != null) {
                                    provider.setSelectedImageGroup(value);
                                  }
                                },
                                items:
                                    imageNames
                                        .map(
                                          (imageName) => DropdownMenuItem(
                                            value: imageName,
                                            child: Text(
                                              imageName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                            Expanded(child: _buildGroupedList(provider)),
                          ],
                        ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupedList(HistoryReadingProvider provider) {
    final selected = provider.selectedImageGroup;
    final files = provider.groupedRecordings[selected] ?? [];
    final imageModel = provider.imageModelMap[selected];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (imageModel != null)
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: '${ApiConstants.baseUrl}${imageModel.path}',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  imageModel.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        ...files.map((fileName) {
          final formattedTime = CommonLogicService.formatReadableTime(fileName);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () async {
                  await provider.deleteHistoryItem(fileName);
                },
              ),
              title: Text(formattedTime),
              trailing: IconButton(
                icon: Icon(
                  provider.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.indigo,
                ),
                onPressed: () => provider.playRecording(fileName),
              ),
            ),
          );
        }),
      ],
    );
  }
}
