# 监控告警体系搭建

> **版本**：v2.0
> **难度**：初学者友好
> **前置知识**：了解 Linux 基本操作、Docker 基础概念
> **预计学习时长**：3-4 小时

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：75 分钟

---

## 本节知识框架

**课程定位**：分类「cloud」· 学习阶段 高级 · 建议用时 60 分钟。

本课主线：用 Prometheus、Grafana 与 Alertmanager 搭建完整的监控告警体系，覆盖指标采集、可视化与告警路由。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照考点精讲定位原因。

### 课程导言
| 序号 | 章节名称 | 核心内容 |
|------|----------|----------|
| 1 | 课程导言：为什么需要监控 | 监控的意义与生活类比 |
| 2 | 可观测性三大支柱 | 指标、日志、链路追踪 |
| 3 | Prometheus 架构与数据模型 | 核心组件、拉取模型、时间序列 |
| 4 | 指标类型详解 | Counter、Gauge、Histogram、Summary |
| 5 | PromQL 查询语言 | 基础查询、聚合函数、实战案例 |
| 6 | Grafana 可视化 | Dashboard 构建、数据源、变量 |
| 7 | Alertmanager 告警路由 | 分组、抑制、静默机制 |
| 8 | 告警策略设计 | 阈值、趋势、异常检测 |
| 9 | SLI/SLO/SLA 定义与实践 | 服务等级目标体系 |
| 10 | 实战：搭建完整监控告警体系 | 从零到一的完整部署 |
| 11 | 生产环境最佳实践 | 高可用、存储优化、安全加固 |
| 12 | 常见陷阱与排错指南 | 故障排查思路与工具 |
| 13 | 复习清单与进阶路线 | 知识回顾与学习建议 |

---

### 第 1 讲·课程导言：为什么需要监控
#### 1.1 生活中的监控：你的汽车仪表盘

想象你正在高速公路上开车。你的汽车仪表盘上有速度表、油量表、水温表、发动机故障灯——这些就是你的"监控系统"。

- **速度表** 告诉你当前车速（相当于 CPU 使用率）
- **油量表** 告诉你剩余油量（相当于磁盘剩余空间）
- **水温表** 告诉你发动机温度（相当于服务响应延迟）
- **故障灯** 在异常时亮起（相当于告警通知）

如果没有仪表盘，你只能在车抛锚后才知道出了问题。同样，没有监控系统的服务就像一辆没有仪表盘的汽车——你不知道它什么时候会出问题，也不知道它现在运行得好不好。

#### 1.2 软件系统为什么需要监控

在生产环境中，一个典型的 Web 应用可能包含：

- 前端服务器（Nginx）
- 后端应用（Java/Go/Python）
- 数据库（MySQL/PostgreSQL）
- 缓存（Redis）
- 消息队列（Kafka/RabbitMQ）

这些组件中的任何一个出问题，都可能导致用户无法正常使用服务。监控系统的作用就是：

1. **实时感知**：随时了解系统运行状态
2. **快速定位**：出问题时迅速找到根因
3. **提前预警**：在问题恶化前发出告警
4. **数据支撑**：为容量规划和优化提供依据

#### 1.3 监控的发展历史

| 时代 | 代表工具 | 特点 |
|------|----------|------|
| 第一代 | Nagios、Zabbix | 基于主机检查，配置复杂 |
| 第二代 | Prometheus、Graphite | 基于指标拉取，云原生友好 |
| 第三代 | OpenTelemetry、Datadog | 统一可观测性，AI 辅助分析 |

本课程聚焦第二代和第三代的核心技术栈。

---

### 第 13 讲·复习清单与进阶路线
#### 13.1 复习清单

完成本课程后，请逐项检查自己是否掌握了以下内容：

#### 基础概念

- [ ] 能解释可观测性三大支柱（指标、日志、链路追踪）的区别和联系
- [ ] 能说出 Prometheus 四种指标类型（Counter、Gauge、Histogram、Summary）的适用场景
- [ ] 能解释 Pull 模型和 Push 模型的区别及各自适用场景
- [ ] 能用自己的话解释 SLI、SLO、SLA 的含义和关系

#### 实操技能

- [ ] 能独立编写 Prometheus 配置文件，添加抓取目标
- [ ] 能使用 PromQL 编写常用查询（CPU/内存/磁盘使用率、错误率、延迟分位数）
- [ ] 能配置 Alertmanager 的告警路由、分组和抑制规则
- [ ] 能在 Grafana 中创建 Dashboard 并使用变量

#### 生产实践

- [ ] 能设计合理的告警策略，避免告警疲劳
- [ ] 了解 Prometheus 高可用方案（Thanos/Cortex）
- [ ] 能进行基本的故障排查（使用 promtool、检查 up 指标）
- [ ] 了解安全加固措施（认证、加密、网络隔离）

#### 13.2 进阶学习路线

```text
本课程（基础监控告警）
    │
    ├──► 日志系统：EFK/ELK Stack（Elasticsearch + Fluentd + Kibana）
    │         或 Loki + Grafana（轻量级日志方案）
    │
    ├──► 链路追踪：Jaeger、Zipkin、OpenTelemetry
    │
    ├──► 长期存储：Thanos、Cortex、Mimir
    │
    ├──► 服务网格监控：Istio + Prometheus
    │
    └──► APM 平台：Datadog、New Relic、SkyWalking
```

#### 13.3 推荐资源

| 资源 | 类型 | 说明 |
|------|------|------|
| Prometheus 官方文档 | 文档 | 最权威的参考资料 |
| Grafana 官方教程 | 文档 | Dashboard 最佳实践 |
| 《Prometheus 监控实战》 | 书籍 | 系统学习 Prometheus |
| Google SRE Book | 书籍 | SLO/SLA 和运维文化 |
| CNCF Landscape | 网站 | 了解云原生监控生态 |

---

## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| Prometheus | 用 Prometheus、Grafana 与 Alertmanager 搭建完整相关：正文给出可操作定义与适用边界。 |
| Grafana | 用 Prometheus、Grafana 与 Alertmanager 搭建完整相关：正文给出可操作定义与适用边界。 |
| Alertmanager | 用 Prometheus、Grafana 与 Alertmanager 搭建完整相关：正文给出可操作定义与适用边界。 |
| 监控告警 | 用 Prometheus、Grafana 与 Alertmanager 搭建完整相关：正文给出可操作定义与适用边界。 |
| 可观测性 | 用 Prometheus、Grafana 与 Alertmanager 搭建完整相关：正文给出可操作定义与适用边界。 |

## 原理与运行机制

《监控告警体系搭建》正文各章按「输入是什么 → 中间如何转换 → 输出到哪 → 失败时怎样表现」四问展开；复习时给每个机制补一句自己的复述，再回到对应章节核对。

