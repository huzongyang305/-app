# 类型注解与测试

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：55 分钟

![类型注解与 pytest 测试流程](images/diagram_py_typing.webp)

![类型注解与测试](images/remaining_python_typing_testing.webp)

## 本节知识框架

**课程定位**：所属分类为「Python」，课程主题为「类型注解与测试」，学习阶段为「进阶」，建议用时 55 分钟。

**本课要解决的主问题**：类型注解、mypy / ruff，以及用 pytest 写可维护的测试。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「类型注解与测试」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「类型注解与测试」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「类型注解」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《模块、包与虚拟环境》

**学习位置**：本课位于《模块、包与虚拟环境》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《Python 容器进阶、拷贝与默认参数》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释类型注解与测试解决了什么问题，而不是只背术语。
- 能说清 「类型注解」、「mypy」、「pytest」、「ruff」 之间的关系，并分别举出一个例子。
- 能把 类型注解 放回「类型注解与测试」的知识体系，说明它和 mypy 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：类型注解、mypy / ruff，以及用 pytest 写可维护的测试。

**教材衔接：前置知识**

- 先完成上一课《模块、包与虚拟环境》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「模块、包与虚拟环境」，或确认自己能独立跑通正文里的 Callable 示例。
- 开始前先复习：类型注解、mypy、pytest。
- 看不懂就直接缩小例子：只保留 类型注解 相关的两行输入，跑通后再加回其余部分。

**教材衔接：本课小结**

类型注解 + mypy 让错误在运行前暴露，pytest 让改动有回归保障。这两件事是 Python 项目从脚本走向工程的分界线。

## 核心概念定义

> 阅读约定：本课先给「类型注解与测试」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| typing | 复杂类型用 typing 模块： | 仅在「类型注解与测试」明确给出的输入、版本与资源条件下成立。 |
| pyproject.toml | 建议在 pyproject.toml 中统一配置： | 仅在「类型注解与测试」明确给出的输入、版本与资源条件下成立。 |
| unittest | 标准库的 unittest 也能用，语法更啰嗦但无需第三方依赖；doctest 则可以直接运行文档字符串里的示例。 | 仅在「类型注解与测试」明确给出的输入、版本与资源条件下成立。 |
| 类型注解 | 类型注解是写给工具和同事看的说明书，运行时不强制，但能让编辑器提前报错。 | 仅在「类型注解与测试」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「类型注解与测试」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

**教材衔接：为什么要类型注解**

Python 是动态类型语言，但可以写类型注解让 IDE 和静态检查工具提前发现问题。注解**不影响运行**，只是给人和工具看的契约。

```python
def greet(name: str, times: int = 1) -> str:
    return f"你好，{name}！" * times

age: int = 18
scores: list[float] = [90.5, 88.0]
user: dict[str, str] = {"name": "小明"}
maybe: str | None = None      # Python 3.10+ 的联合类型写法
```

复杂类型用 `typing` 模块：

```python
from typing import Callable, Iterable, Protocol

def apply(func: Callable[[int], int], items: Iterable[int]) -> list[int]:
    return [func(x) for x in items]

class Reader(Protocol):        # 结构化类型：只要实现了 read 就算
    def read(self) -> str: ...
```

**教材衔接：类型注解速查**

| 写法 | 含义 |
| --- | --- |
| `def f(x: int) -> str:` | 参数与返回值注解 |
| `list[int]` / `dict[str, int]` | 内置泛型（Python 3.9+） |
| `int \| None` | 可空类型（Python 3.10+） |
| `Optional[int]` | 等价写法，需 `from typing import Optional` |
| `Union[int, str]` | 联合类型 |
| `Literal["a", "b"]` | 只能是给定字面量之一 |
| `TypedDict` | 描述字典的键与值类型 |
| `Protocol` | 结构化子类型（鸭子类型检查） |
| `TypeVar` | 泛型参数 |
| `Callable[[int], str]` | 函数类型 |
| `Any` | 关闭类型检查，尽量少用 |
| `cast(int, x)` | 显式断言类型，不做运行时校验 |

