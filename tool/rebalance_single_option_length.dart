// P1-6 第 2 步：消除单选题「最长项即答案」的长度线索。
//
// 用法：
//   dart tool/rebalance_single_option_length.dart            # dry-run
//   dart tool/rebalance_single_option_length.dart --write    # 写回 manifest.json
//   dart tool/rebalance_single_option_length.dart --report   # 输出复核报告
//
// 只处理「正确项比最长干扰项长出 >= 5 字符」的题目（差值 <= 4 时人眼
// 无法当作线索，保持原样）。逐题按以下顺序尝试，保证语义不变：
//   A1 正确项尾部是补充说明括号 → 删除括号；
//   A2 正确项是「主句 + 解释子句」 → 截到仍然完整的最短前缀；
//   A3 正确项尾部是句号 → 去掉句号；
//   B  给最长的错误项补一个语气自然的限定子句（语料见
//      option_length_bias_lib.dart），长度对齐到正确项 ± 若干字符；
//   C  人工整理过的特例改写（术语/代码片段类选项，无法机械续写）。
// 解析里引用了被改写选项时同步替换；找不到安全改写方式时如实报告。
import 'dart:convert';
import 'dart:io';

import 'option_length_bias_lib.dart';
import 'option_length_curated.dart';

const String manifestPath = 'assets/content/manifest.json';
const String reportPath = 'docs/p1_6_option_length_report.md';

/// 差值小于该值时不再处理：4 个字符以内的长度差不足以构成线索。
const int visibleGap = 5;

