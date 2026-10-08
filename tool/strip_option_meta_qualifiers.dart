// P1-6 第 1 步：删掉干扰项里的「元评论」括号限定语。
//
// 用法：
//   dart tool/strip_option_meta_qualifiers.dart            # dry-run
//   dart tool/strip_option_meta_qualifiers.dart --write    # 写回 manifest.json
//
// 早期为了压「最长项即答案」的长度线索，给干扰项补过
// 「（混淆了相邻概念，不能回答本题）」这类括号。它虽然拉平了长度，
// 却直接把「我是错误选项」写在脸上，属于典型的元评论。
// 这里先把括号整体删掉，长度线索随后由
// rebalance_single_option_length.dart 用自然语气的限定子句重新配平。
// 解析里若原样引用了旧选项文本，同步替换成新文本。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

/// 元评论括号：以括号结尾，且括号内出现这些「判定式」说法。
final RegExp metaQualifier = RegExp(
  r'[（(][^（）()]*(仅部分场景成立|与课程定义不一致|忽略了题干限定的前提|'
  r'只在个别条件下成立|只在边界情况下成立|只在极少数边界情况下成立|'
  r'没有覆盖题干给出的条件|混淆了相邻概念|不能回答本题|不能作为答案)'
  r'[^（）()]*[）)]$',
);

void main(List<String> args) {
  final write = args.contains('--write');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

  var stripped = 0;
  var explanationFollowed = 0;
  var skippedDuplicate = 0;
  final byLesson = <String, int>{};
  final samples = <String>[];
  final shortAfterStrip = <String>[];

  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    for (final rawLesson
        in (rawCategory as Map)['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final lessonId = lesson['id'].toString();
      for (final rawQuestion
          in (lesson['quiz'] as List<dynamic>? ?? const [])) {
        final question = (rawQuestion as Map).cast<String, dynamic>();
        final options =
            ((question['options'] as List<dynamic>?) ?? const <dynamic>[])
                .cast<String>();
        var changed = false;
        for (var i = 0; i < options.length; i++) {
          final option = options[i].trim();
          final match = metaQualifier.firstMatch(option);
          if (match == null) continue;
          final base = option.substring(0, match.start).trim();
          if (base.isEmpty) continue;
          if (options.any((other) => other.trim() == base)) {
            skippedDuplicate++;
            continue;
          }
          options[i] = base;
          changed = true;
          stripped++;
          byLesson[lessonId] = (byLesson[lessonId] ?? 0) + 1;
          if (samples.length < 10) {
            samples.add('$lessonId｜$option → $base');
          }
          final explanation = (question['explanation'] as String?) ?? '';
          if (explanation.contains(option)) {
            question['explanation'] = explanation.replaceAll(option, base);
            explanationFollowed++;
            final reduced = (question['explanation'] as String).trim();
            if (reduced.length < 120) {
              shortAfterStrip.add(
                '$lessonId｜${question['question']}｜${reduced.length}',
              );
            }
          }
        }
        if (changed) {
          question['options'] = options;
        }
      }
    }
  }

  stdout.writeln('删除元评论括号  $stripped');
  stdout.writeln('同步解析引用    $explanationFollowed');
  stdout.writeln('跳过（会重复）  $skippedDuplicate');
  stdout.writeln('涉及课程        ${byLesson.length}');
  if (shortAfterStrip.isNotEmpty) {
    stdout.writeln('解析跌到 120 字符以下 ${shortAfterStrip.length}（需人工补写）：');
    for (final item in shortAfterStrip) {
      stdout.writeln('  ! $item');
    }
  }
  for (final sample in samples) {
    stdout.writeln('  · $sample');
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