### 第 2 讲·可观测性三大支柱
#### 2.1 什么是可观测性

**可观测性（Observability）** 是指通过系统的外部输出（指标、日志、链路）来推断系统内部状态的能力。

用一个生活类比：如果你是一个医生，你需要通过以下方式判断病人的健康状况：

- **体温计、血压计**（指标 Metrics）—— 数值化的健康数据
- **病人的描述**（日志 Logs）—— 详细的症状记录
- **CT 扫描、X 光**（链路追踪 Traces）—— 追踪身体内部的具体情况

#### 2.2 支柱一：指标（Metrics）

指标是数值型的时间序列数据，适合聚合和趋势分析。

**特点**：
- 轻量级，存储成本低
- 适合实时监控和告警
- 可以高效聚合（求和、平均、分位数）

**常见指标示例**：
```text
# 系统级指标
node_cpu_seconds_total{cpu="0", mode="idle"} 123456.78
node_memory_MemAvailable_bytes 4294967296

# 应用级指标
http_requests_total{method="GET", status="200"} 98765
http_request_duration_seconds{quantile="0.99"} 0.456
```

#### 2.3 支柱二：日志（Logs）

日志是离散的事件记录，包含丰富的上下文信息。

**特点**：
- 信息量大，包含详细上下文
- 适合问题排查和审计
- 存储成本较高，需要合理的日志级别管理

**日志级别示例**：
```text
2024-01-15 10:23:45 [INFO]  用户登录成功 user_id=12345 ip=192.168.1.100
2024-01-15 10:23:46 [WARN]  数据库连接池使用率超过 80% pool_size=50 active=42
2024-01-15 10:23:47 [ERROR] 订单创建失败 order_id=67890 error="数据库超时"
```

#### 2.4 支柱三：链路追踪（Traces）

链路追踪记录一个请求在分布式系统中的完整调用路径。

**特点**：
- 展示请求的完整生命周期
- 适合定位微服务中的性能瓶颈
- 可以直观看到各服务的耗时

**链路追踪示例**：
```text
请求链路: GET /api/order/12345 (总耗时 250ms)
  ├── API Gateway (5ms)
  ├── Order Service (80ms)
  │   ├── Auth Check (10ms)
  │   ├── DB Query (45ms)
  │   └── Cache Lookup (25ms)
  └── Payment Service (165ms)
      ├── Balance Check (30ms)
      └── Payment Gateway (135ms)
```

#### 2.5 三大支柱的协同关系

```text
                    ┌─────────────┐
                    │  可观测性    │
                    └──────┬──────┘
            ┌──────────────┼──────────────┐
            ▼              ▼              ▼
     ┌──────────┐   ┌──────────┐   ┌──────────┐
     │  Metrics │   │   Logs   │   │  Traces  │
     │  指标     │   │   日志   │   │  链路     │
     ├──────────┤   ├──────────┤   ├──────────┤
     │ 发生了什么 │   │ 为什么发生│   │ 在哪里发生│
     │ 趋势如何  │   │ 详细原因 │   │ 调用路径  │
     └──────────┘   └──────────┘   └──────────┘
```

**类比理解**：
- 指标告诉你"发烧了"（体温 39 度）
- 日志告诉你"咳嗽三天了，吃了感冒药没好转"
- 链路追踪告诉你"病毒从呼吸道进入，感染了肺部细胞"

三者结合，才能全面理解系统状态。

---

### 第 3 讲·Prometheus 架构与数据模型
#### 3.1 Prometheus 简介

Prometheus 是由 SoundCloud 开发的开源监控和告警系统，现在是 CNCF 的毕业项目。它就像监控世界的"瑞士军刀"——功能全面、生态丰富、社区活跃。

**核心特点**：
- **拉取模型（Pull）**：主动从目标抓取指标数据
- **多维数据模型**：基于标签（label）灵活组织数据
- **强大的查询语言**：PromQL 支持丰富的聚合和计算
- **服务发现**：自动发现监控目标（Kubernetes、Consul 等）
- **告警管理**：通过 Alertmanager 处理告警路由

#### 3.2 Prometheus 架构图

```text
┌─────────────────────────────────────────────────────────┐
│                    Prometheus 架构                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   ┌──────────────┐         ┌──────────────────────┐    │
│   │  Prometheus  │◄────────│   Exporters / 应用    │    │
│   │   Server     │  Pull   │  (Node Exporter,     │    │
│   │              │────────►│   cAdvisor, etc.)    │    │
│   └──────┬───────┘         └──────────────────────┘    │
│          │                                              │
│          ├──► TSDB（时间序列数据库）                      │
│          │                                              │
│          ├──► Alertmanager ──► 邮件/Slack/钉钉/微信      │
│          │                                              │
│          └──► Grafana（可视化）                           │
│                                                         │
│   ┌──────────────┐                                      │
│   │  Pushgateway │◄──── 短生命周期任务（批处理/CronJob）   │
│   └──────────────┘                                      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 3.3 核心组件说明

| 组件 | 作用 | 类比 |
|------|------|------|
| Prometheus Server | 抓取、存储、查询指标数据 | 监控系统的"大脑" |
| Exporter | 将各种系统的指标暴露为 Prometheus 格式 | 各种"传感器" |
| Pushgateway | 接收短生命周期任务的指标推送 | "信箱"（任务把数据放进去） |
| Alertmanager | 处理告警的路由、分组、抑制 | "报警中心" |
| Grafana | 可视化仪表盘 | "仪表盘屏幕" |

#### 3.4 数据模型：时间序列

Prometheus 中所有数据都是**时间序列（Time Series）**，由以下部分组成：

```text
<指标名称>{<标签键值对>} <数值> <时间戳>

# 示例
http_requests_total{method="GET", handler="/api/users", status="200"} 1027 1642245600000
http_requests_total{method="POST", handler="/api/users", status="201"} 43 1642245600000
```

**关键概念**：
- **指标名称（metric name）**：描述这个指标衡量什么
- **标签（label）**：给指标添加维度，如 method、status
- **样本（sample）**：具体的数值 + 时间戳

**类比**：把时间序列想象成一个 Excel 表格：
- 指标名称 = 表名
- 标签 = 列名（筛选条件）
- 时间戳 = 行（每一行是一个时间点）
- 数值 = 单元格中的值

#### 3.5 Prometheus 配置文件

一个完整的 Prometheus 配置示例：

```yaml
# prometheus.yml - Prometheus 主配置文件

global:
  scrape_interval: 15s        # 全局默认抓取间隔
  evaluation_interval: 15s    # 规则评估间隔
  scrape_timeout: 10s         # 抓取超时

