// 最小可运行示例补全工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_minimal_code_examples.dart [--dry-run]
//
// 为没有编程语言代码块的课程补一个最小示例、预期输出和验证步骤。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String marker = '<!-- minimal-code:v1 -->';

const Map<String, List<String>> examples = <String, List<String>>{
  'ai': [
    'python',
    'def score(answer: str) -> int:\n    return 1 if answer.strip() else 0\n\nprint(score("agent"))',
    '1',
  ],
  'security': [
    'python',
    'import hashlib\n\ndigest = hashlib.sha256(b"password").hexdigest()\nprint(digest[:12])',
    '5e884898da28',
  ],
  'network': [
    'python',
    'import socket\n\nprint(socket.gethostbyname("localhost"))',
    '127.0.0.1',
  ],
  'database': ['sql', 'SELECT 2 + 3 AS result;', 'result = 5'],
  'os': [
    'python',
    'import os\n\nprint("pid>0:", os.getpid() > 0)',
    'pid>0: True',
  ],
  'algorithms': [
    'python',
    'def linear_search(items, target):\n    for index, item in enumerate(items):\n        if item == target:\n            return index\n    return -1\n\nprint(linear_search([3, 5, 8], 8))',
    '2',
  ],
  'fundamentals': [
    'python',
    'print(bin(10), hex(255), 0b1010)',
    '0b1010 0xff 10',
  ],
  'toolchain': [
    'bash',
    '#!/usr/bin/env bash\nset -euo pipefail\necho "toolchain-ok"',
    'toolchain-ok',
  ],
  'distributed': [
    'bash',
    '#!/usr/bin/env bash\nset -euo pipefail\ncurl -fsS http://127.0.0.1:8080/health || echo "service-down"',
    '{"status":"ok"} 或 service-down',
  ],
  'software_engineering': [
    'python',
    'def test_add():\n    assert 2 + 3 == 5\n\ntest_add()\nprint("test passed")',
    'test passed',
  ],
  'math': ['python', 'import math\n\nprint(round(math.sqrt(2), 4))', '1.4142'],
  'cross_language': ['python', 'print("python", 2 + 3)', 'python 5'],
  'visual_guide': [
    'python',
    'steps = ["input", "process", "output"]\nprint(" -> ".join(steps))',
    'input -> process -> output',
  ],
  'flutter': ['dart', 'void main() {\n  print(2 + 3);\n}', '5'],
  'html_css': ['html', '<button type="button">提交</button>', '页面显示一个可点击的“提交”按钮'],
  'project_practice': [
    'bash',
    '#!/usr/bin/env bash\nset -euo pipefail\necho "deliverable-ok"',
    'deliverable-ok',
  ],
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
    final example = examples[categoryId] ?? examples['fundamentals']!;
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final file = File(lesson['file'] as String);
      final content = await file.readAsString();
      final hasCode = RegExp(
        r'^```(?!text|markdown)[A-Za-z0-9_+-]+',
        multiLine: true,
      ).hasMatch(content);
      if (hasCode || content.contains(marker)) {
        skipped++;
        continue;
      }
      final title =
          ((lesson['title'] as Map)['zh'] as String? ?? lesson['id'] as String);
      final block =
          '''$marker

## 最小可运行示例

下面示例用于验证「$title」的最小输入、处理和输出。先原样运行，再只修改一个值：

```${example[0]}
${example[1]}
```

## 预期输出

```text
${example[2]}
```

## 验证步骤

1. 记录运行环境、命令和真实输出。
2. 修改一个输入，先写预测再运行。
3. 制造一次错误输入，记录错误信息与修复方式。
4. 把结论写回本课笔记或测试用例。
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

  stdout.writeln('${dryRun ? '待补' : '已补'}最小示例：$appended 篇，已有代码或跳过：$skipped 篇');
}
