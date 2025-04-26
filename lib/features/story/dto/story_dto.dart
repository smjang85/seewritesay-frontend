import 'package:see_write_say/features/story/enum/story_type.dart';

class StoryDto {
  final int id;
  final String title;
  final String content;
  final String? imagePath;
  final String languageCode;
  final String type; // 서버에서 'S' or 'L'로 내려옴
  final DateTime createdAt;
  final String? createdBy;

  StoryDto({
    required this.id,
    required this.title,
    required this.content,
    this.imagePath,
    required this.languageCode,
    required this.type,
    required this.createdAt,
    this.createdBy,
  });

  /// enum 변환: 'S' → StoryType.short, 'L' → StoryType.long
  StoryType get storyType => StoryType.fromCode(type);

  /// 편의 getter
  bool get isShort => storyType == StoryType.short;
  bool get isLong => storyType == StoryType.long;

  factory StoryDto.fromJson(Map<String, dynamic> json) {
    return StoryDto(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imagePath: json['imagePath'],
      languageCode: json['languageCode'] ?? 'ko',
      type: json['type'] ?? 'S',
      createdAt: DateTime.now(), // fallback if createdAt missing
      createdBy: json['createdBy'],
    );
  }
}