# 序列化格式：JSON、YAML、Protobuf 横向对照

![序列化格式：JSON、YAML、Protobuf 横向对照](images/category_cross_serialization.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：18 分钟

## 学习目标

- 能用自己的话解释「序列化格式：JSON、YAML、Protobuf 横向对照」解决了什么问题，而不是只背术语。
- 能说清 「序列化」、「JSON」、「YAML」、「Protobuf」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「跨语言对照」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：四种格式对比、各语言写法、大整数与兼容性规则。

## 前置知识

- 先完成上一课《时间与时区：九种语言横向对照》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：序列化、JSON、YAML。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 一句话说清

序列化解决「把内存里的数据变成可传输、可存储的字节」。
选格式只需回答三个问题：**给谁看、体积要求、是否强类型**。

## 四种主流格式对比

| 维度 | JSON | YAML | Protobuf | MessagePack |
| --- | --- | --- | --- | --- |
| 可读性 | 好 | 最好 | 差（二进制） | 差（二进制） |
| 体积 | 中 | 大 | **小** | 较小 |
| 解析速度 | 中 | 慢 | **快** | 快 |
| 强类型 | 否 | 否 | **是（schema）** | 否 |
| 支持注释 | 否 | 是 | 是（源码里） | 否 |
| 浏览器支持 | 原生 | 需库 | 需库 | 需库 |
| 典型用途 | API、配置 | 配置文件 | 服务间通信 | 缓存、消息 |

## JSON：最通用的交换格式

```json
{
  "id": 1,
  "name": "小明",
  "tags": ["a", "b"],
  "address": { "city": "上海" },
  "active": true,
  "score": null
}
```

| 规则 | 说明 |
| --- | --- |
| 键必须是字符串 | 且用双引号 |
| 值类型 | 对象、数组、字符串、数字、布尔、null |
| 不支持注释 | 需要注释就用 JSON5 或 YAML |
| 数字精度 | 大整数可能丢精度，需转字符串 |
| 无循环引用 | 有环的数据结构会报错 |

```text
JSON 的三个高频坑
  · 大整数超 2 的 53 次方时，JavaScript 会丢精度，改用字符串
  · 键顺序不保证（多数实现保留，但规范不要求）
  · 不支持 undefined、NaN、Infinity
```

## YAML：配置首选，但要小心缩进

```yaml
# 支持注释
server:
  host: 0.0.0.0
  port: 8080
features:
  - dark-mode
  - export
database:
  url: postgres://user:pass@db:5432/app
  pool: { min: 2, max: 10 }
```

| 优势 | 风险 |
| --- | --- |
| 可读性强，支持注释 | 缩进敏感，Tab 会报错 |
| 支持锚点与引用 | 类型推断诡异（裸写 `no` 会变成布尔） |
| 适合多层配置 | 复杂结构容易看错层级 |

```yaml
# 隐式类型的经典陷阱
country: NO          # 会被解析成布尔 false，不是字符串
version: 1.10        # 被解析成数字 1.1

# 正确写法
country: "NO"
version: "1.10"
```

## Protobuf：强类型加上小体积

```protobuf
syntax = "proto3";

message User {
  int64 id = 1;
  string name = 2;
  repeated string tags = 3;
  bool active = 4;
}
```

| 特性 | 说明 |
| --- | --- |
| 字段编号 | 发布后不可改；删除字段要用 `reserved` |
| 兼容性 | 新增字段向后兼容，改类型可能不兼容 |
| 体积 | 比 JSON 小 3 到 10 倍 |
| 可读性 | 需工具解码，不适合手工编辑 |
| 适用 | 服务间高频调用、移动端弱网 |

```text
兼容性规则
  可以：新增字段（用新编号）、删除字段并 reserved
  不可以：复用旧编号、改变已有字段的类型
```

## 各语言的序列化写法

```python
import json

with open("config.json", encoding="utf-8") as f:
    data = json.load(f)

with open("out.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

payload = {"id": str(1234567890123456789)}   # 大整数用字符串
```

```javascript
const data = JSON.parse(text);
const json = JSON.stringify(data, null, 2);
const big = JSON.parse('{"id":"1234567890123456789"}');   // 保持字符串
```

```java
import com.fasterxml.jackson.databind.ObjectMapper;

ObjectMapper mapper = new ObjectMapper();
User user = mapper.readValue(text, User.class);
String json = mapper.writerWithDefaultPrettyPrinter().writeValueAsString(user);

// @JsonIgnoreProperties(ignoreUnknown = true) 可避免上游加字段就崩
```

```csharp
using System.Text.Json;

var user = JsonSerializer.Deserialize<User>(text);
string json = JsonSerializer.Serialize(user, new JsonSerializerOptions
{
    WriteIndented = true,
    PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
});
```

```go
import "encoding/json"

var user User
if err := json.Unmarshal(data, &user); err != nil {
    return fmt.Errorf("解析失败: %w", err)
}
out, err := json.Marshal(user)

// 严格模式：上游多传字段时直接报错
dec := json.NewDecoder(bytes.NewReader(data))
dec.DisallowUnknownFields()
err = dec.Decode(&user)
```

```rust
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
struct User {
    id: u64,
    name: String,
    #[serde(default)]
    tags: Vec<String>,
}

let user: User = serde_json::from_str(text)?;
let json = serde_json::to_string_pretty(&user)?;
```

## 选择决策表

| 场景 | 推荐 |
| --- | --- |
| 对外 REST API | JSON |
| 配置文件 | YAML 或 TOML |
| 服务间高频通信 | Protobuf（gRPC） |
| 本地缓存 | MessagePack 或 Protobuf |
| 日志 | JSON（一行一条） |
| 数据导出给非技术人员 | CSV |

## 序列化的三条通用纪律

```text
1. 反序列化之后必须校验：格式正确不代表内容合法
2. 大整数用字符串传输，避免精度丢失
3. 兼容性优先：新增字段要有默认值，删除字段要保留编号
```

```typescript
// 类型断言不等于校验
const data = (await res.json()) as User;      // 危险

// 正确：解析后真的校验
const parsed = UserSchema.parse(await res.json());
```

## 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 大整数用 JSON 数字 | 精度丢失 | 用字符串 |
| YAML 用 Tab 缩进 | 解析失败 | 统一空格 |
| YAML 裸写 NO 或 1.10 | 类型被隐式转换 | 加引号 |
| Protobuf 复用字段编号 | 线上数据错乱 | 用 `reserved` 保留 |
| 反序列化后不校验 | 脏数据进入业务 | 用 schema 校验 |
| 上游加字段就报错 | 兼容性差 | 忽略未知字段 |
| JSON 里塞注释 | 解析失败 | 改 JSON5 或 YAML |
| 用 JSON 传二进制 | 体积膨胀 | 用 base64 或二进制格式 |

## 本课小结
- **可读性优先选 JSON 或 YAML，性能与类型优先选 Protobuf**。
- 大整数与隐式类型是 JSON、YAML 最常见的两个坑。
- Protobuf 的生命线是**字段编号兼容性**，改之前先想清楚。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「序列化、JSON、YAML」完成复述、实验和交付，每个结果都要能被别人检查。

用两种语言实现同一行为，再对比语法、错误、性能和生态差异。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「序列化格式：JSON、YAML、Protobuf 横向对照」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「JSON」是什么关系？

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
- 至少覆盖「序列化」和「JSON」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Serialization Formats

**Summary:** Format comparison, language snippets and compatibility rules.

**Category:** Cross-Language Comparison  
**Level:** 进阶  
**Key terms:** 序列化, JSON, YAML, Protobuf, 兼容性

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：九种主流语言生态横向对照
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：序列化、JSON、YAML、Protobuf、兼容性
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- top50-rewrite:v1 -->

## 课程专属精读：序列化格式：JSON、YAML、Protobuf 横向对照

### 一、知识地图

| 主题 | 核心要点 | 验证方式 |
| --- | --- | --- |
| 一句话说清 | 序列化解决「把内存里的数据变成可传输、可存储的字节」。 | 复述要点 + 举一个反例 |
| 四种主流格式对比 | 维度：可读性；JSON：好；YAML：最好 | 复述要点 + 举一个反例 |
| JSON：最通用的交换格式 | { "id": 1, "name": "小明", "tags": ["a", "b"], "address": { "city": "上海" }, "active": true… | 运行示例 + 换一个边界输入 |
| YAML：配置首选，但要小心缩进 | # 支持注释 server: host: 0.0.0.0 port: 8080 features: - dark-mode - export database: url: po… | 运行示例 + 换一个边界输入 |
| Protobuf：强类型加上小体积 | syntax = "proto3"; | 运行示例 + 换一个边界输入 |
| 各语言的序列化写法 | import json | 运行示例 + 换一个边界输入 |

### 二、机制与验证

1. **一句话说清**：序列化解决「把内存里的数据变成可传输、可存储的字节」。 验证方式：先复述要点，再举一个反例说明边界。
2. **四种主流格式对比**：维度：可读性；JSON：好；YAML：最好 验证方式：先复述要点，再举一个反例说明边界。
3. **JSON：最通用的交换格式**：{ "id": 1, "name": "小明", "tags": ["a", "b"], "address": { "city": "上海" }, "active": true… 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
4. **YAML：配置首选，但要小心缩进**：# 支持注释 server: host: 0.0.0.0 port: 8080 features: - dark-mode - export database: url: po… 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
5. **Protobuf：强类型加上小体积**：syntax = "proto3"; 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
6. **各语言的序列化写法**：import json 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。

### 三、专属检查问题

1. 「一句话说清」要解决什么问题？请用一句话说明，并给出一个具体例子。
2. 「四种主流格式对比」的输入和输出分别是什么？
3. 「JSON：最通用的交换格式」最常见的失败方式是什么？如何定位？
4. 「YAML：配置首选，但要小心缩进」的适用边界在哪里？什么情况下不该使用？
5. 「Protobuf：强类型加上小体积」和相邻主题相比，最关键的差别是什么？
6. 「各语言的序列化写法」如何验证自己真的掌握了？写出一个可执行的检查步骤。

### 四、故障排查

1. 固定输入和环境，确认问题能稳定复现。
2. 找到第一个异常状态，不从最终错误倒推。
3. 每次只改一个变量，记录预测和真实结果。
4. 修复后补边界、失败与重复执行三类测试。

## 专属复习题库

**问：一句话说清的核心要点是什么？**

答：序列化解决「把内存里的数据变成可传输、可存储的字节」。

**问：四种主流格式对比的核心要点是什么？**

答：维度：可读性；JSON：好；YAML：最好

**问：JSON：最通用的交换格式的核心要点是什么？**

答：{ "id": 1, "name": "小明", "tags": ["a", "b"], "address": { "city": "上海" }, "active": true…

**问：YAML：配置首选，但要小心缩进的核心要点是什么？**

答：# 支持注释 server: host: 0.0.0.0 port: 8080 features: - dark-mode - export database: url: po…

**问：Protobuf：强类型加上小体积的核心要点是什么？**

答：syntax = "proto3";

**问：各语言的序列化写法的核心要点是什么？**

答：import json

## 逐步练习：序列化格式：JSON、YAML、Protobuf 横向对照

### 练习 1：一句话说清

1. 不看原文，用自己的话复述：序列化解决「把内存里的数据变成可传输、可存储的字节」。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 2：四种主流格式对比

1. 不看原文，用自己的话复述：维度：可读性；JSON：好；YAML：最好
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 3：JSON：最通用的交换格式

1. 不看原文，用自己的话复述：{ "id": 1, "name": "小明", "tags": ["a", "b"], "address": { "city": "上海" }, "active": true…
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 4：YAML：配置首选，但要小心缩进

1. 不看原文，用自己的话复述：# 支持注释 server: host: 0.0.0.0 port: 8080 features: - dark-mode - export database: url: po…
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 5：Protobuf：强类型加上小体积

1. 不看原文，用自己的话复述：syntax = "proto3";
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 6：各语言的序列化写法

1. 不看原文，用自己的话复述：import json
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

## 故障排查手册：序列化格式：JSON、YAML、Protobuf 横向对照

| 现象 | 优先检查 | 修复动作 |
| --- | --- | --- |
| 「一句话说清」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「四种主流格式对比」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「JSON：最通用的交换格式」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「YAML：配置首选，但要小心缩进」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「Protobuf：强类型加上小体积」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「各语言的序列化写法」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |

## 自测与面试：序列化格式：JSON、YAML、Protobuf 横向对照

1. 「一句话说清」的输入和输出分别是什么？
2. 「四种主流格式对比」最常见的失败方式是什么？如何定位？
3. 「JSON：最通用的交换格式」的适用边界在哪里？什么情况下不该使用？
4. 「YAML：配置首选，但要小心缩进」和相邻主题相比，最关键的差别是什么？
5. 「Protobuf：强类型加上小体积」如何验证自己真的掌握了？写出一个可执行的检查步骤。
6. 「各语言的序列化写法」要解决什么问题？请用一句话说明，并给出一个具体例子。

## 专属进阶任务 5：序列化格式：JSON、YAML、Protobuf 横向对照

把本课 6 个主题串成一个小练习：选其中一个主题做出可运行的例子，再为另外两个主题各写一条边界用例，最后用一句话说明你的验证结论。

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
| [DevDocs](https://devdocs.io/) | 多语言 API 快速检索 |
| [官方语言文档](https://developer.mozilla.org/docs/Web) | 跨语言语义对照 |

> 本课主题：四种格式对比、各语言写法、大整数与兼容性规则。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

