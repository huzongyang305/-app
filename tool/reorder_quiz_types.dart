// P0：把每课测验恢复成「单选题在前、互动题型在后」的顺序。
//
// 用法：
//   dart tool/reorder_quiz_types.dart [--dry-run]
//
// 之前批量替换元问题时，新单选题被追加到课程末尾，导致填空/代码/排错题
// 跑到了前面。这里按题型稳定排序：组内保持原有相对顺序，不改动题目本身。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

String _typeOf(Map<String, dynamic> q) => (q['type'] as String?) ?? 'single';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

  var lessonsChanged = 0;
  var movedBefore = 0;
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    for (final rawLesson in (rawCategory as Map)['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final quiz = ((lesson['quiz'] as List<dynamic>?) ?? const [])
          .map((raw) => (raw as Map).cast<String, dynamic>())
          .toList();
      if (quiz.isEmpty) continue;
      final singles = quiz.where((q) => _typeOf(q) == 'single').toList();
      final others = quiz.where((q) => _typeOf(q) != 'single').toList();
      if (others.isEmpty) continue;
      final alreadyOrdered =
          quiz.takeWhile((q) => _typeOf(q) == 'single').length ==
          singles.length;
      if (alreadyOrdered) continue;
      movedBefore += others
          .where((other) => quiz.indexOf(other) < singles.length)
          .length;
      lesson['quiz'] = [...singles, ...others];
      lessonsChanged++;
    }
  }

  stdout.writeln('调整课程数          $lessonsChanged');
  stdout.writeln('移到后面的互动题    $movedBefore');
  if (!dryRun) {
    File(
      manifestPath,
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
    stdout.writeln('已写回 $manifestPath');
  }
}
