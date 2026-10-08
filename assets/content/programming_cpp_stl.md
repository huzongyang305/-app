# STL 容器与算法

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：55 分钟

![STL 容器、迭代器与算法的选择](images/diagram_cpp_stl.webp)

![STL 容器与算法](images/remaining_cpp_stl.webp)

## 本节知识框架

**课程定位**：所属分类为「C++」，课程主题为「STL 容器与算法」，学习阶段为「进阶」，建议用时 55 分钟。

**本课要解决的主问题**：vector/map/set 的选择、迭代器、算法库与 erase-remove。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「STL 容器与算法」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「STL 容器与算法」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「STL」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《模板与泛型编程》

**学习位置**：本课位于《模板与泛型编程》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《现代 C++ 特性》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释STL 容器与算法解决了什么问题，而不是只背术语。
- 能说清 「STL」、「vector」、「map」、「unordered_map」 之间的关系，并分别举出一个例子。
- 能把 STL 放回「STL 容器与算法」的知识体系，说明它和 vector 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：vector/map/set 的选择、迭代器、算法库与 erase-remove。

**教材衔接：前置知识**

- 先完成上一课《模板与泛型编程》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「模板与泛型编程」，或确认自己能独立跑通正文里的 minmax_element 示例。
- 开始前先复习：STL、vector、map。
- 如果 常用容器 这一步看不懂，先记录具体卡点，再用 minmax_element 复现一遍。

**教材衔接：本课小结**

STL 的价值在于**容器 + 迭代器 + 算法**三者解耦。先把 `vector`、`unordered_map`、`sort`、`find` 用熟，再按需扩展。

## 核心概念定义

> 阅读约定：本课先给「STL 容器与算法」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| STL | STL 把「存数据」和「处理数据」分开。 | 仅在「STL 容器与算法」明确给出的输入、版本与资源条件下成立。 |
| vector | C++ 标准库中的动态数组，连续存储元素并支持自动扩容。 | 仅在「STL 容器与算法」明确给出的输入、版本与资源条件下成立。 |
| 迭代器 | STL 的价值在于容器 + 迭代器 + 算法三者解耦。 | 仅在「STL 容器与算法」明确给出的输入、版本与资源条件下成立。 |
| algorithm | C++ 标准库算法头文件，提供排序、查找、变换和数值等泛型算法。 | 仅在「STL 容器与算法」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「STL 容器与算法」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「STL」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「vector」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「迭代器」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「STL 容器与算法」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | STL | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | vector | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 迭代器 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「STL 容器与算法」自己的示例验证。「STL 容器与算法」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：算法库**

```cpp
#include <algorithm>
#include <numeric>

std::sort(nums.begin(), nums.end());                   // 升序
std::sort(nums.begin(), nums.end(), std::greater<int>());

auto it = std::find(nums.begin(), nums.end(), 4);
bool has = it != nums.end();

std::reverse(nums.begin(), nums.end());
int total = std::accumulate(nums.begin(), nums.end(), 0);
auto [min_it, max_it] = std::minmax_element(nums.begin(), nums.end());

bool all_positive = std::all_of(nums.begin(), nums.end(),
                                [](int x) { return x > 0; });
```

**教材衔接：lambda 与算法配合**

```cpp
std::vector<std::string> names{"tom", "alice", "bob"};

std::sort(names.begin(), names.end(),
          [](const std::string& a, const std::string& b) {
              return a.size() < b.size();
          });

auto count = std::count_if(names.begin(), names.end(),
                           [](const auto& n) { return n.size() > 3; });
```

**教材衔接：选择容器的思路**

1. 不确定就用 `vector`。
2. 需要按键查找 → `unordered_map`（无需有序）或 `map`（需要有序遍历）。
3. 需要去重 → `set` / `unordered_set`。
4. 频繁在中间插删 → `list`（但缓存不友好，往往仍不如 vector）。

**教材衔接：容器选型速查**

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

**教材衔接：常用算法速查**

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

**教材衔接：零基础详解：STL 容器、迭代器与算法**

### 一句话说清它是什么

STL 把「存数据」和「处理数据」分开：
容器负责存，迭代器负责遍历，算法负责加工。三者用统一的接口拼在一起，所以你学会一套就能通用。

### 用生活比喻理解

