## 魔术方法速查

| 魔术方法 | 触发时机 | 常见用途 |
| --- | --- | --- |
| `__init__` | 创建实例后 | 初始化属性 |
| `__repr__` | `repr()`、调试器、容器展示 | 给开发者看的精确描述 |
| `__str__` | `print()`、`str()` | 给用户看的友好文本 |
| `__eq__` | `==` | 定义相等语义（记得同时定义 `__hash__`） |
| `__hash__` | `hash()`、放进 `set`/`dict` 键 | 不可变对象才适合哈希 |
| `__lt__` 等 | `<`、`>`、排序 | 配合 `functools.total_ordering` 省事 |
| `__len__` | `len(obj)` | 容器类语义 |
| `__getitem__` | `obj[key]` | 支持下标与切片 |
| `__iter__` | `for x in obj` | 定义可迭代行为 |
| `__enter__` / `__exit__` | `with obj:` | 上下文管理（自动释放资源） |
| `__call__` | `obj()` | 让实例像函数一样被调用 |

## 面向对象速查

| 概念 | 写法 | 说明 |
| --- | --- | --- |
| 实例属性 | `self.name = name` | 每个实例独立 |
| 类属性 | 类中直接赋值 | 所有实例共享，改它要谨慎 |
| 私有约定 | `self._x` / `self.__x` | 单下划线是约定，双下划线会改名 |
| 类方法 | `@classmethod` + `cls` | 常用于替代构造器 `from_xxx` |
| 静态方法 | `@staticmethod` | 逻辑相关但不需要实例或类 |
| 属性 | `@property` / `@x.setter` | 访问像字段，内部可做校验 |
| 继承 | `class Dog(Animal):` | 用 `super().__init__(...)` 初始化父类 |
| 抽象基类 | `class Base(ABC):` + `@abstractmethod` | 强制子类实现 |
| 数据类 | `@dataclass` | 自动生成 `__init__`、`__repr__`、`__eq__` |
| 槽位 | `__slots__` | 限制属性、减少内存占用 |

```python
from dataclasses import dataclass, field

@dataclass(frozen=True)          # 不可变，可安全当字典键
class Point:
    x: int
    y: int
    tags: tuple[str, ...] = field(default_factory=tuple)

print(Point(1, 2) == Point(1, 2))   # True，自动生成 __eq__
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 忘记写 `self` 参数 | `TypeError: f() takes 0 positional arguments but 1 was given` | 实例方法第一个参数必须是 `self` |
| 在类里写 `def __init__(self, name)` 却用 `Dog()` 调用 | `TypeError: missing 1 required positional argument` | 构造函数需要参数，或给默认值 |
| 类属性用可变对象 | 所有实例共享，互相污染 | 可变默认值放 `__init__`，或 `field(default_factory=list)` |
| 只用 `__eq__` 不写 `__hash__` | 类变成不可哈希，无法放进 `set` | 定义了 `__eq__` 后 `__hash__` 会被置空，需要显式实现 |
| 直接访问 `self.__x` | `AttributeError` | 双下划线会被改名成 `_类名__x`，这是刻意的保护 |
| 用 `isinstance` 判断后硬编码子类行为 | 新增子类要改多处 | 用多态重写方法替代类型判断 |
| 多重继承随意 `super()` | 初始化顺序混乱 | 明确 MRO（`Class.__mro__`），协作式继承统一用 `super()` |
| `@property` 里写耗时 IO | 访问属性变慢且难察觉 | 属性应是廉价操作，耗时逻辑用显式方法 |
| 忘记在 `__exit__` 返回 False | 误吞异常 | 正常释放资源时返回 `None` / `False` |

## 自测清单

- [ ] 能说清 `self`、`cls`、`@staticmethod` 的区别。
- [ ] 会写 `__repr__` 方便调试，并知道它与 `__str__` 的区别。
- [ ] 知道定义了 `__eq__` 后要一并考虑 `__hash__`。
- [ ] 用 `@dataclass` 减少样板代码，需要不可变时用 `frozen=True`。
- [ ] 用 `super().__init__(...)` 而不是直接写父类名。
