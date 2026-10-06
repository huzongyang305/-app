# Kotlin 基础与空安全

![Kotlin 基础与空安全](images/diagram_kt_basics.webp)

![Kotlin 基础与空安全](images/lesson_kotlin_basics.webp)

> 内容更新时间：2026-10-03 · 学习阶段：基础 · 预计用时：20 分钟

## 学习目标

- 能用自己的话解释：val 声明只读引用，var 可重新赋值，集合内容是否可变由具体类型决定。
- 能用自己的话解释：可空类型在编译期强制处理，?.、?: 和 let 是常用安全操作。
- 能用自己的话解释：类型推断减少样板代码，但公开 API 仍应显式写出关键类型。
- 能把本课知识放回「Kotlin」，并完成练习与测验。

## 前置知识

- 已完成「Kotlin」的基础课程，能运行正文中的最小示例。
- 本课关键词：Kotlin、空安全、val、类型推断。
- 遇到不熟悉的术语先记录问题，完成练习后再回读。

## 核心知识

### 1. val 声明只读引用，var 可重新赋值，集合内容是否可变由具体类型决定。

- 它解决的问题：把「val 声明只读引用，var 可重新赋值，集合内容是否可变由具体类型决定。」放回真实场景，说明不做它会带来什么后果。
- 关键做法：先用最小示例建立基线，再逐步加入边界、失败和性能条件。
- 验证标准：结果可复现、错误可解释、边界有测试、失败能恢复。

### 2. 可空类型在编译期强制处理，?.、?: 和 let 是常用安全操作。

- 它解决的问题：把「可空类型在编译期强制处理，?.、?: 和 let 是常用安全操作。」放回真实场景，说明不做它会带来什么后果。
- 关键做法：先用最小示例建立基线，再逐步加入边界、失败和性能条件。
- 验证标准：结果可复现、错误可解释、边界有测试、失败能恢复。

### 3. 类型推断减少样板代码，但公开 API 仍应显式写出关键类型。

- 它解决的问题：把「类型推断减少样板代码，但公开 API 仍应显式写出关键类型。」放回真实场景，说明不做它会带来什么后果。
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

1. 合上教程，用 3～5 句话解释「Kotlin 基础与空安全」。
2. 从正文选一个例子，改变一个条件并预测结果。
3. 设计一个失败场景，写出止损与恢复步骤。

**验收标准**：留下输入、命令、输出、差异和下一步问题。

## 本课小结

- 本课属于「Kotlin」，核心关键词是 Kotlin、空安全、val、类型推断。
- 先保证正确与可复现，再讨论性能和扩展。
- 完成练习和测验后，把仍然不确定的问题写成下一轮验证清单。

> 本课由 P1 内容扩展生成，重点补充原有课程缺失的主题与工程边界。


## 语言专项实践：Kotlin 基础与空安全

### 一、工具链

| 阶段 | 推荐工具 | 验收标准 |
| --- | --- | --- |
| 编译构建 | kotlinc / Gradle | 命令可复现且错误能被定位 |
| 测试 | JUnit + coroutines-test | 命令可复现且错误能被定位 |
| 静态检查 | detekt / ktlint | 命令可复现且错误能被定位 |
| 发布 | R8/ProGuard + App Bundle | 命令可复现且错误能被定位 |

### 二、运行时与内存模型

围绕「Kotlin、空安全、val、类型推断」说明变量生命周期、资源释放、并发模型和错误传播。语言语法只是入口，真正决定行为的是运行时、标准库和平台约束。

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


## 实践任务

本节围绕“Kotlin 基础与空安全”安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

合上教程，用 5 句话说明“Kotlin 基础与空安全”解决什么问题、输入是什么、输出是什么、失败时会怎样、与相邻概念的边界在哪里。画一张流程图或状态图，把每个节点标注成“输入 / 处理 / 输出 / 失败路径”之一。

