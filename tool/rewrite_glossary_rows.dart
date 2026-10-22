import 'dart:io';

import 'data/glossary_definitions.dart';
import 'data/glossary_definitions_extended.dart';

/// P0 术语表清理：把模板残留的术语说明改写成从课程正文提炼的真实说明。
///
/// 背景：早期生成器把课程摘要、题目题干和故障排查模板写进了术语表，
/// 例如 `Related terms: ...`、`... focuses on ...`、
/// `它在「课名」里是理解「术语」的关键术语……复习时回到正文`、
/// `检查调用链、输入数据和环境配置`。
///
/// 本工具的处理顺序：
///   1. 先查人工校准的术语字典，确保常用概念有稳定、可读的释义；
///   2. 字典没有时，只在正文里找真正以该术语为主语的完整定义句；
///   3. 两者都失败时保留原样并写入报告，绝不编造解释。
///
/// 用法：
///   dart tool/rewrite_glossary_rows.dart --dry-run   # 只报告，不写文件
///   dart tool/rewrite_glossary_rows.dart             # 实际改写
const String _glossaryHeader = '| 术语 | 一句话说明 |';

/// 命中任意一条即视为需要改写的坏说明。
const List<String> badGlossaryMarkers = <String>[
  'focuses on',
  'Related terms:',
  '它在「',
  '复习时回到正文',
  '检查调用链、输入数据和环境配置',
  '下列哪两项是本课强调',
  '本课属于「',
];

/// 说明长度上限（去空白后的字符数）。
const int maxDefinitionLength = 96;

/// 这些章节里的句子不能作为术语说明：它们要么在讲故障排查，
/// 要么直接来自题目解析，取出来会把模板话术重新带回术语表。
const List<String> blockedSectionMarkers = <String>[
  '考点精讲',
  '常见错误',
  '故障',
  '练习',
  '测验',
  '自测',
  '参考答案',
  '参考解析',
  '题目',
  '复习清单',
  '内容复核',
  '参考资料',
  '术语速查',
];

/// 命中这些片段的句子一律丢弃：它们是生成器模板或题目话术。
const List<String> blockedSentenceMarkers = <String>[
  '症状：',
  '本课的',
  '本课关键词',
  '常规用例',
  '边界用例',
  '两次运行',
  '检查调用链',
  '自动化用例',
  '下列',
  '选项',
  '题干',
  '判断依据',
  '正确答案',
  '"type"',
  '本课练习重点',
  '关键做法：',
  '验证标准：',
  '落地检查：',
  '正文依据：',
  '第一周',
  '第二周',
  '第三周',
  '第四周',
];

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final contentDir = Directory('assets/content');
  if (!contentDir.existsSync()) {
    stderr.writeln('找不到 assets/content 目录，请在项目根目录运行。');
    exitCode = 1;
    return;
  }

  final files =
      contentDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.md'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  var glossaryFiles = 0;
  var candidateRows = 0;
  var rewrittenRows = 0;
  var fallbackRows = 0;
  final fallbacks = <String>[];
  final samples = <String>[];

  for (final file in files) {
    final lines = file.readAsLinesSync();
    final headerIndex = lines.indexWhere(
      (line) => line.trim() == _glossaryHeader,
    );
    if (headerIndex < 0) continue;
    glossaryFiles++;

    // 术语表之前的正文才是提炼来源，避免把表格自身当成依据。
    final body = lines.sublist(0, headerIndex).join('\n');
    var changed = false;

    for (var i = headerIndex + 2; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (!trimmed.startsWith('|')) break;

      final match = RegExp(r'^\|\s*`([^`]+)`\s*\|\s*(.*?)\s*\|\s*$')
          .firstMatch(line);
      if (match == null) continue;
      final term = match.group(1)!.trim();
      final description = match.group(2)!.trim();
      if (!needsRewrite(description)) continue;

      candidateRows++;
      final definition = buildDefinition(
        term,
        body,
        lessonId: _fileName(file.path).replaceAll('.md', ''),
      );
      if (definition == null) {
        fallbackRows++;
        fallbacks.add('${file.path} :: $term');
        continue;
      }
      final next = '| `$term` | $definition |';
      if (samples.length < 12) {
        samples.add(
          '${_fileName(file.path)} :: $term\n  旧: ${_clip(description)}\n  新: $definition',
        );
      }
      if (next != line) {
        lines[i] = next;
        changed = true;
      }
      rewrittenRows++;
    }

    if (changed && !dryRun) {
      file.writeAsStringSync('${lines.join('\n')}\n');
    }
  }

  stdout.writeln('模式        ${dryRun ? 'dry-run（不写文件）' : '改写'}');
  stdout.writeln('含术语表文件 $glossaryFiles');
  stdout.writeln('待改写行数   $candidateRows');
  stdout.writeln('已生成说明   $rewrittenRows');
  stdout.writeln('无法提炼     $fallbackRows');
  stdout.writeln('');
  stdout.writeln('--- 抽样 ---');
  for (final sample in samples) {
    stdout.writeln(sample);
    stdout.writeln('');
  }
  if (fallbacks.isNotEmpty) {
    stdout.writeln('--- 无法自动提炼（保留原样，需人工处理） ---');
    for (final item in fallbacks.take(40)) {
      stdout.writeln(item);
    }
    if (fallbacks.length > 40) {
      stdout.writeln('…… 其余 ${fallbacks.length - 40} 条省略');
    }
    final reportDir = Directory('tool/reports');
    if (!reportDir.existsSync()) reportDir.createSync(recursive: true);
    File('tool/reports/glossary_rewrite_fallbacks.txt')
        .writeAsStringSync('${fallbacks.join('\n')}\n');
    stdout.writeln('完整清单已写入 tool/reports/glossary_rewrite_fallbacks.txt');
  }
}

