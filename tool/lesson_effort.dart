// P0 内容量度：难度梯度与预计用时模型的唯一实现。
//
// 这个文件同时被两处引用，保证「写入」和「校验」用的是同一套口径：
//   - tool/rebalance_learning_path.dart（写入 manifest 与正文）
//   - tool/audit_content_governance.dart（审计，防止元数据再次漂移）
//
// 预计用时模型（口径写死在这里，改口径必须同时重跑校准工具）：
//   常规课：正文精读 chars/480 分钟 + 每个代码块 1 分钟 + 每道题 0.8 分钟；
//   实战课：正文之外要真正动手实现，取「代码块数量×5 + 20 分钟」与阅读量
//          的较大值，保证跟着做完的时间不被低估；
//   最后四舍五入到 5 分钟，并夹在常规课 15~75、实战课 60~180 之间。
import 'dart:math' as math;

/// 难度梯度：下标越大越难，顺序即推荐学习顺序。
const List<String> difficultyLadder = <String>['入门', '基础', '进阶', '高级'];

/// 难度在梯度中的下标；遇到未知标签按「基础」处理，避免审计崩溃。
int difficultyRank(String difficulty) {
  final index = difficultyLadder.indexOf(difficulty);
  return index < 0 ? 1 : index;
}

/// 一篇课程的内容量度。
class LessonEffort {
  const LessonEffort({
    required this.chars,
    required this.codeBlocks,
    required this.quizCount,
    required this.handsOn,
  });

  /// 去空白后的正文字符数。
  final int chars;

  /// 带语言标记的代码块数量（```text 之类的纯输出块不计入阅读负担）。
  final int codeBlocks;

  /// 选择题数量。
  final int quizCount;

  /// 是否实战/项目课：需要动手实现，用时按实现工作量加权。
  final bool handsOn;
}

/// 统计 Markdown 正文的内容量度。
LessonEffort measureEffort(
  String markdown, {
  required int quizCount,
  required bool handsOn,
}) {
  final chars = markdown.replaceAll(RegExp(r'\s'), '').length;
  final fence = RegExp(r'^```([^\n]*)$', multiLine: true);
  var codeBlocks = 0;
  for (final match in fence.allMatches(markdown)) {
    if ((match.group(1) ?? '').trim().isNotEmpty) codeBlocks++;
  }
  return LessonEffort(
    chars: chars,
    codeBlocks: codeBlocks,
    quizCount: quizCount,
    handsOn: handsOn,
  );
}

/// 预计用时（分钟）。
int estimateMinutes(LessonEffort effort) {
  final reading =
      effort.chars / 480 +
      effort.codeBlocks * 1.0 +
      effort.quizCount * 0.8;
  if (!effort.handsOn) {
    return _roundToFive(reading.clamp(15.0, 75.0));
  }
  final handsOn = math.max(reading, effort.codeBlocks * 5.0 + 20.0);
  return _roundToFive(handsOn.clamp(60.0, 180.0));
}

/// 是否实战/项目课：id 含 project，或标题里写明「实战」。
bool isHandsOnLesson({required String id, required String title}) =>
    id.contains('project') || title.contains('实战');

int _roundToFive(double value) => (value / 5).round() * 5;
