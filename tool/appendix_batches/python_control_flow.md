## 常见错误对照表

| 容易写错的写法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `for name in names: names.remove(name)` | 元素被跳过，删不干净 | 遍历时修改长度；改成推导式 `names = [n for n in names if 条件]` 或倒序删除 |
| `while x > 0:` 但循环体没改 `x` | 死循环，CPU 跑满 | 确认循环变量每轮都在向终止条件靠近 |
| `if x = 1:` | `SyntaxError` | 赋值与比较不同，条件应该写 `==` |
| `if 0.1 + 0.2 == 0.3:` | 条件永远不成立 | 浮点比较用 `math.isclose()` |
| `if name == "a" or "b":` | 条件恒为真 | `or` 两边是独立表达式，正确写法 `name in ("a", "b")` |
| `for i in range(len(items)):` 只为取值 | 可读性差、容易越界 | 直接迭代元素；确实需要下标再用 `enumerate(items)` |
| 循环里用 `+=` 拼字符串 | 数据量大时越来越慢 | 先收集到列表，最后 `"".join(parts)` |
| `try: ... except:` 吞掉所有异常 | 真正的 bug 被隐藏，排查困难 | 只捕获预期异常类型，并至少 `logging.exception(...)` 记录 |
| 忘记 `break` 导致 `else` 没执行 | `for...else` 行为与直觉相反 | `else` 只在循环**正常结束**（没有 `break`）时执行 |

## 循环控制速查

| 关键词 | 作用 | 典型场景 |
| --- | --- | --- |
| `break` | 立刻结束整个循环 | 找到目标就收工 |
| `continue` | 跳过本次，进入下一次 | 过滤不符合条件的元素 |
| `else`（配合循环） | 没有触发 `break` 时执行 | 判断「一个都没找到」 |
| `enumerate` | 同时拿到下标与元素 | 需要序号或就地修改列表 |
| `zip` | 并行遍历多个序列 | 对齐两份数据 |
| `reversed` | 反向遍历 | 倒序删除时避免下标错位 |
| `sorted(key=...)` | 按指定规则排序 | 复杂对象排序，不修改原列表 |

常用推导式与生成器速查：

```python
squares = [x * x for x in range(10)]                    # 列表推导式
even = [x for x in range(20) if x % 2 == 0]             # 带条件
pairs = {k: v for k, v in items if v > 0}               # 字典推导式
unique = {len(w) for w in words}                        # 集合推导式
lazy = (x * x for x in range(10 ** 7))                  # 生成器，不占内存
flat = [n for row in matrix for n in row]               # 嵌套展平，顺序与嵌套循环一致
```

`for...else` 的实战写法：

```python
for user in users:
    if user.id == target:
        print("找到了")
        break
else:
    print("没找到，走兜底逻辑")   # 只有循环没被 break 才执行
```

## 自测清单

- [ ] 知道 `range(5)` 不含 5，`range(1, 10, 2)` 步长为 2。
- [ ] 遍历中需要删除元素时，改用推导式或倒序遍历。
- [ ] 能用 `enumerate` 替代 `range(len(...))`。
- [ ] 分得清 `break` 与 `continue`，并记得 `for...else` 的触发条件。
- [ ] 知道生成器表达式不立即求值，适合超大数据量。
