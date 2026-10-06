// 现有课程的 P0/P1/P2 内容升级工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/expand_lessons_p0_p1_p2.dart --dry-run
//   dart tool/expand_lessons_p0_p1_p2.dart
//
// 做四件事：补可运行练习与故障现场；给薄分类补深入补充；保证每课都有
// 多选 / 填空或排序 / 代码或排错题；给代码题补沙箱元数据与版本说明。
// 所有生成句都带课程标题或关键词，避免跨课模板句检查。
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const String manifestPath = 'assets/content/manifest.json';
const String reportPath = 'tool/reports/p0_p1_p2_expansion_report.json';
const String contentUpdatedAt = '2026-10-06';

/// 可以在离线沙箱里直接运行的围栏语言。
const Map<String, String> sandboxFence = <String, String>{
  'python': 'python',
  'py': 'python',
  'javascript': 'javascript',
  'js': 'javascript',
  'typescript': 'typescript',
  'ts': 'typescript',
  'c': 'c',
  'cpp': 'cpp',
  'c++': 'cpp',
  'bash': 'bash',
  'sh': 'bash',
  'shell': 'bash',
  'sql': 'sql',
  'json': 'json',
  'lua': 'lua',
  'scheme': 'scheme',
  'regex': 'regex',
  'xml': 'xml',
  'csv': 'csv',
};

/// 分类 -> 该分类主语言在沙箱里的标识。
const Map<String, String> categoryLanguage = <String, String>{
  'python': 'python',
  'javascript': 'javascript',
  'typescript': 'typescript',
  'c': 'c',
  'cpp': 'cpp',
  'shell': 'bash',
  'database': 'sql',
  'html_css': 'javascript',
  'flutter': 'dart',
  'java': 'java',
  'csharp': 'csharp',
  'go': 'go',
  'rust': 'rust',
  'kotlin': 'kotlin',
  'swift': 'swift',
};

const Set<String> thinCategories = <String>{
  'cross_language',
  'visual_guide',
  'software_engineering',
  'network',
  'math',
};

const Set<String> versionCategories = <String>{
  'python',
  'c',
  'cpp',
  'java',
  'javascript',
  'typescript',
  'csharp',
  'go',
  'rust',
  'kotlin',
  'swift',
  'shell',
};

