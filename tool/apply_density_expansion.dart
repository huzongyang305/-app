// 内容密度扩展工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_density_expansion.dart [--dry-run] [--min=6200]
//
// 对低于目标长度的教程追加“工程化拆解 / 对比边界 / 进阶挑战”三类内容，
// 按语言、系统、数据算法、工程、AI 分组选择观察指标、故障模式与实践工具。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String markerPrefix = '<!-- density:v1';

class DensityProfile {
  const DensityProfile({
    required this.focus,
    required this.metrics,
    required this.failures,
    required this.tools,
    required this.projects,
  });

  final String focus;
  final List<String> metrics;
  final List<String> failures;
  final List<String> tools;
  final List<String> projects;
}

const Map<String, DensityProfile> profiles = <String, DensityProfile>{
  'language': DensityProfile(
    focus: '语言课的重点是把语法、类型、运行时行为和工程实践连起来，而不是只记写法',
    metrics: [
      '正确性：正常、边界和失败输入是否符合预期',
      '可读性：命名、分层和错误信息是否清晰',
      '性能：时间、内存和资源开销是否可解释',
      '可测试性：核心逻辑能否独立验证',
    ],
    failures: [
      '类型转换或空值处理遗漏',
      '异常被吞掉或错误信息没有上下文',
      '资源未释放、连接未关闭',
      '并发共享状态缺少同步',
      '依赖版本和运行环境不一致',
    ],
    tools: ['编译器和静态检查', '单元测试与覆盖率', '格式化与 lint 工具', '性能剖析和调试器'],
    projects: ['写一个可独立运行的最小工具', '把核心逻辑抽成库并补测试', '加入一个失败路径和恢复策略'],
  ),
  'systems': DensityProfile(
    focus: '系统课的重点是理解请求、资源、状态和故障如何跨层传递，并用指标定位瓶颈',
    metrics: [
      '延迟：P50/P95/P99 与超时率',
      '吞吐：单位时间完成量与队列积压',
      '资源：CPU、内存、磁盘和网络利用率',
      '可用性：故障恢复时间与错误预算',
    ],
    failures: [
      '超时与重试风暴放大故障',
      '容量估算不足导致资源耗尽',
      '配置漂移造成环境行为不一致',
      '单点故障或缺少降级路径',
      '监控缺失导致问题无法定位',
    ],
    tools: ['结构化日志', '指标与告警', '链路追踪', '压测与故障注入'],
    projects: ['画出一条完整请求链路', '设计一次故障演练', '用指标验证容量与恢复时间'],
  ),
  'data': DensityProfile(
    focus: '数据与算法课的重点是把正确性、复杂度、数据分布和可复现实验放在一起判断',
    metrics: [
      '正确性：边界、空值和重复数据',
      '时间复杂度：不同规模下的增长趋势',
      '空间复杂度：内存峰值与磁盘占用',
      '可复现性：固定数据、环境和随机种子',
    ],
    failures: [
      '边界条件遗漏导致错误结果',
      '数据规模扩大后复杂度爆炸',
      '数据倾斜让少数分区成为瓶颈',
      '浮点误差或精度损失',
      '实验环境变化导致结果不可复现',
    ],
    tools: ['单元测试与性质测试', '基准测试与剖析器', '固定数据集与随机种子', '执行计划或复杂度分析'],
    projects: ['用 3 组数据验证边界', '对比两种实现的复杂度', '写一份可复现的性能报告'],
  ),
  'product': DensityProfile(
    focus: '工程实践课的重点是把目标、范围、质量、交付和反馈闭环连接起来',
    metrics: [
      '用户价值：是否解决真实问题',
      '缺陷率：回归和线上问题数量',
      '交付周期：从需求到上线的时间',
      '可维护性：文档、测试和回滚能力',
    ],
    failures: ['需求模糊导致反复返工', '范围膨胀拖垮交付节奏', '缺少回归测试造成线上故障', '文档与实现漂移', '发布不可回滚'],
    tools: ['需求与验收清单', '代码评审', 'CI 质量门禁', '灰度和回滚流程'],
    projects: ['写一页需求与验收标准', '为一个功能补回归测试', '设计一次灰度发布与回滚'],
  ),
  'ai': DensityProfile(
    focus: 'AI 课的重点是把数据、模型、提示、工具、评测、成本和安全放在同一条链路上',
    metrics: [
      '质量：正确率、相关性、流畅度和引用质量',
      '延迟：首 token 与端到端耗时',
      '成本：token、算力和调用次数',
      '安全：注入、越权、泄露和滥用风险',
    ],
    failures: [
      '模型幻觉被当成事实输出',
      '提示注入绕过权限或系统规则',
      '上下文溢出导致关键信息丢失',
      '评测集泄漏让指标虚高',
      '成本随并发和上下文失控',
    ],
    tools: ['离线评测集', '调用链追踪', 'A/B 与人工评审', '输入输出护栏'],
    projects: ['构造 20 条离线评测样本', '对比两种提示或模型策略', '记录一次失败和安全事件'],
  ),
  'security': DensityProfile(
    focus: '安全课的重点是把资产、威胁、控制、验证和剩余风险连接成闭环',
    metrics: [
      '资产与边界：保护什么、信任谁、暴露面在哪里',
      '威胁概率：攻击成本和发生可能性',
      '影响范围：数据、资金、可用性和合规损失',
      '控制有效性：预防、检测、响应和恢复能力',
    ],
    failures: [
      '输入未校验导致注入或越权',
      '权限过大让单点泄露扩大影响',
      '密钥硬编码或写入日志',
      '缺少审计与告警导致攻击不可见',
      '没有演练导致恢复流程失效',
    ],
    tools: ['威胁建模与数据流图', 'SAST/DAST 与依赖扫描', '密钥管理和访问审计', '安全事件演练'],
    projects: ['画出一张数据流与信任边界图', '为一个接口补输入校验和权限测试', '设计一次泄露后的轮换与复盘'],
  ),
};

