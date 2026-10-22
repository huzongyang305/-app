## 参数写法速查

| 写法 | 含义 | 调用示例 | 注意点 |
| --- | --- | --- | --- |
| `def f(a, b):` | 必填位置参数 | `f(1, 2)` | 顺序敏感 |
| `def f(a, b=1):` | 默认参数 | `f(1)`、`f(1, 5)` | 默认值只在定义时求值一次 |
| `def f(*args):` | 收集位置参数为元组 | `f(1, 2, 3)` | 只能有一个，放在普通参数之后 |
| `def f(**kwargs):` | 收集关键字参数为字典 | `f(x=1)` | 只能有一个，放在最后 |
| `def f(a, *, b):` | `b` 只能是关键字参数 | `f(1, b=2)` | `*` 之后强制关键字传参 |
| `def f(a, /, b):` | `a` 只能是位置参数 | `f(1, 2)` | `/` 之前禁止写成关键字 |
| `f(*nums)` | 解包序列成位置参数 | `f(*[1, 2])` | 与 `def f(*args)` 配对使用 |
| `f(**cfg)` | 解包字典成关键字参数 | `f(**{"x": 1})` | 键必须是字符串 |

参数顺序的固定规则：位置参数 → 默认参数 → `*args` → 仅关键字参数 → `**kwargs`。

## 常见错误对照表

| 容易写错的写法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `def add(x, items=[]):` | 多次调用共享同一个列表，数据越攒越多 | 可变对象默认值在定义时创建一次；改成 `items=None` 再在函数内 `items = items or []` |
| 函数里写 `count = 1` 想修改全局 | 只创建了局部变量，外部没变 | 显式声明 `global count`；更好的做法是把值 `return` 出去 |
| 返回列表后调用方直接 `append` | 调用方的改动影响所有持有者 | 需要隔离时返回 `list(result)` 或 `copy.deepcopy()` |
| `def f(a, b=1, c):` | `SyntaxError: non-default argument follows default argument` | 有默认值的参数后面不能再出现无默认值的位置参数 |
| 在函数内修改传入的 `tuple` | `TypeError: 'tuple' object does not support item assignment` | 元组不可变，需要新对象：`t = t[:1] + (9,) + t[2:]` |
| 用 `return` 返回多个值却忘了打包顺序 | 调用方解包错位 | `return a, b` 实际是元组，解包时数量必须一致 |
| 函数名与变量名相同 | 后续调用报 `TypeError: 'int' object is not callable` | 函数名与变量名分开命名 |
| 递归函数忘记写终止条件 | `RecursionError: maximum recursion depth exceeded` | 先写基准情形，并确认每次递归规模在缩小 |

## 速查：返回值与作用域

```python
def stats(nums):
    """返回最小值、最大值、平均值，一次打包返回。"""
    if not nums:
        return None, None, None      # 早返回比层层缩进更清晰
    return min(nums), max(nums), sum(nums) / len(nums)

low, high, avg = stats([3, 5, 9])

def add_item(item, items=None):
    items = items if items is not None else []   # 避免可变默认值的经典写法
    items.append(item)
    return items
```

| 概念 | 说明 |
| --- | --- |
| 局部变量 | 函数内赋值即创建，函数结束销毁 |
| 闭包 | 内层函数引用了外层变量，外层返回后仍可访问 |
| `nonlocal` | 在内层函数中修改外层（非全局）变量 |
| `global` | 直接修改模块级变量，可读性差，能不用就不用 |
| 文档字符串 | 函数第一行的字符串，`help(f)` 与 `f.__doc__` 可查看 |

## 自测清单

- [ ] 能写出「位置 → 默认 → `*args` → 仅关键字 → `**kwargs`」的顺序。
- [ ] 记得默认参数不要用列表、字典这类可变对象。
- [ ] 知道函数没有 `return` 时返回 `None`。
- [ ] 会用 `*` 强制某些参数必须以关键字传入，提升调用可读性。
- [ ] 递归函数里先写基准情形，并验证规模确实在缩小。
