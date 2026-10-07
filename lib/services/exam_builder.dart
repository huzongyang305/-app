import 'dart:math';

import '../models/lesson.dart';
import 'practice_question_factory.dart';

/// 模拟考试中的一道题：来自某个知识点的某道选择题。
class ExamQuestion {
  const ExamQuestion({required this.lesson, required this.questionIndex});

  final Lesson lesson;
  final int questionIndex;

  QuizQuestion get question => lesson.allQuiz[questionIndex];
}

/// 生成一份考卷：按难度权重抽知识点（基础/进阶/高级 = 2/2/1，入门权重 1），
/// 每个知识点随机取一道题；同一知识点只出现一次。
///
/// [categoryId] 为空表示全课程范围，否则只在指定分类内组卷。
List<ExamQuestion> buildExamPaper(
  List<Lesson> allLessons, {
  int size = 10,
  int? seed,
  String? categoryId,
  Set<String>? lessonIds,
  Set<String>? difficulties,
  Set<String>? questionTypes,
}) {
  final random = Random(seed);
  final pool =
      allLessons
          .where(
            (lesson) => lesson.allQuiz.any(
              (question) => _typeAllowed(question, questionTypes),
            ),
          )
          .where(
            (lesson) =>
                difficulties == null ||
                difficulties.isEmpty ||
                difficulties.contains(lesson.difficulty),
          )
          .where(
            (lesson) => categoryId == null || lesson.categoryId == categoryId,
          )
          .where((lesson) => lessonIds == null || lessonIds.contains(lesson.id))
          .toList()
        ..shuffle(random);

  final quotas = _difficultyQuotas(pool, size);

  final picked = <Lesson>[];
  final used = <String>{};
  for (final entry in quotas.entries) {
    if (entry.value <= 0) continue;
    final bucket = pool
        .where(
          (lesson) =>
              lesson.difficulty == entry.key && !used.contains(lesson.id),
        )
        .take(entry.value);
    for (final lesson in bucket.toList()) {
      picked.add(lesson);
      used.add(lesson.id);
    }
  }
  for (final lesson in pool) {
    if (picked.length >= size) break;
    if (used.add(lesson.id)) picked.add(lesson);
  }

  picked.shuffle(random);
  return picked
      .take(size)
      .map(
        (lesson) => ExamQuestion(
          lesson: lesson,
          questionIndex: _pickQuestionIndex(lesson, questionTypes, random),
        ),
      )
      .toList();
}

/// 按难度梯度分配题目配额。
///
/// 权重沿用历史口径「基础/进阶/高级 = 2/2/1」，即 40% / 40% / 20%；
/// 「入门」权重为 1，这样入门课不再被配额排除、只能靠兜底补位。
/// 配额只在实际出现的难度之间按权重分摊，并用最大余数法补齐取整误差，
/// 保证总和恰好等于 [size]。
Map<String, int> _difficultyQuotas(List<Lesson> pool, int size) {
  const ladder = <String>['入门', '基础', '进阶', '高级'];
  const weights = <String, int>{'入门': 1, '基础': 2, '进阶': 2, '高级': 1};
  final present = ladder
      .where((level) => pool.any((lesson) => lesson.difficulty == level))
      .toList();
  if (present.isEmpty || size <= 0) return const <String, int>{};

  final weightSum = present.fold<int>(0, (sum, level) => sum + weights[level]!);
  final quotas = <String, int>{};
  final remainders = <MapEntry<String, double>>[];
  var assigned = 0;
  for (final level in present) {
    final exact = size * weights[level]! / weightSum;
    final floor = exact.floor();
    quotas[level] = floor;
    assigned += floor;
    remainders.add(MapEntry(level, exact - floor));
  }
  remainders.sort((a, b) => b.value.compareTo(a.value));
  for (var i = 0; assigned < size; i++, assigned++) {
    final level = remainders[i % remainders.length].key;
    quotas[level] = quotas[level]! + 1;
  }
  return quotas;
}

/// 指定范围内可参与组卷的知识点数量（用于考前提示可选范围）。
int examPoolSize(
  List<Lesson> allLessons, {
  String? categoryId,
  Set<String>? difficulties,
  Set<String>? questionTypes,
}) {
  return allLessons
      .where(
        (lesson) => lesson.allQuiz.any(
          (question) => _typeAllowed(question, questionTypes),
        ),
      )
      .where(
        (lesson) =>
            difficulties == null ||
            difficulties.isEmpty ||
            difficulties.contains(lesson.difficulty),
      )
      .where((lesson) => categoryId == null || lesson.categoryId == categoryId)
      .length;
}

/// 题型筛选：空集合表示不限制。
bool _typeAllowed(QuizQuestion question, Set<String>? questionTypes) =>
    questionTypes == null ||
    questionTypes.isEmpty ||
    questionTypes.contains(question.type);

/// 在允许的题型中随机取一道，保证题量与题型筛选一致。
int _pickQuestionIndex(
  Lesson lesson,
  Set<String>? questionTypes,
  Random random,
) {
  final candidates = <int>[
    for (var i = 0; i < lesson.allQuiz.length; i++)
      if (_typeAllowed(lesson.allQuiz[i], questionTypes)) i,
  ];
  if (candidates.isEmpty) return random.nextInt(lesson.allQuiz.length);
  return candidates[random.nextInt(candidates.length)];
}

/// 把错题本的键（`知识点ID#题号`）解析成题目列表。
///
/// 知识点不存在、题号非法或越界的条目会被静默忽略，
/// 因此历史数据里残留的脏键不会影响组卷。
List<ExamQuestion> _parseWrongQuestions(
  List<Lesson> allLessons,
  Iterable<String> wrongKeys,
) {
  final byId = <String, Lesson>{
    for (final lesson in allLessons)
      if (lesson.allQuiz.isNotEmpty) lesson.id: lesson,
  };

  final questions = <ExamQuestion>[];
  final seen = <String>{};
  for (final key in wrongKeys) {
    final parts = key.split('#');
    if (parts.length != 2) continue;
    final lesson = byId[parts[0]];
    final index = int.tryParse(parts[1]);
    if (lesson == null || index == null) continue;
    if (index < 0 || index >= lesson.allQuiz.length) continue;
    if (!seen.add(key)) continue;
    questions.add(ExamQuestion(lesson: lesson, questionIndex: index));
  }
  return questions;
}

/// 错题本里可用于重练的题目数量。
int wrongQuestionPoolSize(
  List<Lesson> allLessons,
  Iterable<String> wrongKeys,
) => _parseWrongQuestions(allLessons, wrongKeys).length;

/// 生成「错题重练」试卷：只抽取错题本中记录过的题目，
/// 顺序随机，最多 [size] 题。
List<ExamQuestion> buildWrongAnswerPaper(
  List<Lesson> allLessons, {
  required Iterable<String> wrongKeys,
  int size = 10,
  int? seed,
}) {
  final questions = _parseWrongQuestions(allLessons, wrongKeys)
    ..shuffle(Random(seed));
  return questions.take(size).toList();
}
