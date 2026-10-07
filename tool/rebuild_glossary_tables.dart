// P0 术语表结构清理：删除伪术语与重复说明，并用本课标题、关键词和
// 三级标题补齐至少 4 条真实词条。
//
// 用法：
//   dart tool/rebuild_glossary_tables.dart --dry-run
//   dart tool/rebuild_glossary_tables.dart
import 'dart:convert';
import 'dart:io';

import 'rewrite_glossary_rows.dart';

const String manifestPath = 'assets/content/manifest.json';
const String glossaryHeader = '| 术语 | 一句话说明 |';
const String glossarySeparator = '| --- | --- |';
const int minimumGlossaryRows = 4;
const int maximumGlossaryRows = 8;

const Set<String> _allowedSpecialTerms = <String>{
  'set -e',
  '.NET',
  'B+树',
  'B+ 树',
  'C#',
  'C++',
  'Node.js',
};

/// 这两课的旧术语表全部由代码变量或片段组成，自动候选不足 4 条，
/// 这里给出按本课主题校准的最小术语集。
const Map<String, List<List<String>>> _curatedReplacementRows =
    <String, List<List<String>>>{
      'css_design_tokens': <List<String>>[
        <String>['设计令牌', '把颜色、间距、字体等设计决策命名为可复用变量的系统。'],
        <String>['原始令牌', '与业务无关的基础色阶和尺寸刻度，只描述可用的原始值。'],
        <String>['语义令牌', '表达用途的令牌，如主色或表面色，主题切换时映射到不同原始令牌。'],
        <String>['组件令牌', '只服务某个组件内部结构的变量，如按钮内边距或卡片圆角。'],
      ],
      'web_components': <List<String>>[
        <String>['Web Components', '浏览器原生提供的可复用自定义元素标准集合。'],
        <String>['Custom Elements', '定义和注册自定义 HTML 标签及其生命周期的 API。'],
        <String>['Shadow DOM', '给元素附加隔离的 DOM 与样式作用域，避免外部样式泄漏。'],
        <String>['HTML Template', '用 template 标签保存可克隆但不立即渲染的 DOM 片段。'],
      ],
    };

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final lessons = <Map<String, dynamic>>[
    for (final rawCategory in manifest['categories'] as List<dynamic>)
      for (final raw in (rawCategory as Map)['lessons'] as List<dynamic>)
        (raw as Map).cast<String, dynamic>(),
  ];

  var changedFiles = 0;
  var removedRows = 0;
  var addedRows = 0;
  var unresolved = <String>[];
  final samples = <String>[];

  for (final lesson in lessons) {
    final id = lesson['id'].toString();
    final file = File(lesson['file'].toString());
    if (!file.existsSync()) continue;
    final markdown = file.readAsStringSync();
    final result = _rebuildGlossaryTable(markdown, lesson);
    if (result == null) continue;
    removedRows += result.removedRows;
    addedRows += result.addedRows;
    if (!result.changed) continue;
    changedFiles++;
    if (samples.length < 20) {
      samples.add(
        '$id  保留=${result.keptRows} 删除=${result.removedRows} '
        '补齐=${result.addedRows}',
      );
    }
    if (result.keptRows < minimumGlossaryRows) {
      unresolved.add('$id：重建后仅 ${result.keptRows} 条');
      continue;
    }
    if (!dryRun) file.writeAsStringSync(result.markdown, flush: true);
  }

  stdout.writeln('模式        ${dryRun ? 'dry-run（不写文件）' : '重建'}');
  stdout.writeln('改动课程     $changedFiles');
  stdout.writeln('删除伪术语/重复行 $removedRows');
  stdout.writeln('补齐真实术语 $addedRows');
  stdout.writeln('无法补足 4 条 ${unresolved.length}');
  if (samples.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('--- 抽样 ---');
    for (final sample in samples) {
      stdout.writeln(sample);
    }
  }
  if (unresolved.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('--- 需人工处理 ---');
    for (final item in unresolved.take(80)) {
      stdout.writeln(item);
    }
    if (unresolved.length > 80) {
      stdout.writeln('…… 其余 ${unresolved.length - 80} 条省略');
    }
    final reportDir = Directory('tool/reports');
    if (!reportDir.existsSync()) reportDir.createSync(recursive: true);
    File('tool/reports/glossary_table_unresolved.txt')
        .writeAsStringSync('${unresolved.join('\n')}\n');
  }
  if (unresolved.isNotEmpty && !dryRun) exitCode = 1;
}

