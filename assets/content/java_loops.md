# Java 循环入门

> 内容更新时间：2026-10-06 · 学习阶段：入门 · 预计用时：55 分钟

![Java 三种循环与流程控制](images/diagram_java_loops.webp)

![Java 循环入门](images/remaining_java_loops.webp)

## 本节知识框架

上一课你学会了让程序「做选择」——条件判断。但生活中很多事不是做一次就够的：跑操要跑 10 圈，背单词要把一本词典从头翻到尾，数钱要从第一张数到最后一张。这些重复性的操作，用**循环**来做最合适。

Java 提供了三种循环方式：`for` 循环适合「已知次数」的场景，`while` 循环适合「做到某个条件满足为止」的场景，`do-while` 循环则是「至少做一次再说」。本课重点掌握前两种。

**学完这一课，你会**：
- 熟练使用 `for` 循环遍历数字序列并做累加
- 用 `while` 循环处理「不确定次数，靠条件退出」的场景
- 知道增强 for 循环（for-each）怎么遍历数组和集合
- 避开「死循环」「循环里拼字符串」这些常见陷阱

**先修**：《Java 条件判断》。**后续**：《Java 方法入门》。

### 复习清单

- [ ] 能不看正文写出 `for (int i = 0; i < n; i++)` 的结构并说出每部分含义。
- [ ] 能解释 `while (true)` 循环为什么需要 `break` 退出。
- [ ] 能用增强 for 循环遍历一个 `int[]` 数组并求和。

## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| `for 循环` | 把初始化、条件、更新写在一行，适合次数确定的循环。 |
| `while 循环` | 条件为真就执行，适合次数取决于运行状态的循环。 |
| `增强 for 循环` | for (int value : array) 的简写，依次访问每个元素。 |
| `break` | 立即退出当前循环，跳到循环体后面。 |
| `continue` | 跳过本次循环剩余部分，进入下一次迭代。 |
| `StringBuilder` | 可变的字符序列，循环中拼接字符串应使用它。 |
| `区间开闭` | 描述循环覆盖下标时用 `[start, end)` 或 `[start, end]`，写清才能防止差一。 |
| `迭代器` | 集合提供的游标对象，增强 for 与显式删除都靠它推进。 |
| `嵌套循环` | 一个循环体内再放一个循环，总迭代次数是两层次数相乘。 |
| `循环不变量外提` | 把每轮结果都相同的一次运算或对象创建搬到循环外，能显著降低开销。 |

## 原理与运行机制

### for 循环：三件事写在一行

`for` 循环把三件事压缩到一行里：

```java
for (int i = 1; i <= 5; i++) {
    // 循环体
}
```

执行顺序：初始化 → 判断条件 → 执行循环体 → 更新 → 再判断条件 → ...直到条件为 false。

最经典的用法——从 1 累加到 5：

```java
int total = 0;
for (int i = 1; i <= 5; i++) {
    total += i;
}
System.out.println("total=" + total);  // total=15
```

### while 循环：条件为真就一直做

```java
int count = 1;
while (count <= 5) {
    System.out.println("第 " + count + " 次");
    count++;
}
```

`while` 先判断条件，条件为 true 才执行循环体。如果一开始条件就是 false，循环体一次都不执行。

### 增强 for 循环（for-each）

遍历数组或集合时，如果不需要索引，用增强 for 最简洁：

```java
int[] numbers = {10, 20, 30, 40, 50};
int sum = 0;
for (int value : numbers) {
    sum += value;
}
System.out.println("总和：" + sum);  // 150
```

### break 和 continue

- `break`：立即退出整个循环
- `continue`：跳过本次循环的剩余部分，进入下一轮迭代

### while (true) 与死循环

`while (true)` 创建一个永远为真的循环，必须靠 `break` 退出。如果忘记写退出条件，程序会永远卡在这个循环里——这就是「死循环」。必须存在可到达的退出条件，否则线程会一直占用。

### 三件套的执行顺序

把 `for (初始化; 条件; 更新) { 循环体 }` 展开，实际发生的顺序是：

```text
初始化（只做 1 次）
  ↓
条件（每轮开始前） → false → 退出
  ↓ true
循环体
  ↓
更新（每轮结束后）
  ↑ 回到"条件"
```

