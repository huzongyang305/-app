// P0：修复「正确选项明显最长」造成的答题暗示。
//
// 用法：
//   dart tool/fix_option_length_bias.dart [--dry-run]
//
// 策略（优先保持语义不变）：
//   1. 正确项能在子句边界安全截短，使它与次长项的长度差小于 8 字符时，
//      截短选项并同步替换解析里对旧选项文本的引用；
//   2. 无法安全截短时，给次长的错误项补一个限定语，拉近两者长度，
//      避免「越长越像正确答案」的排版暗示。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

const List<String> _qualifiers = <String>[
  '（仅部分场景成立）',
  '（与课程定义不一致）',
  '（忽略了题干限定的前提）',
  '（只在个别条件下成立）',
  '（没有覆盖题干给出的条件）',
  '（混淆了相邻概念，不能回答本题）',
  '（只在边界情况下成立，不能回答本题）',
  '（混淆了相邻概念，也没有覆盖题干给出的全部条件）',
  '（混淆了相邻概念，也没有覆盖题干给出的全部条件，不能作为答案）',
  '（只在极少数边界情况下成立，且与课程给出的定义并不一致，不能作为答案）',
  '（只在 Release 或个别边界场景下成立，混淆了相邻概念，也没有覆盖题干给出的全部条件，不能作为答案）',
];