# 告警规则文件
rule_files:
  - "alert_rules.yml"

# Alertmanager 配置
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - "alertmanager:9093"

# 抓取配置
scrape_configs:
  # Prometheus 自身的指标
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  # 节点监控（服务器指标）
  - job_name: "node-exporter"
    static_configs:
      - targets:
          - "node-exporter:9100"
        labels:
          env: "production"
          datacenter: "beijing"

  # 应用监控
  - job_name: "my-app"
    metrics_path: "/metrics"
    scrape_interval: 10s
    static_configs:
      - targets:
          - "app-server-1:8080"
          - "app-server-2:8080"
        labels:
          env: "production"
          service: "user-service"

  # Kubernetes 服务发现
  - job_name: "kubernetes-pods"
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        target_label: __address__
        regex: (.+)
        replacement: $1
```

---

### 第 4 讲·指标类型详解
#### 4.1 四种指标类型概览

Prometheus 定义了四种指标类型，每种适用于不同的场景：

| 类型 | 特点 | 适用场景 | 生活类比 |
|------|------|----------|----------|
| Counter | 只增不减（可重置） | 请求总数、错误总数 | 汽车里程表 |
| Gauge | 可增可减 | 温度、内存使用量、队列长度 | 汽车油量表 |
| Histogram | 预定义桶的分布统计 | 请求延迟分布、响应大小 | 身高分布统计 |
| Summary | 客户端计算分位数 | 请求延迟的 P99/P95 | 考试成绩分位数 |

#### 4.2 Counter（计数器）

Counter 是最简单的指标类型，只能递增或重置（如进程重启时归零）。

**使用场景**：
- HTTP 请求总数
- 错误总数
- 消息处理总数

```yaml
# Counter 指标示例
# HELP http_requests_total 总请求数
# TYPE http_requests_total counter
http_requests_total{method="GET", status="200"} 123456
http_requests_total{method="GET", status="500"} 42
http_requests_total{method="POST", status="201"} 7890
```

**查询示例**：
```promql
# 每秒请求速率
rate(http_requests_total[5m])

# 每分钟的错误请求数
rate(http_requests_total{status=~"5.."}[5m]) * 60
```

#### 4.3 Gauge（仪表盘）

Gauge 可以任意增减，适合表示"当前值"的指标。

**使用场景**：
- 当前内存使用量
- CPU 使用率
- 队列中的待处理消息数
- 当前活跃连接数

```yaml
# Gauge 指标示例
# HELP node_memory_MemAvailable_bytes 可用内存字节数
# TYPE node_memory_MemAvailable_bytes gauge
node_memory_MemAvailable_bytes 4294967296

# HELP process_open_fds 打开的文件描述符数
# TYPE process_open_fds gauge
process_open_fds 256
```

**查询示例**：
```promql
# 内存使用率（百分比）
1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)

# 磁盘使用率
1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)
```

#### 4.4 Histogram（直方图）

Histogram 将观测值放入预定义的桶（bucket）中，用于统计分布情况。

**使用场景**：
- 请求延迟分布
- 响应体大小分布
- 队列等待时间分布

```yaml
# Histogram 指标示例
# HELP http_request_duration_seconds HTTP 请求延迟
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.005"} 24054
http_request_duration_seconds_bucket{le="0.01"} 33444
http_request_duration_seconds_bucket{le="0.025"} 100392
http_request_duration_seconds_bucket{le="0.05"} 129389
http_request_duration_seconds_bucket{le="0.1"} 134567
http_request_duration_seconds_bucket{le="0.25"} 135633
http_request_duration_seconds_bucket{le="0.5"} 135841
http_request_duration_seconds_bucket{le="1"} 135882
http_request_duration_seconds_bucket{le="+Inf"} 135890
http_request_duration_seconds_sum 4567.89
http_request_duration_seconds_count 135890
```

**查询示例**：
```promql
# P99 延迟
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# 平均延迟
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])
```

#### 4.5 Summary（摘要）

Summary 与 Histogram 类似，但在客户端直接计算分位数。

**使用场景**：
- 需要精确的分位数（如 P99、P95）
- 不需要跨实例聚合分位数

```yaml
# Summary 指标示例
# HELP http_request_duration_seconds HTTP 请求延迟
# TYPE http_request_duration_seconds summary
http_request_duration_seconds{quantile="0.5"} 0.0034
http_request_duration_seconds{quantile="0.9"} 0.0156
http_request_duration_seconds{quantile="0.99"} 0.0892
http_request_duration_seconds_sum 4567.89
http_request_duration_seconds_count 135890
```

#### 4.6 如何选择指标类型

```text
需要统计"总共发生了多少次"？
  └── 是 → Counter（如请求总数、错误总数）

需要知道"当前是多少"？
  └── 是 → Gauge（如内存使用量、连接数）

需要了解"值的分布情况"？
  ├── 需要跨实例聚合 → Histogram
  └── 只需单实例精确分位数 → Summary
```

---

### 第 5 讲·PromQL 查询语言
#### 5.1 PromQL 简介

PromQL（Prometheus Query Language）是 Prometheus 的查询语言，就像 SQL 之于数据库。它是监控系统的"查询引擎"，用于从时间序列数据中提取和计算信息。

#### 5.2 基础查询

```promql
# 选择所有时间序列
http_requests_total

# 通过标签筛选
http_requests_total{method="GET"}
http_requests_total{method="GET", status="200"}

# 正则匹配标签
http_requests_total{status=~"2.."}       # 匹配 2xx 状态码
http_requests_total{status!~"5.."}       # 排除 5xx 状态码

# 标签值包含多个值
http_requests_total{method=~"GET|POST"}  # GET 或 POST
```

#### 5.3 时间范围与函数

```promql
# 选择过去 5 分钟的数据
http_requests_total[5m]

# 速率计算（Counter 必备）
rate(http_requests_total[5m])           # 每秒平均增长率
irate(http_requests_total[5m])          # 瞬时增长率

# 增量计算
increase(http_requests_total[1h])       # 过去 1 小时的增量

# 预测（基于线性回归）
predict_linear(http_requests_total[1h], 3600)  # 预测 1 小时后的值
```

#### 5.4 聚合操作

```promql
# 按标签聚合
sum(http_requests_total) by (method)           # 按 method 分组求和
avg(node_cpu_seconds_total) by (instance)      # 按实例分组求平均
max(http_request_duration_seconds) by (handler) # 按 handler 分组取最大值

# 全局聚合
sum(http_requests_total)                       # 所有序列求和
count(up == 1)                                 # 统计在线实例数

