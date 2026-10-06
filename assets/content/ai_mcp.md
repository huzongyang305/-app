# MCP 模型上下文协议

![MCP Host Client Server 架构](images/diagram_mcp.webp)

![MCP 模型上下文协议](images/lesson_ai_mcp.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：24 分钟

## 学习目标

- 能用自己的话解释：MCP 用统一协议把模型应用与外部工具、资源和提示连接起来。
- 能用自己的话解释：Host 负责权限与用户交互，Client 连接 Server，Server 暴露受控能力。
- 能用自己的话解释：工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。
- 能把本课知识放回「AI 与智能体」，并完成练习与测验。

## 前置知识

- 已完成「AI 与智能体」的基础课程，能运行正文中的最小示例。
- 本课关键词：MCP、工具协议、资源、权限。
- 遇到不熟悉的术语先记录问题，完成练习后再回读。

## 核心知识

### 1. MCP 用统一协议把模型应用与外部工具、资源和提示连接起来。

- 它解决的问题：把「MCP 用统一协议把模型应用与外部工具、资源和提示连接起来。」放回真实场景，说明不做它会带来什么后果。
- 关键做法：先用最小示例建立基线，再逐步加入边界、失败和性能条件。
- 验证标准：结果可复现、错误可解释、边界有测试、失败能恢复。

### 2. Host 负责权限与用户交互，Client 连接 Server，Server 暴露受控能力。

- 它解决的问题：把「Host 负责权限与用户交互，Client 连接 Server，Server 暴露受控能力。」放回真实场景，说明不做它会带来什么后果。
- 关键做法：先用最小示例建立基线，再逐步加入边界、失败和性能条件。
- 验证标准：结果可复现、错误可解释、边界有测试、失败能恢复。

### 3. 工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。

- 它解决的问题：把「工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。」放回真实场景，说明不做它会带来什么后果。
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

1. 合上教程，用 3～5 句话解释「MCP 模型上下文协议」。
2. 从正文选一个例子，改变一个条件并预测结果。
3. 设计一个失败场景，写出止损与恢复步骤。

**验收标准**：留下输入、命令、输出、差异和下一步问题。

## 本课小结

- 本课属于「AI 与智能体」，核心关键词是 MCP、工具协议、资源、权限。
- 先保证正确与可复现，再讨论性能和扩展。
- 完成练习和测验后，把仍然不确定的问题写成下一轮验证清单。

> 本课由 P1 内容扩展生成，重点补充原有课程缺失的主题与工程边界。


## 可运行练习

下面 3 个任务围绕“MCP 模型上下文协议”展开，代码可以直接粘贴到 App 的离线沙箱里运行；如果示例会读取标准输入，请按代码注释在沙箱的 stdin 区域填入同样格式的数据。

### 任务 1：先跑通，再解释

```python
def score(answer: str) -> int:
    return 1 if answer.strip() else 0

print(score("agent"))
```

**预期输出**：运行后会输出与“MCP 模型上下文协议”相关的关键结果；请重点核对输出行数、最后一个数值和异常提示。

**验收标准**：代码能正常运行；逐行解释每个变量的值如何变化，并指出哪一行决定了最终结果。

### 任务 2：只改一个条件

复制上面的代码，只修改一个输入、边界或参数（例如空值、最大值、循环次数、过滤条件），先写出你的预测，再实际运行。

**验收标准**：留下“原结果 → 改动 → 预测 → 实际结果 → 差异原因”五步记录；如果预测错误，要写出修正后的心智模型。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

**验收标准**：代码不少于 10 行，至少包含 1 个边界检查；把代码和运行结果保存到笔记或片段库。


## 故障现场

这一节把“MCP 模型上下文协议”最常见的失败方式还原成现场记录，练习时按“症状 → 复现 → 定位 → 修复 → 预防”的顺序排查。

### 现场 1：“MCP 模型上下文协议”的 MCP 常规用例通过，但边界用例失败

**症状**：在“MCP 模型上下文协议”的练习或生产场景里出现““MCP 模型上下文协议”的 MCP 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发““MCP 模型上下文协议”的 MCP 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“MCP 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：为“MCP 模型上下文协议”补一条空值或极值用例，把前置条件写成断言，并让失败信息直接指出是哪个输入越界

**预防**：把““MCP 模型上下文协议”的 MCP 常规用例通过，但边界用例失败”写成一条自动化用例，并在“MCP 模型上下文协议”的验收清单里保留对应检查项。


### 现场 2：“MCP 模型上下文协议”的 工具协议 结果在两次运行之间不一致

**症状**：在“MCP 模型上下文协议”的练习或生产场景里出现““MCP 模型上下文协议”的 工具协议 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发““MCP 模型上下文协议”的 工具协议 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“工具协议 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：固定“MCP 模型上下文协议”使用的版本与随机种子，记录两次运行的完整输入和输出，再逐项消除非确定性来源

**预防**：把““MCP 模型上下文协议”的 工具协议 结果在两次运行之间不一致”写成一条自动化用例，并在“MCP 模型上下文协议”的验收清单里保留对应检查项。


### 现场 3：离线评测分数很高，线上仍然频繁给出错误答案

**症状**：在“MCP 模型上下文协议”的练习或生产场景里出现“离线评测分数很高，线上仍然频繁给出错误答案”。

**复现**：准备一组最小输入，只保留触发“离线评测分数很高，线上仍然频繁给出错误答案”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“评测集与真实输入分布不一致，MCP 的提示词或检索结果没有覆盖失败场景”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：为“MCP 模型上下文协议”建立固定评测集、边界题和对抗题，分别记录准确率、拒答率、延迟与 token 成本

**预防**：把“离线评测分数很高，线上仍然频繁给出错误答案”写成一条自动化用例，并在“MCP 模型上下文协议”的验收清单里保留对应检查项。


## 深入补充：MCP 模型上下文协议 的取舍与边界

### 一、把概念放回真实约束

学习“MCP 模型上下文协议”时，最容易只记住结论而忽略前提。先写出三个约束：数据规模、时间预算、可接受的失败方式；再判断 MCP 与 工具协议 在这些约束下是否仍然成立。只要约束改变，原来的最优解就可能变成错误解。

| 维度 | 要回答的问题 | 常见做法 | 失败信号 |
| --- | --- | --- | --- |
| 数据 | MCP 的训练或检索数据从哪来、质量如何 | 清洗、去重、标注与版本化 | 评测集泄漏或分布漂移 |
| 模型 | 工具协议 的能力边界与成本是多少 | 基线对比、离线评测、灰度发布 | 指标好看但线上任务失败 |
| 评测 | 如何证明改动真的有效 | 固定评测集、人工抽检、A/B | 只比较单例输出 |
| 安全 | 失败时会不会泄露或越权 | 权限校验、内容过滤、审计 | 提示注入或数据外泄 |

### 二、三个容易混淆的边界

1. **把“能跑”当成“正确”**：MCP 模型上下文协议 的示例通过，只说明这条输入路径可用；还要用空值、极值和并发路径验证。
2. **把“平均值”当成“全部”**：MCP 的指标好看，不代表尾部请求、冷启动或失败重试也好看。
3. **把“当前版本”当成“永久行为”**：工具协议 依赖的默认值、API 或性能特征都可能随版本变化，需要固定版本并保留回归用例。

### 三、一个生产场景

假设团队要在真实系统里使用“MCP 模型上下文协议”：第一周先做小流量验证，记录 MCP 的基线与异常；第二周扩大输入规模，观察 工具协议 是否成为瓶颈；第三周再做故障演练，主动注入超时、重复请求和依赖不可用，确认系统能降级、能重试、能恢复。每一步都要留下指标、日志和结论，而不是只留下“感觉更快了”。

### 四、自测清单

- 能否用一句话说出“MCP 模型上下文协议”解决的核心问题与不适用场景？
- 能否画出 MCP 的数据流或状态变化，并标出失败路径？
- 能否给出一个反例，证明某个看似合理的结论在边界条件下不成立？
- 能否写出一条可复现的验证命令，让别人独立得到相同结论？

### 五、AI 工程补充

在“MCP 模型上下文协议”里，模型输出只是系统的一部分：输入要先经过权限与数据质量检查，检索或工具调用要有超时和降级，输出要经过引用核验或规则校验，最后记录 token、延迟、失败类型和人工反馈。评测时至少准备固定题、边界题和对抗题，并把 MCP 与 工具协议 的指标分开记录；否则一次提示词改动看似提升体验，实际可能只是评测样本泄漏或随机波动。


## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：关于「MCP 用统一协议把模型应用与外部工…」，下列说法正确的是？

- **正确判断**：MCP 用统一协议把模型应用与外部工具、资源和提示连接起来。
- **判断依据**：正确答案是「MCP 用统一协议把模型应用与外部工具、资源和提示连接起来。」，本课在「本课小结」中说明：本课属于「AI 与智能体」，核心关键词是 MCP、工具协议、资源、权限。，本课在「核心知识」中说明：它解决的问题：把MCP 用统一协议把模型应用与外部工具、资源和提示连接起来。，本课在「核心知识」中说明：它解决的问题：把工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：关于「Host 负责权限与用户交互 Cli…」，下列说法正确的是？

- **正确判断**：Host 负责权限与用户交互，Client 连接 Server
- **判断依据**：正确答案是「Host 负责权限与用户交互，Client 连接 Server」，本课在「核心知识」中说明：它解决的问题：把Host 负责权限与用户交互，Client 连接 Server，Server 暴露受控能力。本课还在核心知识中说明：它解决的问题：把工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。本课还在「本课小结」中说明：本课属于「AI 与智能体」，核心关键词是 MCP、工具协议、资源、权限。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：关于「工具描述、输入 schema、超时和…」，下列说法正确的是？

- **正确判断**：工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。
- **判断依据**：正确答案是「工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。」，本课在「核心知识」中说明：它解决的问题：把MCP 用统一协议把模型应用与外部工具、资源和提示连接起来。，本课在「核心知识」中说明：它解决的问题：把工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。，本课在「本课小结」中说明：本课属于「AI 与智能体」，核心关键词是 MCP、工具协议、资源、权限。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 4：「MCP 模型上下文协议」的核心学习目标是什么？

- **正确判断**：理解 MCP 的 Host、Client、Server、工具与资源模型及权限边界。
- **判断依据**：正确答案是「理解 MCP 的 Host、Client、Server、工具与资源模型及权限边界。」，这道题在问MCP模型上下文协议的核心学习目标是什么，判断时要把题干限定的输入、边界与目标逐项对齐。，本课在核心知识中说明：它解决的问题：把工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。本课还在核心知识中说明：它解决的问题：把MCP 用统一协议把模型应用与外部工具、资源和提示连接起来。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 5：补全代码：「MCP 模型上下文协议」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `return 1 if ____.strip() else 0`

- **正确判断**：answer
- **判断依据**：正确答案是「answer」，本课在「核心知识」中说明：它解决的问题：把MCP 用统一协议把模型应用与外部工具、资源和提示连接起来。本课还在「核心知识」中说明：它解决的问题：把工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。
- **迁移检查**：把答案换成另一种等价写法，是否仍然正确？说明依据。

### 补充考点 1：按照「MCP 模型上下文协议」从概念到实践的讲解顺序排列下列主题。

- **正确判断**：核心知识 → 关键流程 → 实践路径 → 常见误区
- **判断依据**：在「MCP 模型上下文协议」中，正确顺序是：1. 核心知识 → 2. 关键流程 → 3. 实践路径 → 4. 常见误区。「MCP 模型上下文协议」先建立概念，再解释运行机制，随后进入代码与工程实践，最后处理失败路径。在「MCP 模型上下文协议」里，如果把后一步放到前面，通常会缺少前一步产生的定义、输入或验证结果。本课围绕理解 MCP 的 Host、Client、Server、工具与资源模型及权限边界。展开。

### 补充自测（2 题）

1. 围绕“MCP 模型上下文协议”中的 MCP、工具协议、资源，下列哪两项是本课强调的实践判断？
2. 下面这段 Python 代码复现了“MCP 模型上下文协议”中 MCP、工具协议、资源 相关的一个常见故障，哪一项最准确地解释了问题？

这些题按“先定位概念、再排除边界错误、最后核对答案”的顺序作答；每题解析都给出了判断依据。


## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「关于「MCP 用统一协议把模型应用与外部工…」，下列说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「关于「Host 负责权限与用户交互 Cli…」，下列说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「关于「工具描述、输入 schema、超时和…」，下列说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「「MCP 模型上下文协议」的核心学习目标是什么？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「MCP 模型上下文协议」示例中，下面这行代码缺少哪个关键字或函数名？…」的判断依据。
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
| `MCP` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `工具协议` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `资源` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `权限` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：关于「MCP 用统一协议把模型应用与外部工…」，下列说法正确的是？

**参考回答**：正确答案是「MCP 用统一协议把模型应用与外部工具、资源和提示连接起来。」，本课在「核心知识」中说明：它解决的问题：把MCP 用统一协议把模型应用与外部工具、资源和提示连接起来。，本课在「核心知识」中说明：它解决的问题：把工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。，本课在「本课小结」中说明：本课属于「AI 与智能体」，核心关键词是 MCP、工具协议、资源、权限。

### 追问 2：关于「Host 负责权限与用户交互 Cli…」，下列说法正确的是？

**参考回答**：正确答案是「Host 负责权限与用户交互，Client 连接 Server」，本课在「核心知识」中说明：它解决的问题：把Host 负责权限与用户交互，Client 连接 Server，Server 暴露受控能力。本课还在核心知识中说明：它解决的问题：把工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。本课还在「本课小结」中说明：本课属于「AI 与智能体」，核心关键词是 MCP、工具协议、资源、权限。

### 追问 3：关于「工具描述、输入 schema、超时和…」，下列说法正确的是？

**参考回答**：正确答案是「工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。」，本课在「核心知识」中说明：它解决的问题：把工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。，本课在「本课小结」中说明：本课属于「AI 与智能体」，核心关键词是 MCP、工具协议、资源、权限。，本课在「核心知识」中说明：它解决的问题：把MCP 用统一协议把模型应用与外部工具、资源和提示连接起来。

### 追问 4：「MCP 模型上下文协议」的核心学习目标是什么？

**参考回答**：正确答案是「理解 MCP 的 Host、Client、Server、工具与资源模型及权限边界。」，本课在「本课小结」中说明：本课属于「AI 与智能体」，核心关键词是 MCP、工具协议、资源、权限。，本课在核心知识中说明：它解决的问题：把工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。本课还在核心知识中说明：它解决的问题：把MCP 用统一协议把模型应用与外部工具、资源和提示连接起来。

### 追问 5：补全代码：「MCP 模型上下文协议」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `return 1 if ____.strip() else 0`

**参考回答**：正确答案是「answer」，本课在「核心知识」中说明：它解决的问题：把MCP 用统一协议把模型应用与外部工具、资源和提示连接起来。本课还在「核心知识」中说明：它解决的问题：把工具描述、输入 schema、超时和权限确认共同决定 Agent 能否安全调用。

## English Overview

**Title:** Model Context Protocol

**Summary:** Understand MCP hosts, clients, servers, tools, resources and permissions.

**Category:** AI & Agents  
**Level:** 高级  
**Key terms:** MCP, 工具协议, 资源, 权限

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：主流大模型 API、开源模型与向量数据库
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：MCP、工具协议、资源、权限
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 最小可运行示例

下面示例用于验证「MCP 模型上下文协议」的最小输入、处理和输出。先原样运行，再只修改一个值：

```python
def score(answer: str) -> int:
    return 1 if answer.strip() else 0

print(score("agent"))
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


## Full English Study Guide

### Overview

**Model Context Protocol** focuses on Understand MCP hosts, clients, servers, tools, resources and permissions.

### Learning Outcomes

- Explain what **Model Context Protocol** solves and when it should be used.
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

- Topic: **Model Context Protocol**
- Related terms: MCP, 工具协议, 资源, 权限
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.


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
| 最小可运行示例 | Minimal Runnable Examples |
| 预期输出 | Expected Output |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [OpenAI Docs](https://platform.openai.com/docs/) | 模型 API、工具与评估 |
| [Hugging Face Docs](https://huggingface.co/docs) | 模型、数据集与推理 |
| [Model Context Protocol](https://modelcontextprotocol.io/) | Agent 工具与上下文协议 |

> 本课主题：理解 MCP 的 Host、Client、Server、工具与资源模型及权限边界。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
