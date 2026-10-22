// P2 内容体验补全工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_p2_enrichment.dart [--dry-run]
//
// 为每篇教程补充英文概览、内容版本/适用环境元数据；
// 为项目/实战课程补充项目专属架构、数据模型与验收场景。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String marker = '<!-- p2-enrichment:v1 -->';
const String updatedAt = '2026-10-03';
const String contentVersion = '2.0';

const Map<String, String> environments = <String, String>{
  'flutter': 'Flutter 3.x / Dart 3.x',
  'html_css': '现代浏览器（Chrome/Firefox/Safari）',
  'python': 'Python 3.12+',
  'cpp': 'C++20 / GCC 13+ 或 Clang 17+',
  'c': 'C11 / GCC 或 Clang',
  'java': 'Java 21+ / Maven 或 Gradle',
  'kotlin': 'Kotlin 2.x / Android SDK',
  'swift': 'Swift 6 / Xcode 16+',
  'javascript': 'Node.js 22+ / 现代浏览器',
  'csharp': '.NET 9 / C# 13',
  'go': 'Go 1.24+',
  'rust': 'Rust 1.85+ / Cargo',
  'typescript': 'TypeScript 5.x / Node.js 22+',
  'shell': 'Bash 5 / POSIX Shell',
  'fundamentals': '通用计算机体系结构知识',
  'algorithms': '任意主流语言（伪代码与复杂度为主）',
  'network': 'TCP/IP、HTTP/2、HTTP/3 与现代网络栈',
  'database': 'PostgreSQL / MySQL / SQLite 等主流数据库',
  'os': 'Linux 6.x / POSIX',
  'toolchain': 'Git / Docker / Kubernetes / CI 平台',
  'ai': '主流大模型 API、开源模型与向量数据库',
  'distributed': '分布式系统与云原生基础设施',
  'software_engineering': '通用软件工程实践',
  'math': '线性代数、概率统计与优化基础',
  'cross_language': '九种主流语言生态横向对照',
  'visual_guide': '通用图解与系统原理',
  'project_practice': '通用项目交付流程',
  'security': 'OWASP、云原生与合规安全实践',
};

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
  var changed = 0;
  var skipped = 0;

  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final categoryId = category['id'] as String;
    final categoryTitleEn =
        ((category['title'] as Map)['en'] as String? ?? categoryId);
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final file = File(lesson['file'] as String);
      var content = await file.readAsString();
      if (content.contains(marker)) {
        skipped++;
        continue;
      }
      final titleZh =
          ((lesson['title'] as Map)['zh'] as String? ?? lesson['id'] as String);
      final titleEn = ((lesson['title'] as Map)['en'] as String? ?? titleZh);
      final summaryEn = ((lesson['summary'] as Map)['en'] as String? ?? '')
          .trim();
      final keywords =
          (lesson['keywords'] as List?)
              ?.map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .toList() ??
          <String>[];
      final difficulty = (lesson['difficulty'] as String? ?? '基础');
      final environment = environments[categoryId] ?? '通用开发环境';
      final isProject =
          lesson['id'].toString().contains('project') ||
          titleZh.contains('实战') ||
          titleZh.contains('项目');

      final buffer = StringBuffer()
        ..writeln(marker)
        ..writeln()
        ..writeln('## English Overview')
        ..writeln()
        ..writeln('**Title:** $titleEn')
        ..writeln()
        ..writeln('**Summary:** ${summaryEn.isEmpty ? titleEn : summaryEn}')
        ..writeln()
        ..writeln('**Category:** $categoryTitleEn  ')
        ..writeln('**Level:** $difficulty  ')
        ..writeln('**Key terms:** ${keywords.join(', ')}')
        ..writeln()
        ..writeln(
          '> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.',
        )
        ..writeln()
        ..writeln('## 内容元数据')
        ..writeln()
        ..writeln('- 内容版本：v$contentVersion')
        ..writeln('- 最后更新：$updatedAt')
        ..writeln('- 学习阶段：$difficulty')
        ..writeln('- 适用环境：$environment')
        ..writeln('- 内容来源：内置结构化课程与工程实践整理')
        ..writeln('- 相关主题：${keywords.join('、')}')
        ..writeln('- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全');

      if (isProject) {
        buffer
          ..writeln()
          ..writeln('## 项目专属规格：$titleZh')
          ..writeln()
          ..writeln('### 核心场景')
          ..writeln()
          ..writeln(
            '${((lesson['summary'] as Map)['zh'] as String? ?? '').trim()} 项目目标是把「${keywords.join('、')}」落实为可运行、可测试、可回滚的交付物。',
          )
          ..writeln()
          ..writeln('### 架构与数据流')
          ..writeln()
          ..writeln('```text')
          ..writeln('用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控')
          ..writeln('                         ↘ 失败分类 → 重试/补偿 → 回滚')
          ..writeln('```')
          ..writeln()
          ..writeln('### 最小数据模型')
          ..writeln()
          ..writeln('| 对象 | 关键字段 | 约束 |')
          ..writeln('| --- | --- | --- |')
          ..writeln(
            '| 输入实体 | ${keywords.isNotEmpty ? keywords[0] : '请求'}、时间、来源 | 必填校验、长度限制、幂等键 |',
          )
          ..writeln('| 任务实体 | 状态、优先级、创建时间 | 状态迁移合法、不可重复执行 |')
          ..writeln('| 结果实体 | 输出、错误码、耗时 | 可序列化、错误可解释 |')
          ..writeln('| 审计记录 | 操作者、动作、结果、时间 | 不可篡改、可查询、脱敏 |')
          ..writeln()
          ..writeln('### 验收场景')
          ..writeln()
          ..writeln('1. 正常路径：最小输入得到预期输出，并留下日志与指标。')
          ..writeln('2. 边界路径：空值、最大值、重复数据和超长内容得到明确处理。')
          ..writeln('3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。')
          ..writeln('4. 幂等路径：同一请求执行两次不会产生重复副作用。')
          ..writeln('5. 回滚路径：回滚后数据一致，且能说明恢复时间和影响范围。');
      }

      if (!dryRun) {
        content = '${content.trimRight()}\n\n$buffer\n';
        await file.writeAsString(content, flush: true);
      }
      changed++;
    }
  }

  if (!dryRun) {
    manifest['content_version'] = contentVersion;
    manifest['content_updated_at'] = updatedAt;
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      flush: true,
    );
  }
  stdout.writeln('${dryRun ? '待补充' : '已补充'}：$changed 篇，已存在跳过：$skipped 篇');
}