# Top N
topk(5, rate(http_requests_total[5m]))         # 速率最高的 5 个序列
```

#### 5.5 常用查询实战案例

```promql
# 1. CPU 使用率（百分比）
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# 2. 内存使用率（百分比）
100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)

# 3. 磁盘使用率（百分比）
100 * (1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})

# 4. HTTP 错误率（百分比）
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100

# 5. P99 请求延迟
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# 6. 服务可用性（up 指标）
avg_over_time(up{job="my-app"}[1h]) * 100

# 7. 网络接收速率（MB/s）
rate(node_network_receive_bytes_total{device="eth0"}[5m]) / 1024 / 1024
```

#### 5.6 记录规则（Recording Rules）

对于复杂或频繁使用的查询，可以使用记录规则预先计算：

```yaml
# recording_rules.yml
groups:
  - name: http_recording_rules
    interval: 30s
    rules:
      # 预计算每秒请求速率
      - record: job:http_requests:rate5m
        expr: sum(rate(http_requests_total[5m])) by (job)

      # 预计算错误率
      - record: job:http_error_rate:ratio5m
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) by (job)
          /
          sum(rate(http_requests_total[5m])) by (job)
```

---

### 第 6 讲·Grafana 可视化
#### 6.1 Grafana 简介

如果说 Prometheus 是监控系统的"大脑"，那么 Grafana 就是它的"脸面"。Grafana 是一个开源的可视化平台，让你可以创建美观且功能强大的监控仪表盘。

**类比**：Prometheus 是汽车的发动机和传感器，Grafana 就是你看到的仪表盘屏幕——把所有数据以图表的形式展示出来。

#### 6.2 数据源配置

首先，需要将 Prometheus 添加为 Grafana 的数据源：

```yaml
# grafana-datasource.yml（ provisioning 方式）
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
    jsonData:
      timeInterval: "15s"
      httpMethod: POST
```

#### 6.3 Dashboard 构建

一个完整的 Grafana Dashboard JSON 示例（Node Exporter 监控面板）：

```json
{
  "dashboard": {
    "id": null,
    "uid": "node-monitoring",
    "title": "服务器监控仪表盘",
    "tags": ["node-exporter", "production"],
    "timezone": "browser",
    "refresh": "30s",
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "templating": {
      "list": [
        {
          "name": "instance",
          "type": "query",
          "datasource": "Prometheus",
          "query": "label_values(node_uname_info, instance)",
          "refresh": 2,
          "includeAll": true,
          "multi": true
        }
      ]
    },
    "panels": [
      {
        "id": 1,
        "title": "CPU 使用率",
        "type": "timeseries",
        "gridPos": { "x": 0, "y": 0, "w": 12, "h": 8 },
        "targets": [
          {
            "expr": "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\", instance=~\"$instance\"}[5m])) * 100)",
            "legendFormat": "{{instance}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
            "thresholds": {
              "steps": [
                { "color": "green", "value": null },
                { "color": "yellow", "value": 70 },
                { "color": "red", "value": 90 }
              ]
            }
          }
        }
      },
      {
        "id": 2,
        "title": "内存使用率",
        "type": "gauge",
        "gridPos": { "x": 12, "y": 0, "w": 6, "h": 8 },
        "targets": [
          {
            "expr": "100 * (1 - node_memory_MemAvailable_bytes{instance=~\"$instance\"} / node_memory_MemTotal_bytes{instance=~\"$instance\"})",
            "legendFormat": "{{instance}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
            "thresholds": {
              "steps": [
                { "color": "green", "value": null },
                { "color": "orange", "value": 75 },
                { "color": "red", "value": 90 }
              ]
            }
          }
        }
      },
      {
        "id": 3,
        "title": "网络流量",
        "type": "timeseries",
        "gridPos": { "x": 0, "y": 8, "w": 12, "h": 8 },
        "targets": [
          {
            "expr": "rate(node_network_receive_bytes_total{instance=~\"$instance\", device=\"eth0\"}[5m])",
            "legendFormat": "接收 - {{instance}}"
          },
          {
            "expr": "rate(node_network_transmit_bytes_total{instance=~\"$instance\", device=\"eth0\"}[5m])",
            "legendFormat": "发送 - {{instance}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "Bps"
          }
        }
      },
      {
        "id": 4,
        "title": "磁盘使用率",
        "type": "bargauge",
        "gridPos": { "x": 12, "y": 8, "w": 12, "h": 8 },
        "targets": [
          {
            "expr": "100 * (1 - node_filesystem_avail_bytes{instance=~\"$instance\", mountpoint=\"/\"} / node_filesystem_size_bytes{instance=~\"$instance\", mountpoint=\"/\"})",
            "legendFormat": "{{mountpoint}} - {{instance}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percent",
            "min": 0,
            "max": 100,
            "thresholds": {
              "steps": [
                { "color": "green", "value": null },
                { "color": "yellow", "value": 70 },
                { "color": "red", "value": 85 }
              ]
            }
          }
        }
      }
    ]
  }
}
```

#### 6.4 变量的使用

变量让 Dashboard 更加灵活和可复用：

| 变量类型 | 用途 | 示例 |
|----------|------|------|
| Query | 从数据源动态获取值 | 选择 instance、job |
| Custom | 预定义固定值列表 | 选择环境（dev/staging/prod） |
| Interval | 时间间隔选择 | 选择聚合粒度（1m/5m/15m） |
| Datasource | 数据源选择 | 切换不同 Prometheus 实例 |

**变量使用示例**：
```promql
# 在查询中使用变量
node_cpu_seconds_total{instance=~"$instance"}

# 使用 interval 变量控制聚合粒度
avg_over_time(node_cpu_seconds_total{instance=~"$instance"}[$interval])
```

#### 6.5 常用面板类型

- **Time Series**：时间序列折线图，最常用
- **Gauge**：仪表盘，适合展示当前值
- **Stat**：大数字统计，适合展示关键指标
- **Bar Gauge**：条形进度条，适合对比多个值
- **Table**：表格，适合展示详细信息
- **Heatmap**：热力图，适合展示分布情况
- **Logs**：日志面板，展示日志流

---

### 第 7 讲·Alertmanager 告警路由
#### 7.1 Alertmanager 简介

Alertmanager 是 Prometheus 生态中的告警处理组件。如果把 Prometheus 比作"发现问题的侦探"，那 Alertmanager 就是"负责通知的邮递员"——它接收告警，决定发给谁、怎么发、何时发。

**核心功能**：
- **分组（Grouping）**：将相关告警合并为一条通知
- **抑制（Inhibition）**：当某个告警触发时，抑制其他相关告警
- **静默（Silencing）**：在维护窗口期间临时屏蔽告警
- **路由（Routing）**：根据告警标签决定通知渠道

#### 7.2 Alertmanager 配置文件

```yaml
# alertmanager.yml - Alertmanager 完整配置

