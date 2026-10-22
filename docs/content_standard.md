# 内容标准（九段式教材、学习路径与元数据口径）

本文件是课程元数据的唯一口径说明。任何改动都应先改这里，再改工具与数据，
最后由 `tool/audit_content_governance.dart` 卡口校验。

## 1. 难度梯度

四档难度按学习顺序排列，`入门` 最浅、`高级` 最深：

| 难度 | 含义 | 典型形态 |
| --- | --- | --- |
| 入门 | 第一次接触该主题，只需要看懂概念与最小示例 | 第一个程序、变量与输入输出、条件判断 |
| 基础 | 完整掌握该主题的概念与语法主干 | 基础语法、数据结构、SQL、机器学习核心概念 |
| 进阶 | 能独立完成一个能力模块或工程化任务 | 并发、工程实践、性能优化、领域实战 |
| 高级 | 需要复合背景，或依赖真实集群/硬件/压测环境验证 | 分布式共识、内核、GPU 推理服务、企业级项目 |

唯一实现见 `tool/lesson_effort.dart` 的 `difficultyLadder` / `difficultyRank`。

## 2. 学习路径不变量

App 用 `manifest.json` 里每个课程的 `order` 字段渲染「推荐学习顺序」
（`lib/screens/category_screen.dart` 按 `order` 排序）。因此必须满足：

1. **order 连续**：同一分类内的 order 是 `0..n-1`，不重复、不留空号。
2. **难度不倒挂**：按 order 排序后，难度下标非递减。
3. **先修在前**：`prerequisites` 指向的课程必须排在本课之前。
4. **先修不难于本课**：`rank(先修) <= rank(本课)`；一条「入门课要求先学高级课」
   的边是数据错误，直接删除而不是保留。
5. **先修必须存在**：不允许悬空引用。

历史问题：多轮扩容把「零基础入门块」追加到分类末尾，并给块内第一课挂了该分类
最后一课（通常是高级课）作为先修，例如「Python 第一个脚本 ← Python 打包、发布
与性能」。`tool/rebalance_learning_path.dart` 会统一清理这类边，并按上述不变量
重建 order；该工具可重复执行（幂等）。

## 3. 预计用时

`minutes` 必须等于 `tool/lesson_effort.dart` 的 `estimateMinutes` 输出：

```
常规课 = 字数/480 + 代码块数×1.0 + 题数×0.8        （夹在 15~75 分钟）
实战课 = max(上式, 代码块数×5 + 20)                 （夹在 60~180 分钟）
最后四舍五入到 5 分钟
```

- 字数指**去掉空白**后的正文字符数；
- 代码块只统计带语言标记的围栏代码块，`text` 之类的纯输出块不计入；
- 实战课判定：id 含 `project`，或标题含「实战」；
- 头部元数据行统一为
  `> 内容更新时间：YYYY-MM-DD · 学习阶段：难度 · 预计用时：N 分钟`。

内容改动后需要重跑 `dart tool/rebalance_learning_path.dart`，
否则 `audit_content_governance.dart` 会以 `minutes_drift` 报错。

## 4. 章节结构（九段式教材）

每门课必须包含下面 9 个 `##` 核心章节，顺序固定、名称一致、同一课内不允许重复；
核心章节之后保留 5 个教材附录章节。`tool/apply_textbook_structure.dart` 负责把
历史内容按语义归入对应章节，代码块、配图、表格、术语与测验一律原样保留。

| 核心章节 | 作用 |
| --- | --- |
| 本节知识框架 | 课程定位、学习层次表、阅读路线与前后衔接 |
| 核心概念定义 | 术语的操作性定义、适用边界与定义用法 |
| 原理与运行机制 | 从定义到输出或结论的可复现过程 |
| 典型应用场景 | 适用与不适用场景、输入输出与失败路径 |
| 代码/协议/SQL 示例 | 本课最小可运行示例或结构化证据检查表 |
| 时间/空间复杂度或性能分析 | 复杂度证据、时间/空间/吞吐维度与测量方法 |
| 常见误区与易错点 | 易错点、常见表现与正确做法 |
| 与其他知识点的关系 | 先修、关联与同分类前后顺序 |
| 自测题与参考答案 | 抽取自题库的自测题、参考答案与解析 |

