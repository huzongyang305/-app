## 零基础详解：四种容器怎么选

### 一句话说清它是什么

Python 的四种主力容器分工明确：**列表管顺序、元组管固定、字典管查找、集合管去重**。
选错容器，代码不会报错，但会又慢又难读。

### 用生活比喻理解

| 容器 | 比喻 | 什么时候用 |
| --- | --- | --- |
| `list` | 一排带编号的抽屉 | 有顺序、会增删、允许重复 |
| `tuple` | 刻好字的石板 | 一旦确定不再改，例如坐标、配置项 |
| `dict` | 字典 / 通讯录 | 用名字快速查内容 |
| `set` | 一筐不重复的球 | 去重、判断是否存在、集合运算 |

### 四种容器横向对比

| 对比项 | list | tuple | dict | set |
| --- | --- | --- | --- | --- |
| 写法 | `[1, 2]` | `(1, 2)` | `{"a": 1}` | `{1, 2}` |
| 有序 | 是 | 是 | 是（3.7+） | 否 |
| 可修改 | 是 | 否 | 是 | 是 |
| 允许重复 | 是 | 是 | 键不能重复 | 否 |
| 能否作字典键 | 否 | 是（元素不可变时） | 否 | 否（要用 frozenset） |
| 查找速度 | O(n) | O(n) | O(1) | O(1) |

### 按「问题」选容器

| 你要做的事 | 选它 | 示例 |
| --- | --- | --- |
| 按顺序保存、后面还要改 | `list` | 待办清单 |
| 一次返回多个固定值 | `tuple` | `return (x, y)` |
| 用 ID 查找对象 | `dict` | `users[user_id]` |
| 快速判断「有没有」 | `set` 或 `dict` | 黑名单、已访问集合 |
| 去掉重复项 | `set` | `set(names)` |
| 保持顺序去重 | `dict.fromkeys` | `list(dict.fromkeys(seq))` |

```python
# 去重且保持原顺序（最常用的写法）
names = ["a", "b", "a", "c"]
unique = list(dict.fromkeys(names))     # ['a', 'b', 'c']

# 用字典做计数，比 list.count 快得多
counter = {}
for ch in "banana":
    counter[ch] = counter.get(ch, 0) + 1
```

### 常用操作速查

```python
nums = [3, 1, 2]
nums.append(4)          # 尾部添加
nums.insert(0, 0)       # 指定位置插入
nums.remove(1)          # 按值删第一个
last = nums.pop()       # 弹出尾部
nums.sort()             # 原地排序
sorted_copy = sorted(nums)   # 返回新列表

point = (3, 4)
x, y = point            # 解包

user = {"id": 1, "name": "小明"}
user.get("age", 0)      # 取不到时给默认值，比 user["age"] 安全
for k, v in user.items():
    print(k, v)

tags = {"py", "db"}
tags.add("ai")
"py" in tags            # True，O(1)
```

### 复杂度直觉：为什么查找要用字典

| 操作 | list | dict / set |
| --- | --- | --- |
| 按下标取 | O(1) | —— |
| 按值查找 | O(n) | O(1) |
| 判断存在 | O(n) | O(1) |
| 尾部追加 | O(1) | O(1) |
| 中间插入或删除 | O(n) | —— |

数据量一万时差别不明显，一百万时就是「瞬间」和「等几秒」的区别。

### 新手最容易踩的七个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `list` 判存在 | 数据量大时极慢 | 换成 `set` |
| 遍历时删元素 | 漏掉若干项 | 遍历副本或倒序删 |
| 用下标取不存在的键 | 抛 `KeyError` | 用 `.get(key, 默认值)` |
| 用 list 当字典键 | `TypeError: unhashable` | 换成 tuple |
| 直接改 tuple | `TypeError` | 需要可变就换 list |
| 以为 `{}` 是空集合 | 其实是空字典 | 空集合写 `set()` |
| 浅拷贝嵌套结构 | 改内层互相影响 | 用 `copy.deepcopy()` |

### 手把手练习：词频统计前三名

```python
text = "the quick brown fox jumps over the lazy dog the fox"

counts = {}
for word in text.split():
    counts[word] = counts.get(word, 0) + 1

top3 = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))[:3]
for word, n in top3:
    print(f"{word}: {n} 次")

print("不同单词数：", len(set(text.split())))
```

### 学完自测

- [ ] 能说出四种容器各自最适合的场景。
- [ ] 知道为什么判断存在性要用 set 而不是 list。
- [ ] 能写出「去重且保持原顺序」的一行代码。
- [ ] 知道 `{}` 是空字典，空集合要写 `set()`。
- [ ] 能解释浅拷贝与深拷贝的区别。
