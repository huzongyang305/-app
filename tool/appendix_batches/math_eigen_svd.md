## 特征分解与 SVD 速查

| 概念 | 定义 | 说明 |
| --- | --- | --- |
| 特征值 λ | `Av = λv` 中的 λ | 表示该方向上的伸缩倍率 |
| 特征向量 v | 被 A 作用后方向不变 | 只被拉伸或压缩 |
| 特征分解 | `A = Q Λ Q⁻¹` | 需要可对角化 |
| 对称矩阵 | `A = Aᵀ`，特征值实数、特征向量正交 | 应用最广 |
| 奇异值 σ | `AᵀA` 特征值的平方根 | 非负，按大小排列 |
| SVD | `A = U Σ Vᵀ` | 任意矩阵都成立 |
| 低秩近似 | 保留前 k 个奇异值 | Eckart-Young 最优 |
| 条件数 | 最大与最小奇异值之比 | 衡量病态程度 |

## 降维速查

| 方法 | 原理 | 特点 |
| --- | --- | --- |
| PCA | 对中心化数据做 SVD | 线性、无监督、最大方差 |
| 截断 SVD | 直接保留前 k 个奇异值 | 稀疏矩阵友好 |
| NMF | 非负矩阵分解 | 结果可解释（如词主题） |
| t-SNE / UMAP | 非线性降维 | 可视化好，不保留全局距离 |

```python
import math

Matrix = list

def power_iteration(matrix: Matrix, iterations: int = 500, tol: float = 1e-9):
    """幂迭代：求主特征值与主特征向量（适合较大稀疏矩阵）。"""
    n = len(matrix)
    vector = [1.0 / math.sqrt(n)] * n
    eigenvalue = 0.0
    for _ in range(iterations):
        product = [sum(matrix[i][j] * vector[j] for j in range(n)) for i in range(n)]
        norm = math.sqrt(sum(value * value for value in product))
        if norm == 0:
            return 0.0, [0.0] * n
        new_vector = [value / norm for value in product]
        new_eigenvalue = sum(new_vector[i] * product[i] for i in range(n))
        if abs(new_eigenvalue - eigenvalue) < tol:
            vector, eigenvalue = new_vector, new_eigenvalue
            break
        vector, eigenvalue = new_vector, new_eigenvalue
    return round(eigenvalue, 6), [round(value, 6) for value in vector]

def condition_number(singular_values: list) -> float:
    """条件数：最大与最小奇异值之比，越大越病态。"""
    smallest = min(singular_values)
    if smallest == 0:
        return float("inf")
    return round(max(singular_values) / smallest, 4)

def explained_variance_ratio(singular_values: list, k: int) -> float:
    """前 k 个奇异值解释的方差占比。"""
    total = sum(value * value for value in singular_values)
    if total == 0:
        return 0.0
    kept = sum(value * value for value in singular_values[:k])
    return round(kept / total, 4)

def low_rank_error(singular_values: list, k: int) -> float:
    """截断到前 k 个后的误差（Frobenius 范数意义下）。"""
    return round(math.sqrt(sum(value * value for value in singular_values[k:])), 6)

print(power_iteration([[2, 1], [1, 2]]))
print(condition_number([10, 5, 0.1]), explained_variance_ratio([10, 5, 0.1], 2))
```

## 应用速查

| 场景 | 用法 |
| --- | --- |
| PCA 降维 | 中心化后 SVD，取前 k 个主成分 |
| 图像压缩 | 保留少量奇异值重构近似图 |
| 推荐系统 | 用户-物品矩阵低秩分解 |
| 潜在语义分析 | 词-文档矩阵 SVD |
| LoRA 微调 | 用低秩矩阵近似权重更新 |
| 主成分可视化 | 取前两个主成分作图 |
| 数值稳定性诊断 | 用条件数判断是否病态 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| PCA 前不标准化 | 量纲大的特征主导 | 先标准化（z-score） |
| 用 SVD 前不中心化 | 结果受均值影响 | PCA 必须先中心化 |
| 认为所有矩阵都可特征分解 | 分解失败 | 非对称矩阵可能不可对角化，用 SVD |
| 奇异值取负数 | 概念错误 | 奇异值非负 |
| 用条件数判断是否可逆 | 误判 | 条件数衡量病态程度，可逆性看奇异值是否为 0 |
| 随便选 k 值 | 信息损失或降维不足 | 看解释方差比例或肘部法 |
| 用 t-SNE 距离解释全局结构 | 结论错误 | 它只保留局部邻域结构 |
| 浮点误差当作真实小奇异值 | 秩判断错误 | 设阈值或用相对判定 |
| 对稀疏大矩阵直接求全 SVD | 内存与时间爆炸 | 用截断 SVD 或随机化算法 |
| 忽略数值缩放 | 条件数恶化 | 归一化与正则化 |

## 自测清单

- [ ] 能解释特征值与特征向量的几何意义。
- [ ] 知道 SVD 适用于任意矩阵且奇异值非负。
- [ ] 会计算解释方差比例并据此选择 k。
- [ ] 理解条件数与病态问题的关系。
- [ ] 知道 PCA 需要先中心化与标准化。
