import 'lesson.dart';

/// 闪卡来源：测验题卡、笔记卡。
enum FlashcardKind {
  question('question'),
  note('note');

  const FlashcardKind(this.storageKey);

  final String storageKey;

  static FlashcardKind fromStorage(String? value) {
    for (final kind in FlashcardKind.values) {
      if (kind.storageKey == value) return kind;
    }
    return FlashcardKind.question;
  }
}

/// 一张闪卡：正面是问题/提示，背面是答案/笔记内容。
class Flashcard {
  const Flashcard({
    required this.id,
    required this.lessonId,
    required this.categoryId,
    required this.kind,
    required this.front,
    required this.back,
    this.code,
    this.questionIndex,
    this.explanation,
  });

  /// 稳定标识：题目卡为 `课程#题号`，笔记卡为 `note:课程`。
  final String id;
  final String lessonId;
  final String categoryId;
  final FlashcardKind kind;
  final String front;
  final String back;

  /// 代码题干（题目卡可能有）。
  final String? code;

  /// 题目在课程题集中的下标；笔记卡为 null。
  final int? questionIndex;

  /// 答案解析（题目卡可能有）。
  final String? explanation;

  /// 从题目生成闪卡：正面为题面，背面为正确答案 + 解析。
  factory Flashcard.fromQuestion({
    required Lesson lesson,
    required QuizQuestion question,
    required int questionIndex,
  }) {
    return Flashcard(
      id: '${lesson.id}#$questionIndex',
      lessonId: lesson.id,
      categoryId: lesson.categoryId,
      kind: FlashcardKind.question,
      front: question.question,
      back: answerTextOf(question),
      code: question.code,
      questionIndex: questionIndex,
      explanation: question.explanation.isEmpty ? null : question.explanation,
    );
  }

  /// 从本地笔记生成闪卡：正面是课程标题，背面是笔记正文。
  factory Flashcard.fromNote({
    required Lesson lesson,
    required String content,
  }) {
    return Flashcard(
      id: 'note:${lesson.id}',
      lessonId: lesson.id,
      categoryId: lesson.categoryId,
      kind: FlashcardKind.note,
      front: lesson.title.zh,
      back: content,
    );
  }

  /// 题目的标准答案文本（兼容选择、多选、填空、排序等题型）。
  static String answerTextOf(QuizQuestion question) {
    switch (question.type) {
      case 'multi':
        return question.correctIndexes
            .where((index) => index >= 0 && index < question.options.length)
            .map((index) => question.options[index])
            .join('、');
      case 'order':
        final order = question.correctOrder.isEmpty
            ? question.correctIndexes
            : question.correctOrder;
        return order
            .where((index) => index >= 0 && index < question.options.length)
            .map((index) => question.options[index])
            .join(' → ');
      case 'fill':
        if (question.acceptedAnswers.isNotEmpty) {
          return question.acceptedAnswers.join(' / ');
        }
        return question.explanation.isEmpty ? '（见解析）' : question.explanation;
      default:
        final index = question.answerIndex;
        if (index >= 0 && index < question.options.length) {
          return question.options[index];
        }
        return question.explanation.isEmpty ? '（见解析）' : question.explanation;
    }
  }
}