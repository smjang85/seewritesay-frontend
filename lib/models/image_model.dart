class ImageModel {
  final int id;
  final String name;
  final String path;
  final String? category; // 서버의 categoryName 매핑
  final String? description;

  String? get categoryName => category;

  ImageModel({
    required this.id,
    required this.name,
    required this.path,
    this.category,
    this.description,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      category: json['categoryName'], // ✅ 여기 수정!
      description: json['description'],
    );
  }
}
