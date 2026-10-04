## 常用质量指标速查

| 指标 | 含义 | 使用注意 |
| --- | --- | --- |
| 测试覆盖率 | 被测试执行的代码比例 | 需结合断言质量与变异测试 |
| 变异测试得分 | 故意注入缺陷被测试发现的比例 | 衡量测试有效性 |
| 缺陷逃逸率 | 上线后发现、本应被拦住的缺陷比例 | 衡量测试与评审效果 |
| 平均修复时间（MTTR） | 从发现到恢复的时长 | 反映响应能力 |
| 变更失败率 | 发布导致故障的比例 | 衡量发布质量 |
| 部署频率 | 单位时间发布次数 | 反映交付能力 |
| 领先时间 | 从提交到上线的时长 | 反映流程效率 |

注意：**度量用于改进流程，不用于考核个人**，否则会导致数据造假与隐瞒。

## CI 门禁速查

| 门禁 | 建议阈值 |
| --- | --- |
| 单元测试 | 全部通过 |
| 静态检查 | 无 error 级问题 |
| 类型检查 | 通过 |
| 依赖漏洞 | 高危为 0 |
| 密钥扫描 | 无命中 |
| 覆盖率 | 不低于基线（不强制 100%） |
| 端到端冒烟 | 核心路径通过 |
| 性能基线 | 关键接口无显著回归 |

```python
from dataclasses import dataclass, field

@dataclass
class QualityGate:
    """质量门禁评估：任一硬门禁失败即阻止合并。"""

    tests_passed: bool = True
    lint_errors: int = 0
    type_errors: int = 0
    high_vulns: int = 0
    secrets_found: int = 0
    coverage: float = 0.0
    coverage_baseline: float = 0.0
    perf_regression: float = 0.0

    def hard_failures(self) -> list:
        failures = []
        if not self.tests_passed:
            failures.append("测试未全部通过")
        if self.lint_errors:
            failures.append(f"静态检查 error {self.lint_errors} 个")
        if self.type_errors:
            failures.append(f"类型错误 {self.type_errors} 个")
        if self.high_vulns:
            failures.append(f"高危漏洞 {self.high_vulns} 个")
        if self.secrets_found:
            failures.append(f"疑似密钥 {self.secrets_found} 处")
        return failures

    def soft_warnings(self) -> list:
        warnings = []
        if self.coverage + 1e-9 < self.coverage_baseline:
            warnings.append(f"覆盖率低于基线 {self.coverage_baseline:.2%}")
        if self.perf_regression > 0.2:
            warnings.append(f"性能回退 {self.perf_regression:.0%}")
        return warnings

    def verdict(self) -> dict:
        hard = self.hard_failures()
        soft = self.soft_warnings()
        return {
            "pass": not hard,
            "blocking": hard,
            "warnings": soft,
            "decision": "阻止合并" if hard else ("允许合并但需关注" if soft else "允许合并"),
        }

gate = QualityGate(tests_passed=True, coverage=0.72, coverage_baseline=0.75, perf_regression=0.05)
print(gate.verdict())
```

## 代码评审速查

| 关注点 | 具体检查 |
| --- | --- |
| 正确性 | 边界、异常、并发、错误处理 |
| 可维护性 | 命名、职责、重复、复杂度 |
| 安全性 | 输入校验、权限、密钥、注入 |
| 性能 | 复杂度、N+1、无谓分配 |
| 测试 | 覆盖关键路径与异常分支 |
| 兼容性 | 接口变更是否向后兼容 |
| 可观测性 | 日志、指标、追踪是否充分 |

评审规模建议：单次变更控制在几百行以内，超过则拆分。

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用覆盖率考核个人 | 写无断言测试刷指标 | 度量用于流程改进 |
| 覆盖率 100% 就放心 | 关键缺陷仍漏出 | 结合变异测试与缺陷逃逸率 |
| 门禁阈值定得过严 | 大量时间花在修指标 | 阈值以可修复、与质量相关为准 |
| 门禁只跑一次 | 新问题无人拦 | 每次提交与合并都跑 |
| 只看速度不看失败率 | 上线故障增多 | 质量与效率指标一起看 |
| 大 PR 一次评审 | 评审质量下降 | 小批量频繁评审 |
| 不记录缺陷根因 | 同类问题重复发生 | 做根因分析与改进项跟踪 |
| 指标只看单点 | 趋势无法判断 | 看趋势与基线对比 |
| 忽略测试稳定性 | flaky 用例被忽略 | 优先修复不稳定用例 |
| 只统计不行动 | 指标没有价值 | 每个指标对应改进行动 |

## 自测清单

- [ ] 质量指标用于流程改进而非个人考核。
- [ ] 覆盖率与变异测试、缺陷逃逸率结合使用。
- [ ] CI 门禁覆盖测试、静态检查、漏洞与密钥扫描。
- [ ] 评审关注正确性、安全、性能与测试。
- [ ] 每个指标都有对应的改进行动与跟踪。
