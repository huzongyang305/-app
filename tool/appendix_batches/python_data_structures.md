## 容器选型速查

| 需求 | 首选 | 理由 | 常用写法 |
| --- | --- | --- | --- |
| 有序、可重复、频繁按下标访问 | `list` | 数组实现，下标访问 O(1) | `items[0]`、`items[-1]` |
| 数据不重复、只判存在性 | `set` | 哈希实现，判断 `in` 平均 O(1) | `if x in seen:` |
| 键值映射、按 key 查找 | `dict` | 哈希实现，平均 O(1) | `count[word] += 1` |
| 数据固定不变、可作字典键 | `tuple` | 不可变、可哈希 | `point = (3, 4)` |
| 需要先进先出队列 | `collections.deque` | 两端操作 O(1) | `q.append(x)`、`q.popleft()` |
| 需要计数 | `collections.Counter` | 自带 `most_common` | `Counter(words)` |
| 需要带默认值的字典 | `collections.defaultdict` | 免去初始化判断 | `d[k].append(v)` |

## 常用操作对照

| 操作 | 列表 | 字典 | 集合 |
| --- | --- | --- | --- |
| 添加元素 | `append` / `insert` / `extend` | `d[k] = v` / `setdefault` | `add` / `update` |
| 删除元素 | `pop(i)` / `remove(v)` | `pop(k)` / `del d[k]` | `remove` / `discard` |
| 安全取值 | `items[i]`（越界报错） | `d.get(k, 默认值)` | 无下标，用 `in` 判断 |
| 判断存在 | `v in items`（O(n)） | `k in d`（平均 O(1)） | `v in s`（平均 O(1)） |
| 合并 | `a + b` / `a.extend(b)` | `a.update(b)` / `{**a, **b}` | `a | b` |
| 排序 | `items.sort()`（原地） | 按键排序 `sorted(d.items())` | `sorted(s)` 返回列表 |
| 浅拷贝 | `items.copy()` / `items[:]` | `d.copy()` | `s.copy()` |

## 常见错误对照表

| 容易写错的写法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `d["missing"]` | `KeyError` | 不确定键存在时用 `d.get("missing", 0)` |
| `d.get("k") + 1` 首次统计 | `TypeError: NoneType + int` | 给默认值：`d.get("k", 0) + 1`，或用 `Counter` |
| `[[]] * 3` | 三个元素是同一个列表 | 改成 `[[] for _ in range(3)]` |
| `s = {}` 想建集合 | 实际建了空字典 | 空集合要写 `set()` |
| 把列表放进集合 | `TypeError: unhashable type: 'list'` | 先转元组：`{(x, y) for x, y in points}` |
| `list.sort()` 后写 `x = list.sort()` | `x` 是 `None` | 原地方法返回 `None`；需要新列表用 `sorted(list)` |
| `d.items()` 遍历中删除 | `RuntimeError: dictionary changed size` | 先收集要删的键，再统一删除；或用推导式重建 |
| 用 `list.pop(0)` 当队列 | 数据量大时越来越慢 | 改用 `collections.deque` 的 `popleft()` |
| 切片赋值给原列表想改副本 | 原列表被改 | `b = a` 是同一对象，要副本写 `b = a[:]` 或 `a.copy()` |

## 复杂度速查

| 操作 | list | dict / set | deque |
| --- | --- | --- | --- |
| 按下标访问 | O(1) | 不适用 | O(n) |
| 查找 `in` | O(n) | 平均 O(1) | O(n) |
| 尾部追加 | 均摊 O(1) | 平均 O(1) | O(1) |
| 头部插入/删除 | O(n) | 不适用 | O(1) |
| 中间插入/删除 | O(n) | 不适用 | O(n) |
| 有序遍历 | O(n) | O(n)（无序） | O(n) |

## 自测清单

- [ ] 能用 `set` 给一批数据去重，并说明为什么比列表快。
- [ ] 统计词频时优先想到 `Counter` 或 `defaultdict(int)`。
- [ ] 知道字典的键必须是可哈希（不可变）对象。
- [ ] 需要队列时用 `deque`，不会用 `list.pop(0)`。
- [ ] 分得清 `sort()`（原地、返回 `None`）与 `sorted()`（返回新列表）。