void main(List<String> args) {
  final write = args.contains('--write');
  final emitReport = args.contains('--report');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

  var singles = 0;
  var visible = 0;
  var trimParen = 0;
  var trimClause = 0;
  var trimPeriod = 0;
  var padDistractor = 0;
  var curatedApplied = 0;
  var sweepResidual = 0;
  var untouchedSmallGap = 0;
  final unresolved = <String>[];
  final samples = <String>[];

  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    for (final rawLesson
        in (rawCategory as Map)['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final lessonId = lesson['id'].toString();
      for (final rawQuestion
          in (lesson['quiz'] as List<dynamic>? ?? const [])) {
        final question = (rawQuestion as Map).cast<String, dynamic>();
        if (((question['type'] as String?) ?? 'single') != 'single') continue;
        final options =
            ((question['options'] as List<dynamic>?) ?? const <dynamic>[])
                .cast<String>();
        final answer = (question['answer'] as num?)?.toInt() ?? 0;
        if (options.length < 2 || answer >= options.length) continue;
        singles++;

        final questionText = (question['question'] as String?) ?? '';
        final correct = options[answer].trim();
        var longestIndex = -1;
        for (var i = 0; i < options.length; i++) {
          if (i == answer) continue;
          if (longestIndex == -1 ||
              options[i].trim().length > options[longestIndex].trim().length) {
            longestIndex = i;
          }
        }
        final longest = options[longestIndex].trim();
        final gap = correct.length - longest.length;
        if (gap <= 0) continue;
        if (gap < visibleGap) {
          // 已整理过、但仍差 1-4 个字符的题目：继续用自然子句抹平，
          // 让最终指标贴近 25% 的随机水平；只处理人工清单覆盖的题目。
          if (_sweepCuratedResidual(
            lessonId: lessonId,
            questionText: questionText,
            question: question,
            options: options,
            answer: answer,
          )) {
            sweepResidual++;
          }
          untouchedSmallGap++;
          continue;
        }
        visible++;

        final outcome = _fix(
          lessonId: lessonId,
          questionText: questionText,
          question: question,
          options: options,
          answer: answer,
          correct: correct,
          longestIndex: longestIndex,
        );
        if (outcome.applied) {
          question['options'] = options;
          switch (outcome.strategy) {
            case 'A1':
              trimParen++;
            case 'A2':
              trimClause++;
            case 'A3':
              trimPeriod++;
            case 'B':
              padDistractor++;
            case 'C':
              curatedApplied++;
          }
          if (samples.length < 12) {
            samples.add(
              '$lessonId｜$questionText｜$correct｜$longest → ${outcome.detail}',
            );
          }
        } else {
          unresolved.add(
            '$lessonId｜$questionText｜正确项=$correct｜最长干扰项=$longest｜'
            '差值=$gap',
          );
        }
      }
    }
  }

  final after = _measure(manifest);
  stdout.writeln('单选题总数              $singles');
  stdout.writeln('可见长度线索（差值>=5） $visible');
  stdout.writeln('  A1 删尾部括号         $trimParen');
  stdout.writeln('  A2 截短解释子句       $trimClause');
  stdout.writeln('  A3 去掉句号           $trimPeriod');
  stdout.writeln('  B 补自然限定子句      $padDistractor');
  stdout.writeln('  C 人工整理            $curatedApplied');
  stdout.writeln('  残余差值再抹平        $sweepResidual');
  stdout.writeln('  未能自动处理          ${unresolved.length}');
  stdout.writeln('差值 <= 4（保持原样）  $untouchedSmallGap');
  stdout.writeln('');
  stdout.writeln(
    '修复后严格最长          ${after.strictCount} 道 '
    '(${after.strictRate}%，原 58.9%)',
  );
  stdout.writeln('修复后并列最长          ${after.tieCount} 道');
  stdout.writeln('修复后差值 >= 5 的题目  ${after.visibleGapCount}');
  stdout.writeln('正确项长度排名分布      ${after.rankDistribution}');
  for (final sample in samples) {
    stdout.writeln('  · $sample');
  }
  if (unresolved.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('需要人工整理（${unresolved.length}）：');
    for (final item in unresolved) {
      stdout.writeln('  - $item');
    }
  }

  if (emitReport) {
    File(reportPath).writeAsStringSync(_buildReport(after, unresolved));
    stdout.writeln('');
    stdout.writeln('已写入 $reportPath');
  }
  if (!write) {
    stdout.writeln('');
    stdout.writeln('（dry-run，未写入文件；加 --write 生效）');
    return;
  }
  File(manifestPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('');
  stdout.writeln('已写入 $manifestPath');
}

class _Outcome {
  const _Outcome(this.applied, this.strategy, this.detail);

  final bool applied;
  final String strategy;
  final String detail;
}

/// 对单道题依次尝试 A1/A2/A3/B/C 策略，直接改写 [options]。
_Outcome _fix({
  required String lessonId,
  required String questionText,
  required Map<String, dynamic> question,
  required List<String> options,
  required int answer,
  required String correct,
  required int longestIndex,
}) {
  final longest = options[longestIndex].trim();
  final explanation = (question['explanation'] as String?) ?? '';

  // A1：删除正确项尾部的补充说明括号。
  final parenMatch = RegExp(r'[（(]([^（）()]{2,40})[）)]$').firstMatch(correct);
  if (parenMatch != null) {
    final inner = parenMatch.group(1)!;
    final base = correct.substring(0, parenMatch.start).trim();
    final innerCjk = RegExp(r'[\u4e00-\u9fff]').allMatches(inner).length;
    final codeLike = RegExp(r'[:;{}<>=]').hasMatch(inner);
    // 纯英文的括号同样可能是补充说明（如「.aab（Android App Bundle）」），
    // 但要求它是多个单词，避免把「print(x)」这类代码括号当成说明删掉。
    final descriptiveEnglish =
        RegExp(r'^[A-Za-z][A-Za-z0-9 +./&-]*$').hasMatch(inner) &&
        inner.contains(' ') &&
        inner.trim().split(RegExp(r'\s+')).length >= 2;
    final baseComplete = RegExp(
      r'[\u4e00-\u9fffA-Za-z0-9_）)]$',
    ).hasMatch(base);
    if ((innerCjk >= 1 || descriptiveEnglish) &&
        !codeLike &&
        base.length >= 2 &&
        base.length <= longest.length &&
        baseComplete &&
        _noConflict(base, options, answer) &&
        _explanationSafe(
          explanation: explanation,
          oldText: correct,
          newText: base,
          dropped: matchGroupText(correct, parenMatch.start),
        )) {
      options[answer] = base;
      _syncExplanation(question, correct, base);
      return _Outcome(true, 'A1', base);
    }
  }

  // A2：把「主句 + 解释子句」截短到仍然完整的最长前缀。
  final clauses = splitClauses(correct);
  if (clauses.length > 1) {
    var prefix = '';
    String? best;
    for (var i = 0; i < clauses.length - 1; i++) {
      prefix = i == 0 ? clauses[i].trim() : '$prefix，${clauses[i].trim()}';
      if (prefix.length < 8 || prefix.length > longest.length) continue;
      if (RegExp(r'[的了和与或把将对为让使在从向并且但而即等是]$').hasMatch(prefix)) {
        continue;
      }
      best = prefix;
    }
    if (best != null &&
        _noConflict(best, options, answer) &&
        _explanationSafe(
          explanation: explanation,
          oldText: correct,
          newText: best,
          dropped: correct.substring(best.length).replaceFirst(
            RegExp(r'^[，；、]'),
            '',
          ),
        )) {
      options[answer] = best;
      _syncExplanation(question, correct, best);
      return _Outcome(true, 'A2', best);
    }
  }

  // A3：去掉正确项尾部的句号。
  if (correct.endsWith('。') && correct.length - 1 <= longest.length) {
    final base = correct.substring(0, correct.length - 1).trim();
    if (base.isNotEmpty &&
        _noConflict(base, options, answer) &&
        _explanationSafe(
          explanation: explanation,
          oldText: correct,
          newText: base,
          dropped: '。',
        )) {
      options[answer] = base;
      _syncExplanation(question, correct, base);
      return _Outcome(true, 'A3', base);
    }
  }

  // B：给错误项补自然限定子句，按长度从长到短尝试每个干扰项。
  final distractors = <int>[
    for (var i = 0; i < options.length; i++)
      if (i != answer) i,
  ]..sort(
      (a, b) => options[b].trim().length.compareTo(options[a].trim().length),
    );
  for (final index in distractors) {
    final base = options[index].trim();
    final clause = caveatsToReach(questionText, base, correct.length);
    if (clause == null) continue;
    if (!_canSyncDistractor(explanation, base)) continue;
    final next = '$base$clause';
    if (next.length > correct.length + 14) continue;
    if (options.any((other) => other.trim() == next)) continue;
    options[index] = next;
    _syncExplanation(question, base, next);
    return _Outcome(true, 'B', next);
  }

  // C：人工整理过的特例。
  for (final rewrite in curatedRewrites) {
    if (rewrite.lessonId != lessonId) continue;
    if (!questionText.contains(rewrite.questionKeyword)) continue;
    final before = List<String>.from(options);
    var hit = false;
    if (rewrite.rewritesAnswer &&
        options[answer].trim() == rewrite.oldAnswerText &&
        _explanationSafe(
          explanation: explanation,
          oldText: rewrite.oldAnswerText!,
          newText: rewrite.newAnswerText!,
          dropped: '',
        )) {
      options[answer] = rewrite.newAnswerText!;
      _syncExplanation(question, rewrite.oldAnswerText!, rewrite.newAnswerText!);
      hit = true;
    }
    if (rewrite.rewritesDistractor) {
      for (var i = 0; i < options.length; i++) {
        if (i == answer) continue;
        if (options[i].trim() != rewrite.oldDistractorText) continue;
        if (options.any((other) => other.trim() == rewrite.newDistractorText)) {
          break;
        }
        if (!_canSyncDistractor(explanation, rewrite.oldDistractorText!)) {
          break;
        }
        options[i] = rewrite.newDistractorText!;
        _syncExplanation(
          question,
          rewrite.oldDistractorText!,
          rewrite.newDistractorText!,
        );
        hit = true;
        break;
      }
    }
    if (!hit) continue;
    // 人工改写后若仍留 1-4 个字符的差值，再自动补一句自然限定子句收尾。
    var newCorrect = options[answer].trim();
    var newLongestIndex = -1;
    for (var i = 0; i < options.length; i++) {
      if (i == answer) continue;
      if (newLongestIndex == -1 ||
          options[i].trim().length > options[newLongestIndex].trim().length) {
        newLongestIndex = i;
      }
    }
    if (newCorrect.length > options[newLongestIndex].trim().length) {
      final base = options[newLongestIndex].trim();
      final clause = caveatsToReach(questionText, base, newCorrect.length);
      if (clause != null) {
        final next = '$base$clause';
        if (next.length <= newCorrect.length + 14 &&
            !options.any((other) => other.trim() == next)) {
          options[newLongestIndex] = next;
          _syncExplanation(question, base, next);
          newCorrect = options[answer].trim();
        }
      }
    }
    // 只有确实把长度差压到可感知阈值以下才接受改写。
    var newLongest = 0;
    for (var i = 0; i < options.length; i++) {
      if (i == answer) continue;
      final length = options[i].trim().length;
      if (length > newLongest) newLongest = length;
    }
    if (newCorrect.length - newLongest >= visibleGap) {
      for (var i = 0; i < options.length; i++) {
        options[i] = before[i];
      }
      continue;
    }
    return _Outcome(true, 'C', options[answer]);
  }
  return const _Outcome(false, '', '');
}

/// 截短正确项后，解析里不能留下对已删除片段的悬空引用。
/// 已整理过、但仍留 1-4 个字符差值的题目：补一句自然子句收尾。
///
/// 只处理人工清单覆盖的题目（选项里已经出现清单中的新文本），
/// 避免对本来就未列入计划的 1-4 字符差值动手。
bool _sweepCuratedResidual({
  required String lessonId,
  required String questionText,
  required Map<String, dynamic> question,
  required List<String> options,
  required int answer,
}) {
  final correct = options[answer].trim();
  var longestIndex = -1;
  for (var i = 0; i < options.length; i++) {
    if (i == answer) continue;
    if (longestIndex == -1 ||
        options[i].trim().length > options[longestIndex].trim().length) {
      longestIndex = i;
    }
  }
  if (longestIndex == -1) return false;
  final longest = options[longestIndex].trim();
  if (correct.length <= longest.length) return false;
  final matched = curatedRewrites.any(
    (rewrite) =>
        rewrite.lessonId == lessonId &&
        questionText.contains(rewrite.questionKeyword) &&
        ((rewrite.newAnswerText != null &&
                options[answer].trim() == rewrite.newAnswerText) ||
            (rewrite.newDistractorText != null &&
                options.any(
                  (option) => option.trim() == rewrite.newDistractorText,
                ))),
  );
  if (!matched) return false;
  final clause = caveatsToReach(questionText, longest, correct.length);
  if (clause == null) return false;
  final next = '$longest$clause';
  if (options.any((other) => other.trim() == next)) return false;
  if (!_canSyncDistractor(
    (question['explanation'] as String?) ?? '',
    longest,
  )) {
    return false;
  }
  options[longestIndex] = next;
  _syncExplanation(question, longest, next);
  return true;
}

/// 干扰项改写前的解析安全检查。
///
/// 解析只有在「」/“”里引用选项时才允许跟着替换；若旧选项文本出现在正文
/// 语义句里（没有被引号包裹），同步替换会把解析改成病句，此时必须放弃这次
/// 干扰项改写，宁可保留长度差也不能污染内容。
bool _canSyncDistractor(String explanation, String oldText) {
  if (explanation.isEmpty || oldText.isEmpty) return true;
  const openers = <String>['「', '“', '『', '"'];
  const closers = <String>['」', '”', '』', '"'];
  var index = explanation.indexOf(oldText);
  while (index >= 0) {
    final before = index == 0 ? '' : explanation[index - 1];
    final afterIndex = index + oldText.length;
    final after =
        afterIndex >= explanation.length ? '' : explanation[afterIndex];
    final quoted =
        openers.contains(before) || closers.contains(after);
    if (!quoted) return false;
    index = explanation.indexOf(oldText, index + 1);
  }
  return true;
}

bool _explanationSafe({
  required String explanation,
  required String oldText,
  required String newText,
  required String dropped,
}) {
  // 解析本身有 120 字符的下限门槛，替换答案文本后不能掉到线下。
  if (explanation.contains(oldText) &&
      explanation.length - oldText.length + newText.length < 130) {
    return false;
  }
  if (!explanation.contains(dropped.trim()) || dropped.trim().isEmpty) {
    return true;
  }
  return explanation.contains(oldText);
}

void _syncExplanation(
  Map<String, dynamic> question,
  String oldText,
  String newText,
) {
  final explanation = (question['explanation'] as String?) ?? '';
  if (explanation.isEmpty || !explanation.contains(oldText)) return;
  question['explanation'] = explanation.replaceAll(oldText, newText);
}

/// 截短后的正确项不能与其它选项重复或互为前缀。
bool _noConflict(String candidate, List<String> options, int answer) {
  for (var i = 0; i < options.length; i++) {
    if (i == answer) continue;
    final other = options[i].trim();
    if (other == candidate) return false;
    if (other.startsWith(candidate) || candidate.startsWith(other)) return false;
  }
  return true;
}

String matchGroupText(String text, int start) => text.substring(start);

class _Measure {
  const _Measure({
    required this.strictRate,
    required this.strictCount,
    required this.tieCount,
    required this.visibleGapCount,
    required this.rankDistribution,
  });

  final String strictRate;
  final int strictCount;
  final int tieCount;
  final int visibleGapCount;
  final String rankDistribution;
}

/// 统计修复后的偏置指标：严格最长占比、差值 >= 5 的题数、正确项长度排名。
_Measure _measure(Map<String, dynamic> manifest) {
  var singles = 0;
  var strict = 0;
  var ties = 0;
  var visibleGapCount = 0;
  final rank = <int, int>{0: 0, 1: 0, 2: 0, 3: 0};
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    for (final rawLesson
        in (rawCategory as Map)['lessons'] as List<dynamic>) {
      for (final rawQuestion
          in ((rawLesson as Map)['quiz'] as List<dynamic>? ?? const [])) {
        final question = (rawQuestion as Map).cast<String, dynamic>();
        if (((question['type'] as String?) ?? 'single') != 'single') continue;
        final options =
            ((question['options'] as List<dynamic>?) ?? const <dynamic>[])
                .cast<String>();
        final answer = (question['answer'] as num?)?.toInt() ?? 0;
        if (options.length < 2 || answer >= options.length) continue;
        singles++;
        final correct = options[answer].trim();
        var longer = 0;
        var tied = 0;
        var longestOther = 0;
        for (var i = 0; i < options.length; i++) {
          if (i == answer) continue;
          final text = options[i].trim();
          if (text.length > correct.length) longer++;
          if (text.length == correct.length) tied++;
          if (text.length > longestOther) longestOther = text.length;
        }
        if (longer == 0 && tied == 0) strict++;
        if (longer == 0 && tied > 0) ties++;
        if (correct.length - longestOther >= visibleGap) visibleGapCount++;
        rank[longer.clamp(0, 3)] = (rank[longer.clamp(0, 3)] ?? 0) + 1;
      }
    }
  }
  final rate = singles == 0 ? '0.0' : (strict * 100 / singles).toStringAsFixed(1);
  return _Measure(
    strictRate: rate,
    strictCount: strict,
    tieCount: ties,
    visibleGapCount: visibleGapCount,
    rankDistribution:
        '{0项更长: ${rank[0]}, 1项: ${rank[1]}, 2项: ${rank[2]}, 3项: ${rank[3]}}',
  );
}

String _buildReport(_Measure after, List<String> unresolved) {
  final buffer = StringBuffer()
    ..writeln('# P1-6 单选题长度线索复核报告')
    ..writeln()
    ..writeln('- 严格最长（无并列）：${after.strictCount} 道，占比 ${after.strictRate}%')
    ..writeln('- 与干扰项并列最长：${after.tieCount} 道')
    ..writeln('- 差值 >= 5 的题目：${after.visibleGapCount}')
    ..writeln('- 正确项长度排名分布：${after.rankDistribution}')
    ..writeln()
    ..writeln('差值 <= 4 的题目保持原样：该量级不足以构成可感知的答题线索。')
    ..writeln();
  if (unresolved.isEmpty) {
    buffer.writeln('未发现需要人工整理的题目。');
  } else {
    buffer.writeln('需要人工整理（${unresolved.length}）：');
    buffer.writeln();
    for (final item in unresolved) {
      buffer.writeln('- $item');
    }
  }
  return buffer.toString();
}
