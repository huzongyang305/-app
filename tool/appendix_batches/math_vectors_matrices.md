## 向量运算速查

| 运算 | 定义 | 用途 |
| --- | --- | --- |
| 加法 | 对应分量相加 | 位移叠加 |
| 数乘 | 每个分量乘标量 | 缩放 |
| 点积 | 对应分量相乘再求和 | 相似度、夹角、投影 |
| 范数 | 向量长度，`sqrt(Σx²)` | 归一化、距离 |
| 叉积 | 三维向量运算 | 法向量、面积 |
| 余弦相似度 | 点积除以两范数之积 | 文本与向量检索 |

关系式：`a · b = |a||b|cosθ`。点积为 0 意味着正交。

## 矩阵运算速查

| 运算 | 条件 | 结果形状 |
| --- | --- | --- |
| 加法 | 形状相同 | 形状不变 |
| 转置 | 任意 | `m×n` 变 `n×m` |
| 矩阵乘法 | 左列数等于右行数 | `m×p` |
| 矩阵向量乘 | 列数等于向量维数 | 向量 |
| 逆矩阵 | 方阵且行列式非零 | 同形状 |
| 行列式 | 方阵 | 标量，衡量体积缩放 |
| 秩 | 任意 | 线性无关行列的最大数 |

```python
import math
from typing import Sequence

Vector = Sequence[float]
Matrix = Sequence[Sequence[float]]

def dot(a: Vector, b: Vector) -> float:
    if len(a) != len(b):
        raise ValueError("维度不一致")
    return sum(x * y for x, y in zip(a, b))

def norm(a: Vector) -> float:
    return math.sqrt(dot(a, a))

def cosine(a: Vector, b: Vector) -> float:
    na, nb = norm(a), norm(b)
    return 0.0 if na == 0 or nb == 0 else dot(a, b) / (na * nb)

def matmul(a: Matrix, b: Matrix) -> list:
    """矩阵乘法：形状 (m,n) x (n,p) 得到 (m,p)。"""
    if not a or not b or len(a[0]) != len(b):
        raise ValueError("形状不满足乘法条件")
    b_t = list(zip(*b))
    return [[dot(row, col) for col in b_t] for row in a]

def transpose(a: Matrix) -> list:
    return [list(row) for row in zip(*a)]

def project(a: Vector, b: Vector) -> Vector:
    """把 a 投影到 b 上：分量 = (a·b / b·b) * b。"""
    bb = dot(b, b)
    if bb == 0:
        raise ValueError("不能投影到零向量")
    scale = dot(a, b) / bb
    return [scale * value for value in b]

print(round(cosine([1, 2, 3], [2, 4, 6]), 6))          # 1.0，方向相同
print(matmul([[1, 2], [3, 4]], [[5, 6], [7, 8]]))
print(project([3, 4], [1, 0]))
```

## 应用速查

| 场景 | 用到的概念 |
| --- | --- |
| 文本与图像检索 | 余弦相似度、归一化 |
| 推荐系统 | 内积、矩阵分解 |
| 最小二乘拟合 | 投影、伪逆 |
| 图形变换 | 矩阵乘法、齐次坐标 |
| 神经网络前向计算 | 矩阵乘法 + 非线性 |
| 降维与压缩 | 秩、SVD |
| 协同过滤 | 低秩近似 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 忽略矩阵乘法形状 | 结果维度不符或报错 | 先校验中间维度相等 |
| 认为矩阵乘法可交换 | 结果与预期不同 | `AB` 通常不等于 `BA` |
| 对未归一化向量算余弦 | 结果超出直觉范围 | 余弦本身已归一化，但实现要去零 |
| 用点积比较不同长度文本 | 长文本得分虚高 | 先归一化或用余弦 |
| 认为低秩矩阵一定可逆 | 求逆失败 | 秩亏矩阵不可逆 |
| 忽略浮点误差判断秩 | 数值秩判断错误 | 用阈值或 SVD 判断 |
| 用行列式判断数值可逆性 | 病态矩阵被误判可逆 | 看条件数 |
| 混淆广播与逐元素乘法 | 形状或结果错误 | 明确是 Hadamard 积还是矩阵乘 |
| 忽略数值稳定性 | 结果溢出或精度崩溃 | 归一化、用对数域或稳定算法 |
| 把转置符号写反 | 维度错误 | 明确 `(AB)^T = B^T A^T` |

## 自测清单

- [ ] 能计算点积、范数与余弦相似度。
- [ ] 记得矩阵乘法形状规则与不可交换性。
- [ ] 知道投影与最小二乘的关系。
- [ ] 能判断矩阵是否可逆并理解条件数的作用。
- [ ] 会在检索场景中先归一化再比较。
