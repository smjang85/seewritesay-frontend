import 'package:see_write_say/core/presentation/helpers/snackbar_helper.dart';
import 'package:see_write_say/features/image/dto/image_dto.dart';
import 'package:see_write_say/features/writing/api/writing_api_service.dart';
import 'package:see_write_say/core/presentation/dialog/dialog_popup_helper.dart';
import 'package:see_write_say/core/helpers/system/navigation_helpers.dart';
import 'package:flutter/material.dart';
import 'package:see_write_say/features/writing/logic/writing_locic_service.dart';

class WritingProvider extends ChangeNotifier {
  final ImageDto? imageDto;
  final String? initialSentence;

  WritingProvider(this.imageDto, {this.initialSentence});

  final textController = TextEditingController();
  final scrollController = ScrollController();
  final feedbackKey = GlobalKey();

  String correctedText = '';
  String feedback = '';
  String grade = '';

  bool feedbackShown = false;
  bool isLoading = false;
  bool hasReceivedFeedback = false;

  int _writingRemainingCount = -1;
  final int maxLength = 300;

  String get cleanedCorrection => WritingLogicService.cleanCorrection(correctedText);

  final focusNode = FocusNode();

  String get feedbackWritingRemainingCount {
    if (_writingRemainingCount == -1) return '조회중';
    if (_writingRemainingCount == 0) return '오늘은 완료';
    return '$_writingRemainingCount회 남음';
  }
  bool _shouldUnfocusOnInit = false;
  Future<void> initialize(BuildContext context) async {
    debugPrint("initialSentence : $initialSentence");
    isTextEditable = true;
    if (initialSentence != null) {
      textController.text = initialSentence!;
    }

    if (_shouldUnfocusOnInit) {
      FocusScope.of(context).unfocus();
      _shouldUnfocusOnInit = false; // 한번만
    }

    focusNode.unfocus();

    notifyListeners();

    await _loadFeedbackLimit(context);
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

  Future<void> _loadFeedbackLimit(BuildContext context) async {
    try {
      final imageId = (imageDto?.id is int) ? imageDto!.id : 0;
      final counts = await WritingApiService.fetchRemainingCounts(imageId);
      _writingRemainingCount = counts.writingRemainingCount;
      notifyListeners();
    } catch (e) {
      debugPrint("❌ 피드백 횟수 조회 실패: $e");
    }
  }


  Future<void> saveHistory(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final shouldSave = await WritingLogicService.confirmOverwriteDialog(
      context,
    );

    if (shouldSave) {
      final userText = textController.text.trim();
      if (userText.isEmpty || userText.length > maxLength) return;

      await WritingLogicService.saveHistory(userText, grade, imageDto?.id ?? 0);
    }
    focusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  Future<void> getAIFeedback(BuildContext context) async {
    focusNode.unfocus();
    final userText = textController.text.trim();
    if (userText.isEmpty || userText.length > maxLength) return;

    if (_writingRemainingCount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ 피드백 횟수를 모두 사용했어요.")));
      return;
    }



    // AI 피드백 진행 전에 사용자에게 피드백 여부를 묻는 알럿 메시지
    final shouldProceed = await DialogPopupHelper.confirmDialog(
      context: context,
      title: "AI 피드백 진행",
      content: "AI 피드백 횟수가 차감됩니다. 진행하시겠습니까?", // 새로운 알럿 문구
      cancelButtonText: "취소", // 취소 버튼 텍스트
      confirmButtonText: "진행", // 확인 버튼 텍스트
    );

    if (!shouldProceed) return; // 취소 시 리턴하여 피드백 진행하지 않음


    _resetFeedback();
    isLoading = true;
    notifyListeners();

    try {
      final imageId = (imageDto?.id is int) ? imageDto!.id : 0;
      final result = await WritingApiService.fetchAIWriteFeedback(userText, imageId,);
      await WritingApiService.decreaseWritingFeedbackCount(imageId);

      correctedText = result['correction'] ?? '';
      feedback = result['feedback'] ?? '';
      grade = result['grade'] ?? '';
      feedbackShown = true;
      hasReceivedFeedback = true;
      _writingRemainingCount--;
    } catch (e) {
      debugPrint("❌ GPT 오류 발생: $e");
      SnackbarHelper.showError(context, e);

    } finally {
      isLoading = false;
      FocusScope.of(context).unfocus();
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
    focusNode.unfocus();

    final result = await NavigationHelpers.openHistoryWritingAndReturn(
      context,
      imageId: imageDto?.id,
    );

    if (result != null) {
      textController.text = result['sentence'] ?? '';
      _resetFeedback();
    }
  }

// WritingProvider.dart 안에
  void goToReading(BuildContext context) {
    focusNode.unfocus();

    final image = imageDto;
    if (image == null) return;

    final currentSentence = textController.text.trim();
    debugPrint("goToReading currentSentence $currentSentence");
    NavigationHelpers.goToReadingScreen(
        context,
        sentence: currentSentence,
        imageDto: imageDto!
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

      FocusScope.of(context).unfocus();
      isTextEditable = false;
      notifyListeners();

      DialogPopupHelper.showConfirmAndNavigate(
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
    FocusScope.of(context).unfocus();
    notifyListeners();

    DialogPopupHelper.showConfirmAndNavigate(
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
    focusNode.dispose();
    super.dispose();
  }
}
