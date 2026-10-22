## 倒排索引速查

| 概念 | 说明 |
| --- | --- |
| 词项（term） | 分词后的最小检索单位 |
| 倒排表 | 词项到文档 ID 列表的映射 |
| 位置信息 | 记录词项在文档中的位置，支持短语查询 |
| 词频 TF | 词在文档中出现次数 |
| 文档频率 DF | 包含该词的文档数 |
| 段（segment） | 索引的最小存储单位，不可变 |
| 合并（merge） | 把多个段合并成大段，回收删除标记 |
| refresh | 让新写入文档可被搜索（默认约 1 秒） |
| flush | 把数据持久化到磁盘 |

## 相关性打分速查

| 因素 | 影响 |
| --- | --- |
| TF | 词出现越多越相关（有饱和） |
| IDF | 词越稀有越有区分度 |
| 字段长度 | 短字段命中权重更高 |
| 字段权重 | `title^3` 提高标题权重 |
| 协调因子 | 命中查询词越多越相关（BM25 已简化） |

BM25 是工业界默认打分模型；需要语义相似时叠加向量检索，形成混合检索。

```json
// 建索引：显式定义映射，避免动态推断导致类型不符合预期
PUT /articles
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1,
    "refresh_interval": "1s"
  },
  "mappings": {
    "properties": {
      "title":   { "type": "text", "analyzer": "ik_max_word" },
      "content": { "type": "text", "analyzer": "ik_max_word" },
      "tags":    { "type": "keyword" },
      "author_id": { "type": "keyword" },
      "created_at": { "type": "date" },
      "embedding": {
        "type": "dense_vector",
        "dims": 768,
        "index": true,
        "similarity": "cosine"
      }
    }
  }
}
```

```json
// 混合检索：关键词打分 + 向量召回 + 元数据过滤
POST /articles/_search
{
  "size": 10,
  "query": {
    "bool": {
      "must": [
        { "multi_match": { "query": "分布式事务", "fields": ["title^3", "content"] } }
      ],
      "filter": [
        { "term":  { "tags": "backend" } },
        { "range": { "created_at": { "gte": "2025-01-01" } } }
      ]
    }
  },
  "sort": [ { "_score": "desc" }, { "created_at": "desc" } ]
}
```

| 操作 | 代价 | 说明 |
| --- | --- | --- |
| `filter` | 便宜且可缓存 | 只做筛选，不参与打分 |
| `must` | 参与打分 | 影响相关性 |
| `should` | 加分 | 满足会提升排序 |
| `must_not` | 排除 | 不参与打分 |
| 深分页 `from + size` | 昂贵（默认上限 10000） | 改用 `search_after` 游标 |
| 聚合 | 昂贵 | 限制桶数与基数 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 把 ES 当唯一数据源 | 数据丢失无法恢复 | 权威数据入库，ES 做索引 |
| 动态映射不做约束 | 字段类型推断错误 | 显式定义 mapping |
| 深分页用大 `from` | 内存暴涨、超时 | 用 `search_after` 或滚动查询 |
| 用 `text` 做精确匹配 | 匹配结果不符合预期 | 精确值用 `keyword` |
| 中文不装分词器 | 分词效果差 | 使用 IK 等中文分词插件 |
| 大量段不合并 | 查询变慢 | 控制 refresh 频率并让后台合并 |
| 一次性重建索引 | 线上查询不可用 | 用别名 + 双写 + 原子切换 |
| 聚合基数不设上限 | OOM | 用 `composite` 分页聚合 |
| 忽略副本与分片规划 | 扩容困难 | 分片数按数据量与增长预估 |
| 索引不设保留策略 | 磁盘被写满 | 按时间滚动索引并配置 ILM |

## 自测清单

- [ ] 能解释倒排索引与 `text` / `keyword` 的差别。
- [ ] 知道 `filter` 比 `must` 便宜且可缓存。
- [ ] 深分页改用 `search_after`。
- [ ] 中文检索配置合适的分词器。
- [ ] 重建索引用别名切换，做到零停机。
