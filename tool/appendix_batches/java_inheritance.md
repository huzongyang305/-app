## 抽象类与接口速查

| 维度 | 抽象类 | 接口 |
| --- | --- | --- |
| 关键字 | `abstract class` | `interface` |
| 继承数量 | 只能继承一个 | 可以实现多个 |
| 构造器 | 有 | 无 |
| 字段 | 任意字段 | 只能是 `public static final` 常量 |
| 方法实现 | 可以有 | 可以有 `default` / `static` 方法 |
| 适用 | 共享状态与部分实现 | 定义能力契约 |

多态速查：

| 概念 | 说明 |
| --- | --- |
| 向上转型 | 父类引用指向子类对象，安全 |
| 向下转型 | 需要显式转换，转换失败抛 `ClassCastException` |
| 运行时多态 | 调用被重写的方法执行子类实现 |
| `@Override` | 编译期检查是否真的重写 |
| 动态分派 | 按实际对象类型选择方法 |
| 静态方法 | 不参与多态，按引用类型调用 |

```java
public interface PaymentMethod {
    void pay(long cents);

    default String describe() {
        return "支付方式：" + name();
    }

    static PaymentMethod of(String type) {
        return switch (type) {
            case "alipay" -> new Alipay();
            case "card" -> new Card();
            default -> throw new IllegalArgumentException("不支持：" + type);
        };
    }
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 忘记 `@Override` | 拼错方法名后变成新方法，不报错 | 重写方法一律加注解 |
| 用 `==` 比较对象内容 | 结果不符合预期 | 重写 `equals` 或用 `Objects.equals` |
| 父类构造器没有无参构造，子类未调用 | 编译错误 | 子类构造器显式 `super(...)` |
| 向下转型不判断 | `ClassCastException` | 先 `instanceof` 再转换 |
| 在父类构造器里调用被重写方法 | 子类状态未初始化 | 构造器只调用 `private` / `final` 方法 |
| 接口里放可变状态 | 编译不允许或语义混乱 | 状态放实现类，接口只定义行为 |
| 用继承复用工具代码 | 层级僵化 | 优先组合，必要时才继承 |
| `default` 方法冲突 | 编译错误：类继承了不相关的方法 | 在实现类中显式重写解决冲突 |
| 静态方法想被重写 | 编译不报错但行为不符合预期 | 静态方法按类型调用，不参与多态 |
| 把父类字段设为 `protected` | 子类强耦合 | 用私有字段 + `protected` 方法 |

## 自测清单

- [ ] 能说出抽象类与接口的取舍标准。
- [ ] 重写方法一定加 `@Override`。
- [ ] 向下转型前先用 `instanceof` 判断。
- [ ] 优先用组合而不是继承复用代码。
- [ ] 构造器中不调用可被重写的方法。