**验收标准**：图里至少有 5 个节点和 1 条失败路径；每个节点都能在正文中找到依据。

### 任务 2：做一次对比实验

从正文里选两个差异最小的方案，列成 4 列表格：方案、前提、代价、适用边界。然后只改变一个条件（数据规模、并发度、精度或资源上限），记录结果变化。

**验收标准**：表格里两个方案的结论不能完全一样；写下“在什么条件下应该换方案”。

### 任务 3：迁移到自己的场景

把“Kotlin 基础与空安全”的核心方法用到你熟悉的一个真实场景，写出一份 300 字以内的实施记录：目标、步骤、验证方式、仍然不确定的问题。

**验收标准**：至少有一个可复现的命令、代码片段或数据样例；结论能被别人独立检查。


## 故障现场

这一节把“Kotlin 基础与空安全”最常见的失败方式还原成现场记录，练习时按“症状 → 复现 → 定位 → 修复 → 预防”的顺序排查。

### 现场 1：“Kotlin 基础与空安全”的 Kotlin 常规用例通过，但边界用例失败

**症状**：在“Kotlin 基础与空安全”的练习或生产场景里出现““Kotlin 基础与空安全”的 Kotlin 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发““Kotlin 基础与空安全”的 Kotlin 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“Kotlin 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：为“Kotlin 基础与空安全”补一条空值或极值用例，把前置条件写成断言，并让失败信息直接指出是哪个输入越界

**预防**：把““Kotlin 基础与空安全”的 Kotlin 常规用例通过，但边界用例失败”写成一条自动化用例，并在“Kotlin 基础与空安全”的验收清单里保留对应检查项。


### 现场 2：“Kotlin 基础与空安全”的 空安全 结果在两次运行之间不一致

**症状**：在“Kotlin 基础与空安全”的练习或生产场景里出现““Kotlin 基础与空安全”的 空安全 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发““Kotlin 基础与空安全”的 空安全 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“空安全 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：固定“Kotlin 基础与空安全”使用的版本与随机种子，记录两次运行的完整输入和输出，再逐项消除非确定性来源

**预防**：把““Kotlin 基础与空安全”的 空安全 结果在两次运行之间不一致”写成一条自动化用例，并在“Kotlin 基础与空安全”的验收清单里保留对应检查项。


### 现场 3：“Kotlin 基础与空安全”的验证只在开发机通过

**症状**：在“Kotlin 基础与空安全”的练习或生产场景里出现““Kotlin 基础与空安全”的验证只在开发机通过”。

**复现**：准备一组最小输入，只保留触发““Kotlin 基础与空安全”的验证只在开发机通过”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，Kotlin 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：把“Kotlin 基础与空安全”的运行环境、输入样本和预期输出写成清单，并在另一套环境复跑同一条命令

**预防**：把““Kotlin 基础与空安全”的验证只在开发机通过”写成一条自动化用例，并在“Kotlin 基础与空安全”的验收清单里保留对应检查项。



## 版本与时效

这一节记录“Kotlin 基础与空安全”涉及的版本基线与升级检查点，避免把某个版本的默认行为当成永久结论。

- Kotlin 2.x 以 K2 编译器为核心，语言版本与 JVM 目标独立配置
- 升级前检查注解处理、协程库、Compose 编译器与 Gradle 插件矩阵
- 显式 API 模式与多平台源集是团队协作时的重点
- 官方说明：https://kotlinlang.org/docs/releases.html

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改一个版本变量，记录编译、测试、性能与产物体积的变化。
- 重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。
- 升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。


## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：关于「val 声明只读引用 var 可重新…」，下列说法正确的是？

