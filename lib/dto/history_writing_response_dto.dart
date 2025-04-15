class HistoryWritingResponseDto{
  final int id;
  final int imageId;
  final String imagePath;
  final String imageName;
  final String? imageDescription;
  final String sentence;
  final int categoryId;
  final String categoryName;
  final DateTime? createdAt;

  HistoryWritingResponseDto({
    required this.id,
    required this.imageId,
    required this.imagePath,
    required this.imageName,
    this.imageDescription,
    required this.sentence,
    required this.categoryId,
    required this.categoryName,
    this.createdAt,
  });

  factory HistoryWritingResponseDto.fromJson(Map<String, dynamic> json) {
    return HistoryWritingResponseDto(
      id: json['id'] ?? 0,
      imageId: json['imageId'] ?? 0,
      imagePath: json['imagePath'] ?? '',
      imageName: json['imageName'] ?? '',
      imageDescription: json['imageDescription'],
      sentence: json['sentence'] ?? '',
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) // 안전하게 파싱
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageId': imageId,
      'imagePath': imagePath,
      'imageName': imageName,
      'imageDescription': imageDescription,
      'sentence': sentence,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
