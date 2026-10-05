import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/models/localized_text.dart';
import 'package:code_learn_app/services/exam_builder.dart';
import 'package:code_learn_app/services/practice_question_factory.dart';
import 'package:flutter_test/flutter_test.dart';

/// 模拟考试组卷规则测试。
void main() {
  group('错题重练组卷', () {
    test('只抽取错题本里记录过的题目', () {
      final lessons = List<Lesson>.generate(3, (index) {
        return Lesson(
          id: 'cat_$index',
          categoryId: 'cat',
          difficulty: '基础',
          title: LocalizedText(zh: '知识点 $index', en: 'Lesson $index'),
          summary: const LocalizedText(zh: '摘要', en: 'Summary'),
          assetFile: 'assets/content/lesson_$index.md',
          minutes: 10,
          keywords: const <String>['测试'],
          quiz: const <QuizQuestion>[
            QuizQuestion(
              question: '题干 A',
              options: ['1', '2', '3', '4'],
              answerIndex: 0,
              explanation: '解析 A',
            ),
          ],
        );
      });

      final paper = buildWrongAnswerPaper(
        lessons,
        wrongKeys: const <String>['cat_0#0', 'cat_2#0'],
        size: 10,
        seed: 1,
      );

      expect(paper.length, 2);
      expect(paper.map((q) => q.lesson.id).toSet(), <String>{'cat_0', 'cat_2'});
    });

    test('忽略知识点不存在、题号越界与格式错误的键', () {
      final lessons = List<Lesson>.generate(1, (index) {
        return Lesson(
          id: 'cat_$index',
          categoryId: 'cat',
          difficulty: '基础',
          title: LocalizedText(zh: '知识点 $index', en: 'Lesson $index'),
          summary: const LocalizedText(zh: '摘要', en: 'Summary'),
          assetFile: 'assets/content/lesson_$index.md',
          minutes: 10,
          keywords: const <String>['测试'],
          quiz: const <QuizQuestion>[
            QuizQuestion(
              question: '题干 A',
              options: ['1', '2', '3', '4'],
              answerIndex: 0,
              explanation: '解析 A',
            ),
          ],
        );
      });

      final paper = buildWrongAnswerPaper(
        lessons,
        wrongKeys: const <String>[
          'cat_0#0', // 有效
          'missing#0', // 知识点不存在
          'cat_0#9', // 题号越界
          'cat_0#abc', // 题号非数字
          'cat_0', // 缺少题号
        ],
        size: 10,
      );

      expect(paper.length, 1);
      expect(paper.single.lesson.id, 'cat_0');
      expect(paper.single.questionIndex, 0);
    });

    test('题量上限与错题池统计一致', () {
      final lessons = List<Lesson>.generate(5, (index) {
        return Lesson(
          id: 'cat_$index',
          categoryId: 'cat',
          difficulty: '基础',
          title: LocalizedText(zh: '知识点 $index', en: 'Lesson $index'),
          summary: const LocalizedText(zh: '摘要', en: 'Summary'),
          assetFile: 'assets/content/lesson_$index.md',
          minutes: 10,
          keywords: const <String>['测试'],
          quiz: const <QuizQuestion>[
            QuizQuestion(
              question: '题干 A',
              options: ['1', '2', '3', '4'],
              answerIndex: 0,
              explanation: '解析 A',
            ),
          ],
        );
      });
      final keys = <String>[for (var i = 0; i < 5; i++) 'cat_$i#0'];

      expect(wrongQuestionPoolSize(lessons, keys), 5);
      expect(
        buildWrongAnswerPaper(lessons, wrongKeys: keys, size: 3).length,
        3,
      );
    });

    test('错题本为空时组卷结果为空', () {
      final lessons = List<Lesson>.generate(2, (index) {
        return Lesson(
          id: 'cat_$index',
          categoryId: 'cat',
          difficulty: '基础',
          title: LocalizedText(zh: '知识点 $index', en: 'Lesson $index'),
          summary: const LocalizedText(zh: '摘要', en: 'Summary'),
          assetFile: 'assets/content/lesson_$index.md',
          minutes: 10,
          keywords: const <String>['测试'],
          quiz: const <QuizQuestion>[
            QuizQuestion(
              question: '题干 A',
              options: ['1', '2', '3', '4'],
              answerIndex: 0,
              explanation: '解析 A',
            ),
          ],
        );
      });

      expect(buildWrongAnswerPaper(lessons, wrongKeys: const []), isEmpty);
      expect(wrongQuestionPoolSize(lessons, const []), 0);
    });
  });

  /// 造一批带测验的知识点，按索引轮流分配三种难度。
  List<Lesson> makeLessons(
    int count, {
    bool withQuiz = true,
    String categoryId = 'cat',
  }) {
    const difficulties = ['基础', '进阶', '高级'];
    return List<Lesson>.generate(count, (index) {
      return Lesson(
        id: '${categoryId}_$index',
        categoryId: categoryId,
        difficulty: difficulties[index % difficulties.length],
        title: LocalizedText(zh: '知识点 $index', en: 'Lesson $index'),
        summary: const LocalizedText(zh: '摘要', en: 'Summary'),
        assetFile: 'assets/content/lesson_$index.md',
        minutes: 10,
        keywords: const <String>['测试'],
        quiz: withQuiz
            ? const <QuizQuestion>[
                QuizQuestion(
                  question: '题干 A',
                  options: ['1', '2', '3', '4'],
                  answerIndex: 0,
                  explanation: '解析 A',
                ),
                QuizQuestion(
                  question: '题干 B',
                  options: ['1', '2', '3', '4'],
                  answerIndex: 1,
                  explanation: '解析 B',
                ),
              ]
            : const <QuizQuestion>[],
      );
    });
  }

  test('默认考卷 10 题且知识点不重复', () {
    final paper = buildExamPaper(makeLessons(60), seed: 42);
    expect(paper.length, 10);
    expect(paper.map((item) => item.lesson.id).toSet().length, 10);
  });

  test('题号始终落在该知识点的完整题库范围内', () {
    final paper = buildExamPaper(makeLessons(60), size: 20, seed: 5);
    for (final item in paper) {
      expect(
        item.questionIndex,
        inInclusiveRange(0, item.lesson.allQuiz.length - 1),
      );
      expect(item.question, item.lesson.allQuiz[item.questionIndex]);
    }
  });

  test('语言课程会追加动态代码练习，非语言课程保持原题库', () {
    final languageLesson = makeLessons(1, categoryId: 'python').single;
    final otherLesson = makeLessons(1, categoryId: 'cat').single;

    expect(languageLesson.allQuiz.length, languageLesson.quiz.length + 6);
    expect(otherLesson.allQuiz.length, otherLesson.quiz.length);
    expect(languageLesson.totalQuestionCount, languageLesson.allQuiz.length);
  });

  test('同一 seed 生成的考卷完全一致，便于复现问题', () {
    final lessons = makeLessons(60);
    String fingerprint(List<ExamQuestion> paper) => paper
        .map((item) => '${item.lesson.id}#${item.questionIndex}')
        .join(',');

    expect(
      fingerprint(buildExamPaper(lessons, seed: 7)),
      fingerprint(buildExamPaper(lessons, seed: 7)),
    );
    expect(
      fingerprint(buildExamPaper(lessons, seed: 7)),
      isNot(fingerprint(buildExamPaper(lessons, seed: 8))),
    );
  });

  test('按 40% / 40% / 20% 配比覆盖三种难度', () {
    final paper = buildExamPaper(makeLessons(60), size: 10, seed: 3);
    int countOf(String difficulty) =>
        paper.where((item) => item.lesson.difficulty == difficulty).length;
    expect(countOf('基础'), 4);
    expect(countOf('进阶'), 4);
    expect(countOf('高级'), 2);
  });

  test('可选知识点不够时按实际数量出卷，不补重复题', () {
    final paper = buildExamPaper(makeLessons(4), size: 10, seed: 1);
    expect(paper.length, 4);
    expect(paper.map((item) => item.lesson.id).toSet().length, 4);
  });

  test('没有测验的知识点不会被抽到', () {
    final lessons = <Lesson>[
      ...makeLessons(20),
      ...makeLessons(5, withQuiz: false).map(
        (lesson) => Lesson(
          id: 'empty_${lesson.id}',
          categoryId: lesson.categoryId,
          difficulty: lesson.difficulty,
          title: lesson.title,
          summary: lesson.summary,
          assetFile: lesson.assetFile,
          minutes: lesson.minutes,
          keywords: lesson.keywords,
          quiz: const <QuizQuestion>[],
        ),
      ),
    ];
    final paper = buildExamPaper(lessons, size: 20, seed: 11);
    expect(paper, hasLength(20));
    for (final item in paper) {
      expect(item.lesson.quiz, isNotEmpty);
      expect(item.lesson.id.startsWith('empty_'), isFalse);
    }
  });

  test('空课程库返回空考卷而不报错', () {
    expect(buildExamPaper(const <Lesson>[], size: 10, seed: 0), isEmpty);
  });

  test('限定分类组卷时只抽该分类的知识点', () {
    final lessons = <Lesson>[
      ...makeLessons(20, categoryId: 'python'),
      ...makeLessons(20, categoryId: 'java'),
    ];
    final paper = buildExamPaper(
      lessons,
      size: 10,
      seed: 9,
      categoryId: 'python',
    );
    expect(paper, hasLength(10));
    expect(paper.every((item) => item.lesson.categoryId == 'python'), isTrue);
  });

  test('examPoolSize 会把有动态代码练习的语言课程计入题库', () {
    final lessons = <Lesson>[
      ...makeLessons(20, categoryId: 'python'),
      ...makeLessons(5, categoryId: 'java', withQuiz: false),
      ...makeLessons(3, categoryId: 'java'),
    ];
    // 语言课程即使没有内置题目，也会由代码练习工厂补充 6 道动态题。
    expect(examPoolSize(lessons), 28);
    expect(examPoolSize(lessons, categoryId: 'python'), 20);
    expect(examPoolSize(lessons, categoryId: 'java'), 8);
    expect(examPoolSize(lessons, categoryId: 'go'), 0);
  });

  test('范围内没有可用知识点时返回空考卷', () {
    final lessons = makeLessons(5, withQuiz: false);
    expect(buildExamPaper(lessons, size: 10, seed: 1), isEmpty);
  });
}