| 附录章节 | 作用 |
| --- | --- |
| 考点精讲 | 与题库一一对应的考点 |
| 术语速查 | 术语与一句话说明（不少于 4 条） |
| 参考资料与复核 | 可追溯的官方来源与复核信息 |
| 内容元数据 | 难度、用时与复核信息 |

历史章节（学习目标、前置知识、动手练习、考点精讲、故障现场、本课小结、
参考资料与复核、内容元数据、本课复习清单、术语速查、可运行练习、
常见错误与排查、复习与自测）不再以 `##` 标题出现：原文按语义
归入九段结构后保留为 `**教材衔接：<旧章节名>**` 小标题。旧章节名回到 `##`
层级会被 `tool/audit_content_governance.dart` 判为 error。

实现约定：

- 章节解析必须识别代码围栏（`tool/markdown_fences.dart`）：示例里的 `## 标题`
  只是被围栏包住的文本。判定按反引号数量配对，四反引号围栏里嵌套的三反引号
  代码块不会提前关闭外层围栏。
- 迁移前后代码围栏数量与配图数量只允许持平或增加，否则 `_validateRebuild`
  直接中止；H1 必须保持 `# <课程标题>`。
- 九段正文中的跨课通用句必须改写为带课程标题或关键词的表述：
  `_normalizeStructuredMarkdown` 负责归一化，治理与质量审计统计
  「正文重复段落类」，同类段落反复出现即触发卡口。
- 工具必须幂等：第二次执行 `dart tool/apply_textbook_structure.dart` 应为
  「教材化课程 0 篇，模板句归一化 0 篇，跳过 629 篇」。

## 5. 术语表与错误表（P2）

### 术语速查

- 每课必须有不少于 **4 条**术语，表头统一为 `| 术语 | 一句话说明 |`。
- 术语必须是本课真实出现的概念（语法关键字、机制名、模型名），
  不能是命令、代码片段、通用词（如「入门练习」）或课程标题本身。
- 说明必须是一句能独立读懂的解释，不引用测验题干，也不写「关键术语」这类空话。
- 入门课与项目实战课的词条由 `tool/rebuild_glossaries.dart` 的
  `curatedGlossaries` 人工维护，跑一次工具即可幂等写回 Markdown。

### 常见错误与排查（现位于「常见误区与易错点」）

- 统一使用三列表：`易错点 / 容易踩的做法 / 正确结论`。
- 人工复核过的表要在章节下写复核标记：
  `> 复核：已人工核对并重写（YYYY-MM-DD），每行对应本课的一个真实易错点。`
- P1 用测验题自动生成的表头 `| 题目 | 容易踩的做法 | 正确结论 |`
  再次出现即判为 `unreviewed_mistake_table`，必须重写后再保留。
- 复核表由 `tool/review_mistake_tables.dart` 维护，同样幂等。

### 故障现场（现位于「常见误区与易错点」）

- 每课保持 3 个 `### 现场 N：<本课具体问题>` 小标题，每个现场都要写全
  `症状 / 根因 / 修复 / 验证` 四段，内容必须来自本课的「常见错误与排查」
  表或课程关键词，不允许出现跨课复用的占位套话。
- 深挖章节的「正文出处」列会按 `现场 N：标题` 回引现场：标题改写后引用
  必须同步，长标题允许在引用处截断成「前缀…」，但不允许指错场景。
- 两条卡口都在 `tool/audit_content_governance.dart`：`generic_fault_scenario`
  拦跨课套话，`fault_reference_drift` 拦引用漂移。
