# 软件供应链安全

![软件供应链安全](images/lesson_security_supply_chain.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：24 分钟

## 学习目标

- 能用自己的话解释：依赖要锁定版本、扫描漏洞、检查许可证和维护状态。
- 能用自己的话解释：构建环境要可复现，制品要签名并保留来源信息。
- 能用自己的话解释：SBOM 能在漏洞爆发时快速定位受影响系统，但必须持续更新才有价值。
- 能把本课知识放回「安全与合规」，并完成练习与测验。

## 前置知识

- 已完成「安全与合规」的基础课程，能运行正文中的最小示例。
- 本课关键词：供应链、SBOM、依赖漏洞、制品签名。
- 遇到不熟悉的术语先记录问题，完成练习后再回读。

## 核心知识

### 1. 依赖要锁定版本、扫描漏洞、检查许可证和维护状态。

- 它解决的问题：把「依赖要锁定版本、扫描漏洞、检查许可证和维护状态。」放回真实场景，说明不做它会带来什么后果。
- 关键做法：先用最小示例建立基线，再逐步加入边界、失败和性能条件。
- 验证标准：结果可复现、错误可解释、边界有测试、失败能恢复。

### 2. 构建环境要可复现，制品要签名并保留来源信息。

- 它解决的问题：把「构建环境要可复现，制品要签名并保留来源信息。」放回真实场景，说明不做它会带来什么后果。
- 关键做法：先用最小示例建立基线，再逐步加入边界、失败和性能条件。
- 验证标准：结果可复现、错误可解释、边界有测试、失败能恢复。

### 3. SBOM 能在漏洞爆发时快速定位受影响系统，但必须持续更新才有价值。

- 它解决的问题：把「SBOM 能在漏洞爆发时快速定位受影响系统，但必须持续更新才有价值。」放回真实场景，说明不做它会带来什么后果。
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

1. 合上教程，用 3～5 句话解释「软件供应链安全」。
2. 从正文选一个例子，改变一个条件并预测结果。
3. 设计一个失败场景，写出止损与恢复步骤。

**验收标准**：留下输入、命令、输出、差异和下一步问题。

## 本课小结

- 本课属于「安全与合规」，核心关键词是 供应链、SBOM、依赖漏洞、制品签名。
- 先保证正确与可复现，再讨论性能和扩展。
- 完成练习和测验后，把仍然不确定的问题写成下一轮验证清单。

> 本课由 P1 内容扩展生成，重点补充原有课程缺失的主题与工程边界。


## 安全落地补充：软件供应链安全

### 一、资产、边界与信任

先回答：保护哪些数据、谁可以访问、哪些组件是信任边界、攻击者能从哪些入口进入。围绕「供应链、SBOM、依赖漏洞、制品签名」列出至少 3 个入口和对应的最小权限。

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


## 考点精讲：把测验题还原成判断过程

本课有 4 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：关于「依赖要锁定版本、扫描漏洞、检查许可证…」，下列说法正确的是？

- **正确判断**：依赖要锁定版本、扫描漏洞、检查许可证和维护状态。
- **判断依据**：学习《软件供应链安全》时应把该要点与「供应链」一起理解。复习《软件供应链安全》的「供应链、SBOM、依赖漏洞」时，再用一个边界输入验证同一个结论。正确项「依赖要锁定版本、扫描漏洞、检查许可证和维护状态」与题干要求一致，是本课知识点的准确定义。错误项「所有外部输入都不可信，必须校验类型、长度、范围和业务约束」忽略了题目中的限制条件，因此不成立。错误项「威胁建模从资产、信任边界和数据流出发，先画清系统再讨论攻击」把不同概念混在一起，缺少题干限定的前提。错误项「访问控制必须在服务端逐请求校验，不能依赖前端隐藏按钮」与课程给出的定义相冲突，不能回答题目所问。把题干「关于「依赖要锁定版本、扫描漏洞、检查许可证…」，下列说法正确的是？」放回《软件供应链安全》的「从依赖、构建、制品签名到 SBOM 建立可追溯的供应链防线」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 2：关于「构建环境要可复现 制品要签名并保留来…」，下列说法正确的是？

- **正确判断**：构建环境要可复现，制品要签名并保留来源信息。
- **判断依据**：学习《软件供应链安全》时应把该要点与「供应链」一起理解。复习《软件供应链安全》的「供应链、SBOM、依赖漏洞」时，再用一个边界输入验证同一个结论。正确项「构建环境要可复现，制品要签名并保留来源信息」与题干要求一致，是本课知识点的准确定义。错误项「注入问题来自把不可信数据当成代码或查询结构，参数化和白名单是根本修复」忽略了题目中的限制条件，因此不成立。错误项「输出编码要按 HTML、SQL、Shell、URL 等不同上下文分别处理」属于相邻主题的说法，范围与本题要求不一致。错误项「STRIDE 分别覆盖伪装、篡改、抵赖、信息泄露、拒绝服务和提权」与课程给出的定义相冲突，不能回答题目所问。把题干「关于「构建环境要可复现 制品要签名并保留来…」，下列说法正确的是？」放回《软件供应链安全》的「从依赖、构建、制品签名到 SBOM 建立可追溯的供应链防线」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 3：关于「SBOM 能在漏洞爆发时快速定位受影…」，下列说法正确的是？

- **正确判断**：SBOM 能在漏洞爆发时快速定位受影响系统，但必须持续更新才有价值。
- **判断依据**：学习《软件供应链安全》时应把该要点与「供应链」一起理解。复习《软件供应链安全》的「供应链、SBOM、依赖漏洞」时，再用一个边界输入验证同一个结论。正确项「SBOM 能在漏洞爆发时快速定位受影响系统，但必须持续更新才有价值」与本课示例和结论一致，可以直接用于实际编码。错误项「每个威胁都要落到缓解措施、验证方式和剩余风险，而不是只列清单」只看到了表面现象，没有解释题干真正考查的机制。错误项「加密失败常源于明文存储、弱算法、密钥硬编码和证书校验被关闭」在边界或失败路径上会得出错误结果，在题干「关于「SBOM 能在漏洞爆发时快速定位受影…」，下列说法正确的是？」的语境下并不成立。错误项「错误信息不能泄露堆栈、SQL、路径和密钥，日志也要脱敏」适用于其他场景，但与本题的前提不匹配。把题干「关于「SBOM 能在漏洞爆发时快速定位受影…」，下列说法正确的是？」放回《软件供应链安全》的「从依赖、构建、制品签名到 SBOM 建立可追溯的供应链防线」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 4：「软件供应链安全」的核心学习目标是什么？

- **正确判断**：从依赖、构建、制品签名到 SBOM 建立可追溯的供应链防线。
- **判断依据**：正确项「从依赖、构建、制品签名到 SBOM 建立可追溯的供应链防线」完整覆盖了题目要求的关键点，没有遗漏前提。错误项「用资产、边界、攻击面和 STRIDE 分类在编码前识别安全风险」适用于其他场景，但与本题的前提不匹配。错误项「理解访问控制、注入、加密失败、配置错误等常见 Web 风险的成因与修复」把因果关系颠倒了，不能作为正确结论。错误项「把输入校验、输出编码、最小权限和错误处理落实到代码边界」忽略了题目中的限制条件，因此不成立。把题干「「软件供应链安全」的核心学习目标是什么？」放回《软件供应链安全》的「从依赖、构建、制品签名到 SBOM 建立可追溯的供应链防线」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「关于「依赖要锁定版本、扫描漏洞、检查许可证…」，下列说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「关于「构建环境要可复现 制品要签名并保留来…」，下列说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「关于「SBOM 能在漏洞爆发时快速定位受影…」，下列说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「「软件供应链安全」的核心学习目标是什么？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** Software Supply Chain Security

**Summary:** Build traceable supply-chain defenses from dependencies to signed artifacts.

**Category:** Security & Compliance  
**Level:** 高级  
**Key terms:** 供应链, SBOM, 依赖漏洞, 制品签名

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：OWASP、云原生与合规安全实践
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：供应链、SBOM、依赖漏洞、制品签名
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 最小可运行示例

下面示例用于验证「软件供应链安全」的最小输入、处理和输出。先原样运行，再只修改一个值：

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


## Full English Study Guide

### Overview

**Software Supply Chain Security** focuses on Build traceable supply-chain defenses from dependencies to signed artifacts.

### Learning Outcomes

- Explain what **Software Supply Chain Security** solves and when it should be used.
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

- Topic: **Software Supply Chain Security**
- Related terms: 供应链, SBOM, 依赖漏洞, 制品签名
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
| 安全落地补充：软件供应链安全 | Security落地补充：软件供应链Security |
| 最小可运行示例 | 最小可运行示例 |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [OWASP Cheat Sheets](https://cheatsheetseries.owasp.org/) | 应用安全实践 |
| [NIST Cybersecurity](https://www.nist.gov/cyberframework) | 风险治理框架 |

> 本课主题：从依赖、构建、制品签名到 SBOM 建立可追溯的供应链防线。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

