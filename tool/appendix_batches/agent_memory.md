## 记忆分层速查

| 层 | 内容 | 存储 | 生命周期 |
| --- | --- | --- | --- |
| 工作记忆 | 当前对话上下文 | 内存 / 上下文窗口 | 单次会话 |
| 会话摘要 | 历史对话压缩 | 数据库 | 中期 |
| 长期语义记忆 | 事实、偏好、结论 | 向量库 + 关系库 | 长期 |
| 情景记忆 | 具体事件与结果 | 事件表 | 长期，可归档 |
| 程序性记忆 | 常用流程与工具用法 | 提示模板库 | 长期 |

## 写入与检索速查

| 环节 | 建议 |
| --- | --- |
| 写入时机 | 会话结束、用户显式要求、重要事件发生时 |
| 写入内容 | 结构化字段：类型、主体、内容、时间、来源 |
| 去重 | 相似度阈值 + 唯一键，避免重复记忆 |
| 冲突处理 | 新记忆覆盖旧记忆时保留历史版本 |
| 检索 | 向量检索 + 元数据过滤（用户、类型、时间） |
| 排序 | 相似度 + 新近度 + 重要性加权 |
| 注入 | 只注入最相关的少量记忆，避免污染上下文 |
| 清理 | TTL + 容量上限 + 用户删除接口 |

```python
import math
import time
from dataclasses import dataclass, field

@dataclass
class Memory:
    memory_id: str
    user_id: str
    content: str
    kind: str                   # preference / fact / event
    created_at: float
    importance: float = 0.5     # 0 到 1
    vector: tuple = ()
    source: str = "chat"

    def age_days(self, now: float | None = None) -> float:
        now = time.time() if now is None else now
        return (now - self.created_at) / 86400


def cosine(a: tuple, b: tuple) -> float:
    if not a or not b:
        return 0.0
    dot = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    return 0.0 if na == 0 or nb == 0 else dot / (na * nb)


def score(memory: Memory, query_vec: tuple, now: float | None = None) -> float:
    """综合相似度、新近度与重要性的记忆打分。"""
    similarity = cosine(query_vec, memory.vector)
    recency = math.exp(-memory.age_days(now) / 30)      # 30 天半衰期
    return round(0.6 * similarity + 0.2 * recency + 0.2 * memory.importance, 4)


def retrieve(memories: list, query_vec: tuple, user_id: str, top_k: int = 5) -> list:
    """检索前先按用户隔离，避免跨用户记忆泄漏。"""
    candidates = [m for m in memories if m.user_id == user_id]
    ranked = sorted(candidates, key=lambda m: -score(m, query_vec))
    return ranked[:top_k]


def should_write(memory: Memory, existing: list, threshold: float = 0.92) -> bool:
    """写入前去重：与已有记忆过于相似则不再写入。"""
    return all(cosine(memory.vector, m.vector) < threshold for m in existing)


now = time.time()
memories = [
    Memory("m1", "u1", "偏好简洁回答", "preference", now - 86400, 0.8, (0.9, 0.1, 0.0)),
    Memory("m2", "u2", "另一用户的偏好", "preference", now, 0.9, (0.9, 0.1, 0.0)),
]
print([m.memory_id for m in retrieve(memories, (0.85, 0.15, 0.0), "u1")])
```

## 合规要点速查

| 要求 | 做法 |
| --- | --- |
| 用户知情 | 明确告知会记录哪些内容 |
| 可查看 | 提供记忆列表查询接口 |
| 可删除 | 提供单条与全部删除能力 |
| 可导出 | 支持导出为结构化数据 |
| 最小化 | 只存必要信息，敏感字段不入库 |
| 隔离 | 按用户与租户严格隔离 |
| 保留期 | 明确 TTL 与自动清理策略 |
| 审计 | 记录记忆的读写与删除操作 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 把整段对话都存为记忆 | 噪声大、检索差 | 结构化摘要后再写入 |
| 不做去重 | 记忆重复、上下文膨胀 | 相似度阈值 + 唯一键 |
| 不做用户隔离 | 跨用户泄漏 | 检索前强制按用户过滤 |
| 只按相似度排序 | 重要记忆被淹没 | 相似度 + 新近度 + 重要性加权 |
| 检索结果全量注入 | 上下文被污染 | 只注入 top 少量记忆 |
| 无可视化与删除入口 | 合规不达标 | 提供查看、删除与导出 |
| 记忆永不过期 | 存储无限增长 | TTL + 容量上限 |
| 冲突记忆不处理 | 行为前后矛盾 | 覆盖时保留版本并标注时间 |
| 把模型猜测写入记忆 | 错误长期留存 | 只写入用户确认或高置信信息 |
| 不做访问审计 | 泄漏无法追溯 | 记录读写与删除日志 |

## 自测清单

- [ ] 记忆分层清晰：工作、会话摘要与长期记忆分离。
- [ ] 写入前去重，冲突时保留历史版本。
- [ ] 检索做用户隔离并按相似度、新近度、重要性综合排序。
- [ ] 用户可查看、删除与导出自己的记忆。
- [ ] 有 TTL、容量上限与访问审计。