很多人误以为"更新在条件之前"，其实顺序反过来；这一点决定了 `for (int i = 0; i < n; i++)` 里循环体最后一轮看到的 `i` 是 `n-1`，退出时 `i` 已经是 `n`。理解了这个顺序，"循环里少跑一次/多跑一次"的问题几乎都能自己推导出来。

### 增强 for 循环的两种底层

`for (int v : numbers)` 看起来像语法糖，但 Java 对数组和集合会编译成不同代码：

- **数组**：编译器展开为 `for (int i = 0; i < arr.length; i++) { int v = arr[i]; ... }`，直接走索引，速度等同普通 `for`。
- **集合**：编译器展开为 `for (Iterator<T> it = list.iterator(); it.hasNext(); ) { T v = it.next(); ... }`，遍历过程走迭代器协议。

两种展开方式解释了为什么增强 for 在 `LinkedList` 上是 O(n)，而用 `list.get(i)` 索引遍历却是 O(n^2)：前者每一步 `it.next()` 只是把游标往后挪一格，后者每次都要从头点数到第 i 个。写循环前先问一句"这个容器到底给了我什么遍历协议"，比事后拿 profiler 追因更省事。

### while (true) 与状态机式循环

当循环退出条件不止一个——比如"读到 EOF 或读到用户输入 quit 都退出"——把外层写成 `while (true)`，内部用若干 `break` 表达退出分支，比把三四个条件拼成一个巨大的布尔表达式清晰：

```java
java.util.Scanner sc = new java.util.Scanner(System.in);
int count = 0;
while (true) {
    if (!sc.hasNextLine()) break;                 // 输入结束
    String line = sc.nextLine();
    if (line.equals("quit")) break;               // 用户主动退出
    if (line.isEmpty()) continue;                 // 忽略空行，进入下一轮
    count++;
}
System.out.println("lines=" + count);
```

这段骨架里每一条退出路径都能到达：正常累计、`hasNextLine()` 返回 false、`"quit"` 命中；`continue` 只吞掉空行不会导致死循环。用 `while (true)` 之前一定要在纸面上先列清楚所有 `break`，否则线程会一直占用 CPU 或把 `main` 卡在这里永远不返回。

### 嵌套循环与 continue/break 的作用范围

`break` 和 `continue` 只影响**最内层**的循环。想一次跳出多层，可以给外层循环加标签：

```java
outer:
for (int i = 0; i < matrix.length; i++) {
    for (int j = 0; j < matrix[i].length; j++) {
        if (matrix[i][j] < 0) break outer;   // 找到第一个负数就整体退出
    }
}
```

入门阶段更推荐"给内层用一个布尔变量做标记，外层条件里判断这个标记"的写法——标签语法在项目里少见，读代码的人容易一时想不起它跳到哪一层。

## 典型应用场景

### 场景一：累加求和

```java
public class Main {
    public static void main(String[] args) {
        int total = 0;
        for (int i = 1; i <= 5; i++) {
            total += i;
        }
        System.out.println("total=" + total);
    }
}
```

### 场景二：遍历数组求平均

```java
public class Main {
    public static void main(String[] args) {
        int[] scores = {85, 92, 78, 63, 95};
        int sum = 0;
        for (int score : scores) {
            sum += score;
        }
        double average = (double) sum / scores.length;
        System.out.printf("平均分：%.1f%n", average);
    }
}
```

### 场景三：用 while 找第一个满足条件的数

```java
public class Main {
    public static void main(String[] args) {
        int n = 1;
        while (n * n < 100) {
            n++;
        }
        System.out.println("第一个平方 >= 100 的数：" + n);
    }
}
```

### 场景四：把列表拼成 CSV 行

这是"循环里拼接字符串"的正面写法——`StringBuilder` 在循环外创建，只在循环里 `append`：

```java
public class Main {
    public static void main(String[] args) {
        int[] scores = {85, 92, 78, 63, 95};
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < scores.length; i++) {
            if (i > 0) sb.append(',');
            sb.append(scores[i]);
        }
        System.out.println(sb);
    }
}
```

