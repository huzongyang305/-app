## 容器选型速查

| 需求 | 容器 | 复杂度 | 说明 |
| --- | --- | --- | --- |
| 默认顺序容器 | `std::vector` | 尾部均摊 O(1) | 连续内存、缓存友好 |
| 频繁两端插入删除 | `std::deque` | 两端 O(1) | 分段连续存储 |
| 频繁中间插入删除 | `std::list` | 已知位置 O(1) | 缓存不友好，谨慎使用 |
| 固定大小、栈上分配 | `std::array` | 访问 O(1) | 编译期确定大小 |
| 有序键值 | `std::map` | O(log n) | 红黑树，可范围遍历 |
| 无序键值、只求快 | `std::unordered_map` | 平均 O(1) | 哈希表，最坏 O(n) |
| 有序去重集合 | `std::set` | O(log n) | 需要排序或范围查询时用 |
| 无序去重集合 | `std::unordered_set` | 平均 O(1) | 判存在性最快 |
| 优先级队列 | `std::priority_queue` | 入出 O(log n) | 默认大顶堆 |
| 只读视图 | `std::string_view` / `std::span` | O(1) 构造 | C++17 / C++20，注意生命周期 |

## 常用算法速查

| 目的 | 算法 | 备注 |
| --- | --- | --- |
| 查找元素 | `std::find` | 顺序查找 O(n) |
| 有序容器二分 | `std::lower_bound` / `upper_bound` | O(log n)，需已排序 |
| 排序 | `std::sort` | 平均 O(n log n)，不稳定 |
| 稳定排序 | `std::stable_sort` | 保留相等元素顺序 |
| 条件计数 | `std::count_if` | 配合 lambda |
| 变换 | `std::transform` | 类似 map |
| 过滤并删除 | `erase-remove` 惯用法 | `v.erase(remove_if(...), v.end())` |
| 累加 | `std::accumulate` | 注意初始值类型决定结果类型 |
| 最值 | `std::min_element` / `max_element` | 返回迭代器 |
| 并行版本 | `std::sort(std::execution::par, ...)` | C++17，需链接 TBB |

```cpp
#include <algorithm>
#include <numeric>
#include <vector>

std::vector<int> v{5, 1, 4, 2, 3};
std::sort(v.begin(), v.end());                      // 1 2 3 4 5
v.erase(std::remove_if(v.begin(), v.end(),
                       [](int x) { return x % 2 == 0; }),
        v.end());                                   // 删除偶数
auto sum = std::accumulate(v.begin(), v.end(), 0);  // 初始值 0 决定返回 int
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 在 `vector` 上 `erase` 后继续用旧迭代器 | 崩溃或跳过元素 | 用 `it = v.erase(it)` 接收返回值 |
| 循环中反复 `v.push_back` 并持有引用 | 引用失效（扩容后悬空） | 扩容会让所有指针/引用失效；先 `reserve` 或改用下标 |
| `map` 用 `operator[]` 查询 | 不存在时插入默认值，size 变大 | 只读查询用 `find` / `at` |
| 用 `std::list` 当默认容器 | 遍历慢、内存碎片多 | 默认用 `vector`，测过再换 |
| 用 `std::sort` 排 `std::list` | 编译报错 | `list` 用成员函数 `sort()` |
| 比较函数写 `<=` | 触发断言或未定义行为 | 严格弱序要求用 `<` |
| 遍历容器时删除元素 | 迭代器失效 | 用 `erase-remove` 惯用法，或先记录再删 |
| `unordered_map` 用自定义类型作键 | 编译或链接错误 | 需要提供 `std::hash` 特化与 `operator==` |
| `std::accumulate` 初始值写 `0` 累加 `double` | 结果被截断 | 初始值写 `0.0` |
| `string_view` 指向临时字符串 | 悬空，读到垃圾数据 | 确保被引用对象生命周期长于视图 |

## 自测清单

- [ ] 默认选 `vector`，能说出 `map` 与 `unordered_map` 的取舍。
- [ ] 会写 `erase-remove` 惯用法删除元素。
- [ ] 知道哪些操作会让孩子迭代器 / 引用失效。
- [ ] 只读查询 `map` 时用 `find` 或 `at`，不用 `operator[]`。
- [ ] 记得 `accumulate` 的初始值类型决定结果类型。
