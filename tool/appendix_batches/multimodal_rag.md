## 多模态分块速查

| 内容类型 | 分块策略 | 说明 |
| --- | --- | --- |
| 正文段落 | 按语义单元，300 到 800 Token | 保留标题路径 |
| 表格 | 转成结构化描述或 Markdown | 保留表头与单位 |
| 图表 | 生成描述 + 原始图片引用 | 描述用于检索，原图用于引用 |
| 公式 | 用 LaTeX 保留 | 避免图片化丢失信息 |
| 扫描件 | OCR 后按版面分块 | 保留页码与坐标 |
| 幻灯片 | 一页一块 | 页标题作为上下文前缀 |

## 检索与溯源速查

| 环节 | 要求 |
| --- | --- |
| 向量表示 | 文本与图像映射到同一空间（多模态嵌入） |
| 元数据 | 文档 ID、页码、块序号、模态类型、权限 |
| 混合检索 | 文本关键词 + 向量 + 图表描述 |
| 重排 | 对候选片段精排，控制噪声 |
| 生成 | 片段带编号，回答必须引用编号 |
| 展示 | 前端支持点击引用跳转到原图与页码 |

```python
from dataclasses import dataclass, field

@dataclass
class MultiModalChunk:
    chunk_id: str
    modality: str          # text / table / image / formula
    content: str           # 文本，或图片/图表的文字描述
    doc_id: str
    page: int
    asset_uri: str | None = None
    metadata: dict = field(default_factory=dict)

    def citation(self) -> str:
        label = {"text": "段落", "table": "表格", "image": "图", "formula": "公式"}
        return f"{self.doc_id} 第 {self.page} 页{label.get(self.modality, '内容')}"


def build_context(hits: list) -> str:
    """构造带编号与来源的上下文，要求模型只依据这些内容作答。"""
    blocks = [
        f"[{i + 1}] {chunk.citation()}\n{chunk.content}"
        for i, chunk in enumerate(hits)
    ]
    return "可用资料如下，回答必须引用编号，资料不足时说明无法回答。\n\n" + "\n\n".join(blocks)


def citation_coverage(answer: str, hit_count: int) -> float:
    """统计回答里出现的引用编号覆盖率，用于评测可溯源性。"""
    if hit_count == 0:
        return 0.0
    cited = {i for i in range(1, hit_count + 1) if f"[{i}]" in answer}
    return round(len(cited) / hit_count, 4)


hits = [
    MultiModalChunk("c1", "table", "2024 年营收 1.2 亿元", "report-2024", 12),
    MultiModalChunk("c2", "image", "折线图显示三季度环比增长 15%", "report-2024", 13, "s3://x/p13.png"),
]
print(build_context(hits))
print(citation_coverage("营收为 1.2 亿元 [1]，三季度环比增长 15% [2]", len(hits)))
```

## 工程要点速查

| 要点 | 做法 |
| --- | --- |
| 解析质量 | 抽样人工校验关键字段 |
| 图片存储 | 原图放对象存储，索引只存 URI |
| 权限 | 检索时按用户权限过滤元数据 |
| 增量更新 | 文档变更触发局部重建索引 |
| 成本 | 图表描述可按需生成并缓存 |
| 评测 | 分别评测文本检索、图表检索与引用准确性 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只索引正文忽略图表 | 图表问题无法回答 | 图表生成描述后一起入库 |
| 图片描述过于笼统 | 检索命中率低 | 包含关键数值、单位与趋势 |
| 不保留原始图片 | 无法人工核验 | 索引存 URI，原图可点开 |
| 表格转成纯文本丢表头 | 数值含义错位 | 保留表头与单位 |
| 共用一套嵌入模型处理所有模态 | 相似度不可比 | 用多模态嵌入或分别建索引 |
| 不做权限过滤 | 越权检索到他人资料 | 检索阶段强制过滤 |
| 引用编号与片段不匹配 | 溯源错误 | 生成后校验编号存在性 |
| 文档更新不重建 | 检索到旧内容 | 变更触发增量重建 |
| 只测文本问答 | 图表场景未验证 | 评测集覆盖表格与图表 |
| 无人工抽检 | 解析错误长期存在 | 定期抽样校验关键字段 |

## 自测清单

- [ ] 不同模态有各自的分块与表示策略。
- [ ] 片段带文档、页码、块序号与权限元数据。
- [ ] 回答强制引用编号，前端可跳转原图。
- [ ] 检索阶段做权限过滤，避免越权。
- [ ] 评测覆盖文本、表格、图表与引用准确性。
