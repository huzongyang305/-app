// 入门/基础课程生成工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/generate_beginner_lessons.dart
//
// 读取 tool/beginner_specs.json，生成 80 篇入门课和特殊题型测验。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String specPath = 'tool/beginner_specs.json';
const String batchDir = 'tool/beginner_batches';
const String updatedAt = '2026-10-03';

const Map<String, String> languageTags = <String, String>{
  'python': 'python',
  'cpp': 'cpp',
  'java': 'java',
  'javascript': 'javascript',
  'csharp': 'csharp',
  'go': 'go',
  'rust': 'rust',
  'typescript': 'typescript',
  'shell': 'bash',
  'c': 'c',
  'kotlin': 'kotlin',
  'swift': 'swift',
  'flutter': 'dart',
  'html_css': 'html',
  'ai': 'python',
  'security': 'python',
  'network': 'python',
  'database': 'sql',
  'os': 'python',
  'algorithms': 'python',
  'fundamentals': 'python',
  'toolchain': 'bash',
  'math': 'python',
};

const Map<String, String> codeSamples = <String, String>{
  'python': 'value = 2 + 3\nprint(f"result={value}")',
  'cpp': '#include <iostream>\nint main() { std::cout << 2 + 3 << "\\n"; }',
  'java': 'public class Main {\n  public static void main(String[] args) { System.out.println(2 + 3); }\n}',
  'javascript': 'const value = 2 + 3;\nconsole.log(`result=\${value}`);',
  'csharp': 'Console.WriteLine(2 + 3);',
  'go': 'package main\nimport "fmt"\nfunc main() { fmt.Println(2 + 3) }',
  'rust': 'fn main() { println!("result={}", 2 + 3); }',
  'typescript':
      'const value: number = 2 + 3;\nconsole.log(`result=\${value}`);',
  'shell': '#!/usr/bin/env bash\nset -euo pipefail\nvalue=\$((2 + 3))\necho "result=\$value"',
  'c': '#include <stdio.h>\nint main(void) { printf("result=%d\\n", 2 + 3); return 0; }',
  'kotlin': 'fun main() { println("result=\${2 + 3}") }',
  'swift': 'let value = 2 + 3\nprint("result=\\(value)")',
  'flutter': 'void main() => print(2 + 3);',
  'html_css': '<button type="button">提交</button>',
  'sql': 'SELECT 2 + 3 AS result;',
};

const Map<String, String> specialFailures = <String, String>{
  'python': '忘记转换 input() 返回的字符串，直接参与算术会抛 TypeError。',
  'cpp': '忘记包含头文件或编译参数，导致编译失败。',
  'java': '类名与文件名不一致，导致编译失败。',
  'javascript': '把 == 与 === 混用，造成隐式类型转换。',
  'csharp': '输入转换失败没有处理，运行时抛出 FormatException。',
  'go': '忽略函数返回的 error，导致错误被静默吞掉。',
  'rust': '变量没有声明 mut 就尝试修改，导致编译错误。',
  'typescript': '把任意字符串赋给联合类型，类型检查失败。',
  'shell': '变量没有加引号，路径包含空格时命令参数被拆分。',
  'c': '数组越界或忘记字符串终止符，造成未定义行为。',
  'kotlin': '直接访问可空变量，编译期要求先做空值处理。',
  'swift': '强制解包 nil 可选值，运行时崩溃。',
};

Future<void> main(List<String> args) async {
  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
  final categories = (manifest['categories'] as List)
      .cast<Map<String, dynamic>>();
  final categoryById = <String, Map<String, dynamic>>{
    for (final raw in categories)
      (raw as Map).cast<String, dynamic>()['id'] as String: raw
          .cast<String, dynamic>(),
  };
  final existingIds = <String>{};
  for (final category in categories) {
    existingIds.addAll(
      (category['lessons'] as List).map(
        (item) => (item as Map)['id'] as String,
      ),
    );
  }

  final specs = (jsonDecode(await File(specPath).readAsString()) as Map)
      .cast<String, dynamic>();
  final grouped = <String, List<MapEntry<String, Map<String, dynamic>>>>{};
  for (final entry in specs.entries) {
    final value = (entry.value as Map).cast<String, dynamic>();
    final categoryId = value['category'] as String;
    grouped.putIfAbsent(categoryId, () => []).add(MapEntry(entry.key, value));
    if (!categoryById.containsKey(categoryId)) {
      stderr.writeln('分类不存在：$categoryId');
      exitCode = 1;
      return;
    }
  }

  final batches = <String, List<Map<String, dynamic>>>{};
  var generated = 0;
  for (final categoryEntry in grouped.entries) {
    final categoryId = categoryEntry.key;
    final lessons = categoryEntry.value;
    for (var index = 0; index < lessons.length; index++) {
      final id = lessons[index].key;
      final spec = lessons[index].value;
      if (existingIds.contains(id)) continue;
      final title = ((spec['title'] as Map)['zh'] as String).trim();
      final summary = ((spec['summary'] as Map)['zh'] as String).trim();
      final points = [
        '先认识「$title」需要的工具、输入和输出。',
        '按步骤运行最小示例，并记录结果与错误。',
        '用一个边界输入验证自己是否真正掌握。',
      ];
      final markdown = _buildMarkdown(
        categoryId,
        title,
        summary,
        points,
        categoryById[categoryId]!,
      );
      await File('assets/content/$id.md').writeAsString(markdown, flush: true);
      final quiz = _buildQuiz(id, categoryId, title, summary, points, lessons);
      final order = -(lessons.length - index);
      final difficulty =
          const {'security', 'ai', 'math', 'fundamentals'}.contains(categoryId)
          ? '基础'
          : '入门';
      batches.putIfAbsent(categoryId, () => []).add({
        'id': id,
        'title': spec['title'],
        'summary': spec['summary'],
        'file': 'assets/content/$id.md',
        'minutes': 15,
        'keywords': [title, categoryById[categoryId]!['title']['zh'], '入门练习'],
        'difficulty': difficulty,
        'order': order,
        'quiz': quiz,
      });
      existingIds.add(id);
      generated++;
    }
  }

  await Directory(batchDir).create(recursive: true);
  for (final entry in batches.entries) {
    await File('$batchDir/${entry.key}.json').writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert({'category': entry.key, 'lessons': entry.value}),
      flush: true,
    );
  }
  stdout.writeln('生成入门课程：$generated 篇，批次 ${batches.length} 个');
}

