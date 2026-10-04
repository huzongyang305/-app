// 专项内容补充工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_domain_supplement.dart
//
// 为安全、C、Kotlin、Swift 课程补充更贴合领域的工具链、检查表和落地步骤。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String marker = '<!-- domain-supplement:v1 -->';

const Map<String, List<List<String>>> toolchains = <String, List<List<String>>>{
  'c': [
    ['编译', 'gcc/clang -Wall -Wextra -Werror'],
    ['调试', 'gdb + core dump'],
    ['内存检查', 'AddressSanitizer / Valgrind'],
    ['构建发布', 'Makefile/CMake + 静态或动态链接'],
  ],
  'kotlin': [
    ['编译构建', 'kotlinc / Gradle'],
    ['测试', 'JUnit + coroutines-test'],
    ['静态检查', 'detekt / ktlint'],
    ['发布', 'R8/ProGuard + App Bundle'],
  ],
  'swift': [
    ['编译构建', 'swiftc / xcodebuild'],
    ['测试', 'XCTest + async 测试'],
    ['性能', 'Instruments / signpost'],
    ['发布', 'TestFlight + App Store 审核'],
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
    if (!const {'security', 'c', 'kotlin', 'swift'}.contains(categoryId)) {
      continue;
    }
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final file = File(lesson['file'] as String);
      final content = await file.readAsString();
      if (content.contains(marker)) {
        skipped++;
        continue;
      }
      final title =
          ((lesson['title'] as Map)['zh'] as String? ?? lesson['id'] as String);
      final keywords =
          (lesson['keywords'] as List?)
              ?.map((item) => item.toString())
              .take(4)
              .join('、') ??
          title;
      final block = categoryId == 'security'
          ? _securityBlock(title, keywords)
          : _languageBlock(categoryId, title, keywords);
      if (!dryRun) {
        await file.writeAsString(
          '${content.trimRight()}\n\n$block\n',
          flush: true,
        );
      }
      appended++;
    }
  }

  stdout.writeln('${dryRun ? '待补' : '已补'}专项内容：$appended 篇，已存在跳过：$skipped 篇');
}

String _securityBlock(String title, String keywords) {
  return '''$marker

## 安全落地补充：$title

### 一、资产、边界与信任

先回答：保护哪些数据、谁可以访问、哪些组件是信任边界、攻击者能从哪些入口进入。围绕「$keywords」列出至少 3 个入口和对应的最小权限。

### 二、威胁 → 控制 → 验证

| 威胁 | 预防控制 | 检测方式 | 验证证据 |
| --- | --- | --- | --- |
| 输入被污染 | schema、白名单、编码 | 异常输入日志和告警 | 越权与注入测试 |
| 权限过大 | 最小权限、临时凭证 | 权限审计和异常调用 | 权限边界测试 |
| 密钥泄露 | 密钥管理、轮换 | 仓库和日志扫描 | 轮换与影响范围记录 |
| 操作不可追溯 | 结构化审计日志 | 关键动作告警 | 审计查询和复盘 |
| 恢复失败 | 备份、回滚、演练 | 恢复指标监控 | 演练时间与数据校验 |

### 三、上线前安全清单

- [ ] 所有外部输入经过校验和输出编码。
- [ ] 认证、授权和会话失效逻辑有测试。
- [ ] 密钥不进入源码、镜像和日志。
- [ ] 依赖漏洞、许可证和来源已审查。
- [ ] 高风险操作有确认、审计和回滚。
- [ ] 安全事件有联系人和升级路径。

### 四、事件响应演练

构造一次凭证泄露或越权访问，按发现、隔离、轮换、取证、恢复、复盘六步执行，记录时间线和剩余风险。
''';
}

String _languageBlock(String categoryId, String title, String keywords) {
  final rows = toolchains[categoryId]!;
  return '''$marker

## 语言专项实践：$title

### 一、工具链

| 阶段 | 推荐工具 | 验收标准 |
| --- | --- | --- |
${rows.map((row) => '| ${row[0]} | ${row[1]} | 命令可复现且错误能被定位 |').join('\n')}

### 二、运行时与内存模型

围绕「$keywords」说明变量生命周期、资源释放、并发模型和错误传播。语言语法只是入口，真正决定行为的是运行时、标准库和平台约束。

### 三、测试策略

- 单元测试覆盖核心规则和边界。
- 集成测试覆盖文件、网络、数据库或平台 API。
- 失败测试覆盖超时、取消、异常和资源耗尽。
- 性能测试记录基线，避免只凭感觉优化。

### 四、发布检查

- [ ] 版本和依赖锁定，构建可复现。
- [ ] 产物经过签名、校验和最小权限配置。
- [ ] 日志不泄露密钥和个人信息。
- [ ] 有升级、回滚和故障恢复说明。
''';
}