global:
  resolve_timeout: 5m
  # 邮件 SMTP 配置
  smtp_smarthost: "smtp.example.com:587"
  smtp_from: "alertmanager@example.com"
  smtp_auth_username: "alertmanager@example.com"
  smtp_auth_password: "your-password"
  smtp_require_tls: true

# 告警模板
templates:
  - "/etc/alertmanager/templates/*.tmpl"

# 路由规则
route:
  # 默认接收器
  receiver: "default-email"
  # 分组等待时间
  group_wait: 30s
  # 分组发送间隔
  group_interval: 5m
  # 重复发送间隔
  repeat_interval: 4h
  # 分组标签
  group_by: ["alertname", "cluster", "service"]

  # 子路由 - 严重告警走即时通知
  routes:
    - match:
        severity: critical
      receiver: "critical-pager"
      group_wait: 10s
      repeat_interval: 1h
      continue: true

    # 子路由 - 警告级别走 Slack
    - match:
        severity: warning
      receiver: "slack-warnings"
      repeat_interval: 4h

    # 子路由 - 特定团队告警
    - match_re:
        team: "backend|frontend"
      receiver: "team-{{ .Labels.team }}"

# 接收器配置
receivers:
  - name: "default-email"
    email_configs:
      - to: "ops-team@example.com"
        send_resolved: true

  - name: "critical-pager"
    pagerduty_configs:
      - service_key: "your-pagerduty-key"
    webhook_configs:
      - url: "http://dingtalk-webhook:8080/alert"
        send_resolved: true

  - name: "slack-warnings"
    slack_configs:
      - api_url: "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
        channel: "#alerts-warning"
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}\n{{ end }}'
        send_resolved: true

# 抑制规则
inhibit_rules:
  # 当 critical 告警触发时，抑制同一 alertname 的 warning 告警
  - source_match:
      severity: "critical"
    target_match:
      severity: "warning"
    equal: ["alertname", "cluster", "service"]

  # 当整个集群不可达时，抑制该集群的所有告警
  - source_match:
      alertname: "ClusterDown"
    target_match_re:
      severity: ".+"
    equal: ["cluster"]
```

#### 7.3 告警规则定义

```yaml
# alert_rules.yml - Prometheus 告警规则

groups:
  - name: node_alerts
    rules:
      # 节点宕机
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "实例 {{ $labels.instance }} 宕机"
          description: "实例 {{ $labels.instance }} 已失联超过 1 分钟"

      # CPU 使用率过高
      - alert: HighCpuUsage
        expr: |
          100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "实例 {{ $labels.instance }} CPU 使用率过高"
          description: "CPU 使用率超过 85%，当前值：{{ $value | printf \"%.1f\" }}%"

      # 内存使用率过高
      - alert: HighMemoryUsage
        expr: |
          100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) > 90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "实例 {{ $labels.instance }} 内存使用率过高"
          description: "内存使用率超过 90%，当前值：{{ $value | printf \"%.1f\" }}%"

      # 磁盘即将满
      - alert: DiskSpaceLow
        expr: |
          100 * (1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) > 85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "实例 {{ $labels.instance }} 磁盘空间不足"
          description: "根分区使用率超过 85%，当前值：{{ $value | printf \"%.1f\" }}%"

      # 磁盘预测将在 4 小时内满
      - alert: DiskWillFillIn4Hours
        expr: |
          predict_linear(node_filesystem_avail_bytes{mountpoint="/"}[1h], 4 * 3600) < 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "实例 {{ $labels.instance }} 磁盘将在 4 小时内满"
          description: "根据当前增长趋势，磁盘将在 4 小时内耗尽"

  - name: application_alerts
    rules:
      # HTTP 错误率过高
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) by (job)
          /
          sum(rate(http_requests_total[5m])) by (job) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "服务 {{ $labels.job }} 错误率过高"
          description: "5xx 错误率超过 5%，当前值：{{ $value | printf \"%.2f\" }}%"

      # 请求延迟过高
      - alert: HighLatency
        expr: |
          histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, job)) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "服务 {{ $labels.job }} P99 延迟过高"
          description: "P99 延迟超过 1 秒，当前值：{{ $value | printf \"%.3f\" }}s"
```

#### 7.4 告警生命周期

```text
触发条件满足 → Pending（等待 for 持续时间）→ Firing（发送告警）→ Resolved（恢复正常）
     │                    │                        │                    │
     ▼                    ▼                        ▼                    ▼
  表达式为真          for 时间内持续为真        发送到接收器          表达式恢复为假
```

---

### 第 8 讲·告警策略设计
#### 8.1 告警策略的三个层次

好的告警策略应该像洋葱一样，分层次覆盖不同的问题场景：

| 层次 | 策略 | 示例 | 类比 |
|------|------|------|------|
| 第一层 | 阈值告警 | CPU > 90% 持续 5 分钟 | 体温超过 38.5 度 |
| 第二层 | 趋势告警 | 磁盘 4 小时内将满 | 体重每周增长 1kg |
| 第三层 | 异常检测 | 请求量突然下降 50% | 心跳突然变慢 |

#### 8.2 阈值告警

最基础也最常用的告警策略。关键是要设置合理的阈值和持续时间。

```promql
# 好的阈值告警示例
# 1. 考虑持续时间（避免瞬时波动）
# 2. 考虑不同环境的不同阈值

# 生产环境 CPU 阈值 85%
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle", env="production"}[5m])) * 100) > 85

# 测试环境 CPU 阈值 95%（更宽松）
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle", env="staging"}[5m])) * 100) > 95
```

#### 8.3 趋势告警

趋势告警关注的是"变化的方向和速度"，而不是绝对值。

```promql
# 磁盘空间趋势预测
# 预测 4 小时后磁盘是否会被耗尽
predict_linear(node_filesystem_avail_bytes{mountpoint="/"}[1h], 4 * 3600) < 0

# 请求量趋势（过去 1 小时的增长率）
deriv(http_requests_total[1h]) > 100

# 内存泄漏检测（内存使用量持续上升）
deriv(process_resident_memory_bytes[30m]) > 1048576  # 每分钟增长超过 1MB
```

#### 8.4 异常检测

异常检测用于发现偏离正常模式的行为。

```promql
# 请求量与历史同期对比（偏差超过 50%）
abs(
  sum(rate(http_requests_total[5m]))
  -
  sum(rate(http_requests_total[5m] offset 1w))
) / sum(rate(http_requests_total[5m] offset 1w)) > 0.5