```python
from dataclasses import dataclass

@dataclass
class User:
    id: int
    name: str
    tags: list[str]

def find_user(users: list[User], user_id: int) -> User | None:
    return next((u for u in users if u.id == user_id), None)
```

**教材衔接：零基础详解：类型注解与自动化测试**

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

## 原理与运行机制

### 机制总览

1. **建立输入**：把「typing」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「pyproject.toml」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「unittest」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「类型注解与测试」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | typing | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | pyproject.toml | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | unittest | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「类型注解与测试」自己的示例验证。「类型注解与测试」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：版本与时效**

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 升级时只动一个依赖版本，用 Callable 记录构建与运行结果。
- 回归范围锁定 Callable 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后记录 类型注解 的新旧版本差异，并据此调整下次复核时间。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 类型注解、mypy | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「类型注解与测试」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「类型注解与测试」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:python`，用于动手验证《类型注解与测试》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《类型注解与测试》原文中的最小示例。先预测《类型注解与测试》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```python
def greet(name: str, times: int = 1) -> str:
    return f"你好，{name}！" * times

age: int = 18
scores: list[float] = [90.5, 88.0]
user: dict[str, str] = {"name": "小明"}
maybe: str | None = None      # Python 3.10+ 的联合类型写法
```

**教材衔接：静态检查工具**

```bash
pip install mypy
mypy app.py                    # 类型检查

pip install ruff
ruff check .                   # 代码检查 + 导入排序
ruff format .                  # 格式化（也可用 black）
```

建议在 `pyproject.toml` 中统一配置：

```toml
[tool.ruff]
line-length = 100
target-version = "py311"

[tool.mypy]
python_version = "3.11"
strict = true
```

**教材衔接：用 pytest 写测试**

```python
# calculator.py
def divide(a: float, b: float) -> float:
    if b == 0:
        raise ZeroDivisionError("除数不能为 0")
    return a / b
```

```python
# test_calculator.py
import pytest
from calculator import divide

def test_divide():
    assert divide(10, 2) == 5

def test_divide_by_zero():
    with pytest.raises(ZeroDivisionError):
        divide(1, 0)

@pytest.mark.parametrize("a, b, expected", [(6, 3, 2), (5, 2, 2.5)])
def test_divide_cases(a, b, expected):
    assert divide(a, b) == expected
```

```bash
pip install pytest
pytest -q                      # 运行测试
pytest --cov=. --cov-report=term    # 覆盖率
```

标准库的 `unittest` 也能用，语法更啰嗦但无需第三方依赖；`doctest` 则可以直接运行文档字符串里的示例。

**教材衔接：pytest 速查**

| 目的 | 写法 |
| --- | --- |
| 断言 | `assert result == expected` |
| 断言异常 | `with pytest.raises(ValueError): ...` |
| 断言近似相等 | `assert value == pytest.approx(0.1 + 0.2)` |
| 参数化 | `@pytest.mark.parametrize("a,b,expected", [(1, 2, 3)])` |
| 夹具 | `@pytest.fixture` + 测试函数同名参数 |
| 夹具清理 | 夹具内 `yield` 之后写清理逻辑 |
| 临时目录 | 使用内置夹具 `tmp_path` |
| 跳过用例 | `@pytest.mark.skip(reason="待实现")` |
| 条件跳过 | `@pytest.mark.skipif(sys.version_info < (3, 11), ...)` |
| 预期失败 | `@pytest.mark.xfail(reason="已知问题")` |
| 分组标记 | `@pytest.mark.slow`，运行 `pytest -m slow` |
| 只看失败 | `pytest -x` 或 `pytest --lf` |
| 覆盖率 | `pytest --cov=myapp --cov-report=term-missing` |

```python
import pytest

