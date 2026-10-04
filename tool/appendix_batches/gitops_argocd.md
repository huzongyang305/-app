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