如果这里写成 `String row = ""; row += scores[i];`，每轮都会新建一个 `String` 对象并把之前内容拷贝过去，n 个数就是 O(n^2) 次拷贝；`StringBuilder` 内部用可扩容字符数组，摊销下来是 O(n)。这一条正是本课"字符串拼接陷阱"的具体表现。

### 场景五：找出第一个不合格项并停手

`while` 与 `break` 配合，比在 `for` 条件里塞三个判断更易读：

```java
int[] temps = {36, 37, 38, 39, 41, 37, 36};
int firstBad = -1;
for (int i = 0; i < temps.length; i++) {
    if (temps[i] > 40) { firstBad = i; break; }   // 命中就立刻退出
}
if (firstBad >= 0) System.out.println("第一个超标下标：" + firstBad);
else System.out.println("全部正常");
```

两种结局都算覆盖了：找到（`firstBad >= 0`）与找不到（`firstBad == -1`），空数组也自然走"全部正常"这一支——因为 `i < temps.length` 在 0 长度时直接为假。这种"正常 + 边界 + 失败"三条路径都跑一遍的习惯，是验证循环结论时最省事的清单。

### 场景六：读取一批数并统计极值

```java
java.util.Scanner sc = new java.util.Scanner(System.in);
int n = sc.hasNextInt() ? sc.nextInt() : 0;
int max = Integer.MIN_VALUE, min = Integer.MAX_VALUE;
for (int i = 0; i < n; i++) {
    int v = sc.nextInt();
    if (v > max) max = v;
    if (v < min) min = v;
}
if (n > 0) System.out.println("max=" + max + ", min=" + min);
else System.out.println("没有输入");
```

初始值用 `Integer.MIN_VALUE / MAX_VALUE` 而不是 `0`——否则当所有数都是负数时 `max` 会停在 0，得出错误结论。这一条与"极值初始值"直接挂钩，是循环累计最容易漏的隐性边界。

## 代码/协议/SQL 示例

### 最小可验证示例

```java
public class Main {
    public static void main(String[] args) {
        int total = 0;
        for (int i = 1; i <= 5; i++) {
            total += i;
        }
        System.out.println("total=" + total);
    }
}
```

预期输出：

```text
total=15
```

### 循环中正确拼接字符串

```java
public class Main {
    public static void main(String[] args) {
        StringBuilder sb = new StringBuilder();
        for (int i = 1; i <= 5; i++) {
            if (i > 1) sb.append(", ");
            sb.append("item").append(i);
        }
        System.out.println(sb.toString());
    }
}
```

### 死循环与安全退出

下面这段是典型的"少写一句 nextLine() 导致死循环"的反例：

```java
java.util.Scanner sc = new java.util.Scanner(System.in);
String line;
while (!(line = sc.nextLine()).isEmpty()) {
    // 处理 line
}
```

逻辑本身没错，但如果换成 `sc.hasNextLine()` 判断、`nextLine()` 忘了推进，游标停在原地条件永远成立。安全写法是把推进语句显式写进循环体首行，一眼看得见"每轮消费一点输入"：

```java
while (sc.hasNextLine()) {
    String line = sc.nextLine();   // 每轮消费一行
    if (line.isEmpty()) break;
    // 处理 line
}
```

### 边遍历边删除的正确写法

增强 for 里直接 `list.remove(x)` 会抛 `ConcurrentModificationException`。三种正确姿势：

```java
import java.util.*;

List<Integer> list = new ArrayList<>(Arrays.asList(1, 2, 3, 4, 5, 6));

// 姿势一：Iterator.remove（在遍历过程中就地删）
Iterator<Integer> it = list.iterator();
while (it.hasNext()) {
    if (it.next() % 2 == 0) it.remove();
}

// 姿势二：removeIf（Java 8+，语义最贴近意图）
list.removeIf(x -> x % 3 == 0);

// 姿势三：倒序索引删除（不会打乱未访问的下标）
for (int i = list.size() - 1; i >= 0; i--) {
    if (list.get(i) > 4) list.remove(i);
}
```

三种写法各有适用场景：需要边遍历边做别的动作时用姿势一；只按一个条件筛掉元素时用姿势二最简洁；需要在删除同时读相邻元素时用姿势三，但一定记得**倒序**，否则正序删除会让下标错位、跳过元素。