@pytest.fixture
def users(tmp_path):
    db = {"u1": {"name": "小明"}}
    yield db
    db.clear()                     # 测试结束后清理

@pytest.mark.parametrize(
    "raw,expected",
    [("1", 1), (" 42 ", 42), ("0", 0)],
)
def test_parse_int(raw, expected):
    assert int(raw) == expected

def test_missing_key_raises(users):
    with pytest.raises(KeyError):
        users["nobody"]
```

## 时间/空间复杂度或性能分析

**复杂度证据**：「类型注解与测试」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「类型注解与测试」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「类型注解与测试」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《类型注解与测试》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「类型注解与测试」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

> 说明：本表由《类型注解与测试》的核心知识整理（2026-10-07），人工复核进度见 docs/content_review_batches.md。

| 易错点 | 容易踩的做法 | 正确结论 |
| --- | --- | --- |
| 注解与实现不一致 | 类型检查形同虚设 | 让注解与运行期行为一致，并接入类型检查 |
| 只测正常返回 | 异常与边界路径没覆盖 | 覆盖异常、边界与空输入 |
| 测试依赖真实网络与时间 | 测试结果不稳定 | 用假对象与固定时间替换外部依赖 |

**教材衔接：故障现场**

### 现场 1：注解与实现不一致

**症状**：在《类型注解与测试》的复现场景中，类型检查形同虚设。

**根因**：“类型检查形同虚设”只是表层结果。向上追溯会落到“注解与实现不一致”这一步，因为它省略了《类型注解与测试》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《类型注解与测试》的问题，让注解与运行期行为一致，并接入类型检查。

**验证**：保留《类型注解与测试》里触发“类型检查形同虚设”的输入、版本和日志，按“让注解与运行期行为一致，并接入类型检查”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 2：只测正常返回

**症状**：在《类型注解与测试》的复现场景中，异常与边界路径没覆盖。

**根因**：触发点是把“只测正常返回”当成安全做法。它没有满足《类型注解与测试》要求的前提，因此先表现为“异常与边界路径没覆盖”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《类型注解与测试》的问题，覆盖异常、边界与空输入。

**验证**：先在《类型注解与测试》中记录“只测正常返回”留下的失败证据，再执行“覆盖异常、边界与空输入”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 3：测试依赖真实网络与时间

**症状**：在《类型注解与测试》的复现场景中，测试结果不稳定。

**根因**：“测试结果不稳定”只是表层结果。向上追溯会落到“测试依赖真实网络与时间”这一步，因为它省略了《类型注解与测试》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《类型注解与测试》的问题，用假对象与固定时间替换外部依赖。

**验证**：先在《类型注解与测试》中记录“测试依赖真实网络与时间”留下的失败证据，再执行“用假对象与固定时间替换外部依赖”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《模块、包与虚拟环境》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《并发与异步》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《模块、包与虚拟环境》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《Python 容器进阶、拷贝与默认参数》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「类型注解与测试」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《类型注解与测试》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

Python 的类型注解在运行时的作用是？

A. 强制检查类型并在不符时抛异常
B. 自动完成类型转换
C. 提升运行速度
D. 不影响运行，只供工具和阅读使用

**参考答案**：不影响运行，只供工具和阅读使用

**解析**：在「类型注解与测试」里，不影响运行，只供工具和阅读使用。注解默认不参与运行，需要 mypy 等静态检查工具才能发现类型问题。在「类型注解与测试」里判断这道题，要把类型注解、mypy、pytest的条件、过程与失败路径逐项对齐，换成“Python 的类型注解在运行时的作”这个场景，只有满足前提的结论才成立。

### 自测 2

围绕“类型注解与测试”中的 类型注解、mypy、pytest，下列哪两项是本课强调的实践判断？

A. 只要 类型注解 的常规示例通过，就可以跳过边界与异常路径
B. 验证 mypy 时要固定版本并覆盖边界输入，结论才可复现
C. 把 mypy 的单次运行结果当成所有版本和规模都成立
D. 学习 类型注解 时要同时说明输入、输出和失败路径，不能只看正常流程

**参考答案**：验证 mypy 时要固定版本并覆盖边界输入，结论才可复现；学习 类型注解 时要同时说明输入、输出和失败路径，不能只看正常流程

**解析**：本课把类型注解与测试拆成概念、示例与故障现场三部分，因此判断 类型注解 时必须同时交代输入、输出和失败路径，这使“学习 类型注解 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在类型注解与测试里，判断 mypy 时要固定版本与边界输入，所以“验证 mypy 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 3

阅读「类型注解与测试」正文里的这段 Python 代码，下面哪一项判断是正确的？

```python
# test_calculator.py
import pytest
from calculator import divide

