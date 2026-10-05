# 变量、类型与字符串

![基本类型、包装类与字符串](images/diagram_java_types.webp)

![变量、类型与字符串](images/remaining_java_types.webp)

> 内容更新时间：2026-10-03 · 学习阶段：基础 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「变量、类型与字符串」解决了什么问题，而不是只背术语。
- 能说清 「int」、「Integer」、「装箱」、「String」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Java」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：基本类型与包装类、自动装箱、类型转换与 String 关键特性。

## 前置知识

- 先完成上一课《环境与 JVM》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议会读写简单代码或命令，并理解变量、输入输出等基本概念。
- 开始前先复习：int、Integer、装箱。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 基本类型与包装类

```java
int      count = 42;        // 4 字节
long     big = 9_000_000_000L;
double   pi = 3.14159;
float    ratio = 0.5f;
boolean  ok = true;
char     letter = 'A';

Integer boxed = count;              // 自动装箱
int unboxed = boxed;                // 自动拆箱
```

基本类型不能为 `null`、不能当泛型参数；包装类可以，但拆箱时若为 `null` 会抛 `NullPointerException`。

## 类型转换

```java
int small = 100;
long widened = small;                 // 自动：小范围 → 大范围

double value = 3.99;
int truncated = (int) value;          // 强制：3，小数被截断

String text = "123";
int parsed = Integer.parseInt(text);  // 字符串 → 数字
String back = String.valueOf(parsed);
```

## String 要点

```java
String a = "hello";
String b = "hello";
System.out.println(a == b);            // true：字符串常量池复用

String c = new String("hello");
System.out.println(a == c);            // false：不同对象
System.out.println(a.equals(c));       // true：内容相同

String joined = a + " " + "world";     // 编译期优化为 StringBuilder
String upper = joined.toUpperCase();
```

**比较内容一律用 `equals`**；字符串不可变，每次「修改」都会产生新对象，循环拼接应使用 `StringBuilder`。

```java
StringBuilder sb = new StringBuilder();
for (int i = 0; i < 3; i++) {
    sb.append(i).append(',');
}
System.out.println(sb.toString());

// Java 15+ 文本块，多行字符串更清晰
String json = """
        {"name": "tom"}
        """;
```

## var 与常量

```java
var names = new ArrayList<String>();   // Java 10+ 局部变量类型推导
final int MAX = 100;                   // 常量，不可重新赋值
```

`var` 只用于局部变量，不降低类型安全，但可读性优先时可显式写类型。

## 本课小结
记住三个高频陷阱：**包装类可能为 null、字符串比较用 equals、浮点不要用 == 比较精确值**。


## 基本类型与包装类速查

| 基本类型 | 大小 | 包装类 | 默认值 |
| --- | --- | --- | --- |
| `byte` | 1 字节 | `Byte` | 0 |
| `short` | 2 字节 | `Short` | 0 |
| `int` | 4 字节 | `Integer` | 0 |
| `long` | 8 字节 | `Long` | 0L |
| `float` | 4 字节 | `Float` | 0.0f |
| `double` | 8 字节 | `Double` | 0.0d |
| `char` | 2 字节 | `Character` | '\u0000' |
| `boolean` | 1 字节 | `Boolean` | false |

装箱与拆箱速查：

| 场景 | 说明 |
| --- | --- |
| `Integer a = 1;` | 自动装箱 |
| `int b = a;` | 自动拆箱，`a` 为 `null` 时抛 `NullPointerException` |
| `Integer.valueOf(127) == Integer.valueOf(127)` | `true`（缓存 -128~127） |
| `Integer.valueOf(1000) == Integer.valueOf(1000)` | 通常 `false`，比较对象引用 |
| `a.equals(b)` | 比较值，包装类推荐用法 |
| `Integer.parseInt("42")` | 字符串转 `int`，失败抛 `NumberFormatException` |

## 字符串 API 速查