bool needsRewrite(String description) {
  for (final marker in badGlossaryMarkers) {
    if (description.contains(marker)) return true;
  }
  return false;
}

/// 从正文提炼术语说明：先查人工字典，再找同名小节或定义句。
String? buildDefinition(String term, String body, {String? lessonId}) {
  final normalizedTerm = term.trim();
  if (normalizedTerm.isEmpty) return null;
  final lessonKey = lessonId == null ? '' : '$lessonId::$normalizedTerm';
  final curated =
      glossaryDefinitionsByLesson[lessonKey] ??
      glossaryDefinitions[normalizedTerm] ??
      glossaryDefinitionsExtended[normalizedTerm];
  if (curated != null && curated.trim().isNotEmpty) {
    return clipDefinition(curated);
  }
  return _fromSection(normalizedTerm, body) ??
      _fromSentence(normalizedTerm, body);
}

/// 找标题包含术语的小节，取小节里第一段有信息量的正文。
String? _fromSection(String term, String body) {
  for (final section in extractableSections(body)) {
    if (!section.title.contains(term)) continue;
    for (final rawLine in section.lines) {
      final text = cleanMarkdownLine(rawLine);
      if (text == null) continue;
      if (text.length < 12) continue;
      if (isBlockedSentence(text)) continue;
      final cleaned = stripLeadingBoilerplate(text);
      if (cleaned.length < 12) continue;
      if (looksLikeCodeFragment(cleaned)) continue;
      final exactTitle = section.title.trim() == term;
      if (!exactTitle && !looksDefinitional(cleaned, term)) continue;
      return clipDefinition(cleaned);
    }
  }
  return null;
}

/// 在正文里找第一句包含术语、且像定义或说明的完整句子。
String? _fromSentence(String term, String body) {
  final sentences = <String>[];
  for (final section in extractableSections(body)) {
    for (final rawLine in section.lines) {
      final text = cleanMarkdownLine(rawLine);
      if (text == null || text.length < 12) continue;
      sentences.addAll(
        text
            .split(RegExp(r'(?<=[。！？；])'))
            .map((sentence) => stripLeadingBoilerplate(sentence.trim()))
            .where((sentence) => sentence.isNotEmpty),
      );
    }
  }

  for (final sentence in sentences) {
    if (!sentence.contains(term)) continue;
    if (sentence.length < 16) continue;
    if (sentence.length > 220) continue;
    if (RegExp(r'\d+\s*[.)、]\s*\S').hasMatch(sentence)) continue;
    if (isBlockedSentence(sentence)) continue;
    if (looksLikeCodeFragment(sentence)) continue;
    if (_looksLikeTemplateSentence(sentence)) continue;
    if (looksDefinitional(sentence, term)) return clipDefinition(sentence);
  }
  return null;
}

/// 把正文按标题拆成小节，并过滤掉不适合作为说明来源的章节。
List<({String title, List<String> lines})> extractableSections(String body) {
  final sections = <({String title, List<String> lines})>[];
  var title = '';
  var lines = <String>[];

  void flush() {
    if (lines.isEmpty && title.isEmpty) return;
    sections.add((title: title, lines: lines));
    lines = <String>[];
  }

  for (final rawLine in body.split('\n')) {
    final trimmed = rawLine.trim();
    if (trimmed.startsWith('#')) {
      flush();
      title = trimmed
          .replaceFirst(RegExp(r'^#+\s*'), '')
          .replaceAll('*', '')
          .replaceAll('`', '')
          .trim();
      continue;
    }
    lines.add(rawLine);
  }
  flush();

  return sections
      .where(
        (section) => !blockedSectionMarkers.any(
          (marker) => section.title.contains(marker),
        ),
      )
      .toList();
}

bool isBlockedSentence(String sentence) {
  for (final marker in blockedSentenceMarkers) {
    if (sentence.contains(marker)) return true;
  }
  return false;
}

