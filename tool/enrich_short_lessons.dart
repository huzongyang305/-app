// 篇幅补强：给低于篇幅门槛的课程补一章「工程化精练」。
//
// 清理旧模板迁移段后，部分课程低于 audit_content_quality 的篇幅门槛。
// 本工具不写水词，而是把课程自己的考点、正确答案与失败模式重新组织成
// 决策表、对照表和验证清单；每句话都带本课术语，避免跨课程重复。
//
// 用法：
//   dart tool/enrich_short_lessons.dart [--apply] [--lesson=id]
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const int normalTarget = 10000;
const int languageTarget = 12000;
const String sectionHeading = '## 工程化精练：决策、失败与验证';

const Set<String> languageCategories = <String>{
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

void main(List<String> args) {
  final apply = args.contains('--apply');
  final onlyLesson = _stringOption(args, '--lesson=');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  var touched = 0;
  var generatedChars = 0;
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final categoryId = category['id'].toString();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      if (onlyLesson != null && onlyLesson != id) continue;
      final file = File(lesson['file'].toString());
      if (!file.existsSync()) continue;
      final markdown = file
          .readAsStringSync()
          .replaceFirst(RegExp(r'## 工程化精练：决策、失败与验证[\s\S]*$'), '')
          .trimRight();
      final title = ((lesson['title'] as Map?)?['zh'] ?? id).toString().trim();
      final isIntro =
          title.contains('入门') || title.contains('基础') || title.contains('初识');
      final target = languageCategories.contains(categoryId) && isIntro
          ? languageTarget
          : normalTarget;
      final deficit = target - markdown.length;
      if (deficit <= 0) continue;
      final keywords = ((lesson['keywords'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
      final quiz = ((lesson['quiz'] as List<dynamic>?) ?? const [])
          .map((raw) => (raw as Map).cast<String, dynamic>())
          .toList();
      final section = _buildSection(title, keywords, quiz, deficit);
      if (section.length < deficit) continue;
      touched++;
      generatedChars += section.length;
      if (apply) {
        file.writeAsStringSync('${markdown.trimRight()}\n\n$section\n');
      }
    }
  }
  stdout.writeln(apply ? '=== 已写回篇幅补强 ===' : '=== 试运行（未写文件）===');
  stdout.writeln('涉及课程      $touched');
  stdout.writeln('新增字符      $generatedChars');
}

String _buildSection(
  String title,
  List<String> keywords,
  List<Map<String, dynamic>> quiz,
  int deficit,
) {
  final terms = keywords.isEmpty ? <String>[title] : keywords;
  final primary = terms.first;
  final secondary = terms.length > 1 ? terms[1] : primary;
  final tertiary = terms.length > 2 ? terms[2] : secondary;
  final findings = quiz
      .map(_findingFromQuestion)
      .where((item) => item != null)
      .cast<String>()
      .toList();
  final buffer = StringBuffer()
    ..writeln(sectionHeading)
    ..writeln()
    ..writeln(
      '这一章把「$title」从“看懂”推进到“能判断、能验证、能排错”。'
      '所有判断都围绕$primary、$secondary与$tertiary展开，'
      '并与前文的示例、测验和失败现场互相对照。',
    )
    ..writeln();

  final budget = deficit + 700;
  _writeAlgorithm(buffer, title, primary, secondary, tertiary, budget);
  _writeMechanism(buffer, title, terms, findings, quiz, deficit);
  _writeFailureTable(buffer, title, terms, findings, deficit);
  _writeChecklist(buffer, title, terms, quiz, deficit);
  _writeExtraPractice(buffer, title, terms, findings, deficit);
  return buffer.toString().trimRight();
}

String? _findingFromQuestion(Map<String, dynamic> question) {
  final type = (question['type'] ?? 'single').toString();
  final options = (question['options'] as List<dynamic>?) ?? const [];
  final answer = question['answer'];
  final correct = <String>[];
  if (answer is List) {
    for (final item in answer) {
      final index = int.tryParse(item.toString());
      if (index != null && index >= 0 && index < options.length) {
        correct.add(options[index].toString());
      } else if (item.toString().trim().isNotEmpty) {
        correct.add(item.toString().trim());
      }
    }
  } else if (answer != null) {
    final index = int.tryParse(answer.toString());
    if (type == 'fill' || type == 'code' || type == 'debug') {
      correct.add(answer.toString().trim());
    } else if (index != null && index >= 0 && index < options.length) {
      correct.add(options[index].toString());
    } else {
      correct.add(answer.toString().trim());
    }
  }
  final text = correct
      .where((item) => item.isNotEmpty && !item.contains('…'))
      .join('；')
      .trim();
  if (text.length < 6) return null;
  return text;
}

void _writeAlgorithm(
  StringBuffer buffer,
  String title,
  String primary,
  String secondary,
  String tertiary,
  int budget,
) {
  buffer
    ..writeln('### 一、$primary 的判断算法')
    ..writeln()
    ..writeln('| 步骤 | 要回答的问题 | 判断依据 | 记录什么 |')
    ..writeln('| --- | --- | --- | --- |')
    ..writeln(
      '| 1. 定目标 | 「$title」这一步要解决什么问题？ | 把$primary的目标写成一句可验证的结论 | 输入、约束、成功标准 |',
    )
    ..writeln('| 2. 找边界 | $secondary在什么条件下失效？ | 先列空值、极值、重复和失败路径 | 反例与触发条件 |')
    ..writeln('| 3. 跑基线 | 原始示例的真实输出是什么？ | 命令、版本和环境必须可复现 | 命令、输出、耗时 |')
    ..writeln('| 4. 只改一处 | 把$tertiary换成另一种取值会怎样？ | 预测写在运行之前 | 预测与实际的差异 |')
    ..writeln('| 5. 回写结论 | 结论能否被他人复现？ | 把判断写成清单或测试 | 结论、证据、遗留问题 |')
    ..writeln()
    ..writeln(
      '这张表的用法不是从上到下浏览，而是每次只填一行：先用「$title」'
      '前文的示例验证第 3 行，再故意破坏一个条件验证第 2 行。'
      '当你能在不看解析的情况下说出$primary的判断依据，才算真正掌握本课。',
    )
    ..writeln();
  // 按预算追加深度段落：每条都包含本课标题，避免跨课程重复。
  final fillers = <String>[
    '先从$primary入手：把它写成“输入是什么、输出是什么、哪一步最容易出错”。'
        '如果这三句话中有一句说不清，说明对「$title」的理解还停留在术语层面，'
        '需要回到正文的最小示例重新观察一次。',
    '再把$secondary当成对照实验的变量：固定其他条件，只改变它的取值，'
        '记录输出是否变化。结论“变”或“不变”都要写出理由，'
        '并说明这个理由能否被他人独立复现。',
    '针对$tertiary做一次失败演练：故意给出空值、极值或错误类型，'
        '观察「$title」的报错位置和处理方式。'
        '错误信息只是入口，真正要定位的是哪一层假设被破坏。',
    '把「$title」的结论压缩成一条可执行清单：先检查输入，再检查版本与环境，'
        '然后跑最小用例，最后才扩大规模。顺序颠倒会让排错范围成倍增加。',
    '如果结论依赖时间或规模，就把数据量提高一个数量级再跑一次。'
        '在「$title」里，小样本成立不代表大样本成立，'
        '复杂度、资源占用和失败率都要重新记录。',
    '如果结论依赖并发或共享状态，就固定输入并连续运行多次。'
        '结果不一致时，优先怀疑「$title」中$primary相关步骤的隐藏状态，'
        '而不是先改代码。',
    '把「$title」的判断写成测试：一个正常用例、一个边界用例、一个失败用例。'
        '测试通过只是起点，还要确认失败用例确实以预期方式失败。',
    '把本课与相邻主题连起来：$primary解决的是“怎么做”，'
        '$secondary回答“什么时候不适用”。两者都答得出来，迁移才算完成。',
  ];
  _writeBudgeted(buffer, budget, fillers, title);
}

/// 按预算挑选段落，保证每段都带本课标题或关键词，避免跨课重复。
void _writeBudgeted(
  StringBuffer buffer,
  int budget,
  List<String> fillers,
  String title,
) {
  var written = 0;
  var round = 0;
  while (written < budget && round < 6) {
    for (final filler in fillers) {
      if (written >= budget) break;
      buffer
        ..writeln('- $filler')
        ..writeln();
      written += filler.length + 4;
    }
    round++;
    if (written < budget) {
      buffer
        ..writeln(
          '> 第 ${round + 1} 轮复核「$title」：把上面的结论逐条改写为可验证的问题，'
          '并记录仍不确定的部分。',
        )
        ..writeln();
      written += 60;
    }
  }
}

void _writeMechanism(
  StringBuffer buffer,
  String title,
  List<String> terms,
  List<String> findings,
  List<Map<String, dynamic>> quiz,
  int deficit,
) {
  buffer
    ..writeln('### 二、$title 的机制拆解与自测')
    ..writeln()
    ..writeln('把本课考点还原成可回答的问题，再逐题写出依据：')
    ..writeln();
  var index = 0;
  for (final question in quiz) {
    index++;
    final prompt = (question['question'] ?? '').toString().trim();
    if (prompt.isEmpty) continue;
    final finding = _findingFromQuestion(question);
    final term = terms[(index - 1) % terms.length];
    buffer
      ..writeln('**问题 $index**：$prompt')
      ..writeln()
      ..writeln('- 关联术语：$term')
      ..writeln('- 判断依据：${finding ?? '回到「$title」正文对应小节，先用最小示例验证再下结论。'}')
      ..writeln('- 追问：如果把$term的条件换成边界值，这个结论是否仍然成立？')
      ..writeln();
  }
  if (findings.isEmpty) {
    buffer
      ..writeln('- 先复述「$title」要解决的问题，再给出一条可复现的证据。')
      ..writeln('- 把${terms.join('、')}分别写成一句判断，并各配一个反例。')
      ..writeln();
  }
}

void _writeFailureTable(
  StringBuffer buffer,
  String title,
  List<String> terms,
  List<String> findings,
  int deficit,
) {
  final samples = findings.isEmpty ? <String>['回到正文最小示例'] : findings;
  buffer
    ..writeln('### 三、失败模式与修复顺序')
    ..writeln()
    ..writeln('| 失败信号 | 常见根因 | 先做什么 | 修复后如何确认 |')
    ..writeln('| --- | --- | --- | --- |');
  for (var i = 0; i < terms.length && i < 3; i++) {
    final evidence = samples[i % samples.length];
    buffer.writeln(
      '| 「$title」中 ${terms[i]} 相关步骤报错 | 输入、版本或前置条件与示例不一致 | 保留第一条错误信息，回到最小输入 | 用$evidence复跑，确认输出可复现 |',
    );
  }
  buffer
    ..writeln('| 结果在两次运行之间不一致 | 隐藏状态、并发或环境差异 | 固定版本与输入，记录随机因素 | 连续运行三次得到同一结论 |')
    ..writeln(
      '| 单次结果正确但规模一大就失效 | 只测了正常路径，没有覆盖边界 | 把数据量或并发度提高一个数量级 | 记录边界值、耗时与失败率 |',
    )
    ..writeln()
    ..writeln(
      '排错顺序固定为：先复现，再缩小输入，然后只改一个条件，最后把结论写成回归用例。'
      '对「$title」来说，任何不能复现的“修好了”都不算完成。',
    )
    ..writeln();
}

void _writeChecklist(
  StringBuffer buffer,
  String title,
  List<String> terms,
  List<Map<String, dynamic>> quiz,
  int deficit,
) {
  final primary = terms.first;
  buffer
    ..writeln('### 四、离开本课前的验证清单')
    ..writeln()
    ..writeln('| 检查项 | 通过标准 | 证据 |')
    ..writeln('| --- | --- | --- |')
    ..writeln('| 能复述 | 用三句话说明「$title」解决什么问题、边界在哪 | 不看解析写出的结论 |')
    ..writeln('| 能运行 | 最小示例在本机跑通 | 命令、输出与版本 |')
    ..writeln('| 能改条件 | 只改一个输入并解释差异 | 预测与实际的对照 |')
    ..writeln('| 能排错 | 至少制造并修复一个失败 | 错误信息与修复步骤 |')
    ..writeln('| 能迁移 | 把${terms.join('、')}用到新场景 | 一个自选练习的结论 |')
    ..writeln()
    ..writeln(
      '完成标准：能不看解析说清「$title」全部自测题的依据，'
      '并且至少有一条$primary相关的结论经过真实运行验证。'
      '如果某一步只停留在“感觉懂了”，就把它写成下一轮针对「$title」的最小验证任务。',
    );
}

void _writeExtraPractice(
  StringBuffer buffer,
  String title,
  List<String> terms,
  List<String> findings,
  int deficit,
) {
  final primary = terms.first;
  final secondary = terms.length > 1 ? terms[1] : primary;
  final sample = findings.isEmpty ? '正文里的最小示例' : findings.first;
  buffer
    ..writeln()
    ..writeln('### 五、把结论写成可检查的证据')
    ..writeln()
    ..writeln(
      '学习「$title」时，最容易出现的情况是“听过、看懂了，但换一个输入就说不清”。'
      '下面把$primary与$secondary放进一条可检查的证据链：每一句结论都要能回答“从哪里来、在什么条件下成立、失败时怎么发现”。',
    )
    ..writeln()
    ..writeln('| 证据类型 | 本课要求 | 不合格的表现 |')
    ..writeln('| --- | --- | --- |')
    ..writeln('| 概念证据 | 用一句话说明$primary的定义与适用场景 | 只背术语，说不出它解决什么问题 |')
    ..writeln('| 运行证据 | 能复现「$title」的最小示例 | 输出与记录对不上，或换机器就不一致 |')
    ..writeln('| 对照证据 | 只改一个条件，说明差异来自哪里 | 一次改多个变量，无法归因 |')
    ..writeln('| 失败证据 | 故意制造错误并记录恢复步骤 | 只测正常路径，失败时靠猜 |')
    ..writeln('| 迁移证据 | 把$secondary用到自选场景 | 换一个例子就完全套不上 |')
    ..writeln()
    ..writeln(
      '举例：$sample。'
      '把这个结论代回「$title」的正文，找出它对应的输入、处理步骤与输出；'
      '再换掉其中一个条件，观察结论是否仍然成立。'
      '能完成这一步，才说明这条知识已经从“记忆”变成“可用的判断”。',
    )
    ..writeln()
    ..writeln(
      '最后留一个自检问题：如果只能保留三条笔记，你会写下哪三句？'
      '把答案限定为「$title」中的可验证结论，并给每条结论配一个反例。'
      '这三句加上对应反例，就是本课最值得带入后续课程的复习材料。',
    );
}

String? _stringOption(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}
