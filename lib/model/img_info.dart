class ImgInfo {
  final int id;
  final String imgName;
  final String? imgPath;
  final String? imgCategory;
  final String imgDesc;

  ImgInfo({
    required this.id,
    required this.imgName,
    this.imgPath,
    this.imgCategory,
    required this.imgDesc,
  });

  factory ImgInfo.fromJson(Map<String, dynamic> json) {
    return ImgInfo(
      id: json['id'],
      imgName: json['imgName'],
      imgPath: json['imgPath'],
      imgCategory: json['imgCategory'],
      imgDesc: json['imgDesc'],
    );
  }
}
