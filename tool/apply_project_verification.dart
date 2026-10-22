// 项目课验证章节补全工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_project_verification.dart [--dry-run]
//
// 为所有项目/实战课程补「验证命令与预期输出」，让示例代码有可执行的验收方式。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String marker = '<!-- project-verification:v1 -->';

const Map<String, List<List<String>>> commands = <String, List<List<String>>>{
  'python': [
    ['安装依赖', 'python -m pip install -r requirements.txt', '依赖安装完成，没有版本冲突'],
    ['语法检查', 'python -m compileall .', '所有模块编译通过'],
    ['运行测试', 'python -m pytest -q', '测试全部通过，失败用例数为 0'],
    ['启动示例', 'python main.py', '服务启动并输出监听地址'],
  ],
  'cpp': [
    ['配置构建', 'cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug', '生成 CMake 缓存且无错误'],
    ['编译', 'cmake --build build --parallel', '目标全部编译成功且无警告'],
    ['运行测试', 'ctest --test-dir build --output-on-failure', '所有 CTest 用例通过'],
  ],
  'java': [
    ['编译', './mvnw -q -DskipTests package', '生成 JAR 且编译无错误'],
    ['运行测试', './mvnw test', 'JUnit 测试全部通过'],
    ['启动服务', 'java -jar target/app.jar', '端口监听成功并输出启动日志'],
  ],
  'javascript': [
    ['安装依赖', 'npm ci', '按锁文件安装，无缺失依赖'],
    ['运行测试', 'npm test', '测试全部通过'],
    ['构建', 'npm run build', '生成 dist 目录且没有构建错误'],
  ],
  'typescript': [
    ['安装依赖', 'npm ci', '依赖与锁文件一致'],
    ['类型检查', 'npx tsc --noEmit', '没有类型错误'],
    ['运行测试', 'npm test', '测试全部通过'],
    ['构建', 'npm run build', '产物生成成功'],
  ],
  'csharp': [
    ['还原依赖', 'dotnet restore', '依赖还原成功'],
    ['运行测试', 'dotnet test', '所有 xUnit 测试通过'],
    ['启动示例', 'dotnet run', '应用启动并输出预期结果'],
  ],
  'go': [
    ['格式化检查', 'gofmt -l .', '没有文件需要格式化'],
    ['静态检查', 'go vet ./...', '没有 vet 报告'],
    ['运行测试', 'go test ./... -count=1', '所有包测试通过'],
  ],
  'rust': [
    ['格式检查', 'cargo fmt --check', '没有格式差异'],
    ['静态检查', 'cargo clippy -- -D warnings', '没有 clippy 警告'],
    ['运行测试', 'cargo test', '所有测试通过'],
  ],
  'shell': [
    ['语法检查', 'bash -n script.sh', '脚本语法通过'],
    ['静态检查', 'shellcheck script.sh', '没有高危提示'],
    ['干跑验证', 'DRY_RUN=1 ./script.sh', '输出计划且不修改生产资源'],
  ],
  'flutter': [
    ['静态检查', 'flutter analyze', '无分析问题'],
    ['运行测试', 'flutter test', '测试全部通过'],
    ['构建', 'flutter build apk --release', '成功生成 APK'],
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
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final title = ((lesson['title'] as Map)['zh'] as String? ?? '');
      final id = lesson['id'] as String;
      if (!id.contains('project') &&
          !title.contains('实战') &&
          !title.contains('项目')) {
        continue;
      }
      final file = File(lesson['file'] as String);
      final content = await file.readAsString();
      if (content.contains('## 验证命令与预期输出') || content.contains(marker)) {
        skipped++;
        continue;
      }
      final rows = commands[categoryId] ?? commands['python']!;
      final block =
          '''$marker

## 验证命令与预期输出

项目代码不能只看“能编译”，还要能按固定命令复现结果。下表给出最低验证集：

| 阶段 | 命令 | 预期输出 |
| --- | --- | --- |
${rows.map((row) => '| ${row[0]} | `${row[1]}` | ${row[2]} |').join('\n')}

### 验收证据

- [ ] 保存依赖安装和启动命令的完整输出。
- [ ] 至少运行 3 条测试，其中包含一条非法输入或失败路径。
- [ ] 重复执行同一操作两次，确认没有重复写入或副作用。
- [ ] 记录一次失败状态码、错误日志和恢复步骤。
- [ ] 在 README 中写明环境版本、启动方式和回滚方式。

### 回归与回滚

1. 先在一个可丢弃的目录或临时数据库执行，避免污染真实数据。
2. 修改一处逻辑后重跑全部验证命令，确认没有回归。
3. 若失败，回滚到上一个可运行版本并保留失败日志。
4. 定位原因后补一条自动化测试，再重新执行发布流程。
5. 把教训写入项目复盘或本课笔记，形成下一次的检查项。
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

  stdout.writeln('${dryRun ? '待补' : '已补'}验证章节：$appended 篇，已存在跳过：$skipped 篇');
}
