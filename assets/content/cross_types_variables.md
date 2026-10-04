# 类型与变量：九种语言横向对照

![类型与变量：九种语言横向对照](images/category_cross_types_variables.webp)

> 内容更新时间：2026-10-03 · 学习阶段：入门 · 预计用时：20 分钟

## 学习目标

- 能用自己的话解释「类型与变量：九种语言横向对照」解决了什么问题，而不是只背术语。
- 能说清 「类型系统」、「变量」、「不可变」、「空值」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「跨语言对照」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：静态与动态、可变与不可变、空值表达的横向对照。

## 前置知识

- 先完成上一课《九种语言的第一个程序》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：入门。只需要基本计算机操作，不要求编程经验。
- 开始前先复习：类型系统、变量、不可变。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 一句话目标

变量「怎么声明、能不能改、能不能换类型」，最能体现一门语言的性格。
本文把九种语言放在同一张表里对照。

## 变量声明对照

| 语言 | 可变变量 | 不可变 | 类型标注 |
| --- | --- | --- | --- |
| Python | `x = 1` | 无语法强制（约定全大写） | 可选：`x: int = 1` |
| JavaScript | `let x = 1` | `const x = 1` | 无 |
| TypeScript | `let x: number = 1` | `const x: number = 1` | 有，编译期检查 |
| Java | `int x = 1;` | `final int x = 1;` | 必须写 |
| C# | `int x = 1;` | `const int X = 1;` | 必须写，可用 `var` 推断 |
| C++ | `int x = 1;` | `const int x = 1;` | 必须写，可用 `auto` 推断 |
| Go | `x := 1` | `const X = 1` | 可用 `:=` 推断 |
| Rust | `let mut x = 1;` | `let x = 1;`（默认不可变） | 可推断，函数签名必须写 |
| Shell | `x=1` | `readonly x=1` | 无类型概念 |

## 类型系统的四个维度

| 维度 | 说明 | 例子 |
| --- | --- | --- |
| 静态 / 动态 | 类型在编译期还是运行时确定 | Java 静态，Python 动态 |
| 强 / 弱 | 是否允许隐式跨类型转换 | Python 偏强，JavaScript 偏弱 |
| 显式 / 推断 | 是否必须手写类型 | Java 必须，Go 与 Rust 可推断 |
| 可变 / 不可变 | 默认能否重新赋值 | Rust 默认不可变，其它多默认可变 |

## 数字与字符串的坑：九种语言对比

```python
# Python：类型错误会直接抛异常
"1" + 1          # TypeError
"1" + str(1)     # "11"
int("1") + 1     # 2
```

```javascript
// JavaScript：会隐式转换，最容易踩坑
"1" + 1          // "11"（字符串拼接）
"1" - 1          // 0（转成数字）
Number("1") + 1  // 2
```

```typescript
// TypeScript：编译期就拦住
const a: number = 1;
// a + "1" 会被允许（结果为 string），但类型会变化
```

```java
// Java：字符串与数字相加会拼接，且顺序影响结果
System.out.println(1 + 2 + "a");   // "3a"
System.out.println("a" + 1 + 2);   // "a12"
```

```csharp
// C#：字符串插值是更安全的写法
Console.WriteLine($"{1 + 1}");      // "2"
```

```cpp
// C++：整数除法丢小数是最经典的坑
double a = 5 / 2;                  // 2.0，不是 2.5
double b = 5 / 2.0;                // 2.5
```

```go
// Go：类型严格，必须显式转换
var a int = 1
// var b float64 = a        // 编译错误
b := float64(a) + 1.5
```

```rust
// Rust：同样严格，整数与浮点不能混算
let a = 1i32;
let b = a as f64 + 1.5;
```

```bash
# Shell：一切皆字符串，需要算术时用 (( ))
a=1
b=$((a + 2))
echo "$b"                        # 3
echo "$a + 2"                    # 1 + 2（字符串）
```

## 空值怎么表达

| 语言 | 空值 | 检查方式 |
| --- | --- | --- |
| Python | `None` | `if x is None:` |
| JavaScript | `null` / `undefined` | `x == null` 或 `x === undefined` |
| TypeScript | 同 JavaScript，加 `strictNullChecks` | 用 `?.` 与 `??` |
| Java | `null` | `Optional` 或判空 |
| C# | `null`（可空引用类型） | `?.` 与 `??` |
| C++ | `nullptr` | 判空或 `std::optional` |
| Go | `nil`（仅指针、切片、map、接口等） | `if x == nil` |
| Rust | 没有 null，用 `Option<T>` | `match`、`?`、`unwrap_or` |
| Shell | 空字符串 `""` | `[[ -z "$x" ]]` |

**Rust 用类型系统消灭了空指针**：想表达「可能没有」，就必须用 `Option<T>`，编译器强制你处理。

## 新手最容易踩的八个坑

| 坑 | 出现语言 | 正确做法 |
| --- | --- | --- |
| 字符串与数字直接相加 | JavaScript、Java | 显式转换或插值 |
| 整数除法丢小数 | C++、Java、Go、Rust | 先转浮点 |
| 有符号与无符号混用 | C++、Rust | 统一类型 |
| 浮点直接比相等 | 全部 | 用误差范围 |
| 把 `None` 当字符串用 | Python | 显式判空 |
| 忘记 `strictNullChecks` | TypeScript | 打开严格模式 |
| 以为 `const` 是深不可变 | JavaScript、TypeScript | 它只锁绑定 |
| 变量名与关键字冲突 | 全部 | 避开保留字 |

## 本课小结
- **类型越严格，越早暴露问题**：Rust、Go、TypeScript 严格模式属于这一类。
- **类型越宽松，写得越快、坑也越多**：JavaScript、Shell 属于这一类。
- 判断一门语言对新手是否友好，可以先看它「字符串加数字」会发生什么。

