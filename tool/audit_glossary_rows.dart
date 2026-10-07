// 术语速查行体检工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart run tool/audit_glossary_rows.dart                     # 打印摘要
//   dart run tool/audit_glossary_rows.dart --fail-on-findings  # 有发现时退出码 1
//
// 背景：术语速查要求「术语 + 中文一句话说明」。历史批量工具在补行数时
// 混进过四类脏数据：
//   1. 任务/步骤标题当术语（`任务 1：先跑通，再解释`）；
//   2. 说明是代码行（`def permute(nums)。`、`n = len(nums)。`）；
//   3. 说明是英文摘要（`Summary: Cover navigation ...`）；
//   4. 说明是模板句（`复述当前方案对「SJF」的假设……`）。
// 这里逐课扫描，输出报告与人工修复清单，供后续批次逐条改写。
import 'dart:convert';
import 'dart:io';

const String contentDir = 'assets/content';
const String reportPath = 'tool/reports/glossary_rows_report.json';
const String backlogPath = 'docs/glossary_review_backlog.md';

/// 术语列如果是「任务/步骤/实验」这类小节标题，就不是术语。
final RegExp taskTermPattern = RegExp(
  r'^(任务|步骤|实验|阶段|第[一二三四五六七八九十\d]+步)\s*[一二三四五六七八九十\d]*\s*[:：]',
);

/// 说明列的模板句特征：出现任意一条即视为占位文本。
const List<String> templateMarkers = <String>[
  '复述当前方案对',
  '最小示例复制一份',
  '保持输出格式与任务',
  '用同一套思路处理一组你自己的数据',
  '输入与产出：先写清本步',
  '验收标准：至少有一个可复现',
  '不看书，用一张图说清',
  '两个方案的差异必须落在',
  '先用最小输入和明确验收标准',
  '用一句话说明「',
];

/// 明显是代码的起始标记（即使夹着中文注释也按代码处理）。
final RegExp strongCodePattern = RegExp(r'^(//|/\*|\$ |> |>>> )');

final RegExp hanPattern = RegExp(r'[\u4e00-\u9fff]');
final RegExp codeShapePattern = RegExp(
  r'^(from|import|def|class|const|let|var|function|return|SELECT|INSERT|'
  r'UPDATE|DELETE|CREATE|git|kubectl|docker|npm|pip|cargo|dotnet|go|fn|use|'
  r'pub|struct|impl|for|while|if|echo|export|printf|awk|sed)\b|'
  r'^[\w\.\(\)\[\]\{\}\s,;:=\+\-*/%<>]+[;{]$',
);

class GlossaryRow {
  const GlossaryRow({
    required this.lessonId,
    required this.file,
    required this.line,
    required this.term,
    required this.description,
  });

  final String lessonId;
  final String file;
  final int line;
  final String term;
  final String description;

  /// 返回问题类型；null 表示这一行是合格的「术语 + 中文说明」。
  String? get finding {
    if (taskTermPattern.hasMatch(term)) return 'task_term';
    if (description.toLowerCase().startsWith('summary:')) {
      return 'english_summary';
    }
    if (templateMarkers.any(description.contains)) return 'template_desc';
    if (strongCodePattern.hasMatch(description)) return 'code_desc';
    if (!hanPattern.hasMatch(description) &&
        codeShapePattern.hasMatch(description)) {
      return 'code_desc';
    }
    return null;
  }
}

