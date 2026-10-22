// P0/P1 结构治理：修复跨课程可见的 Markdown 结构缺陷。
//
// 处理对象：
//   1. 术语表残留 `[a, b][index]` 模板占位符；
//   2. 术语表「本课围绕该主题展开」套话；
//   3. 同一张术语表里重复行超出安全上限的部分；
//   4. `- **X**：X` 这种要点自我重复；
//   5. 有序列表从中间开始编号。
//
// 用法：
//   dart tool/repair_content_structure.dart [--apply] [--lesson=id]
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String genericTermGloss = '本课围绕该主题展开，结合正文与代码示例理解它的适用边界。';
const int maxRowsPerTermTable = 6;
const int minGlossLength = 18;
const int maxGlossLength = 120;

void main(List<String> args) {
  final apply = args.contains('--apply');
  final onlyLesson = _stringOption(args, '--lesson=');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final stats = <String, int>{};
  var lessonsTouched = 0;
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      if (onlyLesson != null && onlyLesson != id) continue;
      final file = File(lesson['file'].toString());
      if (!file.existsSync()) continue;
      final markdown = file.readAsStringSync();
      final keywords = ((lesson['keywords'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
      final title = ((lesson['title'] as Map?)?['zh'] ?? id).toString().trim();
      final result = _repair(markdown, title, keywords, stats);
      if (result != markdown) {
        lessonsTouched++;
        if (apply) file.writeAsStringSync(result);
      }
    }
  }
  final ordered = stats.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  stdout.writeln(apply ? '=== 已写回结构修复 ===' : '=== 试运行（未写文件）===');
  stdout.writeln('涉及课程  $lessonsTouched');
  for (final entry in ordered) {
    stdout.writeln('${entry.key.padRight(16)} ${entry.value}');
  }
}

String _repair(
  String markdown,
  String title,
  List<String> keywords,
  Map<String, int> stats,
) {
  var lines = markdown.split('\n');
  lines = _repairOrderedLists(lines, title, stats);
  lines = _repairSelfRepeatingBullets(lines, title, stats);
  lines = _repairTermTables(lines, title, keywords, markdown, stats);
  return lines.join('\n');
}

List<String> _repairSelfRepeatingBullets(
  List<String> lines,
  String title,
  Map<String, int> stats,
) {
  final output = <String>[];
  var inFence = false;
  for (final line in lines) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      output.add(line);
      continue;
    }
    if (inFence) {
      output.add(line);
      continue;
    }
    final match = RegExp(r'^(\s*-\s+\*\*(.+?)\*\*\s*[：:]\s*)(.+)$')
        .firstMatch(line);
    if (match == null) {
      output.add(line);
      continue;
    }
    final head = match.group(2)!;
    final tail = match.group(3)!;
    if (_normalize(head) == _normalize(tail)) {
      stats.update('要点自我重复', (v) => v + 1, ifAbsent: () => 1);
      final question = RegExp(r'^考点\s*\d+[：:]\s*(.+?)[？?]?$').firstMatch(head);
      if (question != null) {
        output.add(
          '${match.group(1)}针对「$title」，先自问「${question.group(1)}」；'
          '作答后回到对应考点核对判断依据。',
        );
      } else {
        output.add(
          '${match.group(1)}在「$title」里，「$head」这一步要先写清输入与预期，'
          '再记录实际结果和差异；结果不符时回到对应小节核对前提。',
        );
      }
      continue;
    }
    output.add(line);
  }
  return output;
}