# 延迟突然增加（当前延迟是历史均值的 3 倍以上）
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
> 3 * histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m] offset 1d))
```

#### 8.5 告警疲劳的防范

**告警疲劳**是运维团队的大敌。当告警太多时，人们会开始忽视告警，真正重要的告警也会被淹没。

**防范策略**：

1. **只告警需要人工介入的问题**
   - 好的告警：磁盘将在 2 小时内满（需要立即处理）
   - 坏的告警：CPU 使用率 60%（正常波动，不需要处理）

2. **合理设置告警级别**
   - Critical：需要立即响应（凌晨 3 点也要起来处理）
   - Warning：工作时间处理即可
   - Info：仅记录，不发送通知

3. **定期回顾和优化告警规则**
   - 每周统计告警数量
   - 消除误报
   - 合并相关告警

---

### 第 9 讲·SLI/SLO/SLA 定义与实践
#### 9.1 概念解释

用餐厅的例子来理解这三个概念：

| 术语 | 全称 | 含义 | 餐厅类比 |
|------|------|------|----------|
| SLI | Service Level Indicator | 服务等级指标——实际测量的值 | 实际出餐时间：平均 12 分钟 |
| SLO | Service Level Objective | 服务等级目标——你期望达到的值 | 目标出餐时间：95% 的订单在 15 分钟内 |
| SLA | Service Level Agreement | 服务等级协议——对客户的承诺 | 承诺出餐时间：99% 的订单在 20 分钟内，否则免单 |

**关系**：SLI 是实际值，SLO 是内部目标，SLA 是外部承诺。通常 SLA 比 SLO 更宽松，留出缓冲空间。

#### 9.2 定义 SLI

**常见的 SLI 类型**：

```promql
# 1. 可用性 SLI：成功请求的比例
# SLI = 成功请求数 / 总请求数
sum(rate(http_requests_total{status=~"2.."}[30d])) / sum(rate(http_requests_total[30d]))

# 2. 延迟 SLI：满足延迟阈值的请求比例
# SLI = 延迟 < 500ms 的请求数 / 总请求数
sum(rate(http_request_duration_seconds_bucket{le="0.5"}[30d])) / sum(rate(http_request_duration_seconds_count[30d]))

# 3. 吞吐量 SLI：每秒处理的请求数
sum(rate(http_requests_total[5m]))

# 4. 错误率 SLI：错误请求的比例
sum(rate(http_requests_total{status=~"5.."}[30d])) / sum(rate(http_requests_total[30d]))
```

#### 9.3 设定 SLO

SLO 的设定需要平衡用户体验和技术可行性：

```yaml
# SLO 定义示例
slos:
  - service: user-api
    sli:
      type: availability
      expression: |
        sum(rate(http_requests_total{status=~"2.."}[30d]))
        /
        sum(rate(http_requests_total[30d]))
    target: 0.999        # 99.9% 可用性
    window: 30d          # 30 天滚动窗口

  - service: user-api
    sli:
      type: latency
      expression: |
        sum(rate(http_request_duration_seconds_bucket{le="0.5"}[30d]))
        /
        sum(rate(http_request_duration_seconds_count[30d]))
    target: 0.99         # 99% 的请求延迟 < 500ms
    window: 30d
```

#### 9.4 错误预算（Error Budget）

错误预算是 SLO 实践中的核心概念。它量化了"允许出错的额度"。

**计算方式**：
```text
SLO 目标：99.9% 可用性
错误预算：100% - 99.9% = 0.1%

30 天内的错误预算：
总分钟数 = 30 * 24 * 60 = 43200 分钟
允许的故障时间 = 43200 * 0.1% = 43.2 分钟
```

**错误预算的使用策略**：
- 预算充足：可以大胆发布新功能
- 预算紧张：减缓发布节奏，专注于稳定性
- 预算耗尽：冻结发布，全力修复问题

```promql
# 计算当前错误预算消耗率
(1 - (sum(rate(http_requests_total{status=~"2.."}[30d])) / sum(rate(http_requests_total[30d])))) / (1 - 0.999)
# 结果 > 1 表示已经超出错误预算
```

#### 9.5 SLA 与违约处理

SLA 通常包含以下要素：

1. **服务可用性承诺**：如 99.95%
2. **测量方法**：如何计算可用性
3. **违约补偿**：未达标时的赔偿方案
4. **免责条款**：计划维护等不计入

---

### 第 11 讲·生产环境最佳实践
#### 11.1 高可用部署

生产环境中，单点故障是不可接受的。Prometheus 的高可用方案：

```text
                    ┌─────────────────────┐
                    │     Load Balancer    │
                    └──────────┬──────────┘
                    ┌──────────┴──────────┐
                    ▼                     ▼
           ┌──────────────┐      ┌──────────────┐
           │ Prometheus-1 │      │ Prometheus-2 │
           │  (副本 A)     │      │  (副本 B)     │
           └──────┬───────┘      └──────┬───────┘
                  │                     │
                  ▼                     ▼
           ┌──────────────┐      ┌──────────────┐
           │   Thanos     │      │   Thanos     │
           │   Store      │      │   Store      │
           └──────────────┘      └──────────────┘
```

**关键配置**：
- 至少部署两个 Prometheus 实例
- 使用 Thanos 或 Cortex 实现长期存储和全局查询
- Alertmanager 集群至少 3 个节点（使用 Raft 共识）

#### 11.2 存储优化

```yaml
# Prometheus 存储优化配置
global:
  scrape_interval: 15s
  evaluation_interval: 15s

# TSDB 配置
storage:
  tsdb:
    retention.time: 30d       # 数据保留 30 天
    retention.size: 10GB      # 最大存储空间
    min-block-duration: 2h    # 最小块时长
    max-block-duration: 36h   # 最大块时长
```

**存储优化建议**：
- 使用 recording rules 预计算常用查询
- 合理设置 scrape_interval（不需要太频繁）
- 使用标签时避免高基数（如不要用 user_id 作为标签）
- 定期清理不需要的指标

#### 11.3 安全加固

```yaml
# Prometheus 基本认证配置
scrape_configs:
  - job_name: "secure-target"
    basic_auth:
      username: "prometheus"
      password: "secure-password"
    tls_config:
      ca_file: "/etc/prometheus/ca.crt"
      cert_file: "/etc/prometheus/client.crt"
      key_file: "/etc/prometheus/client.key"