### 三档边界自测清单

写完循环至少跑这三组输入：

```java
// 求 int[] 里正数个数
static int countPositive(int[] arr) {
    int c = 0;
    for (int v : arr) if (v > 0) c++;
    return c;
}

// 三档：
//   空数组 new int[0]              → 期望 0，验证循环一次都不进
//   单元素 {-1}                    → 期望 0，验证分支不吞元素
//   大数组 1_000_000 个 1          → 期望 1_000_000，验证累加器不会溢出
```

在同一份代码上固定 JDK 版本、固定 `-Xint`/`-Xmixed` 之类的运行模式各跑一次，两次结果的差值才是能引用的性能结论；单次跑出来的数字不足以支撑"这段循环比那段快"的断言。

## 时间/空间复杂度或性能分析

循环是程序性能的关键区域：

- **时间复杂度**：一层 for 从 1 到 n 是 O(n)，两层嵌套是 O(n^2)。
- **字符串拼接陷阱**：在循环里用 `+` 拼接字符串，每次都会创建新的 String 对象。应该用 `StringBuilder`。
- **增强 for vs 普通 for**：遍历 `LinkedList` 时增强 for 是 O(n)，而用索引访问是 O(n^2)。

测量方法：固定输入跑一遍记录基线，再提高规模复测，两次结果的差值才是结论依据。

### String 拼接为什么是 O(n^2)

`String` 在 Java 里不可变：`s = s + x` 每一步都会新建一个 `String` 并把 `s` 的旧内容整段拷进去。n 轮下来累计拷贝 `1 + 2 + ... + n = n(n+1)/2` 次字符，是 O(n^2) 时间；同时给 GC 制造 n 个短命对象。改法两条：

- 循环里累积文本一律用 `StringBuilder`，它在循环外 `new` 一次，内部数组按需扩容，摊销是 O(n)。
- 如果只是简单拼接定长片段、又在意可读性，`String.join(",", parts)` 或 `Stream.collect(Collectors.joining())` 内部也走 `StringBuilder`。

### 索引遍历 vs 迭代器遍历的性能差

对 `ArrayList` 而言 `get(i)` 与 `it.next()` 都是 O(1)，两种循环量级相同。对 `LinkedList` 就不同：`get(i)` 是 O(i)，从 0 到 n 全遍历就是 O(n^2)；`it.next()` 每次都只挪一个节点，是 O(n)。规则：**接口是 `List` 且实现可能是 `LinkedList` 时，别用索引遍历**；需要索引语义就先把 `LinkedList` 拷成 `ArrayList`。

### 循环不变量外提

把每轮结果相同的表达式或对象创建挪到循环外，是入门阶段最见效的微调：

```java
// 反例：每轮都调 size()、每轮都 new Pattern
for (int i = 0; i < list.size(); i++) {
    if (Pattern.matches("\\d+", list.get(i))) { /* ... */ }
}

// 正例：不变量提到外面
Pattern p = Pattern.compile("\\d+");
int n = list.size();
for (int i = 0; i < n; i++) {
    if (p.matcher(list.get(i)).matches()) { /* ... */ }
}
```

JIT 通常会自动做一部分外提，但对 `size()` 这种可能修改对象的方法它不敢保证无副作用，就留给你自己判断。看到循环条件或循环体里有"看起来每轮结果都一样"的调用，就顺手挪出来，代码可读性同时受益。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 循环里拼接字符串 | 产生大量临时对象。 | 改用 StringBuilder 并在循环外创建。 |
| 边遍历边删除集合元素 | 抛出并发修改异常。 | 用迭代器删除，或先收集再统一处理。 |
| 下标边界差一 | 越界异常或漏掉元素。 | 用增强 for，或写清区间开闭。 |
| `while (true)` 里没有可达的 `break` | 线程一直占用，程序挂住。 | 明确列出所有退出分支，必要时给循环加计数上限。 |
| 极值初始值取 0 | 全负数组时 max 停在 0，结论错。 | 用 `Integer.MIN_VALUE`/`MAX_VALUE`，或用首个元素初始化。 |
| 空数组/空集合未测 | 循环一次都没跑，累加器保持初值，下游代码误以为"存在数据"。 | 边界三档（0/1/最大）都跑一遍，把结论写进注释。 |