String _buildMarkdown(
  String categoryId,
  String title,
  String summary,
  List<String> points,
  Map<String, dynamic> category,
) {
  final language = languageTags[categoryId] ?? 'text';
  final code = codeSamples[categoryId] ?? 'print("hello")';
  final categoryTitle = (category['title'] as Map)['zh'] as String;
  final buffer = StringBuffer()
    ..writeln('# $title')
    ..writeln()
    ..writeln('> 内容更新时间：$updatedAt · 学习阶段：入门 · 预计用时：15 分钟')
    ..writeln()
    ..writeln('## 学习目标')
    ..writeln();
  for (final point in points) {
    buffer.writeln('- $point');
  }
  buffer
    ..writeln()
    ..writeln('## 前置知识')
    ..writeln()
    ..writeln('- 会进行基本的文件或命令行操作。')
    ..writeln('- 不需要预先掌握「$categoryTitle」的高级知识。')
    ..writeln()
    ..writeln('## 一句话入门')
    ..writeln()
    ..writeln(summary)
    ..writeln()
    ..writeln('## 最小示例')
    ..writeln()
    ..writeln('```$language')
    ..writeln(code)
    ..writeln('```')
    ..writeln()
    ..writeln('## 预期输出')
    ..writeln()
    ..writeln('```text')
    ..writeln('result=5')
    ..writeln('```')
    ..writeln()
    ..writeln('## 常见错误')
    ..writeln()
    ..writeln('- ${specialFailures[categoryId] ?? '输入或环境与示例不一致，导致结果不符合预期。'}')
    ..writeln('- 复制命令时遗漏空格、引号或必要参数。')
    ..writeln()
    ..writeln('## 动手练习')
    ..writeln()
    ..writeln('1. 原样运行最小示例，保存命令和输出。')
    ..writeln('2. 把数字 2 改成 10，预测并验证新结果。')
    ..writeln('3. 制造一个错误输入，写出错误信息和修复方法。')
    ..writeln()
    ..writeln('## 本课小结')
    ..writeln()
    ..writeln('- 入门阶段先保证能运行、能观察、能解释，再追求复杂功能。')
    ..writeln('- 每次只改一个变量，记录预测与实际结果。')
    ..writeln('- 遇到错误先看第一条错误信息，再回到最小示例。')
    ..writeln();
  return buffer.toString().trimRight();
}

List<Map<String, dynamic>> _buildQuiz(
  String id,
  String categoryId,
  String title,
  String summary,
  List<String> points,
  List<MapEntry<String, Map<String, dynamic>>> siblings,
) {
  final correctOutput = 'result=5';
  final wrongOutputs = ['result=23', '编译失败', '没有任何输出'];
  final failure = specialFailures[categoryId] ?? '没有检查输入和环境。';
  final wrongFailures = [
    '只要代码能运行，就不需要观察输出。',
    '出错后应该直接重写整个程序。',
    '边界输入不会影响入门程序。',
  ];
  final orderOptions = [
    '运行最小示例 → 修改一个值 → 预测结果 → 验证输出',
    '修改所有代码 → 删除测试 → 直接部署 → 再阅读错误',
    '先优化性能 → 再写需求 → 最后运行',
    '复制答案 → 不运行 → 认为已经掌握',
  ];
  final fillCorrect = '最小示例 → 预测 → 运行 → 对比';
  final fillWrong = ['直接上线 → 再观察', '复制代码 → 不运行', '优化性能 → 再写代码'];
  return [
    {
      'question': '运行「$title」的最小示例，预期输出是什么？',
      'options': [correctOutput, ...wrongOutputs],
      'answer': 0,
      'explanation': '示例计算 2 + 3，并输出 result=5。加法结果不是 23，程序也不应该编译失败或无输出；先运行最小示例并观察 stdout 是入门阶段最重要的验证动作。',
      'type': 'code',
      'code': codeSamples[categoryId] ?? 'print("hello")',
    },
    {
      'question': '「$title」最容易出现的错误是？',
      'options': [failure, ...wrongFailures],
      'answer': 0,
      'explanation':
          '$failure 其他选项把错误处理理解成跳过验证或推倒重写；正确做法是先阅读第一条错误信息，回到最小示例，只改变一个变量并复现问题。',
      'type': 'debug',
    },
    {
      'question': '学习「$title」时，正确的操作顺序是？',
      'options': orderOptions,
      'answer': 0,
      'explanation':
          '入门学习应先运行最小示例，再修改一个值，写下预测并运行验证。一次修改多个变量会让失败原因无法定位，直接优化或部署也缺少正确性基线。',
      'type': 'order',
    },
    {
      'question': '「$title」的练习闭环应该怎么填空？',
      'options': [fillCorrect, ...fillWrong],
      'answer': 0,
      'explanation':
          '最小示例、预测、运行、对比构成最小学习闭环。跳过运行或不记录结果都无法验证理解，先优化性能则容易在错误基线上做无效工作。',
      'type': 'fill',
    },
  ];
}
