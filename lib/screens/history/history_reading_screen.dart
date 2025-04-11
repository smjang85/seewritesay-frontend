import 'package:SeeWriteSay/constants/api_constants.dart';
import 'package:SeeWriteSay/providers/history/history_reading_provider.dart';
import 'package:SeeWriteSay/style/text_styles.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:SeeWriteSay/widgets/common_appbar.dart';
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<HistoryReadingProvider>(
        builder: (context, provider, _) {
          final recordings = provider.groupedRecordings;
          final imageNames = recordings.keys.toList();

          // 선택된 이미지 그룹 자동 설정
          if (provider.selectedImageGroup.isEmpty && recordings.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.setSelectedImageGroup(imageNames.first);
            });
          }

          return Scaffold(
            appBar: CommonAppBar(
              title: "녹음 히스토리",
              leadingIcon: Icons.record_voice_over,
              onLeadingTap: () => NavigationHelpers.goToPictureScreen(context),
            ),

            body: recordings.isEmpty
                ? const CommonEmptyMessage(message: '진행한 녹음이 없습니다.')
                : Column(
              children: [
                CommonDropdown(
                  label: "카테고리",
                  value: provider.selectedCategory,
                  items: provider.categories,
                  onChanged: (value) => provider.setSelectedCategory(value!),
                ),
                CommonDropdown(
                  label: "이미지",
                  value: provider.selectedImageGroup,
                  items: imageNames,
                  onChanged: (value) => provider.setSelectedImageGroup(value!),
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
                  softWrap: true,          // 줄바꿈 허용
                  overflow: TextOverflow.visible, // 오버플로 생략 없이 그대로 표시
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        ...files.map((fileName) {
          debugPrint("fileName : $fileName");
          final formattedTime = CommonLogicService.extractRecordingTimestamp(fileName);
          debugPrint("formattedTime : $fileName");

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () async {
                  await provider.deleteHistoryItem(fileName);
                },
              ),
              title: Text(formattedTime, style: kTimestampTextStyle,),
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
