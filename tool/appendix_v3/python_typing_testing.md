## 零基础详解：类型注解与自动化测试

### 一句话说清它是什么

类型注解是**写给工具和同事看的说明书**，运行时不强制，但能让编辑器提前报错；
自动化测试则是**写给未来的自己**的安全网，改代码时立刻知道有没有弄坏别的东西。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 类型注解 | 货物标签 | 标明里面装什么，便于检查 |
| mypy / pyright | 质检员 | 静态检查类型是否自相矛盾 |
| dataclass | 标准表格模板 | 少写一堆样板代码 |
| pytest | 自动化验收员 | 一条命令跑完全部断言 |
| fixture | 公共准备工作 | 复用测试前置条件 |

### 类型注解速查

```python
from collections.abc import Iterable, Sequence
from typing import Optional, Union

def greet(name: str, times: int = 1) -> str:
    return f"你好，{name}！" * times

def total(nums: Sequence[float]) -> float:
    return sum(nums)

def find_user(uid: int) -> Optional[dict[str, str]]:    # 可能返回 None
    return None

Number = Union[int, float]        # Python 3.10+ 可写 int | float
def twice(n: Number) -> Number:
    return n * 2

def names(users: Iterable[dict[str, str]]) -> list[str]:
    return [u["name"] for u in users]
```

| 写法 | 含义 |
| --- | --- |
| `list[str]` | 字符串列表 |
| `dict[str, int]` | 键字符串、值整数的字典 |
| `Optional[X]` 或 `X \| None` | 可能是 X 或 None |
| `Sequence[X]` | 只读序列，列表元组都行 |
| `Callable[[int], str]` | 输入 int、返回 str 的函数 |
| `TypeVar("T")` | 泛型占位 |

### dataclass：数据类少写样板

```python
from dataclasses import dataclass, field


@dataclass(frozen=True)                 # 不可变，可作字典键
class Point:
    x: float
    y: float


@dataclass
class Order:
    customer: str
    items: list[str] = field(default_factory=list)   # 可变默认值必须这样写
    paid: bool = False

    @property
    def item_count(self) -> int:
        return len(self.items)


print(Point(1, 2) == Point(1, 2))       # True，自动实现按值比较
print(Order("小明").item_count)         # 0
```

### pytest 的四件必备

```python
# test_order.py
import pytest
from myapp import Order


@pytest.fixture
def order() -> Order:
    return Order("小明", ["键盘", "鼠标"])


def test_item_count(order: Order) -> None:
    assert order.item_count == 2


@pytest.mark.parametrize(
    ("items", "expected"),
    [([], 0), (["a"], 1), (["a", "b"], 2)],
)
def test_counts(items: list[str], expected: int) -> None:
    assert Order("小红", items).item_count == expected


def test_invalid_customer() -> None:
    with pytest.raises(ValueError):
        Order("", [])
```

| 概念 | 作用 |
| --- | --- |
| `assert` | 断言，失败即测试失败 |
| `fixture` | 复用的前置数据或环境 |
| `parametrize` | 一份逻辑跑多组数据 |
| `raises` | 断言会抛指定异常 |
| `-k` / `-m` | 按名字或标记筛选用例 |

常用命令：

```bash
pytest -q                       # 安静模式
pytest -k "order"               # 只跑名字含 order 的用例
pytest --cov=myapp --cov-report=term-missing   # 覆盖率
mypy src                        # 类型检查
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 注解与实现不一致 | 工具报错 | 让 mypy 在 CI 里跑 |
| 忘记 `from __future__ import annotations` | 老版本语法受限 | 3.10+ 可直接用 `X \| None` |
| dataclass 用可变默认值 | `ValueError` | 用 `field(default_factory=list)` |
| 用 `Any` 图省事 | 类型检查失效 | 用 `object` 加收窄 |
| 测试依赖执行顺序 | 单独跑就失败 | 每个用例自带准备与清理 |
| 只测正常路径 | 异常分支无人管 | 补 `raises` 与边界用例 |
| 断言太弱 | 出错也通过 | 断言具体值而不是「不为 None」 |
| 用 `print` 调试测试 | 输出难读 | 用 `pytest -vv` 或断点 |

### 手把手练习：给购物车写测试

```python
# cart.py
class Cart:
    def __init__(self) -> None:
        self._items: dict[str, float] = {}

    def add(self, name: str, price: float) -> None:
        if price < 0:
            raise ValueError("价格不能为负")
        self._items[name] = price

    def total(self) -> float:
        return round(sum(self._items.values()), 2)


# test_cart.py
import pytest
from cart import Cart


def test_empty_total() -> None:
    assert Cart().total() == 0


def test_add_and_total() -> None:
    cart = Cart()
    cart.add("键盘", 199.0)
    cart.add("鼠标", 89.5)
    assert cart.total() == 288.5


@pytest.mark.parametrize("bad_price", [-1, -0.01])
def test_negative_price_raises(bad_price: float) -> None:
    with pytest.raises(ValueError, match="不能为负"):
        Cart().add("测试", bad_price)
```

### 学完自测

- [ ] 能说出类型注解为什么在运行时不做检查。
- [ ] 知道 `Optional[X]` 的含义。
- [ ] 能写出一个 `@dataclass` 并处理可变默认值。
- [ ] 能说出 fixture 与 parametrize 的用途。
- [ ] 知道为什么测试不能依赖执行顺序。
