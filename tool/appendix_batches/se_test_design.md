## 用例设计方法速查

| 方法 | 适用 | 产出 |
| --- | --- | --- |
| 等价类划分 | 输入范围明确的接口 | 有效与无效等价类 |
| 边界值分析 | 数值、长度、时间边界 | 边界与邻近值用例 |
| 判定表 | 多条件组合决定动作 | 条件组合到动作的映射 |
| 状态迁移 | 状态驱动的业务 | 状态与事件迁移覆盖 |
| 场景法 | 端到端用户流程 | 主流程与备选流程 |
| 正交实验 | 多因素多水平 | 少量高覆盖组合 |
| 错误推测 | 经验补充 | 高风险点清单 |

组合取舍：先覆盖单因素边界与等价类，再覆盖两两组合，最后补充高风险组合。

## 用例要素速查

| 要素 | 要求 |
| --- | --- |
| 前置条件 | 数据与状态可复现 |
| 操作步骤 | 具体到接口或界面元素 |
| 预期结果 | 可断言（状态码、字段值、数据变化） |
| 优先级 | 核心流程 P0，异常路径 P1，边界 P2 |
| 可追溯 | 关联需求或验收标准编号 |

```python
from itertools import combinations
from dataclasses import dataclass, field

def boundary_cases(low: int, high: int) -> list:
    """边界值：边界本身与紧邻值，外加典型无效值。"""
    return [low - 1, low, low + 1, high - 1, high, high + 1]

def equivalence_classes(value_range: tuple, invalid: list) -> dict:
    """等价类：有效区间与各类无效输入。"""
    low, high = value_range
    return {
        "valid": [low, (low + high) // 2, high],
        "invalid_too_small": [low - 1],
        "invalid_too_large": [high + 1],
        "invalid_type": invalid,
    }

def pairwise(params: dict) -> list:
    """两两组合：在因素较多时控制用例数量。"""
    names = list(params)
    cases = []
    for a, b in combinations(names, 2):
        for va in params[a]:
            for vb in params[b]:
                cases.append({a: va, b: vb})
    return cases

@dataclass
class TestCase:
    case_id: str
    title: str
    precondition: str
    steps: list
    expected: str
    priority: str = "P1"
    tags: list = field(default_factory=list)

    def is_assertable(self) -> bool:
        """预期结果必须包含可断言要素。"""
        hints = ("=", "返回", "状态码", "字段", "记录", "提示")
        return any(hint in self.expected for hint in hints)

print(boundary_cases(1, 100))
print(pairwise({"浏览器": ["Chrome", "Safari"], "网络": ["4G", "WiFi"]})[:4])
case = TestCase("TC-1", "创建订单", "用户已登录", ["提交订单"], "返回 201 且订单表新增 1 条记录")
print(case.is_assertable())
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只测正常值 | 边界缺陷漏到线上 | 必测边界与邻近值 |
| 预期结果写「正常」 | 无法自动断言 | 写成具体状态码与字段 |
| 用例依赖前置数据手工准备 | 无法自动执行 | 前置条件可脚本化 |
| 全组合穷举 | 用例爆炸 | 用两两组合 + 高风险补充 |
| 不标优先级 | 时间不足时乱测 | 按业务影响排序 |
| 用例与需求脱节 | 覆盖不到验收点 | 与需求编号双向追溯 |
| 状态迁移遗漏非法迁移 | 出现不可能状态 | 既测合法也测非法迁移 |
| 复制粘贴用例 | 维护成本高 | 参数化生成用例 |
| 只写步骤不写下预期 | 结果判断主观 | 每步或整体给可断言结果 |
| 回归不更新用例 | 覆盖面逐步失效 | 需求变更同步更新 |

## 自测清单

- [ ] 会用等价类与边界值设计输入类用例。
- [ ] 多条件场景使用判定表或两两组合。
- [ ] 状态驱动业务覆盖合法与非法迁移。
- [ ] 每条用例预期结果可自动断言。
- [ ] 用例与需求双向可追溯并有优先级。