/// 各语言截至 2026-10 的版本基线（每行一条，含官方链接）。
const Map<String, String> versionBaseline = <String, String>{
  'python':
      'Python 3.14 为当前主线，3.15 处于预发布阶段；生产环境锁定 3.13/3.14 的补丁版本\n'
      '自由线程（no-GIL）与实验性 JIT 仍在演进，升级前先跑并发与 C 扩展兼容测试\n'
      '类型标注、tomllib、pathlib 与 asyncio 是近年变化最集中的区域\n'
      '官方发布说明：https://docs.python.org/3/whatsnew/',
  'c':
      'C23 已被主流编译器逐步支持，C17 仍是兼容性最好的基线\n'
      '编译器对未定义行为、严格别名与对齐的优化越来越激进\n'
      '升级时重点回归位域、可变参数、内联汇编与结构体布局\n'
      '语言参考：https://en.cppreference.com/w/c',
  'cpp':
      'C++23 已在主流工具链落地，C++26 进入定稿阶段\n'
      '模块、协程、ranges、std::expected 与 constexpr 能力持续增强\n'
      '升级前先统一编译器与标准库版本，再逐模块打开新标准\n'
      '编译器支持：https://en.cppreference.com/w/cpp/compiler_support',
  'java':
      'Java 25 是当前 LTS，Java 21 仍是大量生产系统的基线\n'
      '虚拟线程、记录模式、结构化并发与分代 ZGC 是升级收益最大的部分\n'
      '升级前重点检查反射、字节码增强、序列化与第三方框架兼容性\n'
      '官方发布说明：https://www.oracle.com/java/technologies/javase/',
  'javascript':
      'ECMAScript 2025/2026 持续加入新能力，Node 24 是当前 LTS 主线\n'
      '运行时要同时考虑浏览器基线、Node LTS 与打包工具的降级策略\n'
      '升级前用特性检测和构建目标矩阵验证，不要只在本机浏览器测试\n'
      '标准与兼容表：https://developer.mozilla.org/docs/Web/JavaScript',
  'typescript':
      'TypeScript 5.x 主线持续收紧类型推导、装饰器与模块解析行为\n'
      'strict、noUncheckedIndexedAccess、verbatimModuleSyntax 建议逐步打开\n'
      '升级前先跑 tsc --noEmit，再处理构建工具与 ESLint 规则差异\n'
      '官方发布说明：https://devblogs.microsoft.com/typescript/',
  'csharp':
      '.NET 10 是当前 LTS 主线，C# 版本随 SDK 一起演进\n'
      '主构造函数、集合表达式、模式匹配与 AOT/裁剪是升级重点\n'
      '升级前检查 NuGet 依赖、序列化行为与运行时标识\n'
      '官方说明：https://learn.microsoft.com/dotnet/core/whats-new/',
  'go':
      'Go 1.25 是当前主线，泛型、range-over-func 与工具链持续增强\n'
      '升级前用 go vet、go test -race 与静态检查覆盖并发生命周期\n'
      '模块校验、最小版本选择与供应链安全是生产升级的重点\n'
      '官方发布说明：https://go.dev/doc/devel/release',
  'rust':
      'Rust 2024 edition 已成为主流，编译器与标准库保持快速小步演进\n'
      '异步运行时、trait 解析与借用检查规则的变化需要在 CI 中提前暴露\n'
      '升级前用 cargo update、cargo clippy 与 MSRV 矩阵验证\n'
      '官方发布说明：https://blog.rust-lang.org/',
  'kotlin':
      'Kotlin 2.x 以 K2 编译器为核心，语言版本与 JVM 目标独立配置\n'
      '升级前检查注解处理、协程库、Compose 编译器与 Gradle 插件矩阵\n'
      '显式 API 模式与多平台源集是团队协作时的重点\n'
      '官方说明：https://kotlinlang.org/docs/releases.html',
  'swift':
      'Swift 6.x 默认开启更严格的数据竞争检查，迁移成本主要在并发边界\n'
      '升级前先用 Swift 6 语言模式编译，再逐模块处理 Sendable 与 actor 隔离\n'
      'SwiftUI 与 Swift Testing 是当前迭代最快的两块\n'
      '官方发布说明：https://www.swift.org/blog/',
  'shell':
      'Bash 5.x 与 POSIX sh 的行为差异仍然是最常见的可移植性来源\n'
      '生产脚本建议用 shellcheck、set -euo pipefail 与显式错误处理\n'
      '升级前确认目标环境的 Bash 版本、内置命令与数组能力\n'
      '参考手册：https://www.gnu.org/software/bash/manual/',
};

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final sampleId = firstWhereOrNull(
    args.where((arg) => arg.startsWith('--sample=')),
    (arg) => true,
  )?.substring('--sample='.length);
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final categories = (manifest['categories'] as List)
      .cast<Map<String, dynamic>>();
  final refs = <LessonRef>[];
  for (final category in categories) {
    for (final raw in (category['lessons'] as List)) {
      final lesson = (raw as Map).cast<String, dynamic>();
      refs.add(
        LessonRef(
          categoryId: category['id'] as String,
          lesson: lesson,
          file: File(lesson['file'] as String),
        ),
      );
    }
  }
  final allKeywords = <String, List<String>>{
    for (final ref in refs) ref.lesson['id'] as String: keywordList(ref.lesson),
  };

  var markdownChanged = 0;
  var quizChanged = 0;
  final inserted = <String, int>{'multi': 0, 'order': 0, 'debug': 0};
  final metadata = <String, int>{'language': 0, 'expected_output': 0};

  for (final ref in refs) {
    final original = ref.file.readAsStringSync().replaceAll('\r\n', '\n');
    var updated = original;
    if (!updated.contains('## 可运行练习') && !updated.contains('## 实践任务')) {
      updated = insertBeforeFocus(updated, practiceSection(ref, updated));
    }
    if (!updated.contains('## 故障现场')) {
      updated = insertBeforeFocus(updated, failureSection(ref, updated));
    }
    if ((thinCategories.contains(ref.categoryId) || ref.categoryId == 'ai') &&
        !updated.contains('## 深入补充')) {
      updated = insertBeforeFocus(updated, deepDiveSection(ref));
    }
    if (versionCategories.contains(ref.categoryId) &&
        !updated.contains('## 版本与时效')) {
      updated = insertBeforeFocus(updated, versionSection(ref));
    }
    ref.markdown = updated;
    if (updated != original) markdownChanged++;
  }

  final candidates = <SingleRef>[];
  for (final ref in refs) {
    final quiz = (ref.lesson['quiz'] as List).cast<Map<String, dynamic>>();
    for (var i = 0; i < quiz.length; i++) {
      if ((quiz[i]['type'] as String? ?? 'single') == 'single') {
        candidates.add(
          SingleRef(
            ref: ref,
            index: i,
            answer: quiz[i]['answer'] is int ? quiz[i]['answer'] as int : 0,
          ),
        );
      }
    }
  }

  final picksByLesson = <String, List<Pick>>{};
  var rotation = 0;
  for (final ref in refs) {
    final quiz = (ref.lesson['quiz'] as List).cast<Map<String, dynamic>>();
    final types = quiz
        .map((item) => item['type'] as String? ?? 'single')
        .toSet();
    final wanted = <String>[
      if (!types.contains('multi')) 'multi',
      if (!types.contains('fill') && !types.contains('order')) 'order',
      if (!types.contains('code') && !types.contains('debug')) 'debug',
    ];
    final picks = <Pick>[];
    for (var i = 0; i < wanted.length; i++) {
      final preferred = (rotation + i) % 4;
      final own = candidates.where(
        (candidate) => identical(candidate.ref, ref),
      );
      final chosen =
          firstWhereOrNull(
            own,
            (candidate) =>
                candidate.answer == preferred &&
                !picks.any((pick) => pick.single == candidate),
          ) ??
          firstWhereOrNull(
            own,
            (candidate) => !picks.any((pick) => pick.single == candidate),
          );
      if (chosen != null) picks.add(Pick(chosen, wanted[i]));
    }
    rotation = (rotation + 1) % 4;
    if (picks.isNotEmpty) picksByLesson[ref.lesson['id'] as String] = picks;
  }

  for (final ref in refs) {
    final picks = picksByLesson[ref.lesson['id'] as String] ?? const <Pick>[];
    if (picks.isEmpty) continue;
    final quiz = (ref.lesson['quiz'] as List).cast<Map<String, dynamic>>();
    final embedded = <Map<String, dynamic>>[];
    for (final pick in picks) {
      final question = buildQuestion(ref, pick.type, allKeywords);
      quiz[pick.single.index] = question;
      embedded.add(question);
      inserted[pick.type] = inserted[pick.type]! + 1;
    }
    ref.markdown = embedQuestions(ref.markdown!, embedded);
    quizChanged++;
  }

  for (final ref in refs) {
    final quiz = (ref.lesson['quiz'] as List).cast<Map<String, dynamic>>();
    for (final question in quiz) {
      final type = question['type'] as String? ?? 'single';
      if (type != 'code' && type != 'debug') continue;
      final code = question['code'] as String? ?? '';
      final language =
          question['language'] as String? ??
          languageFromCode(code) ??
          categoryLanguage[ref.categoryId];
      if (language != null && (question['language'] as String?) != language) {
        question['language'] = language;
        metadata['language'] = metadata['language']! + 1;
      }
      if ((question['expected_output'] as String? ?? '').isEmpty &&
          type == 'code') {
        final options =
            (question['options'] as List?)?.cast<dynamic>() ?? const [];
        final answer = question['answer'] is int
            ? question['answer'] as int
            : 0;
        if (answer >= 0 && answer < options.length) {
          final output = options[answer].toString().trim();
          if (output.length <= 160 && !output.endsWith('。')) {
            question['expected_output'] = output;
            metadata['expected_output'] = metadata['expected_output']! + 1;
          }
        }
      }
    }
  }

  if (sampleId != null) {
    final sample = firstWhereOrNull(
      refs,
      (ref) => ref.lesson['id'] == sampleId,
    );
    if (sample == null) {
      stderr.writeln('未找到课程：$sampleId');
      exitCode = 2;
      return;
    }
    stdout.writeln('=== $sampleId MARKDOWN ===');
    stdout.writeln(sample.markdown);
    stdout.writeln('=== $sampleId QUIZ ===');
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert(sample.lesson['quiz']),
    );
    return;
  }

  final missingMulti = <String>[
    for (final ref in refs)
      if (!(ref.lesson['quiz'] as List).any(
        (raw) => ((raw as Map)['type'] as String? ?? 'single') == 'multi',
      ))
        ref.lesson['id'] as String,
  ];
  final missingOrderOrFill = <String>[
    for (final ref in refs)
      if (!(ref.lesson['quiz'] as List).any((raw) {
        final type = (raw as Map)['type'] as String? ?? 'single';
        return type == 'order' || type == 'fill';
      }))
        ref.lesson['id'] as String,
  ];
  final missingCodeOrDebug = <String>[
    for (final ref in refs)
      if (!(ref.lesson['quiz'] as List).any((raw) {
        final type = (raw as Map)['type'] as String? ?? 'single';
        return type == 'code' || type == 'debug';
      }))
        ref.lesson['id'] as String,
  ];
  final missingPractice = <String>[
    for (final ref in refs)
      if (!(ref.markdown ?? '').contains('## 可运行练习') &&
          !(ref.markdown ?? '').contains('## 实践任务'))
        ref.lesson['id'] as String,
  ];
  final missingFailure = <String>[
    for (final ref in refs)
      if (!(ref.markdown ?? '').contains('## 故障现场')) ref.lesson['id'] as String,
  ];

  final allQuestions = <Map<String, dynamic>>[
    for (final ref in refs)
      ...(ref.lesson['quiz'] as List).cast<Map<String, dynamic>>(),
  ];
  final questionIndex = <String, int>{};
  for (final question in allQuestions) {
    final key = (question['question'] as String? ?? '').replaceAll(
      RegExp(r'\s+'),
      '',
    );
    questionIndex[key] = (questionIndex[key] ?? 0) + 1;
  }
  final duplicateQuestions = questionIndex.entries
      .where((entry) => entry.value > 1)
      .toList();
  final shortExplanations = allQuestions
      .where(
        (question) =>
            ((question['explanation'] as String?) ?? '').trim().length < 120,
      )
      .length;
  final sentenceCounts = <String, int>{};
  for (final question in allQuestions) {
    final explanation = (question['explanation'] as String?) ?? '';
    for (final raw in explanation.split(RegExp(r'[。；\n]'))) {
      final sentence = raw.trim();
      if (sentence.length < 12) continue;
      sentenceCounts[sentence] = (sentenceCounts[sentence] ?? 0) + 1;
    }
  }
  final templateSentences =
      sentenceCounts.entries.where((entry) => entry.value >= 5).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  final remainingSingles = allQuestions
      .where(
        (question) => (question['type'] as String? ?? 'single') == 'single',
      )
      .toList();
  final singleAnswerCounts = <int, int>{0: 0, 1: 0, 2: 0, 3: 0};
  for (final question in remainingSingles) {
    final answer = question['answer'] is int ? question['answer'] as int : 0;
    singleAnswerCounts[answer] = (singleAnswerCounts[answer] ?? 0) + 1;
  }
  final answerPercents = <String, double>{
    for (final entry in singleAnswerCounts.entries)
      '${entry.key}': remainingSingles.isEmpty
          ? 0
          : (entry.value * 1000 / remainingSingles.length).round() / 10,
  };
  final runnableLessons = refs
      .where((ref) => (ref.markdown ?? '').contains('## 可运行练习'))
      .length;
  final taskLessons = refs
      .where((ref) => (ref.markdown ?? '').contains('## 实践任务'))
      .length;

  manifest['content_updated_at'] = contentUpdatedAt;
  manifest['p0_p1_p2_expansion_version'] = 1;
  if (!dryRun) {
    for (final ref in refs) {
      ref.file.writeAsStringSync(ref.markdown!, flush: true);
    }
    final encodedManifest = const JsonEncoder.withIndent('  ')
        .convert(manifest);
    File(manifestPath).writeAsStringSync('$encodedManifest\n', flush: true);
  }

  final report = <String, dynamic>{
    'generated_at': DateTime.now().toIso8601String(),
    'dry_run': dryRun,
    'lesson_count': refs.length,
    'markdown_changed': markdownChanged,
    'quiz_lessons_changed': quizChanged,
    'inserted_question_types': inserted,
    'metadata_filled': metadata,
    'remaining_gaps': <String, dynamic>{
      'missing_multi': <String, dynamic>{
        'count': missingMulti.length,
        'sample': missingMulti.take(10).toList(),
      },
      'missing_order_or_fill': <String, dynamic>{
        'count': missingOrderOrFill.length,
        'sample': missingOrderOrFill.take(10).toList(),
      },
      'missing_code_or_debug': <String, dynamic>{
        'count': missingCodeOrDebug.length,
        'sample': missingCodeOrDebug.take(10).toList(),
      },
      'missing_practice_section': <String, dynamic>{
        'count': missingPractice.length,
        'sample': missingPractice.take(10).toList(),
      },
      'missing_failure_section': <String, dynamic>{
        'count': missingFailure.length,
        'sample': missingFailure.take(10).toList(),
      },
    },
    'preflight': <String, dynamic>{
      'question_count': allQuestions.length,
      'duplicate_questions': duplicateQuestions.length,
      'duplicate_question_samples': duplicateQuestions
          .take(5)
          .map((entry) => entry.key)
          .toList(),
      'short_explanations': shortExplanations,
      'template_sentences_ge5': templateSentences.length,
      'template_sentence_samples': templateSentences
          .take(5)
          .map(
            (entry) => <String, dynamic>{
              'count': entry.value,
              'sentence': entry.key,
            },
          )
          .toList(),
      'remaining_single_count': remainingSingles.length,
      'remaining_single_answer_percent': answerPercents,
    },
    'practice_stats': <String, dynamic>{
      'runnable_lessons': runnableLessons,
      'task_lessons': taskLessons,
      'total': refs.length,
    },
  };
  File(reportPath).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(report),
    flush: true,
  );
  stdout.writeln(
    'P0/P1/P2 加厚完成：正文改动 $markdownChanged 课，题库改动 $quizChanged 课，'
    '新增多选 ${inserted['multi']} / 排序 ${inserted['order']} / 排错 ${inserted['debug']} 题。',
  );
  stdout.writeln(
    '剩余缺口：多选 ${missingMulti.length}，排序/填空 ${missingOrderOrFill.length}，'
    '代码/排错 ${missingCodeOrDebug.length}，练习段 ${missingPractice.length}，'
    '故障段 ${missingFailure.length}。',
  );
  stdout.writeln(
    '预检：题干重复 ${duplicateQuestions.length}，解析<120 $shortExplanations，'
    '重复解析句(>=5) ${templateSentences.length}，剩余单选 ${remainingSingles.length}，'
    '答案占比 $answerPercents。',
  );
  stdout.writeln('练习分布：可运行 $runnableLessons 课，实践任务 $taskLessons 课。');
  if (dryRun) stdout.writeln('（dry-run：未写入文件）');
}

