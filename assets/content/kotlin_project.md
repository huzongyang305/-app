# 实战：Kotlin Android 客户端

![实战：Kotlin Android 客户端](images/lesson_kotlin_project.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：130 分钟

## 学习目标

- 能用自己的话解释：把界面状态建模为加载、成功、空、失败四种，避免多个布尔值互相冲突。
- 能用自己的话解释：网络层要有超时、重试、缓存和错误映射，UI 只消费领域结果。
- 能用自己的话解释：项目验收要覆盖旋转、断网、重复请求和进程恢复。
- 能把本课知识放回「Kotlin」，并完成练习与测验。

## 前置知识

- 已完成「Kotlin」的基础课程，能运行正文中的最小示例。
- 本课关键词：Android 项目、网络、缓存、状态。
- 遇到不熟悉的术语先记录问题，完成练习后再回读。

## 核心知识

### 1. 把界面状态建模为加载、成功、空、失败四种，避免多个布尔值互相冲突。

- 它解决的问题：把「把界面状态建模为加载、成功、空、失败四种，避免多个布尔值互相冲突。」放回真实场景，说明不做它会带来什么后果。
- 关键做法：先用最小示例建立基线，再逐步加入边界、失败和性能条件。
- 验证标准：结果可复现、错误可解释、边界有测试、失败能恢复。

### 2. 网络层要有超时、重试、缓存和错误映射，UI 只消费领域结果。

- 它解决的问题：把「网络层要有超时、重试、缓存和错误映射，UI 只消费领域结果。」放回真实场景，说明不做它会带来什么后果。
- 关键做法：先用最小示例建立基线，再逐步加入边界、失败和性能条件。
- 验证标准：结果可复现、错误可解释、边界有测试、失败能恢复。

### 3. 项目验收要覆盖旋转、断网、重复请求和进程恢复。

- 它解决的问题：把「项目验收要覆盖旋转、断网、重复请求和进程恢复。」放回真实场景，说明不做它会带来什么后果。
- 关键做法：先用最小示例建立基线，再逐步加入边界、失败和性能条件。
- 验证标准：结果可复现、错误可解释、边界有测试、失败能恢复。

## 关键流程

```text
输入 → 校验 → 核心处理 → 验证 → 记录指标 → 失败恢复
```

## 实践路径

1. 用一句话复述本课要解决的问题。
2. 跑通正文中的最小示例并记录基线。
3. 只改变一个输入或参数，预测并验证结果。
4. 补一个失败路径，记录错误、恢复和指标。
5. 把结论写成可复现的笔记或测试。

## 常见误区

| 误区 | 后果 | 修正 |
| --- | --- | --- |
| 只记术语不做实验 | 遇到真实问题无法判断 | 用最小输入跑通并记录结果 |
| 只测正常路径 | 边界和故障上线才暴露 | 补空值、极值和依赖失败 |
| 没有基线就优化 | 无法证明改进有效 | 先测量再修改 |
| 忽略成本与安全 | 性能和风险失控 | 同时记录资源、权限与失败代价 |

## 动手练习

1. 合上教程，用 3～5 句话解释「实战：Kotlin Android 客户端」。
2. 从正文选一个例子，改变一个条件并预测结果。
3. 设计一个失败场景，写出止损与恢复步骤。

**验收标准**：留下输入、命令、输出、差异和下一步问题。

## 本课小结

- 本课属于「Kotlin」，核心关键词是 Android 项目、网络、缓存、状态。
- 先保证正确与可复现，再讨论性能和扩展。
- 完成练习和测验后，把仍然不确定的问题写成下一轮验证清单。

> 本课由 P1 内容扩展生成，重点补充原有课程缺失的主题与工程边界。


## 验证命令与预期输出

项目代码不能只看“能编译”，还要能按固定命令复现结果。下表给出最低验证集：

| 阶段 | 命令 | 预期输出 |
| --- | --- | --- |
| 安装依赖 | `python -m pip install -r requirements.txt` | 依赖安装完成，没有版本冲突 |
| 语法检查 | `python -m compileall .` | 所有模块编译通过 |
| 运行测试 | `python -m pytest -q` | 测试全部通过，失败用例数为 0 |
| 启动示例 | `python main.py` | 服务启动并输出监听地址 |

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


## 语言专项实践：实战：Kotlin Android 客户端

### 一、工具链

| 阶段 | 推荐工具 | 验收标准 |
| --- | --- | --- |
| 编译构建 | kotlinc / Gradle | 命令可复现且错误能被定位 |
| 测试 | JUnit + coroutines-test | 命令可复现且错误能被定位 |
| 静态检查 | detekt / ktlint | 命令可复现且错误能被定位 |
| 发布 | R8/ProGuard + App Bundle | 命令可复现且错误能被定位 |

### 二、运行时与内存模型

围绕「Android 项目、网络、缓存、状态」说明变量生命周期、资源释放、并发模型和错误传播。语言语法只是入口，真正决定行为的是运行时、标准库和平台约束。

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


## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：关于「把界面状态建模为加载、成功、空、失败…」，下列说法正确的是？

- **正确判断**：把界面状态建模为加载、成功、空、失败四种，避免多个布尔值互相冲突。
- **判断依据**：正确答案是「把界面状态建模为加载、成功、空、失败四种，避免多个布尔值互相冲突。」，本课在「项目专属规格：实战：Kotlin Android 客户端」中说明：实现列表、详情、网络、缓存、加载状态和错误恢复。，本课在「核心知识」中说明：它解决的问题：把把界面状态建模为加载、成功、空、失败四种，避免多个布尔值互相冲突。，本课在「本课小结」中说明：本课属于「Kotlin」，核心关键词是 Android 项目、网络、缓存、状态。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：关于「网络层要有超时、重试、缓存和错误映射…」，下列说法正确的是？

- **正确判断**：网络层要有超时、重试、缓存和错误映射，UI 只消费领域结果。
- **判断依据**：正确答案是「网络层要有超时、重试、缓存和错误映射，UI 只消费领域结果。」，本课在「项目专属规格：实战：Kotlin Android 客户端」中说明：实现列表、详情、网络、缓存、加载状态和错误恢复。，本课在「核心知识」中说明：它解决的问题：把网络层要有超时、重试、缓存和错误映射，UI 只消费领域结果。，本课在「核心知识」中说明：它解决的问题：把把界面状态建模为加载、成功、空、失败四种，避免多个布尔值互相冲突。本课还在「本课小结」中说明：本课属于「Kotlin」，核心关键词是 Android 项目、网络、缓存、状态。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 3：关于「项目验收要覆盖旋转、断网、重复请求和…」，下列说法正确的是？

- **正确判断**：项目验收要覆盖旋转、断网、重复请求和进程恢复。
- **判断依据**：正确答案是「项目验收要覆盖旋转、断网、重复请求和进程恢复。」，本课在「核心知识」中说明：它解决的问题：把网络层要有超时、重试、缓存和错误映射，UI 只消费领域结果。，本课在「本课小结」中说明：本课属于「Kotlin」，核心关键词是 Android 项目、网络、缓存、状态。，本课在核心知识中说明：它解决的问题：把项目验收要覆盖旋转、断网、重复请求和进程恢复。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 4：「实战：Kotlin Android 客户端」的核心学习目标是什么？

- **正确判断**：实现列表、详情、网络、缓存、加载状态和错误恢复。
- **判断依据**：正确答案是「实现列表、详情、网络、缓存、加载状态和错误恢复。」，本课在「核心知识」中说明：它解决的问题：把把界面状态建模为加载、成功、空、失败四种，避免多个布尔值互相冲突。，本课在核心知识中说明：它解决的问题：把网络层要有超时、重试、缓存和错误映射，UI 只消费领域结果。，本课在核心知识中说明：它解决的问题：把项目验收要覆盖旋转、断网、重复请求和进程恢复。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 5：补全代码：「实战：Kotlin Android 客户端」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `"project": "____",`

- **正确判断**：kotlin_project
- **判断依据**：正确答案是「kotlin_project」，本课在「本课小结」中说明：本课属于「Kotlin」，核心关键词是 Android 项目、网络、缓存、状态。本课还在核心知识中说明：它解决的问题：把网络层要有超时、重试、缓存和错误映射，UI 只消费领域结果。本课还在「核心知识」中说明：它解决的问题：把项目验收要覆盖旋转、断网、重复请求和进程恢复。
- **迁移检查**：不看题干，用自己的话补全这句话，再与标准答案对照。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「关于「把界面状态建模为加载、成功、空、失败…」，下列说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「关于「网络层要有超时、重试、缓存和错误映射…」，下列说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「关于「项目验收要覆盖旋转、断网、重复请求和…」，下列说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「「实战：Kotlin Android 客户端」的核心学习目标是什么？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「实战：Kotlin Android 客户端」示例中，下面这行代码缺少…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把本课反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `python -m compileall .` | \| 语法检查 \| `python -m compileall .` \| 所有模块编译通过 \| |
| `python -m pytest -q` | \| 运行测试 \| `python -m pytest -q` \| 测试全部通过，失败用例数为 0 \| |
| `python main.py` | \| 启动示例 \| `python main.py` \| 服务启动并输出监听地址 \| |
| `Android 项目` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `网络` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `缓存` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `状态` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：关于「把界面状态建模为加载、成功、空、失败…」，下列说法正确的是？

**参考回答**：正确答案是「把界面状态建模为加载、成功、空、失败四种，避免多个布尔值互相冲突。」，本课在「核心知识」中说明：它解决的问题：把把界面状态建模为加载、成功、空、失败四种，避免多个布尔值互相冲突。，本课在「本课小结」中说明：本课属于「Kotlin」，核心关键词是 Android 项目、网络、缓存、状态。，本课在「项目专属规格：实战：Kotlin Android 客户端」中说明：实现列表、详情、网络、缓存、加载状态和错误恢复。

### 追问 2：关于「网络层要有超时、重试、缓存和错误映射…」，下列说法正确的是？

**参考回答**：正确答案是「网络层要有超时、重试、缓存和错误映射，UI 只消费领域结果。」，本课在「核心知识」中说明：它解决的问题：把网络层要有超时、重试、缓存和错误映射，UI 只消费领域结果。，本课在「核心知识」中说明：它解决的问题：把把界面状态建模为加载、成功、空、失败四种，避免多个布尔值互相冲突。，本课在「项目专属规格：实战：Kotlin Android 客户端」中说明：实现列表、详情、网络、缓存、加载状态和错误恢复。本课还在「本课小结」中说明：本课属于「Kotlin」，核心关键词是 Android 项目、网络、缓存、状态。

### 追问 3：关于「项目验收要覆盖旋转、断网、重复请求和…」，下列说法正确的是？

**参考回答**：正确答案是「项目验收要覆盖旋转、断网、重复请求和进程恢复。」，本课在「项目专属规格·实战·Kotlin Android 客户端」中说明：实现列表、详情、网络、缓存、加载状态和错误恢复。，本课在「核心知识」中说明：它解决的问题：把项目验收要覆盖旋转、断网、重复请求和进程恢复。，本课在「核心知识」中说明：它解决的问题：把网络层要有超时、重试、缓存和错误映射，UI 只消费领域结果。本课还在「本课小结」中说明：本课属于「Kotlin」，核心关键词是 Android 项目、网络、缓存、状态。

### 追问 4：「实战：Kotlin Android 客户端」的核心学习目标是什么？

**参考回答**：正确答案是「实现列表、详情、网络、缓存、加载状态和错误恢复。」，本课在「核心知识」中说明：它解决的问题：把项目验收要覆盖旋转、断网、重复请求和进程恢复。，本课在「项目专属规格·实战·Kotlin Android 客户端」中说明：实现列表、详情、网络、缓存、加载状态和错误恢复。，本课在核心知识中说明：它解决的问题：把网络层要有超时、重试、缓存和错误映射，UI 只消费领域结果。

### 追问 5：补全代码：「实战：Kotlin Android 客户端」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `"project": "____",`

**参考回答**：正确答案是「kotlin_project」，本课在「项目专属规格·实战·Kotlin Android 客户端」中说明：实现列表、详情、网络、缓存、加载状态和错误恢复。本课还在核心知识中说明：它解决的问题：把网络层要有超时、重试、缓存和错误映射，UI 只消费领域结果。

## English Overview

**Title:** Project: Kotlin Android Client

**Summary:** Build list, detail, network, cache, loading and error recovery.

**Category:** Kotlin  
**Level:** 高级  
**Key terms:** Android 项目, 网络, 缓存, 状态

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：Kotlin 2.x / Android SDK
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Android 项目、网络、缓存、状态
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 项目专属规格：实战：Kotlin Android 客户端

### 核心场景

实现列表、详情、网络、缓存、加载状态和错误恢复。 项目目标是把「Android 项目、网络、缓存、状态」落实为可运行、可测试、可回滚的交付物。

### 架构与数据流

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### 最小数据模型

| 对象 | 关键字段 | 约束 |
| --- | --- | --- |
| 输入实体 | Android 项目、时间、来源 | 必填校验、长度限制、幂等键 |
| 任务实体 | 状态、优先级、创建时间 | 状态迁移合法、不可重复执行 |
| 结果实体 | 输出、错误码、耗时 | 可序列化、错误可解释 |
| 审计记录 | 操作者、动作、结果、时间 | 不可篡改、可查询、脱敏 |

### 验收场景

1. 正常路径：最小输入得到预期输出，并留下日志与指标。
2. 边界路径：空值、最大值、重复数据和超长内容得到明确处理。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：回滚后数据一致，且能说明恢复时间和影响范围。


## 最小可运行示例

下面示例用于验证「实战：Kotlin Android 客户端」的最小输入、处理和输出。先原样运行，再只修改一个值：

```kotlin
data class Task(val title: String, val done: Boolean = false)

fun main() {
    val tasks = listOf(Task("读一节教程"), Task("跑一个示例", done = true))
    println(tasks.count { it.done })
}
```

## 预期输出

```text
1
```

## 验证步骤

1. 记录运行环境、命令和真实输出。
2. 修改一个输入，先写预测再运行。
3. 制造一次错误输入，记录错误信息与修复方式。
4. 把结论写回本课笔记或测试用例。


## 项目交付物

### 建议仓库结构

```text
app/src/main/
app/src/test/
build.gradle.kts
README.md
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
  "project": "kotlin_project",
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

> 项目验收围绕「Android 项目、网络、缓存」：至少完成一次正常路径、一次边界输入、一次失败恢复和一次幂等检查。


## Full English Study Guide

### Overview

**Project: Kotlin Android Client** focuses on Build list, detail, network, cache, loading and error recovery.

### Learning Outcomes

- Explain what **Project: Kotlin Android Client** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **Project: Kotlin Android Client**
- Related terms: Android 项目, 网络, 缓存, 状态
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.


## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 核心知识 | Core concepts |
| 关键流程 | 关键流程 |
| 实践路径 | 实践路径 |
| 常见误区 | 常见误区 |
| 动手练习 | Hands-on practice |
| 本课小结 | Summary |
| 验证命令与预期输出 | 验证命令与预期输出 |
| 语言专项实践：实战：Kotlin Android 客户端 | 语言专项实践：Hands-on project：Kotlin Android 客户端 |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Kotlin 官方文档](https://kotlinlang.org/docs/home.html) | 语言、协程与互操作 |
| [Android Kotlin](https://developer.android.com/kotlin) | Android 工程实践 |

> 本课主题：实现列表、详情、网络、缓存、加载状态和错误恢复。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
