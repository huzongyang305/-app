import '../models/lesson.dart';
import 'practice_question_factory.dart';

/// 每日一题：某天的题目与所属课程。
class DailyQuestion {
  const DailyQuestion({required this.lesson, required this.questionIndex});

  final Lesson lesson;
  final int questionIndex;

  QuizQuestion get question => lesson.allQuiz[questionIndex];
}

/// 每日一题服务：按日期从本地题库确定性抽题，离线可用。
///
/// 同一天、同一份题库永远得到同一道题；题库更新后会自动指向新题目。
class DailyQuestionService {
  const DailyQuestionService._();

  /// 抽取 [day] 当天的题目；题库为空时返回 null。
  static DailyQuestion? pick(List<Lesson> lessons, DateTime day) {
    final pool = <DailyQuestion>[];
    for (final lesson in lessons) {
      final count = lesson.allQuiz.length;
      for (var index = 0; index < count; index++) {
        pool.add(DailyQuestion(lesson: lesson, questionIndex: index));
      }
    }
    if (pool.isEmpty) return null;
    // 优先选择有正文与解析的题目；这里直接按稳定哈希取模即可。
    final index = _stableHash(dayKey(day)) % pool.length;
    return pool[index];
  }

  /// 日期键：yyyy-MM-dd。
  static String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// FNV-1a 变体：保证跨平台、跨版本结果稳定。
  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