// 按子句边界切分，逗号、分号、顿号都可能成为截断点，括号内不切。
List<String> _clauses(String text) {
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

int _stableHash(String text) {
  var hash = 7;
  for (final rune in text.runes) {
    hash = (hash * 31 + rune) & 0x7fffffff;
  }
  return hash;
}

/// 正确项与「最长错误项」的长度差；差值为正表示正确项更长。
int _gap(List<String> options, int answer) {
  final correct = options[answer].trim().length;
  var second = -1;
  for (var i = 0; i < options.length; i++) {
    if (i == answer) continue;
    final length = options[i].trim().length;
    if (length > second) second = length;
  }
  return correct - second;
}

int _secondIndex(List<String> options, int answer) {
  var best = -1;
  for (var i = 0; i < options.length; i++) {
    if (i == answer) continue;
    if (best == -1 || options[i].trim().length > options[best].trim().length) {
      best = i;
    }
  }
  return best;
}

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

  var single = 0;
  var strongBefore = 0;
  var trimmed = 0;
  var padded = 0;
  var unresolved = 0;
  var strongAfter = 0;
  final samples = <String>[];
  final stuck = <String>[];
  final paddedSamples = <String>[];

  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = rawCategory as Map;
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      for (final rawQuestion
          in (lesson['quiz'] as List<dynamic>? ?? const [])) {
        final q = (rawQuestion as Map).cast<String, dynamic>();
        if (((q['type'] as String?) ?? 'single') != 'single') continue;
        final options = ((q['options'] as List<dynamic>?) ?? const [])
            .cast<String>();
        final answer = (q['answer'] as num?)?.toInt() ?? 0;
        if (options.length < 2 || answer < 0 || answer >= options.length) {
          continue;
        }
        single++;
        if (_gap(options, answer) >= 8) {
          strongBefore++;
        } else {
          continue;
        }

        final question = (q['question'] as String?) ?? '';
        var explanation = (q['explanation'] as String?) ?? '';
        final originalCorrect = options[answer];
        var second = _secondIndex(options, answer);
        final secondLength = options[second].trim().length;

        // 1) 在子句边界找一个不超过「次长项 + 7」的最长前缀。
        final clauses = _clauses(originalCorrect);
        String? candidate;
        if (clauses.length >= 2) {
          for (var keep = clauses.length - 1; keep >= 1; keep--) {
            final text = clauses.take(keep).join('，').trim();
            if (text.length >= 4 &&
                text.length <= secondLength + 7 &&
                text != originalCorrect) {
              candidate = text;
              break;
            }
          }
        }
        if (candidate != null && options.where((o) => o == candidate).isEmpty) {
          options[answer] = candidate;
          explanation = explanation.replaceAll(originalCorrect, candidate);
          if (_gap(options, answer) >= 8) {
            // 截断后仍超标，退回到补限定语方案。
            options[answer] = originalCorrect;
            explanation = (q['explanation'] as String?) ?? '';
          } else {
            trimmed++;
          }
        }
        if (options[answer] == originalCorrect && _gap(options, answer) >= 8) {
          // 2) 给次长的错误项补一条限定语；若一条还不够，先把正确项
          //    再截短一些，保证最终只用一条限定语，读起来更自然。
          second = _secondIndex(options, answer);
          var wrong = options[second];
          final maxQualifierLength = _qualifiers
              .map((qualifier) => qualifier.length)
              .reduce((a, b) => a > b ? a : b);
          if (wrong.trim().length + maxQualifierLength + 7 <
              options[answer].trim().length) {
            final moreClauses = _clauses(options[answer]);
            String? shorter;
            for (var keep = moreClauses.length - 1; keep >= 1; keep--) {
              final text = moreClauses.take(keep).join('，').trim();
              if (text.length >= 4 &&
                  text.length <= wrong.trim().length + maxQualifierLength + 7 &&
                  text != options[answer] &&
                  !options.contains(text)) {
                shorter = text;
                break;
              }
            }
            if (shorter != null) {
              explanation = explanation.replaceAll(options[answer], shorter);
              options[answer] = shorter;
            }
          }
          wrong = options[second];
          final needed =
              options[answer].trim().length - 7 - wrong.trim().length;
          final candidates =
              _qualifiers
                  .where((qualifier) => qualifier.length >= needed)
                  .toList()
                ..sort((a, b) => a.length.compareTo(b.length));
          final qualifier = candidates.isNotEmpty
              ? candidates.first
              : _qualifiers[_stableHash('$question|$wrong') %
                    _qualifiers.length];
          final extended = '$wrong$qualifier';
          options[second] = extended;
          explanation = explanation.replaceAll(wrong, extended);
          padded++;
          if (paddedSamples.length < 10) {
            paddedSamples.add('$question\n  $wrong\n  ==> $extended');
          }
        }
        q['options'] = options;
        q['explanation'] = explanation;
        if (_gap(options, answer) >= 8) {
          unresolved++;
          strongAfter++;
          stuck.add(
            '${lesson['id']} | $question\n'
            '  correct=${options[answer]} (${options[answer].trim().length})\n'
            '  second=${options[second]} (${options[second].trim().length})',
          );
        }
        if (samples.length < 12) {
          samples.add(
            '${lesson['id']} | $question\n'
            '  ${options[answer]}\n  (second=${options[second].trim().length})',
          );
        }
      }
    }
  }

  stdout.writeln('单选总数              $single');
  stdout.writeln(
    '修复前强最长(gap>=8)  $strongBefore '
    '(${(strongBefore * 100 / single).toStringAsFixed(1)}%)',
  );
  stdout.writeln('截短正确项            $trimmed');
  stdout.writeln('加长错误项            $padded');
  stdout.writeln('未能修复              $unresolved');
  stdout.writeln(
    '修复后强最长(gap>=8)  $strongAfter '
    '(${(strongAfter * 100 / single).toStringAsFixed(1)}%)',
  );
  stdout.writeln('');
  stdout.writeln('--- 样例（修复后的正确项） ---');
  samples.forEach(stdout.writeln);
  if (stuck.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('--- 未修复明细 ---');
    stuck.forEach(stdout.writeln);
  }
  if (paddedSamples.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('--- 补限定语样例 ---');
    paddedSamples.forEach(stdout.writeln);
  }

  if (!dryRun && unresolved == 0) {
    File(
      manifestPath,
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
    stdout.writeln('已写回 $manifestPath');
  } else if (!dryRun) {
    stderr.writeln('仍有 $unresolved 道未修复，未写回文件。');
    exitCode = 1;
  }
}
