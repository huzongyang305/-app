## SDL 阶段速查

| 阶段 | 安全活动 | 产出 |
| --- | --- | --- |
| 需求 | 安全需求、合规确认 | 安全需求清单 |
| 设计 | 威胁建模（STRIDE）、架构评审 | 威胁与缓解措施 |
| 编码 | 安全编码规范、代码评审 | 评审记录 |
| 测试 | SAST、依赖扫描、渗透测试 | 漏洞清单与修复 |
| 发布 | 密钥检查、配置基线 | 发布检查表 |
| 运维 | 监控、应急响应、补丁 | 事件记录与复盘 |

## STRIDE 威胁速查

| 威胁 | 含义 | 典型缓解 |
| --- | --- | --- |
| Spoofing 伪装 | 冒充身份 | 强认证、多因素 |
| Tampering 篡改 | 修改数据或代码 | 完整性校验、签名 |
| Repudiation 抵赖 | 否认操作 | 审计日志、数字签名 |
| Information disclosure 信息泄露 | 数据被读取 | 加密、最小权限、脱敏 |
| Denial of service 拒绝服务 | 服务不可用 | 限流、弹性、隔离 |
| Elevation of privilege 提权 | 获得更高权限 | 最小权限、输入校验 |

```python
from dataclasses import dataclass, field

@dataclass
class Threat:
    category: str            # STRIDE 之一
    asset: str
    scenario: str
    likelihood: int          # 1 到 5
    impact: int              # 1 到 5
    mitigation: str = ""

    def risk(self) -> int:
        return self.likelihood * self.impact

    def priority(self) -> str:
        score = self.risk()
        if score >= 20:
            return "P0：必须在设计阶段解决"
        if score >= 12:
            return "P1：编码阶段落实缓解"
        if score >= 6:
            return "P2：纳入测试与监控"
        return "P3：记录并观察"

@dataclass
class SecurityReview:
    threats: list = field(default_factory=list)

    def add(self, threat: Threat) -> None:
        self.threats.append(threat)

    def unmitigated(self) -> list:
        return [t for t in self.threats if not t.mitigation]

    def report(self) -> dict:
        ordered = sorted(self.threats, key=lambda t: -t.risk())
        return {
            "total": len(self.threats),
            "unmitigated": len(self.unmitigated()),
            "top": [(t.scenario, t.priority()) for t in ordered[:3]],
            "blocking": [t.scenario for t in self.threats if t.priority() == "P0：必须在设计阶段解决"],
        }

review = SecurityReview()
review.add(Threat("Information disclosure", "用户数据库", "越权读取他人订单", 4, 5))
review.add(Threat("Denial of service", "下单接口", "无限制刷单", 3, 3, "按用户与 IP 限流"))
print(review.report())
```

## CI 安全检查速查

| 检查 | 目标 | 工具类型 |
| --- | --- | --- |
| SAST | 代码层漏洞（注入、路径穿越） | 静态分析 |
| SCA | 第三方依赖已知漏洞 | 依赖扫描 |
| 密钥扫描 | 硬编码密钥与令牌 | 正则加熵检测 |
| DAST | 运行时接口漏洞 | 动态扫描 |
| 镜像扫描 | 容器基础镜像漏洞 | 镜像扫描 |
| IaC 扫描 | 云资源配置错误 | 配置检查 |
| 许可证合规 | 依赖许可证风险 | 许可证检查 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 上线前才做安全测试 | 问题发现太晚、成本高 | 需求与设计阶段就介入 |
| 只靠扫描器 | 业务逻辑漏洞漏掉 | 结合威胁建模与人工审计 |
| 扫描告警不修 | 漏洞长期存在 | 高危阻断、中低排期修复 |
| 密钥散落各处 | 泄漏与轮换困难 | 集中密钥管理并定期轮换 |
| 无审计日志 | 事件无法追溯 | 关键操作记录不可篡改日志 |
| 依赖不更新 | 已知漏洞长期暴露 | 定期扫描与升级 |
| 权限过大 | 一处失守全线崩溃 | 最小权限与网络分段 |
| 无应急响应流程 | 事件处理混乱 | 预案 + 演练 + 分工 |
| 不做威胁建模 | 遗漏重要威胁 | 设计阶段做 STRIDE |
| 安全需求无验收 | 无法验证是否落实 | 转化为可测的安全用例 |

## 自测清单

- [ ] 需求与设计阶段就开展安全活动（安全左移）。
- [ ] 用 STRIDE 做威胁建模并给出缓解措施。
- [ ] CI 集成 SAST、SCA、密钥与镜像扫描。
- [ ] 密钥集中管理并定期轮换。
- [ ] 有应急响应预案与演练记录。
