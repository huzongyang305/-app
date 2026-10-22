## 逻辑等价速查

| 表达式 | 等价形式 | 名称 |
| --- | --- | --- |
| `p → q` | `¬p ∨ q` | 蕴含等价 |
| `p → q` | `¬q → ¬p` | 逆否 |
| `¬(p ∧ q)` | `¬p ∨ ¬q` | 德摩根律 |
| `¬(p ∨ q)` | `¬p ∧ ¬q` | 德摩根律 |
| `p ↔ q` | `(p → q) ∧ (q → p)` | 双条件 |
| `p ⊕ q` | `(p ∨ q) ∧ ¬(p ∧ q)` | 异或 |
| `p ∧ (q ∨ r)` | `(p ∧ q) ∨ (p ∧ r)` | 分配律 |

## 常用证明与计数方法

| 方法 | 适用 | 要点 |
| --- | --- | --- |
| 直接证明 | 一般命题 | 从前提推导结论 |
| 逆否证明 | `p → q` 难直接证 | 改证 `¬q → ¬p` |
| 反证法 | 否定结论导出矛盾 | 假设结论为假 |
| 数学归纳法 | 与自然数相关的命题 | 基础情形 + 归纳步 |
| 强归纳法 | 依赖多个较小情形 | 假设所有小于 n 成立 |
| 鸽巢原理 | 存在性证明 | n+1 个物品放入 n 个盒子 |
| 容斥原理 | 计数并集 | 加单集、减交集、加三交集 |
| 双计数 | 组合恒等式 | 用两种方式数同一集合 |

```python
from itertools import combinations

def pigeonhole_check(items, boxes):
    """鸽巢原理：物品数超过盒子数时必有盒子至少装两个。"""
    return len(items) > boxes


def inclusion_exclusion(sets):
    """容斥原理：计算多个集合的并集大小。"""
    total = 0
    n = len(sets)
    for k in range(1, n + 1):
        sign = 1 if k % 2 == 1 else -1
        for combo in combinations(range(n), k):
            intersection = set.intersection(*(sets[i] for i in combo))
            total += sign * len(intersection)
    return total


def binomial(n: int, k: int) -> int:
    """组合数 C(n,k)，用递推避免阶乘溢出。"""
    if k < 0 or k > n:
        return 0
    k = min(k, n - k)
    result = 1
    for i in range(k):
        result = result * (n - i) // (i + 1)
    return result


assert inclusion_exclusion([{1, 2, 3}, {3, 4}, {4, 5}]) == 5
assert binomial(5, 2) == 10
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 把 `p → q` 的逆命题当等价 | 逻辑错误 | 只有逆否命题等价：`¬q → ¬p` |
| 混淆「必要」与「充分」 | 推理方向反了 | 充分条件是 `p → q` 中的 p |
| 归纳法只证归纳步 | 证明不完整 | 必须先证基础情形 |
| 归纳步假设不足 | 结论不成立 | 强归纳需假设所有更小情形 |
| 容斥漏掉交集项 | 计数偏大 | 交替加减并检查符号 |
| 组合数用阶乘直算 | 大数溢出或极慢 | 用递推或取模运算 |
| 把「存在」与「任意」写反 | 命题错误 | 明确量词顺序，顺序不同含义不同 |
| 忽略空集情形 | 边界错误 | 空集是任何集合的子集 |
| 认为图论只有无向图结论 | 结论误用 | 有向图的连通性与无向图不同 |
| 用鸽巢原理证明「唯一」 | 结论错 | 它只能证明「至少存在一个」 |

## 自测清单

- [ ] 记得 `p → q` 等价于 `¬p ∨ q` 与 `¬q → ¬p`。
- [ ] 能说清充分条件与必要条件的方向。
- [ ] 会用数学归纳法（含基础情形）。
- [ ] 会用容斥原理计算并集大小。
- [ ] 知道鸽巢原理只能证明存在性。