| 目的 | 写法 |
| --- | --- |
| 判空 | `str == null \|\| str.isEmpty()`，或 `str.isBlank()` |
| 比较 | `a.equals(b)`、`a.equalsIgnoreCase(b)` |
| 查找 | `indexOf`、`contains`、`startsWith`、`endsWith` |
| 截取 | `substring(begin, end)`（左闭右开） |
| 替换 | `replace`、`replaceAll`（正则） |
| 拆分 | `split(",")`，注意 `split` 参数是正则 |
| 拼接 | `String.join(",", list)` |
| 格式化 | `String.format("%.2f", price)` |
| 去空格 | `strip()`（推荐）、`trim()`（仅 ASCII） |
| 大小写 | `toUpperCase(Locale.ROOT)`（避免地区差异） |
| 与数字互转 | `Integer.parseInt` / `String.valueOf` |

```java
// 文本块（Java 15+）：写多行 JSON 或 SQL 更清晰
String json = """
        {
          "name": "小明",
          "age": 18
        }
        """;

// 金额用 BigDecimal，并明确舍入模式
import java.math.BigDecimal;
import java.math.RoundingMode;

BigDecimal price = new BigDecimal("19.9");
BigDecimal total = price.multiply(BigDecimal.valueOf(3))
                        .setScale(2, RoundingMode.HALF_UP);
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `a == b` 比较字符串 | 内容相同时可能为 `false` | 用 `equals`，注意顺序避免空指针 |
| `str.equals("x")` 且 `str` 为 null | `NullPointerException` | 写成 `"x".equals(str)` 或用 `Objects.equals` |
| 包装类直接参与运算 | 为 null 时 NPE | 先判空或用基本类型 |
| `double` 算金额 | 精度误差 | 用 `BigDecimal` 并指定舍入 |
| `float` 存大整数 | 精度丢失 | 用 `long` 或 `double` |
| `int` 相加溢出 | 结果变成负数 | 用 `long` 或 `Math.addExact` |
| `"a,b,,".split(",")` 长度不符 | 结尾空串被丢弃 | 用 `split(",", -1)` 保留空串 |
| `replaceAll(".", "")` 想删点号 | 全部字符被删 | 参数是正则，点号要转义或用 `replace` |
| `String` 循环拼接 | 产生大量临时对象 | 用 `StringBuilder` |
| 用 `==` 比较包装类 | 大数值时结果错误 | 用 `equals` 或先拆箱成基本类型 |

## 自测清单

- [ ] 能列出八种基本类型、包装类与默认值。
- [ ] 知道装箱缓存的取值范围（-128~127）。
- [ ] 字符串比较一律用 `equals`，并把常量写在前面。
- [ ] 金额用 `BigDecimal`，明确小数位与舍入模式。
- [ ] 循环拼接字符串使用 `StringBuilder`。


## 零基础详解：基本类型、包装类与字符串

### 一句话说清它是什么

Java 的类型分成两大家族：**基本类型**（直接存值，8 种）和**引用类型**（存地址，指向对象）。
理解这条分界线，`==`、装箱、null 这些问题就都通了。

### 八种基本类型

| 类型 | 大小 | 范围（约） | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `byte` | 1 字节 | -128 ~ 127 | 0 | 处理原始字节 |
| `short` | 2 字节 | ±3.2 万 | 0 | 很少用 |
| `int` | 4 字节 | ±21 亿 | 0 | 默认整数类型 |
| `long` | 8 字节 | ±9.2×10¹⁸ | 0L | 写常量要加 `L` |
| `float` | 4 字节 | 约 7 位有效数字 | 0.0f | 写常量要加 `f` |
| `double` | 8 字节 | 约 15 位有效数字 | 0.0d | 默认小数类型 |
| `char` | 2 字节 | 0 ~ 65535 | '\u0000' | 存一个 Unicode 字符 |
| `boolean` | 1 位语义 | true / false | false | 不能与数字互转 |

### 基本类型 vs 包装类

| 对比项 | 基本类型 `int` | 包装类 `Integer` |
| --- | --- | --- |
| 存储 | 直接存值 | 存对象引用 |
| 能否为 null | 不能 | 能 |
| 能否当泛型参数 | 不能 | 能（`List<Integer>`） |
| 比较相等 | `==` 比值 | 必须用 `.equals()` |
| 性能 | 更好 | 有装箱开销 |

```java
Integer a = 127, b = 127;
System.out.println(a == b);        // true，小整数走了缓存池

