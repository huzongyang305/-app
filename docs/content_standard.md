# 内容标准（P0 学习路径与元数据口径）

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

## 4. 校验入口

| 命令 | 作用 |
| --- | --- |
| `dart tool/rebalance_learning_path.dart --dry-run` | 预览先修、顺序、时长会怎么改 |
| `dart tool/audit_content_governance.dart` | 治理卡口：模板化、引用复用、难度/顺序/时长不变量 |
| `dart tool/audit_content_structure.dart` | 结构缺陷 |
| `dart tool/audit_content_quality.dart` | 题库质量与题型分布 |
| `flutter test test/content_test.dart` | 端上断言：order 连续、难度不倒挂、先修在前 |
