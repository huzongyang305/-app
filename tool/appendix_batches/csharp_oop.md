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