Integer c = 128, d = 128;
System.out.println(c == d);        // false！超出缓存范围就是不同对象
```

**结论：包装类比较一律用 `.equals()`，别用 `==`。**

### 自动装箱与拆箱的隐藏陷阱

```java
Integer total = null;
int value = total;      // 拆箱时直接抛 NullPointerException
```

所以方法参数尽量用基本类型；必须用包装类时，先判空。

### String 的三条铁律

1. **不可变**：任何「修改」都返回新对象，原串不变。
2. **`==` 比地址，`.equals()` 比内容**。
3. **频繁拼接用 `StringBuilder`**，否则循环里会产生大量临时对象。

```java
String s = "abc";
s.toUpperCase();
System.out.println(s);              // 还是 abc，因为没用返回值

StringBuilder sb = new StringBuilder();
for (int i = 0; i < 3; i++) sb.append(i).append(',');
System.out.println(sb);             // 0,1,2,
```

### 类型转换：自动与强制

```java
int n = 100;
long big = n;               // 小 -> 大，自动提升
int back = (int) big;       // 大 -> 小，必须强转，可能丢高位
double d = 5 / 2;           // 结果是 2.0，不是 2.5！
double ok = 5 / 2.0;        // 2.5
```

整数除法先算完再提升，这是新手最常见的「精度丢失」原因。

### 新手最容易踩的七个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 浮点直接比相等 | 条件几乎不成立 | 用误差 `Math.abs(a - b) < 1e-9` |
| `int` 溢出 | 结果变成负数 | 用 `long`，或 `Math.addExact` 抛异常 |
| 包装类 `==` 比较 | 128 以上就不相等 | 改用 `.equals()` |
| 拆箱空指针 | `NullPointerException` | 用前判空或用基本类型 |
| `String` 循环拼接 | 数据量大时极慢 | 用 `StringBuilder` |
| 字符串没接收返回值 | 以为被改了 | `s = s.trim()` |
| 忘记 `L` / `f` 后缀 | 编译错误或精度丢失 | `long n = 10L; float f = 1.5f;` |

### 手把手练习：金额与格式化

```java
import java.math.BigDecimal;
import java.math.RoundingMode;