- **正确判断**：val 声明只读引用，var 可重新赋值，集合内容是否可变由具体类型决定。
- **判断依据**：正确答案是「val 声明只读引用，var 可重新赋值，集合内容是否可变由具体类型决定。」，本课在「本课小结」中说明：本课属于「Kotlin」，核心关键词是 Kotlin、空安全、val、类型推断。，本课在「核心知识」中说明：它解决的问题：把val 声明只读引用，var 可重新赋值，集合内容是否可变由具体类型决定。，本课在「核心知识」中说明：它解决的问题：把类型推断减少样板代码，但公开 API 仍应显式写出关键类型。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：关于「可空类型在编译期强制处理 ? 、?:…」，下列说法正确的是？

- **正确判断**：可空类型在编译期强制处理，?.、?: 和 let 是常用安全操作。
- **判断依据**：正确答案是「可空类型在编译期强制处理，?.、?: 和 let 是常用安全操作。」，本课在「本课小结」中说明：本课属于「Kotlin」，核心关键词是 Kotlin、空安全、val、类型推断。，本课在「核心知识」中说明：它解决的问题：把可空类型在编译期强制处理，?.、?: 和 let 是常用安全操作。，本课在「核心知识」中说明：它解决的问题：把类型推断减少样板代码，但公开 API 仍应显式写出关键类型。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 3：关于「类型推断减少样板代码 但公开 API…」，下列说法正确的是？

- **正确判断**：类型推断减少样板代码，但公开 API 仍应显式写出关键类型。
- **判断依据**：正确答案是「类型推断减少样板代码，但公开 API 仍应显式写出关键类型。」，本课在「核心知识」中说明：它解决的问题：把可空类型在编译期强制处理，?.、?: 和 let 是常用安全操作。，本课在核心知识中说明：它解决的问题：把类型推断减少样板代码，但公开 API 仍应显式写出关键类型。本课还在核心知识中说明：它解决的问题：把val 声明只读引用，var 可重新赋值，集合内容是否可变由具体类型决定。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：「Kotlin 基础与空安全」的核心学习目标是什么？

- **正确判断**：掌握 val/var、类型推断、可空类型和安全调用。
- **判断依据**：正确答案是「掌握 val/var、类型推断、可空类型和安全调用。」，本课在「核心知识」中说明：它解决的问题：把val 声明只读引用，var 可重新赋值，集合内容是否可变由具体类型决定。，本课在核心知识中说明：它解决的问题：把类型推断减少样板代码，但公开 API 仍应显式写出关键类型。，本课在核心知识中说明：它解决的问题：把可空类型在编译期强制处理，?.、?: 和 let 是常用安全操作。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 5：以下哪些术语与「Kotlin 基础与空安全」直接相关？（多选）

- **正确判断**：Kotlin、空安全
- **判断依据**：正确答案是「Kotlin、空安全」，本课在「核心知识」中说明：它解决的问题：把类型推断减少样板代码，但公开 API 仍应显式写出关键类型。本课还在「核心知识」中说明：它解决的问题：把val 声明只读引用，var 可重新赋值，集合内容是否可变由具体类型决定。本课还在「核心知识」中说明：它解决的问题：把可空类型在编译期强制处理，?.、?: 和 let 是常用安全操作。
- **迁移检查**：把其中一个正确项换成它的反例，判断结论会怎样变化。

### 补充考点 1：按照「Kotlin 基础与空安全」从概念到实践的讲解顺序排列下列主题。

- **正确判断**：核心知识 → 关键流程 → 实践路径 → 常见误区
- **判断依据**：在「Kotlin 基础与空安全」中，正确顺序是：1. 核心知识 → 2. 关键流程 → 3. 实践路径 → 4. 常见误区。「Kotlin 基础与空安全」先建立概念，再解释运行机制，随后进入代码与工程实践，最后处理失败路径。在「Kotlin 基础与空安全」里，如果把后一步放到前面，通常会缺少前一步产生的定义、输入或验证结果。本课围绕掌握 val/var、类型推断、可空类型和安全调用。展开。

### 补充自测（1 题）

1. 下面这段 Kotlin 代码复现了“Kotlin 基础与空安全”中 Kotlin、空安全、val 相关的一个常见故障，哪一项最准确地解释了问题？

