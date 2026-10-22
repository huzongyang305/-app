## 模态与任务对照

| 模态 | 输入 | 输出 | 典型任务 |
| --- | --- | --- | --- |
| 图像 | 图片 | 文本或标签 | 分类、检测、OCR、理解 |
| 语音 | 音频 | 文本或音频 | 识别、翻译、合成 |
| 视频 | 视频 | 文本或标注 | 摘要、检索、动作识别 |
| 图文混合 | 图 + 文 | 文本 | 图文问答、票据解析 |
| 文档 | PDF / 扫描件 | 结构化字段 | 抽取、问答 |

## 工程要点速查

| 场景 | 建议做法 |
| --- | --- |
| 票据与表单 | OCR 取字 + 规则校验 + 模型理解 |
| 长音频 | 分段（VAD）后识别，再按时间戳拼接 |
| 大图 | 缩放或分块，保留关键区域 |
| 表格 | 转成结构化文本或 HTML 后送入模型 |
| 多图输入 | 标注图片编号，要求按编号引用 |
| 生成内容 | 加水印或元数据标识，声明 AI 生成 |
| 隐私 | 人脸、证件等敏感信息先脱敏 |
| 成本 | 图片 Token 更高，按需降采样与裁剪 |

```python
from dataclasses import dataclass

@dataclass
class MediaSegment:
    start: float
    end: float
    text: str

    @property
    def duration(self) -> float:
        return max(0.0, self.end - self.start)


def merge_segments(segments: list, max_gap: float = 0.8, max_chars: int = 400) -> list:
    """合并过短的语音片段，减少下游调用次数。"""
    merged: list = []
    for seg in segments:
        if merged:
            last = merged[-1]
            if seg.start - last.end <= max_gap and len(last.text) + len(seg.text) <= max_chars:
                merged[-1] = MediaSegment(last.start, seg.end, f"{last.text} {seg.text}".strip())
                continue
        merged.append(seg)
    return merged


def estimate_image_tokens(width: int, height: int, patch: int = 28) -> int:
    """粗略估算图像 Token 数：按切块数量计算。"""
    return max(1, (width // patch) * (height // patch))


def needs_downscale(width: int, height: int, max_side: int = 1536) -> bool:
    """超过最长边阈值时建议降采样，兼顾质量与成本。"""
    return max(width, height) > max_side


segments = [MediaSegment(0, 1.0, "大家好"), MediaSegment(1.2, 2.5, "今天讲多模态")]
print([(s.start, s.end, s.text) for s in merge_segments(segments)])
print(estimate_image_tokens(1024, 1024), needs_downscale(4000, 3000))
```

## 质量与合规速查

| 关注点 | 做法 |
| --- | --- |
| 识别准确率 | 按字段分别统计，金额、单号单独校验 |
| 幻觉 | 关键字段要求引用原文位置 |
| 多语言 | 明确语言或自动检测，术语表统一 |
| 内容安全 | 输入输出双重审核，禁止生成违法内容 |
| 标识 | 生成内容加标识与元数据，便于追溯 |
| 版权 | 训练与生成内容注意授权范围 |
| 隐私 | 不把人脸、声纹等生物特征用于未授权用途 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 让模型直接读原始扫描件取数字 | 关键字段出错 | OCR + 规则校验 + 交叉验证 |
| 长音频整段送入 | 超上下文或截断 | VAD 分段后逐段处理并拼接 |
| 大图不降采样 | 成本高、超时 | 按需缩放或裁剪关键区域 |
| 不标注图片编号 | 回答无法对应 | 每图编号并要求引用 |
| 只信模型输出的金额 | 财务风险 | 与原始 OCR 或规则结果比对 |
| 不做输入内容审核 | 违规内容进入系统 | 前置审核与拦截 |
| 生成内容无标识 | 合规风险 | 加水印或元数据声明 AI 生成 |
| 忽略模态对齐错误 | 图文不匹配 | 校验数量与顺序一致性 |
| 不统计各模态成本 | 成本不可控 | 分别记录文本、图像、音频用量 |
| 不做人工抽检 | 长尾错误无人发现 | 定期抽样并统计字段级准确率 |

## 自测清单

- [ ] 能按模态选择合适的处理链路。
- [ ] 票据类场景使用 OCR + 规则 + 模型三重校验。
- [ ] 长音频与超大图先分段或降采样。
- [ ] 多图输入有编号与引用约束。
- [ ] 生成内容有标识，敏感信息先脱敏。
