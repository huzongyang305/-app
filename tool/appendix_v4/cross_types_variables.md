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