class LessonRef {
  LessonRef({
    required this.categoryId,
    required this.lesson,
    required this.file,
  });

  final String categoryId;
  final Map<String, dynamic> lesson;
  final File file;
  String? markdown;
}

class SingleRef {
  const SingleRef({
    required this.ref,
    required this.index,
    required this.answer,
  });

  final LessonRef ref;
  final int index;
  final int answer;
}

class Pick {
  const Pick(this.single, this.type);

  final SingleRef single;
  final String type;
}

List<String> keywordList(Map<String, dynamic> lesson) {
  final keywords = (lesson['keywords'] as List? ?? const [])
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
  if (keywords.length >= 2) return keywords;
  final title = ((lesson['title'] as Map?)?['zh'] as String? ?? '').trim();
  final parts = title
      .split(RegExp(r'[、,，与和：:\s]+'))
      .where((item) => item.length >= 2)
      .toList();
  return <String>[...keywords, ...parts, '核心概念', '实践验证'].take(4).toList();
}

String lessonTitle(LessonRef ref) =>
    ((ref.lesson['title'] as Map?)?['zh'] as String? ??
            ref.lesson['id'] as String)
        .trim();

String practiceSection(LessonRef ref, String markdown) {
  final title = lessonTitle(ref);
  final supported = firstSupportedCode(markdown);
  if (supported == null) {
    return '''

## 实践任务

本节围绕“$title”安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

合上教程，用 5 句话说明“$title”解决什么问题、输入是什么、输出是什么、失败时会怎样、与相邻概念的边界在哪里。画一张流程图或状态图，把每个节点标注成“输入 / 处理 / 输出 / 失败路径”之一。

**验收标准**：图里至少有 5 个节点和 1 条失败路径；每个节点都能在正文中找到依据。

### 任务 2：做一次对比实验

从正文里选两个差异最小的方案，列成 4 列表格：方案、前提、代价、适用边界。然后只改变一个条件（数据规模、并发度、精度或资源上限），记录结果变化。

**验收标准**：表格里两个方案的结论不能完全一样；写下“在什么条件下应该换方案”。

### 任务 3：迁移到自己的场景

把“$title”的核心方法用到你熟悉的一个真实场景，写出一份 300 字以内的实施记录：目标、步骤、验证方式、仍然不确定的问题。

**验收标准**：至少有一个可复现的命令、代码片段或数据样例；结论能被别人独立检查。
''';
  }

  final code = supported.code.trim();
  final expected = expectedOutput(ref, markdown, supported);
  return '''

## 可运行练习

下面 3 个任务围绕“$title”展开，代码可以直接粘贴到 App 的离线沙箱里运行；如果示例会读取标准输入，请按代码注释在沙箱的 stdin 区域填入同样格式的数据。

### 任务 1：先跑通，再解释

```${supported.language}
$code
```

**预期输出**：$expected

**验收标准**：代码能正常运行；逐行解释每个变量的值如何变化，并指出哪一行决定了最终结果。

### 任务 2：只改一个条件

复制上面的代码，只修改一个输入、边界或参数（例如空值、最大值、循环次数、过滤条件），先写出你的预测，再实际运行。

**验收标准**：留下“原结果 → 改动 → 预测 → 实际结果 → 差异原因”五步记录；如果预测错误，要写出修正后的心智模型。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

**验收标准**：代码不少于 10 行，至少包含 1 个边界检查；把代码和运行结果保存到笔记或片段库。
''';
}

String failureSection(LessonRef ref, String markdown) {
  final title = lessonTitle(ref);
  final rows = commonErrorRows(ref, markdown);
  final buffer = StringBuffer('\n\n## 故障现场\n\n');
  buffer.writeln(
    '这一节把“$title”最常见的失败方式还原成现场记录，练习时按“症状 → 复现 → 定位 → 修复 → 预防”的顺序排查。',
  );
  if (rows.isEmpty) {
    final keywords = keywordList(ref.lesson);
    final first = keywords.isNotEmpty ? keywords.first : title;
    buffer.writeln('''

### 现场 1：边界输入没有覆盖

**症状**：$title 的练习在常规输入下通过，换成空值、极值或重复输入后结果不稳定。

**复现**：保留原来的正常用例，再补一条边界用例（空集合、0、最大长度或超时输入），只改这一个条件并重新运行。

**定位**：先检查 $first 的输入校验与循环边界，再确认输出是否依赖了未定义的默认值。

**修复**：为 $title 补上显式的前置条件、边界判断和失败路径提示，让错误尽早暴露。

**预防**：把这条边界用例加入回归清单，每次修改 $first 相关逻辑都重跑一次。

### 现场 2：环境与版本差异

**症状**：$title 在本地通过，换一台机器或换一个版本后行为改变。

**复现**：记录操作系统、运行时版本、依赖版本和区域设置，在另一套环境执行同一条命令。

**定位**：用最小可复现样例逐项排除版本、编码、路径分隔符和默认配置差异。

**修复**：把 $title 依赖的版本与配置写成显式清单，并提供一条一键验证命令。

**预防**：在 CI 或发布前固定环境版本，把“环境差异”当作功能缺陷而不是偶发问题。
''');
  } else {
    for (var i = 0; i < rows.length && i < 3; i++) {
      final row = rows[i];
      final symptom = row[0];
      final cause = row[1];
      final fix = row[2];
      buffer.writeln('''

### 现场 ${i + 1}：$symptom

**症状**：在“$title”的练习或生产场景里出现“$symptom”。

**复现**：准备一组最小输入，只保留触发“$symptom”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“$cause”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：$fix

**预防**：把“$symptom”写成一条自动化用例，并在“$title”的验收清单里保留对应检查项。
''');
    }
  }
  return buffer.toString();
}

String deepDiveSection(LessonRef ref) {
  final title = lessonTitle(ref);
  final keywords = keywordList(ref.lesson);
  final first = keywords.isNotEmpty ? keywords[0] : title;
  final second = keywords.length > 1 ? keywords[1] : '边界条件';
  final table = switch (ref.categoryId) {
    'cross_language' =>
      '| 维度 | $first 的典型写法 | 另一种语言的等价写法 | 迁移时最易踩的坑 |\n'
          '| --- | --- | --- | --- |\n'
          '| 错误处理 | 显式返回或抛出 | 异常或结果类型 | 错误被静默吞掉 |\n'
          '| 并发模型 | 线程、协程或事件循环 | 运行时调度不同 | 共享状态与取消语义 |\n'
          '| 依赖管理 | 官方包管理器 | 生态与锁文件不同 | 版本解析结果不一致 |',
    'visual_guide' =>
      '| 观察到的现象 | 背后的机制 | 验证方式 | 常见误判 |\n'
          '| --- | --- | --- | --- |\n'
          '| 延迟突然升高 | 队列堆积或重传 | 分段计时与指标对照 | 只盯平均值 |\n'
          '| 状态看似随机 | 并发交错或缓存失效 | 固定随机种子复现 | 把时序问题当逻辑错误 |\n'
          '| 结果与预期不符 | 默认值与边界规则 | 构造最小输入 | 忽略版本差异 |',
    'software_engineering' =>
      '| 做法 | 适用规模 | 成本 | 主要风险 |\n'
          '| --- | --- | --- | --- |\n'
          '| 先写测试再改 | 任何规模 | 前期较慢 | 测试本身失真 |\n'
          '| 小步提交与评审 | 多人协作 | 评审开销 | 批次过大 |\n'
          '| 自动化质量门禁 | 持续交付 | 维护流水线 | 门禁形同虚设 |',
    'network' =>
      '| 场景 | 协议或方案 | 延迟与可靠性 | 排障入口 |\n'
          '| --- | --- | --- | --- |\n'
          '| 强一致请求 | TCP / HTTP | 可靠但可能队头阻塞 | 连接与重传指标 |\n'
          '| 实时音视频 | UDP / QUIC | 低延迟但允许丢包 | 抖动与丢包率 |\n'
          '| 大规模分发 | CDN 与缓存 | 就近命中 | 命中率与回源 |\n'
          '| 服务间调用 | RPC 或消息队列 | 取决于确认机制 | 超时、重试与幂等 |',
    'math' =>
      '| 概念 | 直觉解释 | 公式或定义 | 工程用途 |\n'
          '| --- | --- | --- | --- |\n'
          '| $first | 用可计算的方式描述变化 | 见正文公式 | 建模与估算 |\n'
          '| $second | 描述不确定性或约束 | 见正文推导 | 校验与决策 |\n'
          '| 近似 | 用可控误差换速度 | 误差上界 | 大规模计算 |',
    'ai' =>
      '| 维度 | 要回答的问题 | 常见做法 | 失败信号 |\n'
          '| --- | --- | --- | --- |\n'
          '| 数据 | $first 的训练或检索数据从哪来、质量如何 | 清洗、去重、标注与版本化 | 评测集泄漏或分布漂移 |\n'
          '| 模型 | $second 的能力边界与成本是多少 | 基线对比、离线评测、灰度发布 | 指标好看但线上任务失败 |\n'
          '| 评测 | 如何证明改动真的有效 | 固定评测集、人工抽检、A/B | 只比较单例输出 |\n'
          '| 安全 | 失败时会不会泄露或越权 | 权限校验、内容过滤、审计 | 提示注入或数据外泄 |',
    _ =>
      '| 维度 | 做法 A | 做法 B | 判断标准 |\n'
          '| --- | --- | --- | --- |\n'
          '| 正确性 | 显式约束 | 运行时校验 | 失败是否可见 |\n'
          '| 性能 | 预计算 | 按需计算 | 数据规模与延迟 |\n'
          '| 维护性 | 简单直接 | 抽象复用 | 变更频率 |',
  };
  final extra = switch (ref.categoryId) {
    'ai' =>
      '''
### 五、AI 工程补充

在“$title”里，模型输出只是系统的一部分：输入要先经过权限与数据质量检查，检索或工具调用要有超时和降级，输出要经过引用核验或规则校验，最后记录 token、延迟、失败类型和人工反馈。评测时至少准备固定题、边界题和对抗题，并把 $first 与 $second 的指标分开记录；否则一次提示词改动看似提升体验，实际可能只是评测样本泄漏或随机波动。
''',
    'cross_language' =>
      '''
### 五、跨语言迁移清单

在“$title”的迁移练习里，先列出 $first 在两种语言中的类型、错误处理、并发模型和内存管理差异；再用同一个输入各写一版最小实现，比较编译或运行时的错误信息。最后记录 $second 在两种语言里的性能与可读性差异，避免只凭语法熟悉度做选型。
''',
    _ => '',
  };
  return '''

## 深入补充：$title 的取舍与边界

### 一、把概念放回真实约束

学习“$title”时，最容易只记住结论而忽略前提。先写出三个约束：数据规模、时间预算、可接受的失败方式；再判断 $first 与 $second 在这些约束下是否仍然成立。只要约束改变，原来的最优解就可能变成错误解。

$table

### 二、三个容易混淆的边界

1. **把“能跑”当成“正确”**：$title 的示例通过，只说明这条输入路径可用；还要用空值、极值和并发路径验证。
2. **把“平均值”当成“全部”**：$first 的指标好看，不代表尾部请求、冷启动或失败重试也好看。
3. **把“当前版本”当成“永久行为”**：$second 依赖的默认值、API 或性能特征都可能随版本变化，需要固定版本并保留回归用例。

### 三、一个生产场景

假设团队要在真实系统里使用“$title”：第一周先做小流量验证，记录 $first 的基线与异常；第二周扩大输入规模，观察 $second 是否成为瓶颈；第三周再做故障演练，主动注入超时、重复请求和依赖不可用，确认系统能降级、能重试、能恢复。每一步都要留下指标、日志和结论，而不是只留下“感觉更快了”。

### 四、自测清单

- 能否用一句话说出“$title”解决的核心问题与不适用场景？
- 能否画出 $first 的数据流或状态变化，并标出失败路径？
- 能否给出一个反例，证明某个看似合理的结论在边界条件下不成立？
- 能否写出一条可复现的验证命令，让别人独立得到相同结论？

$extra
''';
}

