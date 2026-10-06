# 类、属性与对象

![C# 类型系统的对象建模方式](images/diagram_cs_oop.webp)

![类、属性与对象](images/remaining_csharp_oop.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「类、属性与对象」解决了什么问题，而不是只背术语。
- 能说清 「class」、「属性」、「init」、「record」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「C#」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：属性与访问控制、对象初始化器、record 与静态成员。

## 前置知识

- 先完成上一课《控制流与方法》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：class、属性、init。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 定义类

```csharp
public class Account
{
    private decimal _balance;
    public Account(string owner, decimal balance)
    {
        Owner = owner;
        _balance = balance;
    }
    public string Owner { get; }
    public decimal Balance => _balance;
    public void Deposit(decimal amount)
    {
        if (amount <= 0) throw new ArgumentOutOfRangeException(nameof(amount));
        _balance += amount;
    }
    public static Account CreateDefault(string owner) => new(owner, 0);
}
```

属性是字段的受控访问器，常见写法：`{ get; set; }`、`{ get; init; }`（仅初始化时赋值）、`{ get; private set; }`。

## 对象初始化

```csharp
var account = new Account("小明", 100);
account.Deposit(50);
Console.WriteLine(account.Balance);
var person = new Person { Name = "tom", Age = 18 };
```

## record：不可变数据模型

```csharp
public record Person(string Name, int Age)
{
    public string Display => $"{Name} ({Age})";
}
var a = new Person("tom", 18);
var b = a with { Age = 19 };
Console.WriteLine(a == new Person("tom", 18));
```

record 自动生成构造器、`Equals`、`GetHashCode`、`ToString` 与 `with`，适合 DTO 与值对象。

## 静态成员与常量

```csharp
public class Config
{
    public const string Version = "1.0";
    public static readonly DateTime StartTime = DateTime.UtcNow;
    public static int Count { get; private set; }
}
```

`const` 必须是编译期常量且隐式静态；`static readonly` 可在运行时初始化一次。

## 本课小结
C# 面向对象的核心：**属性暴露状态、方法表达行为、record 表达不可变数据**，不要直接公开字段。


## 类成员速查

| 成员 | 写法 | 说明 |
| --- | --- | --- |
| 字段 | `private readonly int _id;` | 私有、只读，`_camelCase` 命名 |
| 自动属性 | `public string Name { get; set; }` | 最常用 |
| 只读属性 | `public string Id { get; }` | 构造器内赋值 |
| 初始化属性 | `public string Name { get; init; }` | 对象初始化后不可改 |
| 计算属性 | `public string Full => $"{First} {Last}";` | 没有存储 |
| 静态成员 | `public static int Count { get; }` | 属于类型 |
| 常量 | `public const double Pi = 3.14;` | 编译期内联 |
| 静态只读 | `public static readonly DateTime Start = DateTime.UtcNow;` | 运行期赋值 |
| 索引器 | `public T this[int i] => _items[i];` | 支持下标访问 |
| 事件 | `public event EventHandler? Changed;` | 发布订阅 |

```csharp
// 不可变数据对象：init + 必填 + 校验
public sealed record User
{
    public required string Id { get; init; }
    public required string Name { get; init; }
    public int Age { get; init; }

    public User WithAge(int age) => this with { Age = age };
}

var user = new User { Id = "u1", Name = "小明" };
var older = user.WithAge(19);      // 生成新对象，原对象不变

// 属性访问器中的校验
public sealed class Account
{
    private decimal _balance;

    public decimal Balance
    {
        get => _balance;
        private set => _balance = value >= 0
            ? value
            : throw new ArgumentOutOfRangeException(nameof(value));
    }
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 public 字段 | 无法校验、无法数据绑定 | 用属性封装 |
| `const` 存运行期值 | 编译错误 | 用 `static readonly` |
| record 里定义可变的 `set` | 失去不可变优势 | 用 `init` + `with` |
| 属性里做耗时 IO | 访问像字段但很慢 | 改成显式方法 |
| `required` 成员未赋值 | 编译错误 | 初始化时全部赋值 |
| 忘记实现 `IDisposable` | 资源泄漏 | 实现 `Dispose`，或改用 `using` |
| 事件订阅后不取消 | 内存泄漏 | 在合适时机 `-=` 取消订阅 |
| 静态字段存可变状态 | 并发问题、实例互相影响 | 用实例字段或注入的服务 |
| 重写 `Equals` 不重写 `GetHashCode` | 集合行为异常 | 两者成对重写，或用 record |
| 用 `sealed` 修饰可继承类 | 无法继承 | 明确设计意图，需要扩展时去掉 |

## 自测清单

- [ ] 用属性而不是公开字段。
- [ ] 不可变数据用 record + `init` + `with`。
- [ ] 知道 `const` 与 `static readonly` 的区别。
- [ ] 实现 `IDisposable` 并用 `using` 释放资源。
- [ ] 事件订阅与取消成对出现。


## 零基础详解：类、属性与封装

### 一句话说清它是什么

C# 的类把数据和行为打包，属性（property）是它最优雅的封装手段：
对外看起来像字段，内部其实可以带校验、只读或计算逻辑。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 类 | 图纸 | 定义有哪些字段与方法 |
| 对象 | 实物 | `new` 出来的实例 |
| 字段 | 内部零件 | 通常 private |
| 属性 | 带门禁的窗口 | 读写可控，可加校验 |
| 方法 | 能做的事 | 对外提供的操作 |
| record | 一次性信息卡 | 天生带比较与打印 |

### 从字段到属性的三种写法

```csharp
public class Account
{
    private decimal _balance;                         // 1. 字段：内部存储
    public decimal Balance => _balance;               // 2. 只读计算属性
    public string Owner { get; private set; } = "";   // 3. 对外只读、类内可写

    public Account(string owner, decimal initial)
    {
        Owner = owner;
        Deposit(initial);
    }

    public void Deposit(decimal amount)
    {
        if (amount <= 0) throw new ArgumentOutOfRangeException(nameof(amount));
        _balance += amount;
    }
}
```

| 写法 | 含义 |
| --- | --- |
| `{ get; set; }` | 可读可写 |
| `{ get; private set; }` | 外部只能读，类内可写 |
| `=> _balance` | 只读计算属性，没有存储 |
| 带 `init` | 只在对象初始化时赋值 |

### 带校验的属性

```csharp
public class User
{
    private string _email = "";

    public required string Email
    {
        get => _email;
        set
        {
            if (string.IsNullOrWhiteSpace(value) || !value.Contains('@'))
                throw new ArgumentException("邮箱格式不正确", nameof(value));
            _email = value.Trim().ToLowerInvariant();
        }
    }

    public string Display { get; init; } = "";
}
```

`required` 让编译器强制调用方初始化该属性，`init` 让属性只在创建时能赋值。

### record：数据搬运的首选

```csharp
public record User(string Name, int Age)
{
    public bool IsAdult => Age >= 18;
}

var a = new User("小明", 18);
var b = a with { Age = 19 };                     // 非破坏性修改
Console.WriteLine(a == new User("小明", 18));    // True：按值比较
Console.WriteLine(b);                            // User { Name = 小明, Age = 19 }
```

| 类型 | 比较方式 | 适用场景 |
| --- | --- | --- |
| `class` | 默认引用比较 | 有身份与生命周期的实体 |
| `record` | 按值比较 | DTO、消息、配置、不可变数据 |
| `struct` | 按值比较 | 小且短命的数据 |

### 静态成员与常量

```csharp
public static class MathTools
{
    public const double Epsilon = 1e-9;                        // 编译期常量
    public static readonly DateTime Start = DateTime.UtcNow;    // 运行时只读

    public static bool NearlyEqual(double a, double b)
        => Math.Abs(a - b) < Epsilon;
}
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 字段公开 | 外部随意改，校验被绕过 | 用属性封装 |
| 在属性 getter 里做重活 | 调试时反复触发 | 用方法或缓存 |
| 忘了 `required` | 对象可能缺关键字段 | 关键字段加 `required` |
| 用 `==` 比较普通 class | 比的是引用 | 需要值语义就用 `record` |
| 在 struct 里放大对象 | 频繁复制，性能差 | 改 class 或 record |
| 静态可变状态 | 并发问题难查 | 尽量用只读静态 |
| 不校验构造参数 | 错误延后暴露 | 尽早校验并明确异常类型 |
| 属性与字段同名 | 语法冲突 | 字段加下划线前缀 |

### 手把手练习：订单与金额校验

```csharp
public record OrderLine(string Name, decimal UnitPrice, int Quantity)
{
    public decimal Subtotal => UnitPrice * Quantity;
}

public class Order
{
    private readonly List<OrderLine> _lines = new();

    public required string Customer { get; init; }
    public IReadOnlyList<OrderLine> Lines => _lines;
    public decimal Total => _lines.Sum(l => l.Subtotal);

    public void Add(string name, decimal price, int quantity)
    {
        if (price < 0) throw new ArgumentOutOfRangeException(nameof(price));
        if (quantity <= 0) throw new ArgumentOutOfRangeException(nameof(quantity));
        _lines.Add(new OrderLine(name, price, quantity));
    }
}

var order = new Order { Customer = "小明" };
order.Add("键盘", 199m, 1);
order.Add("鼠标", 89.5m, 2);

Console.WriteLine($"{order.Customer} 合计 {order.Total:C}");
foreach (var line in order.Lines)
{
    Console.WriteLine($"  {line.Name} x{line.Quantity} = {line.Subtotal:C}");
}
```

### 学完自测

- [ ] 能说出字段与属性的区别。
- [ ] 知道 `private set` 与 `init` 分别限制了什么。
- [ ] 能说出 class 与 record 在比较语义上的差别。
- [ ] 知道 `required` 帮你避免什么问题。
- [ ] 能写一个带校验的只读属性。

## 动手练习


> 本课练习重点：围绕「class、属性、init」完成复述、实验和交付，每个结果都要能被别人检查。

先建最小控制台程序，再补类型、异步和异常路径，最后用 dotnet test 验证。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「类、属性与对象」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「属性」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

写一个控制台小程序，补一个正例、一个边界值和一个异常路径。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「class」和「属性」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 实践任务

本节围绕“类、属性与对象”安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

合上教程，用 5 句话说明“类、属性与对象”解决什么问题、输入是什么、输出是什么、失败时会怎样、与相邻概念的边界在哪里。画一张流程图或状态图，把每个节点标注成“输入 / 处理 / 输出 / 失败路径”之一。

**验收标准**：图里至少有 5 个节点和 1 条失败路径；每个节点都能在正文中找到依据。

### 任务 2：做一次对比实验

从正文里选两个差异最小的方案，列成 4 列表格：方案、前提、代价、适用边界。然后只改变一个条件（数据规模、并发度、精度或资源上限），记录结果变化。

**验收标准**：表格里两个方案的结论不能完全一样；写下“在什么条件下应该换方案”。

### 任务 3：迁移到自己的场景

把“类、属性与对象”的核心方法用到你熟悉的一个真实场景，写出一份 300 字以内的实施记录：目标、步骤、验证方式、仍然不确定的问题。

**验收标准**：至少有一个可复现的命令、代码片段或数据样例；结论能被别人独立检查。


## 故障现场

这一节把“类、属性与对象”最常见的失败方式还原成现场记录，练习时按“症状 → 复现 → 定位 → 修复 → 预防”的顺序排查。

### 现场 1：“类、属性与对象”的 class 常规用例通过，但边界用例失败

**症状**：在“类、属性与对象”的练习或生产场景里出现““类、属性与对象”的 class 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发““类、属性与对象”的 class 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“class 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：为“类、属性与对象”补一条空值或极值用例，把前置条件写成断言，并让失败信息直接指出是哪个输入越界

**预防**：把““类、属性与对象”的 class 常规用例通过，但边界用例失败”写成一条自动化用例，并在“类、属性与对象”的验收清单里保留对应检查项。


### 现场 2：“类、属性与对象”的 属性 结果在两次运行之间不一致

**症状**：在“类、属性与对象”的练习或生产场景里出现““类、属性与对象”的 属性 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发““类、属性与对象”的 属性 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“属性 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：固定“类、属性与对象”使用的版本与随机种子，记录两次运行的完整输入和输出，再逐项消除非确定性来源

**预防**：把““类、属性与对象”的 属性 结果在两次运行之间不一致”写成一条自动化用例，并在“类、属性与对象”的验收清单里保留对应检查项。


### 现场 3：“类、属性与对象”的验证只在开发机通过

**症状**：在“类、属性与对象”的练习或生产场景里出现““类、属性与对象”的验证只在开发机通过”。

**复现**：准备一组最小输入，只保留触发““类、属性与对象”的验证只在开发机通过”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，class 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：把“类、属性与对象”的运行环境、输入样本和预期输出写成清单，并在另一套环境复跑同一条命令

**预防**：把““类、属性与对象”的验证只在开发机通过”写成一条自动化用例，并在“类、属性与对象”的验收清单里保留对应检查项。



## 版本与时效

这一节记录“类、属性与对象”涉及的版本基线与升级检查点，避免把某个版本的默认行为当成永久结论。

- .NET 10 是当前 LTS 主线，C# 版本随 SDK 一起演进
- 主构造函数、集合表达式、模式匹配与 AOT/裁剪是升级重点
- 升级前检查 NuGet 依赖、序列化行为与运行时标识
- 官方说明：https://learn.microsoft.com/dotnet/core/whats-new/

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改一个版本变量，记录编译、测试、性能与产物体积的变化。
- 重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。
- 升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：属性使用 { get; init; } 表示？

- **正确判断**：只能在对象初始化时赋值
- **判断依据**：正确答案是「只能在对象初始化时赋值」，本课在「定义类」中说明：属性是字段的受控访问器，常见写法：{ get; set; }、{ get; init; }（仅初始化时赋值）、{ get; private set; }。init 访问器让属性在对象初始化后不可变，兼顾对象初始化器语法与不可变性。本课还在「零基础详解：类、属性与封装」中说明：required 让编译器强制调用方初始化该属性，init 让属性只在创建时能赋值。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 2：record 的 with 表达式作用是？

- **正确判断**：生成一个修改了部分属性的新对象
- **判断依据**：正确答案是「生成一个修改了部分属性的新对象」，本课在「本课小结」中说明：C# 面向对象的核心：属性暴露状态、方法表达行为、record 表达不可变数据，不要直接公开字段。with 执行非破坏性修改，原对象保持不变，这是值语义的重要体现。本课还在「record：不可变数据模型」中说明：record 自动生成构造器、Equals、GetHashCode、ToString 与 with，适合 DTO 与值对象。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：const 与 static readonly 的区别是？

- **正确判断**：const 是编译期常量
- **判断依据**：正确答案是「const 是编译期常量」，本课在「静态成员与常量」中说明：static readonly 可在运行时初始化一次。const 在编译时替换到调用处，static readonly 在运行时初始化一次，可用于 DateTime.Now 等。本课还在「零基础详解：类、属性与封装」中说明：能说出 class 与 record 在比较语义上的差别。本课还在「本课小结」中说明：C# 面向对象的核心：属性暴露状态、方法表达行为、record 表达不可变数据，不要直接公开字段。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：属性（property）相比 public 字段的优势是？

- **正确判断**：可在 get/set 中加校验与计算逻辑，并且能被接口约束、支持数据绑定
- **判断依据**：正确答案是「可在 get/set 中加校验与计算逻辑，并且能被接口约束、支持数据绑定」，本课在「零基础详解：类、属性与封装」中说明：对外看起来像字段，内部其实可以带校验、只读或计算逻辑。自动属性 { get; set; } 是语法糖，需要时再展开成带逻辑的完整属性。本课还在「定义类」中说明：属性是字段的受控访问器，常见写法：{ get; set; }、{ get; init; }（仅初始化时赋值）、{ get; private set; }。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：sealed 关键字的作用是？

- **正确判断**：修饰类时禁止被继承
- **判断依据**：正确答案是「修饰类时禁止被继承」，本课在「零基础详解：类、属性与封装」中说明：知道 private set 与 init 分别限制了什么。sealed 可避免继承带来的行为不确定性，string 就是 sealed 类。本课还在「零基础详解：类、属性与封装」中说明：能说出 class 与 record 在比较语义上的差别。本课还在「record：不可变数据模型」中说明：record 自动生成构造器、Equals、GetHashCode、ToString 与 with，适合 DTO 与值对象。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 6：补全代码：「类、属性与对象」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `____ = balance;`

- **正确判断**：_balance
- **判断依据**：正确答案是「_balance」，本课在「零基础详解：类、属性与封装」中说明：C# 的类把数据和行为打包，属性（property）是它最优雅的封装手段。本课还在「零基础详解：类、属性与封装」中说明：required 让编译器强制调用方初始化该属性，init 让属性只在创建时能赋值。
- **迁移检查**：不看题干，用自己的话补全这句话，再与标准答案对照。

### 补充自测（2 题）

1. 围绕“类、属性与对象”中的 class、属性、init，下列哪两项是本课强调的实践判断？
2. 下面这段 C# 代码复现了“类、属性与对象”中 class、属性、init 相关的一个常见故障，哪一项最准确地解释了问题？

这些题按“先定位概念、再排除边界错误、最后核对答案”的顺序作答；每题解析都给出了判断依据。


## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「属性使用 { get; init; } 表示？」的判断依据。
- [ ] 不看解析，能说出「record 的 with 表达式作用是？」的判断依据。
- [ ] 不看解析，能说出「const 与 static readonly 的区别是？」的判断依据。
- [ ] 不看解析，能说出「属性（property）相比 public 字段的优势是？」的判断依据。
- [ ] 不看解析，能说出「sealed 关键字的作用是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「类、属性与对象」示例中，下面这行代码缺少哪个关键字或函数名？请填入 …」的判断依据。
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
| `{ get; set; }` | 属性是字段的受控访问器，常见写法：`{ get; set; }`、`{ get; init; }`（仅初始化时赋值）、`{ get; private set; }`。 |
| `{ get; init; }` | 属性是字段的受控访问器，常见写法：`{ get; set; }`、`{ get; init; }`（仅初始化时赋值）、`{ get; private set; }`。 |
| `{ get; private set; }` | 属性是字段的受控访问器，常见写法：`{ get; set; }`、`{ get; init; }`（仅初始化时赋值）、`{ get; private set; }`。 |
| `Equals` | record 自动生成构造器、`Equals`、`GetHashCode`、`ToString` 与 `with`，适合 DTO 与值对象。 |
| `GetHashCode` | record 自动生成构造器、`Equals`、`GetHashCode`、`ToString` 与 `with`，适合 DTO 与值对象。 |
| `ToString` | record 自动生成构造器、`Equals`、`GetHashCode`、`ToString` 与 `with`，适合 DTO 与值对象。 |
| `with` | record 自动生成构造器、`Equals`、`GetHashCode`、`ToString` 与 `with`，适合 DTO 与值对象。 |
| `const` | `const` 必须是编译期常量且隐式静态；`static readonly` 可在运行时初始化一次。 |
| `static readonly` | `const` 必须是编译期常量且隐式静态；`static readonly` 可在运行时初始化一次。 |
| `private readonly int _id;` | \| 字段 \| `private readonly int _id;` \| 私有、只读，`_camelCase` 命名 \| |
| `_camelCase` | \| 字段 \| `private readonly int _id;` \| 私有、只读，`_camelCase` 命名 \| |
| `public string Name { get; set; }` | \| 自动属性 \| `public string Name { get; set; }` \| 最常用 \| |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：属性使用 { get; init; } 表示？

**参考回答**：正确答案是「只能在对象初始化时赋值」，本课在「定义类」中说明：属性是字段的受控访问器，常见写法：{ get; set; }、{ get; init; }（仅初始化时赋值）、{ get; private set; }。init 访问器让属性在对象初始化后不可变，兼顾对象初始化器语法与不可变性。本课还在「零基础详解·类、属性与封装」中说明：required 让编译器强制调用方初始化该属性，init 让属性只在创建时能赋值。

### 追问 2：record 的 with 表达式作用是？

**参考回答**：正确答案是「生成一个修改了部分属性的新对象」，本课在「本课小结」中说明：C# 面向对象的核心：属性暴露状态、方法表达行为、record 表达不可变数据，不要直接公开字段。with 执行非破坏性修改，原对象保持不变，这是值语义的重要体现。本课还在「record·不可变数据模型」中说明：record 自动生成构造器、Equals、GetHashCode、ToString 与 with，适合 DTO 与值对象。

### 追问 3：const 与 static readonly 的区别是？

**参考回答**：正确答案是「const 是编译期常量」，本课在「静态成员与常量」中说明：static readonly 可在运行时初始化一次。const 在编译时替换到调用处，static readonly 在运行时初始化一次，可用于 DateTime.Now 等。本课还在「零基础详解·类、属性与封装」中说明：能说出 class 与 record 在比较语义上的差别。本课还在「本课小结」中说明：C# 面向对象的核心：属性暴露状态、方法表达行为、record 表达不可变数据，不要直接公开字段。

### 追问 4：属性（property）相比 public 字段的优势是？

**参考回答**：正确答案是「可在 get/set 中加校验与计算逻辑，并且能被接口约束、支持数据绑定」，本课在「零基础详解·类、属性与封装」中说明：对外看起来像字段，内部其实可以带校验、只读或计算逻辑。自动属性 { get; set; } 是语法糖，需要时再展开成带逻辑的完整属性。本课还在「定义类」中说明：属性是字段的受控访问器，常见写法：{ get; set; }、{ get; init; }（仅初始化时赋值）、{ get; private set; }。

### 追问 5：sealed 关键字的作用是？

**参考回答**：正确答案是「修饰类时禁止被继承」，本课在「零基础详解·类、属性与封装」中说明：知道 private set 与 init 分别限制了什么。sealed 可避免继承带来的行为不确定性，string 就是 sealed 类。本课还在「零基础详解·类、属性与封装」中说明：能说出 class 与 record 在比较语义上的差别。本课还在「record·不可变数据模型」中说明：record 自动生成构造器、Equals、GetHashCode、ToString 与 with，适合 DTO 与值对象。

## English Overview

**Title:** Classes & Objects

**Summary:** Properties, initializers, records and statics.

**Category:** C#  
**Level:** 进阶  
**Key terms:** class, 属性, init, record, with, static

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：.NET 9 / C# 13
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：class、属性、init、record、with、static
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [C# 官方指南](https://learn.microsoft.com/dotnet/csharp/) | 语言、异步与模式匹配 |
| [.NET 文档](https://learn.microsoft.com/dotnet/) | 运行时、GC 与发布 |

> 本课主题：属性与访问控制、对象初始化器、record 与静态成员。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