这些题按“先定位概念、再排除边界错误、最后核对答案”的顺序作答；每题解析都给出了判断依据。


## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「关于「val 声明只读引用 var 可重新…」，下列说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「关于「可空类型在编译期强制处理 ? 、?:…」，下列说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「关于「类型推断减少样板代码 但公开 API…」，下列说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「「Kotlin 基础与空安全」的核心学习目标是什么？」的判断依据。
- [ ] 不看解析，能说出「以下哪些术语与「Kotlin 基础与空安全」直接相关？（多选）」的判断依据。
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
| `Kotlin` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `空安全` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `val` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `类型推断` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：关于「val 声明只读引用 var 可重新…」，下列说法正确的是？

**参考回答**：正确答案是「val 声明只读引用，var 可重新赋值，集合内容是否可变由具体类型决定。」，本课在「核心知识」中说明：它解决的问题：把val 声明只读引用，var 可重新赋值，集合内容是否可变由具体类型决定。，本课在「核心知识」中说明：它解决的问题：把类型推断减少样板代码，但公开 API 仍应显式写出关键类型。，本课在「本课小结」中说明：本课属于「Kotlin」，核心关键词是 Kotlin、空安全、val、类型推断。

### 追问 2：关于「可空类型在编译期强制处理 ? 、?:…」，下列说法正确的是？

**参考回答**：正确答案是「可空类型在编译期强制处理，?.、?: 和 let 是常用安全操作。」，本课在「核心知识」中说明：它解决的问题：把可空类型在编译期强制处理，?.、?: 和 let 是常用安全操作。，本课在「核心知识」中说明：它解决的问题：把类型推断减少样板代码，但公开 API 仍应显式写出关键类型。，本课在「本课小结」中说明：本课属于「Kotlin」，核心关键词是 Kotlin、空安全、val、类型推断。

### 追问 3：关于「类型推断减少样板代码 但公开 API…」，下列说法正确的是？

**参考回答**：正确答案是「类型推断减少样板代码，但公开 API 仍应显式写出关键类型。」，本课在「本课小结」中说明：本课属于「Kotlin」，核心关键词是 Kotlin、空安全、val、类型推断。，本课在「核心知识」中说明：它解决的问题：把可空类型在编译期强制处理，?.、?: 和 let 是常用安全操作。，本课在核心知识中说明：它解决的问题：把类型推断减少样板代码，但公开 API 仍应显式写出关键类型。本课还在「核心知识」中说明：它解决的问题：把val 声明只读引用，var 可重新赋值，集合内容是否可变由具体类型决定。

### 追问 4：「Kotlin 基础与空安全」的核心学习目标是什么？

**参考回答**：正确答案是「掌握 val/var、类型推断、可空类型和安全调用。」，本课在「本课小结」中说明：本课属于「Kotlin」，核心关键词是 Kotlin、空安全、val、类型推断。，本课在「核心知识」中说明：它解决的问题：把val 声明只读引用，var 可重新赋值，集合内容是否可变由具体类型决定。，本课在核心知识中说明：它解决的问题：把类型推断减少样板代码，但公开 API 仍应显式写出关键类型。本课还在「核心知识」中说明：它解决的问题：把可空类型在编译期强制处理，?.、?: 和 let 是常用安全操作。

### 追问 5：以下哪些术语与「Kotlin 基础与空安全」直接相关？（多选）

**参考回答**：正确答案是「Kotlin、空安全」，本课在「核心知识」中说明：它解决的问题：把类型推断减少样板代码，但公开 API 仍应显式写出关键类型。课程摘要指出掌握 val/var，类型推断，可空类型和安全调用，本课要判断的正是以下哪些术语与Kotlin基础与空安全直接相关，（多选）。

## English Overview

**Title:** Kotlin Basics and Null Safety

**Summary:** Learn val/var, type inference, nullable types and safe calls.

