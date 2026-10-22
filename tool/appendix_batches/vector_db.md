## 选型对照

| 方案 | 数据规模 | 特点 | 适用 |
| --- | --- | --- | --- |
| pgvector | 百万级以内 | 复用现有 PostgreSQL，事务与过滤强 | 已有 PG、规模不大 |
| Elasticsearch kNN | 千万级 | 与全文检索同栈，混合检索方便 | 已有 ES 的搜索场景 |
| Milvus | 亿级 | 索引丰富、可水平扩展 | 大规模专用场景 |
| Qdrant | 千万到亿级 | 过滤能力强、部署简单 | 需要复杂元数据过滤 |
| Weaviate | 千万级 | 内置混合检索与模块 | 快速搭建 |
| FAISS | 单机 | 纯库、无服务，性能高 | 离线与嵌入式 |
| Redis Vector | 百万级 | 低延迟、与缓存同栈 | 实时性优先 |

选型顺序建议：**先用现有数据库的方案（如 pgvector）跑通，规模或功能不够时再迁移专用向量库。**

## 索引类型速查

| 索引 | 原理 | 召回率 | 内存 | 适用 |
| --- | --- | --- | --- | --- |
| 平铺（Flat） | 暴力精确搜索 | 100% | 高 | 小数据、评测基线 |
| HNSW | 分层小世界图 | 高 | 高 | 低延迟高召回 |
| IVF-Flat | 先聚类再搜桶 | 中高 | 中 | 大数据、内存有限 |
| IVF-PQ | 聚类 + 乘积量化 | 中 | 低 | 超大规模、可接受精度损失 |
| DiskANN | 磁盘图索引 | 中高 | 低 | 数据量超过内存 |

关键参数：

| 参数 | 含义 | 调大后的影响 |
| --- | --- | --- |
| `M`（HNSW） | 每层连接数 | 召回升高、内存与构建时间增加 |
| `efConstruction` | 构建时的候选宽度 | 索引质量更高、构建更慢 |
| `efSearch` | 查询时的候选宽度 | 召回升高、延迟增加 |
| `nlist`（IVF） | 聚类桶数量 | 桶更细、训练更久 |
| `nprobe` | 查询扫描的桶数 | 召回升高、延迟增加 |

```python
import math
from dataclasses import dataclass

def ivf_nlist(num_vectors: int) -> int:
    """IVF 的 nlist 经验值：约为向量数的平方根量级。"""
    return max(1, int(4 * math.sqrt(num_vectors)))


def hnsw_m(dims: int) -> int:
    """HNSW 的 M 经验值：维度越高需要越大（通常 16 到 64）。"""
    if dims <= 256:
        return 16
    if dims <= 1024:
        return 32
    return 48


@dataclass
class RecallReport:
    """用暴力搜索作基线，评估近似索引的召回率。"""

    exact: list
    approx: list

    def recall(self) -> float:
        if not self.exact:
            return 0.0
        return round(len(set(self.exact) & set(self.approx)) / len(self.exact), 4)

    def verdict(self, target: float = 0.95) -> str:
        value = self.recall()
        if value >= target:
            return "达标"
        return f"未达标：提高 efSearch 或 nprobe（当前 {value}）"


def memory_gb(num_vectors: int, dims: int, bytes_per_value: int = 4, overhead: float = 1.3) -> float:
    """向量数据内存估算（含索引开销）。"""
    raw = num_vectors * dims * bytes_per_value / (1024 ** 3)
    return round(raw * overhead, 2)


print(ivf_nlist(1_000_000), hnsw_m(768))
print(RecallReport(exact=[1, 2, 3, 4, 5], approx=[1, 2, 3, 9, 10]).recall())
print(memory_gb(1_000_000, 768))
```

## 调优与运维速查

| 目标 | 手段 | 代价 |
| --- | --- | --- |
| 提高召回 | 提高 `efSearch` 或 `nprobe` | 延迟上升 |
| 降低延迟 | 降维、量化、减少返回条数 | 召回下降 |
| 降低内存 | PQ 量化、磁盘索引 | 精度与延迟取舍 |
| 提高过滤效率 | 常用过滤字段建标量索引 | 写入与存储增加 |
| 提高吞吐 | 分片 + 副本 | 运维复杂度 |
| 降低成本 | 冷热分层、压缩旧向量 | 实现复杂 |

必做的三件事：**用暴力搜索做召回基线、用真实查询分布压测、监控召回率与延迟趋势**。

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 换嵌入模型不重建索引 | 检索结果混乱 | 模型更换必须全量重建 |
| 只用相似度不做过滤 | 越权或结果不相关 | 元数据过滤 + 相似度 |
| 先检索后过滤 | 候选不足、精度差 | 支持过滤的索引或先过滤再检索 |
| 不做召回基线 | 不知道近似索引损失多少 | 用 Flat 索引测召回 |
| 只调延迟不测召回 | 结果悄悄变差 | 两者同时监控 |
| 分片数与数据量不匹配 | 小分片过多或单分片过大 | 按数据量与并发规划 |
| 无维度与内存评估 | 上线后 OOM | 提前估算内存与索引开销 |
| 不做增量更新策略 | 数据陈旧 | 支持 upsert 与删除 |
| 忽略删除后的空间回收 | 存储持续增长 | 定期 compaction 或重建 |
| 只压测空载 | 生产表现不符 | 用真实数据量与查询分布压测 |

## 自测清单

- [ ] 选型从现有数据库方案起步，按规模再升级。
- [ ] 能说出 Flat、HNSW、IVF、PQ 的取舍。
- [ ] 用暴力搜索做召回基线并持续监控召回率。
- [ ] 过滤条件下推，避免「先检索后过滤」导致候选不足。
- [ ] 换嵌入模型时全量重建索引。
