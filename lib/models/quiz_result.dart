/// 一次测验的最好成绩记录。
class QuizResult {
  const QuizResult({
    required this.lessonId,
    required this.correct,
    required this.total,
    required this.attempts,
    required this.updatedAt,
  });

  final String lessonId;
  final int correct;
  final int total;
  final int attempts;
  final DateTime updatedAt;

  double get accuracy => total == 0 ? 0 : correct / total;

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'correct': correct,
    'total': total,
    'attempts': attempts,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      lessonId: json['lessonId'] as String,
      correct: json['correct'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      attempts: json['attempts'] as int? ?? 1,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
