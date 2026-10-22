// 项目交付物补全工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_project_delivery.dart [--dry-run]
//
// 为项目/实战课程补仓库结构、测试矩阵、验收数据和复盘模板。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String marker = '<!-- project-delivery:v1 -->';

const Map<String, List<String>> repoTrees = <String, List<String>>{
  'python': ['app/', '  api/', '  domain/', '  infra/', 'tests/', 'README.md'],
  'java': [
    'src/main/java/',
    'src/main/resources/',
    'src/test/java/',
    'pom.xml',
    'README.md',
  ],
  'csharp': [
    'src/App/',
    'src/Domain/',
    'tests/App.Tests/',
    'App.sln',
    'README.md',
  ],
  'javascript': [
    'src/',
    '  routes/',
    '  services/',
    '  repositories/',
    'tests/',
    'package.json',
  ],
  'typescript': [
    'src/',
    '  domain/',
    '  adapters/',
    'tests/',
    'tsconfig.json',
    'package.json',
  ],
  'go': ['cmd/app/', 'internal/domain/', 'internal/infra/', 'pkg/', 'go.mod'],
  'rust': ['src/main.rs', 'src/domain/', 'src/infra/', 'tests/', 'Cargo.toml'],
  'cpp': ['src/', 'include/', 'tests/', 'CMakeLists.txt', 'README.md'],
  'c': ['src/', 'include/', 'tests/', 'Makefile', 'README.md'],
  'kotlin': ['app/src/main/', 'app/src/test/', 'build.gradle.kts', 'README.md'],
  'swift': ['Sources/App/', 'Tests/', 'Package.swift', 'README.md'],
  'flutter': [
    'lib/',
    '  models/',
    '  screens/',
    '  services/',
    'test/',
    'pubspec.yaml',
  ],
  'shell': ['bin/', 'scripts/', 'tests/', 'Makefile', 'README.md'],
  'default': ['src/', 'tests/', 'docs/', 'README.md'],
};

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final manifest = jsonDecode(
    await File(manifestPath).readAsString(),
  ) as Map<String, dynamic>;
  var appended = 0;
  var skipped = 0;

  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final categoryId = category['id'] as String;
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final title = ((lesson['title'] as Map)['zh'] as String? ?? '');
      final isProject =
          lesson['id'].toString().contains('project') ||
          title.contains('实战') ||
          title.contains('项目');
      if (!isProject) continue;
      final file = File(lesson['file'] as String);
      final content = await file.readAsString();
      if (content.contains(marker) || content.contains('## 项目交付物')) {
        skipped++;
        continue;
      }
      final keywords =
          (lesson['keywords'] as List?)
              ?.map((item) => item.toString())
              .take(3)
              .join('、') ??
          title;
      final tree = repoTrees[categoryId] ?? repoTrees['default']!;
      final block =
          '''$marker

## 项目交付物

### 建议仓库结构

```text
${tree.join('\n')}
```

### 测试矩阵

| 层级 | 覆盖内容 | 最低数量 | 通过标准 |
| --- | --- | ---: | --- |
| 单元测试 | 领域规则、边界和错误分类 | 8 | 正常、边界、失败路径全部通过 |
| 集成测试 | 数据库、网络、文件或平台边界 | 3 | 使用真实边界且可重复运行 |
| 端到端测试 | 核心用户路径 | 1 | 从输入到输出完整跑通 |
| 手动验收 | 文档中列出的 5 个场景 | 5 | 有命令、输出和结论记录 |

### 验收数据

```json
{
  "project": "${lesson['id']}",
  "input": {"case": "normal", "value": 5},
  "expected": {"ok": true, "result": 5},
  "failure_case": {"value": -1, "error": "validation_error"},
  "idempotency_key": "demo-001"
}
```

### 复盘模板

| 问题 | 记录 |
| --- | --- |
| 原目标是什么？ | 用一句话描述可验收目标 |
| 实际发生了什么？ | 时间线、指标和关键日志 |
| 哪个假设被推翻？ | 根因与促成因素 |
| 如何回滚？ | 步骤、耗时和数据校验 |
| 下一步做什么？ | 负责人、期限和验证方式 |

> 项目验收围绕「$keywords」：至少完成一次正常路径、一次边界输入、一次失败恢复和一次幂等检查。
''';
      if (!dryRun) {
        await file.writeAsString(
          '${content.trimRight()}\n\n$block\n',
          flush: true,
        );
      }
      appended++;
    }
  }

  stdout.writeln('${dryRun ? '待补' : '已补'}项目交付物：$appended 篇，已存在跳过：$skipped 篇');
}
