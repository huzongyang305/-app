## 补充：熵、交叉熵与互信息的计算与用途

### 熵：不确定性的度量

```text
信息熵 H(X) = -Σ p(x) · log₂ p(x)

直观理解：平均而言，描述一个结果最少需要多少比特
  公平硬币：H = -(0.5·log₂0.5 + 0.5·log₂0.5) = 1 bit
  必然事件：H = -1·log₂1 = 0 bit（毫无不确定性）
  八面骰子：H = log₂8 = 3 bit

结论：分布越均匀，熵越大；越确定，熵越小
```

```python
from math import log2

def entropy(probs: list[float]) -> float:
    return -sum(p * log2(p) for p in probs if p > 0)

print(entropy([0.5, 0.5]))          # 1.0
print(entropy([0.9, 0.1]))          # 约 0.469
print(entropy([1.0, 0.0]))          # 0.0
```

### 交叉熵：衡量两个分布有多不同

```text
交叉熵 H(p, q) = -Σ p(x) · log₂ q(x)

  p 是真实分布，q 是模型预测分布
  · q 越接近 p，交叉熵越小
  · 当 q = p 时，交叉熵等于熵（这是理论下界）

它正是分类任务最常用的损失函数：
  模型对正确答案给出 0.9 的概率 → 损失很小
  模型对正确答案给出 0.1 的概率 → 损失很大
```

```python
def cross_entropy(p: list[float], q: list[float]) -> float:
    return -sum(pi * log2(qi) for pi, qi in zip(p, q) if pi > 0)

print(cross_entropy([1, 0], [0.9, 0.1]))   # 约 0.152
print(cross_entropy([1, 0], [0.1, 0.9]))   # 约 3.32（预测错，损失大）
```

### KL 散度：两个分布的距离（非对称）

```text
KL(p ‖ q) = H(p, q) - H(p)
          = 交叉熵 - 熵

性质：
  · 恒 ≥ 0，当且仅当 p = q 时为 0
  · 不对称：KL(p‖q) ≠ KL(q‖p)
  · 因此它衡量的是「用 q 近似 p 的额外代价」
```

| 概念 | 公式 | 用途 |
| --- | --- | --- |
| 熵 | `-Σ p log p` | 描述数据本身的混乱程度 |
| 交叉熵 | `-Σ p log q` | 分类损失函数 |
| KL 散度 | `H(p,q) - H(p)` | 分布差异、正则化、蒸馏 |

### 互信息：两个变量「共享」多少信息

```text
I(X; Y) = H(X) - H(X | Y) = H(X) + H(Y) - H(X, Y)

含义：知道 Y 之后，X 的不确定性减少多少
  · 完全独立 → 0
  · 完全相关 → 等于各自的熵

用途：
  · 特征选择：挑与标签互信息高的特征
  · 词与类别关联度分析
  · 聚类质量评估（与标签的互信息）
```

```python
from collections import Counter
from math import log2

def mutual_information(pairs: list[tuple[str, str]]) -> float:
    n = len(pairs)
    xy = Counter(pairs)
    x = Counter(a for a, _ in pairs)
    y = Counter(b for _, b in pairs)
    mi = 0.0
    for (a, b), c in xy.items():
        p_xy = c / n
        p_x = x[a] / n
        p_y = y[b] / n
        mi += p_xy * log2(p_xy / (p_x * p_y))
    return mi
```

### 在机器学习与工程中的四个落点

| 场景 | 用到的概念 | 说明 |
| --- | --- | --- |
| 分类损失 | 交叉熵 | 模型输出概率与真实标签的差距 |
| 知识蒸馏 | KL 散度 | 让学生模型贴近教师模型的输出分布 |
| 特征选择 | 互信息 | 挑与目标相关性最强的特征 |
| 压缩与编码 | 熵 | 熵决定理论最短平均编码长度（霍夫曼编码） |

```text
一个常见误解
  「交叉熵越小越好」只在同一份数据上比较模型时才成立；
  不同数据集之间比较损失值没有意义，因为熵底不同。
```

### 自查清单

- [ ] 能写出熵、交叉熵、KL 散度的公式与关系
- [ ] 能解释为什么交叉熵是分类任务的常用损失
- [ ] 知道 KL 散度不对称，不能当成距离度量
- [ ] 能用互信息做一次特征筛选
- [ ] 知道熵给出了压缩的理论下界

