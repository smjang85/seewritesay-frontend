import 'package:SeeWriteSay/constants/api_constants.dart';
import 'package:SeeWriteSay/providers/history/history_reading_provider.dart';
import 'package:SeeWriteSay/style/text_styles.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:SeeWriteSay/widgets/common_dropdown.dart';
import 'package:SeeWriteSay/widgets/common_empty_message.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:SeeWriteSay/providers/image/image_list_provider.dart';

class HistoryReadingScreen extends StatefulWidget {
  const HistoryReadingScreen({super.key});

  @override
  State<HistoryReadingScreen> createState() => _HistoryReadingScreenState();
}

class _HistoryReadingScreenState extends State<HistoryReadingScreen> {
  late HistoryReadingProvider _provider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _provider = HistoryReadingProvider();
    _initialize();
  }

  Future<void> _initialize() async {
    final imageListProvider = context.read<ImageListProvider>();
    await _provider.initializeHistoryView(imageListProvider.images);
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
              title: const Row(
                children: [
                  Icon(Icons.edit_note),
                  SizedBox(width: 8),
                  Text("녹음 히스토리"),
                ],
              ),
            ),
            body:
                recordings.isEmpty
                    ? const CommonEmptyMessage(message: '진행한 녹음이 없습니다.')
                    : Column(
                      children: [
                        CommonDropdown(
                          label: "카테고리",
                          value: provider.selectedCategory,
                          items: provider.categories,
                          onChanged:
                              (value) => provider.setSelectedCategory(value!),
                        ),
                        CommonDropdown(
                          label: "이미지",
                          value: provider.selectedImageGroup,
                          items: imageNames,
                          onChanged:
                              (value) => provider.setSelectedImageGroup(value!),
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
                  imageModel.description?.isNotEmpty == true
                      ? imageModel.description!
                      : imageModel.name,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        // Only show the progress bar and time info if a file is selected and playing

        // 프로그레스 바는 항상 보이고, 선택 후에만 초/시간을 업데이트
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Slider(
                value:
                    provider.position.inMilliseconds
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
                  // 파일이 재생 중일 때만 초와 시간을 표시하도록 조건 추가
                  Text(
                    provider.currentFile != null &&
                            provider.duration.inMilliseconds > 0
                        ? _formatTime(provider.position)
                        : '00:00', // 재생되지 않으면 00:00을 표시
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    provider.currentFile != null &&
                            provider.duration.inMilliseconds > 0
                        ? _formatTime(provider.duration)
                        : '00:00', // 전체 시간도 동일하게 표시
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...files.map((fileName) {
          final formattedTime = CommonLogicService.extractRecordingTimestamp(
            fileName,
          );

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
                onPressed:
                    () async => await provider.deleteHistoryItem(fileName),
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
