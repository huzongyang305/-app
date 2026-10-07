import 'localized_text.dart';

/// 代码沙箱里的一个挑战用例。
///
/// 与 [SandboxExample] 不同：示例给出完整可运行代码，用来演示语言特性；
/// 挑战只给出任务描述、起始骨架与期望输出，由学习者自己补全代码，
/// 沙箱运行后把真实输出与 [expectedOutput] 比对，给出通过 / 未通过结论。
///
/// 只有内置了真实运行时的语言才提供挑战（JavaScript / TypeScript /
/// Python / Lua / SQL / Bash / Scheme / C++ 等）；Java、C#、Dart、Go、
/// Rust、Kotlin、Swift 目前是静态追踪教学模式，输出格式带诊断信息，
/// 不适合做严格比对，因此挑战列表为空。
class SandboxChallenge {
  const SandboxChallenge({
    required this.id,
    required this.title,
    required this.prompt,
    required this.starterCode,
    required this.expectedOutput,
    this.stdin = '',
    this.hint,
  });

  /// 全局唯一的挑战标识（用于记录通过状态）。
  final String id;

  /// 挑战名称（中英双语）。
  final LocalizedText title;

  /// 任务描述：要求学习者写出什么。
  final LocalizedText prompt;

  /// 起始代码骨架，选中挑战时填入编辑器。
  final String starterCode;

  /// 期望的标准输出（按行比对，忽略行尾空白与多余空行）。
  final String expectedOutput;

  /// 该挑战使用的标准输入；为空表示不需要输入。
  final String stdin;

  /// 可选提示，折叠显示，避免直接给出答案。
  final LocalizedText? hint;
}
