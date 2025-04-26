import 'package:flutter/foundation.dart';
import 'package:see_write_say/features/story/api/story_api_service.dart';
import 'package:see_write_say/features/story/dto/chapter_dto.dart';

class ChapterSelectionProvider extends ChangeNotifier {
  List<ChapterDto> _chapters = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _sortDescending = true;

  List<ChapterDto> get chapters {
    final sorted = List<ChapterDto>.from(_chapters);
    sorted.sort((a, b) => _sortDescending
        ? b.chapterOrder.compareTo(a.chapterOrder)
        : a.chapterOrder.compareTo(b.chapterOrder));
    return sorted;
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get sortDescending => _sortDescending;

  Future<void> fetchChapters(int storyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _chapters = await StoryApiService.fetchChapters(storyId);
    } catch (e) {
      debugPrint("❌ 챕터 불러오기 실패: $e");
      _errorMessage = "챕터를 불러오지 못했습니다.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleSort() {
    _sortDescending = !_sortDescending;
    notifyListeners();
  }

  void clear() {
    _chapters = [];
    _errorMessage = null;
    _isLoading = false;
    _sortDescending = true;
    notifyListeners();
  }
}
