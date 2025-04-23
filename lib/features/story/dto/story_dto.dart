class StoryDto {
  final int id;
  final String title;
  final String content;
  final String? imagePath;
  final String languageCode;
  final DateTime createdAt;
  final String? createdBy;

  StoryDto({
    required this.id,
    required this.title,
    required this.content,
    this.imagePath,
    required this.languageCode,
    required this.createdAt,
    this.createdBy,
  });

  factory StoryDto.fromJson(Map<String, dynamic> json) {
    return StoryDto(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imagePath: json['imagePath'],
      languageCode: json['languageCode'] ?? 'ko',
      createdAt: DateTime.now(), // fallback if createdAt missing
      createdBy: json['createdBy'],
    );
  }
}