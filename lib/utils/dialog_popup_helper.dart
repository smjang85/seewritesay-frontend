import 'dart:async';
import 'dart:convert';

import 'package:SeeWriteSay/dto/ai_reading_feeback_response_dto.dart';
import 'package:flutter/material.dart';
import 'package:SeeWriteSay/services/api/feedback/ai_feedback_api_service.dart';
import 'package:SeeWriteSay/services/logic/common/common_logic_service.dart';
import 'package:confetti/confetti.dart';

class DialogPopupHelper {
  /// 뒤로가기 및 외부 클릭 방지 팝업 (확인 버튼만 있는 타입)
  static Future<void> showBlockingDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  child: Text(confirmText),
                ),
              ],
            ),
          ),
    );
  }

  static Future<void> evaluatePronunciationDialog({
    required BuildContext context,
    required String filePath,
  }) async {
    final confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    try {
      final data = await AiFeedbackApiService.fetchAIReadingFeedback(filePath);
      final feedback = AiReadingFeedbackResponseDto.fromJson(data);

      // 평균 점수 계산
      final double avgScore =
          (feedback.accuracyScore +
              feedback.fluencyScore +
              feedback.completenessScore +
              feedback.pronScore) /
          4;

      // 평균 점수가 90 이상일 때 이펙트 발동
      if (avgScore >= 90) confettiController.play();

      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "닫기",
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "AI 발음 평가 결과",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: "📌 AI가 인식한 문장:\n"),
                              TextSpan(
                                text: '"${feedback.sentenceFromFile}"',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "🎙️ 신뢰도: ${(feedback.confidence * 100).toStringAsFixed(1)}%",
                        ),
                        const Divider(),
                        _scoreRow("🎯 정확도", feedback.accuracyScore),
                        _scoreRow("💬 유창성", feedback.fluencyScore),
                        _scoreRow("🧩 완성도", feedback.completenessScore),
                        _scoreRow("🔊 운율점수", feedback.pronScore),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("확인"),
                        ),
                      ],
                    ),
                  ),
                  ConfettiWidget(
                    confettiController: confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        transitionBuilder: (context, anim1, anim2, child) {
          return Transform.scale(
            scale: anim1.value,
            child: Opacity(opacity: anim1.value, child: child),
          );
        },
      );
    } catch (e) {
      debugPrint("❌ 발음 피드백 에러: $e");
      showErrorDialog(context, e);
    } finally {
      confettiController.dispose();
    }
  }

  static Widget _scoreRow(String label, double score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static Future<void> showConfirmAndNavigate({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context);
                },
                child: const Text("아니요"),
              ),
              ElevatedButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context);
                  onConfirm();
                },
                child: const Text("네"),
              ),
            ],
          ),
    );
  }

  static Future<bool> confirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    String cancelButtonText = "취소",
    String confirmButtonText = "확인",
  }) async {
    CommonLogicService.dismissKeyboard(context);

    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(title),
                content: Text(content),
                actions: [
                  TextButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context, false);
                    },
                    child: Text(cancelButtonText),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context, true);
                    },
                    child: Text(confirmButtonText),
                  ),
                ],
              ),
        ) ??
        false;
  }

  static void showErrorDialog(BuildContext context, Object error) {
    String raw = error.toString().replaceAll('Exception: ', '');
    String msg = raw;

    try {
      final jsonStart = raw.indexOf('{');
      if (jsonStart != -1) {
        final jsonPart = raw.substring(jsonStart);
        final decoded = jsonDecode(jsonPart);
        if (decoded is Map<String, dynamic>) {
          msg = decoded['message'] ?? decoded['errorCode'] ?? raw;
        }
      }
    } catch (_) {
      msg = raw;
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("⚠️ 오류 발생"),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("확인"),
              ),
            ],
          ),
    );
  }

  static Future<void> showCountdownBlockingDialog({
    required BuildContext context,
    required int countdownSeconds,
    required VoidCallback onTimeout,
    required VoidCallback onExtend,
  }) async {
    int secondsLeft = countdownSeconds;
    late Timer timer;
    late StateSetter dialogSetState;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      secondsLeft--;
      if (secondsLeft <= 0) {
        t.cancel();
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        onTimeout();
      } else {
        dialogSetState(() {});
      }
    });

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;
            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                title: const Text("세션 연장"),
                content: Text(
                  "세션이 곧 만료됩니다.\n남은 시간: ${secondsLeft}s",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      timer.cancel();
                      Navigator.of(context).pop();
                      onExtend();
                    },
                    child: const Text("연장"),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      if (timer.isActive) timer.cancel();
    });
  }
}
