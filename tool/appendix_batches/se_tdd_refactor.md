## TDD 循环速查

| 阶段 | 动作 | 要求 |
| --- | --- | --- |
| 红 | 先写一个失败的测试 | 测试因功能缺失而失败，而非语法错误 |
| 绿 | 用最简实现让测试通过 | 不追求优雅，先跑通 |
| 重构 | 在测试保护下改善结构 | 行为不变，小步前进 |

节奏建议：每轮几分钟到十几分钟，测试与实现都保持小而聚焦。

## 重构手法速查

| 坏味道 | 手法 |
| --- | --- |
| 长函数 | 提取函数 |
| 重复代码 | 提取公共方法或抽象 |
| 深层嵌套 | 提前返回或卫语句 |
| 长参数列表 | 引入参数对象 |
| 发散式变化 | 按变化原因拆分 |
| 数据泥团 | 提取值对象 |
| 特性依恋 | 把方法移到数据所在类 |
| 基本类型偏执 | 引入值对象封装概念 |

```python
from dataclasses import dataclass

# 重构前：深层嵌套 + 魔法数字 + 多职责
def fee_bad(amount, is_vip, days):
    if amount > 0:
        if is_vip:
            if days <= 3:
                return amount * 0.95
            else:
                return amount * 0.9
        else:
            if days <= 3:
                return amount
            else:
                return amount * 0.98
    return 0

# 重构后：策略表 + 提前返回 + 值对象
@dataclass(frozen=True)
class FeePolicy:
    vip_rate: float = 0.9
    normal_rate: float = 0.98
    short_window_days: int = 3
    short_bonus: float = 0.05

    def rate(self, is_vip: bool, days: int) -> float:
        base = self.vip_rate if is_vip else self.normal_rate
        if days <= self.short_window_days:
            base = min(1.0, base + self.short_bonus)
        return base

def fee(amount: float, is_vip: bool, days: int, policy: FeePolicy | None = None) -> float:
    if amount <= 0:
        return 0.0
    policy = policy or FeePolicy()
    return round(amount * policy.rate(is_vip, days), 2)

assert fee(100, True, 2) == round(fee_bad(100, True, 2), 2)
assert fee(100, False, 10) == round(fee_bad(100, False, 10), 2)
print("行为一致")
```

## 遗留代码改造速查

| 步骤 | 动作 |
| --- | --- |
| 1 找接缝 | 定位可替换的边界（依赖注入点） |
| 2 补特征测试 | 固定当前行为，包括怪异行为 |
| 3 小步重构 | 每次改动后测试必须通过 |
| 4 引入新设计 | 用策略、适配器等替换旧逻辑 |
| 5 删除死代码 | 有测试保护后再清理 |

原则：**先固定行为，再改结构**。特征测试是遗留代码的安全网。

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 先写实现再补测试 | 测试只是为了通过 | 先写测试驱动设计 |
| 一次写很大的测试 | 失败原因难定位 | 小而聚焦，一次一个行为 |
| 绿阶段过度设计 | 反馈变慢 | 先最简实现，重构阶段优化 |
| 重构与功能改动混在一起 | 出问题无法归因 | 分两次提交 |
| 测试断言实现细节 | 重构后大量失败 | 断言可观察行为 |
| 遗留代码直接重写 | 风险极高 | 先补特征测试再逐步替换 |
| 只跑单个测试 | 回归漏掉 | 提交前跑完整套件 |
| 测试依赖外部服务 | 不稳定且慢 | 用替身隔离 |
| 无版本控制小步提交 | 无法回退 | 每轮循环提交一次 |
| 忽略覆盖率盲区 | 关键分支未测 | 看未覆盖分支补用例 |

## 自测清单

- [ ] 遵循红、绿、重构三步且节奏小步。
- [ ] 测试断言行为而非实现细节。
- [ ] 重构与功能改动分开提交。
- [ ] 遗留代码先补特征测试再改造。
- [ ] 每轮循环结束跑完整测试套件。
