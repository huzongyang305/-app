## 零基础详解：分支、循环与方法

### 一句话说清它是什么

方法把逻辑打包并命名，分支处理不同情况，循环重复执行。
Java 的方法**必须写在类里面**，这是它和 C 系语言最直观的差别。

### 分支：`if` 与 `switch` 的分工

| 场景 | 推荐 | 原因 |
| --- | --- | --- |
| 范围判断（分数段、金额区间） | `if / else if` | 天然支持范围与组合条件 |
| 对固定值分流（枚举、状态码） | `switch` | 结构清晰、编译器能查漏 |
| 少数几个分支 | 三元运算符 `? :` | 一行写完，但别嵌套 |

```java
// 传统 switch
switch (day) {
    case 1: System.out.println("周一"); break;
    case 2: System.out.println("周二"); break;
    default: System.out.println("其它");
}

// 新式 switch 表达式：不会穿透，还能直接赋值
String type = switch (day) {
    case 1, 2, 3, 4, 5 -> "工作日";
    case 6, 7 -> "周末";
    default -> throw new IllegalArgumentException("非法日期");
};
```

### 循环三兄弟

| 循环 | 适合场景 | 注意 |
| --- | --- | --- |
| `for` | 次数明确、遍历数组 | 最常用 |
| 增强 `for` | 遍历集合/数组，不需要下标 | 不能边遍历边删元素 |
| `while` | 条件驱动，可能一次都不执行 | 别忘更新条件变量 |
| `do...while` | 至少执行一次 | 例如重试输入 |

```java
for (int i = 0; i < 3; i++) System.out.println(i);

int[] nums = {1, 2, 3};
for (int n : nums) System.out.println(n);

int n = 0;
while (n < 3) { System.out.println(n); n++; }
```

### 方法签名：每一部分都有用

```java
public static int add(int a, int b) { return a + b; }
//  |      |      |    |        |
//  |      |      |    |        └─ 参数列表
//  |      |      |    └────────── 返回类型
//  |      |      └─────────────── 方法名
//  |      └────────────────────── static：属于类，不需要 new
//  └───────────────────────────── 访问修饰符
```

### 方法重载：同名不同参

```java
int add(int a, int b) { return a + b; }
double add(double a, double b) { return a + b; }
int add(int a, int b, int c) { return a + b + c; }
```

判定依据只有**方法名 + 参数列表**；只改返回类型不算重载，编译不过。

### Java 只有值传递

这是最容易被绕晕的点：**Java 传的永远是值的副本**，只不过引用类型复制的是「地址」。

```java
void change(int x) { x = 99; }              // 外面不变
void change(int[] arr) { arr[0] = 99; }     // 外面会变，因为改的是堆里同一个数组
```

记忆方法：**改副本本身无效，改副本指向的对象有效。**

### 可变参数

```java
int sum(int... nums) {          // 调用时可以传 0 个或多个
    int total = 0;
    for (int n : nums) total += n;
    return total;
}
sum();                // 0
sum(1, 2, 3);         // 6
```

可变参数必须放在参数列表最后，一个方法只能有一个。

### 新手最容易踩的七个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| `if (a = b)` | 编译报错或逻辑错 | 比较写 `==` |
| 循环里删集合元素 | `ConcurrentModificationException` | 用 `Iterator.remove()` 或 `removeIf` |
| 增强 `for` 里改数组 | 改了副本没效果 | 需要下标时用普通 `for` |
| 递归无终止条件 | `StackOverflowError` | 先写出口 |
| 方法名相同但只有返回类型不同 | 编译错误 | 改参数列表 |
| 方法太长 | 难测试难复用 | 按单一职责拆分 |
| 忽略返回值 | 以为对象被改了 | 接收返回值或改用可变对象 |

### 手把手练习：数字猜谜 + 素数统计

```java
public class Demo {
    static boolean isPrime(int n) {
        if (n < 2) return false;
        for (int d = 2; d * d <= n; d++) {
            if (n % d == 0) return false;
        }
        return true;
    }

    static int countPrimes(int limit) {
        int count = 0;
        for (int i = 2; i <= limit; i++) {
            if (isPrime(i)) count++;
        }
        return count;
    }

    public static void main(String[] args) {
        System.out.println("100 以内素数有 " + countPrimes(100) + " 个");
    }
}
```

### 学完自测

- [ ] 能说出新式 `switch` 表达式相比传统写法的两个好处。
- [ ] 能解释为什么增强 `for` 里删除元素会抛异常。
- [ ] 能说清「Java 只有值传递」这句话的含义。
- [ ] 能写出一个用可变参数求和的静态方法。
- [ ] 知道方法重载的判定依据是什么。
