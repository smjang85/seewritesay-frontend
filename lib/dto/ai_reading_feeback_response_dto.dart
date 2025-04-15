class AiReadingFeedbackResponseDto {
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore;
  final double pronScore;
  final double confidence;
  final String sentenceFromFile;
  final String? sentence;

  AiReadingFeedbackResponseDto({
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    required this.pronScore,
    required this.confidence,
    required this.sentenceFromFile,
    this.sentence,
  });

  factory AiReadingFeedbackResponseDto.fromJson(Map<String, dynamic> json) {
    return AiReadingFeedbackResponseDto(
      accuracyScore: json['accuracyScore'].toDouble(),
      fluencyScore: json['fluencyScore'].toDouble(),
      completenessScore: json['completenessScore'].toDouble(),
      pronScore: json['pronScore'].toDouble(),
      confidence: json['confidence'].toDouble(),
      sentenceFromFile: json['sentenceFromFile'],
      sentence: json['sentence'],
    );
  }
}