_GlossaryTableResult? _rebuildGlossaryTable(
  String markdown,
  Map<String, dynamic> lesson,
) {
  final lines = markdown.split('\n');
  final headerIndex = lines.indexWhere((line) => line.trim() == glossaryHeader);
  if (headerIndex < 0) return null;

  var tableEnd = headerIndex + 2;
  while (tableEnd < lines.length && lines[tableEnd].trim().startsWith('|')) {
    tableEnd++;
  }

  final parsed = <_GlossaryRow>[];
  for (var index = headerIndex + 2; index < tableEnd; index++) {
    final match = RegExp(r'^\|\s*`([^`]+)`\s*\|\s*(.*?)\s*\|\s*$')
        .firstMatch(lines[index]);
    if (match == null) continue;
    parsed.add(
      _GlossaryRow(
        term: match.group(1)!.trim(),
        description: match.group(2)!.trim(),
      ),
    );
  }

  final curated = _curatedReplacementRows[lesson['id'].toString()];
  if (curated != null) {
    final replacement = <String>[
      glossaryHeader,
      glossarySeparator,
      for (final row in curated) '| `${row[0]}` | ${row[1]} |',
    ];
    final output = <String>[
      ...lines.sublist(0, headerIndex),
      ...replacement,
      ...lines.sublist(tableEnd),
    ];
    final next = '${output.join('\n').trimRight()}\n';
    return _GlossaryTableResult(
      markdown: next,
      changed: next != markdown,
      keptRows: curated.length,
      removedRows: parsed.length - curated.length.clamp(0, parsed.length),
      addedRows: curated.length,
    );
  }

  final kept = <_GlossaryRow>[];
  final usedTerms = <String>{};
  final usedDescriptions = <String>{};
  for (final row in parsed) {
    if (!isCleanGlossaryTerm(row.term)) continue;
    if (!usedTerms.add(row.term)) continue;
    if (!isCleanGlossaryDescription(row.description)) continue;
    if (!usedDescriptions.add(row.description)) continue;
    kept.add(row);
  }

  final added = <_GlossaryRow>[];
  if (kept.length < minimumGlossaryRows) {
    final body = lines.sublist(0, headerIndex).join('\n');
    final candidates = <String>[
      ((lesson['title'] as Map?)?['zh'] ?? lesson['id']).toString(),
      ...((lesson['keywords'] as List?) ?? const []).map((item) => '$item'),
      ...RegExp(r'^###\s+(.+)$', multiLine: true)
          .allMatches(body)
          .map((match) => match.group(1)!.replaceAll('*', '').trim()),
    ];
    for (final candidate in candidates) {
      if (kept.length + added.length >= minimumGlossaryRows) break;
      if (!isCleanGlossaryTerm(candidate)) continue;
      if (!usedTerms.add(candidate)) continue;
      final definition = buildDefinition(
        candidate,
        body,
        lessonId: lesson['id'].toString(),
      );
      if (definition == null) continue;
      if (!usedDescriptions.add(definition)) continue;
      if (!isCleanGlossaryDescription(definition)) continue;
      added.add(_GlossaryRow(term: candidate, description: definition));
    }
  }

  final finalRows = <_GlossaryRow>[...kept, ...added];
  if (finalRows.length > maximumGlossaryRows) {
    finalRows.removeRange(maximumGlossaryRows, finalRows.length);
  }
  if (finalRows.length == parsed.length &&
      finalRows.every((row) => parsed.any((old) => old.term == row.term))) {
    return _GlossaryTableResult(
      markdown: markdown,
      changed: false,
      keptRows: finalRows.length,
      removedRows: parsed.length - finalRows.length,
      addedRows: added.length,
    );
  }

  final replacement = <String>[
    glossaryHeader,
    glossarySeparator,
    for (final row in finalRows) '| `${row.term}` | ${row.description} |',
  ];
  final output = <String>[
    ...lines.sublist(0, headerIndex),
    ...replacement,
    ...lines.sublist(tableEnd),
  ];
  return _GlossaryTableResult(
    markdown: '${output.join('\n').trimRight()}\n',
    changed: true,
    keptRows: finalRows.length,
    removedRows: parsed.length - finalRows.length,
    addedRows: added.length,
  );
}

bool isCleanGlossaryTerm(String term) {
  final value = term.trim();
  if (value.isEmpty || value.length > 40) return false;
  if (_allowedSpecialTerms.contains(value)) return true;
  if (RegExp(r'\.js\b').hasMatch(value)) return false;
  if (value.startsWith('--') || value.startsWith('-')) return false;
  if (RegExp(r'[\n\r]').hasMatch(value)) return false;
  if (RegExp(r'[\[\]{}()<>|\\/;:@?!#$%^~&]').hasMatch(value)) return false;
  if (value.contains('"') || value.contains("'")) return false;
  if (value.contains('=') || value.contains('->') || value.contains('||')) {
    return false;
  }
  if (RegExp(r'\s[-+/=]\s|==|>=|<=|&&|\+\+|--|\?\?').hasMatch(value)) {
    return false;
  }
  if (RegExp(r'^[0-9]').hasMatch(value)) return false;
  if (RegExp(r'^[,，、。；：]').hasMatch(value)) return false;
  if (value == '和' || value == '或' || value == '的') return false;
  // 保留 C# / C++ / Node.js 这类符号出现在词尾的名称，但拒绝表达式。
  if (RegExp(r'[+\-*/^]$').hasMatch(value) && !value.endsWith('+')) {
    return false;
  }
  return true;
}

bool isCleanGlossaryDescription(String description) {
  final value = description.trim();
  if (value.length < 8 || value.length > 180) return false;
  if (value.contains('。。') || value.contains('|')) return false;
  if (badGlossaryMarkers.any(value.contains)) return false;
  if (RegExp(r'(本课属于|复习时回到正文|检查调用链|常规用例|边界用例失败|先验证假设再改代码)').hasMatch(value)) {
    return false;
  }
  if (looksLikeCodeFragment(value)) return false;
  return true;
}

class _GlossaryRow {
  const _GlossaryRow({required this.term, required this.description});

  final String term;
  final String description;
}

class _GlossaryTableResult {
  const _GlossaryTableResult({
    required this.markdown,
    required this.changed,
    required this.keptRows,
    required this.removedRows,
    required this.addedRows,
  });

  final String markdown;
  final bool changed;
  final int keptRows;
  final int removedRows;
  final int addedRows;
}