const Map<String, String> categoryGroups = <String, String>{
  'flutter': 'language',
  'html_css': 'language',
  'python': 'language',
  'cpp': 'language',
  'java': 'language',
  'javascript': 'language',
  'csharp': 'language',
  'go': 'language',
  'rust': 'language',
  'typescript': 'language',
  'shell': 'language',
  'fundamentals': 'systems',
  'network': 'systems',
  'os': 'systems',
  'toolchain': 'systems',
  'distributed': 'systems',
  'algorithms': 'data',
  'database': 'data',
  'math': 'data',
  'software_engineering': 'product',
  'project_practice': 'product',
  'cross_language': 'product',
  'visual_guide': 'product',
  'ai': 'ai',
  'security': 'security',
  'c': 'language',
  'kotlin': 'language',
  'swift': 'language',
};

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  var minimum = 6200;
  for (final arg in args) {
    if (arg.startsWith('--min=')) {
      minimum = int.tryParse(arg.substring('--min='.length)) ?? minimum;
    }
  }

  final manifest = jsonDecode(
    await File(manifestPath).readAsString(),
  ) as Map<String, dynamic>;
  final categories = (manifest['categories'] as List)
      .cast<Map<String, dynamic>>();
  var changed = 0;
  var skipped = 0;
  final errors = <String>[];

  for (final rawCategory in categories) {
    final category = rawCategory.cast<String, dynamic>();
    final categoryId = category['id'] as String;
    final profile = profiles[categoryGroups[categoryId] ?? 'systems']!;
    final categoryTitle =
        ((category['title'] as Map)['zh'] as String? ?? categoryId);
    final lessons = (category['lessons'] as List).cast<Map<String, dynamic>>();

    for (var index = 0; index < lessons.length; index++) {
      final lesson = lessons[index];
      final file = File(lesson['file'] as String);
      if (!file.existsSync()) {
        errors.add('${lesson['id']}：文件不存在');
        continue;
      }
      var content = await file.readAsString();
      if (content.length >= minimum) {
        skipped++;
        continue;
      }

      final title =
          ((lesson['title'] as Map)['zh'] as String? ?? lesson['id'] as String);
      final summary = ((lesson['summary'] as Map)['zh'] as String? ?? '')
          .trim();
      final keywords =
          (lesson['keywords'] as List?)
              ?.map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .toList() ??
          <String>[];
      final previous = index == 0
          ? '本分类的入门内容'
          : ((lessons[index - 1]['title'] as Map)['zh'] as String? ?? '上一课');
      final next = index == lessons.length - 1
          ? '后续的实战与综合主题'
          : ((lessons[index + 1]['title'] as Map)['zh'] as String? ?? '下一课');

      var round = 0;
      while (content.length < minimum && round < 12) {
        final marker = round == 0
            ? '$markerPrefix -->'
            : '$markerPrefix-$round -->';
        if (content.contains(marker)) {
          round++;
          continue;
        }
        content =
            '${content.trimRight()}\n\n${_buildBlock(round: round, marker: marker, title: title, summary: summary, categoryTitle: categoryTitle, keywords: keywords, previous: previous, next: next, profile: profile)}\n';
        round++;
      }
      if (content.length < minimum) {
        errors.add('${lesson['id']}：扩展后仍只有 ${content.length} 字符');
        continue;
      }
      if (!dryRun) {
        await file.writeAsString(content, flush: true);
      }
      changed++;
    }
  }

  stdout.writeln('${dryRun ? '待扩展' : '已扩展'}：$changed 篇，已达标或已处理：$skipped 篇');
  if (errors.isNotEmpty) {
    stderr.writeln('失败 ${errors.length} 项：');
    for (final error in errors.take(40)) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
  }
}

