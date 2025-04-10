import 'package:SeeWriteSay/models/image_model.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:SeeWriteSay/providers/reading/reading_provider.dart';
import 'package:SeeWriteSay/widgets/common_image_viewer.dart';

class ReadingScreen extends StatelessWidget {
  final String? sentence;
  final ImageModel? imageModel;

  const ReadingScreen({super.key, this.sentence, this.imageModel});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReadingProvider()
        ..initialize(sentence ?? '', imageModel: imageModel),
      child: const ReadingContent(),
    );
  }
}

class ReadingContent extends StatelessWidget {
  const ReadingContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingProvider>();
    final isFromWriting = provider.sentence.isNotEmpty;
    final isFromPicture = provider.imageModel != null && provider.imageModel!.path.isNotEmpty && provider.sentence.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("리딩 연습"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            debugPrint("isFromWriting : $isFromWriting");
            debugPrint("isFromPicture : $isFromPicture");
            if (isFromWriting) {
              NavigationHelpers.goToWritingScreen(context, provider.imageModel!, sentence: provider.sentence);
            } else if (isFromPicture) {
              NavigationHelpers.goToPictureScreen(context);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isFromPicture) ...[
              CommonImageViewer(imagePath: provider.imageModel!.path, height: 200, borderRadius: 12,),
              const SizedBox(height: 8),
            ] else if (isFromWriting) ...[
              const Text("작문 완료한 문장입니다", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              Center(
                child: Text('"${provider.sentence}"',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 8),
            ],

            ElevatedButton.icon(
              onPressed: provider.isRecording ? provider.stopRecording : provider.startRecording,
              icon: Icon(provider.isRecording ? Icons.stop : Icons.mic),
              label: Text(provider.isRecording ? "중지" : "읽기 시작"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: provider.isRecording || provider.currentFilePath.isEmpty ? null : () => provider.playRecording(provider.currentFilePath),
              icon: const Icon(Icons.play_arrow),
              label: const Text("내 음성 듣기"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.indigo),
            ),
            if (provider.duration.inMilliseconds > 0) ...[
              Slider(
                value: provider.position.inMilliseconds / provider.duration.inMilliseconds,
                onChanged: (value) => provider.seekTo(value),
              ),
            ],
            const SizedBox(height: 20),
            if (provider.showResult) Text(provider.feedback),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => NavigationHelpers.goToPictureScreen(context),
              child: const Text("처음 화면으로 돌아가기"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 20),
            if (provider.recordedPaths.isNotEmpty) ...[
              const Divider(),
              const Text("녹음 히스토리"),
              ...provider.recordedPaths.asMap().entries.map((entry) {
                final fileName = entry.value;
                return ListTile(
                  title: Text(CommonLogicService.formatReadableTime(fileName), style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () async {
                          final dir = await getApplicationDocumentsDirectory();
                          final fullPath = '${dir.path}/$fileName.aac';
                          provider.playRecording(fullPath);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await provider.deleteHistoryItem(fileName);
                        },
                      ),
                    ],
                  ),
                );
              }),
            ]
          ],
        ),
      ),
    );
  }
}