```

**安全检查清单**：
- 启用 HTTPS 加密通信
- 配置访问认证（Basic Auth 或 OAuth2）
- 限制网络访问（只允许监控网络访问抓取端口）
- 定期轮换凭证
- 审计告警通知中的敏感信息

---

## 典型应用场景

- 结合「监控告警体系搭建」的常见落地场景与选型边界，详见正文各章节的对比讨论。
- 迁移到新项目时，先明确输入规模、失败代价与可观测手段，再决定采用深度。

### 第 10 讲·实战：搭建完整监控告警体系
#### 10.1 架构总览

![监控告警体系架构图](images/devops_monitoring_stack.webp)

本次实战将使用 Docker Compose 搭建以下组件：

- Prometheus：指标采集与存储
- Node Exporter：服务器指标
- Alertmanager：告警管理
- Grafana：可视化仪表盘

#### 10.2 项目目录结构

```text
monitoring-stack/
├── docker-compose.yml
├── prometheus/
│   ├── prometheus.yml
│   ├── alert_rules.yml
│   └── recording_rules.yml
├── alertmanager/
│   ├── alertmanager.yml
│   └── templates/
│       └── default.tmpl
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── datasource.yml
│   │   └── dashboards/
│   │       └── dashboard.yml
│   └── dashboards/
│       └── node-monitoring.json
└── .env
```

#### 10.3 Docker Compose 配置

```yaml
# docker-compose.yml

version: "3.8"

services:
  prometheus:
    image: prom/prometheus:v2.48.0
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/alert_rules.yml:/etc/prometheus/alert_rules.yml
      - ./prometheus/recording_rules.yml:/etc/prometheus/recording_rules.yml
      - prometheus_data:/prometheus
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.path=/prometheus"
      - "--storage.tsdb.retention.time=30d"
      - "--storage.tsdb.retention.size=10GB"
      - "--web.enable-lifecycle"
    restart: unless-stopped
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:v1.7.0
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - "--path.procfs=/host/proc"
      - "--path.sysfs=/host/sys"
      - "--path.rootfs=/rootfs"
      - "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)"
    restart: unless-stopped
    networks:
      - monitoring

  alertmanager:
    image: prom/alertmanager:v0.26.0
    container_name: alertmanager
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - ./alertmanager/templates:/etc/alertmanager/templates
    command:
      - "--config.file=/etc/alertmanager/alertmanager.yml"
      - "--storage.path=/alertmanager"
    restart: unless-stopped
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:10.2.0
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-admin}
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
      - grafana_data:/var/lib/grafana
    restart: unless-stopped
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:

networks:
  monitoring:
    driver: bridge
```

#### 10.4 启动与验证

```bash
# 1. 进入项目目录
cd monitoring-stack

# 2. 设置 Grafana 管理员密码
export GRAFANA_ADMIN_PASSWORD="your-secure-password"

# 3. 启动所有服务
docker compose up -d

# 4. 检查服务状态
docker compose ps

# 5. 验证各组件
# Prometheus: http://localhost:9090
# Alertmanager: http://localhost:9093
# Grafana: http://localhost:3000
# Node Exporter: http://localhost:9100/metrics

# 6. 查看日志
docker compose logs -f prometheus
docker compose logs -f alertmanager
docker compose logs -f grafana
```

#### 10.5 验证 Prometheus 抓取

```bash
# 检查抓取目标状态
curl -s http://localhost:9090/api/v1/targets | python3 -m json.tool | head -30

# 手动查询指标
curl -s "http://localhost:9090/api/v1/query?query=up" | python3 -m json.tool

# 查看告警规则状态
curl -s http://localhost:9090/api/v1/rules | python3 -m json.tool | head -50
```

---

## 代码/协议/SQL 示例

《监控告警体系搭建》正文首个示例可作为最小验证起点（原样保留在上方章节）：先跑通，再改一个输入观察输出变化。

```text
# 系统级指标
node_cpu_seconds_total{cpu="0", mode="idle"} 123456.78
node_memory_MemAvailable_bytes 4294967296

# 应用级指标
http_requests_total{method="GET", status="200"} 98765
http_request_duration_seconds{quantile="0.99"} 0.456
```

## 时间/空间复杂度或性能分析

- 在《监控告警体系搭建》里处理规模 n 时，先估计主循环与嵌套层数，再决定优化方向；小样本上的耗时读数不能外推。
- 性能结论要绑定输入分布：换数据规模、并发度或缓存命中情况后须重新测量。

## 常见误区与易错点

| 错误做法 | 典型现象 | 修复方向 |
| --- | --- | --- |
| 只验证正常输入 | 边界数据触发时才暴露问题 | 为每个结论补一个空值/极值/重复值用例 |
| 背结论不跑实验 | 换个输入就失效 | 按「预测—实测—差异归因」三步复盘 |
| 忽略环境与版本差异 | 本机可用线上报错 | 把版本、配置与依赖写入复现步骤 |

### 第 12 讲·常见陷阱与排错指南
#### 12.1 常见问题与解决方案

| 问题 | 可能原因 | 解决方案 |
|------|----------|----------|
| Target 显示 DOWN | 网络不通或 Exporter 未启动 | 检查网络连通性和 Exporter 状态 |
| 数据丢失 | 存储空间不足或保留时间过短 | 增加存储或调整 retention |
| 告警风暴 | 阈值设置不合理 | 调整阈值和 for 持续时间 |
| 查询缓慢 | 高基数标签或复杂查询 | 使用 recording rules 优化 |
| 内存溢出 | 时间序列过多 | 减少标签维度或增加内存 |

#### 12.2 排错工具与命令

```bash
# 1. 检查 Prometheus 配置是否正确
promtool check config prometheus.yml

# 2. 检查告警规则
promtool check rules alert_rules.yml

# 3. 测试 PromQL 查询
promtool query instant http://localhost:9090 "up"

# 4. 查看 Prometheus 运行时信息
curl -s http://localhost:9090/api/v1/status/config
curl -s http://localhost:9090/api/v1/status/runtimeinfo
curl -s http://localhost:9090/api/v1/status/tsdb

# 5. 检查 Alertmanager 配置
amtool check-config alertmanager.yml

# 6. 测试告警路由
amtool alert add TestAlert severity=warning instance=test
```

#### 12.3 调试技巧

```promql
# 调试抓取问题：检查 up 指标
up{job="my-job"}

# 调试标签问题：查看某个 job 的所有标签
count({job="my-job"}) by (__name__)

# 调试数据缺失：检查某个时间段的数据
http_requests_total[5m] offset 1h