/// 学习目标类句子以「能用自己的话解释：」开头，去掉前缀后仍是好说明。
String stripLeadingBoilerplate(String sentence) {
  var value = sentence.trim();
  for (final prefix in <String>[
    '能用自己的话解释：',
    '能用自己的话解释',
    '能说明：',
    '能说出：',
    '能说清：',
    '能说清',
    '能区分：',
    '能对比：',
    '能复述：',
    '理解：',
  ]) {
    if (value.startsWith(prefix)) {
      value = value.substring(prefix.length).trim();
      break;
    }
  }
  return value;
}

/// 定义性判断：术语后面紧跟解释性谓语，或术语出现在句子话题位置。
bool looksDefinitional(String sentence, String term) {
  final index = sentence.indexOf(term);
  if (index < 0) return false;
  // 定义句里术语应当出现在话题位置。术语埋在长句中段时，抽取到的通常
  // 是操作步骤、示例或故障描述，不能冒充一句话说明。
  if (index > 8) return false;
  final after = sentence.substring(index + term.length);
  if (RegExp(r'^\s*(是|指|表示|意味|用于|负责|通过|可以|会|需要|把|让|使)').hasMatch(after)) {
    return true;
  }
  // 术语后直接跟等号 / 冒号，说明这句话在定义它。
  if (RegExp(r'^\s*[=＝：:]').hasMatch(after)) return true;
  // 句子以术语开头时，后面必须以冒号、等号或「是/指」类谓语继续说明；
  // 仅有示例或动作列表不算定义。
  if (index == 0 && RegExp(r'^[：:=＝]\s*\S').hasMatch(after)) return true;
  return false;
}

bool _looksLikeTemplateSentence(String sentence) {
  final value = sentence.trim();
  if (RegExp(r'^(坏轨迹|示例|例如|步骤如下|操作步骤|流程是|常见做法)').hasMatch(value)) {
    return true;
  }
  if (value.contains('例如') || value.contains('比如')) return true;
  if (RegExp(r'^(先用|再|然后|最后|同时盯|需要|要)').hasMatch(value)) {
    return true;
  }
  // 以动词开头、没有定义性谓语的句子通常是步骤或建议。
  if (RegExp(r'^(把|用|从|为|给|让|将|先|在|对|围绕|通过)\S*').hasMatch(value)) {
    return true;
  }
  return false;
}

/// JSON、命令行等代码片段不适合作为一句话说明。
bool looksLikeCodeFragment(String sentence) {
  final value = sentence.trim();
  if (value.startsWith('{') ||
      value.startsWith('[') ||
      value.startsWith('"') ||
      value.startsWith('<')) {
    return true;
  }
  if (value.contains('->')) return true;
  if (value.contains('→')) return true;
  // 以标点开头说明句子被截断过，不完整。
  if (RegExp(r'^[、，。；：）」]').hasMatch(value)) return true;
  // 「由 N 部分组成」这类句子没有真正解释术语。
  if (RegExp(r'由[一二三四五六七八九十两0-9]+部分组成').hasMatch(value)) {
    return true;
  }
  final codeChars = RegExp(r'[{}<>]').allMatches(value).length;
  if (codeChars >= 2 && value.length < 60) return true;
  return false;
}

/// 清理 markdown 行；返回 null 表示这行不适合作为说明来源。
String? cleanMarkdownLine(String raw) {
  var line = raw.trim();
  if (line.isEmpty) return null;
  if (line.startsWith('#')) return null;
  if (line.startsWith('|')) return null;
  if (line.startsWith('```')) return null;
  if (line.startsWith('![')) return null;
  if (line.startsWith('<')) return null;
  if (RegExp(r'^-{3,}$').hasMatch(line)) return null;
  if (line.startsWith('> 内容更新时间')) return null;
  if (line.startsWith('> 一句话摘要')) return null;

  line = line.replaceFirst(RegExp(r'^(>\s*|[-*+]\s+|\d+[.)、]\s+)'), '');
  line = line.replaceAllMapped(
    RegExp(r'\[([^\]]*)\]\([^)]*\)'),
    (match) => match.group(1) ?? '',
  );
  line = line.replaceAll('**', '').replaceAll('`', '');
  line = line.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (line.isEmpty) return null;
  return line;
}

/// 截断到合适长度，尽量在句末标点处收尾。
String clipDefinition(String text) {
  var value = text.trim();
  if (value.length > maxDefinitionLength) {
    final window = value.substring(0, maxDefinitionLength);
    final cut = _lastSentenceBreak(window);
    value = cut > 24 ? window.substring(0, cut) : window;
  }
  value = value.replaceFirst(RegExp(r'[。；;，,、:：]+$'), '');
  if (!value.endsWith('。') && !value.endsWith('！') && !value.endsWith('？')) {
    value = '$value。';
  }
  return value;
}

int _lastSentenceBreak(String value) {
  var index = -1;
  for (final marker in <String>['。', '；', '！', '？']) {
    final found = value.lastIndexOf(marker);
    if (found > index) index = found;
  }
  return index < 0 ? -1 : index + 1;
}

String _clip(String value) =>
    value.length <= 80 ? value : '${value.substring(0, 80)}……';

String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;