**Category:** Kotlin  
**Level:** 基础  
**Key terms:** Kotlin, 空安全, val, 类型推断

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：基础
- 适用环境：Kotlin 2.x / Android SDK
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Kotlin、空安全、val、类型推断
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 最小可运行示例

下面示例用于验证「Kotlin 基础与空安全」的最小输入、处理和输出。先原样运行，再只修改一个值：

```kotlin
fun main() {
    val name = "Ada"
    val year = 1815
    println("$name born in $year")
}
```

## 预期输出

```text
Ada born in 1815
```

## 验证步骤

1. 记录运行环境、命令和真实输出。
2. 修改一个输入，先写预测再运行。
3. 制造一次错误输入，记录错误信息与修复方式。
4. 把结论写回本课笔记或测试用例。


## Full English Study Guide

### Overview

**Kotlin Basics and Null Safety** focuses on Learn val/var, type inference, nullable types and safe calls.

### Learning Outcomes

- Explain what **Kotlin Basics and Null Safety** solves and when it should be used.
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

- Topic: **Kotlin Basics and Null Safety**
- Related terms: Kotlin, 空安全, val, 类型推断
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
| 语言专项实践：Kotlin 基础与空安全 | 语言专项实践：Kotlin 基础与空Security |
| 最小可运行示例 | 最小可运行示例 |

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

> 本课主题：掌握 val/var、类型推断、可空类型和安全调用。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

<!-- code-practice:v1:start -->

## 代码练习（6 题）

下面题目与课程测验同源：覆盖代码输出、排错与场景判断。建议先自己写出答案，再到「测验」里核对成绩。

### 练习 1 · 代码输出

在 Kotlin 课程“Kotlin 基础与空安全”的输入输出实验里，这段代码运行后输出什么？

```kotlin
fun main() {
    val x = 7
    println(x)
}
```

- A. 8
- B. 14
- C. 7
- D. 6

**参考答案**：C. 7
**参考输出**：`7`

**解析**

在 Kotlin 课程“Kotlin 基础与空安全”的输入输出代码实验里，程序先完成赋值、循环或函数调用，再把结果写到标准输出，因此正确结果是 7。
判断 Kotlin 课程“Kotlin 基础与空安全”的代码输出时，要把“源码写了什么”和“运行时实际打印什么”分开；变量值和循环边界都会直接改变最终结果。
把 7 当作基线后，可以只改一个输入或一个边界，再观察 Kotlin 课程“Kotlin 基础与空安全”的输出如何变化，这就是验证掌握程度的方法。

### 练习 2 · 代码输出

在 Kotlin 课程“Kotlin 基础与空安全”的边界实验里，这段代码运行后输出什么？

```kotlin
fun main() {
    var total = 0
    for (i in 1..5) {
        total += i
    }
    println(total)
}
```

- A. 30
- B. 14
- C. 15
- D. 16

**参考答案**：C. 15
**参考输出**：`15`

**解析**

在 Kotlin 课程“Kotlin 基础与空安全”的边界代码实验里，程序先完成赋值、循环或函数调用，再把结果写到标准输出，因此正确结果是 15。
判断 Kotlin 课程“Kotlin 基础与空安全”的代码输出时，要把“源码写了什么”和“运行时实际打印什么”分开；变量值和循环边界都会直接改变最终结果。
把 15 当作基线后，可以只改一个输入或一个边界，再观察 Kotlin 课程“Kotlin 基础与空安全”的输出如何变化，这就是验证掌握程度的方法。

### 练习 3 · 代码输出

在 Kotlin 课程“Kotlin 基础与空安全”的变量实验里，这段代码运行后输出什么？

```kotlin
fun double(value: Int): Int = value * 2

fun main() {
    println(double(5))
}
```

- A. 20
- B. 10
- C. 9
- D. 11

**参考答案**：B. 10
**参考输出**：`10`

**解析**

