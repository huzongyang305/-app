## 概念层级速查

| 层级 | 关注点 | 例子 |
| --- | --- | --- |
| 人工智能 | 让机器表现出智能行为 | 规划、推理、感知 |
| 机器学习 | 从数据中学习规律 | 回归、分类、聚类 |
| 深度学习 | 用多层神经网络表示特征 | CNN、Transformer |
| 生成式 AI | 生成新内容 | 文本、图像、音频、视频 |
| 大语言模型 | 大规模预训练的文本模型 | GPT、Claude、Llama、Qwen |

## 模型类型对照

| 类型 | 输入到输出 | 典型任务 |
| --- | --- | --- |
| 判别式 | 输入到标签 | 分类、检测、排序 |
| 生成式 | 输入到新内容 | 写作、绘图、语音合成 |
| 嵌入模型 | 文本到向量 | 检索、聚类、去重 |
| 重排模型 | 查询与文档对到分数 | 精排 |
| 多模态模型 | 多模态输入到文本或内容 | 图文问答、OCR 理解 |

```python
from dataclasses import dataclass

@dataclass
class TokenBudget:
    """上下文预算：把窗口切成提示、资料、输出三部分。"""

    window: int                 # 模型上下文上限
    prompt: int                 # 系统提示与指令
    retrieved: int              # 检索资料
    output: int                 # 预留输出

    @property
    def used(self) -> int:
        return self.prompt + self.retrieved + self.output

    @property
    def remaining(self) -> int:
        return self.window - self.used

    def fits(self) -> bool:
        return self.remaining >= 0

    def trim_retrieved(self) -> "TokenBudget":
        """超预算时优先裁剪检索资料，保证提示与输出完整。"""
        if self.fits():
            return self
        overflow = -self.remaining
        return TokenBudget(
            self.window, self.prompt,
            max(0, self.retrieved - overflow),
            self.output,
        )


def estimate_tokens(text: str, chars_per_token: float = 1.6) -> int:
    """粗略估算 Token 数：中文约 1 字 1 到 2 Token，英文约 4 字符 1 Token。"""
    return max(1, int(len(text) / chars_per_token))


budget = TokenBudget(window=128_000, prompt=2_000, retrieved=90_000, output=4_000)
print(budget.fits(), budget.remaining)
print(estimate_tokens("请把下面这段中文总结成三句话。"))
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 把「生成式 AI」等同于「大模型」 | 概念混淆 | 生成式 AI 含图像、语音等多种模型 |
| 认为模型参数越多越好 | 成本与延迟失控 | 按任务难度选型，小模型 + 路由常更划算 |
| 按字符数估 Token | 预算估算偏差大 | 中文与代码的 Token 密度不同，按实测校准 |
| 忽略上下文窗口限制 | 请求被截断或报错 | 预留输出空间并裁剪资料 |
| 认为模型输出一定正确 | 幻觉进入生产 | 提供依据 + 校验 + 兜底话术 |
| 用大模型做纯规则任务 | 成本高且不稳定 | 规则能解决就用规则 |
| 不记录模型版本 | 结果变化无法归因 | 记录模型名、版本与参数 |
| 忽略推理参数影响 | 输出不稳定 | 明确温度、top_p 与最大输出长度 |
| 直接处理敏感数据 | 合规风险 | 脱敏、鉴权与私有部署 |
| 只做 Demo 不做评测 | 上线后质量不可控 | 建离线评测集并持续回归 |

## 自测清单

- [ ] 能画出 AI、机器学习、深度学习、生成式 AI 的层级关系。
- [ ] 能按任务选择合适的模型类型（判别、生成、嵌入、重排）。
- [ ] 会为请求做 Token 预算并预留输出空间。
- [ ] 知道幻觉无法完全消除，必须用检索与校验兜底。
- [ ] 模型版本与推理参数都进入配置管理与评测。
