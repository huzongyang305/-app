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
