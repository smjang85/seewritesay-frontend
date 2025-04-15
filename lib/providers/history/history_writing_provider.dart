import 'package:SeeWriteSay/dto/history_writing_response_dto.dart';
import 'package:flutter/material.dart';
import 'package:SeeWriteSay/services/api/history/history_writing_api_service.dart';

class HistoryWritingProvider extends ChangeNotifier {
  /// 카테고리 필터 기반 불러오기 여부
  final bool loadWithCategory;

  /// 특정 이미지 ID 기반 조회 (선택적)
  final int? imageId;

  /// 전체 히스토리 데이터 (카테고리 필터링 전)
  List<HistoryWritingResponseDto> _allHistory = [];

  /// 현재 필터링된 히스토리 목록
  List<HistoryWritingResponseDto> _filteredHistory = [];

  /// 외부 노출용 히스토리 getter
  List<HistoryWritingResponseDto> get history => _filteredHistory;

  /// 카테고리 관련
  List<String> _categories = ['전체'];
  String _selectedCategory = '전체';

  List<String> get categories => _categories;

  String get selectedCategory => _selectedCategory;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  /// 생성자에서 자동 로딩
  HistoryWritingProvider({this.imageId, this.loadWithCategory = false}) {
    if (loadWithCategory) {
      loadHistoryWithCategory();
    } else {
      loadHistory();
    }
  }

  /// 드롭다운 카테고리 변경 시 필터 적용
  void setSelectedCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _applyCategoryFilter();
      notifyListeners();
    }
  }

  /// 필터링 로직
  void _applyCategoryFilter() {
    if (_selectedCategory == '전체') {
      _filteredHistory = _allHistory;
    } else {
      _filteredHistory =
          _allHistory
              .where((e) => e.categoryName == _selectedCategory)
              .toList();
    }
  }

  /// 전체 카테고리 추출
  void _extractCategories() {
    final categorySet = {'전체'};
    for (var entry in _allHistory) {
      if (entry.categoryName.isNotEmpty) {
        categorySet.add(entry.categoryName);
      }
    }
    _categories = categorySet.toList();
  }

  /// 일반 히스토리 불러오기
  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loaded = await HistoryWritingApiService.fetchHistory(
        imageId: imageId,
      );
      _filteredHistory =
          loaded.map((e) => HistoryWritingResponseDto.fromJson(e)).toList()..sort(
            (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
              a.createdAt ?? DateTime(1970),
            ),
          );
    } catch (e) {
      debugPrint("❌ 서버 히스토리 불러오기 실패: $e");
      _filteredHistory = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 카테고리 기반 전체 히스토리 불러오기
  Future<void> loadHistoryWithCategory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await HistoryWritingApiService.fetchHistoryWithCategory();
      _allHistory = data;
      _extractCategories();
      _applyCategoryFilter();
    } catch (e, stack) {
      debugPrint("❌ 히스토리 불러오기 실패: $e");
      debugPrint("📌 Stacktrace: $stack");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteHistoryItem(int index) async {
    if (index < 0 || index >= _filteredHistory.length) return;

    final id = _filteredHistory[index].id;
    try {
      await HistoryWritingApiService.deleteHistoryById(id);
      _filteredHistory.removeAt(index);
      _allHistory.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 삭제 실패: $e');
    }
  }
}
