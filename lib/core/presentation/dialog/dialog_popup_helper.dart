import 'dart:async';
import 'dart:convert';

import 'package:see_write_say/core/helpers/system/keyboard_helper.dart';
import 'package:see_write_say/features/reading/dto/ai_reading_feeback_dto.dart';
import 'package:see_write_say/features/reading/api/reading_api_service.dart';
import 'package:flutter/material.dart';
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
    required int imageId,
    String? sentence
  }) async {
    final confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    try {
      final data = await ReadingApiService.fetchAIReadingFeedback(filePath, imageId, sentence);
      final feedback = AiReadingFeedbackDto.fromJson(data);

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
    KeyboardHelper.dismiss(context);

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
    String msg = '알 수 없는 오류가 발생했습니다.';

    // 디버깅용 로그 출력
    debugPrint("❌ 오류 상세: $raw");

    try {
      // 401 인증 오류 메시지 커스텀 처리
      if (raw.contains("status code of 401")) {
        msg = '🔐 로그인 인증이 만료되었거나 잘못되었습니다.\n다시 로그인해주세요.';
      } else if (raw.contains("Connection timed out") || raw.contains("SocketException")) {
        msg = '⏱️ 서버에 연결할 수 없습니다.\n인터넷 연결을 확인해주세요.';
      } else {
        final jsonStart = raw.indexOf('{');
        if (jsonStart != -1) {
          final jsonPart = raw.substring(jsonStart);
          final decoded = jsonDecode(jsonPart);
          if (decoded is Map<String, dynamic>) {
            msg = decoded['message'] ?? decoded['errorCode'] ?? raw;
          }
        } else {
          msg = raw;
        }
      }
    } catch (_) {
      // JSON 파싱 실패 시 기존 메시지 유지
      msg = raw;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
    final ValueNotifier<int> secondsLeft = ValueNotifier(countdownSeconds);
    Timer? timer;

    void startTimer() {
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (secondsLeft.value <= 1) {
          t.cancel();
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          onTimeout();
        } else {
          secondsLeft.value -= 1;
        }
      });
    }

    startTimer();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _RotatingHourglass(),
                SizedBox(width: 8),
                Text(
                  "세션 연장",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            content: ValueListenableBuilder<int>(
              valueListenable: secondsLeft,
              builder: (_, value, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "세션이 곧 만료됩니다.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "남은 시간: ${value}s",
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.of(dialogContext).pop();
                  onExtend();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "세션 연장하기",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      timer?.cancel();
      secondsLeft.dispose();
    });


  }



  /// 공통 로딩 다이얼로그
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _RotatingHourglass extends StatefulWidget {
  const _RotatingHourglass();

  @override
  State<_RotatingHourglass> createState() => _RotatingHourglassState();
}

class _RotatingHourglassState extends State<_RotatingHourglass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut, // 부드럽고 자연스러운 회전 커브
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: animation,
      child: const Text(
        "⏳",
        style: TextStyle(fontSize: 26),
      ),
    );
  }
}