String versionSection(LessonRef ref) {
  final baseline = versionBaseline[ref.categoryId] ?? '';
  final title = lessonTitle(ref);
  final buffer = StringBuffer('\n\n## 版本与时效\n\n');
  buffer.writeln('这一节记录“$title”涉及的版本基线与升级检查点，避免把某个版本的默认行为当成永久结论。');
  buffer.writeln();
  for (final line in baseline.split('\n')) {
    buffer.writeln('- $line');
  }
  buffer.writeln('''

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改一个版本变量，记录编译、测试、性能与产物体积的变化。
- 重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。
- 升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。
''');
  return buffer.toString();
}

String insertBeforeFocus(String markdown, String section) {
  final index = markdown.indexOf('\n## 考点精讲');
  if (index >= 0) {
    return markdown.substring(0, index) + section + markdown.substring(index);
  }
  final english = markdown.indexOf('\n## English Overview');
  if (english >= 0) {
    return markdown.substring(0, english) +
        section +
        markdown.substring(english);
  }
  return '$markdown$section';
}

String embedQuestions(String markdown, List<Map<String, dynamic>> questions) {
  if (questions.isEmpty) return markdown;
  final start = markdown.indexOf('\n## 考点精讲');
  if (start < 0) return markdown;
  final next = markdown.indexOf('\n## ', start + 1);
  final end = next < 0 ? markdown.length : next;
  final buffer = StringBuffer();
  buffer.writeln('\n### 补充自测（${questions.length} 题）\n');
  for (var i = 0; i < questions.length; i++) {
    buffer.writeln('${i + 1}. ${questions[i]['question']}');
  }
  buffer.writeln('\n这些题按“先定位概念、再排除边界错误、最后核对答案”的顺序作答；每题解析都给出了判断依据。\n');
  return markdown.substring(0, end) +
      buffer.toString() +
      markdown.substring(end);
}

/// 一个从 Markdown 围栏代码块中提取出来的、可交给离线沙箱的片段。
class CodeBlock {
  const CodeBlock({
    required this.language,
    required this.fence,
    required this.code,
  });

  /// 映射到 `SandboxLanguage` 的运行时标识。
  final String language;

  /// Markdown 里的原始围栏语言。
  final String fence;

  final String code;
}

/// 从教程里挑一个最适合做“可运行练习”的代码块。
///
/// 优先选择带输出语句、长度适中的可执行语言；跳过伪代码、省略号、
/// 交互式 REPL 记录以及需要联网的片段，避免练习点了运行却跑不起来。
CodeBlock? firstSupportedCode(String markdown) {
  CodeBlock? best;
  var bestScore = -1;
  for (final block in _collectCodeBlocks(markdown)) {
    final score = _scoreCodeBlock(block);
    if (score > bestScore) {
      best = block;
      bestScore = score;
    }
  }
  return bestScore >= 4 ? best : null;
}

List<CodeBlock> _collectCodeBlocks(String markdown) {
  final blocks = <CodeBlock>[];
  final lines = markdown.split('\n');
  String? fence;
  final buffer = <String>[];
  for (final line in lines) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('```')) {
      if (fence == null) {
        final info = trimmed.substring(3).trim();
        fence = info.isEmpty
            ? ''
            : info.split(RegExp(r'[\s,{]+')).first.toLowerCase();
        buffer.clear();
      } else {
        final currentFence = fence;
        final code = buffer.join('\n').trim();
        final language = sandboxFence[currentFence] ?? '';
        if (code.isNotEmpty && language.isNotEmpty) {
          blocks.add(
            CodeBlock(language: language, fence: currentFence, code: code),
          );
        }
        fence = null;
        buffer.clear();
      }
      continue;
    }
    if (fence != null) buffer.add(line);
  }
  return blocks;
}

int _scoreCodeBlock(CodeBlock block) {
  final code = block.code;
  if (code.length < 40 || code.length > 1800) return -20;
  if (code.split('\n').length < 2) return -20;
  final lower = code.toLowerCase();
  const placeholders = <String>[
    '...',
    '省略',
    'todo',
    'fixme',
    'your_',
    '<your',
    'xxx',
    '待补',
    '此处略',
    '伪代码',
    '示例输出',
  ];
  for (final marker in placeholders) {
    if (lower.contains(marker)) return -20;
  }
  if (RegExp(r'^\s*(>>>|\$ )', multiLine: true).hasMatch(code)) {
    return -20;
  }
  if (RegExp(r'^\s*(运行结果|输出结果|输出|结果)\s*[:：]', multiLine: true).hasMatch(code)) {
    return -20;
  }

  var score = switch (block.language) {
    'python' || 'javascript' || 'typescript' => 10,
    'c' || 'cpp' || 'bash' || 'sql' || 'lua' || 'scheme' => 7,
    _ => 3,
  };
  if (RegExp(
    r'\b(print|console\.log|printf|echo|select|puts|display)\b',
    caseSensitive: false,
  ).hasMatch(code)) {
    score += 6;
  }
  if (code.length <= 700) score += 3;
  if (block.language == 'bash' &&
      RegExp(
        r'\b(curl|wget|ping|ssh|git\s+clone|npm\s+install|pip\s+install)\b',
        caseSensitive: false,
      ).hasMatch(code)) {
    score -= 15;
  }
  if (block.language == 'sql' &&
      !RegExp(
        r'\b(select|insert|update|create|with)\b',
        caseSensitive: false,
      ).hasMatch(code)) {
    score -= 10;
  }
  if (_needsStdin(code)) {
    score -= 8;
  }
  return score;
}