<!-- appendix:v4 -->

## 补充：类型转换矩阵、装箱与类型推断

### 隐式转换与显式转换对照

| 语言 | 是否允许隐式转换 | 显式转换写法 | 典型陷阱 |
| --- | --- | --- | --- |
| Python | 近似不允许（数字间除外） | `int(x)`、`str(x)` | `int("3.5")` 报错，要先 `float` |
| JavaScript | **大量隐式转换** | `Number(x)`、`String(x)` | `"1" + 1` 得到 `"11"` |
| TypeScript | 编译期拦截大部分 | `as`、`Number()` | 断言不改运行时数据 |
| Java | 小范围到大范围自动 | `(int) longValue` | 超范围强转会截断 |
| C# | 同上，另有 `checked` | `(int)longValue`、`Convert.ToInt32` | 溢出默认不报错 |
| C++ | 大量隐式（含构造转换） | `static_cast<int>(x)` | 类型提升导致重载选错 |
| Go | **不允许隐式数值转换** | `float64(n)` | 编译直接报错，最安全 |
| Rust | 不允许隐式转换 | `x as f64`、`From`/`Into` | `as` 会截断，需手动检查 |
| Shell | 一切皆字符串 | `$(( ))` 做算术 | 比较符号需区分字符串与数值 |

```text
安全排序（从严格到宽松）
  Rust / Go  >  Java / C# / TypeScript  >  C++  >  JavaScript / Shell
越严格的语言，越早暴露问题，但需要写更多转换代码
```

### 装箱与拆箱：包装类的开销

```java
// Java：基本类型与包装类之间的自动转换
Integer boxed = 42;          // 装箱：int → Integer（堆上对象）
int unboxed = boxed;         // 拆箱：Integer → int

Integer a = 127, b = 127;
System.out.println(a == b);  // true（-128~127 有缓存）
Integer c = 128, d = 128;
System.out.println(c == d);  // false（超出缓存，两个对象）
```

| 影响 | 说明 |
| --- | --- |
| 内存 | 每个包装对象有对象头开销 |
| 性能 | 频繁装箱在热路径上会显著变慢 |
| 空值 | 包装类可能为 `null`，拆箱会抛空指针 |

**建议**：热路径用基本类型；泛型与可空场景才用包装类，且比较一律用 `equals`。

### 类型推断：四种写法

| 语言 | 推断写法 | 推断时机 | 注意 |
| --- | --- | --- | --- |
| Java | `var list = new ArrayList<String>()` | 编译期 | 只能用于局部变量 |
| C# | `var user = new User()` | 编译期 | 不等于 `dynamic` |
| C++ | `auto p = std::make_unique<T>()` | 编译期 | 需要引用要写 `auto&` |
| Go | `n := 42` | 编译期 | 只能用在函数内 |
| Rust | `let x = 5;` | 编译期 | 默认 `i32`，需要时标注 |
| Kotlin | `val x = 5` | 编译期 | 与 `var` 区分可变性 |
| TypeScript | `const x = 5` | 编译期 | `as const` 可收窄为字面量 |

```text
推断的三个好处与一个风险
  好处：少写类型、重构时自动跟随、泛型调用更简洁
  风险：类型不明显时降低可读性

经验：局部变量用推断，函数签名与公共 API 写全类型
```

### 类型别名的三种用法

```typescript
// TypeScript
type UserId = string;                    // 语义化别名
type Result<T> = { ok: true; data: T } | { ok: false; error: string };
type Status = "pending" | "done";        // 联合字面量
```

```rust
// Rust：用 newtype 模式避免语义混淆
struct UserId(u64);
struct OrderId(u64);
// 两者不能互相赋值，编译器帮你挡住「把订单 ID 当用户 ID 用」
```

```go
// Go：类型别名 vs 新类型
type UserID = int64        // 别名：与 int64 完全等价
type OrderID int64         // 新类型：需要显式转换
```

### 类型检查发生在什么时候

| 语言 | 检查时机 | 运行时能否发现类型错误 |
| --- | --- | --- |
| TypeScript | 编译期（转译后类型消失） | 不能 |
| Java / C# | 编译期 + 运行时（反射、强转） | 能（ClassCastException） |
| Rust | 编译期 | 基本不能（类型擦除后仍安全） |
| Go | 编译期 + 运行时断言 | 能（类型断言失败） |
| Python / JavaScript | 运行时 | 能（TypeError） |

```text
结论：无论哪种语言，外部输入都要做运行时校验。
TypeScript 的 interface 不会帮你在运行时挡住脏数据。
```

### 自查清单

- [ ] 说得清自己常用语言的隐式转换规则
- [ ] 知道包装类比较必须用 equals
- [ ] 热路径避免频繁装箱
- [ ] 局部变量用推断，公共 API 写全类型
- [ ] 外部输入一律做运行时校验

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「类型系统、变量、不可变」完成复述、实验和交付，每个结果都要能被别人检查。

用两种语言实现同一行为，再对比语法、错误、性能和生态差异。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「类型与变量：九种语言横向对照」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「变量」是什么关系？

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
- 至少覆盖「类型系统」和「变量」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Types and Variables Across Languages

**Summary:** Static vs dynamic typing, mutability and null handling compared.

**Category:** Cross-Language Comparison  
**Level:** 入门  
**Key terms:** 类型系统, 变量, 不可变, 空值, 类型推断

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：入门
- 适用环境：九种主流语言生态横向对照
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：类型系统、变量、不可变、空值、类型推断
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

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

> 本课主题：静态与动态、可变与不可变、空值表达的横向对照。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