| 组件 | 比喻 | 说明 |
| --- | --- | --- |
| 容器 | 各种收纳盒 | vector、map、set 各有取舍 |
| 迭代器 | 手指 | 指向某个位置，能前后移动 |
| 算法 | 加工机器 | sort、find、transform |
| 仿函数或 Lambda | 加工参数 | 告诉算法「按什么规则」 |

### 容器选择表

| 容器 | 结构 | 查找 | 插入删除 | 典型用途 |
| --- | --- | --- | --- | --- |
| `vector` | 动态数组 | O(n) | 尾部 O(1) | **默认选择** |
| `deque` | 双端队列 | O(n) | 两端 O(1) | 双端进出 |
| `list` | 双向链表 | O(n) | 已知位置 O(1) | 频繁中间插入 |
| `map` / `set` | 红黑树 | O(log n) | O(log n) | 需要有序 |
| `unordered_map` | 哈希表 | 平均 O(1) | 平均 O(1) | 需要极速查找 |
| `array` | 固定数组 | O(n) | 长度不可变 | 编译期确定大小 |

### 一段代码走完常用操作

```cpp
#include <algorithm>
#include <iostream>
#include <map>
#include <numeric>
#include <string>
#include <unordered_map>
#include <vector>

int main() {
    std::vector<int> nums{5, 3, 1, 4, 2};
    std::sort(nums.begin(), nums.end());                  // 排序
    auto it = std::find(nums.begin(), nums.end(), 4);     // 查找
    int sum = std::accumulate(nums.begin(), nums.end(), 0);
    std::cout << "和为 " << sum << "，找到 " << *it << '\n';

    // 统计词频：unordered_map 是首选
    std::unordered_map<std::string, int> freq;
    for (const auto& word : {"a", "b", "a", "c", "a"}) {
        ++freq[word];
    }
    for (const auto& [word, count] : freq) {
        std::cout << word << '=' << count << ' ';
    }
    std::cout << '\n';

    // 有序遍历用 map
    std::map<std::string, int> ordered(freq.begin(), freq.end());
    for (const auto& [word, count] : ordered) {
        std::cout << word << ':' << count << ' ';
    }
}
```

### 迭代器的三种类型

| 类型 | 写法 | 能否修改 |
| --- | --- | --- |
| `begin()` / `end()` | `auto it = v.begin()` | 能 |
| `cbegin()` / `cend()` | 只读迭代器 | 不能 |
| 反向 `rbegin()` / `rend()` | 从后往前 | 能 |

通用遍历建议（既安全又简洁）：

```cpp
for (const auto& item : container) { /* 只读 */ }
for (auto& item : container) { /* 需要修改 */ }
```

### 常用算法速查

| 算法 | 作用 |
| --- | --- |
| `sort` / `stable_sort` | 排序 |
| `find` / `find_if` | 查找 |
| `count` / `count_if` | 计数 |
| `transform` | 映射变换 |
| `remove_if` + `erase` | 删除符合条件的元素 |
| `accumulate` | 求和或自定义聚合 |
| `min_element` / `max_element` | 取极值 |
| `any_of` / `all_of` | 条件判断 |

```cpp
std::erase_if(nums, [](int n) { return n % 2 == 0; });   // C++20 起可直接删
```

### 性能与安全习惯

```cpp
std::vector<int> v;
v.reserve(1000);          // 预分配，避免多次扩容与拷贝
v.push_back(1);
v.emplace_back(2);        // 原地构造，少一次移动
v.at(0);                  // 带越界检查，越界抛异常
v[0];                     // 不检查，追求速度时用
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 扩容后继续用旧迭代器 | 迭代器失效，崩溃 | 扩容后重新获取迭代器 |
| 遍历中删元素 | 迭代器失效 | 用 erase 的返回值或 erase_if |
| 在 `unordered_map` 里存自定义键 | 编译错误 | 提供 `std::hash` 与 `operator==` |
| 用 `map` 当极速查找 | 比哈希慢 | 无顺序需求就用 `unordered_map` |
| 忘了 `reserve` | 反复扩容影响性能 | 已知规模就预留 |
| `vector<bool>` 当普通容器 | 行为特殊 | 用 `deque<bool>` 或 `vector<char>` |
| 用 `[]` 越界访问 | 未定义行为 | 关键路径用 `at()` |
| 拷贝大容器 | 性能差 | 传 `const&`，或用移动 |

### 手把手练习：词频统计前五名

```cpp
#include <algorithm>
#include <iostream>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

