## NoSQL 类型对照

| 类型 | 数据模型 | 代表 | 强项 | 弱项 |
| --- | --- | --- | --- | --- |
| 键值 | key → value | Redis、etcd | 极快、简单 | 无复杂查询 |
| 文档 | JSON 文档 | MongoDB | 结构灵活、查询较强 | 跨文档事务弱 |
| 宽列 | 行键 + 列族 | Cassandra、HBase | 超高写入、水平扩展 | 查询受限于主键设计 |
| 图 | 点与边 | Neo4j | 关系遍历快 | 通用分析弱 |
| 搜索 | 倒排索引 | Elasticsearch | 全文检索与聚合 | 非权威存储、近实时 |
| 时序 | 时间戳 + 标签 | InfluxDB、TDengine | 高写入压缩比 | 通用事务弱 |

## CAP 与 BASE 速查

| 概念 | 含义 |
| --- | --- |
| C 一致性 | 所有节点看到相同数据 |
| A 可用性 | 每个请求都能得到非错误响应 |
| P 分区容忍 | 网络分区时系统仍可运行 |
| CA / CP / AP | 分区发生时只能二选一：CP 牺牲可用性，AP 牺牲强一致 |
| BASE | 基本可用、软状态、最终一致 |
| 最终一致 | 停止写入后，副本最终收敛一致 |

实践要点：网络分区一定会发生，所以选择实际是在 CP 与 AP 之间。多数系统提供可调一致性（如 `QUORUM`、`ONE`）。

```python
def quorum_needed(replicas: int) -> tuple[int, int]:
    """写与读的法定人数：W + R > N 才能保证读到最新写入。"""
    write = replicas // 2 + 1
    read = replicas - write + 1
    return write, read


print(quorum_needed(3))     # (2, 2)：写 2 读 2 必然有交集
print(quorum_needed(5))     # (3, 3)


def choose_store(needs: dict) -> str:
    """按需求给一个粗略的选型建议。"""
    if needs.get("complex_transaction"):
        return "关系型数据库（PostgreSQL / MySQL）"
    if needs.get("full_text"):
        return "Elasticsearch + 权威存储"
    if needs.get("massive_write"):
        return "宽列存储（Cassandra / HBase）"
    if needs.get("flexible_schema"):
        return "文档数据库（MongoDB）"
    return "键值存储（Redis）"


print(choose_store({"full_text": True}))
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 NoSQL 替代一切 | 事务与一致性难保证 | 按访问模式分工，混合存储常见 |
| 认为 NoSQL 不需要建模 | 后期查询无法支持 | 宽列与文档都必须按查询设计模型 |
| 把 Elasticsearch 当权威存储 | 数据丢失难以恢复 | 权威数据放数据库，搜索做索引 |
| 忽略最终一致的业务影响 | 用户看到过期数据 | 读写路径设计补偿与提示 |
| 无脑选 AP 系统 | 业务出现超卖 | 关键路径用 CP 或加分布式锁 |
| 把 N+1 查询搬到 NoSQL | 依然慢 | 按主键批量取或反范式冗余 |
| 认为扩容就能解决热点 | 单分区仍被打爆 | 重新设计分区键打散热点 |
| 用 Redis 存唯一权威数据 | 重启或淘汰后丢失 | 明确持久化与主存储职责 |
| 忽略文档大小上限 | 写入失败 | 拆分大文档或改用对象存储 |
| 不做容量与压测评估 | 上线后性能不达标 | 用真实数据量与并发压测 |

## 自测清单

- [ ] 能按数据模型与访问模式选对 NoSQL 类型。
- [ ] 能解释 CAP 中 P 必然存在，实际是在 C 与 A 间取舍。
- [ ] 知道 `W + R > N` 是读到自己写入的条件。
- [ ] 搜索型存储不做唯一权威数据源。
- [ ] 最终一致场景有补偿与对账机制。
