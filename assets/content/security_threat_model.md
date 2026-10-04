# 威胁建模与 STRIDE

![威胁建模与 STRIDE](images/lesson_security_threat_model.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：22 分钟

## 学习目标

- 能用自己的话解释：威胁建模从资产、信任边界和数据流出发，先画清系统再讨论攻击。
- 能用自己的话解释：STRIDE 分别覆盖伪装、篡改、抵赖、信息泄露、拒绝服务和提权。
- 能用自己的话解释：每个威胁都要落到缓解措施、验证方式和剩余风险，而不是只列清单。
- 能把本课知识放回「安全与合规」，并完成练习与测验。

## 前置知识

- 已完成「安全与合规」的基础课程，能运行正文中的最小示例。
- 本课关键词：威胁建模、STRIDE、攻击面、数据流图。
- 遇到不熟悉的术语先记录问题，完成练习后再回读。

## 核心知识

### 1. 威胁建模从资产、信任边界和数据流出发，先画清系统再讨论攻击。

- 它解决的问题：把「威胁建模从资产、信任边界和数据流出发，先画清系统再讨论攻击。」放回真实场景，说明不做它会带来什么后果。
- 关键做法：先用最小示例建立基线，再逐步加入边界、失败和性能条件。
- 验证标准：结果可复现、错误可解释、边界有测试、失败能恢复。

### 2. STRIDE 分别覆盖伪装、篡改、抵赖、信息泄露、拒绝服务和提权。

- 它解决的问题：把「STRIDE 分别覆盖伪装、篡改、抵赖、信息泄露、拒绝服务和提权。」放回真实场景，说明不做它会带来什么后果。
- 关键做法：先用最小示例建立基线，再逐步加入边界、失败和性能条件。
- 验证标准：结果可复现、错误可解释、边界有测试、失败能恢复。

### 3. 每个威胁都要落到缓解措施、验证方式和剩余风险，而不是只列清单。

- 它解决的问题：把「每个威胁都要落到缓解措施、验证方式和剩余风险，而不是只列清单。」放回真实场景，说明不做它会带来什么后果。
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

1. 合上教程，用 3～5 句话解释「威胁建模与 STRIDE」。
2. 从正文选一个例子，改变一个条件并预测结果。
3. 设计一个失败场景，写出止损与恢复步骤。

**验收标准**：留下输入、命令、输出、差异和下一步问题。

## 本课小结

- 本课属于「安全与合规」，核心关键词是 威胁建模、STRIDE、攻击面、数据流图。
- 先保证正确与可复现，再讨论性能和扩展。
- 完成练习和测验后，把仍然不确定的问题写成下一轮验证清单。

> 本课由 P1 内容扩展生成，重点补充原有课程缺失的主题与工程边界。

<!-- domain-supplement:v1 -->

## 安全落地补充：威胁建模与 STRIDE

### 一、资产、边界与信任

先回答：保护哪些数据、谁可以访问、哪些组件是信任边界、攻击者能从哪些入口进入。围绕「威胁建模、STRIDE、攻击面、数据流图」列出至少 3 个入口和对应的最小权限。

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

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Threat Modeling and STRIDE

**Summary:** Identify security risks before coding with assets, boundaries and STRIDE.

**Category:** Security & Compliance  
**Level:** 进阶  
**Key terms:** 威胁建模, STRIDE, 攻击面, 数据流图

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：OWASP、云原生与合规安全实践
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：威胁建模、STRIDE、攻击面、数据流图
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- minimal-code:v1 -->

## 最小可运行示例

下面示例用于验证「威胁建模与 STRIDE」的最小输入、处理和输出。先原样运行，再只修改一个值：

```python
import hashlib

digest = hashlib.sha256(b"password").hexdigest()
print(digest[:12])
```

## 预期输出

```text
5e884898da28
```

## 验证步骤

1. 记录运行环境、命令和真实输出。
2. 修改一个输入，先写预测再运行。
3. 制造一次错误输入，记录错误信息与修复方式。
4. 把结论写回本课笔记或测试用例。

<!-- top50-rewrite:v1 -->

## 课程专属精读：威胁建模与 STRIDE

### 一、知识地图

- **1. 威胁建模从资产、信任边界和数据流出发，先画清系统再讨论攻击。**：理解它的定义、输入、输出和失败边界。
- **2. STRIDE 分别覆盖伪装、篡改、抵赖、信息泄露、拒绝服务和提权。**：理解它的定义、输入、输出和失败边界。
- **3. 每个威胁都要落到缓解措施、验证方式和剩余风险，而不是只列清单。**：理解它的定义、输入、输出和失败边界。

### 二、机制与验证

| 主题 | 需要回答的问题 | 验证方式 |
| --- | --- | --- |
| 1. 威胁建模从资产、信任边界和数据流出发，先画清系统再讨论攻击。 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 2. STRIDE 分别覆盖伪装、篡改、抵赖、信息泄露、拒绝服务和提权。 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 3. 每个威胁都要落到缓解措施、验证方式和剩余风险，而不是只列清单。 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |

### 三、专属检查问题

1. 1. 威胁建模从资产、信任边界和数据流出发，先画清系统再讨论攻击。 与相邻主题的边界是什么？
2. 2. STRIDE 分别覆盖伪装、篡改、抵赖、信息泄露、拒绝服务和提权。 与相邻主题的边界是什么？
3. 3. 每个威胁都要落到缓解措施、验证方式和剩余风险，而不是只列清单。 与相邻主题的边界是什么？

### 四、故障排查

1. 固定输入和环境，确认问题能复现。
2. 找到第一个异常状态，不从最终错误倒猜。
3. 只改变一个变量，记录预测和真实结果。
4. 修复后补边界、失败和重复执行测试。

## 专属复习题库

**问：1. 威胁建模从资产、信任边界和数据流出发，先画清系统再讨论攻击。 的关键点是什么？**

答：理解它的定义、输入、输出和失败边界。 复习时要能用自己的话复述，并给出一个失败场景。

**问：2. STRIDE 分别覆盖伪装、篡改、抵赖、信息泄露、拒绝服务和提权。 的关键点是什么？**

答：理解它的定义、输入、输出和失败边界。 复习时要能用自己的话复述，并给出一个失败场景。

**问：3. 每个威胁都要落到缓解措施、验证方式和剩余风险，而不是只列清单。 的关键点是什么？**

答：理解它的定义、输入、输出和失败边界。 复习时要能用自己的话复述，并给出一个失败场景。

## 专属进阶任务 2：威胁建模与 STRIDE

- 围绕「1. 威胁建模从资产、信任边界和数据流出发，先画清系统再讨论攻击。」完成一个可复现实验，记录输入、输出、指标和失败恢复。
- 围绕「2. STRIDE 分别覆盖伪装、篡改、抵赖、信息泄露、拒绝服务和提权。」完成一个可复现实验，记录输入、输出、指标和失败恢复。
- 围绕「3. 每个威胁都要落到缓解措施、验证方式和剩余风险，而不是只列清单。」完成一个可复现实验，记录输入、输出、指标和失败恢复。

### 验收标准

- [ ] 能复现正文中的最小示例。
- [ ] 能解释该主题的正常、边界和失败路径。
- [ ] 能用测试、日志或指标证明结果。
- [ ] 能把结论放回「security_threat_model」所属的学习路径。

## 专属进阶任务 3：威胁建模与 STRIDE

- 围绕「1. 威胁建模从资产、信任边界和数据流出发，先画清系统再讨论攻击。」完成一个可复现实验，记录输入、输出、指标和失败恢复。
- 围绕「2. STRIDE 分别覆盖伪装、篡改、抵赖、信息泄露、拒绝服务和提权。」完成一个可复现实验，记录输入、输出、指标和失败恢复。
- 围绕「3. 每个威胁都要落到缓解措施、验证方式和剩余风险，而不是只列清单。」完成一个可复现实验，记录输入、输出、指标和失败恢复。

### 验收标准

- [ ] 能复现正文中的最小示例。
- [ ] 能解释该主题的正常、边界和失败路径。
- [ ] 能用测试、日志或指标证明结果。
- [ ] 能把结论放回「security_threat_model」所属的学习路径。

## 专属进阶任务 4：威胁建模与 STRIDE

- 围绕「1. 威胁建模从资产、信任边界和数据流出发，先画清系统再讨论攻击。」完成一个可复现实验，记录输入、输出、指标和失败恢复。
- 围绕「2. STRIDE 分别覆盖伪装、篡改、抵赖、信息泄露、拒绝服务和提权。」完成一个可复现实验，记录输入、输出、指标和失败恢复。
- 围绕「3. 每个威胁都要落到缓解措施、验证方式和剩余风险，而不是只列清单。」完成一个可复现实验，记录输入、输出、指标和失败恢复。

### 验收标准

- [ ] 能复现正文中的最小示例。
- [ ] 能解释该主题的正常、边界和失败路径。
- [ ] 能用测试、日志或指标证明结果。
- [ ] 能把结论放回「security_threat_model」所属的学习路径。

## 专属进阶任务 5：威胁建模与 STRIDE

- 围绕「1. 威胁建模从资产、信任边界和数据流出发，先画清系统再讨论攻击。」完成一个可复现实验，记录输入、输出、指标和失败恢复。
- 围绕「2. STRIDE 分别覆盖伪装、篡改、抵赖、信息泄露、拒绝服务和提权。」完成一个可复现实验，记录输入、输出、指标和失败恢复。
- 围绕「3. 每个威胁都要落到缓解措施、验证方式和剩余风险，而不是只列清单。」完成一个可复现实验，记录输入、输出、指标和失败恢复。

### 验收标准

- [ ] 能复现正文中的最小示例。
- [ ] 能解释该主题的正常、边界和失败路径。
- [ ] 能用测试、日志或指标证明结果。
- [ ] 能把结论放回「security_threat_model」所属的学习路径。

## 专属进阶任务 6：威胁建模与 STRIDE

- 围绕「1. 威胁建模从资产、信任边界和数据流出发，先画清系统再讨论攻击。」完成一个可复现实验，记录输入、输出、指标和失败恢复。
- 围绕「2. STRIDE 分别覆盖伪装、篡改、抵赖、信息泄露、拒绝服务和提权。」完成一个可复现实验，记录输入、输出、指标和失败恢复。
- 围绕「3. 每个威胁都要落到缓解措施、验证方式和剩余风险，而不是只列清单。」完成一个可复现实验，记录输入、输出、指标和失败恢复。

### 验收标准

- [ ] 能复现正文中的最小示例。
- [ ] 能解释该主题的正常、边界和失败路径。
- [ ] 能用测试、日志或指标证明结果。
- [ ] 能把结论放回「security_threat_model」所属的学习路径。

## 专属进阶任务 7：威胁建模与 STRIDE

- 围绕「1. 威胁建模从资产、信任边界和数据流出发，先画清系统再讨论攻击。」完成一个可复现实验，记录输入、输出、指标和失败恢复。
- 围绕「2. STRIDE 分别覆盖伪装、篡改、抵赖、信息泄露、拒绝服务和提权。」完成一个可复现实验，记录输入、输出、指标和失败恢复。
- 围绕「3. 每个威胁都要落到缓解措施、验证方式和剩余风险，而不是只列清单。」完成一个可复现实验，记录输入、输出、指标和失败恢复。

### 验收标准

- [ ] 能复现正文中的最小示例。
- [ ] 能解释该主题的正常、边界和失败路径。
- [ ] 能用测试、日志或指标证明结果。
- [ ] 能把结论放回「security_threat_model」所属的学习路径。

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Threat Modeling and STRIDE** focuses on Identify security risks before coding with assets, boundaries and STRIDE.

### Learning Outcomes

- Explain what **Threat Modeling and STRIDE** solves and when it should be used.
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

- Topic: **Threat Modeling and STRIDE**
- Related terms: 威胁建模, STRIDE, 攻击面, 数据流图
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning Objectives |
| 前置知识 | Pre-knowledge |
| 核心知识 | Core knowledge |
| 关键流程 | Key Processes |
| 实践路径 | Practice Path |
| 常见误区 | Common Misconceptions |
| 动手练习 | Hands on exercise: |
| 本课小结 | Lesson Summary |
| 安全落地补充：威胁建模与 STRIDE | Safe to Land Supplement: Threat Modeling and stride |
| 最小可运行示例 | Minimal Runnable Examples |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [OWASP Cheat Sheets](https://cheatsheetseries.owasp.org/) | 应用安全实践 |
| [NIST Cybersecurity](https://www.nist.gov/cyberframework) | 风险治理框架 |

> 本课主题：用资产、边界、攻击面和 STRIDE 分类在编码前识别安全风险。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

