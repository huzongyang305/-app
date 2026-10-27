import 'package:code_learn_app/models/code_snippet.dart';
import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/models/lesson_category.dart';
import 'package:code_learn_app/models/localized_text.dart';
import 'package:code_learn_app/models/note.dart';
import 'package:code_learn_app/models/note_anchor.dart';
import 'package:code_learn_app/models/sandbox_language.dart';
import 'package:code_learn_app/services/global_search_service.dart';
import 'package:code_learn_app/services/search_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 统一搜索：术语索引随全文索引构建，以及笔记 / 错题 / 片段 / 挑战匹配。
void main() {
  const lesson = Lesson(
    id: 'python_basics',
    categoryId: 'programming',
    title: LocalizedText(zh: 'Python 基础语法', en: 'Python Basics'),
    summary: LocalizedText(zh: '变量、函数与缩进', en: 'Variables and functions'),
    assetFile: 'assets/content/python_basics.md',
    minutes: 12,
    keywords: <String>['变量', '函数', '缩进'],
    quiz: <QuizQuestion>[
      QuizQuestion(
        question: 'Python 中用于定义函数的关键字是什么？',
        options: <String>['def', 'func', 'function', 'lambda'],
        answerIndex: 0,
        explanation: 'Python 使用 def 定义函数。',
      ),
    ],
  );

  const category = LessonCategory(
    id: 'programming',
    title: LocalizedText(zh: '编程语言', en: 'Programming'),
    iconName: 'code',
    colorValue: 0x2563EB,
    lessons: <Lesson>[lesson],
  );

  const categories = <LessonCategory>[category];

  const markdown = '''
# Python 基础语法

| 术语 | 一句话说明 |
| --- | --- |
| 闭包 | 函数与它定义时所在环境的组合，可以记住外部变量 |
| 生成器 | 用 yield 按需产出值的迭代器，节省内存 |
''';

  Future<String> plainTextOf(Lesson _) async => 'Python 用缩进划分代码块。';
  Future<String> markdownOf(Lesson _) async => markdown;

  final lessonsById = <String, Lesson>{lesson.id: lesson};
  final categoriesById = <String, LessonCategory>{category.id: category};

  group('术语索引', () {
    test('构建全文索引时顺带提取术语，可按术语与解释搜索', () async {
      final index = LessonSearchIndex();
      await index.build(categories, plainTextOf, markdownOf: markdownOf);

      final exact = index.searchTerms('闭包');
      expect(exact, hasLength(1));
      expect(exact.first.term, '闭包');
      expect(exact.first.lesson.id, 'python_basics');
      expect(exact.first.category.id, 'programming');
      expect(exact.first.explanation, contains('外部变量'));

      final byExplanation = index.searchTerms('迭代器');
      expect(byExplanation.map((hit) => hit.term), contains('生成器'));

      // 分类筛选与其他结果保持一致。
      expect(
        index.searchTerms('闭包', categoryId: 'programming'),
        hasLength(1),
      );
      expect(index.searchTerms('闭包', categoryId: 'network'), isEmpty);

      // 单字查询噪声太大，直接返回空。
      expect(index.searchTerms('闭'), isEmpty);
    });

    test('术语写入缓存后可以完整恢复，无需重新读 Markdown', () async {
      final index = LessonSearchIndex();
      await index.build(categories, plainTextOf, markdownOf: markdownOf);

      final restored = LessonSearchIndex();
      final ok = restored.restoreFromCache(categories, index.toCacheJson());
      expect(ok, isTrue);

      final hits = restored.searchTerms('闭包');
      expect(hits, hasLength(1));
      expect(hits.first.lesson.id, 'python_basics');
      expect(restored.search('基础语法').first.lesson.id, 'python_basics');
    });

    test('内容指纹不匹配时拒绝旧缓存', () async {
      final index = LessonSearchIndex();
      await index.build(categories, plainTextOf, markdownOf: markdownOf);

      const changed = LessonCategory(
        id: 'programming',
        title: LocalizedText(zh: '编程语言', en: 'Programming'),
        iconName: 'code',
        colorValue: 0x2563EB,
        lessons: <Lesson>[],
      );
      final restored = LessonSearchIndex();
      expect(
        restored.restoreFromCache(const <LessonCategory>[changed], index.toCacheJson()),
        isFalse,
      );
    });
  });

  group('本地学习数据匹配', () {
    test('笔记正文与标签都可以命中，并按更新时间排序', () {
      final older = Note(
        lessonId: 'python_basics',
        content: '闭包会记住外部变量，注意循环里的延迟绑定。',
        updatedAt: DateTime(2026, 10, 1),
        tags: const <String>['重点'],
        anchors: const <NoteAnchor>[
          NoteAnchor(title: '闭包', progress: 0.4),
        ],
      );
      final newer = Note(
        lessonId: 'python_basics',
        content: '闭包常用于装饰器与回调。',
        updatedAt: DateTime(2026, 10, 20),
      );

      final hits = GlobalSearchService.matchNotes(
        notes: <Note>[older, newer],
        lessonsById: lessonsById,
        categoriesById: categoriesById,
        query: '闭包',
      );
      expect(hits, hasLength(2));
      expect(hits.first.note, same(newer));
      expect(hits.first.snippet, contains('闭包'));

      final tagHits = GlobalSearchService.matchNotes(
        notes: <Note>[older],
        lessonsById: lessonsById,
        categoriesById: categoriesById,
        query: '重点',
      );
      expect(tagHits, hasLength(1));
      expect(tagHits.first.note, same(older));

      expect(
        GlobalSearchService.matchNotes(
          notes: <Note>[older],
          lessonsById: lessonsById,
          categoriesById: categoriesById,
          query: '闭包',
          categoryId: 'network',
        ),
        isEmpty,
      );

      expect(
        GlobalSearchService.matchNotes(
          notes: <Note>[older],
          lessonsById: lessonsById,
          categoriesById: categoriesById,
          query: '不存在的词',
        ),
        isEmpty,
      );
    });

    test('错题定位到具体题目，并带上作答次数', () {
      final hits = GlobalSearchService.matchWrongQuestions(
        keys: const <String>['python_basics#0'],
        lessonsById: lessonsById,
        categoriesById: categoriesById,
        query: 'def',
        wrongCountOf: (_, _) => 2,
      );
      expect(hits, hasLength(1));
      expect(hits.first.questionIndex, 0);
      expect(hits.first.question.question, contains('定义函数'));
      expect(hits.first.wrongCount, 2);

      expect(
        GlobalSearchService.matchWrongQuestions(
          keys: const <String>['python_basics#0'],
          lessonsById: lessonsById,
          categoriesById: categoriesById,
          query: 'def',
          wrongCountOf: (_, _) => 2,
          categoryId: 'network',
        ),
        isEmpty,
      );

      expect(
        GlobalSearchService.matchWrongQuestions(
          keys: const <String>['python_basics#9', 'unknown#0'],
          lessonsById: lessonsById,
          categoriesById: categoriesById,
          query: 'def',
          wrongCountOf: (_, _) => 1,
        ),
        isEmpty,
      );
    });

    test('代码片段按标题与代码命中，并给出代码摘录', () {
      final snippet = CodeSnippet(
        id: 's1',
        languageId: 'javascript',
        title: '数组去重',
        code: 'const unique = [...new Set(raw)];',
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );
      final byTitle = GlobalSearchService.matchSnippets(
        items: <CodeSnippet>[snippet],
        query: '去重',
      );
      expect(byTitle, hasLength(1));
      expect(byTitle.first.snippet.id, 's1');

      final byCode = GlobalSearchService.matchSnippets(
        items: <CodeSnippet>[snippet],
        query: 'new set',
      );
      expect(byCode.single.excerpt, contains('new Set'));
    });

    test('沙箱挑战的中英文标题与任务描述都可搜索', () {
      final hits = GlobalSearchService.matchChallenges(
        languages: SandboxLanguage.values,
        query: 'fizzbuzz',
      );
      expect(hits, isNotEmpty);
      expect(hits.first.challenge.id, 'js-fizzbuzz');
      expect(hits.first.language, SandboxLanguage.javascript);

      expect(
        GlobalSearchService.matchChallenges(
          languages: SandboxLanguage.values,
          query: '完全不存在的挑战',
        ),
        isEmpty,
      );
    });
  });
}
