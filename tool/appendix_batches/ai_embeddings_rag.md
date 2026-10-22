## RAG 链路速查

| 阶段 | 关键决策 | 常见做法 |
| --- | --- | --- |
| 解析 | 保留结构与页码 | PDF 解析、表格结构化 |
| 分块 | 粒度与重叠 | 300 到 800 Token，重叠 10% 到 20% |
| 嵌入 | 模型与维度 | 中文优先选中文或多语模型 |
| 存储 | 向量库与元数据 | 向量 + 文档 ID + 位置 + 权限 |
| 检索 | 召回策略 | 向量 + 关键词混合，取 top 20 到 50 |
| 重排 | 精排 | Cross-Encoder 取 top 3 到 8 |
| 生成 | 提示构造 | 片段编号 + 要求引用 |
| 评测 | 命中与作答 | 召回率、忠实度、引用准确率 |

## 相似度速查

| 度量 | 公式直觉 | 适用 |
| --- | --- | --- |
| 余弦相似度 | 看方向夹角 | 文本嵌入（最常用） |
| 点积 | 方向与长度都算 | 归一化后等价于余弦 |
| 欧氏距离 | 看空间距离 | 图像特征 |
| 内积最大值搜索（MIPS） | 最大内积 | 推荐与检索 |

重要前提：**查询与文档必须使用同一个嵌入模型与同一版本**，否则向量空间不一致。

```python
import math
from dataclasses import dataclass

def cosine_similarity(a: list[float], b: list[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    norm_a = math.sqrt(sum(x * x for x in a))
    norm_b = math.sqrt(sum(y * y for y in b))
    return 0.0 if norm_a == 0 or norm_b == 0 else dot / (norm_a * norm_b)


@dataclass
class Chunk:
    doc_id: str
    position: int
    text: str
    vector: list[float]
    metadata: dict


def hybrid_score(vector_score: float, keyword_score: float, alpha: float = 0.7) -> float:
    """混合检索：向量分与关键词分加权，alpha 控制偏向。"""
    return alpha * vector_score + (1 - alpha) * keyword_score


def retrieve(query_vec, chunks, top_k=5, filters=None, alpha=0.7, keyword_fn=None):
    """带元数据过滤与混合打分的检索。"""
    scored = []
    for chunk in chunks:
        if filters and not all(chunk.metadata.get(k) == v for k, v in filters.items()):
            continue
        vector_score = cosine_similarity(query_vec, chunk.vector)
        keyword_score = keyword_fn(chunk.text) if keyword_fn else 0.0
        scored.append((hybrid_score(vector_score, keyword_score, alpha), chunk))
    scored.sort(key=lambda item: -item[0])
    return scored[:top_k]


def build_prompt(question: str, hits) -> str:
    """把检索片段编号后拼进提示，便于要求引用来源。"""
    context = "\n\n".join(
        f"[{i + 1}] ({c.doc_id} 第 {c.position} 段)\n{c.text}"
        for i, (_, c) in enumerate(hits)
    )
    return (
        "只能依据下面的资料回答；资料不足时明确说明无法回答。\n"
        "回答末尾用 [编号] 标注引用来源。\n\n"
        f"资料：\n{context}\n\n问题：{question}"
    )


print(round(cosine_similarity([1, 2, 3], [2, 4, 6]), 4))
```

## 分块策略对照

| 策略 | 适用 | 注意 |
| --- | --- | --- |
| 固定长度 | 通用快速方案 | 可能切断句子 |
| 按段落 | 结构清晰的文档 | 段落过长需再切 |
| 按标题层级 | 手册、规范 | 保留标题作为上下文 |
| 语义分块 | 内容主题变化明显 | 计算成本较高 |
| 父子块 | 检索小块、返回大块 | 兼顾精度与上下文 |
| 表格与图表单独处理 | 财务报表、论文 | 转成结构化描述 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 查询与文档用不同嵌入模型 | 检索结果随机 | 统一模型与版本 |
| 分块过大 | 检索噪声多 | 300 到 800 Token，加重叠 |
| 分块过小 | 语义断裂 | 保留标题与上下文前缀 |
| 不做重排 | 相关性不足 | 向量召回后加 Cross-Encoder 精排 |
| 无元数据过滤 | 越权召回他人文档 | 强制按租户与权限过滤 |
| 没有引用信息 | 回答无法核验 | 片段带文档 ID 与位置，回答标引用 |
| 只测检索不测作答 | 端到端质量差 | 分别评测召回与生成 |
| 语料更新后不重建索引 | 用户拿到旧内容 | 变更触发增量索引与版本标记 |
| 直接拼接用户输入 | 提示注入 | 分隔符隔离并声明资料不可信 |
| 忽略文档解析质量 | 表格数字错乱 | 解析后抽样人工校验 |

## 自测清单

- [ ] 能画出 RAG 的完整链路与每阶段决策点。
- [ ] 查询与文档使用同一嵌入模型与版本。
- [ ] 分块粒度合理且保留上下文与来源信息。
- [ ] 检索有元数据权限过滤与重排。
- [ ] 分别评测召回质量与作答质量。
