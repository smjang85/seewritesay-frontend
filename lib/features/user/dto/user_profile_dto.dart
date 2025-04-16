class UserProfileDto {
  final String? nickname;
  final String? avatar;
  final String? ageGroup;

  UserProfileDto({
    this.nickname,
    this.avatar,
    this.ageGroup,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      nickname: json['nickname'],
      avatar: json['avatar'],
      ageGroup: json['ageGroup'],
    );
  }
}
