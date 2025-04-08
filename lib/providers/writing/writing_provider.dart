import 'package:SeeWriteSay/utils/navigation_helpers.dart';
import 'package:flutter/material.dart';
import 'package:SeeWriteSay/models/image_model.dart';
import 'package:SeeWriteSay/services/api/feedback/ai_feedback_api_service.dart';
import 'package:SeeWriteSay/services/api/feedback/user_feedback_api_service.dart';
import 'package:SeeWriteSay/services/logic/writing/writing_locic_service.dart';

class WritingProvider extends ChangeNotifier {
  final ImageModel? imageModel;
  final String? initialSentence;

  WritingProvider(this.imageModel, {this.initialSentence});

  final textController = TextEditingController();
  final scrollController = ScrollController();
  final feedbackKey = GlobalKey();

  String correctedText = '';
  String feedback = '';

  bool feedbackShown = false;
  bool isLoading = false;
  bool hasReceivedFeedback = false;

  int remainingFeedback = 999;
  final int maxLength = 300;

  String get cleanedCorrection =>
      WritingLogicService.cleanCorrection(correctedText);

  String get feedbackRemainingText {
    if (remainingFeedback >= 999) return '조회중';
    if (remainingFeedback <= 0) return '오늘은 모두 사용했어요';
    return '$remainingFeedback회 남음';
  }

  Future<void> initialize() async {
    debugPrint("initialSentence : $initialSentence");
    if (initialSentence != null) {
      textController.text = initialSentence!;
      notifyListeners();
    }

    await _loadFeedbackLimit();
    textController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (hasReceivedFeedback) {
      feedbackShown = false;
      correctedText = '';
      feedback = '';
      hasReceivedFeedback = false;
      notifyListeners();
    }
  }

  Future<void> _loadFeedbackLimit() async {
    try {
      final imageId = (imageModel?.id is int) ? imageModel!.id : 0;
      final count = await UserFeedbackApiService.fetchRemainingCount(imageId);
      remainingFeedback = count;
      notifyListeners();
    } catch (e) {
      debugPrint("❌ 피드백 횟수 조회 실패: $e");
    }
  }

  Future<void> getAIFeedback(BuildContext context) async {
    final userText = textController.text.trim();
    if (userText.isEmpty || userText.length > maxLength) return;

    if (remainingFeedback <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ 피드백 횟수를 모두 사용했어요.")),
      );
      return;
    }

    final shouldSave = await WritingLogicService.confirmOverwriteDialog(context);
    if (shouldSave) {
      await WritingLogicService.saveHistory(userText, imageModel?.id ?? 0);
    }

    FocusScope.of(context).unfocus();
    _resetFeedback();
    isLoading = true;
    notifyListeners();

    try {
      final imageId = (imageModel?.id is int) ? imageModel!.id : 0;
      final result = await AiFeedbackApiService.fetchAIFeedback(
        userText,
        imageId,
      );
      await UserFeedbackApiService.decreaseFeedbackCount(imageId);

      correctedText = result['correction'] ?? '';
      feedback = result['feedback'] ?? '';
      feedbackShown = true;
      hasReceivedFeedback = true;
      remainingFeedback--;
    } catch (e) {
      debugPrint("❌ GPT 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AI 피드백 요청에 실패했어요.")),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _resetFeedback() {
    correctedText = '';
    feedback = '';
    feedbackShown = false;
    hasReceivedFeedback = false;
    notifyListeners();
  }

  void applyCorrection() {
    textController.text = cleanedCorrection;
    _resetFeedback();
  }

  Future<void> openHistory(BuildContext context) async {
    final result = await NavigationHelpers.openWritingHistoryAndReturn(
      context,
      imageId: imageModel?.id,
    );

    if (result != null) {
      textController.text = result['sentence'] ?? '';
      _resetFeedback();
    }
  }

  void goToReading(BuildContext context) {
    final sentence = cleanedCorrection.isNotEmpty
        ? cleanedCorrection
        : textController.text.trim();
    NavigationHelpers.goToReadingScreen(context, sentence);
  }

  void resetFeedback() {
    correctedText = '';
    feedback = '';
    feedbackShown = false;
    hasReceivedFeedback = false;
    notifyListeners();
  }
}
