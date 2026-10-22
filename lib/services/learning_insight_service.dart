import '../models/lesson.dart';
import '../models/study_center.dart';
import 'practice_question_factory.dart';
import 'progress_provider.dart';

/// 学习洞察：概念级掌握度、错因分布与单题难度校准。
class LearningInsightService {
  const LearningInsightService._();

  static const List<String> errorCauses = <String>[
    '概念不清',
    '粗心',
    '语法/API',
    '边界条件',
    '性能判断',
    '读题遗漏',
    '其他',
  ];

  static List<String> conceptsOf(Lesson lesson, {int limit = 6}) {
    final seen = <String>{};
    final result = <String>[];
    for (final keyword in lesson.keywords) {
      final value = keyword.trim();
      if (value.isEmpty || !seen.add(value)) continue;
      result.add(value);
      if (result.length >= limit) break;
    }
    if (result.isEmpty) {
      result.add(
        lesson.group?.trim().isNotEmpty == true
            ? lesson.group!
            : lesson.categoryId,
      );
    }
    return result;
  }

  static List<ConceptMastery> buildConceptMastery({
    required List<Lesson> lessons,
    required ProgressProvider progress,
  }) {
    final attempts = <String, int>{};
    final correct = <String, int>{};
    final score = <String, double>{};
    final lessonIds = <String, Set<String>>{};
    for (final lesson in lessons) {
      final result = progress.resultOf(lesson.id);
      final quizCount = lesson.allQuiz.length;
      if (result == null || quizCount == 0) continue;
      final lessonAttempts = result.attempts * quizCount;
      if (lessonAttempts <= 0) continue;
      final lessonCorrect = (result.accuracy * lessonAttempts).round();
      final wrongPenalty = progress.wrongCountFor(lesson.id);
      for (final concept in conceptsOf(lesson)) {
        attempts[concept] = (attempts[concept] ?? 0) + lessonAttempts;
        correct[concept] = (correct[concept] ?? 0) + lessonCorrect;
        final raw =
            ((result.accuracy * lessonAttempts) - wrongPenalty * 0.5) /
            lessonAttempts;
        score[concept] = (score[concept] ?? 0) + raw.clamp(0.0, 1.0);
        lessonIds.putIfAbsent(concept, () => <String>{}).add(lesson.id);
      }
    }
    final counts = <String, int>{};
    for (final lesson in lessons) {
      for (final concept in conceptsOf(lesson)) {
        counts[concept] = (counts[concept] ?? 0) + 1;
      }
    }
    final list = <ConceptMastery>[];
    for (final concept in attempts.keys) {
      final count = counts[concept] ?? 1;
      list.add(
        ConceptMastery(
          concept: concept,
          score: ((score[concept] ?? 0) / count).clamp(0.0, 1.0),
          attempts: attempts[concept] ?? 0,
          correct: correct[concept] ?? 0,
          lessonIds: List<String>.unmodifiable(
            lessonIds[concept] ?? const <String>{},
          ),
        ),
      );
    }
    list.sort((a, b) => a.score.compareTo(b.score));
    return List<ConceptMastery>.unmodifiable(list);
  }

  static List<QuestionStat> buildQuestionStats({
    required List<Lesson> lessons,
    required ProgressProvider progress,
  }) {
    final result = <QuestionStat>[];
    for (final lesson in lessons) {
      final quiz = lesson.allQuiz;
      for (var index = 0; index < quiz.length; index++) {
        final key = '${lesson.id}#$index';
        final stat = progress.questionStat(key);
        if (stat == null || stat['attempts'] is! int) continue;
        final attempts = stat['attempts'] as int;
        final correct = stat['correct'] is int ? stat['correct'] as int : 0;
        final partial =
            (stat['partialScore'] as num?)?.toDouble() ?? correct.toDouble();
        result.add(
          QuestionStat(
            key: key,
            lessonId: lesson.id,
            questionIndex: index,
            question: quiz[index].question,
            attempts: attempts,
            correct: correct,
            partialScore: partial,
            lastConfidence: stat['lastConfidence']?.toString() ?? 'unsure',
            lastCause: stat['lastCause']?.toString() ?? '其他',
          ),
        );
      }
    }
    result.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return List<QuestionStat>.unmodifiable(result);
  }

  static List<ErrorCauseStat> errorCauseStats(ProgressProvider progress) {
    final raw = progress.errorCauseCounts;
    final list =
        raw.entries
            .map(
              (entry) => ErrorCauseStat(cause: entry.key, count: entry.value),
            )
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));
    return List<ErrorCauseStat>.unmodifiable(list);
  }
}
