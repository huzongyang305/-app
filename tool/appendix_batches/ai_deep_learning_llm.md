## Transformer 结构速查

| 组件 | 作用 |
| --- | --- |
| 词嵌入 | 把 Token 映射为向量 |
| 位置编码 | 注入位置信息（RoPE 等） |
| 多头自注意力 | 建模序列内的长距离依赖 |
| 前馈网络 | 逐位置非线性变换，占多数参数 |
| 残差与归一化 | 稳定训练，支持深层堆叠 |
| 输出头 | 映射到词表概率分布 |

| 注意力 | 可见范围 | 典型用途 |
| --- | --- | --- |
| 双向（Encoder） | 全序列 | 理解、嵌入、分类 |
| 因果（Decoder） | 只能看左侧 | 生成式模型 |
| 交叉注意力 | 编码器到解码器 | 翻译、语音识别 |

## 训练三阶段速查

| 阶段 | 数据 | 目标 | 成本 |
| --- | --- | --- | --- |
| 预训练 | 海量无标注文本 | 预测下一个 Token | 极高 |
| 指令微调（SFT） | 指令与答案对 | 学会遵循指令 | 中 |
| 偏好对齐（RLHF / DPO） | 人类偏好对比 | 更符合人类偏好与安全要求 | 中高 |

## 推理参数速查

| 参数 | 作用 | 建议 |
| --- | --- | --- |
| temperature | 控制随机性 | 事实类 0 到 0.3，创意类 0.7 到 1.0 |
| top_p | 核采样阈值 | 与 temperature 二选一调整 |
| top_k | 只保留前 k 个候选 | 需要强约束时使用 |
| max_tokens | 输出上限 | 按业务设上限控制成本 |
| stop | 停止序列 | 结构化输出时避免多余内容 |
| presence/frequency penalty | 抑制重复 | 长文生成时适度使用 |
| seed | 复现性（若支持） | 评测时固定 |

```python
import math

def softmax(logits: list[float], temperature: float = 1.0) -> list[float]:
    """温度采样：温度越低分布越尖锐，越高越平均。"""
    if temperature <= 0:
        raise ValueError("温度必须为正，贪心解码请单独实现")
    scaled = [value / temperature for value in logits]
    top = max(scaled)
    exps = [math.exp(value - top) for value in scaled]
    total = sum(exps)
    return [value / total for value in exps]


def top_p_filter(probs: list[float], top_p: float = 0.9) -> list[int]:
    """核采样：累计概率达到 top_p 的最小候选集合。"""
    order = sorted(range(len(probs)), key=lambda i: -probs[i])
    kept, cumulative = [], 0.0
    for index in order:
        kept.append(index)
        cumulative += probs[index]
        if cumulative >= top_p:
            break
    return kept


def attention_shapes(seq_len: int, d_model: int, heads: int) -> dict:
    """多头注意力张量形状，便于排查维度错误。"""
    d_head = d_model // heads
    return {
        "qkv": (seq_len, d_model),
        "per_head": (heads, seq_len, d_head),
        "attention_matrix": (heads, seq_len, seq_len),
    }


print([round(p, 3) for p in softmax([2.0, 1.0, 0.1], temperature=0.5)])
print(attention_shapes(seq_len=1024, d_model=4096, heads=32))
```

## 幻觉与可控性速查

| 手段 | 作用 | 限制 |
| --- | --- | --- |
| 检索增强（RAG） | 用外部依据约束回答 | 依赖检索质量 |
| 结构化输出 | 限制格式，便于校验 | 不能保证内容正确 |
| 引用来源 | 可溯源、可抽查 | 需要文档与位置信息 |
| 拒答话术 | 无依据时明确说不知道 | 需要评测拒答率 |
| 自一致性投票 | 多次采样取多数 | 成本成倍增加 |
| 工具校验 | 用计算器、代码执行验证 | 需为工具结果设计兜底 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 认为模型「记住」了事实 | 幻觉频发 | 事实依赖外部数据源与检索 |
| 只调 temperature 追求稳定 | 输出仍波动 | 固定 seed、降低温度、加结构化约束 |
| 同时调 temperature 与 top_p | 效果难归因 | 一次只调一个参数 |
| 忽略上下文长度 | 长文档被截断 | 分块检索或使用长上下文模型 |
| 认为参数多必然更好 | 成本与延迟上升 | 按任务选型并做 A/B |
| 不做输出校验 | 非法 JSON 进入系统 | 用 Schema 校验并重试 |
| 认为微调能补知识 | 知识更新滞后 | 知识用 RAG，行为与格式用微调 |
| 忽略位置编码长度限制 | 超长文本质量骤降 | 明确有效长度并做评测 |
| 用测试集调推理参数 | 指标虚高 | 参数调优只看验证集 |
| 不记录推理参数 | 线上问题无法复现 | 参数随请求一起入库 |

## 自测清单

- [ ] 能说出 Transformer 的主要组件与作用。
- [ ] 记得预训练、SFT、偏好对齐三阶段的目标。
- [ ] 会按任务设置温度与输出上限。
- [ ] 知道幻觉只能抑制，无法根除，必须配合检索与校验。
- [ ] 推理参数与模型版本进入请求日志。
