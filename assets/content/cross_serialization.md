# 序列化格式：JSON、YAML、Protobuf 横向对照

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：40 分钟

![JSON、YAML、Protobuf 的对比](images/diagram_cross_serialization.webp)

![序列化格式：JSON、YAML、Protobuf 横向对照](images/category_cross_serialization.webp)

## 学习目标

- 能用自己的话解释序列化格式：JSON、YAML、Protobuf 横向对照解决了什么问题，而不是只背术语。
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

## 常见错误与排查

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

> 本课练习重点：围绕「序列化、JSON、YAML」完成复述、实验和交付，每个结果都要能被别人检查。

用两种语言实现同一行为，再对比语法、错误、性能和生态差异。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 序列化格式：JSON、YAML、Protobuf 横向对照解决了什么问题？
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

## 可运行练习

### 任务 1：先跑通，再解释

```python
import json

with open("config.json", encoding="utf-8") as f:
    data = json.load(f)

with open("out.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

payload = {"id": str(1234567890123456789)}   # 大整数用字符串
```

### 任务 2：只改一个条件

把「序列化格式：JSON、YAML、Protobuf 横向对照」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只把序列化的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「序列化格式：JSON、YAML、Protobuf 横向对照」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响序列化。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：本课的 序列化 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 序列化 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 序列化 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“序列化 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 序列化 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 JSON 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 JSON 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 JSON 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“JSON 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 JSON 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：本课的验证只在开发机通过

**症状**：在本课的练习或生产场景里出现“本课的验证只在开发机通过”。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，序列化 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 深入补充：序列化格式：JSON、YAML、Protobuf 横向对照 的取舍与边界

### 一、把概念放回真实约束

学习序列化格式：JSON、YAML、Protobuf 横向对照时，最容易只记住结论而忽略前提。先写出三个约束：数据规模、时间预算、可接受的失败方式；再判断 序列化 与 JSON 在这些约束下是否仍然成立。只要约束改变，原来的最优解就可能变成错误解。

| 维度 | 序列化 的典型写法 | 另一种语言的等价写法 | 迁移时最易踩的坑 |
| --- | --- | --- | --- |
| 错误处理 | 显式返回或抛出 | 异常或结果类型 | 错误被静默吞掉 |
| 并发模型 | 线程、协程或事件循环 | 运行时调度不同 | 共享状态与取消语义 |
| 依赖管理 | 官方包管理器 | 生态与锁文件不同 | 版本解析结果不一致 |

### 二、三个容易混淆的边界

1. 澄清输入与目标。先写清「序列化格式：JSON、YAML、Protobuf 横向对照」要解决的问题、合法输入范围和成功标准，再进入后续步骤。
2. **把“平均值”当成“全部”**：序列化 的指标好看，不代表尾部请求、冷启动或失败重试也好看。
3. **把“当前版本”当成“永久行为”**：JSON 依赖的默认值、API 或性能特征都可能随版本变化，需要固定版本并保留回归用例。

### 三、一个生产场景

假设团队要在真实系统里使用序列化格式：JSON、YAML、Protobuf 横向对照：第一周先做小流量验证，记录 序列化 的基线与异常；第二周扩大输入规模，观察 JSON 是否成为瓶颈；第三周再做故障演练，主动注入超时、重复请求和依赖不可用，确认系统能降级、能重试、能恢复。每一步都要留下指标、日志和结论，而不是只留下“感觉更快了”。

### 四、自测清单

- 能否用一句话说出序列化格式：JSON、YAML、Protobuf 横向对照解决的核心问题与不适用场景？
- 能否画出 序列化 的数据流或状态变化，并标出失败路径？
- 能否给出一个反例，证明某个看似合理的结论在边界条件下不成立？
- 能否写出一条可复现的验证命令，让别人独立得到相同结论？

### 五、跨语言迁移清单

在本课的迁移练习里，先列出 序列化 在两种语言中的类型、错误处理、并发模型和内存管理差异；再用同一个输入各写一版最小实现，比较编译或运行时的错误信息。最后记录 JSON 在两种语言里的性能与可读性差异，避免只凭语法熟悉度做选型。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「服务间高频通信更推荐哪种格式，为什么？」的判断依据。
- [ ] 不看解析，能说出「在 JavaScript 中处理超大整数 ID，正确做法是？」的判断依据。
- [ ] 不看解析，能说出「YAML 中裸写 no 会有什么问题？」的判断依据。
- [ ] 不看解析，能说出「Protobuf 中删除字段的正确做法是？」的判断依据。
- [ ] 不看解析，能说出的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `no` | \| 支持锚点与引用 \| 类型推断诡异（裸写 `no` 会变成布尔） \| |
| `reserved` | \| 字段编号 \| 发布后不可改；删除字段要用 `reserved` \| |
| `序列化` | 在本课的迁移练习里，先列出 序列化 在两种语言中的类型、错误处理、并发模型和内存管理差异；再用同一个输入各写一版最小实现，比较编译或运行时的错误信息。 |
| `JSON` | 围绕“JSON 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。 |
| `YAML` | 把「序列化格式：JSON、YAML、Protobuf 横向对照」的最小示例复制一份，只改一个条件再跑一次：。 |
| `Protobuf` | 把「序列化格式：JSON、YAML、Protobuf 横向对照」的最小示例复制一份，只改一个条件再跑一次：。 |

