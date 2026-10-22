## 导数与梯度速查

| 概念 | 含义 | 用途 |
| --- | --- | --- |
| 导数 | 函数变化率 | 一维优化 |
| 偏导数 | 对单个变量求导 | 多元函数 |
| 梯度 | 偏导组成的向量 | 上升最快方向 |
| 方向导数 | 某方向的变化率 | 最速下降方向为负梯度 |
| 二阶导 / Hessian | 曲率信息 | 判断极值与收敛速度 |
| 链式法则 | 复合函数求导 | 反向传播基础 |
| 雅可比矩阵 | 向量值函数的一阶导 | 向量反向传播 |

更新规则：`θ ← θ - η ∇L(θ)`，其中 η 是学习率。

## 优化器速查

| 优化器 | 核心思想 | 特点 |
| --- | --- | --- |
| 批量梯度下降 | 用全部样本算梯度 | 稳定但慢 |
| 随机梯度下降 | 单样本更新 | 抖动大、可能逃离局部极小 |
| 小批量 SGD | 折中方案 | 实践默认 |
| Momentum | 累积历史梯度 | 加速并抑制震荡 |
| RMSProp | 梯度平方的滑动平均 | 自适应步长 |
| Adam | 一阶与二阶矩估计 | 收敛快、常用 |
| AdamW | 解耦权重衰减 | 大模型训练常用 |

```python
import math
from typing import Callable

def numerical_gradient(f: Callable, point: list, eps: float = 1e-6) -> list:
    """数值梯度：用小扰动近似偏导，用于校验解析梯度。"""
    grad = []
    for index in range(len(point)):
        forward, backward = list(point), list(point)
        forward[index] += eps
        backward[index] -= eps
        grad.append((f(forward) - f(backward)) / (2 * eps))
    return [round(value, 6) for value in grad]

def gradient_descent(f, grad_f, start: list, lr: float = 0.1, steps: int = 100):
    """梯度下降：记录损失曲线并返回最优点。"""
    point = list(start)
    history = []
    for _ in range(steps):
        gradient = grad_f(point)
        point = [p - lr * g for p, g in zip(point, gradient)]
        history.append(round(f(point), 8))
    return point, history

def sgd_momentum(grad_f, start: list, lr: float = 0.1, momentum: float = 0.9, steps: int = 50):
    """带动量的小批量更新：累积历史梯度减少震荡。"""
    point, velocity = list(start), [0.0] * len(start)
    for _ in range(steps):
        gradient = grad_f(point)
        velocity = [momentum * v - lr * g for v, g in zip(velocity, gradient)]
        point = [p + v for p, v in zip(point, velocity)]
    return [round(value, 6) for value in point]

def adam_step(param, grad, m, v, t, lr=0.001, beta1=0.9, beta2=0.999, eps=1e-8):
    """Adam 单步更新：含偏差校正。"""
    m = beta1 * m + (1 - beta1) * grad
    v = beta2 * v + (1 - beta2) * grad * grad
    m_hat = m / (1 - beta1 ** t)
    v_hat = v / (1 - beta2 ** t)
    return param - lr * m_hat / (math.sqrt(v_hat) + eps), m, v

f = lambda p: (p[0] - 3) ** 2 + (p[1] + 1) ** 2
grad_f = lambda p: [2 * (p[0] - 3), 2 * (p[1] + 1)]
print(numerical_gradient(f, [0.0, 0.0]))
point, history = gradient_descent(f, grad_f, [0.0, 0.0])
print([round(v, 4) for v in point], history[0], history[-1])
```

## 学习率与收敛速查

| 现象 | 可能原因 | 处理 |
| --- | --- | --- |
| 损失震荡或发散 | 学习率过大 | 降低学习率或加 warmup |
| 收敛极慢 | 学习率过小 | 提高学习率或换自适应优化器 |
| 后期来回跳 | 没有衰减 | 加余弦或阶梯衰减 |
| 训练初期不稳 | 初始更新过大 | 加 warmup |
| 梯度爆炸 | 深网络或长序列 | 梯度裁剪、归一化 |
| 梯度消失 | 深层链式乘积衰减 | 残差连接、合理初始化 |
| 过拟合 | 训练损失持续降但验证升 | 正则、早停、加数据 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用梯度方向做上升 | 损失越来越大 | 更新用负梯度 |
| 学习率一次调很大 | 损失 NaN | 从小值开始并观察曲线 |
| 同时调学习率与批大小 | 无法归因 | 一次只改一个超参数 |
| 不做梯度校验 | 反向传播实现有错却不自知 | 用数值梯度对比解析梯度 |
| 不裁剪梯度 | 训练不稳定 | 设梯度裁剪阈值（如 1.0） |
| 用测试集选超参数 | 指标虚高 | 只在验证集上调参 |
| 认为 Adam 无需调参 | 收敛快但泛化未必好 | 仍需调学习率与权重衰减 |
| 忽略学习率调度 | 后期难以收敛到精细解 | 加衰减与 warmup |
| 特征量纲差异大 | 优化呈锯齿状 | 标准化输入 |
| 只看最终损失 | 漏掉发散或过拟合 | 记录损失曲线与验证指标 |

## 自测清单

- [ ] 能解释梯度方向与负梯度更新的关系。
- [ ] 会用数值梯度校验解析梯度。
- [ ] 能识别学习率过大与过小的典型现象。
- [ ] 知道 Momentum、RMSProp、Adam 的差别。
- [ ] 训练时监控损失曲线与验证指标。
