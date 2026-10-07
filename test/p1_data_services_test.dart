import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/models/lesson_category.dart';
import 'package:code_learn_app/models/localized_text.dart';
import 'package:code_learn_app/models/note.dart';
import 'package:code_learn_app/services/content_pack_workbench.dart';
import 'package:code_learn_app/services/note_export_service.dart';
import 'package:code_learn_app/services/search_service.dart';

const _programming = LessonCategory(
  id: 'programming',
  title: LocalizedText(zh: '编程语言', en: 'Programming'),
  iconName: 'code',
  colorValue: 0x2563EB,
  lessons: <Lesson>[
    Lesson(
      id: 'python_basics',
      categoryId: 'programming',
      title: LocalizedText(zh: 'Python 基础语法', en: 'Python Basics'),
      summary: LocalizedText(zh: '变量、函数与缩进', en: 'Variables'),
      assetFile: 'python_basics.md',
      minutes: 12,
      keywords: <String>['变量', '函数'],
      quiz: <QuizQuestion>[],
    ),
    Lesson(
      id: 'cpp_pointers',
      categoryId: 'programming',
      title: LocalizedText(zh: 'C++ 指针', en: 'C++ Pointers'),
      summary: LocalizedText(zh: '地址与引用', en: 'Pointers'),
      assetFile: 'cpp_pointers.md',
      minutes: 14,
      keywords: <String>['指针', '内存'],
      quiz: <QuizQuestion>[],
    ),
  ],
);

Future<String> _plainTextOf(Lesson lesson) async =>
    lesson.id == 'python_basics' ? '变量 函数 缩进 循环' : '地址 引用 指针 内存';

