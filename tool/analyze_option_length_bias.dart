// P1-6 度量：单选题「最长项即答案」偏置的结构化拆解。
//
// 用法：
//   dart tool/analyze_option_length_bias.dart
//
// 输出：
//   · 正确项与「最长干扰项」的长度差分布；
//   · 正确项结尾标点/子句数量/尾部括号的构成；
//   · gap >= 5 的子集里，各类自动修复策略分别能覆盖多少题（只预估，不写文件）。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

/// 按子句边界切分，括号内不切。
List<String> splitClauses(String text) {
  final parts = <String>[];
  final buffer = StringBuffer();
  var depth = 0;
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    if (ch == '(' || ch == '（') depth++;
    if (ch == ')' || ch == '）') depth = depth > 0 ? depth - 1 : 0;
    if (depth == 0 && (ch == '，' || ch == '；' || ch == '、')) {
      parts.add(buffer.toString());
      buffer.clear();
      continue;
    }
    buffer.write(ch);
  }
  if (buffer.isNotEmpty) parts.add(buffer.toString());
  return parts;
}

/// 干扰项是否「像一句完整的话」，可以安全续写限定子句。
bool canAppendClause(String text) {
  final trimmed = text.trim();
  if (trimmed.length < 6) return false;
  if (trimmed.startsWith('.') || trimmed.startsWith('/')) return false;
  if (RegExp(r'^[A-Za-z_][A-Za-z0-9_./{}\s]*$').hasMatch(trimmed)) return false;
  final cjk = RegExp(r'[\u4e00-\u9fff]').allMatches(trimmed).length;
  if (cjk < 4) return false;
  if (trimmed.endsWith('。') ||
      trimmed.endsWith('；') ||
      trimmed.endsWith('，')) {
    return false;
  }
  return true;
}

class BiasCase {
  BiasCase({
    required this.lessonId,
    required this.question,
    required this.options,
    required this.answer,
  });

  final String lessonId;
  final String question;
  final List<String> options;
  final int answer;

  String get correct => options[answer].trim();

  String get longestDistractor {
    var best = '';
    for (var i = 0; i < options.length; i++) {
      if (i == answer) continue;
      final text = options[i].trim();
      if (text.length > best.length) best = text;
    }
    return best;
  }

  int get longestOther => longestDistractor.length;

  int get gap => correct.length - longestOther;
}

void main() {
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final cases = <BiasCase>[];
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    for (final rawLesson
        in (rawCategory as Map)['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      for (final rawQuestion
          in (lesson['quiz'] as List<dynamic>? ?? const [])) {
        final q = (rawQuestion as Map).cast<String, dynamic>();
        if (((q['type'] as String?) ?? 'single') != 'single') continue;
        final options = ((q['options'] as List<dynamic>?) ?? const <dynamic>[])
            .cast<String>();
        final answer = (q['answer'] as num?)?.toInt() ?? 0;
        if (options.length < 2 || answer >= options.length) continue;
        cases.add(
          BiasCase(
            lessonId: lesson['id'].toString(),
            question: (q['question'] as String?) ?? '',
            options: options,
            answer: answer,
          ),
        );
      }
    }
  }

  final singles = cases.length;
  final strict = cases.where((item) => item.gap > 0).toList();
  final gapBuckets = <String, int>{};
  final clauseBuckets = <String, int>{};
  var endsWithPeriod = 0;
  var endsWithParen = 0;
  for (final item in strict) {
    final gap = item.gap;
    final bucket = gap <= 2
        ? '1-2'
        : gap <= 4
        ? '3-4'
        : gap <= 7
        ? '5-7'
        : gap <= 15
        ? '8-15'
        : '16+';
    gapBuckets[bucket] = (gapBuckets[bucket] ?? 0) + 1;
    if (item.correct.endsWith('。')) endsWithPeriod++;
    if (RegExp(r'[（(][^（）()]{2,40}[）)]$').hasMatch(item.correct)) {
      endsWithParen++;
    }
    final count = splitClauses(item.correct).length;
    final key = count >= 4 ? '4+' : '$count';
    clauseBuckets[key] = (clauseBuckets[key] ?? 0) + 1;
  }

  stdout.writeln('单选题总数            $singles');
  stdout.writeln(
    '正确项严格最长        ${strict.length} '
    '(${(strict.length * 100 / singles).toStringAsFixed(1)}%)',
  );
  stdout.writeln('长度差分布（正确项 - 最长干扰项）');
  for (final key in const ['1-2', '3-4', '5-7', '8-15', '16+']) {
    stdout.writeln('  $key\t${gapBuckets[key] ?? 0}');
  }
  stdout.writeln('正确项结尾句号        $endsWithPeriod');
  stdout.writeln('正确项结尾括号        $endsWithParen');
  stdout.writeln('正确项子句数分布      $clauseBuckets');

  // gap >= 5 的子集：可见线索必须全部处理，先看自动策略能覆盖多少。
  final visible = strict.where((item) => item.gap >= 5).toList();
  var trimParen = 0;
  var trimClause = 0;
  var trimPunct = 0;
  var sentenceDistractor = 0;
  final needsCuration = <String>[];
  for (final item in visible) {
    final correct = item.correct;
    final paren = RegExp(r'[（(][^（）()]{2,40}[）)]$').firstMatch(correct);
    if (paren != null &&
        paren.start >= 4 &&
        correct.substring(0, paren.start).trim().length >= 4) {
      trimParen++;
      continue;
    }
    final clauses = splitClauses(correct);
    if (clauses.length > 1) {
      var length = 0;
      var hit = false;
      for (var i = 0; i < clauses.length; i++) {
        length += clauses[i].trim().length + (i == 0 ? 0 : 1);
        if (length >= 8 && length <= item.longestOther) {
          hit = true;
          break;
        }
      }
      if (hit) {
        trimClause++;
        continue;
      }
    }
    if (correct.endsWith('。') && correct.length - 1 <= item.longestOther) {
      trimPunct++;
      continue;
    }
    if (canAppendClause(item.longestDistractor)) {
      sentenceDistractor++;
      continue;
    }
    needsCuration.add(
      '${item.lessonId}｜${item.question}｜$correct｜'
      '${item.longestDistractor}',
    );
  }
  stdout.writeln('');
  stdout.writeln('=== gap >= 5 的子集（${visible.length} 题） ===');
  stdout.writeln('正确项去掉尾部括号    $trimParen');
  stdout.writeln('正确项截短尾部子句    $trimClause');
  stdout.writeln('正确项去掉句号        $trimPunct');
  stdout.writeln('干扰项补自然子句      $sentenceDistractor');
  stdout.writeln('需要人工处理          ${needsCuration.length}');
  for (final item in needsCuration) {
    stdout.writeln('  - $item');
  }
}