int main() {
    const std::string text = "the quick brown fox jumps over the lazy dog the fox";
    std::unordered_map<std::string, int> freq;

    std::istringstream stream(text);
    for (std::string word; stream >> word; ) {
        ++freq[word];
    }

    std::vector<std::pair<std::string, int>> items(freq.begin(), freq.end());
    std::sort(items.begin(), items.end(), [](const auto& a, const auto& b) {
        return a.second != b.second ? a.second > b.second : a.first < b.first;
    });

    for (std::size_t i = 0; i < std::min<std::size_t>(5, items.size()); ++i) {
        std::cout << items[i].first << ": " << items[i].second << '\n';
    }
    std::cout << "不同单词数：" << freq.size() << '\n';
}
```

### 学完自测

- [ ] 能说出 vector、map、unordered_map 各自的复杂度。
- [ ] 能说出迭代器失效的常见原因。
- [ ] 知道 `reserve` 与 `emplace_back` 各优化了什么。
- [ ] 能用 `accumulate` 或 `sort` 加工容器。
- [ ] 知道为什么要传 `const&` 而不是按值传递容器。

**教材衔接：版本与时效**

- C++23 已在主流工具链落地；升级 STL 相关代码前先确认标准库实现情况。
- 升级前先用 minmax_element 建立基线：记录版本、命令和输出，升级后只比较这些可观察量。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 升级时只动一个依赖版本，用 minmax_element 记录构建与运行结果。
- 升级后重点回归 STL 的默认值、警告信息与错误格式。
- 升级完成后记录 STL 的新旧版本差异，并据此调整下次复核时间。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 STL、vector | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「STL 容器与算法」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「STL 容器与算法」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:cpp`，用于动手验证《STL 容器与算法》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《STL 容器与算法》原文中的最小示例。先预测《STL 容器与算法》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```cpp
#include <vector>
#include <unordered_map>
#include <string>

std::vector<int> nums{3, 1, 2};
nums.push_back(4);
nums[0] = 9;

std::unordered_map<std::string, int> ages;
ages["小明"] = 18;
if (auto it = ages.find("小明"); it != ages.end()) {   // C++17 带初始化的 if
    std::cout << it->second;
}
```

**教材衔接：常用容器**

| 容器 | 结构 | 典型用途 |
| --- | --- | --- |
| `vector` | 动态数组 | 默认选择，随机访问快 |
| `array` | 固定数组 | 长度已知，无堆分配 |
| `deque` | 双端队列 | 两端频繁插入删除 |
| `list` | 双向链表 | 中间频繁插删 |
| `map` / `set` | 红黑树 | 有序、按 key 查找 |
| `unordered_map` / `unordered_set` | 哈希表 | 平均 O(1) 查找 |
| `stack` / `queue` | 容器适配器 | LIFO / FIFO |

```cpp
#include <vector>
#include <unordered_map>
#include <string>

std::vector<int> nums{3, 1, 2};
nums.push_back(4);
nums[0] = 9;

std::unordered_map<std::string, int> ages;
ages["小明"] = 18;
if (auto it = ages.find("小明"); it != ages.end()) {   // C++17 带初始化的 if
    std::cout << it->second;
}
```

**教材衔接：迭代器**

迭代器是容器与算法之间的统一接口。

```cpp
for (auto it = nums.begin(); it != nums.end(); ++it) {
    std::cout << *it << ' ';
}

nums.erase(std::remove(nums.begin(), nums.end(), 1), nums.end());  // erase-remove 惯用法
```

注意：修改容器结构（如 `push_back`）可能让迭代器失效。

## 时间/空间复杂度或性能分析

**复杂度证据**：本课正文出现 `O(1)`、`O(n)`、`O(log n)`、`O(n log n)` 等量级表达式；使用前要同时确认输入规模、最好/平均/最坏情况以及常数项来源。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「STL 容器与算法」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「STL 容器与算法」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《STL 容器与算法》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「STL 容器与算法」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：复杂度与常见坑**

| 容器 | 查找 | 插入 | 删除 | 备注 |
| --- | --- | --- | --- | --- |
| vector | O(n) | 尾部均摊 O(1) | 尾部 O(1) | 内存连续、缓存友好 |
| deque | O(n) | 两端 O(1) | 两端 O(1) | 分段连续 |
| list | O(n) | 已知位置 O(1) | 已知位置 O(1) | 缓存不友好，实际少用 |
| map/set | O(log n) | O(log n) | O(log n) | 红黑树，有序 |
| unordered_map/set | 平均 O(1) | 平均 O(1) | 平均 O(1) | 哈希，需自定义哈希时注意 |

