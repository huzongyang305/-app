/// 用户自行收录的错题：来自拍照识别或手动补录，不属于内置题库。
///
/// 与内置题目的区别在于没有 `lessonId` / `questionIndex`，因此它不进题目级
/// 复习队列，而是以闪卡形式参与间隔重复（见 `Flashcard.fromCustom`）。
class CustomQuestion {
  const CustomQuestion({
    required this.id,
    required this.question,
    required this.answer,
    this.explanation = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// 题干，识别结果里第一块非空文本。
  final String question;

  /// 答案，由用户确认或补录，识别文本不能直接保证正确。
  final String answer;

  /// 解析 / 错因备注。
  final String explanation;

  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'question': question,
    'answer': answer,
    'explanation': explanation,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CustomQuestion.fromJson(Map<String, dynamic> json) {
    final created =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();
    return CustomQuestion(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      createdAt: created,
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? created,
    );
  }

  CustomQuestion copyWith({
    String? question,
    String? answer,
    String? explanation,
    DateTime? updatedAt,
  }) {
    return CustomQuestion(
      id: id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 题干与答案都非空才值得保留：缺一都会让闪卡背面变成空白。
  bool get isValid => question.trim().isNotEmpty && answer.trim().isNotEmpty;
}
