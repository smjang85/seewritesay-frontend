import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:see_write_say/core/helpers/system/keyboard_helper.dart';
import 'package:see_write_say/features/reading/dto/ai_reading_feeback_dto.dart';
import 'package:see_write_say/features/reading/api/reading_api_service.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:permission_handler/permission_handler.dart';
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
    String? sentence,
  }) async {
    final confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    try {
      final data = await ReadingApiService.fetchAIReadingFeedback(
        filePath,
        imageId,
        sentence,
      );
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
                          "AI 읽기 피드백",
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
                          "🎙️ AI가 얼마나 확신했는지: ${(feedback.confidence * 100).toStringAsFixed(1)}%",
                        ),
                        const Divider(),
                        _scoreRow("🎯 정확도", feedback.accuracyScore),
                        _scoreRow("💬 유창성", feedback.fluencyScore),
                        _scoreRow("🧩 완성도", feedback.completenessScore),
                        _scoreRow("🔊 리듬/억양", feedback.pronScore),
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
    String msg = '알 수 없는 오류가 발생했습니다.';
    String raw = error.toString().replaceAll('Exception: ', '');

    debugPrint("❌ 오류 상세: $raw");

    try {
      if (error is DioException) {
        final statusCode = error.response?.statusCode;

        // ✅ 상태코드 기반 에러 메시지
        switch (statusCode) {
          case 500:
            msg = '🚨 서버 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
            break;
          case 404:
            msg = '🔍 요청한 정보를 찾을 수 없습니다.';
            break;
          case 401:
            msg = '🔐 로그인 인증이 만료되었거나 잘못되었습니다.\n다시 로그인해주세요.';
            break;
          case 403:
            msg = '⛔ 접근 권한이 없습니다.';
            break;
          case 408:
            msg = '⏱ 요청 시간이 초과되었습니다.\n인터넷 연결을 확인해주세요.';
            break;
          default:
          // 서버가 커스텀 메시지를 줄 수 있음
            final data = error.response?.data;
            if (data is Map<String, dynamic>) {
              msg = data['message'] ?? data['errorCode'] ?? msg;
            }
        }
      } else if (raw.contains("Connection timed out") ||
          raw.contains("SocketException")) {
        msg = '📡 네트워크 연결에 실패했습니다.\n인터넷을 확인해주세요.';
      } else {
        // 혹시 JSON 문자열이 있다면 파싱 시도
        final jsonStart = raw.indexOf('{');
        if (jsonStart != -1) {
          final jsonPart = raw.substring(jsonStart);
          final decoded = jsonDecode(jsonPart);
          if (decoded is Map<String, dynamic>) {
            msg = decoded['message'] ?? decoded['errorCode'] ?? msg;
          }
        } else {
          msg = raw;
        }
      }
    } catch (e) {
      debugPrint("⚠️ 오류 메시지 파싱 실패: $e");
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            content: ValueListenableBuilder<int>(
              valueListenable: secondsLeft,
              builder:
                  (_, value, __) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("세션이 곧 만료됩니다.", textAlign: TextAlign.center),
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
                child: const Text("세션 연장하기", style: TextStyle(fontSize: 16)),
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

  /// 마이크 등 시스템 권한 요청 후 '설정 열기' 안내 다이얼로그
  static Future<void> showPermissionDeniedDialog({
    required BuildContext context,
    String title = '권한 필요',
    String content = '이 기능을 사용하려면 권한이 필요합니다.\n설정에서 권한을 허용해주세요.',
    String confirmText = '설정 열기',
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings(); // 시스템 설정 앱 열기
            },
            child: Text(confirmText),
          ),
        ],
      ),
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
      child: const Text("⏳", style: TextStyle(fontSize: 26)),
    );
  }
}