## 考点精讲

### 考点 1：多选辨析·序列化

- **题目**：围绕“序列化格式：JSON、YAML、Protobuf 横向对照”中的 序列化、JSON、YAML，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把序列化格式：JSON、YAML、Protobuf 横向对照拆成概念、示例与故障现场三部分，因此判断 序列化 时必须同时交代输入、输出和失败路径，这使“学习 序列化 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在序列化格式：JSON、YAML、Protobuf 横向对照里，判断 JSON 时要固定版本与边界输入，所以“验证 JSON 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：代码补全·序列化

- **题目**：阅读「序列化格式：JSON、YAML、Protobuf 横向对照」正文里的这段 JavaScript 代码，下面哪一项判断是正确的？
- **判断依据**：在「序列化格式：JSON、YAML、Protobuf 横向对照」里，这段代码只做静态声明，没有循环、分支或可观察输出。这段代码出自「序列化格式：JSON、YAML、Protobuf 横向对照」的正文示例，围绕序列化、JSON、YAML展开；把输入或边界换成空值、极值或失败情况后，结论要以「序列化格式：JSON、YAML、Protobuf 横向对照」的实际运行结果为准。

### 考点 3：概念判断·序列化

- **题目**：YAML 中裸写 no 会有什么问题？
- **判断依据**：在「序列化格式：JSON、YAML、Protobuf 横向对照」里，被解析成布尔 false 而不是字符串。YAML 有隐式类型推断，no、yes、on、off 会被当成布尔值。「序列化格式：JSON、YAML、Protobuf 横向对照」要求先交代序列化、JSON、YAML的前提再下结论，所以“被解析成布尔 false 而不是字符串”只在题干“YAML 中裸写 no 会有什么问题”给定的条件下成立。

### 考点 4：概念判断·序列化

- **题目**：Protobuf 中删除字段的正确做法是？
- **判断依据**：在「序列化格式：JSON、YAML、Protobuf 横向对照」里，结论应落在「删除字段并用 reserved 保留编号」。字段编号是兼容性的生命线，必须保留不复用。在「序列化格式：JSON、YAML、Protobuf 横向对照」里，这道题要求区分概念与边界，「删除字段并用 reserved 保留编号」只有在题干给出的前提下才成立，而「直接把字段删掉，编号留给新字段复用」、「把字段类型改成 string」缺少同一组条件。

### 考点 5：填空·序列化

- **题目**：补全代码：「序列化格式：JSON、YAML、Protobuf 横向对照」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `· 大整数超 2 的 53 次方时，____ 会丢精度，改用字符串`
- **判断依据**：在「序列化格式：JSON、YAML、Protobuf 横向对照」里，JavaScript。「序列化格式：JSON、YAML、Protobuf 横向对照」要求先交代序列化、JSON、YAML的前提再下结论，所以“JavaScript”只在题干“序列化格式”给定的条件下成立。把“JavaScript”代回「序列化格式：JSON、YAML、Protobuf 横向对照」里“序列化格式”的例子核对，条件一旦改变，结论就要用序列化、JSON、YAML重新推导。

## 复习与自测

- [ ] 能用一句话说明「一句话说清」解决什么问题。
- [ ] 能把「四种主流格式对比」的判断标准套到一个新例子上。
- [ ] 能说清「JSON：最通用的交换格式」的结论，并说出它的适用边界。
- [ ] 能用自己的话复述「YAML：配置首选，但要小心缩进」，并各举一个正例和反例。
- [ ] 能解释「Protobuf：强类型加上小体积」里最容易混淆的两个概念。
- [ ] 能不看正文写出「各语言的序列化写法」的关键步骤。

## English Overview

**Title:** Serialization Formats

**Summary:** Format comparison, language snippets and compatibility rules.

**Category:** Cross-Language Comparison
**Level:** 进阶
**Key terms:** 序列化, JSON, YAML, Protobuf, 兼容性

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：九种主流语言生态横向对照
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：序列化、JSON、YAML、Protobuf、兼容性
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [DevDocs](https://devdocs.io/) | 多语言 API 快速检索 |
| [Rosetta Code](https://rosettacode.org/wiki/Rosetta_Code) | 同一任务的跨语言实现 |
| [MDN Web Docs](https://developer.mozilla.org/) | Web 技术跨语言参考 |

> 「序列化格式：JSON、YAML、Protobuf 横向对照」的链接用于离线阅读后的延伸核对；App 不会自动联网。
