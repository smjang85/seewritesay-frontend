enum StoryType {
  short,
  long;

  String get code {
    switch (this) {
      case StoryType.short:
        return 'S';
      case StoryType.long:
        return 'L';
    }
  }

  String get displayName {
    switch (this) {
      case StoryType.short:
        return '단편';
      case StoryType.long:
        return '장편';
    }
  }

  static StoryType fromCode(String code) {
    switch (code) {
      case 'L':
        return StoryType.long;
      case 'S':
      default:
        return StoryType.short;
    }
  }
}
