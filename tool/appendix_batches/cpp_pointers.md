## 指针与引用速查

| 概念 | 写法 | 能否为空 | 能否改指向 | 说明 |
| --- | --- | --- | --- | --- |
| 对象 | `T obj;` | 否 | 不适用 | 优先使用 |
| 引用 | `T& r = obj;` | 否 | 否 | 使用像对象，必须初始化 |
| 常量引用 | `const T& r = obj;` | 否 | 否 | 传参首选 |
| 指针 | `T* p = &obj;` | 是 | 是 | 需要可空或可改指向时用 |
| 常量指针 | `T* const p = &obj;` | 是 | 否 | 指针本身不可改 |
| 指向常量 | `const T* p = &obj;` | 是 | 是 | 不能通过 p 改值 |

```cpp
#include <memory>
#include <vector>

void scale(std::vector<int>& data, int factor) {   // 引用：必定非空
    for (int& value : data) value *= factor;
}

// 现代 C++：动态对象用智能指针，不用裸 new
std::unique_ptr<int> makeValue(int v) {
    return std::make_unique<int>(v);
}

// 只读观察用指针表示「可能没有」
void print(const std::string* name) {
    if (name != nullptr) {
        std::cout << *name << '\n';
    }
}
```

## 数组与指针速查

| 写法 | 含义 | 风险 |
| --- | --- | --- |
| `int a[5];` | 栈上固定数组 | 越界不会检查 |
| `int* p = a;` | 数组退化为指针 | 丢失长度信息 |
| `std::array<int,5> a;` | 固定大小容器 | 推荐替代裸数组 |
| `std::vector<int> v;` | 动态数组 | 首选 |
| `std::span<int> s` | 连续内存视图 | C++20，注意生命周期 |
| `sizeof(a) / sizeof(a[0])` | 求数组长度 | 退化后失效 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 使用未初始化的指针 | 随机崩溃 | 定义就初始化为 `nullptr` |
| `delete` 后继续使用 | 悬空指针 | 置 `nullptr` 或用智能指针 |
| 忘记释放 `new` 出的对象 | 内存泄漏 | 用 `unique_ptr` / `shared_ptr` |
| 返回局部变量地址 | 悬空指针 | 按值返回或返回智能指针 |
| `p + 1` 越界访问 | 未定义行为 | 用 `vector` 与迭代器，注意边界 |
| 用 `==` 比较 C 字符串 | 比较的是地址 | 用 `std::string` 或 `strcmp` |
| 传数组给函数并 `sizeof` | 得到指针大小 | 额外传长度或用 `std::span` |
| 引用绑定临时对象后长期保存 | 悬空引用 | 值接收或延长生命周期 |
| 空指针解引用 | 段错误 | 使用前判空，或用引用表达非空 |
| 多层指针 `T**` | 复杂度高、易错 | 用容器、智能指针或引用替代 |

## 自测清单

- [ ] 默认用对象与引用，只有需要可空或改指向时才用指针。
- [ ] 动态对象一律用智能指针管理。
- [ ] 指针使用前判空，删除后置空。
- [ ] 不再手工计算数组长度，改用容器与 `span`。
- [ ] 能分清 `const T*` 与 `T* const`。
