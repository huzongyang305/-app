// 校验脚本的外部工具链解析（开发期使用，不参与 App 打包）。
//
// CI（Ubuntu）与本地（Windows）的可执行文件名并不相同，这里统一按候选
// 列表探测；探测失败时返回 null，由调用方降级为结构校验并记录提示，
// 避免把「环境里缺少某个命令」变成脚本崩溃。
import 'dart:io';

/// 依次探测候选命令，返回第一个能正常响应 `--version` 的命令名。
String? resolveToolchain(List<String> candidates) {
  for (final candidate in candidates) {
    if (candidate.isEmpty) continue;
    try {
      final result = Process.runSync(candidate, const <String>['--version']);
      if (result.exitCode == 0) return candidate;
    } on ProcessException {
      // 命令不存在或不可执行：继续尝试下一个候选。
    }
  }
  return null;
}

/// Python 解释器的跨平台候选：优先显式环境变量 `PYTHON`。
List<String> get pythonCandidates => <String>[
      Platform.environment['PYTHON'] ?? '',
      if (Platform.isWindows) 'python',
      if (Platform.isWindows) 'py',
      if (!Platform.isWindows) 'python3',
      if (!Platform.isWindows) 'python',
    ];

/// 执行一条校验命令；可执行文件缺失（ProcessException）时返回 null。
ProcessResult? runToolchain(String? executable, List<String> arguments) {
  if (executable == null) return null;
  try {
    return Process.runSync(executable, arguments);
  } on ProcessException {
    return null;
  }
}
