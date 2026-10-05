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
      '内容更新时间：2026-10-03',
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

  test('P2 难度顺序：首课不是高级，末课不是入门且冲突已修正', () {
    for (final category in categories) {
      if (category.lessons.isEmpty) continue;
      final ordered = <Lesson>[...category.lessons]
        ..sort((a, b) => a.order.compareTo(b.order));
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
    final byId = <String, Lesson>{
      for (final category in categories)
        for (final lesson in category.lessons) lesson.id: lesson,
    };
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

  test('复习间隔按 1/3/7/30 天递增，答错回落', () async {
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
}