四个高频坑：① **迭代器失效**（vector 扩容、erase 后继续用旧迭代器）；② **erase-remove 遗漏 erase**（remove 只移动元素不改变大小）；③ `map[key]` 会**默认构造**不存在的键（查询应用 find/at）；④ **自定义类型作 map 键**需提供严格弱序比较（operator< 要满足传递性，否则行为未定义）。

**教材衔接：常见错误与排查**

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

**教材衔接：故障现场**

### 现场 1：在 vector 上 erase 后继续用旧迭代器

**症状**：在《STL 容器与算法》的复现场景中，崩溃或跳过元素。

**根因**：触发点是把“在 vector 上 erase 后继续用旧迭代器”当成安全做法。它没有满足《STL 容器与算法》要求的前提，因此先表现为“崩溃或跳过元素”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《STL 容器与算法》的问题，用 it = v.erase(it) 接收返回值。

**验证**：在《STL 容器与算法》中按“用 it = v.erase(it) 接收返回值”调整后，从“在 vector 上 erase 后继续用旧迭代器”的触发条件重放同一条路径，确认“崩溃或跳过元素”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：循环中反复 v.push_back 并持有引用

**症状**：在《STL 容器与算法》的复现场景中，引用失效（扩容后悬空）。

**根因**：当出现“循环中反复 v.push_back 并持有引用”时，执行路径已经绕过了《STL 容器与算法》的关键约束，最终以“引用失效（扩容后悬空）”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《STL 容器与算法》的问题，扩容会让所有指针/引用失效；先 reserve 或改用下标。

**验证**：在《STL 容器与算法》中按“扩容会让所有指针/引用失效；先 reserve 或改用下标”调整后，从“循环中反复 v.push_back 并持有引用”的触发条件重放同一条路径，确认“引用失效（扩容后悬空）”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 3：map 用 operator[] 查询

**症状**：在《STL 容器与算法》的复现场景中，不存在时插入默认值，size 变大。

**根因**：“不存在时插入默认值，size 变大”只是表层结果。向上追溯会落到“map 用 operator[] 查询”这一步，因为它省略了《STL 容器与算法》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《STL 容器与算法》的问题，只读查询用 find / at。

**验证**：先在《STL 容器与算法》中记录“map 用 operator[] 查询”留下的失败证据，再执行“只读查询用 find / at”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《模板与泛型编程》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《现代 C++ 特性》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《模板与泛型编程》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《现代 C++ 特性》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「STL 容器与算法」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《STL 容器与算法》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

下面这段 C++ 代码摘自「STL 容器与算法」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？

```cpp
#include <algorithm>
#include <iostream>
#include <map>
#include <numeric>
#include <string>
#include <unordered_map>
#include <vector>

int main() {
    std::vector<int> nums{5, 3, 1, 4, 2};
    std::sort(nums.begin(), nums.end());                  // 排序
    auto it = std::find(nums.begin(), nums.end(), 4);     // 查找
    int sum = std::accumulate(nums.begin(), nums.end(), 0);
    std::cout << "和为 " << sum << "，找到 " << *it << '\n';

    // 统计词频：unordered_map 是首选
    std::unordered_map<std::string, int> freq;
    for (const auto& word : {"a", "b", "a", "c", "a"}) {
        ++freq[word];
    }
    for (const auto& [word, count] : freq) {
        std::cout << word << '=' << count << ' ';
    }
    std::cout << '\n';

    // 有序遍历用 map
    std::map<std::string, int> ordered(freq.begin(), freq.end());
    for (const auto& [word, count] : ordered) {
        std::cout << word << ':' << count << ' ';
    }
}
```

A. 这段代码只做静态声明，没有循环、分支或可观察输出。
B. 这段代码包含条件分支，不同输入会走不同的执行路径。
C. 这段代码包含循环结构，同一段逻辑会被重复执行。
D. 这段代码会读取外部输入，结果依赖传入的数据。

**参考答案**：这段代码包含循环结构，同一段逻辑会被重复执行。