### 误区一：`for (int i = 0; i <= n; i++)` 多了一次

从 0 到 n（含），一共执行 n+1 次。如果本意是执行 n 次，条件应该是 `i < n`。

### 误区二：循环变量在循环外使用

for 循环变量 `i` 的作用域只在循环内，出了循环就不能再用。

### 误区三：在循环里修改集合

增强 for 循环中不能直接修改集合，需要用 `Iterator` 的 `remove` 方法或 `removeIf`。

### 误区四：循环外还在用循环变量

`for (int i = 0; i < n; i++) { ... }` 里的 `i` 只在循环体内可见，出了花括号引用它会直接编译不通过。真想在退出后看最后一次的 `i`，就把声明提到循环外：

```java
int i;
for (i = 0; i < n; i++) {
    if (arr[i] < 0) break;
}
System.out.println("停在 i=" + i);
```

这种写法可读性差，一般只在"扫描到第一个不满足条件的下标"时临时使用；能改成把结果直接赋给一个 `firstBadIndex` 变量的，就别让循环变量漏到外面。

### 误区五：在循环里改动集合大小

```java
// 反例：条件里读 size()，循环体里 add()，可能永远不满足终止
List<Integer> list = new ArrayList<>();
list.add(1);
for (int i = 0; i < list.size(); i++) {
    if (list.get(i) < 5) list.add(list.get(i) + 1);  // size 也在长，可能加到手软
}
```

如果确实需要"遍历过程中派生新元素"，先 `for (int x : new ArrayList<>(list)) { ... }` 拷贝一份再往里塞；或者干脆把新增元素放到另一个列表，遍历结束后统一合并。这一条与"下标边界差一"是同一类问题的两个面：**别在循环运行期间动控制循环的那个变量或容器**。

## 与其他知识点的关系

- **先修**：《Java 条件判断》。本课默认你已经会用 if/else 做分支判断。
- **后续**：《Java 方法入门》会把循环逻辑封装到方法里复用。
- **术语衔接**：本课定义的 `for 循环`、`while 循环`、`增强 for 循环`、`break`、`continue`、`StringBuilder` 会在后续课程反复出现。

### 概念地图

```text
for 循环（初始化; 条件; 更新）
  └─ while 循环（条件为真就执行）
       └─ 增强 for 循环（遍历每个元素）
            └─ break（退出循环）
                 └─ continue（跳过本轮）
                      └─ StringBuilder（循环中拼接字符串的正确方式）
```

### 循环与集合框架

循环是"手工版遍历"，《Java 集合框架》会把这些遍历交给迭代器、`forEach` 以及 `Iterator.remove`。学完本课的三条陷阱——`while (true)` 缺退出、循环里拼字符串、边遍历边删——就能理解集合 API 为什么长成那个样子：`Iterator` 把游标推进和读取拆成两步，`removeIf` 把删除协议封在实现里，`Spliterator` 更进一步支持并行分段。

### 循环与 Stream 的分工

`for` 强调"每一步都自己做"，Stream 强调"声明做什么、让框架去做"。同一个统计平均：`for` 版是 `for (int v : scores) sum += v;` 再除长度；Stream 版是 `Arrays.stream(scores).average().orElse(0.0)`。入门阶段先把 `for`/`while` 写熟，再回过头看 Stream，才知道它替你省了哪些坑（比如自动处理空数组返回 `OptionalDouble.empty()`）。

### 循环与方法抽取

循环体一旦超过十几行，就该像下一课《Java 方法入门》那样抽成方法：外层循环只负责"遍历"，方法负责"对每个元素做什么"。抽取后参数是输入、返回值是输出，循环不变式可以搬到方法签名上，可读性和可测性都会明显提升。

## 自测题与参考答案

### 自测 1

**问**：`for` 循环的三个部分分别是什么？

**答**：初始化（设置循环变量初值）、条件（判断是否继续循环）、更新（每轮结束后修改变量）。把初始化、条件、更新写在一行，适合次数确定的循环。

### 自测 2

**问**：增强 for 循环适合什么场景？

**答**：依次访问数组或集合中的每个元素。不需要索引、不需要修改元素时最方便。

