import 'package:flutter/material.dart';
import 'package:see_write_say/features/story/api/story_api_service.dart';
import 'package:see_write_say/features/story/dto/story_dto.dart';

class StoryMainProvider extends ChangeNotifier {
  List<StoryDto> _stories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<StoryDto> get stories => _stories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 스토리 목록 조회
  Future<void> fetchStories({String lang = 'ko'}) async {
    _setLoading(true);
    try {
      _stories = await StoryApiService.fetchStories(lang: lang);

      debugPrint("fetchStories _stories : ${_stories}");
      _errorMessage = null;
    } catch (e, stackTrace) {
      debugPrint("❌ fetchStories 실패: $e");
      debugPrint("📛 stacktrace: $stackTrace");
      _errorMessage = "스토리를 불러오는데 실패했습니다.";
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clear() {
    _stories = [];
    _errorMessage = null;
    notifyListeners();
  }
}
