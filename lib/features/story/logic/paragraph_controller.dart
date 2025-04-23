class ParagraphController {
  int currentIndex = 0;
  List<String> paragraphs = [];

  void initializeWithText(String content) {
    paragraphs = content
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    currentIndex = 0;
  }

  bool get hasNext => currentIndex < paragraphs.length - 1;
  bool get hasPrevious => currentIndex > 0;

  void next() {
    if (hasNext) currentIndex++;
  }

  void previous() {
    if (hasPrevious) currentIndex--;
  }

  String get current => paragraphs[currentIndex];
}
