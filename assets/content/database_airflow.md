# Airflow 调度与数据质量

![Airflow 调度与数据质量](images/remaining_airflow_quality.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「Airflow 调度与数据质量」解决了什么问题，而不是只背术语。
- 能说清 「Airflow」、「DAG」、「幂等」、「backfill」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「数据库」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：DAG/幂等/backfill 与六项数据质量检查。

## 前置知识

- 先完成上一课《数据湖与湖仓一体》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：Airflow、DAG、幂等。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## DAG 与核心概念

Airflow 用 DAG（有向无环图）描述任务依赖：DAG 是流程，Task 是具体步骤，Operator 决定 Task 做什么。核心概念还包括：调度周期（schedule）、执行日期（logical date / data interval）、重试策略、变量与连接（Variables/Connections）、传感器（Sensor，用于等待外部条件）。

| 概念 | 要点 |
| --- | --- |
| logical date | 表示"处理哪一段数据"，而不是"什么时候跑"，重跑时用它保证幂等 |
| 幂等 | 任务重跑结果应一致（覆盖写分区、先删后插、按日期分区写入） |
| backfill | 补历史数据，前提是任务幂等且不依赖"当前时间" |
| Sensor | 等待上游就绪，但要用 `reschedule` 模式避免占满 worker |
| catchup | 是否自动补跑历史调度，新建 DAG 时按需关闭 |

## 调度设计原则

1. **一个 DAG 一件事**：不要把几十个不相关任务塞进一个 DAG。
2. **任务粒度适中**：太细会产生大量排队开销，太粗则失败重跑昂贵。
3. **避免在 DAG 定义文件里做重活**：解析器会周期性扫描所有 DAG 文件。
4. **用幂等 + 分区覆盖**替代"只跑一次"的假设。
5. **超时与重试显式配置**：`execution_timeout`、`retries`、`retry_delay` 不要依赖默认值。

## 数据质量监控的六个检查

| 检查 | 说明 | 处理 |
| --- | --- | --- |
| 行数波动 | 与近 7 天均值比较，偏离阈值即告警 | 阻断下游并通知 |
| 主键唯一 | 重复即数据重复投递 | 去重或隔离 |
| 空值率 | 关键字段空值比例超限 | 隔离坏分区 |
| 枚举合法 | 状态字段是否出现未定义值 | 拒绝入仓 |
| 跨表对账 | 订单金额 = 明细之和 | 差异超阈值告警 |
| 时效性 | 分区是否按时产出 | 超时告警并触发补跑 |

落地方式：把检查写成独立任务放在 DAG 关键节点之后，失败即阻断下游；坏数据写入 dead-letter 表并保留原始分区，便于修复后重跑。

## 本课小结
Airflow 的价值是**把数据加工变成可观测、可重跑的流程**：用幂等与分区设计保证重跑安全，用质量检查与告警守住数据可信度。

<!-- appendix:v1 -->

## DAG 设计速查

| 要点 | 做法 |
| --- | --- |
| 幂等 | 同一分区重跑结果一致（覆盖写或 upsert） |
| 参数化 | 用 `{{ ds }}`、`{{ data_interval_start }}` 而不是 `datetime.now()` |
| 分层 | 抽取、清洗、聚合、导出拆成独立任务 |
| 依赖 | 用 `>>` 或 `set_upstream` 明确顺序 |
| 重试 | 配置 `retries` 与 `retry_delay`，区分可重试错误 |
| 超时 | 设 `execution_timeout` 防止任务挂死 |
| 并发控制 | 用 `max_active_runs`、池与优先级 |
| 资源隔离 | 重任务放独立队列或独立 worker |
| 通知 | `on_failure_callback` 发送告警 |
| 测试 | DAG 解析测试 + 任务逻辑单测 |

```python
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.sensors.external_task import ExternalTaskSensor

default_args = {
    "owner": "data",
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
    "execution_timeout": timedelta(minutes=40),
    "on_failure_callback": lambda context: print(f"任务失败：{context['task_instance_key_str']}"),
}

with DAG(
    dag_id="daily_orders",
    start_date=datetime(2025, 1, 1),
    schedule="0 2 * * *",
    catchup=False,                     # 只跑当天，避免历史回填风暴
    max_active_runs=1,                 # 防止多次运行互相覆盖
    default_args=default_args,
    tags=["warehouse", "orders"],
) as dag:
    wait_upstream = ExternalTaskSensor(
        task_id="wait_ods_ready",
        external_dag_id="ods_ingest",
        external_task_id="done",
        mode="reschedule",             # 不占用 worker 槽位
        timeout=60 * 60,
    )

    def build_dwd(ds, **context):
        # 用 {{ ds }} 作为分区参数，可安全重跑同一分区
        print(f"构建 DWD 分区 {ds}")

    dwd = PythonOperator(
        task_id="build_dwd",
        python_callable=build_dwd,
    )
    wait_upstream >> dwd
```

## 数据质量检查速查

| 检查类型 | 例子 | 处理 |
| --- | --- | --- |
| 完整性 | 主键非空、必填字段齐全 | 阻断下游 |
| 唯一性 | 主键与业务键不重复 | 阻断并告警 |
| 一致性 | 明细汇总与汇总表一致 | 告警并重跑 |
| 准确性 | 金额大于等于 0、状态在枚举内 | 阻断 |
| 及时性 | 最新分区时间不早于预期 | 告警 |
| 波动性 | 行数与昨日相比变化不超过阈值 | 先告警后人工确认 |
| 参照完整性 | 外键能在维表找到 | 记录孤儿行 |

```sql
-- 用一条 SQL 产出多项质量指标，便于统一入库与告警
SELECT
  COUNT(*)                                              AS row_count,
  COUNT(DISTINCT order_id)                              AS distinct_orders,
  SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)     AS null_ids,
  SUM(CASE WHEN amount < 0 THEN 1 ELSE 0 END)           AS negative_amounts,
  SUM(CASE WHEN status NOT IN ('created','paid','shipped','done') THEN 1 ELSE 0 END) AS invalid_status,
  MAX(created_at)                                       AS latest_event
FROM dwd_orders
WHERE dt = '{{ ds }}';
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `datetime.now()` 取分区 | 重跑结果错乱 | 用调度时间变量 `{{ ds }}` |
| 任务不幂等 | 重跑产生重复数据 | 覆盖分区或用 upsert |
| Sensor 用默认 poke 模式 | 占满 worker | 改 `mode="reschedule"` |
| 不设 `max_active_runs` | 多轮运行互相覆盖 | 限制并发运行数 |
| 任务粒度过粗 | 失败重跑代价大 | 拆分到合理粒度 |
| 不设超时 | 卡死任务长期占用 | 配置 `execution_timeout` |
| 只在失败时告警 | 数据错但任务成功 | 加数据质量校验任务 |
| 质量校验直接阻断一切 | 小波动导致全链路停摆 | 分阻断与告警两级 |
| 不用 catchup 也不评估回填 | 历史数据缺失 | 明确回填策略与限流 |
| DAG 里写重逻辑 | 解析慢、难测试 | 逻辑抽到模块并写单测 |

## 自测清单

- [ ] DAG 全部使用调度时间参数，可安全重跑。
- [ ] Sensor 使用 `reschedule` 模式。
- [ ] 配置重试、超时与并发上限。
- [ ] 数据质量检查分阻断与告警两级。
- [ ] DAG 解析与任务逻辑都有测试覆盖。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「Airflow、DAG、幂等」完成复述、实验和交付，每个结果都要能被别人检查。

先写 schema 与查询，再补边界和失败数据，最后看执行计划与锁等待。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「Airflow 调度与数据质量」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「DAG」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

在 SQLite 或纸面表结构上写查询，分别验证正常数据、空值和边界数据。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Airflow」和「DAG」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Airflow & Data Quality

**Summary:** DAGs, idempotency, backfill and quality checks.

**Category:** Database  
**Level:** 高级  
**Key terms:** Airflow, DAG, 幂等, backfill, 数据质量

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：PostgreSQL / MySQL / SQLite 等主流数据库
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Airflow、DAG、幂等、backfill、数据质量
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- top50-rewrite:v1 -->

## 课程专属精读：Airflow 调度与数据质量

### 一、知识地图

| 主题 | 核心要点 | 验证方式 |
| --- | --- | --- |
| DAG 与核心概念 | Airflow 用 DAG（有向无环图）描述任务依赖：DAG 是流程，Task 是具体步骤，Operator 决定 Task 做什么。 | 复述要点 + 举一个反例 |
| 调度设计原则 | 一个 DAG 一件事：不要把几十个不相关任务塞进一个 DAG。 | 复述要点 + 举一个反例 |
| 数据质量监控的六个检查 | 落地方式：把检查写成独立任务放在 DAG 关键节点之后，失败即阻断下游；坏数据写入 dead-letter 表并保留原始分区，便于修复后重跑。 | 复述要点 + 举一个反例 |

### 二、机制与验证

1. **DAG 与核心概念**：Airflow 用 DAG（有向无环图）描述任务依赖：DAG 是流程，Task 是具体步骤，Operator 决定 Task 做什么。 验证方式：先复述要点，再举一个反例说明边界。
2. **调度设计原则**：一个 DAG 一件事：不要把几十个不相关任务塞进一个 DAG。 验证方式：先复述要点，再举一个反例说明边界。
3. **数据质量监控的六个检查**：落地方式：把检查写成独立任务放在 DAG 关键节点之后，失败即阻断下游；坏数据写入 dead-letter 表并保留原始分区，便于修复后重跑。 验证方式：先复述要点，再举一个反例说明边界。

### 三、专属检查问题

1. 「DAG 与核心概念」要解决什么问题？请用一句话说明，并给出一个具体例子。
2. 「调度设计原则」的输入和输出分别是什么？
3. 「数据质量监控的六个检查」最常见的失败方式是什么？如何定位？

### 四、故障排查

1. 固定输入和环境，确认问题能稳定复现。
2. 找到第一个异常状态，不从最终错误倒推。
3. 每次只改一个变量，记录预测和真实结果。
4. 修复后补边界、失败与重复执行三类测试。

## 专属复习题库

**问：DAG 与核心概念的核心要点是什么？**

答：Airflow 用 DAG（有向无环图）描述任务依赖：DAG 是流程，Task 是具体步骤，Operator 决定 Task 做什么。

**问：调度设计原则的核心要点是什么？**

答：一个 DAG 一件事：不要把几十个不相关任务塞进一个 DAG。

**问：数据质量监控的六个检查的核心要点是什么？**

答：落地方式：把检查写成独立任务放在 DAG 关键节点之后，失败即阻断下游；坏数据写入 dead-letter 表并保留原始分区，便于修复后重跑。

## 逐步练习：Airflow 调度与数据质量

### 练习 1：DAG 与核心概念

1. 不看原文，用自己的话复述：Airflow 用 DAG（有向无环图）描述任务依赖：DAG 是流程，Task 是具体步骤，Operator 决定 Task 做什么。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 2：调度设计原则

1. 不看原文，用自己的话复述：一个 DAG 一件事：不要把几十个不相关任务塞进一个 DAG。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 3：数据质量监控的六个检查

1. 不看原文，用自己的话复述：落地方式：把检查写成独立任务放在 DAG 关键节点之后，失败即阻断下游；坏数据写入 dead-letter 表并保留原始分区，便于修复后重跑。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

## 故障排查手册：Airflow 调度与数据质量

| 现象 | 优先检查 | 修复动作 |
| --- | --- | --- |
| 「DAG 与核心概念」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「调度设计原则」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「数据质量监控的六个检查」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |

## 自测与面试：Airflow 调度与数据质量

1. 「DAG 与核心概念」的输入和输出分别是什么？
2. 「调度设计原则」最常见的失败方式是什么？如何定位？
3. 「数据质量监控的六个检查」的适用边界在哪里？什么情况下不该使用？

## 专属进阶任务 5：Airflow 调度与数据质量

把本课 3 个主题串成一个小练习：选其中一个主题做出可运行的例子，再为另外两个主题各写一条边界用例，最后用一句话说明你的验证结论。

### 验收标准

- 例子可以独立运行，输出与预期一致。
- 两条边界用例都说清了输入、预期与实际结果。
- 验证结论用一句话写清，不依赖“感觉正确”。

<!-- p2-references:v1 -->
## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [PostgreSQL 文档](https://www.postgresql.org/docs/) | SQL、索引与事务 |
| [SQLite 文档](https://sqlite.org/docs.html) | 嵌入式数据库与 SQL 行为 |

> 本课主题：DAG/幂等/backfill 与六项数据质量检查。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