# 调试告警：查看告警当前值
# 在 Prometheus UI 的 Rules 页面可以看到每个规则的当前状态
```

---

## 与其他知识点的关系

先修与相关课程：cloud_observability_sre、docker。复习时对照这些课程的术语表，找出同名概念在不同场景下的边界差异。

## 自测题与参考答案

以下题目与题库同源，作答后再看解析；错误项要能说出错在哪一步。

## 考点精讲

### 考点 1

Prometheus 采用的数据收集模型是什么？与另一种模型相比有什么优势？

A. Push 模型——由应用主动推送指标到 Prometheus，适合所有场景  
B. 广播模型——所有指标同时发送到所有监控节点  
C. 点对点模型——每个监控目标之间互相交换数据  
D. Pull 模型——Prometheus 主动从目标抓取（scrape）指标数据，便于发现异常目标和统一管理  

**正确答案：D**

**详细解释：** Prometheus 使用 Pull（拉取）模型，由 Prometheus Server 定期主动从目标（如 Node Exporter、应用 /metrics 端点）抓取指标数据。这种模式的优势在于：Prometheus 可以知道哪些目标是可达的（通过 "up" 指标），便于发现故障目标；抓取频率由 Prometheus 统一管理；配置集中，不需要每个应用都配置 Prometheus 地址。对于短生命周期的任务（如 CronJob），则使用 Pushgateway 来弥补 Pull 模型的不足。

---

### 考点 2

在 Prometheus 的四种指标类型中，哪种类型的指标只能递增（或重置），最适合用来统计"总共发生了多少次"？

A. Counter  
B. Gauge  
C. Histogram  
D. Summary  

**正确答案：A**

**详细解释：** Counter（计数器）是最简单的指标类型，只能递增或在进程重启时重置。它适合统计"总共发生了多少次"的场景，如 HTTP 请求总数、错误总数、消息处理总数等。查询时通常配合 "rate()" 函数计算每秒增长率。Gauge 可以任意增减，适合表示"当前值"（如内存使用量）。Histogram 和 Summary 用于统计值的分布情况（如延迟分位数）。

---

### 考点 3

Alertmanager 中"抑制（Inhibition）"规则的作用是什么？

A. 永久删除某个告警规则  
B. 自动修复触发告警的问题  
C. 加速告警的发送速度  
D. 当某个严重告警触发时，抑制同一服务或集群的相关低级告警，避免告警风暴  

**正确答案：D**

**详细解释：** 抑制规则的作用是避免"告警风暴"——当一个严重问题触发大量相关告警时，只发送最重要的告警。例如，当整个集群宕机（critical 级别）时，该集群中所有服务的 warning 级别告警都应该被抑制，因为根因是集群故障，发送数百个服务告警没有意义。抑制规则通过 "source_match"（源告警）和 "target_match"（被抑制告警）配合 "equal" 标签来定义。

---

### 考点 4

关于 SLI、SLO、SLA 三个概念，以下哪个描述是正确的？

A. SLI 是内部目标，SLO 是对客户的外部承诺，SLA 是实际测量值  
B. SLA 是最严格的技术指标，SLO 次之，SLI 最宽松  
C. 三者含义完全相同，只是叫法不同  
D. SLI 是实际测量的服务指标值，SLO 是内部设定的目标值，SLA 是对客户的外部承诺，通常 SLA 比 SLO 更宽松  

**正确答案：D**

**详细解释：** SLI（Service Level Indicator）是实际测量的服务指标值，如"过去 30 天可用性为 99.95%"。SLO（Service Level Objective）是内部设定的目标值，如"目标可用性 99.9%"。SLA（Service Level Agreement）是对客户的外部承诺，如"承诺可用性 99.5%，否则赔偿"。通常 SLA 比 SLO 更宽松，留出缓冲空间，确保即使未达到内部目标也不会违反对客户的承诺。

---

### 考点 5

在 PromQL 中，"histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))" 这个查询的作用是什么？

A. 计算过去 5 分钟的 P99 请求延迟（即 99% 的请求延迟低于此值）  
B. 计算过去 5 分钟的平均请求延迟  
C. 统计过去 5 分钟的总请求数  
D. 计算过去 5 分钟的每秒请求速率  

**正确答案：A**

**详细解释：** "histogram_quantile" 函数用于从 Histogram 类型的指标中计算分位数。参数 "0.99" 表示计算第 99 百分位（P99），即 99% 的请求延迟低于此值。"rate(...[5m])" 计算过去 5 分钟的增长率。P99 延迟是衡量服务性能的重要指标，它反映了"最差体验"用户的需求——如果 P99 延迟是 500ms，意味着 99% 的用户请求延迟在 500ms 以内，只有 1% 的请求超过这个值。

---

> **课程版本**：v2.0
> **最后更新**：2026 年
> **适用环境**：Prometheus 2.48+、Grafana 10.2+、Alertmanager 0.26+

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| Prometheus | 时序数据库，用Pull模式抓取指标并按标签用PromQL查询，是告警的数据源 |
| Grafana | 可视化面板工具，接Prometheus等数据源画出Dashboard并支持模板变量 |
| Alertmanager | 承接Prometheus规则触发的告警，做去重分组、抑制静默并按标签路由通知 |
| 监控告警 | 持续采集运行指标并在越过阈值时通知人，回答系统现在好不好、哪里出问题 |
| 可观测性 | 靠指标、日志、链路追踪三大支柱从外部推断系统内部状态的能力，比监控更完整 |

## 参考资料与复核

- 官方/权威资料：[CNCF 项目总览](https://landscape.cncf.io/)
- 主题延伸：[Grafana 官方文档](https://grafana.com/docs/grafana/latest/)
- 最后复核：2026-10-04
- 下次复核：2027-01-13

### 附录·常用 Exporter 列表
| Exporter | 监控目标 | 默认端口 |
|----------|----------|----------|
| Node Exporter | Linux 服务器指标 | 9100 |
| cAdvisor | Docker 容器指标 | 8080 |
| MySQL Exporter | MySQL 数据库指标 | 9104 |
| Redis Exporter | Redis 缓存指标 | 9121 |
| Blackbox Exporter | 网络探测（HTTP/TCP/ICMP） | 9115 |
| Pushgateway | 短生命周期任务指标 | 9091 |
| Kafka Exporter | Kafka 消息队列指标 | 9308 |
| Nginx Exporter | Nginx Web 服务器指标 | 9113 |

### 附录·PromQL 速查表
| 场景 | PromQL 表达式 |
|------|---------------|
| CPU 使用率 | `100 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100` |
| 内存使用率 | `100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)` |
| 磁盘使用率 | `100 * (1 - node_filesystem_avail_bytes / node_filesystem_size_bytes)` |
| 请求速率 | `sum(rate(http_requests_total[5m]))` |
| 错误率 | `sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))` |
| P99 延迟 | `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))` |
| 在线实例数 | `count(up == 1)` |
| 网络接收速率 | `rate(node_network_receive_bytes_total[5m])` |

---

---

## 内容元数据

- 内容更新时间：2026-10-06

- 内容版本：v2.0
- 课程标识：devops_monitoring
- 所属分类：cloud
- 学习阶段：高级
- 建议用时：60 分钟