Future<void> main(List<String> args) async {
  final failOnFindings = args.contains('--fail-on-findings');
  final rows = <GlossaryRow>[];
  final files = Directory(contentDir)
      .listSync()
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.md'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final lines = await file.readAsLines();
    final lessonId = file.uri.pathSegments.last.replaceAll('.md', '');
    var inGlossary = false;
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (line.startsWith('## ')) {
        inGlossary = line.trimRight() == '## 术语速查';
        continue;
      }
      if (!inGlossary || !line.startsWith('|')) continue;
      final cells = line
          .split('|')
          .map((cell) => cell.trim())
          .where((cell) => cell.isNotEmpty)
          .toList();
      if (cells.length < 2) continue;
      final term = cells[0].replaceAll('`', '').trim();
      final description = cells[1];
      if (term == '术语' || RegExp(r'^-+$').hasMatch(term)) continue;
      rows.add(
        GlossaryRow(
          lessonId: lessonId,
          file: file.path.replaceAll('\\', '/'),
          line: index + 1,
          term: term,
          description: description,
        ),
      );
    }
  }

  final findings = <Map<String, Object>>[];
  final byKind = <String, int>{};
  final lessons = <String, List<GlossaryRow>>{};
  for (final row in rows) {
    lessons.putIfAbsent(row.lessonId, () => <GlossaryRow>[]).add(row);
    final kind = row.finding;
    if (kind == null) continue;
    byKind[kind] = (byKind[kind] ?? 0) + 1;
    findings.add(<String, Object>{
      'lesson': row.lessonId,
      'file': row.file,
      'line': row.line,
      'term': row.term,
      'kind': kind,
      'description': row.description,
    });
  }

  final affected = lessons.entries
      .where((entry) => entry.value.any((row) => row.finding != null))
      .map((entry) {
        final lessonRows = entry.value;
        final bad = lessonRows.where((row) => row.finding != null).toList();
        return <String, Object>{
          'lesson': entry.key,
          'rows': lessonRows.length,
          'findings': bad.length,
          'valid_rows': lessonRows.length - bad.length,
          'samples': bad
              .take(3)
              .map((row) => '${row.term}（${row.finding}）')
              .toList(),
        };
      })
      .toList()
    ..sort((a, b) {
      final byCount = (b['findings'] as int).compareTo(a['findings'] as int);
      if (byCount != 0) return byCount;
      return (a['lesson'] as String).compareTo(b['lesson'] as String);
    });

  final report = <String, Object>{
    'generated_at': DateTime.now().toIso8601String(),
    'lesson_count': files.length,
    'glossary_row_count': rows.length,
    'finding_count': findings.length,
    'findings_by_kind': byKind,
    'affected_lesson_count': affected.length,
    'lessons': affected,
    'findings': findings,
  };
  await File(reportPath).writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  await File(backlogPath).writeAsString(_backlogMarkdown(report));

  stdout.writeln('术语速查行：${rows.length} 行，其中待修 ${findings.length} 行');
  for (final entry in byKind.entries) {
    stdout.writeln('  ${entry.key}: ${entry.value}');
  }
  stdout.writeln('涉及课程：${affected.length} / ${files.length}');
  stdout.writeln('报告：$reportPath');
  stdout.writeln('待修清单：$backlogPath');
  if (failOnFindings && findings.isNotEmpty) exitCode = 1;
}

String _backlogMarkdown(Map<String, Object> report) {
  final buffer = StringBuffer()
    ..writeln('# 术语速查待修清单')
    ..writeln()
    ..writeln('生成时间：${report['generated_at']}')
    ..writeln()
    ..writeln(
      '全库术语速查共 ${report['glossary_row_count']} 行，'
      '其中 ${report['finding_count']} 行需要改写，'
      '涉及 ${report['affected_lesson_count']} 门课。',
    )
    ..writeln()
    ..writeln('问题类型：')
    ..writeln();
  final kinds = report['findings_by_kind'] as Map<String, int>;
  const kindNotes = <String, String>{
    'task_term': '任务/步骤标题被当成术语：删掉该行，必要时补一条真术语。',
    'code_desc': '说明是代码行：改写成中文一句话定义。',
    'english_summary': '说明是英文摘要（Summary: ...）：改写成中文一句话定义。',
    'template_desc': '说明是模板句：改写成该术语的中文一句话定义。',
  };
  for (final entry in kinds.entries) {
    buffer.writeln(
      '- ${entry.key}（${entry.value}）：${kindNotes[entry.key] ?? '需要改写'}',
    );
  }
  buffer
    ..writeln()
    ..writeln('| 课程 | 待修 | 合格 | 示例 |')
    ..writeln('| --- | ---: | ---: | --- |');
  for (final lesson in (report['lessons'] as List<dynamic>)) {
    final map = lesson as Map<String, dynamic>;
    final samples = (map['samples'] as List<dynamic>).join('；');
    buffer.writeln(
      '| `${map['lesson']}` | ${map['findings']} | ${map['valid_rows']} | $samples |',
    );
  }
  return buffer.toString();
}
