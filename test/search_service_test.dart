import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/models/lesson_category.dart';
import 'package:code_learn_app/models/localized_text.dart';
import 'package:code_learn_app/services/search_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 搜索索引单元测试：覆盖中文、英文、拼音、同义词与筛选。
void main() {
  const programming = LessonCategory(
    id: 'programming',
    title: LocalizedText(zh: '编程语言', en: 'Programming'),
    iconName: 'code',
    colorValue: 0x2563EB,
    lessons: <Lesson>[
      Lesson(
        id: 'python_basics',
        categoryId: 'programming',
        title: LocalizedText(zh: 'Python 基础语法', en: 'Python Basics'),
        summary: LocalizedText(zh: '变量、函数与缩进', en: 'Variables and functions'),
        assetFile: 'assets/content/python_basics.md',
        minutes: 12,
        keywords: <String>['变量', '函数', '缩进'],
        quiz: <QuizQuestion>[],
      ),
      Lesson(
        id: 'cpp_pointers',
        categoryId: 'programming',
        title: LocalizedText(zh: 'C++ 指针', en: 'C++ Pointers'),
        summary: LocalizedText(zh: '地址与引用', en: 'Address and reference'),
        assetFile: 'assets/content/cpp_pointers.md',
        minutes: 14,
        keywords: <String>['指针', '内存'],
        quiz: <QuizQuestion>[],
      ),
    ],
  );

  const network = LessonCategory(
    id: 'network',
    title: LocalizedText(zh: '网络', en: 'Network'),
    iconName: 'lan',
    colorValue: 0x0EA5E9,
    lessons: <Lesson>[
      Lesson(
        id: 'dns_basics',
        categoryId: 'network',
        title: LocalizedText(zh: 'DNS 域名解析', en: 'DNS Resolution'),
        summary: LocalizedText(zh: '把域名转换成 IP 地址', en: 'Resolve domain names'),
        assetFile: 'assets/content/dns_basics.md',
        minutes: 10,
        keywords: <String>['域名', '解析'],
        quiz: <QuizQuestion>[],
      ),
    ],
  );

  const database = LessonCategory(
    id: 'database',
    title: LocalizedText(zh: '数据库', en: 'Database'),
    iconName: 'storage',
    colorValue: 0x7C3AED,
    lessons: <Lesson>[
      Lesson(
        id: 'sql_index',
        categoryId: 'database',
        title: LocalizedText(zh: 'SQL 索引原理', en: 'SQL Index'),
        summary: LocalizedText(zh: 'B 树与查询优化', en: 'B tree and optimization'),
        assetFile: 'assets/content/sql_index.md',
        minutes: 16,
        keywords: <String>['索引', '查询优化'],
        quiz: <QuizQuestion>[],
      ),
    ],
  );

  const categories = <LessonCategory>[programming, network, database];

  const bodies = <String, String>{
    'python_basics': 'Python 用缩进划分代码块，变量不需要声明类型，函数用 def 定义。',
    'cpp_pointers': '指针保存变量的内存地址，解引用可以读写目标对象。',
    'dns_basics': 'DNS 把域名解析成 IP 地址，常见记录有 A、AAAA、CNAME。',
    'sql_index': '索引用 B+ 树加速查询，但写入会变慢，需要权衡。',
  };

  Future<String> plainTextOf(Lesson lesson) async => bodies[lesson.id] ?? '';

  Future<LessonSearchIndex> buildIndex() async {
    final index = LessonSearchIndex();
    await index.build(categories, plainTextOf);
    return index;
  }

  test('中文标题按完整关键词命中', () async {
    final index = await buildIndex();
    final hits = index.search('基础语法');
    expect(hits, isNotEmpty);
    expect(hits.first.lesson.id, 'python_basics');
    expect(hits.first.matchedTerms, contains('基础语法'));
  });

  test('英文关键词可命中小写化的标题', () async {
    final index = await buildIndex();
    final hits = index.search('python');
    expect(hits.first.lesson.id, 'python_basics');
  });

  test('全拼拼音可以命中中文标题', () async {
    final index = await buildIndex();
    final hits = index.search('jichuyufa');
    expect(hits, isNotEmpty);
    expect(hits.first.lesson.id, 'python_basics');
  });

  test('连续多音节拼音可以命中（索引与查询都做紧凑化）', () async {
    final index = await buildIndex();
    final hits = index.search('pythonjichu');
    expect(hits, isNotEmpty);
    expect(hits.first.lesson.id, 'python_basics');
  });

  test('三字母以上拼音首字母可以命中', () async {
    final index = await buildIndex();
    final hits = index.search('jcyf');
    expect(hits.map((hit) => hit.lesson.id), contains('python_basics'));
  });

  test('两字母首字母缩写不参与匹配，避免大范围误命中', () async {
    final index = await buildIndex();
    // sy 会巧合地出现在 dnsyumingjiexi 之类的串里，应被忽略。
    final hits = index.search('sy');
    expect(hits, isEmpty);
  });

  test('同义词扩展：域名解析可以找到 DNS 课程', () async {
    final index = await buildIndex();
    final hits = index.search('域名');
    expect(hits.first.lesson.id, 'dns_basics');
    final synonymHits = index.search('dns');
    expect(synonymHits.map((hit) => hit.lesson.id), contains('dns_basics'));
  });

  test('分类筛选只返回该分类课程', () async {
    final index = await buildIndex();
    final hits = index.search('索引', categoryId: 'database');
    expect(hits, isNotEmpty);
    expect(hits.every((hit) => hit.category.id == 'database'), isTrue);
    expect(index.search('索引', categoryId: 'network'), isEmpty);
  });

  test('lessonIds 范围筛选用于收藏、错题等场景', () async {
    final index = await buildIndex();
    final hits = index.search('指针', lessonIds: const <String>{'sql_index'});
    expect(hits, isEmpty);

    final scoped = index.search('索引', lessonIds: const <String>{'sql_index'});
    expect(scoped, hasLength(1));
    expect(scoped.first.lesson.id, 'sql_index');
  });

  test('搜索结果带命中片段', () async {
    final index = await buildIndex();
    final hits = index.search('CNAME');
    expect(hits, isNotEmpty);
    expect(hits.first.lesson.id, 'dns_basics');
    // 片段取自小写化后的索引文本，因此按 cname 断言。
    expect(hits.first.snippet, contains('cname'));
  });

  test('空查询返回空列表', () async {
    final index = await buildIndex();
    expect(index.search('   '), isEmpty);
  });
}
