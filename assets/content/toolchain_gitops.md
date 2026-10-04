# GitOps 与 ArgoCD

![GitOps 与 ArgoCD](images/category_gitops_argocd.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「GitOps 与 ArgoCD」解决了什么问题，而不是只背术语。
- 能说清 「GitOps」、「ArgoCD」、「声明式」、「漂移」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「工具链」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：四原则、仓库结构、ArgoCD 概念与落地建议。

## 前置知识

- 先完成上一课《实战：搭一条完整 CI/CD 流水线》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：GitOps、ArgoCD、声明式。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## GitOps 的四个原则

1. **声明式**：系统的期望状态全部用配置描述（YAML/Helm/Kustomize）。
2. **版本化**：期望状态存在 Git 中，变更即提交，天然有审计与回滚。
3. **自动同步**：集群中的代理持续对比期望状态与实际状态并纠正。
4. **持续协调**：不仅部署一次，而是持续防止漂移。

与传统 CI/CD 的区别：CI 负责构建镜像并更新配置仓库，**CD 由集群内的控制器完成**（拉模型），因此集群不需要把凭据交给外部流水线。

## 仓库结构与流程

| 仓库 | 内容 |
| --- | --- |
| 应用仓库 | 源代码 + Dockerfile + CI 配置 |
| 配置仓库 | 各环境的 K8s 清单（base + overlays，按 env 分目录） |

典型流程：提交代码 → CI 跑测试并构建镜像（tag 用 commit SHA）→ CI 更新配置仓库中的镜像 tag → ArgoCD 检测到差异 → 自动同步到集群 → 健康检查通过。回滚就是 `git revert` 配置提交。

## ArgoCD 核心概念

| 概念 | 说明 |
| --- | --- |
| Application | 一份"配置路径 → 目标集群/命名空间"的映射 |
| Sync | 把 Git 状态应用到集群 |
| Sync Policy | 手动或自动同步，是否允许 prune（删除多余资源）与 self-heal |
| Health | 资源是否健康（Deployment 是否就绪、Pod 是否 Running） |
| Diff | 展示集群实际状态与 Git 期望状态的差异 |

**危险开关**：开启 `prune` 会自动删除 Git 中不存在的资源，务必先在非生产环境验证；`self-heal` 会覆盖手工改动，好处是能自动消除漂移，坏处是紧急手工修复会被回滚（应急时应先暂停同步）。

## 落地建议

1. 环境隔离：dev/staging/prod 使用不同目录与不同 Application，生产需人工审批同步。
2. 密钥不入 Git：用 Sealed Secrets、External Secrets 或 SOPS 加密后提交。
3. 镜像 tag 用不可变标识（commit SHA），禁用 latest。
4. 同步失败要告警并保留历史（ArgoCD 事件 + 通知渠道）。
5. 与 CI 的边界清晰：CI 只产出镜像与配置提交，CD 由集群侧完成。

## 本课小结
GitOps 的价值是**把部署状态收敛到 Git 这一个事实来源**：可审计、可回滚、自动防漂移；ArgoCD 负责对账与同步，而密钥管理、环境隔离与同步策略是落地的三个关键点。

<!-- appendix:v1 -->

## GitOps 原则速查

| 原则 | 说明 |
| --- | --- |
| 声明式 | 集群期望状态写在清单里 |
| 版本化 | 一切变更经 Git，可审计可回滚 |
| 自动同步 | 控制器持续把集群拉向期望状态 |
| 闭环校验 | 持续对比实际与期望，发现漂移 |
| 单一事实源 | Git 是唯一权威来源 |

## 同步策略速查

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

## 密钥与多环境速查

| 主题 | 做法 |
| --- | --- |
| 明文密钥 | 禁止入库 |
| 加密方案 | Sealed Secrets、SOPS、External Secrets |
| 环境隔离 | 目录、分支或 ApplicationSet 分环境 |
| 提升流程 | 预发验证后通过 PR 提升到生产 |
| 权限 | 控制器最小权限，只管理目标命名空间 |
| 审计 | 所有变更对应 Git 提交与 PR |

## 常见错误对照表

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

## 自测清单

- [ ] 集群期望状态全部来自 Git，可审计可回滚。
- [ ] 自动同步与自愈按环境选择，生产慎用 prune。
- [ ] 密钥通过加密方案管理，不入 Git 明文。
- [ ] 有漂移检测、同步窗口与失败告警。
- [ ] 控制器最小权限，变更经 PR 评审。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「GitOps、ArgoCD、声明式」完成复述、实验和交付，每个结果都要能被别人检查。

先在临时环境执行完整命令链，再模拟失败，最后验证回滚和清理。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「GitOps 与 ArgoCD」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「ArgoCD」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

在一个临时目录或本地仓库执行完整命令链，并记录失败时的回滚办法。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「GitOps」和「ArgoCD」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** GitOps & ArgoCD

**Summary:** Principles, repo layout, ArgoCD concepts and practices.

**Category:** Toolchain  
**Level:** 高级  
**Key terms:** GitOps, ArgoCD, 声明式, 漂移, Sealed Secrets

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：Git / Docker / Kubernetes / CI 平台
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：GitOps、ArgoCD、声明式、漂移、Sealed Secrets
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- top50-rewrite:v1 -->

## 课程专属精读：GitOps 与 ArgoCD

### 一、知识地图

- **GitOps 的四个原则**：1. **声明式**：系统的期望状态全部用配置描述（YAML/Helm/Kustomize）。
- **仓库结构与流程**：典型流程：提交代码 → CI 跑测试并构建镜像（tag 用 commit SHA）→ CI 更新配置仓库中的镜像 tag → ArgoCD 检测到差异 → 自动同步到集群 → 健康检查通过。回滚就是 `git revert` 配置提交。
- **ArgoCD 核心概念**：理解它的定义、输入、输出和失败边界。
- **落地建议**：1. 环境隔离：dev/staging/prod 使用不同目录与不同 Application，生产需人工审批同步。
- **GitOps 原则速查**：理解它的定义、输入、输出和失败边界。
- **同步策略速查**：理解它的定义、输入、输出和失败边界。
- **密钥与多环境速查**：理解它的定义、输入、输出和失败边界。
- **常见错误对照表**：理解它的定义、输入、输出和失败边界。

### 二、机制与验证

| 主题 | 需要回答的问题 | 验证方式 |
| --- | --- | --- |
| GitOps 的四个原则 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 仓库结构与流程 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| ArgoCD 核心概念 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 落地建议 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| GitOps 原则速查 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 同步策略速查 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 密钥与多环境速查 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 常见错误对照表 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |

### 三、专属检查问题

1. GitOps 的四个原则 与相邻主题的边界是什么？
2. 仓库结构与流程 与相邻主题的边界是什么？
3. ArgoCD 核心概念 与相邻主题的边界是什么？
4. 落地建议 与相邻主题的边界是什么？
5. GitOps 原则速查 与相邻主题的边界是什么？
6. 同步策略速查 与相邻主题的边界是什么？
7. 密钥与多环境速查 与相邻主题的边界是什么？
8. 常见错误对照表 与相邻主题的边界是什么？

### 四、故障排查

1. 固定输入和环境，确认问题能复现。
2. 找到第一个异常状态，不从最终错误倒猜。
3. 只改变一个变量，记录预测和真实结果。
4. 修复后补边界、失败和重复执行测试。

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Git 文档](https://git-scm.com/doc) | 版本控制与协作 |
| [Docker 文档](https://docs.docker.com/) | 容器与镜像 |
| [Kubernetes 文档](https://kubernetes.io/docs/) | 编排与运维 |

> 本课主题：四原则、仓库结构、ArgoCD 概念与落地建议。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

