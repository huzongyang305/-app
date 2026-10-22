## 类与对象速查

| 修饰符 | 本类 | 同包 | 子类 | 其他 |
| --- | --- | --- | --- | --- |
| `private` | 可见 | 不可见 | 不可见 | 不可见 |
| 默认（无） | 可见 | 可见 | 不可见 | 不可见 |
| `protected` | 可见 | 可见 | 可见 | 不可见 |
| `public` | 可见 | 可见 | 可见 | 可见 |

| 关键字 | 作用 |
| --- | --- |
| `static` | 属于类，所有实例共享 |
| `final` | 类不可继承 / 方法不可重写 / 字段不可重新赋值 |
| `this` | 当前实例引用，构造器重载用 `this(...)` |
| `record` | 不可变数据载体，自动生成 getter、`equals`、`hashCode`、`toString` |
| `enum` | 类型安全枚举，可带字段与方法 |
| `instanceof` | 类型判断，可配合模式变量 |
| `sealed` | 限制可继承的子类集合（Java 17+） |

```java
// 不可变值对象：字段 final、无 setter、构造器校验
public final class Money {
    private final long cents;

    public Money(long cents) {
        if (cents < 0) throw new IllegalArgumentException("金额不能为负");
        this.cents = cents;
    }

    public long cents() { return cents; }

    public Money plus(Money other) {
        return new Money(this.cents + other.cents);   // 返回新对象
    }

    @Override
    public boolean equals(Object o) {
        return o instanceof Money m && m.cents == cents;
    }

    @Override
    public int hashCode() { return Long.hashCode(cents); }
}

// record 版本：等价但更简洁
public record Point(int x, int y) {
    public Point {
        if (x < 0) throw new IllegalArgumentException("x 不能为负");
    }
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 字段公开可改 | 状态被任意修改 | 私有字段 + 构造器校验，必要时返回副本 |
| 只重写 `equals` 不重写 `hashCode` | `HashSet` / `HashMap` 行为异常 | 两者必须成对重写，或用 `record` |
| 可变对象作 `HashMap` 键 | 改字段后查不到 | 用不可变对象作键 |
| `return` 内部可变集合 | 外部能改内部状态 | 返回 `List.copyOf(...)` 或不可变视图 |
| 构造器里调用可被重写的方法 | 子类字段尚未初始化 | 构造器只做本类初始化 |
| `static` 字段存状态 | 多实例互相影响、并发不安全 | 用实例字段或无状态设计 |
| 用 `enum` 存可变的共享状态 | 状态被全局修改 | `enum` 只放常量与不可变数据 |
| `final` 修饰可变对象后直接改内容 | 内容仍然变了 | `final` 只锁定引用，需要真正不可变要深拷贝 |
| `toString` 暴露敏感信息 | 日志泄漏 | 输出必要字段并脱敏 |
| 用 `instanceof` 堆分支 | 新增类型要改多处 | 用多态抽象行为 |

## 自测清单

- [ ] 能画出四种访问修饰符的可见范围。
- [ ] 会用 `record` 表达不可变数据。
- [ ] 重写 `equals` 时同步重写 `hashCode`。
- [ ] 不对外暴露内部可变集合。
- [ ] 构造器只做本类初始化，不调用可重写方法。
