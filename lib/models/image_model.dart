class ImageModel {
  final int id;
  final String name;
  final String? path;
  final String? category;
  final String description;

  ImageModel({
    required this.id,
    required this.name,
    this.path,
    this.category,
    required this.description,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    print("🧾 받은 JSON: $json"); // 디버깅용

    return ImageModel(
      id: json['id'],
      name: json['name'] ?? 'unknown',
      path: json['path'],
      category: json['category'],
      description: json['description'] ?? '',
    );
  }
}