List<String> _repairOrderedLists(
  List<String> lines,
  String title,
  Map<String, int> stats,
) {
  final output = <String>[];
  var inFence = false;
  final numberedPattern = RegExp(r'^(\d+)\.\s+');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      output.add(line);
      continue;
    }
    if (inFence) {
      output.add(line);
      continue;
    }
    final match = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);
    if (match == null) {
      output.add(line);
      continue;
    }
    // 收集同一段连续编号块（允许块内空行），只有整块从 >=2 开始且有 2 项以上时才重排。
    final block = <int>[i];
    var j = i + 1;
    while (j < lines.length) {
      if (numberedPattern.hasMatch(lines[j])) {
        block.add(j);
        j++;
        continue;
      }
      if (lines[j].trim().isEmpty) {
        var k = j;
        while (k < lines.length && lines[k].trim().isEmpty) {
          k++;
        }
        if (k < lines.length && numberedPattern.hasMatch(lines[k])) {
          j = k;
          continue;
        }
      }
      break;
    }
    final firstNumber = int.parse(numberedPattern.firstMatch(line)!.group(1)!);
    // 题干和解析里的编号是题目序号，不是 Markdown 列表，保持原样。
    final inQuizSection = _quizHeadingPattern.hasMatch(
      _latestHeading(lines, i),
    );
    final renumber = !inQuizSection && firstNumber > 1 && block.length >= 2;
    var next = 1;
    if (renumber) {
      // 旧生成器删掉了列表首项，这里按课程语义补回“先澄清输入与目标”。
      output.add('1. 澄清输入与目标。先写清「$title」要解决的问题、合法输入范围和成功标准，再进入后续步骤。');
      stats.update('补齐列表首项', (v) => v + 1, ifAbsent: () => 1);
      next = 2;
    }
    for (final index in block) {
      final itemMatch = numberedPattern.firstMatch(lines[index])!;
      final rest = lines[index].substring(itemMatch.end);
      if (renumber) {
        output.add('$next. $rest');
        stats.update('有序列表重排', (v) => v + 1, ifAbsent: () => 1);
      } else {
        output.add(lines[index]);
      }
      next++;
    }
    i = j - 1;
  }
  return output;
}

final RegExp _quizHeadingPattern = RegExp(r'考点|自测|测验|检查点|参考判断|易错');

String _latestHeading(List<String> lines, int index) {
  for (var i = index; i >= 0; i--) {
    if (lines[i].startsWith('#')) return lines[i];
  }
  return '';
}

List<String> _repairTermTables(
  List<String> lines,
  String title,
  List<String> keywords,
  String markdown,
  Map<String, int> stats,
) {
  final output = <String>[];
  var inFence = false;
  var inTermTable = false;
  var rowsWritten = 0;
  final seenTerms = <String>{};
  for (final line in lines) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      output.add(line);
      continue;
    }
    if (inFence) {
      output.add(line);
      continue;
    }
    if (line.startsWith('## 术语速查')) {
      inTermTable = true;
      rowsWritten = 0;
      seenTerms.clear();
      output.add(line);
      continue;
    }
    if (inTermTable && line.startsWith('## ')) {
      inTermTable = false;
    }
    if (!inTermTable || !line.startsWith('| `')) {
      output.add(line);
      continue;
    }
    final match = RegExp(r'^\|\s*`(.+?)`\s*\|\s*(.*?)\s*\|\s*$')
        .firstMatch(line);
    if (match == null) {
      output.add(line);
      continue;
    }
    final term = match.group(1)!.trim();
    var gloss = match.group(2)!.trim();
    final placeholder = RegExp(r'^\[(.+?)\]\[index\]$').firstMatch(term);
    if (placeholder != null) {
      stats.update('未解析模板占位符', (v) => v + 1, ifAbsent: () => 1);
      final candidates =
          <String>[
                title,
                ...keywords,
                ...placeholder.group(1)!.split(RegExp(r'[,，、]')),
              ]
              .map((item) => item.trim())
              .where(
                (item) =>
                    item.isNotEmpty &&
                    item != title &&
                    item.length <= 20 &&
                    !item.contains('index'),
              )
              .toList();
      final clean = _unique(candidates).take(maxRowsPerTermTable).toList();
      for (final keyword in clean) {
        if (rowsWritten >= maxRowsPerTermTable) break;
        if (!seenTerms.add(keyword)) continue;
        output.add(
          '| `$keyword` | ${_termGloss(keyword, keywords, title, markdown)} |',
        );
        rowsWritten++;
      }
      continue;
    }
    if (gloss == genericTermGloss) {
      stats.update('术语表套话', (v) => v + 1, ifAbsent: () => 1);
      gloss = _termGloss(term, keywords, title, markdown);
    }
    if (!seenTerms.add(term)) {
      stats.update('术语表重复行', (v) => v + 1, ifAbsent: () => 1);
      continue;
    }
    if (rowsWritten >= maxRowsPerTermTable) {
      stats.update('术语表超长', (v) => v + 1, ifAbsent: () => 1);
      continue;
    }
    output.add('| `$term` | $gloss |');
    rowsWritten++;
  }
  return output;
}

String _termGloss(
  String term,
  List<String> keywords,
  String title,
  String markdown,
) {
  var role = term.trim();
  if (role.length > 16) role = title;
  final derived = _findDefinitionSentence(markdown, role);
  if (derived != null) return derived;
  final related = keywords
      .where(
        (item) =>
            item != role &&
            !role.contains(item) &&
            item.length >= 2 &&
            item.length <= 12,
      )
      .take(2)
      .toList();
  final relation = related.isEmpty ? '' : '；它与${related.join('、')}共同决定这一节的判断边界';
  return '它在「$title」里是理解「$role」的关键术语，用来解释定义、适用条件与失败路径$relation。复习时回到正文示例核对输入、输出和验证方式。';
}