public class Money {
    public static void main(String[] args) {
        // 金额不要用 double，用 BigDecimal
        BigDecimal price = new BigDecimal("19.99");
        BigDecimal count = new BigDecimal("3");
        BigDecimal total = price.multiply(count)
                                .setScale(2, RoundingMode.HALF_UP);
        System.out.println("总价：" + total);

        int seconds = 3725;
        int h = seconds / 3600;
        int m = seconds % 3600 / 60;
        int s = seconds % 60;
        System.out.printf("%02d:%02d:%02d%n", h, m, s);
    }
}
```

### 学完自测

- [ ] 能列出八种基本类型并说出各自用途。
- [ ] 能解释 `Integer a = 128` 与 `b = 128` 用 `==` 比较为什么是 false。
- [ ] 知道 `s.toUpperCase()` 为什么不改变原字符串。
- [ ] 能说出 `5 / 2` 和 `5 / 2.0` 的结果差异。
- [ ] 知道涉及金额应该用 `BigDecimal`。

## 动手练习


> 本课练习重点：围绕「int、Integer、装箱」完成复述、实验和交付，每个结果都要能被别人检查。

先跑通最小类与测试，再补异常和并发边界，最后观察线程与资源变化。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「变量、类型与字符串」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「Integer」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

写一个可运行的小类，补一个普通测试和一个边界输入测试。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「int」和「Integer」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：比较两个字符串的内容，应该用？

- **正确判断**：equals()
- **判断依据**：正确答案是「equals()」，本课在「零基础详解：基本类型、包装类与字符串」中说明：结论：包装类比较一律用 .equals()，别用 ==。== 比较引用地址，equals 才比较内容。本课还在「零基础详解：基本类型、包装类与字符串」中说明：== 比地址，.equals() 比内容。本课还在「本课小结」中说明：记住三个高频陷阱：包装类可能为 null、字符串比较用 equals、浮点不要用 == 比较精确值。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 2：包装类对象为 null 时进行自动拆箱会？

- **正确判断**：抛出 NullPointerException
- **判断依据**：正确答案是「抛出 NullPointerException」，本课在「基本类型与包装类」中说明：包装类可以，但拆箱时若为 null 会抛 NullPointerException。拆箱会调用 intValue()，对象为 null 时抛空指针异常，这是常见线上问题。本课还在「本课小结」中说明：记住三个高频陷阱：包装类可能为 null、字符串比较用 equals、浮点不要用 == 比较精确值。本课还在「String 要点」中说明：字符串不可变，每次「修改」都会产生新对象，循环拼接应使用 StringBuilder。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：循环中拼接字符串推荐使用？

- **正确判断**：StringBuilder
- **判断依据**：String 不可变，循环中用 + 会不断创建新对象，StringBuilder 才是原地追加。其他选项：+ 与 concat 每次都会创建新对象，字符数组需要手工管理。针对「循环中拼接字符串推荐使用，」，本课在「String 要点」中说明：字符串不可变，每次「修改」都会产生新对象，循环拼接应使用 StringBuilder。本课还在「零基础详解：基本类型、包装类与字符串」中说明：频繁拼接用 StringBuilder，否则循环里会产生大量临时对象。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 4：Java 中 String 的不可变性意味着？

- **正确判断**：字符串内容创建后不能修改，拼接会产生新对象
- **判断依据**：正确答案是「字符串内容创建后不能修改，拼接会产生新对象」，本课在「基本类型与包装类」中说明：基本类型不能为 null、不能当泛型参数。不可变让字符串可安全共享与缓存哈希，但频繁拼接要改用 StringBuilder。本课还在「零基础详解：基本类型、包装类与字符串」中说明：Java 的类型分成两大家族：基本类型（直接存值，8 种）和引用类型（存地址，指向对象）。本课还在「零基础详解：基本类型、包装类与字符串」中说明：不可变：任何「修改」都返回新对象，原串不变。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：用 double 计算金额的主要风险是？

- **正确判断**：二进制浮点无法精确表示十进制小数
- **判断依据**：正确答案是「二进制浮点无法精确表示十进制小数」，本课在「var 与常量」中说明：var 只用于局部变量，不降低类型安全，但可读性优先时可显式写类型。金额场景应使用 BigDecimal，并明确指定舍入模式与小数位。本课还在「零基础详解：基本类型、包装类与字符串」中说明：知道 s.toUpperCase() 为什么不改变原字符串。本课还在「零基础详解：基本类型、包装类与字符串」中说明：理解这条分界线，==、装箱、null 这些问题就都通了。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 6：补全代码：「变量、类型与字符串」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `int value = total; // 拆箱时直接抛 ____`