void main() {
  group('搜索索引缓存', () {
    test('导出后可以从缓存恢复并保持相同搜索结果', () async {
      final original = LessonSearchIndex();
      await original.build(const <LessonCategory>[_programming], _plainTextOf);
      final serialized = original.toCacheJson();
      final expected = original.search('指针').map((hit) => hit.lesson.id);

      final restored = LessonSearchIndex();
      final ok = restored.restoreFromCache(const <LessonCategory>[
        _programming,
      ], serialized);
      expect(ok, isTrue);
      expect(restored.isBuilt, isTrue);
      expect(restored.search('指针').map((hit) => hit.lesson.id), expected);
      expect(restored.search('python').single.lesson.id, 'python_basics');
    });

    test('指纹不匹配时缓存失效', () async {
      final index = LessonSearchIndex();
      await index.build(const <LessonCategory>[_programming], _plainTextOf);
      final cache = index.toCacheJson();
      const changed = LessonCategory(
        id: 'programming',
        title: LocalizedText(zh: '编程语言', en: 'Programming'),
        iconName: 'code',
        colorValue: 0x2563EB,
        lessons: <Lesson>[
          Lesson(
            id: 'python_basics',
            categoryId: 'programming',
            title: LocalizedText(zh: 'Python 基础语法（新版）', en: 'Python'),
            summary: LocalizedText(zh: '变量', en: 'Variables'),
            assetFile: 'python_basics.md',
            minutes: 12,
            keywords: <String>[],
            quiz: <QuizQuestion>[],
          ),
        ],
      );
      final restored = LessonSearchIndex();
      expect(
        restored.restoreFromCache(const <LessonCategory>[changed], cache),
        isFalse,
      );
    });

    test('缓存损坏时安全返回 false', () async {
      final index = LessonSearchIndex();
      await index.build(const <LessonCategory>[_programming], _plainTextOf);
      final cache = index.toCacheJson();
      cache['documents'] = <String>['broken'];
      final restored = LessonSearchIndex();
      expect(
        restored.restoreFromCache(const <LessonCategory>[_programming], cache),
        isFalse,
      );
    });
  });

  group('NoteExportService', () {
    final notes = <Note>[
      Note(
        lessonId: 'python_basics',
        content: '列表推导式很好用',
        updatedAt: DateTime(2026, 10, 5, 9, 30),
        tags: <String>['Python', '语法'],
      ),
      Note(
        lessonId: 'cpp_pointers',
        content: '',
        updatedAt: DateTime(2026, 10, 4, 20, 0),
        tags: <String>['C++'],
      ),
    ];

    test('Markdown 导出包含标题、标签与正文', () {
      final markdown = NoteExportService.toMarkdown(
        notes,
        titleOf: (id) => id == 'python_basics' ? 'Python 基础语法' : 'C++ 指针',
      );
      expect(markdown, contains('# 学习笔记'));
      expect(markdown, contains('## Python 基础语法'));
      expect(markdown, contains('列表推导式很好用'));
      expect(markdown, contains('标签：Python、语法'));
      expect(markdown, contains('（空白笔记）'));
    });

    test('按标签筛选导出', () {
      final markdown = NoteExportService.toMarkdown(
        notes,
        titleOf: (id) => id,
        tag: 'C++',
      );
      expect(markdown, contains('共 1 条'));
      expect(markdown, isNot(contains('Python')));
    });

    test('JSON 导出可被解析且字段完整', () {
      final decoded = jsonDecode(NoteExportService.toJson(notes)) as List;
      expect(decoded.length, 2);
      final first = decoded.first as Map<String, dynamic>;
      expect(first['lessonId'], 'python_basics');
      expect(first['tags'], <String>['Python', '语法']);
    });

    test('统计给出总数、非空数与标签分布', () {
      final stats = NoteExportService.statistics(notes);
      expect(stats.total, 2);
      expect(stats.nonEmpty, 1);
      expect(stats.totalCharacters, 8);
      expect(stats.tagCounts['Python'], 1);
      expect(stats.latestUpdatedAt, DateTime(2026, 10, 5, 9, 30));
    });
  });

  group('ContentPackWorkbench', () {
    Map<String, dynamic> validPack() => <String, dynamic>{
      'schema': 'code-learn-content-pack',
      'schema_version': 1,
      'pack_id': 'demo-pack',
      'version': '1.1.0',
      'name': '演示包',
      'lessons': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'demo_1',
          'category_id': 'programming',
          'title': <String, String>{'zh': '演示课程', 'en': 'Demo'},
          'summary': <String, String>{'zh': '摘要', 'en': 'Summary'},
          'minutes': 15,
          'markdown': '# 演示\n\n${'正文内容。' * 60}',
          'quiz': <Map<String, dynamic>>[
            <String, dynamic>{
              'question': 'Q1',
              'options': <String>['A'],
            },
            <String, dynamic>{
              'question': 'Q2',
              'options': <String>['B'],
            },
          ],
        },
      ],
    };

    test('分析有效内容包统计课程、分类与题目', () {
      final analysis = ContentPackWorkbench.analyze(validPack());
      expect(analysis.hasErrors, isFalse);
      expect(analysis.packId, 'demo-pack');
      expect(analysis.lessonCount, 1);
      expect(analysis.categoryCount, 1);
      expect(analysis.questionCount, 2);
      expect(analysis.totalCharacters, greaterThan(200));
      expect(analysis.estimatedMinutes, 15);
    });

    test('检测 schema 错误、重复 id 与空正文', () {
      final pack = validPack();
      pack['schema'] = 'wrong';
      final lessons = pack['lessons'] as List<Map<String, dynamic>>;
      final broken = Map<String, dynamic>.from(lessons.first);
      broken['markdown'] = '';
      lessons.add(broken);
      final analysis = ContentPackWorkbench.analyze(pack);
      expect(analysis.hasErrors, isTrue);
      expect(
        analysis.issues.any((item) => item.message.contains('id 重复')),
        isTrue,
      );
      expect(
        analysis.issues.any((item) => item.message.contains('正文')),
        isTrue,
      );
    });

    test('diff 计算新增、更新、不变与移除', () {
      final diff = ContentPackWorkbench.diff(
        installedVersions: <String, String>{
          'keep': '1.0.0',
          'update': '1.0.0',
          'remove': '1.0.0',
        },
        incomingVersions: <String, String>{
          'keep': '1.0.0',
          'update': '2.0.0',
          'add': '1.0.0',
        },
      );
      expect(diff.added, <String>['add']);
      expect(diff.updated, <String>['update']);
      expect(diff.unchanged, <String>['keep']);
      expect(diff.removed, <String>['remove']);
      expect(diff.hasChanges, isTrue);
    });

    test('模板是合法 JSON 且能通过自身校验', () {
      final decoded =
          jsonDecode(ContentPackWorkbench.template()) as Map<String, dynamic>;
      final analysis = ContentPackWorkbench.analyze(decoded);
      expect(analysis.packId, 'my-pack');
      expect(analysis.lessonCount, 1);
      expect(analysis.hasErrors, isFalse);
    });
  });
}
