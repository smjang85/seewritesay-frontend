import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_write_say/core/presentation/theme/text_styles.dart';
import 'package:see_write_say/features/image/dto/image_dto.dart';
import 'package:see_write_say/core/helpers/system/navigation_helpers.dart';
import 'package:see_write_say/core/presentation/components/common/common_image_viewer.dart';
import 'package:see_write_say/features/writing/providers/writing_provider.dart';

class WritingScreen extends StatelessWidget {
  final ImageDto? imageDto;
  final String? initialSentence;

  const WritingScreen({super.key, this.imageDto, this.initialSentence});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WritingProvider(
        imageDto,
        initialSentence: initialSentence,
      )..initialize(context),
      child: const WritingScreenContent(),
    );
  }
}

class WritingScreenContent extends StatelessWidget {
  const WritingScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WritingProvider>();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isWellWritten = provider.cleanedCorrection == provider.textController.text.trim();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationHelpers.goToPictureScreen(context),
        ),
        title: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: '작문 연습', style: kHeadingTextStyle),
              TextSpan(
                text: '(${provider.feedbackWritingRemainingCount})',
                style: kSubtitleTextStyle,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => provider.openHistory(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: provider.scrollController,
            padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardHeight + 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.imageDto != null) ...[
                  CommonImageViewer(
                    imagePath: provider.imageDto!.path,
                    height: 200,
                    borderRadius: 16,
                  ),
                  const SizedBox(height: 20),
                ],
                TextField(
                  controller: provider.textController,
                  focusNode: provider.focusNode,
                  autofocus: false,
                  maxLength: provider.maxLength,
                  maxLines: 5,
                  enabled: provider.isTextEditable,
                  decoration: InputDecoration(
                    hintText: "이 장면에 대해 영어로 이야기해보세요.",
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.indigo, width: 2),
                    ),
                  ),
                  onTap: provider.feedbackShown ? provider.resetFeedback : null,
                ),
                if (provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (provider.feedbackShown && !provider.isLoading) ...[
                  const SizedBox(height: 30),
                  Text("💬 AI 피드백", style: kHeadingTextStyle, key: provider.feedbackKey),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isWellWritten) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.emoji_emotions, color: Colors.green),
                                SizedBox(width: 8),
                                Text("참 잘했어요!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ] else ...[
                          const Text("📝 수정 제안:", style: kBodyTextStyle),
                          const SizedBox(height: 4),
                          Text(provider.correctedText, style: const TextStyle(color: Colors.indigo)),
                          const SizedBox(height: 12),
                          const Text("🔍 피드백:", style: kBodyTextStyle),
                          const SizedBox(height: 4),
                          Text(provider.feedback),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text("📊 등급: ", style: kBodyTextStyle),
                              Text(
                                provider.grade,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: provider.gradeColor(provider.grade),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!isWellWritten)
                        provider.grade == "F"
                            ? OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text("다시 작성하기"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: provider.resetFeedback,
                        )
                            : OutlinedButton.icon(
                          icon: const Icon(Icons.edit_note),
                          label: const Text("Ai 적용 후 읽기 연습하기"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.indigo,
                            side: const BorderSide(color: Colors.indigo),
                          ),
                          onPressed: () => provider.applyCorrectionWithDialog(context),
                        ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("작문내역 저장"),
                        onPressed: () => provider.saveHistory(context),
                      ),
                      ElevatedButton(
                        child: const Text("읽기 연습하기"),
                        onPressed: provider.grade == "F"
                            ? null
                            : () => provider.goToReading(context),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!provider.feedbackShown)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text("AI 피드백 받기"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: provider.isLoading ? null : () => provider.getAIFeedback(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WritingScreenArgs {
  final ImageDto image;
  final String? sentence;

  WritingScreenArgs({required this.image, this.sentence});
}