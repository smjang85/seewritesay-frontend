class ChapterDto {
  final int id;
  final int storyId; // 🔥 추가
  final String title;
  final int chapterOrder;
  final bool isActive;

  ChapterDto({
    required this.id,
    required this.storyId,
    required this.title,
    required this.chapterOrder,
    required this.isActive,
  });

  factory ChapterDto.fromJson(Map<String, dynamic> json) {
    return ChapterDto(
      id: json['id'],
      storyId: json['storyId'], // 백엔드에서 내려주는 필드명 확인 필요
      title: json['title'],
      chapterOrder: json['order'],
      isActive: json['isActive'] ?? true,
    );
  }
}
