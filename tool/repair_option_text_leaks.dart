// P1-6 收尾修复：把选项改写时误同步进「解析」正文的选项文案改成语义通顺的表述。
//
// 背景：rebalance_single_option_length / strip_option_meta_qualifiers 在改写干扰项
// 之后，会把解析里出现的旧选项文本整体替换成新选项文本。当旧文本出现在解析的
// 语义句里（而不是被「」引用的选项名）时，句子会被替换成病句。
// 本工具按人工复核过的清单做定点修复，每条片段都要求唯一命中。
//
// 用法：
//   dart tool/repair_option_text_leaks.dart            # 预演，只报告命中次数
//   dart tool/repair_option_text_leaks.dart --write    # 写回 manifest.json
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

/// 人工复核过的定点修复清单：(定位, 旧片段, 新片段)。
final List<(String, String, String)> repairs = <(String, String, String)>[
  (
    'flutter_state q4',
    '只属于 State 的 setState 属于 StatefulWidget 自身。',
    'setState 属于 StatefulWidget 自身，与 ChangeNotifier 无关。',
  ),
  (
    'html_css_project q4',
    'orientation 这类设备方向查询 针对横竖屏。',
    'orientation 针对横竖屏。',
  ),
  (
    'python_basics q4',
    '其他选项：抛出 SyntaxError 泛指语法问题、TypeError 指类型不匹配。',
    '其他选项：抛出 SyntaxError 只是笼统说法，缩进不一致会报更具体的 IndentationError；TypeError 指类型不匹配。',
  ),
  (
    'python_errors_files q4',
    '其他选项：抛出 IndexError 是下标越界、KeyError 是字典缺键、TypeError 是类型不匹配。',
    '其他选项：抛出 IndexError 对应下标越界，KeyError 是字典缺键，TypeError 是类型不匹配。',
  ),
  (
    'python_modules_stdlib q3',
    '其他选项：pathlib 管路径、改用 subprocess 处理词频，但它只覆盖了部分情况 调进程、math 做数学运算，只有 Counter 专门用于计数。',
    '其他选项：pathlib 管路径、subprocess 调进程、math 做数学运算，只有 Counter 专门用于计数。',
  ),
  (
    'js_objects q5',
    '在「对象、原型与类」里，1，只有 结果仍然是 undefined，不会取默认值 才触发默认值。',
    '在「对象、原型与类」里，1，只有 undefined 才触发默认值；解构默认值在取到的值为 undefined（属性缺失也算）时生效，取到 null 不会触发默认值。',
  ),
  (
    'js_objects q5',
    '在「对象、原型与类」里，解构默认值只在对应值为 结果仍然是 undefined，不会取默认值 时生效，传 null 不会用默认值。',
    '把输入换成 null、0 或缺失属性各跑一次，就能确认只有 undefined 会走到默认值这条分支。',
  ),
  (
    'js_objects q5',
    '“const”与「对象、原型与类」的术语表相呼应，只有符合对象、原型、class约束的“1，只有 结果仍然是 undefined，不会取默认值 才触发默认”才是正文支持的结论。',
    '“const”与「对象、原型与类」的术语表相呼应，只有符合对象、原型、class 约束的结论才由正文支持。',
  ),
];

void main(List<String> args) {
  final write = args.contains('--write');
  final file = File(manifestPath);
  if (!file.existsSync()) {
    stderr.writeln('找不到 $manifestPath');
    exitCode = 1;
    return;
  }
  var text = file.readAsStringSync();
  var applied = 0;
  var missing = 0;
  for (final (label, oldText, newText) in repairs) {
    final hits = RegExp(RegExp.escape(oldText)).allMatches(text).length;
    if (hits != 1) {
      missing++;
      stdout.writeln('跳过 $label：旧片段命中 $hits 次（要求恰好 1 次）');
      continue;
    }
    text = text.replaceFirst(oldText, newText);
    applied++;
    stdout.writeln('修复 $label');
  }
  stdout.writeln('计划修复 ${repairs.length} 处，已处理 $applied 处，未命中 $missing 处');
  if (!write) {
    stdout.writeln('[dry-run] 未写文件，加 --write 写回');
    return;
  }
  if (missing > 0) {
    stderr.writeln('存在未命中片段，已中止写入，避免部分修复');
    exitCode = 1;
    return;
  }
  file.writeAsStringSync(text);
  stdout.writeln('已写回 $manifestPath');
}
