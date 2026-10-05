# 时间与时区：九种语言横向对照

![时间戳、时区与本地化显示的转换](images/diagram_cross_time.webp)

![时间与时区：九种语言横向对照](images/category_cross_time_timezone.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：20 分钟

## 学习目标

- 能用自己的话解释「时间与时区：九种语言横向对照」解决了什么问题，而不是只背术语。
- 能说清 「时间」、「时区」、「UTC」、「ISO 8601」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「跨语言对照」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：时刻与本地时间、三条铁律、数据库字段选择与常见时区错误。

## 前置知识

- 先完成上一课《字符串与正则：九种语言横向对照》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：时间、时区、UTC。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 一句话说清

时间处理只有三条铁律：
**存储用 UTC、传输用 ISO 8601、展示时才转本地时区**。
踩坑几乎都来自把「本地时间」当成「绝对时刻」。

## 四个必须分清的概念

```text
① 时刻 Instant：时间轴上的一个点，与时区无关
   例：2026-03-05T06:02:11Z

② 本地日期时间 LocalDateTime：墙上时钟读数，没有时区信息
   例：2026-03-05 14:02:11（不知道是哪个时区）

③ 时区 ZoneId：规则集合，如 Asia/Shanghai（含夏令时历史）

④ 偏移 Offset：某时刻相对 UTC 的差，如 +08:00

换算关系：时刻 = 本地日期时间 + 时区规则
```

**只存本地日期时间是事故的开始**：同一串数字在不同时区代表不同时刻。

## 各语言的主流时间类型

| 语言 | 时刻类型 | 带时区 | 格式化 |
| --- | --- | --- | --- |
| Python | `datetime`（带 tzinfo） | 显式传 `timezone.utc` | `isoformat` |
| JavaScript | `Date`（内部为毫秒时间戳） | 用 `Intl` 格式化 | `toISOString` |
| TypeScript | 同 JavaScript | 同上 | 同上 |
| Java | `Instant` / `ZonedDateTime` | `ZoneId` | `DateTimeFormatter` |
| C# | `DateTimeOffset` | 内建偏移 | `ToString("o")` |
| C++ | `chrono::system_clock` | C++20 起有 `zoned_time` | `std::format` |
| Go | `time.Time` | `time.Location` | `Format(time.RFC3339)` |
| Rust | `chrono::DateTime<Utc>` | `chrono-tz` | `to_rfc3339` |
| Shell | `date` | `TZ=` 环境变量 | `date -Iseconds` |

## 三条铁律的落地写法

```python
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

now_utc = datetime.now(timezone.utc)              # 存储：始终用 UTC
print(now_utc.isoformat())

local = now_utc.astimezone(ZoneInfo("Asia/Shanghai"))   # 展示：转本地
print(local.strftime("%Y-%m-%d %H:%M"))

parsed = datetime.fromisoformat("2026-03-05T06:02:11+00:00")   # 解析
```

```javascript
const iso = new Date().toISOString();          // 存储：UTC 的 ISO 8601

const shown = new Intl.DateTimeFormat("zh-CN", {
  dateStyle: "medium",
  timeStyle: "short",
  timeZone: "Asia/Shanghai",
}).format(new Date(iso));                      // 展示：按用户时区

const parsed = new Date("2026-03-05T06:02:11Z");
```

```java
import java.time.*;
import java.time.format.DateTimeFormatter;

Instant now = Instant.now();                                   // 时刻
ZonedDateTime local = now.atZone(ZoneId.of("Asia/Shanghai"));
String text = DateTimeFormatter.ISO_INSTANT.format(now);
Instant parsed = Instant.parse("2026-03-05T06:02:11Z");
```

```csharp
var now = DateTimeOffset.UtcNow;
string iso = now.ToString("o");                                // 往返格式
var parsed = DateTimeOffset.Parse("2026-03-05T06:02:11+00:00");
var local = TimeZoneInfo.ConvertTimeBySystemTimeZoneId(parsed, "China Standard Time");
```

```go
now := time.Now().UTC()
text := now.Format(time.RFC3339)
parsed, _ := time.Parse(time.RFC3339, text)

loc, _ := time.LoadLocation("Asia/Shanghai")
fmt.Println(parsed.In(loc).Format("2006-01-02 15:04"))
```

```rust
use chrono::Utc;

let now = Utc::now();
let text = now.to_rfc3339();
let parsed = chrono::DateTime::parse_from_rfc3339(&text)?;
```

```bash
date -u +%Y-%m-%dT%H:%M:%SZ                 # 当前 UTC
TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M'     # 指定时区展示
date -d "2026-03-05T06:02:11Z" +%s          # 解析为时间戳
```

## 五个高频场景的正确做法

| 场景 | 错误做法 | 正确做法 |
| --- | --- | --- |
| 记录创建时间 | 存本地时间字符串 | 存 UTC 时刻 |
| 展示给用户 | 后端按服务器时区格式化 | 前端按用户时区格式化 |
| 每日 0 点执行任务 | 用服务器时间 0 点 | 明确业务时区 |
| 计算相差几天 | 直接相减 | 转同一时区后按日历天计算 |
| 跨夏令时加一天 | 加 24 小时 | 按日历单位加一天 |

## 数据库里的时间字段

| 类型 | 是否带时区 | 建议 |
| --- | --- | --- |
| `TIMESTAMP WITH TIME ZONE` | 带 | **推荐** |
| `TIMESTAMP` / `DATETIME` | 不带 | 需约定全部存 UTC |
| 整数时间戳 | 隐含 UTC | 简单可靠，注意单位统一 |

```text
建议写进团队文档的统一约定
  · 数据库存 UTC
  · 接口传输 ISO 8601，带 Z 或偏移
  · 前端按用户时区渲染
  · 日志时间统一 UTC 并标注
```

## 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用本地时间存库 | 跨时区显示错乱 | 存 UTC |
| 时间戳单位混淆 | 相差 1000 倍 | 明确秒还是毫秒 |
| 字符串比较时间 | 跨格式失效 | 统一 ISO 8601 |
| 用固定 24 小时算一天 | 夏令时地区出错 | 用日历单位 |
| 服务器时区变更 | 历史数据解释变化 | 显式指定时区 |
| 忽略闰年 | 边界计算错误 | 用成熟的日期库 |
| 时区名写成缩写 | `CST` 有歧义 | 用 `Asia/Shanghai` |
| 前端直接显示后端字符串 | 用户看到服务器时间 | 前端按时区渲染 |

## 本课小结
- 记住换算关系：**时刻 = 本地日期时间 + 时区规则**。
- 三条铁律：**存 UTC、传 ISO 8601、展示时再转本地**。
- 涉及「天」的计算要用日历语义，而不是固定 24 小时。

## 动手练习


> 本课练习重点：围绕「时间、时区、UTC」完成复述、实验和交付，每个结果都要能被别人检查。

用两种语言实现同一行为，再对比语法、错误、性能和生态差异。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「时间与时区：九种语言横向对照」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「时区」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

选两种语言实现同一行为，列出语法、错误处理、性能和生态差异。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「时间」和「时区」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。



## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：时间处理的三条铁律是？

- **正确判断**：存 UTC，传输 ISO 8601
- **判断依据**：正确答案是「存 UTC，传输 ISO 8601」，本课在「本课小结」中说明：三条铁律：存 UTC、传 ISO 8601、展示时再转本地。这是跨语言的通用约定，能避免绝大多数时区问题。本课还在「一句话说清」中说明：踩坑几乎都来自把「本地时间」当成「绝对时刻」。本课还在「一句话说清」中说明：存储用 UTC、传输用 ISO 8601、展示时才转本地时区。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 2：「时刻」与「本地日期时间」的关键区别是？

- **正确判断**：时刻是时间轴上的点（与时区无关），本地日期时间只是墙上时钟读数
- **判断依据**：正确答案是「时刻是时间轴上的点（与时区无关），本地日期时间只是墙上时钟读数」，本课在「四个必须分清的概念」中说明：只存本地日期时间是事故的开始：同一串数字在不同时区代表不同时刻。换算关系是「时刻 = 本地日期时间 + 时区规则」。本课还在「本课小结」中说明：记住换算关系：时刻 = 本地日期时间 + 时区规则。本课还在「一句话说清」中说明：踩坑几乎都来自把「本地时间」当成「绝对时刻」。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 3：跨夏令时地区计算「明天同一时间」，正确做法是？

- **正确判断**：按日历单位加一天
- **判断依据**：正确答案是「按日历单位加一天」，本课在「本课小结」中说明：涉及「天」的计算要用日历语义，而不是固定 24 小时。夏令时切换当天可能只有 23 小时或 25 小时，必须用日历语义。本课还在「四个必须分清的概念」中说明：只存本地日期时间是事故的开始：同一串数字在不同时区代表不同时刻。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 4：数据库里存时间，更推荐的做法是？

- **正确判断**：统一存 UTC（带时区类型或整数时间戳）
- **判断依据**：正确答案是「统一存 UTC（带时区类型或整数时间戳）」，本课在「一句话说清」中说明：存储用 UTC、传输用 ISO 8601、展示时才转本地时区。统一存 UTC 才能在任意时区正确还原与比较。本课还在「本课小结」中说明：记住换算关系：时刻 = 本地日期时间 + 时区规则。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 5：补全代码：「时间与时区：九种语言横向对照」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `const shown = new Intl.____("zh-CN", {`

- **正确判断**：DateTimeFormat / datetimeformat
- **判断依据**：正确答案是「DateTimeFormat」，这道题在问补全代码：时间与时区：九种语言横向对照示例中，下面这…Intl.____("zh-CN",{`，判断时要把题干限定的输入、边界与目标逐项对齐。本课示例中还能看到 `import java.time.format.DateTimeFormatter;` 这样的用法，说明该关键字在本课代码中承担实际功能。
- **迁移检查**：不看题干，用自己的话补全这句话，再与标准答案对照。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「时间处理的三条铁律是？」的判断依据。
- [ ] 不看解析，能说出「「时刻」与「本地日期时间」的关键区别是？」的判断依据。
- [ ] 不看解析，能说出「跨夏令时地区计算「明天同一时间」，正确做法是？」的判断依据。
- [ ] 不看解析，能说出「数据库里存时间，更推荐的做法是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「时间与时区：九种语言横向对照」示例中，下面这行代码缺少哪个关键字或函…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把本课反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `datetime` | \| Python \| `datetime`（带 tzinfo） \| 显式传 `timezone.utc` \| `isoformat` \| |
| `timezone.utc` | \| Python \| `datetime`（带 tzinfo） \| 显式传 `timezone.utc` \| `isoformat` \| |
| `isoformat` | \| Python \| `datetime`（带 tzinfo） \| 显式传 `timezone.utc` \| `isoformat` \| |
| `Date` | \| JavaScript \| `Date`（内部为毫秒时间戳） \| 用 `Intl` 格式化 \| `toISOString` \| |
| `Intl` | \| JavaScript \| `Date`（内部为毫秒时间戳） \| 用 `Intl` 格式化 \| `toISOString` \| |
| `toISOString` | \| JavaScript \| `Date`（内部为毫秒时间戳） \| 用 `Intl` 格式化 \| `toISOString` \| |
| `Instant` | \| Java \| `Instant` / `ZonedDateTime` \| `ZoneId` \| `DateTimeFormatter` \| |
| `ZonedDateTime` | \| Java \| `Instant` / `ZonedDateTime` \| `ZoneId` \| `DateTimeFormatter` \| |
| `ZoneId` | \| Java \| `Instant` / `ZonedDateTime` \| `ZoneId` \| `DateTimeFormatter` \| |
| `DateTimeFormatter` | \| Java \| `Instant` / `ZonedDateTime` \| `ZoneId` \| `DateTimeFormatter` \| |
| `DateTimeOffset` | \| C# \| `DateTimeOffset` \| 内建偏移 \| `ToString("o")` \| |
| `ToString("o")` | \| C# \| `DateTimeOffset` \| 内建偏移 \| `ToString("o")` \| |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：时间处理的三条铁律是？

**参考回答**：正确答案是「存 UTC，传输 ISO 8601」，本课在「本课小结」中说明：三条铁律：存 UTC、传 ISO 8601、展示时再转本地。这是跨语言的通用约定，能避免绝大多数时区问题。本课还在「一句话说清」中说明：踩坑几乎都来自把「本地时间」当成「绝对时刻」。本课还在「一句话说清」中说明：存储用 UTC、传输用 ISO 8601、展示时才转本地时区。

### 追问 2：「时刻」与「本地日期时间」的关键区别是？

**参考回答**：正确答案是「时刻是时间轴上的点（与时区无关），本地日期时间只是墙上时钟读数」，本课在「四个必须分清的概念」中说明：只存本地日期时间是事故的开始：同一串数字在不同时区代表不同时刻。换算关系是「时刻 = 本地日期时间 + 时区规则」。本课还在「本课小结」中说明：记住换算关系：时刻 = 本地日期时间 + 时区规则。本课还在「一句话说清」中说明：踩坑几乎都来自把「本地时间」当成「绝对时刻」。

### 追问 3：跨夏令时地区计算「明天同一时间」，正确做法是？

**参考回答**：正确答案是「按日历单位加一天」，本课在「本课小结」中说明：涉及「天」的计算要用日历语义，而不是固定 24 小时。夏令时切换当天可能只有 23 小时或 25 小时，必须用日历语义。本课还在「四个必须分清的概念」中说明：只存本地日期时间是事故的开始：同一串数字在不同时区代表不同时刻。

### 追问 4：数据库里存时间，更推荐的做法是？

**参考回答**：正确答案是「统一存 UTC（带时区类型或整数时间戳）」，本课在「一句话说清」中说明：存储用 UTC、传输用 ISO 8601、展示时才转本地时区。统一存 UTC 才能在任意时区正确还原与比较。本课还在「本课小结」中说明：记住换算关系：时刻 = 本地日期时间 + 时区规则。

### 追问 5：补全代码：「时间与时区：九种语言横向对照」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `const shown = new Intl.____("zh-CN", {`

**参考回答**：正确答案是「DateTimeFormat」，这道题在问补全代码：时间与时区：九种语言横向对照示例中，下面这…Intl.____("zh-CN",{`，判断时要把题干限定的输入、边界与目标逐项对齐。本课示例中还能看到 `import java.time.format.DateTimeFormatter;` 这样的用法，说明该关键字在本课代码中承担实际功能。

## English Overview

**Title:** Time and Time Zones

**Summary:** Instants, wall-clock time, storage rules and timezone pitfalls.

**Category:** Cross-Language Comparison  
**Level:** 进阶  
**Key terms:** 时间, 时区, UTC, ISO 8601, 夏令时

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：九种主流语言生态横向对照
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：时间、时区、UTC、ISO 8601、夏令时
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [DevDocs](https://devdocs.io/) | 多语言 API 快速检索 |
| [官方语言文档](https://developer.mozilla.org/docs/Web) | 跨语言语义对照 |

> 本课主题：时刻与本地时间、三条铁律、数据库字段选择与常见时区错误。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
