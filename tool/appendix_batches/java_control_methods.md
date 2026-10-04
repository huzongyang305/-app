## 控制流速查

| 结构 | 写法 | 注意 |
| --- | --- | --- |
| `if / else if / else` | 条件分支 | 条件必须是 `boolean` |
| `switch` 语句 | 传统分支 | 别忘 `break`，否则穿透 |
| `switch` 表达式 | `case X -> value;` | Java 14+，无穿透且可赋值 |
| `for` | 计次循环 | 注意边界 `i < n` |
| 增强 `for` | `for (String s : list)` | 遍历中不能改集合结构 |
| `while` / `do...while` | 条件循环 | `do...while` 至少执行一次 |
| 标签 + `break` | `break outer;` | 跳出多层循环 |
| `continue` | 跳过本次 | 配合条件过滤 |
| `try / catch / finally` | 异常处理 | 见异常章节 |

```java
// switch 表达式：直接返回值，编译期检查是否覆盖所有分支
String level = switch (score / 10) {
    case 10, 9 -> "优秀";
    case 8 -> "良好";
    case 7 -> "中等";
    default -> "需努力";
};

// 需要多行逻辑时用 yield 返回值
int fee = switch (type) {
    case "vip" -> 0;
    case "normal" -> {
        int base = 10;
        yield base * 2;
    }
    default -> throw new IllegalArgumentException("未知类型：" + type);
};
```

## 方法速查

| 概念 | 规则 |
| --- | --- |
| 重载（Overload） | 同名不同参数列表，返回值不参与判断 |
| 重写（Override） | 子类重新实现父类方法，签名一致 |
| 参数传递 | Java 只有值传递，对象传的是引用的副本 |
| 可变参数 | `int... nums` 必须是最后一个参数 |
| 默认值 | Java 不支持默认参数，用重载或建造者替代 |
| 返回值 | 所有分支都要有返回，或用 `throw` |
| `static` 方法 | 属于类，不能用实例成员 |
| `final` 参数 | 方法内不能重新赋值 |

```java
// 用重载替代默认参数
public void log(String msg) {
    log(msg, false);
}

public void log(String msg, boolean verbose) {
    System.out.println(verbose ? "[DEBUG] " + msg : msg);
}

// 可变参数 + 边界校验
public int sum(int first, int... rest) {
    int total = first;
    for (int n : rest) {
        total += n;
    }
    return total;
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `switch` 忘记 `break` | 穿透执行后续分支 | 用 `->` 表达式或补 `break` |
| 遍历 List 时 `list.remove(x)` | `ConcurrentModificationException` | 用 `removeIf` 或迭代器 |
| 用 `==` 比较字符串 | 结果不可靠 | 用 `equals` |
| 方法写了返回值却有分支没 `return` | 编译错误 | 所有路径都要返回或抛异常 |
| 重载只看返回值不同 | 编译错误：方法重复定义 | 重载必须参数列表不同 |
| 可变参数前面再加普通参数顺序错 | 编译错误 | 可变参数必须在最后 |
| `for (int i = 0; i <= list.size(); i++)` | `IndexOutOfBoundsException` | 用 `<` 或增强 `for` |
| 循环里修改 `i` 造成跳步 | 漏处理元素 | 让循环变量只由一个地方推进 |
| 用浮点数做循环判断 | 死循环或次数不对 | 用整数计数 |
| `while (true)` 没有退出条件 | 程序卡死 | 明确退出条件或 `break` |

## 自测清单

- [ ] 会用 `switch` 表达式和 `yield`。
- [ ] 知道重载与重写的区别。
- [ ] 明白 Java 只有值传递。
- [ ] 可变参数放在参数列表最后。
- [ ] 遍历集合时不在循环里结构性修改。
