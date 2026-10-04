## 零基础详解：STL 容器、迭代器与算法

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
