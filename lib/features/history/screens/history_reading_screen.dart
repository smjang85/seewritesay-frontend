import 'package:see_write_say/app/constants/api_constants.dart';
import 'package:see_write_say/core/helpers/format/format_helper.dart';
import 'package:see_write_say/core/helpers/system/navigation_helpers.dart';
import 'package:see_write_say/core/presentation/components/common_dropdown.dart';
import 'package:see_write_say/core/presentation/components/common_empty_message.dart';
import 'package:see_write_say/core/presentation/theme/text_styles.dart';
import 'package:see_write_say/features/history/providers/history_reading_provider.dart';
import 'package:see_write_say/features/image/providers/image_list_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HistoryReadingScreen extends StatefulWidget {
  const HistoryReadingScreen({super.key});

  @override
  State<HistoryReadingScreen> createState() => _HistoryReadingScreenState();
}

class _HistoryReadingScreenState extends State<HistoryReadingScreen> {
  late HistoryReadingProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = HistoryReadingProvider();
    _initialize();
  }

  Future<void> _initialize() async {
    final imageListProvider = context.read<ImageListProvider>();
    await _provider.initializeHistoryView(imageListProvider.images);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<HistoryReadingProvider>(
        builder: (context, provider, _) {
          final recordings = provider.groupedRecordings;
          final imageNames = recordings.keys.toList();

          if (provider.selectedImageGroup.isEmpty && recordings.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.setSelectedImageGroup(imageNames.first);
            });
          }

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => NavigationHelpers.goToPictureScreen(context),
              ),
              title: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '이전 녹음내역', style: kHeadingTextStyle),
                  ],
                ),
              ),
            ),
            body: recordings.isEmpty
                ? const CommonEmptyMessage(message: '진행한 녹음이 없습니다.')
                : Column(
              children: [
                CommonDropdown(
                  label: "카테고리",
                  value: provider.selectedCategory,
                  items: provider.categories,
                  onChanged: (value) =>
                      provider.setSelectedCategory(value!),
                ),
                CommonDropdown(
                  label: "이미지",
                  value: provider.selectedImageGroup,
                  items: imageNames,
                  onChanged: (value) =>
                      provider.setSelectedImageGroup(value!),
                ),
                Expanded(child: _buildGroupedList(provider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupedList(HistoryReadingProvider provider) {
    final selected = provider.selectedImageGroup;
    final files = provider.groupedRecordings[selected] ?? [];
    final imageDto = provider.imageDtoMap[selected];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (imageDto != null)
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: '${ApiConstants.baseUrl}${imageDto.path}',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  imageDto.description?.isNotEmpty == true
                      ? imageDto.description!
                      : imageDto.name,
                  style: kSubtitleTextStyle,
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Slider(
                value: provider.position.inMilliseconds
                    .clamp(0, provider.duration.inMilliseconds.toDouble())
                    .toDouble(),
                max: provider.duration.inMilliseconds.toDouble(),
                onChanged: (value) {
                  provider.seekTo(Duration(milliseconds: value.toInt()));
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    provider.currentFile != null &&
                        provider.duration.inMilliseconds > 0
                        ? _formatTime(provider.position)
                        : '00:00',
                    style: kTimestampTextStyle,
                  ),
                  Text(
                    provider.currentFile != null &&
                        provider.duration.inMilliseconds > 0
                        ? _formatTime(provider.duration)
                        : '00:00',
                    style: kTimestampTextStyle,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...files.map((fileName) {
          final formattedTime =
          FormatHelper.extractRecordingTimestamp(fileName);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              onTap: () {
                setState(() {
                  provider.setSelectedImageGroup(fileName);
                });
              },
              leading: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () async =>
                await provider.deleteHistoryItem(fileName),
              ),
              title: Text(formattedTime, style: kTimestampTextStyle),
              trailing: Consumer<HistoryReadingProvider>(
                builder: (context, provider, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          provider.isPausedFile(fileName)
                              ? Icons.play_arrow
                              : provider.isPlayingFile(fileName)
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        onPressed: () => provider.playRecording(fileName),
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: () => provider.stopPlayback(),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatTime(Duration duration) {
    final seconds = duration.inSeconds;
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
