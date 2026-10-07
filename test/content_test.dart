import 'dart:convert';
import 'dart:io';

import 'package:code_learn_app/models/lesson_category.dart';
import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/data/learning_paths.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/services/exam_builder.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/markdown_fences.dart';

/// 内容自检：保证内置课程与测验数据完整、可加载。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<LessonCategory> categories;
  late Map<String, dynamic> manifestJson;

  setUpAll(() async {
    final raw = await rootBundle.loadString('assets/content/manifest.json');
    manifestJson = jsonDecode(raw) as Map<String, dynamic>;
    categories = (manifestJson['categories'] as List<dynamic>)
        .map(
          (item) =>
              LessonCategory.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  });

  test('每个知识点都标注了合法的难度', () {
    const allowed = <String>{'入门', '基础', '进阶', '高级'};
    final missing = <String>[];
    for (final category in manifestJson['categories'] as List<dynamic>) {
      for (final lesson in ((category as Map)['lessons'] as List<dynamic>)) {
        final map = (lesson as Map).cast<String, dynamic>();
        final difficulty = (map['difficulty'] as String? ?? '').trim();
        if (!allowed.contains(difficulty)) {
          missing.add('${map['id']}（$difficulty）');
        }
      }
    }
    expect(missing, isEmpty, reason: '缺少难度的知识点：${missing.join('、')}');
  });

  test('分类结构完整：至少 5 个分类且其中至少 5 类有 3 篇以上', () {
    expect(categories.length, greaterThanOrEqualTo(5));
    for (final category in categories) {
      expect(
        category.lessons.length,
        greaterThanOrEqualTo(1),
        reason: '分类 ${category.id} 没有知识点',
      );
    }
    // 主干课程保证每类至少 3 篇（新增的方向性分类允许先以 1 篇起步）
    final majorCategories = categories
        .where((category) => category.lessons.length >= 3)
        .length;
    expect(
      majorCategories,
      greaterThanOrEqualTo(5),
      reason: '至少有 5 个分类需要 3 篇以上内容',
    );
  });

  test('每个知识点都有 3-6 道测验题且答案下标合法', () {
    for (final category in categories) {
      for (final lesson in category.lessons) {
        // GitHub 同步的开源阅读材料不带测验，其余知识点为 3-5 道基础题，
        // 另可加 1 道排序/填空/多选扩展题。
        if (!lesson.id.startsWith('gh_')) {
          expect(
            lesson.quiz.length,
            inInclusiveRange(3, 6),
            reason: '${lesson.id} 的题量不符合要求',
          );
        }
        for (final question in lesson.quiz) {
          if (question.type == 'fill') {
            expect(question.acceptedAnswers, isNotEmpty);
          } else {
            expect(question.options.length, greaterThanOrEqualTo(2));
            expect(
              question.answerIndex,
              inInclusiveRange(0, question.options.length - 1),
            );
          }
          if (question.type == 'multi') {
            expect(question.answerIndexes.length, greaterThanOrEqualTo(2));
          }
          if (question.type == 'order') {
            expect(question.correctOrder.length, question.options.length);
          }
          expect(question.explanation, isNotEmpty);
        }
      }
    }
  });

  test('每篇 Markdown 教程都能从 assets 加载', () async {
    for (final category in categories) {
      for (final lesson in category.lessons) {
        final markdown = await rootBundle.loadString(lesson.assetFile);
        expect(markdown.trim(), isNotEmpty, reason: '${lesson.id} 内容为空');
      }
    }
  });

  test('Markdown 中引用的本地配图都存在且可加载', () async {
    final imagePattern = RegExp(
      r'!\[[^\]]*\]\(([^)]+\.(?:png|webp))\)',
      caseSensitive: false,
    );
    final checked = <String>{};

    for (final category in categories) {
      for (final lesson in category.lessons) {
        final markdown = await rootBundle.loadString(lesson.assetFile);
        for (final match in imagePattern.allMatches(markdown)) {
          final rawPath = match.group(1)!;
          if (rawPath.startsWith('http')) {
            continue;
          }
          final assetPath = rawPath.startsWith('assets/')
              ? rawPath
              : 'assets/content/$rawPath';
          if (!checked.add(assetPath)) {
            continue;
          }
          final data = await rootBundle.load(assetPath);
          expect(
            data.lengthInBytes,
            greaterThan(0),
            reason: '${lesson.id} 引用的配图为空：$assetPath',
          );
        }
      }
    }

    expect(checked, isNotEmpty, reason: '教程中应至少引用一张本地配图');
  });

  test('每篇教程都有统一学习支架且正文不少于 3000 字符', () async {
    const sections = <String>[
      '## 学习目标',
      '## 前置知识',
      '## 动手练习',
      '## 本课小结',
      '内容更新时间：2026-10-06',
    ];

    for (final category in categories) {
      for (final lesson in category.lessons) {
        final markdown = await rootBundle.loadString(lesson.assetFile);
        for (final section in sections) {
          expect(
            markdown,
            contains(section),
            reason: '${lesson.id} 缺少「$section」',
          );
        }
        expect(
          markdown.length,
          greaterThanOrEqualTo(3000),
          reason: '${lesson.id} 正文只有 ${markdown.length} 字符',
        );
      }
    }
  });

  test('P1/P2 结构统一：规范章节、术语表与复核标记全部达标', () async {
    const canonicalSections = <String>[
      '学习目标',
      '前置知识',
      '动手练习',
      '考点精讲',
      '故障现场',
      '本课小结',
      '参考资料与复核',
      'English Overview',
      '内容元数据',
      '本课复习清单',
      '术语速查',
      '可运行练习',
      '常见错误与排查',
      '复习与自测',
    ];
    // 已被规范名取代的旧标题：再次出现说明退回了旧命名。
    const legacySections = <String>[
      '常见错误对照表',
      '常见错误',
      '常见错误速查',
      '常见误区',
      '常见坑',
      '常见陷阱',
      '常见问题',
      '常见问题与对策',
      '常见问题与排查顺序',
      '常见风险速查',
      '常见失败模式',
      '常见反模式速查',
      '反模式',
      '失败模式',
      '新手最容易踩的八个坑',
      '新手最容易踩的六个坑',
      '必须注意的坑',
      '五个高频坑',
      '三个经典坑',
      '易错点回顾',
      '自测清单',
      '逐节复习与自检',
      '深度追问与自测',
      '本课自测清单与错误对照',
      '实践任务',
    ];

    // 代码围栏里的 `## 标题` 是示例文本，判定章节时要先屏蔽。
    String maskFenced(String markdown) {
      final lines = markdown.split('\n');
      final mask = markdownFenceMask(markdown);
      return <String>[
        for (var index = 0; index < lines.length; index++)
          mask[index] ? ' ' * lines[index].length : lines[index],
      ].join('\n');
    }

    RegExp heading(String title) =>
        RegExp('^##\\s+${RegExp.escape(title)}\\s*\$', multiLine: true);

    String sectionBody(String markdown, String title) {
      final match = heading(title).firstMatch(markdown);
      if (match == null) return '';
      final rest = markdown.substring(match.end);
      final next = RegExp(r'^##\s+', multiLine: true).firstMatch(rest);
      return next == null ? rest : rest.substring(0, next.start);
    }

    final missing = <String>[];
    final duplicated = <String>[];
    final legacy = <String>[];
    final thin = <String>[];
    for (final category in categories) {
      for (final lesson in category.lessons) {
        final markdown = await rootBundle.loadString(lesson.assetFile);
        final checked = maskFenced(markdown);
        for (final title in canonicalSections) {
          final hits = heading(title).allMatches(checked).length;
          if (hits == 0) missing.add('${lesson.id}:$title');
          if (hits > 1) duplicated.add('${lesson.id}:$title($hits)');
        }
        for (final title in legacySections) {
          if (heading(title).hasMatch(checked)) {
            legacy.add('${lesson.id}:$title');
          }
        }
        final checklistItems = RegExp(
          r'^- \[ \] ',
          multiLine: true,
        ).allMatches(sectionBody(checked, '本课复习清单')).length;
        if (checklistItems < 3) {
          thin.add('${lesson.id}:本课复习清单($checklistItems)');
        }
        final glossary = sectionBody(checked, '术语速查');
        final termRows = glossary
            .split('\n')
            .where((line) => line.trimLeft().startsWith('|'))
            .length;
        // 表头 + 分隔行 + 至少 4 行术语。
        if (termRows < 6) {
          thin.add('${lesson.id}:术语速查(${termRows - 2} 条)');
        }
        final termHeader = glossary
            .split('\n')
            .map((line) => line.trim())
            .firstWhere((line) => line.startsWith('|'), orElse: () => '');
        if (termHeader != '| 术语 | 一句话说明 |') {
          thin.add('${lesson.id}:表头($termHeader)');
        }
        if (checked.contains('| 题目 | 容易踩的做法 | 正确结论 |')) {
          thin.add('${lesson.id}:未复核的自动错误表');
        }
      }
    }
    expect(missing, isEmpty, reason: '缺少规范章节：${missing.take(15).join('、')}');
    expect(
      duplicated,
      isEmpty,
      reason: '重复规范章节：${duplicated.take(15).join('、')}',
    );
    expect(legacy, isEmpty, reason: '残留旧标题：${legacy.take(15).join('、')}');
    expect(thin, isEmpty, reason: '章节内容过薄：${thin.take(15).join('、')}');
  });

  test('九种语言分类都至少有 2 个项目课', () {
    const languageCategoryIds = <String>{
      'python',
      'cpp',
      'java',
      'javascript',
      'csharp',
      'go',
      'rust',
      'typescript',
      'shell',
    };

    for (final categoryId in languageCategoryIds) {
      final matches = categories
          .where((category) => category.id == categoryId)
          .toList();
      expect(matches, hasLength(1), reason: '分类 $categoryId 不存在');
      final category = matches.first;
      final projects = category.lessons.where((lesson) {
        return lesson.id.contains('project') ||
            lesson.title.zh.contains('实战') ||
            lesson.title.zh.contains('项目');
      }).toList();
      expect(
        projects.length,
        greaterThanOrEqualTo(2),
        reason: '$categoryId 只有 ${projects.length} 个项目课',
      );
    }
  });

  test('原薄课加厚后均不少于 6000 字符', () async {
    const thinLessonIds = <String>{
      'linking_loading',
      'link_layer',
      'bus_io',
      'math_probability_stats',
      'memory_cache',
      'olap_columnar',
      'probability',
      'realtime_warehouse',
      'cross_first_program',
      'distributed_consensus',
      'compiler_frontend',
      'math_graph_combinatorics',
      'cache_eviction',
      'db_design',
      'interrupt_exception',
      'requirements_modeling',
      'storage_engine',
      'stack_queue',
      'microservices',
      'visual_btree_index',
      'wireless_mobile',
      'visual_memory_layout',
      'se_oncall',
      'pentest_basics',
      'cross_package_manage',
      'semantics_analysis',
      'data_lakehouse',
      'hash_table',
      'distributed_cache',
      'visual_db_isolation',
      'visual_git_states',
      'performance_metrics',
      'bigdata_batch_stream',
      'cross_ci_config',
      'se_tech_writing',
      'se_tech_debt',
      'sorting_advanced',
      'balanced_tree',
      'graphics_media',
      'codegen_registers',
      'database_project',
      'cross_i18n',
      'css_render_animation',
      'visual_tcp_handshake',
      'project_retro_improve',
      'cross_api_contract',
      'search_index',
      'math_numerical_linear_algebra',
    };
    final allLessons = categories
        .expand((category) => category.lessons)
        .toList();

    for (final id in thinLessonIds) {
      final matches = allLessons.where((lesson) => lesson.id == id).toList();
      expect(matches, isNotEmpty, reason: '原薄课 $id 不存在');
      final markdown = await rootBundle.loadString(matches.first.assetFile);
      expect(
        markdown.length,
        greaterThanOrEqualTo(6000),
        reason: '$id 加厚后只有 ${markdown.length} 字符',
      );
    }
  });

  test('全部课程正文不少于 6000 字符', () async {
    for (final category in categories) {
      for (final lesson in category.lessons) {
        final markdown = await rootBundle.loadString(lesson.assetFile);
        expect(
          markdown.length,
          greaterThanOrEqualTo(6000),
          reason: '${lesson.id} 正文只有 ${markdown.length} 字符',
        );
      }
    }
  });

  test('测验 P0 质量：解析、答案分布、去重和题型', () {
    final questions = categories
        .expand((category) => category.lessons)
        .expand((lesson) => lesson.quiz)
        .toList();
    final shortExplanations = questions
        .where((question) => question.explanation.trim().length < 120)
        .toList();
    expect(
      shortExplanations,
      isEmpty,
      reason: '仍有 ${shortExplanations.length} 道解析少于 120 字符',
    );

    final metaQuestions = questions
        .where((question) => RegExp(r'《.+?》').hasMatch(question.question))
        .toList();
    expect(
      metaQuestions,
      isEmpty,
      reason: '仍有 ${metaQuestions.length} 道复述课程标题的元问题',
    );

    final sentenceCounts = <String, int>{};
    for (final question in questions) {
      for (final sentence in question.explanation.split(RegExp(r'[。；\n]'))) {
        final trimmed = sentence.trim();
        if (trimmed.length < 12) continue;
        sentenceCounts[trimmed] = (sentenceCounts[trimmed] ?? 0) + 1;
      }
    }
    final templateSentences = sentenceCounts.entries
        .where((entry) => entry.value >= 5)
        .toList();
    expect(
      templateSentences,
      isEmpty,
      reason:
          '解析中仍有 ${templateSentences.length} 种重复 5 次以上的模板句：'
          '${templateSentences.take(3).map((entry) => entry.key).join(' / ')}',
    );

    final singleChoiceQuestions = questions
        .where((question) => question.type == 'single')
        .toList();

    var stronglyLongest = 0;
    for (final question in singleChoiceQuestions) {
      if (question.answerIndex >= question.options.length) continue;
      final correctLength = question.options[question.answerIndex]
          .trim()
          .length;
      var secondLongest = -1;
      for (var index = 0; index < question.options.length; index++) {
        if (index == question.answerIndex) continue;
        final length = question.options[index].trim().length;
        if (length > secondLongest) secondLongest = length;
      }
      if (secondLongest >= 0 && correctLength - secondLongest >= 8) {
        stronglyLongest++;
      }
    }
    final stronglyLongestRate =
        stronglyLongest * 100 / singleChoiceQuestions.length;
    expect(
      stronglyLongestRate,
      lessThan(30),
      reason:
          '正确项明显最长（差距>=8）的比例为 '
          '${stronglyLongestRate.toStringAsFixed(1)}%',
    );

    final answerCounts = <int, int>{};
    for (final question in singleChoiceQuestions) {
      answerCounts[question.answerIndex] =
          (answerCounts[question.answerIndex] ?? 0) + 1;
    }
    for (var index = 0; index < 4; index++) {
      final percent =
          (answerCounts[index] ?? 0) * 100 / singleChoiceQuestions.length;
      expect(
        percent,
        inInclusiveRange(22, 28),
        reason: '单选答案下标 $index 占比 ${percent.toStringAsFixed(1)}%',
      );
    }

    final normalized = questions
        .map((question) => question.question.replaceAll(RegExp(r'\s+'), ''))
        .toList();
    expect(normalized.toSet().length, normalized.length, reason: '题库存在重复题干');

    final types = questions.map((question) => question.type).toSet();
    for (final type in const ['code', 'debug', 'order', 'fill', 'multi']) {
      expect(types, contains(type), reason: '缺少 $type 题型');
    }
    final codeQuestions = questions
        .where((question) => question.type == 'code')
        .toList();
    expect(codeQuestions.length, greaterThanOrEqualTo(9));
    expect(
      codeQuestions.every(
        (question) => (question.code ?? '').trim().isNotEmpty,
      ),
      isTrue,
      reason: '代码输出题必须包含代码片段',
    );

    final fillQuestions = questions
        .where((question) => question.type == 'fill')
        .toList();
    expect(fillQuestions, isNotEmpty);
    expect(
      fillQuestions.every((question) => question.acceptedAnswers.isNotEmpty),
      isTrue,
      reason: '填空题必须配置可接受答案',
    );

    final multiQuestions = questions
        .where((question) => question.type == 'multi')
        .toList();
    expect(multiQuestions, isNotEmpty);
    expect(
      multiQuestions.every((question) => question.answerIndexes.length >= 2),
      isTrue,
      reason: '多选题必须至少有两个正确选项',
    );

    final orderQuestions = questions
        .where((question) => question.type == 'order')
        .toList();
    expect(orderQuestions, isNotEmpty);
    expect(
      orderQuestions.every(
        (question) => question.correctOrder.length == question.options.length,
      ),
      isTrue,
      reason: '排序题正确顺序必须覆盖全部选项',
    );
  });

  test('代码块有语言标记，项目课包含验证命令与预期输出', () async {
    for (final category in categories) {
      for (final lesson in category.lessons) {
        final markdown = await rootBundle.loadString(lesson.assetFile);
        var inFence = false;
        for (final line in markdown.split('\n')) {
          if (!line.trimLeft().startsWith('```')) continue;
          if (inFence) {
            inFence = false;
            continue;
          }
          inFence = true;
          final language = line.trimLeft().substring(3).trim();
          expect(language, isNotEmpty, reason: '${lesson.id} 存在无语言标记的代码块');
        }
        if (lesson.id.contains('project') ||
            lesson.title.zh.contains('实战') ||
            lesson.title.zh.contains('项目')) {
          expect(
            markdown,
            contains('## 验证命令与预期输出'),
            reason: '${lesson.id} 缺少验证命令与预期输出',
          );
        }
      }
    }
  });

  test('P1 覆盖：安全、AI、语言、核心课程与去模板化', () {
    const legacyMarkers = <String>[
      '练习闭环应该怎么填空',
      '正确的操作顺序是',
      '最小示例，预期输出是什么',
      '最容易出现的错误是',
    ];
    final legacyQuestions = categories
        .expand((category) => category.lessons)
        .expand((lesson) => lesson.quiz)
        .where(
          (question) =>
              legacyMarkers.any((marker) => question.question.contains(marker)),
        )
        .toList();
    expect(
      legacyQuestions,
      isEmpty,
      reason: '题库仍残留 ${legacyQuestions.length} 道旧版模板题',
    );
    expect(manifestJson['p1_quiz_version'], 1);

    final byId = <String, LessonCategory>{
      for (final category in categories) category.id: category,
    };
    for (final entry in const <String, int>{
      'security': 12,
      'c': 10,
      'kotlin': 8,
      'swift': 8,
      'python': 16,
      'cpp': 16,
      'java': 16,
      'javascript': 16,
      'csharp': 14,
      'rust': 13,
      'typescript': 17,
      'go': 17,
      'shell': 17,
      'ai': 36,
      'fundamentals': 28,
      'os': 16,
      'algorithms': 33,
      'network': 22,
      'database': 25,
    }.entries) {
      final category = byId[entry.key];
      expect(category, isNotNull, reason: '缺少分类 ${entry.key}');
      expect(
        category!.lessons.length,
        greaterThanOrEqualTo(entry.value),
        reason: '${entry.key} 课程数不足',
      );
    }

    final allIds = categories
        .expand((category) => category.lessons)
        .map((lesson) => lesson.id)
        .toSet();
    for (final id in const <String>[
      'ai_mcp',
      'ai_a2a',
      'ai_computer_use',
      'ai_browser_agent',
      'ai_coding_agent',
      'ai_guardrails',
      'ai_graphrag',
      'ai_vlm',
      'ai_diffusion',
      'ai_realtime_api',
      'ai_model_serving',
      'ai_governance',
    ]) {
      expect(allIds, contains(id), reason: '缺少 P1 AI 课程 $id');
    }
    expect(
      learningPaths.length,
      greaterThanOrEqualTo(16),
      reason: '学习路径应扩展到 16 条以上',
    );
  });

  test('P2 体验：配图、英文概览、元数据与项目专属规格', () async {
    var imageLessons = 0;
    for (final category in categories) {
      for (final lesson in category.lessons) {
        final markdown = await rootBundle.loadString(lesson.assetFile);
        if (RegExp(r'!\[[^\]]*\]\(images/').hasMatch(markdown)) {
          imageLessons++;
        }
        expect(
          markdown,
          contains('## English Overview'),
          reason: '${lesson.id} 缺少英文概览',
        );
        expect(markdown, contains('## 内容元数据'), reason: '${lesson.id} 缺少内容元数据');
        expect(markdown, contains('内容版本：v2.0'), reason: '${lesson.id} 缺少内容版本');
        final isProject =
            lesson.id.contains('project') ||
            lesson.title.zh.contains('实战') ||
            lesson.title.zh.contains('项目');
        if (isProject) {
          expect(
            markdown,
            contains('## 项目专属规格'),
            reason: '${lesson.id} 缺少项目专属规格',
          );
        }
      }
    }
    expect(
      imageLessons,
      greaterThanOrEqualTo(100),
      reason: '配图课程应达到 100 篇以上，当前 $imageLessons',
    );

    final visualGuide = categories.firstWhere(
      (category) => category.id == 'visual_guide',
    );
    for (final lesson in visualGuide.lessons) {
      final markdown = await rootBundle.loadString(lesson.assetFile);
      expect(
        RegExp(r'!\[[^\]]*\]\(images/').hasMatch(markdown),
        isTrue,
        reason: '图解专题 ${lesson.id} 缺少配图',
      );
    }
  });

  test('P0 学习路径不变量：难度不倒挂、先修在前、order 连续', () {
    const ladder = <String>['入门', '基础', '进阶', '高级'];
    int rank(String difficulty) => ladder.indexOf(difficulty);
    final byId = <String, Lesson>{
      for (final category in categories)
        for (final lesson in category.lessons) lesson.id: lesson,
    };

    for (final category in categories) {
      if (category.lessons.isEmpty) continue;
      final ordered = <Lesson>[...category.lessons]
        ..sort((a, b) => a.order.compareTo(b.order));
      // order 必须是 0..n-1 的连续编号，App 才能按推荐顺序学习。
      for (var i = 0; i < ordered.length; i++) {
        expect(ordered[i].order, i, reason: '${category.id} 的 order 必须是连续编号');
      }
      // 难度沿推荐顺序非递减，避免「学完高级再学入门」。
      for (var i = 1; i < ordered.length; i++) {
        expect(
          rank(ordered[i].difficulty),
          greaterThanOrEqualTo(rank(ordered[i - 1].difficulty)),
          reason:
              '${category.id} 在「${ordered[i - 1].title.zh}」'
              '(${ordered[i - 1].difficulty}) 之后出现更简单的'
              '「${ordered[i].title.zh}」(${ordered[i].difficulty})',
        );
      }
      // 先修课必须排在本课之前，且难度不得高于本课。
      final position = <String, int>{
        for (var i = 0; i < ordered.length; i++) ordered[i].id: i,
      };
      for (final lesson in ordered) {
        for (final id in lesson.prerequisites) {
          final prerequisite = byId[id];
          expect(prerequisite, isNotNull, reason: '${lesson.id} 的先修 $id 不存在');
          if (prerequisite == null) continue;
          expect(
            rank(prerequisite.difficulty),
            lessThanOrEqualTo(rank(lesson.difficulty)),
            reason: '先修 ${prerequisite.id} 比 ${lesson.id} 更难',
          );
          final prerequisitePosition = position[prerequisite.id];
          if (prerequisitePosition != null) {
            expect(
              prerequisitePosition,
              lessThan(position[lesson.id]!),
              reason: '先修 ${prerequisite.id} 没有排在 ${lesson.id} 之前',
            );
          }
        }
      }
      expect(
        ordered.first.difficulty,
        isNot('高级'),
        reason: '${category.id} 第一课不应标为高级',
      );
      expect(
        ordered.last.difficulty,
        isNot('入门'),
        reason: '${category.id} 最后一课不应标为入门',
      );
    }
    for (final entry in const <String, String>{
      'go_interfaces_errors': '进阶',
      'rust_ownership': '进阶',
      'ts_narrowing_generics': '进阶',
      'cross_i18n': '进阶',
      'binary_search': '基础',
      'bubble_sort': '基础',
      'security_threat_model': '基础',
    }.entries) {
      expect(byId[entry.key]?.difficulty, entry.value, reason: entry.key);
    }
  });

  test('P3：入门梯度、代码示例、英文指南、项目交付与配图', () async {
    var beginnerOrBasic = 0;
    var withCode = 0;
    var englishGuides = 0;
    var projectDeliveries = 0;
    var projectCount = 0;
    var imageLessons = 0;
    var total = 0;

    for (final category in categories) {
      for (final lesson in category.lessons) {
        total++;
        final markdown = await rootBundle.loadString(lesson.assetFile);
        if (lesson.difficulty == '入门' || lesson.difficulty == '基础') {
          beginnerOrBasic++;
        }
        if (RegExp(
          r'^```(?!text|markdown)[A-Za-z0-9_+-]+',
          multiLine: true,
        ).hasMatch(markdown)) {
          withCode++;
        }
        if (markdown.contains('## Full English Study Guide')) {
          englishGuides++;
        }
        if (RegExp(r'!\[[^\]]*\]\(images/').hasMatch(markdown)) {
          imageLessons++;
        }
        final isProject =
            lesson.id.contains('project') ||
            lesson.title.zh.contains('实战') ||
            lesson.title.zh.contains('项目');
        if (isProject) {
          projectCount++;
          if (markdown.contains('## 项目交付物')) projectDeliveries++;
        }
      }
    }

    expect(
      beginnerOrBasic / total,
      greaterThanOrEqualTo(0.30),
      reason: '入门与基础课程应达到 30%',
    );
    expect(withCode, total, reason: '仍有课程没有编程语言代码示例');
    expect(englishGuides, greaterThanOrEqualTo(50));
    expect(projectDeliveries, projectCount);
    expect(imageLessons, greaterThanOrEqualTo(200));
  });

  test('P0：特殊题型可判分且学习路径有自测与结业项目', () async {
    final questions = categories
        .expand((category) => category.lessons)
        .expand((lesson) => lesson.quiz)
        .toList();
    final special = questions
        .where((question) => question.type != 'single')
        .toList();
    expect(
      special.length,
      greaterThanOrEqualTo(20),
      reason: '特殊题型只有 ${special.length} 道',
    );
    final incompleteInteractive = special.where(
      (question) =>
          (question.type == 'fill' && question.acceptedAnswers.isEmpty) ||
          (question.type == 'order' && question.correctOrder.isEmpty),
    );
    expect(incompleteInteractive, isEmpty, reason: '填空和排序题必须配置新字段，不能保留旧版占位题');

    final provider = ContentProvider();
    await provider.load();
    for (final path in learningPaths) {
      final lessons = resolvePathLessons(provider, path);
      expect(lessons, isNotEmpty, reason: '路径 ${path.id} 没有知识点');
      final minutes = lessons.fold<int>(
        0,
        (sum, lesson) => sum + lesson.minutes,
      );
      expect(minutes, greaterThan(0), reason: '路径 ${path.id} 缺少时长');
      final hasCapstone = lessons.any(
        (lesson) =>
            lesson.id.contains('project') ||
            lesson.title.zh.contains('实战') ||
            lesson.title.zh.contains('项目'),
      );
      expect(hasCapstone, isTrue, reason: '路径 ${path.id} 缺少结业项目');
    }
  });

  test('P4：去模板化、全量配图、English Guide 与项目交付', () async {
    final questions = categories
        .expand((category) => category.lessons)
        .expand((lesson) => lesson.quiz)
        .toList();
    expect(
      questions.where(
        (question) =>
            question.explanation.contains('补充：') ||
            question.explanation.contains('做题时先圈出题干') ||
            question.explanation.contains('本题的关键判断点'),
      ),
      isEmpty,
      reason: '解析中仍有自动扩写模板',
    );

    var images = 0;
    var englishGuides = 0;
    var bilingualOutlines = 0;
    var projectDeliveries = 0;
    var projects = 0;
    for (final category in categories) {
      for (final lesson in category.lessons) {
        final markdown = await rootBundle.loadString(lesson.assetFile);
        if (RegExp(r'!\[[^\]]*\]\(images/').hasMatch(markdown)) images++;
        if (markdown.contains('## Full English Study Guide')) englishGuides++;
        if (markdown.contains('## Bilingual Section Outline')) {
          bilingualOutlines++;
        }
        final isProject =
            lesson.id.contains('project') ||
            lesson.title.zh.contains('实战') ||
            lesson.title.zh.contains('项目');
        if (isProject) {
          projects++;
          if (markdown.contains('## 项目交付物')) projectDeliveries++;
        }
        expect(
          markdown,
          isNot(contains('## 工程化拆解')),
          reason: '${lesson.id} 仍有通用扩写段',
        );
      }
    }
    expect(images, categories.expand((c) => c.lessons).length);
    expect(englishGuides, greaterThanOrEqualTo(50));
    expect(bilingualOutlines, greaterThanOrEqualTo(50));
    expect(projectDeliveries, projects);
  });

  test('英文正文文件可加载并标注部分翻译状态', () async {
    var count = 0;
    for (final category in categories) {
      for (final lesson in category.lessons) {
        final path = lesson.assetFileEn;
        if (path == null || path.isEmpty) continue;
        count++;
        final markdown = await rootBundle.loadString(path);
        expect(
          markdown,
          contains('Translation status: machine translation'),
          reason: '${lesson.id} 英文文件缺少翻译状态说明',
        );
      }
    }
    expect(count, greaterThanOrEqualTo(55));
  });

  test('每课考点精讲与当前题库一致，且不含旧版元问题', () async {
    for (final category in categories) {
      for (final lesson in category.lessons) {
        final markdown = await rootBundle.loadString(lesson.assetFile);
        expect(markdown, contains('## 考点精讲'), reason: '${lesson.id} 缺少考点精讲');
        final focusIndex = markdown.indexOf('## 考点精讲');
        final englishIndex = markdown.indexOf('## English Overview');
        expect(
          focusIndex,
          lessThan(englishIndex),
          reason: '${lesson.id} 的考点精讲应放在英文概览之前',
        );
        expect(
          RegExp(r'《[^》]+》的[“"]').hasMatch(markdown),
          isFalse,
          reason: '${lesson.id} 仍保留旧版元问题引用',
        );
        final normalized = markdown.replaceAll(RegExp(r'\s+'), '');
        for (final question in lesson.quiz) {
          final questionText = question.question.replaceAll(RegExp(r'\s+'), '');
          expect(
            normalized.contains(questionText),
            isTrue,
            reason: '${lesson.id} 的考点精讲没有覆盖题目：${question.question}',
          );
        }
      }
    }
  });

  test('学习路径引用的知识点都存在且数量充足', () async {
    final provider = ContentProvider();
    await provider.load();
    final allLessonIds = provider.allLessons.map((lesson) => lesson.id).toSet();
    final allCategoryIds = provider.categories
        .map((category) => category.id)
        .toSet();
    for (final path in learningPaths) {
      for (final id in path.lessonIds) {
        expect(
          allLessonIds.contains(id),
          isTrue,
          reason: '路径 ${path.id} 引用了不存在的知识点 $id',
        );
      }
      for (final id in path.categoryIds) {
        expect(
          allCategoryIds.contains(id),
          isTrue,
          reason: '路径 ${path.id} 引用了不存在的分类 $id',
        );
      }
      final lessons = resolvePathLessons(provider, path);
      expect(
        lessons.length,
        greaterThanOrEqualTo(5),
        reason: '路径 ${path.id} 只解析到 ${lessons.length} 个知识点，检查 ID 是否写错',
      );
    }
  });

  test('复习间隔按自适应算法递增，答错回落', () async {
    final progress = ProgressProvider(StorageService.inMemory());

    await progress.scheduleReview('demo', perfect: true);
    final first = progress.reviewDueAt('demo')!;
    expect(first.difference(DateTime.now()).inHours, inInclusiveRange(23, 25));

    await progress.scheduleReview('demo', perfect: true);
    final second = progress.reviewDueAt('demo')!;
    expect(second.difference(DateTime.now()).inDays, inInclusiveRange(2, 3));

    await progress.scheduleReview('demo', perfect: false);
    final afterWrong = progress.reviewDueAt('demo')!;
    expect(
      afterWrong.difference(DateTime.now()).inHours,
      inInclusiveRange(23, 25),
    );
  });

  test('模拟考试组卷：题量正确、知识点不重复、答案下标合法', () {
    final lessons = categories.expand((category) => category.lessons).toList();
    final paper = buildExamPaper(lessons, size: 10, seed: 42);

    expect(paper.length, 10);
    expect(
      paper.map((item) => item.lesson.id).toSet().length,
      10,
      reason: '同一知识点不应在一份考卷里出现两次',
    );
    for (final item in paper) {
      if (item.question.type == 'fill') {
        expect(item.question.acceptedAnswers, isNotEmpty);
      } else {
        expect(
          item.question.answerIndex,
          inInclusiveRange(0, item.question.options.length - 1),
        );
      }
    }
  });

  test('P2 资源与引用：逐课复核、官方来源和 WebP 图片', () async {
    expect(manifestJson['p2_references_version'], 1);
    expect(manifestJson['content_last_reviewed_at'], '2026-10-04');
    expect(manifestJson['content_next_review_at'], '2027-04-04');

    final missingReferences = <String>[];
    final pngReferences = <String>[];
    for (final category in categories) {
      for (final lesson in category.lessons) {
        final markdown = await rootBundle.loadString(lesson.assetFile);
        if (!markdown.contains('## 参考资料与复核') ||
            !markdown.contains('- 最后复核：2026-10-04') ||
            !markdown.contains('- 下次复核：2027-04-04')) {
          missingReferences.add(lesson.id);
        }
        final links = RegExp(r'https?://').allMatches(markdown).length;
        if (links < 2) missingReferences.add('${lesson.id}(links=$links)');
        if (RegExp(r'images/[^)]+\.png').hasMatch(markdown)) {
          pngReferences.add(lesson.id);
        }
      }
    }
    expect(missingReferences, isEmpty, reason: '缺少逐课引用或复核日期');
    expect(pngReferences, isEmpty, reason: '仍有 PNG 图片引用');

    final imageDirectory = Directory('assets/content/images');
    expect(imageDirectory.existsSync(), isTrue);
    expect(
      imageDirectory.listSync().whereType<File>().where(
        (file) => file.path.toLowerCase().endsWith('.png'),
      ),
      isEmpty,
      reason: 'PNG 转 WebP 后不应再保留 PNG 文件',
    );
  });

  test('P0/P1 内容治理：H1、占位符、内部题号、复习章节与语言匹配', () async {
    const expectedLanguageByCategory = <String, String>{
      'python': 'python',
      'c': 'c',
      'cpp': 'cpp',
      'java': 'java',
      'javascript': 'javascript',
      'typescript': 'typescript',
      'csharp': 'csharp',
      'go': 'go',
      'rust': 'rust',
      'kotlin': 'kotlin',
      'swift': 'swift',
      'shell': 'shell',
    };
    const placeholderTitle = '本课主题';
    const markdownTemplateMarkers = <String>[
      '先自己作答，再看「判断依据」',
      '**迁移检查**',
      '本课在「',
      '本课还在「',
      '本课在核心知识',
      '本课还在核心知识',
      '课程摘要指出',
      '回到正文对应章节补足概念',
      '把题干里的一个条件换成边界值',
      '把现象和原因写在一起',
      '错误信息通常会指出出错行和期望符号',
    ];
    const explanationTemplateMarkers = <String>[
      '这道题对应的课程',
      '修正后要重跑',
      '本课在「',
      '本课还在「',
      '本课把「',
      '本课在核心知识',
      '本课还在核心知识',
      '对照「',
      '课程摘要',
    ];
    const genericPythonQuestionMarkers = <String>[
      'bucket=[]',
      'items.remove(item)',
      'range(len(data) + 1)',
      '相关的一个常见故障',
    ];
    final internalQuestionIdPattern = RegExp(
      r'[（(]\s*[A-Za-z0-9_]+\s*第\s*\d+\s*题\s*[)）]',
    );

    String sectionOf(String markdown, String heading) {
      final match = RegExp(
        '^##\\s+${RegExp.escape(heading)}\\s*\$',
        multiLine: true,
      ).firstMatch(markdown);
      if (match == null) return '';
      final rest = markdown.substring(match.end);
      final next = RegExp(r'^##\s+', multiLine: true).firstMatch(rest);
      return next == null ? rest : rest.substring(0, next.start);
    }

    List<String> referenceUrls(String markdown) {
      final heading = RegExp(
        r'^##\s+参考资料与复核\s*$',
        multiLine: true,
      ).firstMatch(markdown);
      if (heading == null) return const <String>[];
      final rest = markdown.substring(heading.end);
      final next = RegExp(r'^##\s+', multiLine: true).firstMatch(rest);
      final section = next == null ? rest : rest.substring(0, next.start);
      return RegExp(r'\[[^\]]+\]\((https?://[^)\s]+)\)')
          .allMatches(section)
          .map((match) => match.group(1)!)
          .toSet()
          .toList()
        ..sort();
    }

    final headingMismatches = <String>[];
    final placeholderHits = <String>[];
    final internalIdHits = <String>[];
    final duplicateReviewSections = <String>[];
    final staleReviewSupplements = <String>[];
    final corruptTermTables = <String>[];
    final truncatedStems = <String>[];
    final genericPythonQuestions = <String>[];
    final templateHits = <String>[];
    final languageMismatches = <String>[];
    final referenceSets = <String, Map<String, List<String>>>{};
    final emptySections = <String>[];
    final templatePlaceholders = <String>[];
    final genericTermRows = <String>[];

    for (final rawCategory in manifestJson['categories'] as List<dynamic>) {
      final category = (rawCategory as Map).cast<String, dynamic>();
      final categoryId = category['id'].toString();
      final expectedLanguage = expectedLanguageByCategory[categoryId];
      for (final rawLesson in category['lessons'] as List<dynamic>) {
        final lesson = (rawLesson as Map).cast<String, dynamic>();
        final id = lesson['id'].toString();
        final markdown = await rootBundle.loadString(lesson['file'].toString());
        final title = ((lesson['title'] as Map?)?['zh'] ?? id)
            .toString()
            .trim();

        // P0：小节必须有正文；空标题与模板占位符一律视为缺陷。
        final sectionHeadings = <(int, int, String)>[];
        var inFenceForSections = false;
        final markdownLines = markdown.split('\n');
        for (var lineIndex = 0; lineIndex < markdownLines.length; lineIndex++) {
          final line = markdownLines[lineIndex];
          if (line.trimLeft().startsWith('```')) {
            inFenceForSections = !inFenceForSections;
            continue;
          }
          if (inFenceForSections) continue;
          final match = RegExp(r'^(#{2,6})\s+(.*)$').firstMatch(line);
          if (match != null) {
            sectionHeadings.add((
              lineIndex,
              match.group(1)!.length,
              match.group(2)!.trim(),
            ));
          }
          if (line.contains('][index]')) {
            templatePlaceholders.add('$id:${lineIndex + 1}');
          }
          if (line.contains('本课围绕该主题展开，结合正文与代码示例理解它的适用边界')) {
            genericTermRows.add('$id:${lineIndex + 1}');
          }
        }
        for (
          var headingIndex = 0;
          headingIndex < sectionHeadings.length;
          headingIndex++
        ) {
          final heading = sectionHeadings[headingIndex];
          var end = markdownLines.length;
          for (
            var next = headingIndex + 1;
            next < sectionHeadings.length;
            next++
          ) {
            if (sectionHeadings[next].$2 <= heading.$2) {
              end = sectionHeadings[next].$1;
              break;
            }
          }
          var hasBody = false;
          for (var lineIndex = heading.$1 + 1; lineIndex < end; lineIndex++) {
            final trimmed = markdownLines[lineIndex].trim();
            if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
            hasBody = true;
            break;
          }
          if (!hasBody) emptySections.add('$id:${heading.$3}');
        }

        // P0：H1 必须等于清单标题，占位符与内部题号一律视为缺陷。
        final h1 = RegExp(
          r'^#\s+(.+)$',
          multiLine: true,
        ).firstMatch(markdown)?.group(1)?.trim();
        if (h1 != title) {
          headingMismatches.add('$id($h1)');
        }
        if (markdown.contains(placeholderTitle)) {
          placeholderHits.add('$id(markdown)');
        }
        final markdownIdHits = internalQuestionIdPattern
            .allMatches(markdown)
            .length;
        if (markdownIdHits > 0) {
          internalIdHits.add('$id(markdown:$markdownIdHits)');
        }

        // P1：复习章节只能有一个，且不能残留自动生成的复核补充块。
        final reviewHits = RegExp(
          r'^##\s+复习与迁移\s*$',
          multiLine: true,
        ).allMatches(markdown).length;
        if (reviewHits > 1) {
          duplicateReviewSections.add('$id($reviewHits)');
        }
        if (RegExp(
          r'^[>\s]*#{1,6}\s*复核补充',
          multiLine: true,
        ).hasMatch(markdown)) {
          staleReviewSupplements.add(id);
        }
        final corruptTermRow = sectionOf(markdown, '术语速查')
            .split('\n')
            .any(
              (line) =>
                  line.startsWith('|') &&
                  (line.contains('判断依据') || line.contains('正确答案是')),
            );
        if (corruptTermRow) {
          corruptTermTables.add(id);
        }
        for (final marker in markdownTemplateMarkers) {
          if (markdown.contains(marker)) {
            templateHits.add('$id(markdown:$marker)');
          }
        }

        final quiz = (lesson['quiz'] as List<dynamic>? ?? const [])
            .map((raw) => (raw as Map).cast<String, dynamic>())
            .toList();
        for (var index = 0; index < quiz.length; index++) {
          final question = quiz[index];
          final explanation = (question['explanation'] ?? '').toString();
          final questionText = (question['question'] ?? '').toString();
          final questionBlob = jsonEncode(question);
          if (questionBlob.contains(placeholderTitle)) {
            placeholderHits.add('$id#${index + 1}(quiz)');
          }
          if (internalQuestionIdPattern.hasMatch(questionBlob)) {
            internalIdHits.add('$id#${index + 1}(quiz)');
          }
          if (questionText.contains('…')) {
            truncatedStems.add('$id#${index + 1}');
          }
          if (genericPythonQuestionMarkers.any(questionBlob.contains)) {
            genericPythonQuestions.add('$id#${index + 1}');
          }
          for (final marker in explanationTemplateMarkers) {
            if (explanation.contains(marker)) {
              templateHits.add('$id#${index + 1}($marker)');
            }
          }
          final language = (question['language'] ?? '').toString().trim();
          if (expectedLanguage != null &&
              language.isNotEmpty &&
              language != expectedLanguage) {
            languageMismatches.add(
              '$id#${index + 1}($language!=$expectedLanguage)',
            );
          }
        }

        final signature = referenceUrls(markdown).join('\n');
        referenceSets
            .putIfAbsent(categoryId, () => <String, List<String>>{})
            .putIfAbsent(signature, () => <String>[])
            .add(id);
      }
    }

    final duplicateReferences = <String>[];
    for (final category in referenceSets.entries) {
      for (final entry in category.value.entries) {
        if (entry.value.length > 1) {
          duplicateReferences.add('${category.key}:${entry.value.join('、')}');
        }
      }
    }

    expect(
      headingMismatches,
      isEmpty,
      reason: 'H1 与清单标题不一致：${headingMismatches.take(10).join('、')}',
    );
    expect(
      placeholderHits,
      isEmpty,
      reason: '仍残留标题占位符：${placeholderHits.take(10).join('、')}',
    );
    expect(
      internalIdHits,
      isEmpty,
      reason: '仍残留内部题号：${internalIdHits.take(10).join('、')}',
    );
    expect(
      duplicateReviewSections,
      isEmpty,
      reason: '存在重复复习章节：${duplicateReviewSections.take(10).join('、')}',
    );
    expect(
      staleReviewSupplements,
      isEmpty,
      reason: '残留自动生成复核补充：${staleReviewSupplements.take(10).join('、')}',
    );
    expect(
      corruptTermTables,
      isEmpty,
      reason: '术语速查表格混入解析残句：${corruptTermTables.take(10).join('、')}',
    );
    expect(
      truncatedStems,
      isEmpty,
      reason: '题干被截断：${truncatedStems.take(10).join('、')}',
    );
    expect(
      genericPythonQuestions,
      isEmpty,
      reason: '仍残留跨域 Python 通用题：${genericPythonQuestions.take(10).join('、')}',
    );
    expect(
      templateHits,
      isEmpty,
      reason: '仍有模板命中：${templateHits.take(10).join('、')}',
    );
    expect(
      languageMismatches,
      isEmpty,
      reason: '仍有语言错配：${languageMismatches.take(10).join('、')}',
    );
    expect(
      duplicateReferences,
      isEmpty,
      reason: '仍有重复参考资料集合：${duplicateReferences.take(10).join('、')}',
    );
    expect(
      emptySections,
      isEmpty,
      reason: '仍有空小节：${emptySections.take(10).join('、')}',
    );
    expect(
      templatePlaceholders,
      isEmpty,
      reason: '仍有未解析模板占位符：${templatePlaceholders.take(10).join('、')}',
    );
    expect(
      genericTermRows,
      isEmpty,
      reason: '术语表仍有套话：${genericTermRows.take(10).join('、')}',
    );
  });
}
