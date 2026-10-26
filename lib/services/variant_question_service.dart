import '../models/lesson.dart';
import 'practice_question_factory.dart';

/// 变式题的来源。
enum VariantKind {
  /// 还没有可用的变式，直接使用原题。
  original,

  /// 同一知识点里的另一道题（包括按参数生成的代码题）。
  sameLesson,
}

/// 一次变式选择的结果。
class VariantQuestion {
  const VariantQuestion({
    required this.question,
    required this.kind,
    required this.sourceIndex,
    required this.variantIndex,
  });

  final QuizQuestion question;
  final VariantKind kind;

  /// 原题在 `lesson.allQuiz` 中的下标，复习结果仍记在原题上。
  final int sourceIndex;

  /// 实际展示的题在下标。
  final int variantIndex;

  bool get isVariant =>
      kind == VariantKind.sameLesson && variantIndex != sourceIndex;
}

/// 为题目级复习挑选变式。
///
/// 变式不是凭空改写答案，而是从同一知识点的题集里换一道题：
/// 优先同题型，其次任意不同题；同一个知识点会按 [attempt] 轮换，
/// 这样多次复习不会一直看到同一道题，也不会因选项重排而破坏解析。
class VariantQuestionService {
  const VariantQuestionService._();

  static VariantQuestion? forQuestion(
    Lesson lesson,
    int questionIndex, {
    int attempt = 1,
  }) {
    final questions = lesson.allQuiz;
    if (questionIndex < 0 || questionIndex >= questions.length) return null;
    final origin = questions[questionIndex];
    VariantQuestion original() => VariantQuestion(
      question: origin,
      kind: VariantKind.original,
      sourceIndex: questionIndex,
      variantIndex: questionIndex,
    );

    if (attempt <= 0 || questions.length < 2) return original();
    final candidates = <int>[
      for (var i = 0; i < questions.length; i++)
        if (i != questionIndex &&
            questions[i].question.trim() != origin.question.trim())
          i,
    ];
    if (candidates.isEmpty) return original();

    final sameType = candidates
        .where((index) => questions[index].type == origin.type)
        .toList(growable: false);
    final pool = sameType.isNotEmpty ? sameType : candidates;
    final seed = _stableHash('${lesson.id}#$questionIndex') + attempt.abs();
    final chosen = pool[seed % pool.length];
    return VariantQuestion(
      question: questions[chosen],
      kind: VariantKind.sameLesson,
      sourceIndex: questionIndex,
      variantIndex: chosen,
    );
  }

  static int _stableHash(String value) {
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = 37 * hash + codeUnit;
      hash &= 0x7fffffff;
    }
    return hash;
  }
}
