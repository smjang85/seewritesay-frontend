import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:SeeWriteSay/constants/api_constants.dart';
import 'package:SeeWriteSay/models/image_model.dart';
import 'package:SeeWriteSay/providers/writing/writing_provider.dart';

class WritingScreen extends StatelessWidget {
  final ImageModel? imageModel;
  final String? initialSentence;

  const WritingScreen({super.key, this.imageModel, this.initialSentence});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => WritingProvider(imageModel, initialSentence: initialSentence)..initialize(),

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

    return Scaffold(
      appBar: AppBar(
        title: Text("작문 연습 (${provider.feedbackRemainingText})"),
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
                if (provider.imageModel != null) ...[
                  Center(
                    child: CachedNetworkImage(
                      imageUrl: '${ApiConstants.baseUrl}${provider.imageModel!.path}',
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image, size: 100),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                TextField(
                  controller: provider.textController,
                  maxLength: provider.maxLength,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: "이 장면에 대해 영어로 이야기해보세요.",
                    border: OutlineInputBorder(),
                  ),
                  onTap: provider.feedbackShown ? provider.resetFeedback : null,
                ),
                if (provider.isLoading) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (provider.feedbackShown && !provider.isLoading) ...[
                  const SizedBox(height: 30),
                  Text(
                    "💬 AI 피드백",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    key: provider.feedbackKey,
                  ),
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
                        if (provider.cleanedCorrection ==
                            provider.textController.text.trim()) ...[
                          const Text(
                            "🎉 잘 작문했어요!",
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                        ] else ...[
                          const Text(
                            "📝 수정 제안:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            provider.correctedText,
                            style: const TextStyle(color: Colors.indigo),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "🔍 피드백:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(provider.feedback),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_note),
                        label: const Text("피드백 반영"),
                        onPressed: provider.applyCorrection,
                      ),
                      ElevatedButton(
                        child: const Text("리딩 연습하기"),
                        onPressed: () => provider.goToReading(context),
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
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text("AI 피드백 받기"),
                  onPressed: provider.isLoading
                      ? null
                      : () => provider.getAIFeedback(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WritingScreenArgs {
  final ImageModel image;
  final String? sentence;

  WritingScreenArgs({
    required this.image,
    this.sentence,
  });
}