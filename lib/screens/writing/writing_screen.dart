
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:SeeWriteSay/constants/api_constants.dart';
import 'package:SeeWriteSay/models/image_model.dart';

class WritingScreen extends StatefulWidget {
  final ImageModel? imageModel;

  const WritingScreen({super.key, this.imageModel});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _feedbackKey = GlobalKey();

  String _correctedText = '';
  String _feedback = '';
  bool _feedbackShown = false;
  bool _isLoading = false;
  bool _hasHistory = false;
  bool _hasReceivedFeedback = false;

  int _remainingFeedback = 999;
  final int _maxLength = 300;

  String get _cleanedCorrection =>
      _correctedText.replaceAll(RegExp(r'^\d+\.\s*'), '');

  @override
  void initState() {
    super.initState();
    _checkHistory();
    _loadFeedbackLimit();
    _controller.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (_hasReceivedFeedback) {
      setState(() {
        _feedbackShown = false;
        _correctedText = '';
        _feedback = '';
        _hasReceivedFeedback = false;
      });
    }
  }

  void _resetFeedback() {
    setState(() {
      _correctedText = '';
      _feedback = '';
      _feedbackShown = false;
      _hasReceivedFeedback = false;
    });
  }

  void _getAIFeedback() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty || userText.length > _maxLength) return;

    if (_remainingFeedback <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ 피드백 횟수를 모두 사용했어요.")),
      );
      return;
    }

    final shouldSave = await _showOverwriteDialog();
    if (shouldSave) {
      await saveWritingHistory(userText, widget.imageModel?.path ?? '');
    }

    FocusScope.of(context).unfocus();
    _resetFeedback();
    setState(() => _isLoading = true);

    try {
      final result = await fetchAIFeedback(userText, widget.imageModel?.name ?? '');
      setState(() {
        _correctedText = result['correction'] ?? '';
        _feedback = result['feedback'] ?? '';
        _feedbackShown = true;
        _hasReceivedFeedback = true;
        _remainingFeedback--;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('remainingFeedbackCount', _remainingFeedback);

      await Future.delayed(Duration(milliseconds: 300));
      _scrollToFeedback();
    } catch (e) {
      debugPrint("❌ GPT 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AI 피드백 요청에 실패했어요.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, String>> fetchAIFeedback(String sentence, String imageId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception("❌ JWT 토큰 없음. 로그인 필요");

    final response = await http.post(
      Uri.parse(ApiConstants.feedbackGenerateUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'sentence': sentence, 'imageId': imageId}),
    );

    if (response.statusCode == 401) throw Exception("🔒 로그인 필요: 토큰이 없거나 만료됨");

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)); // ✅ 인코딩 문제 방지
      return {
        'correction': data['correction'] ?? sentence,
        'feedback': data['feedback'] ?? '',
      };
    } else {
      throw Exception("❌ GPT 피드백 API 실패: ${response.statusCode} ${response.body}");
    }
  }

  void _scrollToFeedback() {
    if (_feedbackKey.currentContext != null) {
      Scrollable.ensureVisible(
        _feedbackKey.currentContext!,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _openHistory() async {
    final result = await context.pushNamed(
      'history',
      queryParameters: {'imagePath': widget.imageModel?.path ?? ''},
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _controller.text = result['sentence'] ?? '';
        _resetFeedback();
      });
    }
  }

  void _goToReading() {
    final sentence = _cleanedCorrection.isNotEmpty
        ? _cleanedCorrection
        : _controller.text.trim();
    context.pushNamed('reading', queryParameters: {'text': sentence});
  }

  void _checkHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('writingHistory') ?? [];
    setState(() {
      _hasHistory = history.isNotEmpty;
    });
  }

  void _loadFeedbackLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('remainingFeedbackCount') ?? 5;
    setState(() => _remainingFeedback = count);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text("작문 연습 ($_remainingFeedback 회 남음)"),
        actions: [
          IconButton(icon: Icon(Icons.history), onPressed: _openHistory),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardHeight + 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.imageModel != null) ...[
                  Center(
                    child: Image.network(
                      '${ApiConstants.baseUrl}${widget.imageModel?.path ?? "/images/default.png"}',
                      height: 200,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.broken_image, size: 100),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Text("💡 장면 설명: ${widget.imgInfo!.imgDesc}", style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                  SizedBox(height: 20),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "✏️ 작문 입력 ${_controller.text.length} / $_maxLength",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                TextField(
                  controller: _controller,
                  maxLength: _maxLength,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "이 장면에 대해 영어로 이야기해보세요.",
                    border: OutlineInputBorder(),
                  ),
                  onTap: () {
                    if (_feedbackShown) _resetFeedback();
                  },
                ),
                if (_isLoading) ...[
                  SizedBox(height: 20),
                  Center(child: CircularProgressIndicator()),
                ],
                if (_feedbackShown && !_isLoading) ...[
                  SizedBox(height: 30),
                  Text("💬 AI 피드백", style: TextStyle(fontWeight: FontWeight.bold), key: _feedbackKey),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_cleanedCorrection == _controller.text.trim()) ...[
                          Text("🎉 잘 작문했어요!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          SizedBox(height: 12),
                        ] else ...[
                          Text("📝 수정 제안:", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(_correctedText, style: TextStyle(color: Colors.indigo)),
                          SizedBox(height: 12),
                          Text("🔍 피드백:", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(_feedback),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        icon: Icon(Icons.edit_note),
                        label: Text("피드백 반영"),
                        onPressed: () {
                          setState(() {
                            _controller.text = _cleanedCorrection;
                            _feedbackShown = false;
                            _hasReceivedFeedback = false;
                          });
                        },
                      ),
                      ElevatedButton(
                        child: Text("리딩 연습하기"),
                        onPressed: _goToReading,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!_feedbackShown)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.auto_fix_high),
                  label: Text("AI 피드백 받기"),
                  onPressed: _isLoading ? null : _getAIFeedback,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> _showOverwriteDialog() async {
    FocusScope.of(context).unfocus();
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("기록을 저장할까요?"),
        content: Text("이전 작성 내용은 덮어쓰여요. 계속 진행할까요?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              FocusScope.of(context).unfocus();
            },
            child: Text("취소"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text("저장하기"),
          ),
        ],
      ),
    ) ?? false;
  }
}

Future<void> saveWritingHistory(String sentence, String imagePath) async {
  final prefs = await SharedPreferences.getInstance();
  final entry = {
    'sentence': sentence,
    'image': imagePath,
    'timestamp': DateTime.now().toIso8601String(),
  };

  List<String> history = prefs.getStringList('writingHistory') ?? [];
  history.removeWhere((item) {
    final decoded = jsonDecode(item);
    return decoded['image'] == imagePath;
  });
  history.add(jsonEncode(entry));
  await prefs.setStringList('writingHistory', history);
}
