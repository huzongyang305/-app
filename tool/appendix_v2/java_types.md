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
