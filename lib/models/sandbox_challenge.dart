import 'localized_text.dart';

/// 挑战中的一个测试用例：一组标准输入与对应的期望输出。
///
/// 一个挑战可以带多组用例，只有全部用例的输出都与期望一致才算通过；
/// 这能避免学习者针对单条输入写死答案。
class SandboxChallengeCase {
  const SandboxChallengeCase({
    this.stdin = '',
    required this.expectedOutput,
  });

  /// 该用例使用的标准输入；为空表示不需要输入。
  final String stdin;

  /// 该用例的期望标准输出（按行比对，忽略行尾空白与多余空行）。
  final String expectedOutput;
}

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
    this.extraCases = const <SandboxChallengeCase>[],
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

  /// 第一组测试用例的期望标准输出（按行比对，忽略行尾空白与多余空行）。
  final String expectedOutput;

  /// 第一组测试用例的标准输入；为空表示不需要输入。
  final String stdin;

  /// 除第一组外的附加测试用例。
  final List<SandboxChallengeCase> extraCases;

  /// 可选提示，折叠显示，避免直接给出答案。
  final LocalizedText? hint;

  /// 全部测试用例，第一组由 [stdin] / [expectedOutput] 构成。
  List<SandboxChallengeCase> get cases => <SandboxChallengeCase>[
    SandboxChallengeCase(stdin: stdin, expectedOutput: expectedOutput),
    ...extraCases,
  ];

  int get caseCount => 1 + extraCases.length;
}
