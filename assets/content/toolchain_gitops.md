# GitOps 与 ArgoCD

![GitOps 以 Git 为期望状态的同步闭环](images/diagram_gitops.webp)

![GitOps 与 ArgoCD](images/category_gitops_argocd.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：35 分钟

## 本节知识框架

**课程定位**：所属分类为「工具链」，课程主题为「GitOps 与 ArgoCD」，学习阶段为「高级」，建议用时 35 分钟。

**本课要解决的主问题**：四原则、仓库结构、ArgoCD 概念与落地建议。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「GitOps 与 ArgoCD」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「GitOps 与 ArgoCD」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「GitOps」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《实战：搭一条完整 CI/CD 流水线》

**学习位置**：本课位于《Linux 性能分析》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：本课之后可进入项目实战或综合复习，把本课结论用于一个完整任务。

**教材衔接：学习目标**

- 能用自己的话解释GitOps 与 ArgoCD解决了什么问题，而不是只背术语。
- 能说清 「GitOps」、「ArgoCD」、「声明式」、「漂移」 之间的关系，并分别举出一个例子。
- 能把 GitOps 放回「GitOps 与 ArgoCD」的知识体系，说明它和 ArgoCD 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：四原则、仓库结构、ArgoCD 概念与落地建议。

**教材衔接：前置知识**

- 先完成上一课《实战：搭一条完整 CI/CD 流水线》；如果已经掌握，可以直接用本课练习自测。
- 开始前先复习：GitOps、ArgoCD、声明式。
- 卡在 GitOps 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

**教材衔接：本课小结**

GitOps 的价值是**把部署状态收敛到 Git 这一个事实来源**：可审计、可回滚、自动防漂移；ArgoCD 负责对账与同步，而密钥管理、环境隔离与同步策略是落地的三个关键点。

## 核心概念定义

> 在阅读《GitOps 与 ArgoCD》时，术语第一次出现先给操作性定义，再给边界；正文说法与这里冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| GitOps | GitOps 的价值是把部署状态收敛到 Git 这一个事实来源：可审计、可回滚、自动防漂移；ArgoCD 负责对账与同步，而密钥管理、环境隔离与同步策略是落地的三个关键点。 | 仅在「GitOps 与 ArgoCD」明确给出的输入、版本与资源条件下成立。 |
| 声明式 | 声明式：系统的期望状态全部用配置描述（YAML/Helm/Kustomize）。 | 仅在「GitOps 与 ArgoCD」明确给出的输入、版本与资源条件下成立。 |
| 漂移 | 实际部署状态与声明式配置或版本库中的期望状态发生偏离。 | 仅在「GitOps 与 ArgoCD」明确给出的输入、版本与资源条件下成立。 |
| Sealed Secrets | 密钥不入 Git：用 Sealed Secrets、External Secrets 或 SOPS 加密后提交。 | 仅在「GitOps 与 ArgoCD」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「GitOps 与 ArgoCD」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

**教材衔接：ArgoCD 核心概念**

| 概念 | 说明 |
| --- | --- |
| Application | 一份"配置路径 → 目标集群/命名空间"的映射 |
| Sync | 把 Git 状态应用到集群 |
| Sync Policy | 手动或自动同步，是否允许 prune（删除多余资源）与 self-heal |
| Health | 资源是否健康（Deployment 是否就绪、Pod 是否 Running） |
| Diff | 展示集群实际状态与 Git 期望状态的差异 |

**危险开关**：开启 `prune` 会自动删除 Git 中不存在的资源，务必先在非生产环境验证；`self-heal` 会覆盖手工改动，好处是能自动消除漂移，坏处是紧急手工修复会被回滚（应急时应先暂停同步）。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「GitOps」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「声明式」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「漂移」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「GitOps 与 ArgoCD」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | GitOps | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | 声明式 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 漂移 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「GitOps 与 ArgoCD」自己的示例验证。「GitOps 与 ArgoCD」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：GitOps 的四个原则**

1. **声明式**：系统的期望状态全部用配置描述（YAML/Helm/Kustomize）。
2. **版本化**：期望状态存在 Git 中，变更即提交，天然有审计与回滚。
3. **自动同步**：集群中的代理持续对比期望状态与实际状态并纠正。
4. **持续协调**：不仅部署一次，而是持续防止漂移。

与传统 CI/CD 的区别：CI 负责构建镜像并更新配置仓库，**CD 由集群内的控制器完成**（拉模型），因此集群不需要把凭据交给外部流水线。

**教材衔接：仓库结构与流程**

| 仓库 | 内容 |
| --- | --- |
| 应用仓库 | 源代码 + Dockerfile + CI 配置 |
| 配置仓库 | 各环境的 K8s 清单（base + overlays，按 env 分目录） |

典型流程：提交代码 → CI 跑测试并构建镜像（tag 用 commit SHA）→ CI 更新配置仓库中的镜像 tag → ArgoCD 检测到差异 → 自动同步到集群 → 健康检查通过。回滚就是 `git revert` 配置提交。

**教材衔接：落地建议**

1. 环境隔离：dev/staging/prod 使用不同目录与不同 Application，生产需人工审批同步。
2. 密钥不入 Git：用 Sealed Secrets、External Secrets 或 SOPS 加密后提交。
3. 镜像 tag 用不可变标识（commit SHA），禁用 latest。
4. 同步失败要告警并保留历史（ArgoCD 事件 + 通知渠道）。
5. 与 CI 的边界清晰：CI 只产出镜像与配置提交，CD 由集群侧完成。

**教材衔接：GitOps 原则速查**

| 原则 | 说明 |
| --- | --- |
| 声明式 | 集群期望状态写在清单里 |
| 版本化 | 一切变更经 Git，可审计可回滚 |
| 自动同步 | 控制器持续把集群拉向期望状态 |
| 闭环校验 | 持续对比实际与期望，发现漂移 |
| 单一事实源 | Git 是唯一权威来源 |

**教材衔接：密钥与多环境速查**

| 主题 | 做法 |
| --- | --- |
| 明文密钥 | 禁止入库 |
| 加密方案 | Sealed Secrets、SOPS、External Secrets |
| 环境隔离 | 目录、分支或 ApplicationSet 分环境 |
| 提升流程 | 预发验证后通过 PR 提升到生产 |
| 权限 | 控制器最小权限，只管理目标命名空间 |
| 审计 | 所有变更对应 Git 提交与 PR |

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 GitOps、ArgoCD | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「GitOps 与 ArgoCD」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「GitOps 与 ArgoCD」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

## 代码/协议/SQL 示例

以下代码、协议或 SQL 片段来自《GitOps 与 ArgoCD》原文，保留原有语言标记与上下文；先预测《GitOps 与 ArgoCD》示例的输出，再按正文步骤运行或推演，示例依赖外部环境时同时记录版本与输入。

**教材衔接：同步策略速查**

| 配置 | 作用 | 建议 |
| --- | --- | --- |
| auto-sync | 自动应用 Git 变更 | 预发开启，生产按需 |
| self-heal | 集群被手工改动后自动恢复 | 生产建议开启 |
| prune | 删除 Git 中已移除的资源 | 谨慎开启并配合白名单 |
| sync-window | 只允许在窗口内同步 | 避开业务高峰 |
| 手动同步 | 人工确认后应用 | 高风险变更使用 |
| 应用顺序 | 通过 wave 或 hook 控制 | 依赖资源先建 |

```yaml
# ArgoCD Application 示例：自动同步 + 自愈，但保留资源删除保护
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: orders-api
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://git.example.com/platform/manifests.git
    targetRevision: main
    path: apps/prod/orders-api
  destination:
    server: https://kubernetes.default.svc
    namespace: prod
  syncPolicy:
    automated:
      prune: false          # 先不自动删除，避免误删有状态资源
      selfHeal: true        # 手工改动会被纠正
    syncOptions:
      - CreateNamespace=true
      - PruneLast=true
      - ApplyOutOfSyncOnly=true
    retry:
      limit: 3
      backoff:
        duration: 10s
        factor: 2
        maxDuration: 3m
```

```python
from dataclasses import dataclass

@dataclass
class SyncPlan:
    """同步前评估：列出将创建、更新与删除的资源。"""

    to_create: list
    to_update: list
    to_delete: list

    def is_risky(self) -> bool:
        return len(self.to_delete) > 0

    def summary(self) -> dict:
        return {
            "create": len(self.to_create),
            "update": len(self.to_update),
            "delete": len(self.to_delete),
            "risky": self.is_risky(),
        }

    def decision(self, environment: str, allow_prune: bool = False) -> str:
        if environment == "prod" and self.is_risky() and not allow_prune:
            return "需人工确认：生产环境存在资源删除"
        if self.to_delete and not allow_prune:
            return "已阻止：未开启 prune 时不允许删除"
        return "允许同步"

def detect_drift(desired: dict, actual: dict) -> list:
    """漂移检测：找出实际状态与期望不一致的字段。"""
    drift = []
    for key, value in desired.items():
        if actual.get(key) != value:
            drift.append((key, value, actual.get(key)))
    return drift

plan = SyncPlan(to_create=["svc"], to_update=["deploy"], to_delete=["old-config"])
print(plan.summary(), plan.decision("prod"))
print(detect_drift({"replicas": 3}, {"replicas": 5}))
```

## 时间/空间复杂度或性能分析

**复杂度证据**：「GitOps 与 ArgoCD」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「GitOps 与 ArgoCD」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「GitOps 与 ArgoCD」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《GitOps 与 ArgoCD》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「GitOps 与 ArgoCD」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 直接手工改集群 | 被 self-heal 回滚 | 变更走 Git，紧急改动后回填 |
| 生产默认开启 prune | 误删资源 | 先观察后开启，或按需手动 |
| 密钥明文入库 | 泄漏 | 用密封或外部密钥管理 |
| 所有环境同一分支同一路径 | 相互影响 | 按环境隔离目录与 Application |
| 无同步窗口 | 高峰发布引发故障 | 设窗口并避开业务高峰 |
| 控制器权限过大 | 误操作影响面大 | 最小权限 + 项目隔离 |
| 不做漂移监控 | 实际与期望不一致 | 定期检查 OutOfSync |
| 不评审清单 | 危险配置进入 | PR 评审 + 策略校验 |
| 无回滚方案 | 出错只能前滚 | 用 Git revert 回滚 |
| 忽略同步失败告警 | 状态长期不一致 | 告警到值班渠道 |

**教材衔接：故障现场**

### 现场 1：直接手工改集群

**症状**：在《GitOps 与 ArgoCD》的复现场景中，被 self-heal 回滚。

**根因**：触发点是把“直接手工改集群”当成安全做法。它没有满足《GitOps 与 ArgoCD》要求的前提，因此先表现为“被 self-heal 回滚”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《GitOps 与 ArgoCD》的问题，变更走 Git，紧急改动后回填。

**验证**：保留《GitOps 与 ArgoCD》里触发“被 self-heal 回滚”的输入、版本和日志，按“变更走 Git，紧急改动后回填”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 2：控制器权限过大

**症状**：在《GitOps 与 ArgoCD》的复现场景中，误操作影响面大。

**根因**：当出现“控制器权限过大”时，执行路径已经绕过了《GitOps 与 ArgoCD》的关键约束，最终以“误操作影响面大”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《GitOps 与 ArgoCD》的问题，最小权限 + 项目隔离。

**验证**：在《GitOps 与 ArgoCD》中按“最小权限 + 项目隔离”调整后，从“控制器权限过大”的触发条件重放同一条路径，确认“误操作影响面大”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 3：不做漂移监控

**症状**：在《GitOps 与 ArgoCD》的复现场景中，实际与期望不一致。

**根因**：触发点是把“不做漂移监控”当成安全做法。它没有满足《GitOps 与 ArgoCD》要求的前提，因此先表现为“实际与期望不一致”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《GitOps 与 ArgoCD》的问题，定期检查 OutOfSync。

**验证**：在《GitOps 与 ArgoCD》中按“定期检查 OutOfSync”调整后，从“不做漂移监控”的触发条件重放同一条路径，确认“实际与期望不一致”不再出现，并补一个相邻边界用例检查没有引入新问题。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《实战：搭一条完整 CI/CD 流水线》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《Git 入门》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《Linux 性能分析》 | 同分类中安排在本课之前，建议先完成其自测。 |

把「GitOps 与 ArgoCD」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立完成《GitOps 与 ArgoCD》的自测，再核对答案与解析。答案必须能在本课正文或示例中找到依据，不能只凭语感。

### 自测 1

GitOps 与传统 CD 的关键区别是？

A. 由集群内控制器从 Git 拉取并持续对账
B. 不使用容器
C. 不需要配置
D. 最大的区别就是完全不需要任何 CI，但这会拖慢反馈速度

**参考答案**：由集群内控制器从 Git 拉取并持续对账

**解析**：在「GitOps 与 ArgoCD」里，由集群内控制器从 Git 拉取并持续对账。拉模型让集群不必把凭据交给外部流水线，并能持续纠正漂移。在「GitOps 与 ArgoCD」里判断这道题，要把GitOps、ArgoCD、声明式的条件、过程与失败路径逐项对齐，换成“GitOps 与传统 CD 的关键区”这个场景，只有满足前提的结论才成立。

### 自测 2

围绕“GitOps 与 ArgoCD”中的 GitOps、ArgoCD、声明式，下列哪两项是本课强调的实践判断？

A. 把 ArgoCD 的单次运行结果当成所有版本和规模都成立
B. 学习 GitOps 时要同时说明输入、输出和失败路径，不能只看正常流程
C. 只要 GitOps 的常规示例通过，就可以跳过边界与异常路径
D. 验证 ArgoCD 时要固定版本并覆盖边界输入，结论才可复现

**参考答案**：学习 GitOps 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 ArgoCD 时要固定版本并覆盖边界输入，结论才可复现

**解析**：结论应落在学习 GitOps 时要同时说明输入、输出和失败路径。本课把GitOps 与 ArgoCD拆成概念、示例与故障现场三部分，因此判断 GitOps 时必须同时交代输入、输出和失败路径，这使“学习 GitOps 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在GitOps 与 ArgoCD里，判断 ArgoCD 时要固定版本与边界输入，所以“验证 ArgoCD 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 3

补全代码：「GitOps 与 ArgoCD」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。

`server: https://____.default.svc`

**参考答案**：kubernetes

**解析**：在「GitOps 与 ArgoCD」里，kubernetes。这道题的关键在「GitOps 与 ArgoCD」的GitOps、ArgoCD、声明式：先确认题干“补全代码”问的是哪一步，再排除偷换前提的选项。回到GitOps、ArgoCD、声明式本身再看一遍：只有“kubernetes”与题干“GitOps”的前提一致，结论才成立。

**教材衔接：复习与自测**

- [ ] 集群期望状态全部来自 Git，可审计可回滚。
- [ ] 自动同步与自愈按环境选择，生产慎用 prune。
- [ ] 密钥通过加密方案管理，不入 Git 明文。
- [ ] 有漂移检测、同步窗口与失败告警。
- [ ] 控制器最小权限，变更经 PR 评审。

**教材衔接：动手练习**

> 本课练习重点：围绕「GitOps、ArgoCD、声明式」完成复述、实验和交付，每个结果都要能被别人检查。

先在临时环境执行 GitOps 的完整命令链，再模拟失败并验证回滚。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. GitOps 与 ArgoCD解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「ArgoCD」是什么关系？

验收标准：回答里必须出现 GitOps，并写出一个让结论失效的边界条件。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：用 targetRevision 复现原例后，把ArgoCD改成边界值，五步记录缺一不可，其中「原因」一栏要写明「GitOps 与 ArgoCD」里哪条规则被触发。

### 练习 3：交付一个小结果（30 分钟）

在临时目录执行 GitOps 的完整命令链，并记录失败时的回滚办法。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「GitOps」和「ArgoCD」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```python
from dataclasses import dataclass

@dataclass
class SyncPlan:
    """同步前评估：列出将创建、更新与删除的资源。"""

    to_create: list
    to_update: list
    to_delete: list

    def is_risky(self) -> bool:
        return len(self.to_delete) > 0

    def summary(self) -> dict:
        return {
            "create": len(self.to_create),
            "update": len(self.to_update),
            "delete": len(self.to_delete),
            "risky": self.is_risky(),
        }

    def decision(self, environment: str, allow_prune: bool = False) -> str:
        if environment == "prod" and self.is_risky() and not allow_prune:
            return "需人工确认：生产环境存在资源删除"
        if self.to_delete and not allow_prune:
            return "已阻止：未开启 prune 时不允许删除"
        return "允许同步"

def detect_drift(desired: dict, actual: dict) -> list:
    """漂移检测：找出实际状态与期望不一致的字段。"""
    drift = []
    for key, value in desired.items():
        if actual.get(key) != value:
            drift.append((key, value, actual.get(key)))
    return drift

plan = SyncPlan(to_create=["svc"], to_update=["deploy"], to_delete=["old-config"])
print(plan.summary(), plan.decision("prod"))
print(detect_drift({"replicas": 3}, {"replicas": 5}))
```

### 任务 2：只改一个条件

把「GitOps 与 ArgoCD」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只调整 targetRevision 的一个参数，其余条件一律不动。
- 预测：先写下「GitOps 与 ArgoCD」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响GitOps。

### 任务 3：迁移到自己的数据

把 targetRevision 换成你自己的输入，先保持步骤不变，再比较输出差异。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「GitOps 与传统 CD 的关键区别是？」的判断依据。
- [ ] 不看解析，能说出「ArgoCD 的 prune 开关作用是？」的判断依据。
- [ ] 不看解析，能说出「为什么紧急手工修复可能被自动回滚？」的判断依据。
- [ ] 不看解析，能说出「ArgoCD 的 auto-sync 与 self-heal 的区别是？」的判断依据。
- [ ] 不看解析，能说出「GitOps 中敏感信息（如数据库口令）应如何管理？」的判断依据。
- [ ] 用 GitOps 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

把「GitOps 与 ArgoCD」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `GitOps` | GitOps 的价值是把部署状态收敛到 Git 这一个事实来源：可审计、可回滚、自动防漂移；ArgoCD 负责对账与同步，而密钥管理、环境隔离与同步策略是落地的三个关键点。 |
| `声明式` | 声明式：系统的期望状态全部用配置描述（YAML/Helm/Kustomize）。 |
| `漂移` | 实际部署状态与声明式配置或版本库中的期望状态发生偏离。 |
| `Sealed Secrets` | 密钥不入 Git：用 Sealed Secrets、External Secrets 或 SOPS 加密后提交。 |

## 考点精讲

### 考点 1：概念判断·GitOps

- **题目**：GitOps 与传统 CD 的关键区别是？
- **判断依据**：在「GitOps 与 ArgoCD」里，由集群内控制器从 Git 拉取并持续对账。拉模型让集群不必把凭据交给外部流水线，并能持续纠正漂移。在「GitOps 与 ArgoCD」里判断这道题，要把GitOps、ArgoCD、声明式的条件、过程与失败路径逐项对齐，换成“GitOps 与传统 CD 的关键区”这个场景，只有满足前提的结论才成立。

### 考点 2：概念判断·GitOps

- **题目**：ArgoCD 的 prune 开关作用是？
- **判断依据**：在「GitOps 与 ArgoCD」里，删除 Git 中不存在的集群资源。属于危险开关，必须先在非生产环境验证。在「GitOps 与 ArgoCD」里判断这道题，要把GitOps、ArgoCD、声明式的条件、过程与失败路径逐项对齐，换成“ArgoCD 的 prune 开关作”这个场景，只有满足前提的结论才成立。

### 考点 3：概念判断·GitOps

- **题目**：「GitOps 与 ArgoCD」的核心结论是什么？
- **判断依据**：题干的正确项是GitOps 与 ArgoCD：四原则、仓库结构、ArgoCD 概念与落地建议。在「GitOps 与 ArgoCD」里，把GitOps、ArgoCD、声明式放进最小示例验证，换成空值或极值后结论仍要成立。回到「GitOps 与 ArgoCD」的正文示例，用“GitOps 与 ArgoCD的核心”走一遍GitOps、ArgoCD、声明式的完整流程，能复现的结论才可以保留。

### 考点 4：多选辨析·GitOps

- **题目**：围绕“GitOps 与 ArgoCD”中的 GitOps、ArgoCD、声明式，下列哪两项是本课强调的实践判断？
- **判断依据**：结论应落在学习 GitOps 时要同时说明输入、输出和失败路径。本课把GitOps 与 ArgoCD拆成概念、示例与故障现场三部分，因此判断 GitOps 时必须同时交代输入、输出和失败路径，这使“学习 GitOps 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在GitOps 与 ArgoCD里，判断 ArgoCD 时要固定版本与边界输入，所以“验证 ArgoCD 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 5：概念判断·GitOps

- **题目**：GitOps 中敏感信息（如数据库口令）应如何管理？
- **判断依据**：在「GitOps 与 ArgoCD」里，使用 Sealed Secrets。也可以在集群内引入 External Secrets 从密钥服务动态拉取。把“使用 Sealed Secrets”代回「GitOps 与 ArgoCD」里“GitOps 中敏感信息（如数据库口令）应如何管理”的例子核对，条件一旦改变，结论就要用GitOps、ArgoCD、声明式重新推导。

### 考点 6：填空·GitOps

- **题目**：补全代码：「GitOps 与 ArgoCD」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `server: https://____.default.svc`
- **判断依据**：在「GitOps 与 ArgoCD」里，kubernetes。这道题的关键在「GitOps 与 ArgoCD」的GitOps、ArgoCD、声明式：先确认题干“补全代码”问的是哪一步，再排除偷换前提的选项。回到GitOps、ArgoCD、声明式本身再看一遍：只有“kubernetes”与题干“GitOps”的前提一致，结论才成立。

## English Overview

**Title:** GitOps & ArgoCD

**Summary:** Principles, repo layout, ArgoCD concepts and practices.

**Category:** Toolchain
**Level:** 高级
**Key terms:** GitOps, ArgoCD, 声明式, 漂移, Sealed Secrets

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：Git / Docker / Kubernetes / CI 平台；本课聚焦 GitOps。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：GitOps、ArgoCD、声明式、漂移、Sealed Secrets
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-08-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [GitHub Actions](https://docs.github.com/actions) | CI/CD 工作流 |
| [Git 文档](https://git-scm.com/doc) | 版本控制与分支模型 |
| [npm 文档](https://docs.npmjs.com/) | JavaScript 包管理 |

> 「GitOps 与 ArgoCD」的链接用于离线阅读后的延伸核对；App 不会自动联网。
