## 微调方式对照

| 方式 | 可训练参数 | 显存需求 | 适用 |
| --- | --- | --- | --- |
| 全参微调 | 100% | 极高 | 有大量数据与算力 |
| LoRA | 约 0.1% 到 1% | 中 | 大多数业务微调 |
| QLoRA | 同上（基座 4bit） | 低 | 单卡消费级显卡 |
| Prefix / P-Tuning | 极少 | 低 | 轻量适配 |
| 适配器（Adapter） | 少量 | 低 | 多任务共用基座 |

## 量化与推理引擎对照

| 方案 | 精度 | 显存 | 特点 |
| --- | --- | --- | --- |
| FP16 / BF16 | 高 | 高 | 基准质量 |
| INT8 | 较高 | 中 | 质量损失小 |
| INT4（GPTQ / AWQ） | 中 | 低 | 常用折中方案 |
| GGUF（llama.cpp） | 可变 | 极低 | CPU 与消费级设备友好 |

| 引擎 | 适用场景 | 特点 |
| --- | --- | --- |
| vLLM | 高吞吐服务 | PagedAttention、连续批处理 |
| TensorRT-LLM | NVIDIA 极致性能 | 编译优化、需转换 |
| SGLang | 结构化与高并发 | RadixAttention 前缀复用 |
| llama.cpp / Ollama | 本地与边缘 | 部署简单、CPU 可用 |
| TGI | 生产服务 | 与 HuggingFace 生态集成 |

```python
def lora_param_count(hidden: int, layers: int, rank: int, targets: int = 4) -> dict:
    """估算 LoRA 参数量与占比，判断显存预算是否可行。"""
    # 每个目标模块加两组低秩矩阵：rank * hidden + hidden * rank
    per_layer = targets * 2 * rank * hidden
    lora_total = per_layer * layers
    # 粗略的基座参数量级（注意力与前馈合计约 12 * hidden^2 每层）
    base_total = 12 * hidden * hidden * layers
    return {
        "lora_params": lora_total,
        "base_params": base_total,
        "ratio": round(lora_total / base_total, 5),
    }


def vram_estimate_gb(params_b: float, bytes_per_param: float, overhead: float = 1.3) -> float:
    """按参数规模估算推理显存：权重 + 额外开销。"""
    weight_gb = params_b * 1e9 * bytes_per_param / (1024 ** 3)
    return round(weight_gb * overhead, 2)


def should_fine_tune(needs: dict) -> str:
    """决策表：先提示工程，再 RAG，最后才微调。"""
    if needs.get("knowledge_updates_frequently"):
        return "用 RAG：知识可随时更新"
    if needs.get("needs_strict_format") or needs.get("needs_style"):
        return "考虑 LoRA 微调：约束输出行为"
    if needs.get("no_training_data"):
        return "先做提示工程与少量示例"
    return "先评测基线，再决定是否微调"


print(lora_param_count(hidden=4096, layers=32, rank=8))
print(vram_estimate_gb(7, 2), vram_estimate_gb(7, 0.5))     # FP16 与 INT4
```

## 微调数据速查

| 要点 | 建议 |
| --- | --- |
| 数据量 | 数百到数万条高质量样本起步 |
| 格式 | 指令-输入-输出，或对话多轮结构 |
| 质量 | 人工抽检准确率，宁少勿滥 |
| 去重 | 精确与近似去重都要做 |
| 覆盖 | 包含边界、拒答与对抗样例 |
| 划分 | 训练、验证、测试严格隔离 |
| 模板 | 与推理时的提示模板保持一致 |
| 评测 | 微调前后同一评测集对比 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用微调补知识 | 知识很快过期 | 知识用 RAG，微调改行为 |
| 训练与推理模板不一致 | 效果明显下降 | 严格复用同一模板与特殊 Token |
| 数据量少且质量差 | 学不到规律还过拟合 | 优先提数据质量与数量 |
| 不做基线评测 | 无法证明微调有效 | 先评测提示工程与 RAG 基线 |
| 学习率过大 | 灾难性遗忘 | 小学习率 + 少量 step + 验证集早停 |
| 只用训练损失判断 | 过拟合无感知 | 看验证集与任务指标 |
| 忽略量化带来的质量差 | 上线后质量下降 | 量化前后同评测集对比 |
| 不做吞吐压测 | 上线后延迟爆炸 | 用目标并发压测 P95 与吞吐 |
| 直接上全参微调 | 成本高收益小 | 先用 LoRA / QLoRA 验证 |
| 不监控线上质量 | 漂移无人知 | 加质量抽检与用户反馈闭环 |

## 自测清单

- [ ] 先评估提示工程与 RAG，再决定是否微调。
- [ ] 微调训练与推理使用同一模板。
- [ ] 量化前后用同一评测集对比质量。
- [ ] 部署引擎按吞吐与延迟目标选择。
- [ ] 有线上质量监控与反馈闭环。