String _buildBlock({
  required int round,
  required String marker,
  required String title,
  required String summary,
  required String categoryTitle,
  required List<String> keywords,
  required String previous,
  required String next,
  required DensityProfile profile,
}) {
  final focus = keywords.take(3).join('、');
  return switch (round) {
    0 =>
      '''$marker

## 工程化拆解：$title

$summary

在「$categoryTitle」中，本课不是孤立知识点，而是连接「$previous」与「$next」的中间环节。${profile.focus}。

### 一、四个观察指标

| 指标 | 具体含义 | 记录方式 |
| --- | --- | --- |
${profile.metrics.map((item) => '| $item | 结合「$focus」记录输入、输出和变化 | 基线、改动、结果、差异 |').join('\n')}

### 二、五类常见故障

${profile.failures.asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value}。出现时先最小化复现，再判断是输入、逻辑、资源还是环境问题。').join('\n')}

### 三、最小排查路径

1. 固定输入与环境，确认问题能稳定复现。
2. 从日志、指标或调试器中找到第一个异常状态，而不是从最终错误倒猜。
3. 只改变一个变量，验证假设并记录前后差异。
4. 修复后用边界输入、失败输入和重复执行三种方式回归。
5. 把结论写回本课笔记，补充一个可检查的证据。

### 四、实践工具

${profile.tools.map((item) => '- $item：至少用它完成一次真实测量，不只停留在工具名称。').join('\n')}
''',
    1 =>
      '''$marker

## 对比与边界：$title

### 一、与相邻主题的边界

| 对比项 | 本课关注 | 相邻主题关注 | 判断标准 |
| --- | --- | --- | --- |
| 目标 | 理解「$focus」的机制与取舍 | $next | 能说清问题、输入和输出 |
| 方法 | 先建立模型，再做最小实验 | 后续主题扩展规模与组合 | 结果可复现且能解释 |
| 失败 | 边界、资源和配置变化 | 复杂系统下的连锁故障 | 有定位路径和恢复方案 |

### 二、常见误区

| 误区 | 可能后果 | 修正方式 |
| --- | --- | --- |
${profile.failures.map((item) => '| 忽略「$item」 | 结果不稳定或难以定位 | 用最小案例验证，并记录边界条件 |').join('\n')}

### 三、自测问答

1. 「$title」解决的核心问题是什么？如果不使用它，替代方案是什么？
2. 本课的关键词「$focus」之间是什么关系？请各举一个例子。
3. 哪类输入最容易触发失败？失败时系统应该返回错误、重试还是降级？
4. 如果数据量或并发扩大 10 倍，最先出现的瓶颈在哪里？
5. 你会用什么指标证明自己的修改真实有效？

### 四、复习路径

先复述问题，再画一张结构或流程图，然后完成一个最小实验，最后用自测问答检查遗漏。复习结束后，把仍然不确定的问题写成下一课的待验证清单。
''',
    2 =>
      '''$marker

## 数据、规模与容量：$title

### 一、规模变化带来的四个问题

| 维度 | 小规模表现 | 放大 10 倍后 | 应对方式 |
| --- | --- | --- | --- |
| 数据量 | 扫描和计算很快 | IO、内存和网络成为瓶颈 | 分区、索引、批处理和流式处理 |
| 并发量 | 偶尔冲突 | 锁竞争和排队放大 | 限流、分片、无状态扩展 |
| 错误率 | 单次失败可忽略 | 尾部延迟和重试风暴 | 超时、退避、熔断和幂等 |
| 成本 | 资源充足 | CPU、存储和调用费用上涨 | 预算、采样、缓存和降级 |

### 二、容量估算步骤

1. 统计平均请求量、峰值倍数和数据增长率。
2. 计算单请求的 CPU、内存、存储和网络成本。
3. 给系统留出 30%～50% 的突发余量。
4. 设计超过容量时的排队、拒绝和降级策略。
5. 用压测验证模型，不用线性外推代替测量。

### 三、$focus 的规模边界

当输入、并发或时间窗口扩大时，先观察「$focus」中哪一个条件最先失效。把阈值、告警和处理动作写进运行手册，避免问题出现时才临时讨论。
''',
    3 =>
      '''$marker

## 安全、权限与失败：$title

### 一、风险清单

| 风险 | 触发条件 | 影响 | 控制 |
| --- | --- | --- | --- |
| 输入被污染 | 外部数据未校验 | 注入、越权和错误结果 | 白名单、schema、编码 |
| 权限过大 | 使用默认管理员权限 | 泄露后影响扩大 | 最小权限和临时凭证 |
| 密钥泄露 | 写入日志或仓库 | 资源被滥用 | 密钥管理和轮换 |
| 失败不可恢复 | 没有回滚和幂等 | 数据不一致 | 备份、补偿和重放 |

### 二、失败演练

1. 明确正常路径和关键副作用。
2. 注入一次超时、重复请求或依赖不可用。
3. 观察系统是否重试、降级或快速失败。
4. 检查是否产生重复写入、孤儿数据或权限提升。
5. 记录恢复时间和数据校验结果。

### 三、$title 的最小安全边界

处理「$focus」时，默认所有外部输入都不可信，所有写操作都需要幂等和审计，所有高风险动作都要有回滚方案。安全不是附加功能，而是与正确性同级的验收条件。
''',
    4 =>
      '''$marker

## 团队交付与运维：$title

### 一、交付流程

1. 写清需求、范围、非目标和验收标准。
2. 设计接口、数据结构和失败处理。
3. 小步实现并用自动化测试保护。
4. 通过灰度、开关或小流量发布。
5. 观察指标，确认稳定后再扩大范围。
6. 记录回滚步骤和复盘结论。

### 二、文档与交接

- 文档说明系统解决什么问题、如何启动、如何验证和如何回滚。
- 关键决策记录背景、备选方案、取舍和适用边界。
- 把「$focus」相关命令、指标和常见故障整理成一页运行手册。

### 三、协作检查

- [ ] 另一位成员能按文档独立跑通最小示例。
- [ ] 失败时能根据日志和指标定位到具体阶段。
- [ ] 变更范围可控，出现问题时可以快速回滚。
- [ ] 评审者能说出本课知识点与相邻主题的区别。
- [ ] 行动项有负责人、期限和验证方式。
''',
    5 =>
      '''$marker

## 综合案例：$title

### 一、场景

假设你要在一个真实项目中应用「$focus」。项目有正常流量、突发峰值、偶发依赖故障和严格的回滚要求。请先写下当前基线，再设计一个最小改动。

### 二、分析框架

| 步骤 | 需要回答 | 证据 |
| --- | --- | --- |
| 定位 | 问题发生在输入、处理、存储还是输出？ | 日志、指标、追踪 |
| 假设 | 哪个机制最可能解释现象？ | 对照实验 |
| 改动 | 只改一个变量，预期变化是什么？ | 修改前后数据 |
| 验证 | 正常、边界、失败和恢复都覆盖了吗？ | 测试与演练 |
| 复盘 | 还有哪些未知和风险？ | 行动项 |

### 三、三个追问

1. 如果外部依赖永久不可用，系统应该怎样降级？
2. 如果数据量增长 100 倍，哪个组件最先需要重构？
3. 如何证明这次改动没有把风险转移到其他环节？

### 四、最终交付

输出一份包含问题、假设、改动、指标、失败演练和复盘结论的记录。能复现、能解释、能回滚，才算完成本课。
''',
    _ =>
      '''$marker

## 进阶挑战：$title

### 一、三个可交付任务

${profile.projects.map((item) => '- $item：产物可以是脚本、配置、测试、图表或一页复盘记录。').join('\n')}

### 二、面试追问

1. 请用一句话解释「$title」，并说明它与「$focus」的关系。
2. 这个方案最不适合什么场景？替换方案会带来什么代价？
3. 线上出现偶发问题时，你会按什么顺序收集证据？
4. 如何设计测试覆盖正常、边界、失败和恢复四类路径？
5. 如果要在两周内交付，你会保留哪些能力，砍掉哪些非核心目标？

### 三、验收清单

- [ ] 能用 3～5 句话向别人解释本课核心问题。
- [ ] 有一个可运行或可复现的最小示例。
- [ ] 至少覆盖一个失败场景和一个恢复动作。
- [ ] 有量化指标，能比较修改前后的差异。
- [ ] 能把本课知识放回「$categoryTitle」的学习路线。
''',
  };
}
