# 高风险课人工复核包（首批 7 门）

机器校验（内容治理、质量、深度、代码块、术语行）已经全绿，但
`docs/content_review_records.json` 仍是空的：609 门课的人工复核状态为 0。
这份清单把首批最该真人过一遍的 7 门课该看什么写清楚，让复核人不用先
自己找重点。

## 复核人怎么用

1. 打开下表对应的 Markdown（或在 App 里打开课程页）；
2. 按「重点核对点」逐条核对，发现错误直接改内容文件；
3. 在 `docs/content_review_records.json` 的 `human_reviews` 下登记结论；
4. 跑 `dart run tool/content_review_ledger.dart` 刷新台账。

登记模板（`method` 必须是 `human`，自动检查不能记为人工复核）：

```json
{
  "transaction": {
    "reviewer": "真实复核人",
    "method": "human",
    "reviewed_at": "2026-10-08",
    "scope": ["术语", "题目", "代码", "参考资料"],
    "notes": "逐条核对隔离级别与默认值；发现并修正：……"
  }
}
```

## 首批课程与重点核对点

| 课程 | 文件 | 字符数 | 重点核对点 |
| --- | --- | ---: | --- |
| `transaction` | `assets/content/database_transaction.md` | 10919 | ① ACID 四条定义与「原子性/一致性」的边界；② 四个隔离级别对应的脏读、不可重复读、幻读现象；③ 各数据库默认隔离级别的说法；④ 事务里放网络调用、忘 COMMIT、异常不回滚三条错误结论；⑤ 示例 SQL 在 MySQL 8 可直接执行 |
| `mysql_lock_mvcc` | `assets/content/database_mysql_lock_mvcc.md` | 14031 | ① MVCC 的隐藏列/undo log/Read View 表述；② 快照读与当前读的语句归类；③ 间隙锁与 RC/RR 行为差异；④ 锁排查命令与输出解读；⑤ 术语 `age` 的说明是否够清楚 |
| `storage_engine` | `assets/content/database_storage_engine.md` | 11153 | ① 页大小、行格式等 InnoDB 参数；② redo/undo/binlog 三种日志分工；③ 聚簇索引、二级索引与回表/覆盖索引结论；④ 「关闭 binlog 无法做 PITR」的表述；⑤ 题目与正文一致 |
| `virtual_memory` | `assets/content/os_virtual_memory.md` | 10944 | ① 分页地址转换步骤与多级页表；② 缺页中断处理流程与置换算法对比；③ TLB 命中/未命中路径；④ VSZ/RSS/PSS、`vmstat si/so` 的口径；⑤ **本轮重写的术语表 4 条**（虚拟内存/页表/缺页中断/TLB） |
| `scheduling` | `assets/content/os_scheduling.md` | 12974 | ① SJF 结论（平均等待最短、易饥饿、运行时间不可预知）；② 时间片量级；③ 优先级反转与继承/天花板协议；④ 抢占与非抢占的区分；⑤ **本轮重写的术语表 4 条**（调度/时间片/SJF/优先级反转） |
| `ai_agent_security` | `assets/content/ai_agent_security.md` | 13025 | ① 提示注入＝数据与指令混淆的表述；② 最小权限、工具级授权、敏感操作二次确认；③ 沙箱隔离边界（默认禁网、只读挂载、限时长与资源）；④ 与 `ai_guardrails` 的分工是否矛盾；⑤ 题目与解析 |
| `ai_guardrails` | `assets/content/ai_guardrails.md` | 12711 | ① 输入/上下文/输出三段检查点；② 规则与分类模型并用、高风险转人工；③ 命中记录（规则、置信度、处置）可复盘；④ 与 `ai_agent_security` 的边界；⑤ 题目与解析 |

## 本轮已经处理的相关项

- 术语速查体检（新增 `tool/audit_glossary_rows.dart`）发现 278 行待修，
  分布在 189 门课：任务/步骤标题当术语 125 行、英文摘要当说明 62 行、
  模板句 54 行、代码行当说明 37 行；完整清单见
  `docs/glossary_review_backlog.md`。
- 首批课程里已修正 2 门：`os_virtual_memory`（3 行）与 `os_scheduling`
  （2 行）的术语表，其余 5 门术语表本身合格。
- 抽查结论（非人工复核）：7 门课的「常见错误与排查」表格结论均成立，
  未发现事实性错误；数字与阈值仍需要真人对着权威版本再确认一遍。