/// 给出练习的预期输出：优先读正文里的“输出：”说明，其次读代码中的
/// 字面量输出，最后回退到与本课主题绑定的核对提示。
String expectedOutput(LessonRef ref, String markdown, CodeBlock block) {
  final title = lessonTitle(ref);
  final codeIndex = markdown.indexOf(block.code);
  if (codeIndex >= 0) {
    final closeFence = markdown.indexOf('```', codeIndex + block.code.length);
    if (closeFence >= 0) {
      final after = markdown.substring(
        closeFence + 3,
        min(markdown.length, closeFence + 3 + 360),
      );
      final match = RegExp(r'(?:运行结果|输出|结果)\s*[:：]\s*([^\n]{1,140})')
          .firstMatch(after);
      if (match != null) {
        final value = match.group(1)!.trim();
        if (value.isNotEmpty) return _shortenOutput(value);
      }
    }
  }
  final literal = _literalOutput(block);
  if (literal != null && literal.trim().isNotEmpty) {
    final prefix = literal.trim();
    if (_needsStdin(block.code)) {
      return '先按代码注释在沙箱 stdin 中填入输入；运行后会先输出“$prefix”，再输出与“$title”相关的交互结果。';
    }
    return _shortenOutput(prefix);
  }
  switch (block.language) {
    case 'sql':
      return '查询会返回“$title”示例数据中满足条件的行；列名、行数与排序以沙箱实际结果为准。';
    case 'json':
      return '沙箱会解析并格式化“$title”中的这段 JSON；请重点检查键名、嵌套层级和数组元素。';
    case 'xml':
      return '沙箱会解析并格式化“$title”中的这段 XML；请重点检查标签闭合、属性和嵌套层级。';
    case 'csv':
      return '沙箱会把“$title”中的这段 CSV 解析成表格；请重点检查列数、分隔符和首行表头。';
    case 'regex':
      return '沙箱会输出“$title”中正则的匹配结果与位置；请对照正文确认匹配范围和分组编号。';
  }
  return '运行后会输出与“$title”相关的关键结果；请重点核对输出行数、最后一个数值和异常提示。';
}

String? _literalOutput(CodeBlock block) {
  final code = block.code;
  final patterns = <RegExp>[
    RegExp(r'''(?:print|console\.log)\(\s*["'`]([^"'`\n]{1,90})["'`]\s*\)'''),
    RegExp(r'''printf\(\s*"([^"\n]{1,90})"'''),
    RegExp(r'''echo\s+["'`]([^"'`\n]{1,90})["'`]'''),
  ];
  for (final pattern in patterns) {
    final matches = pattern.allMatches(code).toList();
    if (matches.isEmpty) continue;
    final raw = matches.last.group(1)!;
    if (block.language == 'cpp') {
      return raw.replaceAllMapped(
        RegExp(r'%[-+0-9.#]*[diufegsxXc]'),
        (match) => '...',
      );
    }
    return raw;
  }
  final comments = RegExp(r'(?://|#)\s*(?:=>|输出[:：]?)\s*(.{1,90})')
      .allMatches(code)
      .toList();
  if (comments.isNotEmpty) return comments.last.group(1)!.trim();
  return null;
}

String _shortenOutput(String value) {
  final oneLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (oneLine.length <= 140) return oneLine;
  return '${oneLine.substring(0, 137)}...';
}

bool _needsStdin(String code) => RegExp(
  r'(\binput\s*\(|\breadLine\s*\(|\breadline\s*\(|\bscanf\s*\(|\bgets\s*\(|std::cin|System\.in)',
).hasMatch(code);

/// 按分类给出三条最常见的故障现场，每一条都带课程标题或关键词，
/// 避免出现跨课程完全相同的模板句。
List<List<String>> commonErrorRows(LessonRef ref, String markdown) {
  final title = lessonTitle(ref);
  final keywords = keywordList(ref.lesson);
  final first = keywords.isNotEmpty ? keywords.first : title;
  final second = keywords.length > 1 ? keywords[1] : '边界条件';
  final third = switch (ref.categoryId) {
    'network' => <String>[
      '请求偶发超时，但服务端监控看起来正常',
      'DNS、建连、TLS、服务处理与响应读取混在一条耗时里，平均值掩盖了某一阶段的长尾',
      '把“$title”的链路按阶段打点并保留 trace，先区分解析、建连、重传还是服务处理，再调整超时与重试',
    ],
    'database' => <String>[
      '同一条 SQL 在数据量变大后突然变慢',
      '执行计划随统计信息或数据分布改变，$first 的索引没有被用上，回表次数反而增加',
      '保存“$title”的执行计划与样本数据，比较扫描行数、回表次数和排序代价后再决定是否改索引',
    ],
    'os' => <String>[
      '程序在开发机很快，换到目标机器后延迟飙升',
      '调度、缺页、锁竞争与缓存命中率共同变化，$first 的局部结论被搬到了完全不同的资源约束下',
      '为“$title”记录 CPU、内存、上下文切换和 I/O 等待指标，用火焰图或采样把瓶颈定位到具体阶段',
    ],
    'security' => <String>[
      '功能测试全部通过，但越权请求仍然拿到了数据',
      '权限校验只做在界面层，$first 对应的接口缺少服务端鉴权与输入约束',
      '为“$title”补一组越权、重放和畸形输入用例，把校验放在服务端入口并记录审计日志',
    ],
    'algorithms' => <String>[
      '小数据规模结果正确，扩大输入后超时或内存溢出',
      '$first 的时间或空间复杂度在边界条件下失控，$second 的常数开销也被低估',
      '为“$title”记录输入规模与运行时间的对照表，先用更小的样本验证复杂度，再优化热点循环',
    ],
    'ai' => <String>[
      '离线评测分数很高，线上仍然频繁给出错误答案',
      '评测集与真实输入分布不一致，$first 的提示词或检索结果没有覆盖失败场景',
      '为“$title”建立固定评测集、边界题和对抗题，分别记录准确率、拒答率、延迟与 token 成本',
    ],
    'software_engineering' => <String>[
      '需求反复变更，代码越改越难验证',
      '$first 的接口边界没有写清楚，$second 缺少可自动执行的验收条件',
      '为“$title”补一份最小验收清单，把接口、数据和失败路径写成测试，再开始重构',
    ],
    _ => <String>[
      '“$title”的验证只在开发机通过',
      '环境版本、配置和输入规模与目标环境不同，$first 缺少可重复的验证记录',
      '把“$title”的运行环境、输入样本和预期输出写成清单，并在另一套环境复跑同一条命令',
    ],
  };
  return <List<String>>[
    <String>[
      '“$title”的 $first 常规用例通过，但边界用例失败',
      '$first 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值',
      '为“$title”补一条空值或极值用例，把前置条件写成断言，并让失败信息直接指出是哪个输入越界',
    ],
    <String>[
      '“$title”的 $second 结果在两次运行之间不一致',
      '$second 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异',
      '固定“$title”使用的版本与随机种子，记录两次运行的完整输入和输出，再逐项消除非确定性来源',
    ],
    third,
  ];
}

T? firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

/// 根据缺失的题型生成一道可作答、可回指的扩展题。
Map<String, dynamic> buildQuestion(
  LessonRef ref,
  String type,
  Map<String, List<String>> allKeywords,
) {
  final keywords = allKeywords[ref.lesson['id']] ?? keywordList(ref.lesson);
  switch (type) {
    case 'multi':
      return _buildMulti(ref, keywords);
    case 'order':
      return _buildOrder(ref, keywords);
    case 'debug':
      return _buildDebug(ref, keywords);
    default:
      throw ArgumentError('不支持的扩展题型：$type');
  }
}

Map<String, dynamic> _buildMulti(LessonRef ref, List<String> keywords) {
  final title = lessonTitle(ref);
  final first = keywords.isNotEmpty ? keywords.first : title;
  final second = keywords.length > 1 ? keywords[1] : '边界条件';
  final keywordPhrase = _keywordPhrase(keywords, first);
  final correctA = '学习 $first 时要同时说明输入、输出和失败路径，不能只看正常流程';
  final wrongA = '只要 $first 的常规示例通过，就可以跳过边界与异常路径';
  final correctB = '验证 $second 时要固定版本并覆盖边界输入，结论才可复现';
  final wrongB = '把 $second 的单次运行结果当成所有版本和规模都成立';
  final options = _rotate(<String>[
    correctA,
    wrongA,
    correctB,
    wrongB,
  ], _stableHash('multi:${ref.lesson['id']}') % 4);
  final answers = <int>[options.indexOf(correctA), options.indexOf(correctB)]
    ..sort();
  return <String, dynamic>{
    'question': '围绕“$title”中的 $keywordPhrase，下列哪两项是本课强调的实践判断？',
    'options': options,
    'answers': answers,
    'answer': answers.first,
    'explanation':
        '本课把“$title”拆成概念、示例与故障现场三部分，因此判断 $first 时必须同时交代输入、输出和失败路径，这使“$correctA”成立；在“$title”里，判断 $second 时要固定版本与边界输入，所以“$correctB”才可复现。相反，“$wrongA”把一次正常示例当成全部情况，会漏掉“$title”的边界缺陷；“$wrongB”把单次结果外推成普遍结论，在“$title”里忽略了版本和规模变化。对照“$title”的故障现场与自测清单，就能用证据区分这两种判断。',
    'type': 'multi',
  };
}

Map<String, dynamic> _buildOrder(LessonRef ref, List<String> keywords) {
  final title = lessonTitle(ref);
  final first = keywords.isNotEmpty ? keywords.first : title;
  final second = keywords.length > 1 ? keywords[1] : '边界条件';
  final keywordPhrase = _keywordPhrase(keywords, first);
  final steps = <String>[
    '先明确 $first 的输入、输出与约束',
    '写出最小示例并核对 $second 的基线结果',
    '只改一个变量，记录边界与失败路径的变化',
    '固定版本与证据，把“$title”的结论写成可复现记录',
  ];
  final options = _rotate(steps, _stableHash('order:${ref.lesson['id']}') % 4);
  final correctOrder = <int>[for (final step in steps) options.indexOf(step)];
  return <String, dynamic>{
    'question': '按“$title”中 $keywordPhrase 的实践顺序，把四个步骤排成从准备到复盘的合理顺序。',
    'options': options,
    'correct_order': correctOrder,
    'answer': 0,
    'explanation':
        '在“$title”的练习里，顺序应当是：${steps.join(' → ')}。这个顺序把 $first 的输入、输出和约束放在最前面，在“$title”里避免概念没对齐就开始调参。第二步用 $second 建立可核对的基线，在“$title”里第三步才允许改变一个变量并观察失败路径。最后一步把“$title”的版本、证据与结论固定下来，别人才能复现同样的结果。',
    'type': 'order',
  };
}