- **正确判断**：NullPointerException / nullpointerexception
- **判断依据**：正确答案是「NullPointerException」，本课在「基本类型与包装类」中说明：包装类可以，但拆箱时若为 null 会抛 NullPointerException。本课还在「var 与常量」中说明：var 只用于局部变量，不降低类型安全，但可读性优先时可显式写类型。本课还在「零基础详解：基本类型、包装类与字符串」中说明：知道 s.toUpperCase() 为什么不改变原字符串。
- **迁移检查**：把答案换成另一种等价写法，是否仍然正确？说明依据。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「比较两个字符串的内容，应该用？」的判断依据。
- [ ] 不看解析，能说出「包装类对象为 null 时进行自动拆箱会？」的判断依据。
- [ ] 不看解析，能说出「循环中拼接字符串推荐使用？」的判断依据。
- [ ] 不看解析，能说出「Java 中 String 的不可变性意味着？」的判断依据。
- [ ] 不看解析，能说出「用 double 计算金额的主要风险是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「变量、类型与字符串」示例中，下面这行代码缺少哪个关键字或函数名？请填…」的判断依据。
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
| `null` | 基本类型不能为 `null`、不能当泛型参数；包装类可以，但拆箱时若为 `null` 会抛 `NullPointerException`。 |
| `NullPointerException` | 基本类型不能为 `null`、不能当泛型参数；包装类可以，但拆箱时若为 `null` 会抛 `NullPointerException`。 |
| `equals` | 比较内容一律用 `equals`**；字符串不可变，每次「修改」都会产生新对象，循环拼接应使用 `StringBuilder`。 |
| `StringBuilder` | 比较内容一律用 `equals`**；字符串不可变，每次「修改」都会产生新对象，循环拼接应使用 `StringBuilder`。 |
| `var` | `var` 只用于局部变量，不降低类型安全，但可读性优先时可显式写类型。 |
| `byte` | \| `byte` \| 1 字节 \| `Byte` \| 0 \| |
| `Byte` | \| `byte` \| 1 字节 \| `Byte` \| 0 \| |
| `short` | \| `short` \| 2 字节 \| `Short` \| 0 \| |
| `Short` | \| `short` \| 2 字节 \| `Short` \| 0 \| |
| `int` | \| `int` \| 4 字节 \| `Integer` \| 0 \| |
| `Integer` | \| `int` \| 4 字节 \| `Integer` \| 0 \| |
| `long` | \| `long` \| 8 字节 \| `Long` \| 0L \| |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：比较两个字符串的内容，应该用？

**参考回答**：正确答案是「equals()」，本课在「零基础详解·基本类型、包装类与字符串」中说明：结论：包装类比较一律用 .equals()，别用 ==。== 比较引用地址，equals 才比较内容。本课还在「零基础详解·基本类型、包装类与字符串」中说明：== 比地址，.equals() 比内容。本课还在「本课小结」中说明：记住三个高频陷阱：包装类可能为 null、字符串比较用 equals、浮点不要用 == 比较精确值。

### 追问 2：包装类对象为 null 时进行自动拆箱会？

**参考回答**：正确答案是「抛出 NullPointerException」，本课在「基本类型与包装类」中说明：包装类可以，但拆箱时若为 null 会抛 NullPointerException。拆箱会调用 intValue()，对象为 null 时抛空指针异常，这是常见线上问题。本课还在「本课小结」中说明：记住三个高频陷阱：包装类可能为 null、字符串比较用 equals、浮点不要用 == 比较精确值。本课还在「String 要点」中说明：字符串不可变，每次「修改」都会产生新对象，循环拼接应使用 StringBuilder。

### 追问 3：循环中拼接字符串推荐使用？

**参考回答**：String 不可变，循环中用 + 会不断创建新对象，StringBuilder 才是原地追加。其他选项：+ 与 concat 每次都会创建新对象，字符数组需要手工管理。针对「循环中拼接字符串推荐使用，」，本课在「String 要点」中说明：字符串不可变，每次「修改」都会产生新对象，循环拼接应使用 StringBuilder。本课还在「零基础详解·基本类型、包装类与字符串」中说明：频繁拼接用 StringBuilder，否则循环里会产生大量临时对象。

### 追问 4：Java 中 String 的不可变性意味着？