### 自测 3

**问**：`while (true)` 循环有什么风险？

**答**：必须存在可到达的退出条件，否则线程会一直占用。忘记写 `break` 就会造成死循环。

### 自测 4

**问**：循环里拼接字符串为什么推荐用 `StringBuilder`？

**答**：String 不可变，每次 `+` 都会创建新对象。循环里拼接会产生大量临时对象。改用 StringBuilder 并在循环外创建，性能更好。

### 自测 5

**问**：`for (int i = 1; i <= 5; i++)` 循环体执行几次？

**答**：5 次。i 从 1 到 5，每轮 i 加 1，当 i 变成 6 时条件为 false，循环结束。

## 考点精讲

`Java 循环入门` 的题库有 5 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：下面这段 `java` 代码来自 `Java 循环入门`。课程主线是用 for、while 遍历和累计数据。代码与 `for 循环` 有关。哪一项是代码里真实出现的内容？
- **正确项**：出现字面量 `total=`
- **判断依据**：这道题落在术语 `for 循环` 上：把初始化、条件、更新写在一行，适合次数确定的循环。复习时把 `for 循环` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 2：第 2 题

- **题目**：Java 的增强 for 循环 for (int value : numbers) 适合什么场景？
- **正确项**：依次访问数组或集合中的每个元素
- **判断依据**：这道题落在术语 `for 循环` 上：把初始化、条件、更新写在一行，适合次数确定的循环。复习时把 `for 循环` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 3：第 3 题

- - **题目**：围绕“Java 循环入门”中的 Java 循环入门、Java、入门练习，下列哪两项是本课强调的实践判断？
- **正确项**：学习 Java 循环入门 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 Java 时要固定版本并覆盖边界输入，结论才可复现
- **判断依据**：这道题检验本课主问题：用 for、while 遍历和累计数据。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 4：第 4 题

- **题目**：while (true) 循环中最需要注意的风险是？
- **正确项**：必须存在可到达的退出条件，否则线程会一直占用
- **判断依据**：这道题检验本课主问题：用 for、while 遍历和累计数据。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 5：第 5 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `用 for、while 遍历和累计数据。`，这段说明是：`____`：条件为真就执行，适合次数取决于运行状态的循环。空缺处应填哪个术语？
- **正确项**：while 循环
- **判断依据**：这道题落在术语 `while 循环` 上：条件为真就执行，适合次数取决于运行状态的循环。复习时把 `while 循环` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `for 循环` | 把初始化、条件、更新写在一行，适合次数确定的循环。 |
| `while 循环` | 条件为真就执行，适合次数取决于运行状态的循环。 |
| `增强 for 循环` | for (int value : array) 的简写，依次访问每个元素。 |
| `break` | 立即退出当前循环，跳到循环体后面。 |
| `continue` | 跳过本次循环剩余部分，进入下一次迭代。 |
| `StringBuilder` | 可变的字符序列，循环中拼接字符串应使用它。 |
| `区间开闭` | 用 `[start, end)` 或 `[start, end]` 写清循环覆盖哪些下标。 |
| `迭代器` | 集合的游标对象，`hasNext()/next()` 是它的两把基本工具。 |
| `ConcurrentModificationException` | 遍历期间直接改动集合会抛出的运行时异常。 |
| `循环不变量外提` | 把每轮结果相同的调用或对象创建搬到循环外。 |
| `嵌套循环` | 循环里再放循环，总次数是两层相乘。 |

## 参考资料与复核

- 最后复核：2026-10-04
- [Oracle Java Tutorials - For Loop](https://docs.oracle.com/javase/tutorial/java/nutsandbolts/for.html)
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践

| 参考资料 | 本课用途 |
| --- | --- |
| [dev.java 学习](https://dev.java/learn/) | 现代 Java 官方教程 |
| [Java 集合框架教程](https://docs.oracle.com/javase/tutorial/collections/) | 集合遍历与迭代器 |
| [Java SE API](https://docs.oracle.com/en/java/javase/21/docs/api/) | StringBuilder 等标准库 API |

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：入门
- 适用环境：Java 21+ / Maven 或 Gradle；本课聚焦 Java 循环入门。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Java 循环入门、Java、入门练习