在 Kotlin 课程“Kotlin 基础与空安全”的变量代码实验里，程序先完成赋值、循环或函数调用，再把结果写到标准输出，因此正确结果是 10。
判断 Kotlin 课程“Kotlin 基础与空安全”的代码输出时，要把“源码写了什么”和“运行时实际打印什么”分开；变量值和循环边界都会直接改变最终结果。
把 10 当作基线后，可以只改一个输入或一个边界，再观察 Kotlin 课程“Kotlin 基础与空安全”的输出如何变化，这就是验证掌握程度的方法。

### 练习 4 · 代码排错

Kotlin 课程“Kotlin 基础与空安全”的下面这段代码无法运行，最可能的修复是什么？

```kotlin
fun main() {
    val x = 7
    println(x)
```

- A. 在 main 函数末尾补上右花括号
- B. 把变量名改成另一个单词即可
- C. 重新安装运行时并清空所有缓存
- D. 把输出语句整段删除，代码就会自动修复

**参考答案**：A. 在 main 函数末尾补上右花括号

**解析**

Kotlin 课程“Kotlin 基础与空安全”里的这段代码无法通过编译或解析，关键原因是缺少了必要语法结构，正确修复是在 main 函数末尾补上右花括号。
在 Kotlin 课程“Kotlin 基础与空安全”中，错误信息通常会指出出错行和期望符号；先读第一条错误，再检查这一行的括号、冒号、分号或花括号。
修复后还要重新运行 Kotlin 课程“Kotlin 基础与空安全”的最小示例，确认输出恢复，并记录这次问题属于语法错误而不是逻辑错误。

### 练习 5 · 代码排错

Kotlin 课程“Kotlin 基础与空安全”的这段代码结果偏小，应该怎样修改？

```kotlin
fun main() {
    var total = 0
    for (i in 1 until 5) {
        total += i
    }
    println(total)
}
```

- A. 把 1 until 5 改成 1..5
- B. 把输出语句移到循环体内部
- C. 把循环变量从 1 改成 0，其余保持不变
- D. 把累加操作改成减法操作

**参考答案**：A. 把 1 until 5 改成 1..5
**修复后输出**：`15`

**解析**

Kotlin 课程“Kotlin 基础与空安全”里的循环边界少算了最后一项，当前输出是 10，而完整求和应为 15。
正确修复是把 1 until 5 改成 1..5；这类错误属于边界问题，代码能运行但结果偏离，所以比语法错误更隐蔽。
验证 Kotlin 课程“Kotlin 基础与空安全”时至少选择首项、中间值和末尾值三个输入，比较手算结果与程序输出，才能发现类似偏差。

### 练习 6 · 概念判断

在 Kotlin 课程“Kotlin 基础与空安全”的学习或项目场景中，哪种做法最有助于得到可验证、可迁移的结果？

- A. 先围绕「Kotlin」写最小可运行示例，再用边界输入验证“Kotlin 基础与空安全”的结果
- B. 跳过错误信息，直接复制另一段代码直到能运行
- C. 一次改完所有变量和依赖，再统一观察是否报错
- D. 只背下「Kotlin 基础与空安全」的结论，遇到新输入时凭感觉修改代码

**参考答案**：A. 先围绕「Kotlin」写最小可运行示例，再用边界输入验证“Kotlin 基础与空安全”的结果

**解析**

在 Kotlin 课程“Kotlin 基础与空安全”里，Kotlin不是孤立的名词，而是一组可以用输入、过程、输出和边界验证的行为。
对 Kotlin 课程“Kotlin 基础与空安全”来说，先写最小可运行示例，再逐步增加边界输入，能把“感觉会了”转化成可以重复的证据。
如果只背结论或一次改很多变量，出错时就无法判断是哪一步破坏了 Kotlin 课程“Kotlin 基础与空安全”的预期；先把变化隔离出来才容易定位。

<!-- code-practice:v1:end -->
