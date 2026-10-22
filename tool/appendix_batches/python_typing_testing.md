## 类型注解速查

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

## pytest 速查

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

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 以为注解会做运行时校验 | 传错类型也不报错 | 注解只是给类型检查器，运行时校验用 pydantic 或手写断言 |
| `list[int]` 用在 Python 3.8 | `TypeError` | 用 `from __future__ import annotations` 或 `List[int]` |
| `def f(x: int = None)` | 类型检查告警 | 应写 `int \| None = None` |
| 一个测试里断言十件事 | 失败后不知道哪一步出问题 | 一个测试聚焦一个行为 |
| 测试之间共享可变状态 | 用例顺序一换就失败 | 每个用例自建数据，夹具内清理 |
| 用 `print` 调试测试 | 默认不显示输出 | 用 `pytest -s` 或断言失败信息 |
| 只测正常路径 | 边界与异常没人管 | 补空输入、边界值与异常路径 |
| 覆盖率 100% 就放心 | 断言可能没检查关键结果 | 关注断言质量，必要时做变异测试 |
| 测试依赖真实网络或数据库 | 不稳定、慢 | 用假实现或本地容器，测试保持离线 |
| 忘记装开发依赖 | `ModuleNotFoundError: pytest` | 用 `requirements-dev.txt` 或 `pyproject` 分组声明 |

## 自测清单

- [ ] 公开函数都写了参数与返回值注解。
- [ ] 会用 `pytest.raises` 与 `pytest.approx`。
- [ ] 参数化替代重复的测试函数。
- [ ] 测试之间互不影响，可任意顺序执行。
- [ ] 本地跑 `mypy` / `ruff` 与 `pytest` 后再提交。