/// 从正文里挑一条真正提到该术语的完整句子，优先于兜底模板。
String? _findDefinitionSentence(String markdown, String term) {
  final normalizedTerm = _normalizeTerm(term);
  if (normalizedTerm.length < 2) return null;
  final best = <String>[];
  var inFence = false;
  var className = '';
  for (final raw in markdown.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence || line.isEmpty) continue;
    if (line.startsWith('#')) {
      className = line.replaceFirst(RegExp(r'^#+\s*'), '');
      continue;
    }
    if (line.startsWith('|') || line.startsWith('>') || line.startsWith('![')) {
      continue;
    }
    if (className.contains('术语') ||
        className.contains('考点') ||
        className.contains('参考') ||
        className.contains('元数据') ||
        className.contains('复核') ||
        className.contains('复习清单')) {
      continue;
    }
    final cleaned = line
        .replaceFirst(RegExp(r'^[-*+\d.\s]+'), '')
        .replaceAll(RegExp(r'[*_`]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length < 24 || cleaned.length > maxGlossLength) continue;
    final normalizedLine = _normalizeTerm(cleaned).toLowerCase();
    final needle = normalizedTerm.toLowerCase();
    if (!normalizedLine.contains(needle)) continue;
    if (cleaned.contains('本课围绕该主题展开') ||
        cleaned.contains('][index]') ||
        cleaned.contains('题干的正确项是') ||
        cleaned.contains('这道题') ||
        cleaned.contains('能用自己的话解释') ||
        cleaned.contains('能说清') ||
        cleaned.contains('Key terms') ||
        cleaned.contains('本课的摘要可以当作') ||
        cleaned.contains('自问')) {
      continue;
    }
    final first = _stripScaffoldPrefix(
      cleaned.split(RegExp(r'[。！？!?]')).first.trim(),
    );
    if (first.length < minGlossLength || first.length > maxGlossLength) {
      continue;
    }
    if (!_containsTerm(_normalizeTerm(first).toLowerCase(), needle)) continue;
    if (!_hasTermBoundary(normalizedLine, needle)) continue;
    best.add('$first。');
  }
  if (best.isEmpty) return null;
  best.sort((a, b) => b.length.compareTo(a.length));
  return best.first;
}

const List<String> scaffoldPrefixes = <String>[
  '定位：',
  '要点：',
  '正文依据：',
  '落地检查：',
  '自检：',
  '主干：',
  '连接线：',
  '围绕',
  '关于',
];

String _stripScaffoldPrefix(String value) {
  var result = value;
  for (final prefix in scaffoldPrefixes) {
    if (result.startsWith(prefix)) {
      result = result.substring(prefix.length).trim();
      break;
    }
  }
  return result;
}

bool _containsTerm(String text, String needle) => text.contains(needle);

/// 防止「Flutter」命中「Flutter 状态管理」这类同前缀的长术语。
bool _hasTermBoundary(String text, String needle) {
  var start = text.indexOf(needle);
  while (start >= 0) {
    final before = start == 0 ? '' : text[start - 1];
    final afterIndex = start + needle.length;
    final after = afterIndex >= text.length ? '' : text[afterIndex];
    final beforeBoundary = before.isEmpty || _isBoundaryCharacter(before);
    final afterBoundary = after.isEmpty || _isBoundaryCharacter(after);
    if (beforeBoundary && afterBoundary) return true;
    start = text.indexOf(needle, start + 1);
  }
  return false;
}

bool _isBoundaryCharacter(String value) {
  return RegExp(r'[^\p{L}\p{N}]', unicode: true).hasMatch(value);
}

String _normalizeTerm(String value) {
  return value
      .replaceAll(RegExp(r'[`*_\[\]]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<String> _unique(List<String> values) {
  final seen = <String>{};
  final output = <String>[];
  for (final value in values) {
    if (seen.add(value)) output.add(value);
  }
  return output;
}

String _normalize(String value) {
  return value
      .replaceAll(RegExp(r'[。；，、：:！？!?\s]'), '')
      .replaceAll(RegExp(r'^[-*+\d.\s]+'), '')
      .trim();
}

String? _stringOption(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}
