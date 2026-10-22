## 测试层级速查

| 层级 | 范围 | 数量占比 | 速度 | 稳定性 |
| --- | --- | --- | --- | --- |
| 单元测试 | 单个函数或类 | 约 70% | 毫秒级 | 高 |
| 集成测试 | 多个模块与外部依赖 | 约 20% | 秒级 | 中 |
| 端到端测试 | 完整用户流程 | 约 10% | 分钟级 | 较低 |
| 契约测试 | 服务间接口约定 | 按接口数 | 秒级 | 高 |
| 性能测试 | 吞吐与延迟 | 按场景 | 分钟级 | 中 |

原则：**在能覆盖风险的最低层级写测试**，越高层越慢、越脆、越贵。

## 测试类型速查

| 类型 | 目的 | 触发时机 |
| --- | --- | --- |
| 冒烟测试 | 核心路径是否可用 | 每次部署 |
| 回归测试 | 新改动是否破坏旧功能 | 每次提交 |
| 探索性测试 | 人工发现意外缺陷 | 版本前期 |
| 混沌测试 | 验证容错假设 | 定期演练 |
| 安全测试 | 发现漏洞 | 上线前与定期 |
| 兼容性测试 | 多端多版本可用 | 发布前 |

```python
from dataclasses import dataclass, field

@dataclass
class TestSuite:
    """测试套件统计：关注分布与稳定性，而非单纯覆盖率。"""

    unit: int = 0
    integration: int = 0
    e2e: int = 0
    flaky: int = 0
    durations: list = field(default_factory=list)

    def total(self) -> int:
        return self.unit + self.integration + self.e2e

    def shape_ratio(self) -> dict:
        total = max(1, self.total())
        return {
            "unit": round(self.unit / total, 2),
            "integration": round(self.integration / total, 2),
            "e2e": round(self.e2e / total, 2),
        }

    def flaky_rate(self) -> float:
        return round(self.flaky / max(1, self.total()), 4)

    def p95_seconds(self) -> float:
        if not self.durations:
            return 0.0
        ordered = sorted(self.durations)
        return ordered[int(len(ordered) * 0.95) - 1]

    def verdict(self) -> str:
        ratio = self.shape_ratio()
        if ratio["e2e"] > 0.25:
            return "端到端比例偏高：下移部分用例到单元或集成层"
        if self.flaky_rate() > 0.02:
            return "不稳定用例过多：先修稳定性再扩覆盖"
        if self.p95_seconds() > 600:
            return "反馈过慢：并行化或拆分套件"
        return "结构健康"

suite = TestSuite(unit=140, integration=40, e2e=20, flaky=3, durations=[12, 18, 25, 300, 420])
print(suite.shape_ratio(), suite.flaky_rate(), suite.verdict())
```

## 测试数据与替身速查

| 替身 | 行为 | 适用 |
| --- | --- | --- |
| Stub | 返回固定值 | 提供可预测输入 |
| Spy | 记录调用 | 验证是否被调用 |
| Mock | 预设期望 | 交互行为验证 |
| Fake | 简化可用实现 | 内存版仓库 |
| 真实依赖 | 完整行为 | 集成测试 |

测试数据原则：每个用例自建自清理、不依赖执行顺序、可重复运行、敏感数据脱敏。

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只追求覆盖率数字 | 覆盖率高压不住缺陷 | 关注断言质量与关键路径 |
| 大量端到端用例 | 慢且不稳定 | 用例下移到低层 |
| 测试依赖执行顺序 | 单跑通过、全跑失败 | 每个用例独立准备数据 |
| 共享可变测试数据 | 偶发失败 | 自建自清理或用夹具 |
| 过度 Mock | 测试通过但线上失败 | 只替身外部依赖，核心逻辑用真实实现 |
| 忽略不稳定用例 | CI 反复失败被忽略 | 优先修复 flaky 用例 |
| 不测异常与边界 | 线上才发现 | 覆盖空值、边界、并发与失败路径 |
| 测试里 sleep 等待 | 慢且不稳定 | 用轮询条件或可控时钟 |
| 无契约测试 | 接口变更线上炸 | 消费方契约测试 |
| 测试环境与生产差异大 | 结论不可迁移 | 用容器化环境对齐 |

## 自测清单

- [ ] 测试分布接近金字塔结构。
- [ ] 用例相互独立、可重复、无顺序依赖。
- [ ] 不稳定用例有治理流程。
- [ ] 覆盖边界、异常与并发场景。
- [ ] 服务间有契约测试，接口变更可提前发现。
