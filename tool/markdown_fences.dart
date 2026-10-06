// Markdown 代码围栏识别：给每一行标注它是否属于围栏（含围栏标记行）。
//
// 内容工具与治理审计都要判断「某一行是不是真的章节标题」，
// 而示例代码里出现的 `## 标题` 只是被围栏包住的文本。判定规则：
// - 开围栏：行首（允许缩进）至少 3 个反引号，后面可以跟语言标记；
// - 闭围栏：反引号数量不少于开围栏，且标记之后没有其他内容；
// - 因此 ````markdown 里嵌套的 ```bash 不会提前关闭外层围栏。
List<bool> markdownFenceMask(String markdown) {
  final lines = markdown.split('\n');
  final mask = List<bool>.filled(lines.length, false);
  var fenceLength = 0;
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trimLeft();
    final run = _backtickRun(line);
    if (fenceLength == 0) {
      if (run >= 3) {
        mask[index] = true;
        fenceLength = run;
      }
      continue;
    }
    mask[index] = true;
    if (run >= fenceLength && line.substring(run).trim().isEmpty) {
      fenceLength = 0;
    }
  }
  return mask;
}

int _backtickRun(String line) {
  var count = 0;
  while (count < line.length && line[count] == '`') {
    count++;
  }
  return count;
}