**解析**：题干的正确项是这段代码包含循环结构，同一段逻辑会被重复执行，在「STL 容器与算法」里循环次数与STL的输入规模直接相关。这段代码出自「STL 容器与算法」的正文示例，围绕STL、vector、map展开；把输入或边界换成空值、极值或失败情况后，结论要以「STL 容器与算法」的实际运行结果为准。在「STL 容器与算法」里判断这道题，要把STL、vector、map的条件、过程与失败路径逐项对齐，换成“下面这段 C++ 代码摘自STL 容”这个场景，只有满足前提的结论才成立。

### 自测 2

围绕“STL 容器与算法”中的 STL、vector、map，下列哪两项是本课强调的实践判断？

A. 只要 STL 的常规示例通过，就可以跳过边界与异常路径
B. 验证 vector 时要固定版本并覆盖边界输入，结论才可复现
C. 把 vector 的单次运行结果当成所有版本和规模都成立
D. 学习 STL 时要同时说明输入、输出和失败路径，不能只看正常流程

**参考答案**：验证 vector 时要固定版本并覆盖边界输入，结论才可复现；学习 STL 时要同时说明输入、输出和失败路径，不能只看正常流程

**解析**：本课把STL 容器与算法拆成概念、示例与故障现场三部分，因此判断 STL 时必须同时交代输入、输出和失败路径，这使“学习 STL 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在STL 容器与算法里，判断 vector 时要固定版本与边界输入，所以“验证 vector 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 3

erase-remove 惯用法的作用是？

A. 对容器排序
B. 删除满足条件的元素
C. 清空容器
D. 去重并排序

**参考答案**：删除满足条件的元素

**解析**：在「STL 容器与算法」里，删除满足条件的元素。std::remove 把保留元素前移并返回新末尾，再用 erase 真正缩短容器。回到「STL 容器与算法」的正文示例，用“erase-remove 惯用法的作”走一遍STL、vector、map的完整流程，能复现的结论才可以保留。

**教材衔接：复习与自测**

- [ ] 默认选 `vector`，能说出 `map` 与 `unordered_map` 的取舍。
- [ ] 会写 `erase-remove` 惯用法删除元素。
- [ ] 知道哪些操作会让孩子迭代器 / 引用失效。
- [ ] 只读查询 `map` 时用 `find` 或 `at`，不用 `operator[]`。
- [ ] 记得 `accumulate` 的初始值类型决定结果类型。

**教材衔接：动手练习**

> 本课练习重点：围绕「STL、vector、map」完成复述、实验和交付，每个结果都要能被别人检查。

为 vector 打开内存检查工具跑一遍，确认没有越界与泄漏。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. STL 容器与算法解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「vector」是什么关系？

验收标准：回答里必须出现 STL，并写出一个让结论失效的边界条件。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：围绕「常用容器」小节做一次五步记录，原例取自 minmax_element，改动只允许动一处STL，原因要能指回正文的判断依据。

### 练习 3：交付一个小结果（30 分钟）

把 minmax_element 抽成一个单文件示例，在开启警告的编译选项下构建。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「STL」和「vector」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```cpp
#include <vector>
#include <unordered_map>
#include <string>

std::vector<int> nums{3, 1, 2};
nums.push_back(4);
nums[0] = 9;

std::unordered_map<std::string, int> ages;
ages["小明"] = 18;
if (auto it = ages.find("小明"); it != ages.end()) {   // C++17 带初始化的 if
    std::cout << it->second;
}
```

### 任务 2：只改一个条件

把「STL 容器与算法」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 vector 换成边界值，其他输入保持原样。
- 预测：先写下「STL 容器与算法」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响STL。

### 任务 3：迁移到自己的数据

把 minmax_element 换成你自己的输入，先保持步骤不变，再比较输出差异。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「没有特殊需求时，默认选择哪个容器？」的判断依据。
- [ ] 不看解析，能说出「需要按 key 快速查找且不要求有序，应该用？」的判断依据。
- [ ] 不看解析，能说出「erase-remove 惯用法的作用是？」的判断依据。
- [ ] 不看解析，能说出「std::map 与 std::unordered_map 的底层结构区别是？」的判断依据。
- [ ] 不看解析，能说出「下面哪种操作最容易让 vector 的迭代器失效？」的判断依据。
- [ ] 跑通「STL 容器与算法」的最小示例，并记录一次失败输入的处理方式。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