**参考回答**：正确答案是「字符串内容创建后不能修改，拼接会产生新对象」，本课在「基本类型与包装类」中说明：基本类型不能为 null、不能当泛型参数。不可变让字符串可安全共享与缓存哈希，但频繁拼接要改用 StringBuilder。本课还在「零基础详解·基本类型、包装类与字符串」中说明：Java 的类型分成两大家族：基本类型（直接存值，8 种）和引用类型（存地址，指向对象）。本课还在「零基础详解·基本类型、包装类与字符串」中说明：不可变：任何「修改」都返回新对象，原串不变。

### 追问 5：用 double 计算金额的主要风险是？

**参考回答**：正确答案是「二进制浮点无法精确表示十进制小数」，本课在「var 与常量」中说明：var 只用于局部变量，不降低类型安全，但可读性优先时可显式写类型。金额场景应使用 BigDecimal，并明确指定舍入模式与小数位。本课还在「零基础详解·基本类型、包装类与字符串」中说明：知道 s.toUpperCase() 为什么不改变原字符串。本课还在「零基础详解·基本类型、包装类与字符串」中说明：理解这条分界线，==、装箱、null 这些问题就都通了。

## English Overview

**Title:** Types & Strings

**Summary:** Primitives, wrappers, casting and strings.

**Category:** Java  
**Level:** 基础  
**Key terms:** int, Integer, 装箱, String, StringBuilder, var

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：基础
- 适用环境：Java 21+ / Maven 或 Gradle
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：int、Integer、装箱、String、StringBuilder、var
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Java SE API](https://docs.oracle.com/en/java/javase/) | 语言、标准库与 JVM |
| [dev.java](https://dev.java/learn/) | 现代 Java 官方教程 |

> 本课主题：基本类型与包装类、自动装箱、类型转换与 String 关键特性。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

<!-- code-practice:v1:start -->

## 代码练习（6 题）

下面题目与课程测验同源：覆盖代码输出、排错与场景判断。建议先自己写出答案，再到「测验」里核对成绩。

### 练习 1 · 代码输出

在 Java 课程“变量、类型与字符串”的集合实验里，这段代码运行后输出什么？

```java
public class Main {
    public static void main(String[] args) {
        int x = 8;
        System.out.println(x);
    }
}
```

- A. 8
- B. 7
- C. 16
- D. 9

**参考答案**：A. 8
**参考输出**：`8`

**解析**

在 Java 课程“变量、类型与字符串”的集合代码实验里，程序先完成赋值、循环或函数调用，再把结果写到标准输出，因此正确结果是 8。
判断 Java 课程“变量、类型与字符串”的代码输出时，要把“源码写了什么”和“运行时实际打印什么”分开；变量值和循环边界都会直接改变最终结果。
把 8 当作基线后，可以只改一个输入或一个边界，再观察 Java 课程“变量、类型与字符串”的输出如何变化，这就是验证掌握程度的方法。

### 练习 2 · 代码输出

在 Java 课程“变量、类型与字符串”的条件实验里，这段代码运行后输出什么？

```java
public class Main {
    public static void main(String[] args) {
        int total = 0;
        for (int i = 1; i <= 4; i++) {
            total += i;
        }
        System.out.println(total);
    }
}
```

- A. 10
- B. 9
- C. 20
- D. 11

**参考答案**：A. 10
**参考输出**：`10`

**解析**

在 Java 课程“变量、类型与字符串”的条件代码实验里，程序先完成赋值、循环或函数调用，再把结果写到标准输出，因此正确结果是 10。
判断 Java 课程“变量、类型与字符串”的代码输出时，要把“源码写了什么”和“运行时实际打印什么”分开；变量值和循环边界都会直接改变最终结果。
把 10 当作基线后，可以只改一个输入或一个边界，再观察 Java 课程“变量、类型与字符串”的输出如何变化，这就是验证掌握程度的方法。

### 练习 3 · 代码输出

在 Java 课程“变量、类型与字符串”的错误处理实验里，这段代码运行后输出什么？

```java
public class Main {
    static int doubleValue(int value) {
        return value * 2;
    }

    public static void main(String[] args) {
        System.out.println(doubleValue(4));
    }
}
```

- A. 7
- B. 8
- C. 9
- D. 16

**参考答案**：B. 8
**参考输出**：`8`

**解析**

在 Java 课程“变量、类型与字符串”的错误处理代码实验里，程序先完成赋值、循环或函数调用，再把结果写到标准输出，因此正确结果是 8。
判断 Java 课程“变量、类型与字符串”的代码输出时，要把“源码写了什么”和“运行时实际打印什么”分开；变量值和循环边界都会直接改变最终结果。
把 8 当作基线后，可以只改一个输入或一个边界，再观察 Java 课程“变量、类型与字符串”的输出如何变化，这就是验证掌握程度的方法。

### 练习 4 · 代码排错

Java 课程“变量、类型与字符串”的下面这段代码无法运行，最可能的修复是什么？

```java
public class Main {
    public static void main(String[] args) {
        int x = 8
        System.out.println(x);
    }
}
```

- A. 在 int x = 8 这一行末尾补上分号
- B. 重新安装运行时并清空所有缓存
- C. 把变量名改成另一个单词即可
- D. 把输出语句整段删除，代码就会自动修复

**参考答案**：A. 在 int x = 8 这一行末尾补上分号

**解析**

Java 课程“变量、类型与字符串”里的这段代码无法通过编译或解析，关键原因是缺少了必要语法结构，正确修复是在 int x = 8 这一行末尾补上分号。
在 Java 课程“变量、类型与字符串”中，错误信息通常会指出出错行和期望符号；先读第一条错误，再检查这一行的括号、冒号、分号或花括号。
修复后还要重新运行 Java 课程“变量、类型与字符串”的最小示例，确认输出恢复，并记录这次问题属于语法错误而不是逻辑错误。

### 练习 5 · 代码排错

Java 课程“变量、类型与字符串”的这段代码结果偏小，应该怎样修改？

```java
public class Main {
    public static void main(String[] args) {
        int total = 0;
        for (int i = 1; i < 4; i++) {
            total += i;
        }
        System.out.println(total);
    }
}
```

- A. 把循环条件 i < 4 改成 i <= 4
- B. 把累加操作改成减法操作
- C. 把循环变量从 1 改成 0，其余保持不变
- D. 把输出语句移到循环体内部

**参考答案**：A. 把循环条件 i < 4 改成 i <= 4
**修复后输出**：`10`

**解析**

Java 课程“变量、类型与字符串”里的循环边界少算了最后一项，当前输出是 6，而完整求和应为 10。
正确修复是把循环条件 i < 4 改成 i <= 4；这类错误属于边界问题，代码能运行但结果偏离，所以比语法错误更隐蔽。
验证 Java 课程“变量、类型与字符串”时至少选择首项、中间值和末尾值三个输入，比较手算结果与程序输出，才能发现类似偏差。

### 练习 6 · 概念判断

在 Java 课程“变量、类型与字符串”的学习或项目场景中，哪种做法最有助于得到可验证、可迁移的结果？

- A. 只背下「变量、类型与字符串」的结论，遇到新输入时凭感觉修改代码
- B. 跳过错误信息，直接复制另一段代码直到能运行
- C. 先围绕「int」写最小可运行示例，再用边界输入验证“变量、类型与字符串”的结果
- D. 一次改完所有变量和依赖，再统一观察是否报错

**参考答案**：C. 先围绕「int」写最小可运行示例，再用边界输入验证“变量、类型与字符串”的结果

**解析**

在 Java 课程“变量、类型与字符串”里，int不是孤立的名词，而是一组可以用输入、过程、输出和边界验证的行为。
对 Java 课程“变量、类型与字符串”来说，先写最小可运行示例，再逐步增加边界输入，能把“感觉会了”转化成可以重复的证据。
如果只背结论或一次改很多变量，出错时就无法判断是哪一步破坏了 Java 课程“变量、类型与字符串”的预期；先把变化隔离出来才容易定位。

<!-- code-practice:v1:end -->