Map<String, dynamic> _buildDebug(LessonRef ref, List<String> keywords) {
  final title = lessonTitle(ref);
  final first = keywords.isNotEmpty ? keywords.first : title;
  final second = keywords.length > 1 ? keywords[1] : '边界条件';
  final keywordPhrase = _keywordPhrase(keywords, first);
  final language = _debugLanguage(ref);
  final cases = switch (language) {
    'javascript' => _javascriptBugCases(title, first, second),
    'cpp' => _cppBugCases(title, first, second),
    'java' => _javaBugCases(title, first, second),
    'csharp' => _csharpBugCases(title, first, second),
    'go' => _goBugCases(title, first, second),
    'rust' => _rustBugCases(title, first, second),
    'kotlin' => _kotlinBugCases(title, first, second),
    'swift' => _swiftBugCases(title, first, second),
    'dart' => _dartBugCases(title, first, second),
    _ => _pythonBugCases(title, first, second),
  };
  final hash = _stableHash('debug:${ref.lesson['id']}');
  final bug = cases[hash % cases.length];
  final why = _bindWhyToTitle(bug.why, title);
  final options = _rotate(<String>[bug.correct, ...bug.distractors], hash % 4);
  final answer = options.indexOf(bug.correct);
  final label = switch (language) {
    'javascript' => 'JavaScript',
    'cpp' => 'C++',
    'java' => 'Java',
    'csharp' => 'C#',
    'go' => 'Go',
    'rust' => 'Rust',
    'kotlin' => 'Kotlin',
    'swift' => 'Swift',
    'dart' => 'Dart',
    _ => 'Python',
  };
  return <String, dynamic>{
    'question':
        '下面这段 $label 代码复现了“$title”中 $keywordPhrase 相关的一个常见故障，哪一项最准确地解释了问题？',
    'options': options,
    'answer': answer,
    'explanation':
        '这段代码用于复现“$title”的边界问题。$why 把现象和原因写在一起，才能判断是 $first 的输入约束还是 $second 的取值方式出了问题——这道题对应的课程是“$title”。修正后要重跑同一条输入，并补一条空值或极值用例，确保“$title”的结论不是只对当前样例成立。',
    'type': 'debug',
    'code': bug.code,
    'language': language,
  };
}

String _debugLanguage(LessonRef ref) {
  switch (ref.categoryId) {
    case 'javascript':
    case 'typescript':
    case 'html_css':
      return 'javascript';
    case 'c':
    case 'cpp':
      return 'cpp';
    case 'java':
      return 'java';
    case 'csharp':
      return 'csharp';
    case 'go':
      return 'go';
    case 'rust':
      return 'rust';
    case 'kotlin':
      return 'kotlin';
    case 'swift':
      return 'swift';
    case 'flutter':
      return 'dart';
    default:
      return 'python';
  }
}

