class UserProfileResponseDto {
  final String? nickname;
  final String? avatar;
  final String? ageGroup;

  UserProfileResponseDto({
    this.nickname,
    this.avatar,
    this.ageGroup,
  });

  factory UserProfileResponseDto.fromJson(Map<String, dynamic> json) {
    return UserProfileResponseDto(
      nickname: json['nickname'],
      avatar: json['avatar'],
      ageGroup: json['ageGroup'],
    );
  }
}
