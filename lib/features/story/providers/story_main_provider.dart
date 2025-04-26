import 'package:flutter/material.dart';
import 'package:see_write_say/features/story/api/story_api_service.dart';
import 'package:see_write_say/features/story/dto/story_dto.dart';
import 'package:see_write_say/features/story/enum/story_type.dart';

class StoryMainProvider extends ChangeNotifier {
  List<StoryDto> _stories = [];
  bool _isLoading = false;
  String? _errorMessage;

  StoryType? _selectedType; // ✅ nullable 로 변경
  String _selectedLang = 'ko';

  List<StoryDto> get stories => _stories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StoryType? get selectedType => _selectedType;
  String get selectedLang => _selectedLang;

  Future<void> fetchStories() async {
    _setLoading(true);
    try {
      _stories = await StoryApiService.fetchStories(
        lang: _selectedLang,
        type: _selectedType?.code, // ✅ null 이면 query param 안 감
      );
      debugPrint("✅ fetchStories(${_selectedType?.code}) 성공: $_stories");
      _errorMessage = null;
    } catch (e, stackTrace) {
      debugPrint("❌ fetchStories 실패: $e");
      debugPrint("📛 stacktrace: $stackTrace");
      _errorMessage = "스토리를 불러오는데 실패했습니다.";
    } finally {
      _setLoading(false);
    }
  }

  void changeLang(String lang) {
    if (_selectedLang != lang) {
      _selectedLang = lang;
      fetchStories();
    }
  }

  void changeType(StoryType? type) {
    _selectedType = type; // ✅ null도 허용
    fetchStories();
  }

  void clear() {
    _stories = [];
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