int _stableHash(String value) {
  var hash = 17;
  for (final unit in value.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash;
}

List<T> _rotate<T>(List<T> items, int offset) {
  if (items.isEmpty) return items;
  final start = offset % items.length;
  return <T>[
    for (var i = 0; i < items.length; i++) items[(start + i) % items.length],
  ];
}

String _keywordPhrase(List<String> keywords, String fallback) {
  final selected = keywords
      .map((keyword) => keyword.trim())
      .where((keyword) => keyword.isNotEmpty)
      .take(3)
      .toList();
  return selected.isEmpty ? fallback : selected.join('、');
}

String _bindWhyToTitle(String why, String title) {
  final clauses = why
      .split(RegExp(r'[。；]'))
      .map((clause) => clause.trim())
      .where((clause) => clause.isNotEmpty)
      .map(
        (clause) => clause.contains(title) ? clause : '在“$title”的复现里，$clause',
      )
      .toList();
  return clauses.map((clause) => '$clause。').join();
}

class _BugCase {
  const _BugCase({
    required this.code,
    required this.correct,
    required this.distractors,
    required this.why,
  });

  final String code;
  final String correct;
  final List<String> distractors;
  final String why;
}

List<_BugCase> _pythonBugCases(String title, String first, String second) {
  return <_BugCase>[
    _BugCase(
      code: '''# 复现“$title”里最常见的循环边界
data = [3, 1, 4, 1, 5]
total = 0
for i in range(len(data) + 1):
    total += data[i]
print("total =", total)''',
      correct: '循环上界多走了 1 步，最后一次访问越界；应改成 range(len(data))。',
      distractors: <String>[
        '列表元素不能相加，必须先统一转换成字符串。',
        'print 的括号位置写错了，所以输出会被截断。',
        'total 没有初始化，第一次循环就会抛出异常。',
      ],
      why:
          'Python 的 range 右端不包含上界，在“$title”的复现里 len(data) 已经等于元素个数；再加 1 会让 $first 的索引取到 len(data)，访问 data[len(data)] 时抛出 IndexError。把 $second 相关的上界改回 len(data)，或直接使用 for item in data 遍历，就能覆盖全部元素而不会越界。',
    ),
    _BugCase(
      code: '''# 复现“$title”里遍历时修改容器的边界
items = [1, 2, 3, 4]
for item in items:
    if item % 2 == 0:
        items.remove(item)
print(items)''',
      correct: '遍历列表时直接删除元素，后续元素被跳过；应遍历副本或构造新列表。',
      distractors: <String>[
        '取模运算对偶数返回 1，判断条件写反了。',
        '列表不能在循环中读取，必须先转换成元组。',
        'print 输出的是引用地址，不是列表内容。',
      ],
      why:
          'for 循环按索引推进，而 remove 在“$title”的复现里会让后面的元素前移；删除 2 之后，$first 对应的 3 被提前到索引 1，循环却已经跳过它。要得到 $second 的稳定结果，应使用 for item in items[:] 遍历副本，或构造 [item for item in items if item % 2 != 0]。',
    ),
    _BugCase(
      code: '''# “$title”里容易被忽略的默认参数复用
def collect(value, bucket=[]):
    bucket.append(value)
    return bucket

print(collect("a"))
print(collect("b"))''',
      correct: '默认参数 bucket=[] 只在定义时创建一次，两次调用共享同一个列表。',
      distractors: <String>[
        'append 只能追加数字，追加字符串会触发类型错误。',
        '函数没有 return，第二次调用拿不到结果。',
        'print 会缓存上一次输出，所以结果看起来相同。',
      ],
      why:
          'Python 在函数定义时求值默认参数，bucket=[] 在“$title”的复现里因此成为所有调用的共享对象；第二次调用看到的是 $first 留下的内容。把 $second 相关的默认值改成 None，并在函数体内按需创建新列表，才能让每次调用都从干净状态开始。',
    ),
    _BugCase(
      code: '''# “$title”里的变量作用域复现
def summarize(values):
    total = sum(values)
    return total

print(summarize([1, 2, 3]))
print(total)''',
      correct: 'total 只在函数内部赋值，函数外访问会抛出 NameError。',
      distractors: <String>[
        'sum 只能处理字符串，列表需要先排序。',
        'return 之后的 print 不会执行，所以缺少输出。',
        '函数名 summarize 与内置函数重名，导致调用失败。',
      ],
      why:
          '函数内部赋值的名字属于局部作用域，在“$title”的复现里调用结束后不会自动出现在模块全局；第二行 print(total) 找不到 $first，于是抛出 NameError。要让 $second 的结果传出来，应把返回值赋给外部变量，或在函数内显式返回并在调用处接收。',
    ),
  ];
}

List<_BugCase> _javascriptBugCases(String title, String first, String second) {
  return <_BugCase>[
    _BugCase(
      code: '''// 复现“$title”的数组边界
const data = [3, 1, 4, 1, 5];
let total = 0;
for (let i = 0; i <= data.length; i++) {
  total += data[i];
}
console.log("total =", total);''',
      correct: '循环条件用了 <=，最后一次访问 data[data.length] 得到 undefined。',
      distractors: <String>[
        'const 声明的数组不能参与循环。',
        'console.log 只能输出字符串，数字会被忽略。',
        'total 应该用 const 声明，否则无法累加。',
      ],
      why:
          '数组下标从 0 到 length-1，在“$title”的复现里条件 i <= data.length 会多执行一次；data[data.length] 是 $first 相关位置上的 undefined，参与加法后把 total 变成 NaN。按 $second 的正确边界改成 i < data.length，或用 for...of 直接遍历元素，就能避免边界错误。',
    ),
    _BugCase(
      code: '''// 复现“$title”里的闭包与循环变量
const tasks = [];
for (var i = 1; i <= 3; i++) {
  tasks.push(() => i);
}
console.log(tasks.map((task) => task()).join(","));''',
      correct: 'var 声明的 i 是函数级作用域，三个闭包最终都读到循环结束后的同一个值。',
      distractors: <String>[
        '箭头函数不能放在数组里，必须先转换成普通函数。',
        'map 会修改原数组，所以输出顺序被打乱。',
        'join 只能拼接字符串，数字需要先手动转换。',
      ],
      why:
          'var 在循环结束后仍然保留最后一个值，在“$title”的复现里三个闭包引用的是同一个 $first；因此输出是 4,4,4 而不是 1,2,3。把 $second 对应的 var 换成 let，每次迭代都会创建新的绑定，闭包就能分别捕获正确的值。',
    ),
    _BugCase(
      code: '''// 复现“$title”里的类型比较
const input = "0";
if (input == false) {
  console.log("进入分支");
} else {
  console.log("跳过分支");
}
console.log(input + 1);''',
      correct: '== 会先做类型转换，"0" 被转成数字 0 后与 false 相等。',
      distractors: <String>[
        '字符串不能与布尔值比较，代码会直接抛出语法错误。',
        '加号会把两边都转成布尔值，输出 true。',
        'const 变量在 if 中会被重新赋值，导致条件失效。',
      ],
      why:
          '== 会先做类型转换，在“$title”的复现里字符串 "0" 被转成数字 0，与布尔 false 相等；这让 $first 的判断结果和直觉相反。最后一行 input + 1 触发字符串拼接得到 "01"，要得到 $second 的严格结果，应使用 Number(input) === 0 或 === 比较。',
    ),
  ];
}

List<_BugCase> _cppBugCases(String title, String first, String second) {
  return <_BugCase>[
    _BugCase(
      code: '''// 复现“$title”的数组边界
#include <iostream>
#include <vector>

int main() {
    std::vector<int> data{3, 1, 4, 1, 5};
    int total = 0;
    for (std::size_t i = 0; i <= data.size(); ++i) {
        total += data[i];
    }
    std::cout << "total = " << total << std::endl;
    return 0;
}''',
      correct: '循环条件用了 <=，i == data.size() 时越界访问，属于未定义行为。',
      distractors: <String>[
        'vector 不能在初始化列表里赋值，必须先 push_back。',
        'std::size_t 是无符号类型，不能用于循环。',
        'std::cout 只能输出字符串，整数需要先转换。',
      ],
      why:
          'vector 的合法下标是 0 到 size()-1，在“$title”的复现里条件 i <= data.size() 会多访问一次；越界在 C++ 里属于未定义行为，$first 的结果可能崩溃也可能看似正常。按 $second 的边界改成 i < data.size()，或使用范围 for，才能保证访问始终在边界内。',
    ),
    _BugCase(
      code: '''// 复现“$title”的未初始化变量
#include <iostream>

int main() {
    int total;
    for (int i = 1; i <= 5; ++i) {
        total += i;
    }
    std::cout << total << std::endl;
    return 0;
}''',
      correct: '局部变量 total 没有初始化就参与累加，结果依赖栈上的未定义值。',
      distractors: <String>[
        'for 循环少了 break，执行次数会无限增加。',
        'std::cout 需要先调用 flush，否则没有输出。',
        'int main 必须写成 void main 才能通过编译。',
      ],
      why:
          '局部变量 total 没有初始化，在“$title”的复现里它的初值是未定义的；后续累加会把 $first 的结果交给编译器优化和栈上残留数据决定。要让 $second 的输出稳定，应写成 int total = 0，并在编译时打开 -Wall -Wextra 让警告暴露出来。',
    ),
    _BugCase(
      code: '''// 复现“$title”的悬空引用
#include <iostream>

int& pick() {
    int value = 42;
    return value;
}

int main() {
    std::cout << pick() << std::endl;
    return 0;
}''',
      correct: '函数返回了局部变量的引用，调用结束后对象已销毁，读取属于未定义行为。',
      distractors: <String>[
        'main 函数不能调用其他函数，必须把逻辑内联。',
        'std::endl 会清空 value，所以输出总是 0。',
        '引用必须在堆上分配，栈变量不能取地址。',
      ],
      why:
          '函数返回了局部变量的引用，在“$title”的复现里 value 随着函数返回而销毁；调用方拿到的 $first 引用已经悬空，读取它属于未定义行为。要让 $second 的结果可安全使用，应返回值而不是引用，或用智能指针明确所有权与生命周期。',
    ),
  ];
}

List<_BugCase> _javaBugCases(String title, String first, String second) {
  return <_BugCase>[
    _BugCase(
      code: '''// 复现“$title”的数组边界
public class BoundaryDemo {
    public static void main(String[] args) {
        int[] data = {3, 1, 4, 1, 5};
        int total = 0;
        for (int i = 0; i <= data.length; i++) {
            total += data[i];
        }
        System.out.println("total = " + total);
    }
}''',
      correct: '循环条件用了 <=，i == data.length 时抛出 ArrayIndexOutOfBoundsException。',
      distractors: <String>[
        '数组声明必须写成 int data[]，否则不能遍历。',
        'System.out.println 只能输出字符串，整数需要先转换。',
        'total 声明在循环内部，循环结束后会自动归零。',
      ],
      why:
          'Java 数组的合法下标是 0 到 length-1，在“$title”的复现里 i <= data.length 会多访问一次，触发 ArrayIndexOutOfBoundsException；$first 的边界应改成 i < data.length。要让 $second 的结果稳定，可以用增强 for 循环直接遍历数组，或先把长度保存到局部变量再比较。',
    ),
    _BugCase(
      code: '''// 复现“$title”里的引用比较
public class CompareDemo {
    public static void main(String[] args) {
        String a = new String("ok");
        String b = new String("ok");
        System.out.println(a == b);
    }
}''',
      correct: '== 比较的是两个 String 对象的引用，不是内容；应使用 a.equals(b)。',
      distractors: <String>[
        'String 不能使用 new 创建，只能写成字面量。',
        'println 会自动调用 toString，所以输出一定是 true。',
        '两个字符串内容相同，== 必然返回 true。',
      ],
      why:
          'Java 的 == 对引用类型比较对象地址，在“$title”的复现里 a 与 b 是两次 new 出来的不同对象，因此结果是 false；$first 的语义需要区分“同一对象”和“内容相等”。要让 $second 的判断符合预期，应使用 a.equals(b)，并注意常量池里的字面量比较是另一种情况。',
    ),
  ];
}

List<_BugCase> _csharpBugCases(String title, String first, String second) {
  return <_BugCase>[
    _BugCase(
      code: '''// 复现“$title”的数组边界
var data = new[] { 3, 1, 4, 1, 5 };
var total = 0;
for (var i = 0; i <= data.Length; i++) {
    total += data[i];
}
Console.WriteLine(\$"total = {total}");''',
      correct: '循环条件用了 <=，i == data.Length 时抛出 IndexOutOfRangeException。',
      distractors: <String>[
        'var 不能用于数组，必须显式写出元素类型。',
        'Console.WriteLine 不支持字符串插值，需要手动拼接。',
        'total 没有声明为 long，累加会自动溢出。',
      ],
      why:
          'C# 数组的合法下标是 0 到 Length-1，在“$title”的复现里 i <= data.Length 会越界，抛出 IndexOutOfRangeException；$first 的边界应改成 i < data.Length。要让 $second 的结果稳定，可以用 foreach 直接遍历，或在循环前保存长度并写清单元测试。',
    ),
    _BugCase(
      code: '''// 复现“$title”里遍历时修改集合
var items = new List<int> { 1, 2, 3, 4 };
foreach (var item in items) {
    if (item % 2 == 0) items.Remove(item);
}
Console.WriteLine(string.Join(",", items));''',
      correct:
          'foreach 期间修改集合会抛出 InvalidOperationException，应遍历副本或使用 RemoveAll。',
      distractors: <String>[
        'List 不能使用 foreach，只能使用 for 循环。',
        '取余运算对偶数返回 1，判断条件写反了。',
        'string.Join 会修改原集合，所以输出顺序不稳定。',
      ],
      why:
          'List 的枚举器会在版本变化时失效，在“$title”的复现里 foreach 过程中调用 Remove 会抛出 InvalidOperationException；$first 的修改与遍历发生了冲突。要让 $second 的结果稳定，可以遍历 items.ToList() 副本，或使用 items.RemoveAll(item => item % 2 == 0)。',
    ),
  ];
}

List<_BugCase> _goBugCases(String title, String first, String second) {
  return <_BugCase>[
    _BugCase(
      code: '''// 复现“$title”的切片边界
package main

import "fmt"

func main() {
    data := []int{3, 1, 4, 1, 5}
    total := 0
    for i := 0; i <= len(data); i++ {
        total += data[i]
    }
    fmt.Println("total =", total)
}''',
      correct: '循环条件用了 <=，i == len(data) 时越界，运行时 panic。',
      distractors: <String>[
        '切片必须先用 make 分配长度，否则不能遍历。',
        'fmt.Println 只能输出字符串，整数需要先转换。',
        'total 使用 := 声明后不能再参与累加。',
      ],
      why:
          'Go 切片的合法下标是 0 到 len(data)-1，在“$title”的复现里 i <= len(data) 会多访问一次并触发 index out of range；$first 的边界应改成 i < len(data)。要让 $second 的结果稳定，可以直接使用 for _, v := range data 或把长度保存在局部变量中。',
    ),
    _BugCase(
      code: '''// 复现“$title”里的循环变量捕获
package main

import (
    "fmt"
    "sync"
)

func main() {
    var wg sync.WaitGroup
    for i := 1; i <= 3; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            fmt.Println(i)
        }()
    }
    wg.Wait()
}''',
      correct: '闭包直接捕获循环变量 i，多个 goroutine 可能打印同一个值；应把 i 作为参数传入。',
      distractors: <String>[
        'sync.WaitGroup 不能与 goroutine 一起使用。',
        'fmt.Println 在 goroutine 中调用会导致死锁。',
        'for 循环中的 i 必须在循环外部声明。',
      ],
      why:
          'Go 的闭包按引用捕获外部变量，在“$title”的复现里多个 goroutine 可能共享同一个 $first；它们的执行时机不确定，输出顺序和值都可能出乎意料。要让 $second 的结果可复现，应写成 go func(n int) { ... }(i)，或者把变量在循环体内复制一份再传入闭包。',
    ),
  ];
}

List<_BugCase> _rustBugCases(String title, String first, String second) {
  return <_BugCase>[
    _BugCase(
      code: '''// 复现“$title”的区间边界
fn main() {
    let data = vec![3, 1, 4, 1, 5];
    let mut total = 0;
    for i in 0..=data.len() {
        total += data[i];
    }
    println!("total = {}", total);
}''',
      correct: '0..=data.len() 包含上界，i == len 时越界 panic；应使用 0..data.len()。',
      distractors: <String>[
        'Vec 不能用下标访问，只能使用迭代器。',
        'println! 宏只能输出字符串，整数需要先转换。',
        'total 必须声明为可变引用，否则不能累加。',
      ],
      why:
          'Rust 的区间表达式 ..= 包含右端点，在“$title”的复现里 0..=data.len() 会让 i 取到 len，访问 data[len] 时直接 panic；$first 的边界应改成 0..data.len()。要让 $second 的结果稳定，可以直接使用 for item in &data，让迭代器负责全部边界。',
    ),
    _BugCase(
      code: '''// 复现“$title”里的借用冲突
fn main() {
    let mut data = vec![1, 2, 3];
    let first = &data[0];
    data.push(4);
    println!("{}", first);
}''',
      correct: '不可变借用 first 仍在使用时修改 data，违反借用规则，编译无法通过。',
      distractors: <String>[
        'Vec 不能在声明后继续 push 新元素。',
        'println! 不能打印引用，需要先复制成字符串。',
        'data 必须是不可变变量，才能安全地读取 first。',
      ],
      why:
          'Rust 的借用检查器要求共享借用与可变借用不能同时存在，在“$title”的复现里 first 仍指向 data，push 需要可变借用，因此编译报错；$first 的生命周期需要先结束。要让 $second 的结果可编译，可以先复制出值，或把读取与修改拆到两个作用域里。',
    ),
  ];
}

List<_BugCase> _kotlinBugCases(String title, String first, String second) {
  return <_BugCase>[
    _BugCase(
      code: '''// 复现“$title”的区间边界
fun main() {
    val data = intArrayOf(3, 1, 4, 1, 5)
    var total = 0
    for (i in 0..data.size) {
        total += data[i]
    }
    println("total = \$total")
}''',
      correct: '0..data.size 包含上界，i == size 时抛出 ArrayIndexOutOfBoundsException；应使用 until。',
      distractors: <String>[
        'IntArray 不能使用下标访问，只能调用 get。',
        'println 不支持字符串模板，需要手动拼接。',
        'total 必须声明为 val，否则不能累加。',
      ],
      why:
          'Kotlin 的 .. 是闭区间，在“$title”的复现里 0..data.size 会让 i 取到 size，访问 data[size] 时越界；$first 的边界应改成 0 until data.size 或 data.indices。要让 $second 的结果稳定，可以直接使用 for (value in data) 遍历元素。',
    ),
    _BugCase(
      code: '''// 复现“$title”里的可空类型
fun main() {
    var name: String? = null
    println(name.length)
}''',
      correct: 'name 是可空类型，直接访问 length 无法通过编译，应使用 name?.length 或先判空。',
      distractors: <String>[
        'String? 只能赋值为空字符串，不能赋值为 null。',
        'println 不能输出可空类型，需要先调用 toString。',
        'var 声明的变量不能保存字符串，必须换成 val。',
      ],
      why:
          'Kotlin 把可空性写进类型系统，在“$title”的复现里 name 的类型是 String?，编译器不允许直接调用 length；$first 的安全访问需要显式处理。要让 $second 的结果符合预期，可以使用 name?.length、name ?: "未知" 或先做 if (name != null) 判断。',
    ),
  ];
}

List<_BugCase> _swiftBugCases(String title, String first, String second) {
  return <_BugCase>[
    _BugCase(
      code: '''// 复现“$title”的区间边界
let data = [3, 1, 4, 1, 5]
var total = 0
for i in 0...data.count {
    total += data[i]
}
print("total = \\(total)")''',
      correct: '0...data.count 是闭区间，i == count 时越界崩溃；应使用 0..<data.count。',
      distractors: <String>[
        'Swift 数组不能用下标访问，只能使用 for-in。',
        'print 不能输出整数，需要先转换成 String。',
        'total 必须声明为 let，否则不能累加。',
      ],
      why:
          'Swift 的 ... 运算符创建闭区间，在“$title”的复现里 0...data.count 会把 count 也包含进来，访问 data[count] 时越界；$first 的边界应改成 0..<data.count。要让 $second 的结果稳定，可以直接使用 for value in data，避免手动管理下标。',
    ),
    _BugCase(
      code: '''// 复现“$title”里的可选值
var name: String? = nil
print(name.count)''',
      correct: 'name 是可选类型，直接访问 count 无法通过编译，应使用 name?.count 或解包。',
      distractors: <String>[
        'String? 只能保存空字符串，不能保存 nil。',
        'print 不能输出可选类型，必须先调用 description。',
        'var 声明的变量不能保存字符串，必须换成 let。',
      ],
      why:
          'Swift 用 Optional 表示可能缺失的值，在“$title”的复现里 name 的类型是 String?，编译器要求先解包才能访问 count；$first 的安全访问需要显式处理。要让 $second 的结果符合预期，可以使用 name?.count、if let 绑定或提供默认值。',
    ),
  ];
}

List<_BugCase> _dartBugCases(String title, String first, String second) {
  return <_BugCase>[
    _BugCase(
      code: '''// 复现“$title”的列表边界
void main() {
  final data = [3, 1, 4, 1, 5];
  var total = 0;
  for (var i = 0; i <= data.length; i++) {
    total += data[i];
  }
  print(total);
}''',
      correct: '循环条件用了 <=，i == data.length 时抛出 RangeError；应改成 i < data.length。',
      distractors: <String>[
        'final 列表不能使用下标访问，只能使用迭代器。',
        'print 只能输出字符串，整数需要先转换。',
        'total 声明为 var 后不能参与累加。',
      ],
      why:
          'Dart 列表的合法下标是 0 到 length-1，在“$title”的复现里 i <= data.length 会多访问一次并抛出 RangeError；$first 的边界应改成 i < data.length。要让 $second 的结果稳定，可以直接使用 for (final value in data) 遍历元素。',
    ),
    _BugCase(
      code: '''// 复现“$title”里的空安全
void main() {
  String? name;
  print(name.length);
}''',
      correct: 'name 是可空类型，直接访问 length 无法通过编译，应使用 name?.length 或先判空。',
      distractors: <String>[
        'String? 只能保存空字符串，不能保存 null。',
        'print 不能输出可空类型，必须先调用 toString。',
        'final 变量必须初始化，String? 也不例外。',
      ],
      why:
          'Dart 的空安全把可空性写进类型系统，在“$title”的复现里 name 的类型是 String?，编译器不允许直接访问 length；$first 的安全访问需要显式处理。要让 $second 的结果符合预期，可以使用 name?.length、name ?? "未知" 或先做 if (name != null) 判断。',
    ),
  ];
}

String? languageFromCode(String code) {
  final trimmed = code.trim();
  if (trimmed.isEmpty) return null;
  if (RegExp(
    r'^\s*(#include|using\s+namespace|int\s+main\s*\()',
    multiLine: true,
  ).hasMatch(trimmed)) {
    return 'cpp';
  }
  if (RegExp(
    r'\b(SELECT|INSERT\s+INTO|UPDATE|DELETE\s+FROM|CREATE\s+TABLE)\b',
    caseSensitive: false,
  ).hasMatch(trimmed)) {
    return 'sql';
  }
  if (RegExp(
        r'^\s*(#!/usr/bin/env\s+bash|#!/bin/bash|#!\s*/bin/bash)',
        multiLine: true,
      ).hasMatch(trimmed) ||
      RegExp(r'^\s*echo\s+', multiLine: true).hasMatch(trimmed)) {
    return 'bash';
  }
  final hasJsEvidence =
      RegExp(r'\b(console\.log|document\.|require\(|module\.exports)\b')
          .hasMatch(trimmed) ||
      RegExp(r'\b(const|let)\s+\w+\s*=').hasMatch(trimmed) ||
      RegExp(r'\bfunction\s+\w+\s*\(').hasMatch(trimmed) ||
      trimmed.contains('=>');
  if (hasJsEvidence) {
    final hasTsEvidence = RegExp(
      r'(\binterface\s+\w+\s*\{|\btype\s+\w+\s*=|\bexport\s+(interface|type|class)|\w+\s*:\s*(string|number|boolean)\b)',
    ).hasMatch(trimmed);
    return hasTsEvidence ? 'typescript' : 'javascript';
  }
  if (RegExp(r'\bprint\s*\(').hasMatch(trimmed) ||
      RegExp(
        r'^\s*(def|class|import|from\s+\w+\s+import)\s+',
        multiLine: true,
      ).hasMatch(trimmed)) {
    return 'python';
  }
  if (trimmed.startsWith('<?xml')) return 'xml';
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) return 'json';
  return null;
}
