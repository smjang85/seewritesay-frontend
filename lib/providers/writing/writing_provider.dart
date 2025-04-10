import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
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
  String grade = '';

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
    isTextEditable = true;
    if (initialSentence != null) {
      textController.text = initialSentence!;
    }

    notifyListeners();

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ 피드백 횟수를 모두 사용했어요.")));
      return;
    }

    final shouldSave = await WritingLogicService.confirmOverwriteDialog(
      context,
    );
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
      grade = result['grade'] ?? '';
      feedbackShown = true;
      hasReceivedFeedback = true;
      remainingFeedback--;
    } catch (e) {
      debugPrint("❌ GPT 오류 발생: $e");
      CommonLogicService.showErrorSnackBar(context, e);

    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _resetFeedback() {
    correctedText = '';
    feedback = '';
    grade = '';
    feedbackShown = false;
    hasReceivedFeedback = false;
    notifyListeners();
  }

  void applyCorrection() {
    textController.text = cleanedCorrection;
    _resetFeedback();
  }

  Future<void> openHistory(BuildContext context) async {
    final result = await NavigationHelpers.openHistoryWritingAndReturn(
      context,
      imageId: imageModel?.id,
    );

    if (result != null) {
      textController.text = result['sentence'] ?? '';
      _resetFeedback();
    }
  }

// WritingProvider.dart 안에
  void goToReading(BuildContext context) {
    final image = imageModel;
    if (image == null) return;

    final currentSentence = textController.text.trim();
    debugPrint("goToReading currentSentence $currentSentence");
    NavigationHelpers.goToReadingScreen(
      context,
      sentence: currentSentence,
      imageModel: imageModel!
    );
  }

  void resetFeedback() {
    isTextEditable = true;
    correctedText = '';
    feedback = '';
    feedbackShown = false;
    hasReceivedFeedback = false;
    notifyListeners();
  }


  bool isTextEditable = true; // 추가

  void applyCorrectionWithDialog(BuildContext context) {
    // ✅ 등급이 F가 아니고, 수정문장이 없는 경우 -> 현재 문장 그대로 리딩
    if (grade != 'F' && cleanedCorrection.isEmpty) {
      isTextEditable = false;
      notifyListeners();

      CommonLogicService.showConfirmAndNavigate(
        context: context,
        title: "리딩 연습",
        content: "리딩 연습하기로 넘어가겠습니까?",
        onConfirm: () => goToReading(context),
      );
      return;
    }

    // 일반적인 피드백 반영 흐름
    textController.text = cleanedCorrection;
    isTextEditable = false; // 인풋 비활성화
    notifyListeners();

    CommonLogicService.showConfirmAndNavigate(
      context: context,
      title: "리딩 연습",
      content: "리딩 연습하기로 넘어가겠습니까?",
      onConfirm: () => goToReading(context),
    );
  }


  Color gradeColor(String grade) {
    if (grade == "A+" || grade == "A" || grade == "A-") return Colors.green;
    if (grade.startsWith("B")) return Colors.teal;
    if (grade.startsWith("C")) return Colors.orange;
    if (grade == "D") return Colors.redAccent;
    return Colors.red;
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
