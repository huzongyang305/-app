## 训练流程速查

| 阶段 | 关键动作 | 产出 |
| --- | --- | --- |
| 数据准备 | 清洗、去重、划分、模板化 | 训练与验证集 |
| 基线评测 | 未训练模型在同一评测集上的表现 | 基线指标 |
| 试跑 | 小步数验证流程与显存 | 损失曲线与样例输出 |
| 正式训练 | 监控损失、学习率、梯度范数 | 检查点 |
| 评测 | 验证集与任务指标 | 是否达标 |
| 上线 | 灰度与回滚方案 | 线上版本 |

## 超参数速查

| 超参数 | 常用范围 | 说明 |
| --- | --- | --- |
| 学习率 | 1e-5 到 2e-4（全参更小） | 过大导致发散或遗忘 |
| 批大小 | 按显存最大化 | 配合梯度累积 |
| warmup | 总步数的 1% 到 5% | 避免初期破坏预训练权重 |
| 调度器 | 余弦或线性衰减 | 后期稳定收敛 |
| 权重衰减 | 0.01 到 0.1 | 抑制过拟合 |
| 训练轮数 | 1 到 3 轮（指令微调） | 过多易过拟合 |
| LoRA rank | 8 到 64 | 越大容量越高、显存越多 |
| LoRA alpha | 通常为 rank 的 1 到 2 倍 | 控制缩放 |
| 梯度裁剪 | 1.0 | 防止梯度爆炸 |

```python
from dataclasses import dataclass

@dataclass
class MemoryPlan:
    """显存估算与优化组合，判断是否需要量化或分片。"""

    params_b: float
    bytes_per_param_train: float = 16      # 权重 + 梯度 + 优化器状态约 16 字节
    seq_len: int = 4096
    batch_size: int = 4
    activation_per_sample_gb: float = 0.6

    @property
    def weights_gb(self) -> float:
        return self.params_b * 1e9 * self.bytes_per_param_train / (1024 ** 3)

    @property
    def activations_gb(self) -> float:
        return self.activation_per_sample_gb * self.batch_size * (self.seq_len / 4096)

    def total_gb(self) -> float:
        return round(self.weights_gb + self.activations_gb, 2)

    def suggestions(self, vram_gb: float) -> list:
        tips = []
        if self.total_gb() > vram_gb:
            tips.append("启用梯度检查点（用时间换显存）")
            tips.append("用梯度累积降低 micro-batch")
            tips.append("改用 LoRA 或 QLoRA 减少可训练参数")
            if self.seq_len > 2048:
                tips.append("缩短序列长度或使用分块注意力")
            if self.params_b >= 13:
                tips.append("考虑 ZeRO / 张量并行做分片")
        return tips or ["当前配置显存充足"]


def effective_batch_size(micro_batch: int, grad_accum: int, world_size: int = 1) -> int:
    """有效批大小：用于对齐实验与论文配置。"""
    return micro_batch * grad_accum * world_size


plan = MemoryPlan(params_b=7, batch_size=4)
print(plan.total_gb(), plan.suggestions(vram_gb=24))
print(effective_batch_size(micro_batch=2, grad_accum=8, world_size=4))
```

## 训练稳定性速查

| 现象 | 可能原因 | 处理 |
| --- | --- | --- |
| 损失变 NaN | 学习率过大、精度问题 | 降低学习率、用 BF16、加梯度裁剪 |
| 损失不下降 | 学习率过小、数据或模板错误 | 检查模板与标签，提高学习率 |
| 验证集变差 | 过拟合 | 早停、加数据、加正则 |
| 输出重复 | 采样参数或数据问题 | 检查数据质量与惩罚项 |
| 灾难性遗忘 | 训练过久或学习率过大 | 减少步数、混入通用数据 |
| 吞吐异常低 | 数据加载或通信瓶颈 | 增加加载并行、检查网络带宽 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 不做基线评测 | 无法判断训练是否有效 | 先测未训练模型 |
| 不做小规模试跑 | 正式训练中途报错 | 先跑几十步验证流程 |
| 训练与推理模板不一致 | 效果明显下降 | 严格复用同一模板 |
| 学习率直接取最大值 | 损失爆炸或遗忘 | 从小学习率开始并观察曲线 |
| 只看训练损失 | 过拟合无感知 | 同时看验证集与任务指标 |
| 不用梯度检查点 | 显存不足 | 用时间换显存 |
| 不保存中间检查点 | 中断后重头再来 | 定期保存并保留最优 |
| 不记录超参与数据版本 | 结果无法复现 | 配置与数据版本一起记录 |
| 单一随机种子 | 结论不稳 | 多 seed 验证稳定性 |
| 训练完直接全量上线 | 风险高 | 灰度 + 回滚方案 |

## 自测清单

- [ ] 训练前有基线评测与试跑。
- [ ] 训练与推理使用同一模板。
- [ ] 超参数、数据版本与随机种子可复现。
- [ ] 显存不足时按「检查点、累积、LoRA、分片」顺序优化。
- [ ] 上线有灰度与回滚方案。
