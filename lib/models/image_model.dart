class ImageModel {
  final int id;
  final String name;
  final String path;
  final String? category; // 서버로부터 받은 필드
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
      category: json['category'],
      description: json['description'],
    );
  }
}
