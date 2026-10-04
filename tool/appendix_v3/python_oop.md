## 零基础详解：类与对象，把数据和行为打包

### 一句话说清它是什么

类是一张**模板**，对象是按模板造出来的**实例**。
类的价值是把「一堆相关的数据」和「操作这些数据的方法」放在一起，让代码有边界。

### 用生活比喻理解

| 概念 | 比喻 | 代码 |
| --- | --- | --- |
| 类 | 图纸 | `class Dog:` |
| 实例 | 按图纸造出来的狗 | `d = Dog("旺财")` |
| 属性 | 这条狗的信息 | `d.name` |
| 方法 | 这条狗会做的事 | `d.bark()` |
| `self` | 「这条狗自己」 | 方法第一个参数 |
| 继承 | 在图纸基础上改 | `class Puppy(Dog):` |

### 逐行拆解第一个类

```python
class Dog:
    species = "犬科"                 # 类属性：所有实例共享

    def __init__(self, name: str):   # 构造方法，创建实例时自动调用
        self.name = name             # 实例属性：每条狗各自一份
        self._energy = 100           # 下划线开头表示「内部使用」

    def bark(self) -> str:           # 实例方法，第一个参数是 self
        self._energy -= 5
        return f"{self.name}：汪！剩余体力 {self._energy}"

    def __str__(self) -> str:        # 打印对象时显示的内容
        return f"Dog({self.name})"


d = Dog("旺财")
print(d.bark())
print(d)          # Dog(旺财)，因为定义了 __str__
```

| 语法点 | 说明 |
| --- | --- |
| `__init__` | 构造方法，`Dog("旺财")` 时自动执行 |
| `self` | 指向当前实例，调用时不用手动传 |
| 类属性 vs 实例属性 | 共享配置写类属性，各实例独有数据写实例属性 |
| `__str__` | 让对象有可读的打印效果 |

### 三个「下划线」的含义

| 写法 | 名称 | 含义 |
| --- | --- | --- |
| `name` | 公开 | 谁都能访问 |
| `_energy` | 约定内部 | 「请别直接改」，但语法上仍可访问 |
| `__secret` | 名称改写 | 会被改名为 `_Dog__secret`，用于避免子类冲突 |
| `__str__` | 魔术方法 | 由 Python 在特定场景自动调用 |

Python 没有强制私有，靠约定和自觉。

### 继承与多态

```python
class Animal:
    def __init__(self, name: str):
        self.name = name

    def speak(self) -> str:
        raise NotImplementedError       # 子类必须实现


class Cat(Animal):
    def speak(self) -> str:
        return f"{self.name}：喵"


class Dog(Animal):
    def speak(self) -> str:
        return f"{self.name}：汪"


for animal in (Cat("咪咪"), Dog("旺财")):
    print(animal.speak())               # 同一个调用，不同结果：多态
```

写继承前先问一句：**子类真的是「是一种」父类吗？** 不是的话，用组合（把对象当属性）更合适。

### 常用魔术方法速查

| 方法 | 触发时机 | 例子 |
| --- | --- | --- |
| `__init__` | 创建实例 | `Dog("旺财")` |
| `__str__` | `str(obj)`、`print(obj)` | 给人看的文本 |
| `__repr__` | 调试、列表里显示 | `Dog(name='旺财')` |
| `__eq__` | `==` 比较 | 按业务键判断相等 |
| `__len__` | `len(obj)` | 自定义长度 |
| `__iter__` | `for x in obj` | 让对象可遍历 |

### 用 `@property` 做只读与校验

```python
class Account:
    def __init__(self, balance: float = 0):
        self._balance = balance

    @property
    def balance(self) -> float:        # 像属性一样读取
        return self._balance

    def deposit(self, amount: float) -> None:
        if amount <= 0:
            raise ValueError("金额必须为正")
        self._balance += amount
```

### 新手最容易踩的七个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 忘了写 `self` | `TypeError: takes 1 positional argument but 2 were given` | 实例方法第一个参数必须是 `self` |
| 用可变对象作类属性 | 所有实例共享同一个列表 | 在 `__init__` 里创建实例属性 |
| 直接改 `_` 属性 | 绕过校验，数据不一致 | 提供方法或 `@property` |
| 继承层次过深 | 改一处牵动全身 | 优先组合，继承不超过两层 |
| 忘了调用 `super()` | 父类初始化没执行 | `super().__init__(...)` |
| 用 `is` 比较对象值 | 结果不符预期 | 实现 `__eq__` 并用 `==` |
| 把类当函数用 | 忘了加括号 | `Dog("旺财")` 才是实例 |

### 手把手练习：购物车

```python
from dataclasses import dataclass


@dataclass
class Item:
    name: str
    price: float
    quantity: int = 1

    @property
    def subtotal(self) -> float:
        return round(self.price * self.quantity, 2)


class Cart:
    def __init__(self) -> None:
        self.items: list[Item] = []

    def add(self, item: Item) -> None:
        self.items.append(item)

    @property
    def total(self) -> float:
        return round(sum(i.subtotal for i in self.items), 2)

    def __len__(self) -> int:
        return len(self.items)

    def __str__(self) -> str:
        return f"购物车({len(self)} 件，合计 {self.total} 元)"


cart = Cart()
cart.add(Item("键盘", 199.0))
cart.add(Item("鼠标", 89.5, 2))
print(cart)
```

### 学完自测

- [ ] 能说出类与实例的区别。
- [ ] 知道类属性与实例属性在什么时候会「串数据」。
- [ ] 能解释 `self` 是什么、为什么不用手动传。
- [ ] 能写一个带 `@property` 的只读属性。
- [ ] 能判断一个场景该用继承还是组合。