- 内容改动后跑 `dart tool/rebuild_fault_scenarios.dart` 重建现场；该工具按
  本课错误表生成场景并同步深挖引用，第二次执行即为空操作。

### P0 收口：错误表、配图与复核排期

- 错误表作者工具 `tool/author_p0_mistake_tables.dart` 覆盖 215 门课，按课程数据
  重写三列表；重写时**保留章节里的非表格内容**（对照图、补充段落），避免
  再次出现「重写吃掉配图」。执行 `--dry-run` 为空操作即表示正文与数据一致。
- 单图课程补第二张图分两步：`tool/generate_p0_extra_diagrams.py` 生成
  `assets/content/images/p0x_<lessonId>.webp` 与批次文件
  `tool/image_batches/p0_extra.json`，再由
  `dart tool/insert_section_images.dart tool/image_batches/p0_extra.json`
  插到「本课小结」之前。生成脚本自带文字宽度测量，超出容器宽度会在检查脚本里报出。
- 复核日期按批次排期：`dart tool/schedule_review_batches.dart` 读取
  `docs/content_review_batches.json`，按「本轮改动优先 + 风险」排序，把
  `- 下次复核：YYYY-MM-DD` 分散到 12 个月，并写出
  `docs/content_review_schedule.md`。**排期不等于复核**：人工复核状态仍以
  `docs/content_review_records.json` 为准，没有记录就保持 pending。
- 正文去重：`dart tool/dedupe_repeated_sentences.dart` 压缩「同一行内重复 ≥ 3 次」
  的句子（历史生成缺陷），跨行重复的清单句不动。

### 待清理指标

治理报告里的 `glossary_template_rows` 统计旧模板残留行（同一说明被多个术语复用、
命令当术语等）。当前修复批次要求该指标为 0；它是 P3 清理目标，不再作为长期容忍项。

## 6. 校验入口

### 当前工具

| 命令 | 作用 |
| --- | --- |
| `dart tool/apply_textbook_structure.dart --dry-run` | 预览九段式迁移与模板句归一化，幂等 |
| `dart tool/rebalance_learning_path.dart --dry-run` | 预览先修、顺序、时长会怎么改 |
| `dart tool/rebuild_glossaries.dart --dry-run` | 预览术语表重建与表头统一 |
| `dart tool/review_mistake_tables.dart --dry-run` | 预览错误表复核重写 |
| `dart tool/rebuild_fault_scenarios.dart --dry-run` | 预览故障现场重建与深挖引用同步 |
| `dart tool/author_p0_mistake_tables.dart --dry-run` | 预览错误表重写（覆盖 215 门课） |
| `dart tool/dedupe_repeated_sentences.dart --dry-run` | 预览正文行内重复句压缩 |
| `dart tool/schedule_review_batches.dart --dry-run` | 预览人工复核分批排期 |
| `python tool/generate_p0_extra_diagrams.py` | 重新生成 67 张补全配图与插入批次 |
| `dart tool/audit_content_governance.dart` | 治理卡口：模板化、引用复用、难度/顺序/时长不变量 |
| `dart tool/audit_content_structure.dart` | 结构缺陷 |
| `dart tool/audit_content_quality.dart` | 题库质量与题型分布 |
| `flutter test test/content_test.dart` | 端上断言：order 连续、难度不倒挂、先修在前 |

### 历史工具（会回到旧 14 章结构，九段式改造后不要再对全库运行）

| 命令 | 作用 |
| --- | --- |
| `dart tool/unify_sections.dart --dry-run` | 旧的章节改名与补齐工具，仅用于查阅历史映射 |
| `dart tool/rebuild_lesson_study_sections.dart` | 旧的学习支架生成器，会写出 14 章标题 |
| `dart tool/thicken_*.dart`、`dart tool/diversify_*.dart` | 历史内容加厚工具，写入的是旧章节名 |