def test_divide():
    assert divide(10, 2) == 5

def test_divide_by_zero():
    with pytest.raises(ZeroDivisionError):
        divide(1, 0)

@pytest.mark.parametrize("a, b, expected", [(6, 3, 2), (5, 2, 2.5)])
def test_divide_cases(a, b, expected):
    assert divide(a, b) == expected
```

A. 这段代码只做静态声明，没有循环、分支或可观察输出。
B. 这段代码包含循环结构，同一段逻辑会被重复执行。
C. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。
D. 这段代码会产生可观察的输出，运行后能看到结果。

**参考答案**：这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**解析**：在「类型注解与测试」里，题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行，在「类型注解与测试」里封装边界决定类型注解从哪一步开始生效。把输入或边界换成空值、极值或失败情况后，结论要以「类型注解与测试」的实际运行结果为准。这道题的关键在「类型注解与测试」的类型注解、mypy、pytest：先确认题干“阅读类型注解与测试正文里的这段 Py”问的是哪一步，再排除偷换前提的选项。

**教材衔接：复习与自测**

- [ ] 公开函数都写了参数与返回值注解。
- [ ] 会用 `pytest.raises` 与 `pytest.approx`。
- [ ] 参数化替代重复的测试函数。
- [ ] 测试之间互不影响，可任意顺序执行。
- [ ] 本地跑 `mypy` / `ruff` 与 `pytest` 后再提交。

**教材衔接：动手练习**

> 本课练习重点：围绕「类型注解、mypy、pytest」完成复述、实验和交付，每个结果都要能被别人检查。

把 Callable 抽成函数并补类型标注，最后换成真实输入验证。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 类型注解与测试解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「mypy」是什么关系？

验收标准：说明 类型注解 与 mypy 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：围绕「为什么要类型注解」小节做一次五步记录，原例取自 Callable，改动只允许动一处类型注解，原因要能指回正文的判断依据。

### 练习 3：交付一个小结果（30 分钟）

用 Callable 解析一份自己的数据，输出统计结果并核对一条记录。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「类型注解」和「mypy」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

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

### 任务 2：只改一个条件

把「类型注解与测试」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 mypy 换成边界值，其他输入保持原样。
- 预测：先写下「类型注解与测试」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响类型注解。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的 类型注解 数据，保持输出格式与任务 1 一致。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Python 的类型注解在运行时的作用是？」的判断依据。
- [ ] 不看解析，能说出「用 pytest 断言「抛出指定异常」的正确写法是？」的判断依据。
- [ ] 不看解析，能说出「str | None 这种写法表示？」的判断依据。
- [ ] 不看解析，能说出「mypy 这类工具的作用是？」的判断依据。
- [ ] 不看解析，能说出「pytest 中 fixture 的主要用途是？」的判断依据。
- [ ] 至少运行一次 Callable 的示例，记录输入、输出和 类型注解 的边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `typing` | 复杂类型用 `typing` 模块： |
| `pyproject.toml` | 建议在 `pyproject.toml` 中统一配置： |
| `unittest` | 标准库的 `unittest` 也能用，语法更啰嗦但无需第三方依赖；`doctest` 则可以直接运行文档字符串里的示例。 |
| `类型注解` | 类型注解是写给工具和同事看的说明书，运行时不强制，但能让编辑器提前报错。 |

## 考点精讲

### 考点 1：概念判断·类型注解

- **题目**：Python 的类型注解在运行时的作用是？
- **判断依据**：在「类型注解与测试」里，不影响运行，只供工具和阅读使用。注解默认不参与运行，需要 mypy 等静态检查工具才能发现类型问题。在「类型注解与测试」里判断这道题，要把类型注解、mypy、pytest的条件、过程与失败路径逐项对齐，换成“Python 的类型注解在运行时的作”这个场景，只有满足前提的结论才成立。

### 考点 2：多选辨析·类型注解

- **题目**：围绕“类型注解与测试”中的 类型注解、mypy、pytest，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把类型注解与测试拆成概念、示例与故障现场三部分，因此判断 类型注解 时必须同时交代输入、输出和失败路径，这使“学习 类型注解 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在类型注解与测试里，判断 mypy 时要固定版本与边界输入，所以“验证 mypy 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 3：概念判断·类型注解

- **题目**：str | None 这种写法表示？
- **判断依据**：在「类型注解与测试」里，字符串或空值。它是联合类型，表示值可能是 str，也可能是 None，Python 3.10+ 支持这种写法。「类型注解与测试」要求先交代类型注解、mypy、pytest的前提再下结论，所以“字符串或空值”只在题干“str | None 这种写法表示”给定的条件下成立。

### 考点 4：代码补全·类型注解

- **题目**：阅读「类型注解与测试」正文里的这段 Python 代码，下面哪一项判断是正确的？
- **判断依据**：在「类型注解与测试」里，题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行，在「类型注解与测试」里封装边界决定类型注解从哪一步开始生效。把输入或边界换成空值、极值或失败情况后，结论要以「类型注解与测试」的实际运行结果为准。这道题的关键在「类型注解与测试」的类型注解、mypy、pytest：先确认题干“阅读类型注解与测试正文里的这段 Py”问的是哪一步，再排除偷换前提的选项。

### 考点 5：概念判断·类型注解

- **题目**：pytest 中 fixture 的主要用途是？
- **判断依据**：在「类型注解与测试」里，提供可复用的测试前置准备与清理逻辑。fixture 通过依赖注入复用资源（数据库连接、临时目录），yield 之前准备、之后清理。“pytest”与「类型注解与测试」的术语表相呼应，只有符合类型注解、mypy、pytest约束的“提供可复用的测试前置准备与清理逻辑”才是正文支持的结论。

### 考点 6：填空·类型注解

- **题目**：补全代码：「类型注解与测试」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `raise ____("除数不能为 0")`
- **判断依据**：空格应填写「ZeroDivisionError」、「zerodivisionerror」。在「类型注解与测试」里判断这道题，要把类型注解、mypy、pytest的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。“类型注解与测试示例中”与「类型注解与测试」的术语表相呼应，只有符合类型注解、mypy、pytest约束的“ZeroDivisionError”才是正文支持的结论。

## English Overview

**Title:** Typing & Testing

**Summary:** Type hints, mypy/ruff and testing with pytest.

**Category:** Python
**Level:** 进阶
**Key terms:** 类型注解, mypy, pytest, ruff, 单元测试, unittest

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Python 3.12+
；本课聚焦 类型注解。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：类型注解、mypy、pytest、ruff、单元测试、unittest
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2026-12-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [typing 文档](https://docs.python.org/3/library/typing.html) | 类型标注与泛型 |
| [Python 教程](https://docs.python.org/3/tutorial/) | 语法、数据类型与控制流 |
| [Python 语言参考](https://docs.python.org/3/reference/) | 语言语义与数据模型 |

> 「类型注解与测试」的链接用于离线阅读后的延伸核对；App 不会自动联网。