把「STL 容器与算法」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `STL` | STL 把「存数据」和「处理数据」分开。 |
| `vector` | C++ 标准库中的动态数组，连续存储元素并支持自动扩容。 |
| `迭代器` | STL 的价值在于容器 + 迭代器 + 算法三者解耦。 |
| `algorithm` | C++ 标准库算法头文件，提供排序、查找、变换和数值等泛型算法。 |

## 考点精讲

### 考点 1：代码补全·STL

- **题目**：下面这段 C++ 代码摘自「STL 容器与算法」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？
- **判断依据**：题干的正确项是这段代码包含循环结构，同一段逻辑会被重复执行，在「STL 容器与算法」里循环次数与STL的输入规模直接相关。这段代码出自「STL 容器与算法」的正文示例，围绕STL、vector、map展开；把输入或边界换成空值、极值或失败情况后，结论要以「STL 容器与算法」的实际运行结果为准。在「STL 容器与算法」里判断这道题，要把STL、vector、map的条件、过程与失败路径逐项对齐，换成“下面这段 C++ 代码摘自STL 容”这个场景，只有满足前提的结论才成立。

### 考点 2：多选辨析·STL

- **题目**：围绕“STL 容器与算法”中的 STL、vector、map，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把STL 容器与算法拆成概念、示例与故障现场三部分，因此判断 STL 时必须同时交代输入、输出和失败路径，这使“学习 STL 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在STL 容器与算法里，判断 vector 时要固定版本与边界输入，所以“验证 vector 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 3：概念判断·STL

- **题目**：erase-remove 惯用法的作用是？
- **判断依据**：在「STL 容器与算法」里，删除满足条件的元素。std::remove 把保留元素前移并返回新末尾，再用 erase 真正缩短容器。回到「STL 容器与算法」的正文示例，用“erase-remove 惯用法的作”走一遍STL、vector、map的完整流程，能复现的结论才可以保留。

### 考点 4：概念判断·STL

- **题目**：std::map 与 std::unordered_map 的底层结构区别是？
- **判断依据**：在「STL 容器与算法」里，结论应落在「map 通常用红黑树（有序）」。需要按 key 顺序遍历时选 map，只追求平均查找速度时选 unorderedmap。在「STL 容器与算法」里，这道题要求区分概念与边界，「map 通常用红黑树（有序）」只有在题干给出的前提下才成立，而「两者底层都是数组」、「map 用哈希表，unordered_map 用树」缺少同一组条件。

### 考点 5：概念判断·STL

- **题目**：下面哪种操作最容易让 vector 的迭代器失效？
- **判断依据**：在「STL 容器与算法」里，插入元素触发扩容。删除元素常用 it = v.erase(it) 接收返回的新迭代器来避免悬空。这道题的关键在「STL 容器与算法」的STL、vector、map：先确认题干“下面哪种操作最容易让 vector”问的是哪一步，再排除偷换前提的选项。把“插入元素触发扩容”代回「STL 容器与算法」里“下面哪种操作最容易让 vector 的迭代器失效”的例子核对，条件一旦改变，结论就要用STL、vector、map重新推导。

### 考点 6：填空·STL

- **题目**：补全代码：「STL 容器与算法」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `v.____(2); // 原地构造，少一次移动`
- **判断依据**：空格应填写「emplace_back」。在「STL 容器与算法」里判断这道题，要把STL、vector、map的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。“容器与算法示例中”与「STL 容器与算法」的术语表相呼应，只有符合STL、vector、map约束的“emplaceback”才是正文支持的结论。

## English Overview

**Title:** STL Containers & Algorithms

**Summary:** Containers, iterators, algorithms and erase-remove.

**Category:** C++
**Level:** 进阶
**Key terms:** STL, vector, map, unordered_map, 迭代器, algorithm

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：C++20 / GCC 13+ 或 Clang 17+；本课聚焦 STL。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：STL、vector、map、unordered_map、迭代器、algorithm
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-05-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [cppreference 标准库](https://en.cppreference.com/w/cpp/standard_library) | 标准库组件索引 |
| [C++ 内存管理](https://en.cppreference.com/w/cpp/memory) | RAII、智能指针与所有权 |
| [CMake 文档](https://cmake.org/documentation/) | 跨平台构建与依赖管理 |

> 「STL 容器与算法」的链接用于离线阅读后的延伸核对；App 不会自动联网。
