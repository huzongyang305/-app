## 智能指针选型速查

| 指针 | 所有权 | 拷贝 | 典型用途 | 注意点 |
| --- | --- | --- | --- | --- |
| `T obj` / `T* p` | 无（裸指针不拥有） | 任意 | 观察、传参（能不用指针就不用） | 生命周期由人保证，容易悬空 |
| `std::unique_ptr<T>` | 独占 | 禁止，只能 `std::move` | 工厂返回值、类成员独占资源 | 零额外开销，默认首选 |
| `std::shared_ptr<T>` | 共享（引用计数） | 允许 | 多方共同持有、异步回调 | 有计数开销，小心循环引用 |
| `std::weak_ptr<T>` | 不增加计数 | 允许 | 打破 `shared_ptr` 环、缓存观察 | 用前必须 `lock()` 并判空 |
| `std::string` / `std::vector` | 独占且自带 RAII | 深拷贝（可按需 move） | 绝大多数数据容器 | 优先用它替代手工 `new[]` |

创建与转换速查：

```cpp
auto p = std::make_unique<Widget>(1, 2);   // C++14 起推荐写法，异常安全
std::shared_ptr<Widget> s = std::make_shared<Widget>(1, 2);
std::weak_ptr<Widget> w = s;               // 只观察，不增加计数

if (auto locked = w.lock()) {              // 使用前提升为 shared_ptr
    locked->draw();
}

std::unique_ptr<Widget> moved = std::move(p);  // 转移所有权，p 变为 nullptr
std::shared_ptr<Widget> shared2 = std::move(moved); // unique -> shared 也可
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `new` 之后某条分支提前 `return` | 内存泄漏 | 用智能指针或容器管理，让析构自动执行 |
| `new` / `delete` 与 `malloc` / `free` 混用 | 未定义行为，可能崩溃 | 严格配对：`new` 对 `delete`，`malloc` 对 `free` |
| 两个 `shared_ptr` 各自 `shared_ptr<T>(raw)` | 双重释放 | 只能从一次 `make_shared` 或另一个 `shared_ptr` 复制 |
| `shared_ptr` 互相持有 | 引用计数永不归零，内存泄漏 | 其中一侧改成 `weak_ptr` |
| 返回局部变量的引用或指针 | 悬空引用，行为未定义 | 按值返回，或返回智能指针 / 容器 |
| `std::move` 之后再使用源对象 | 值不确定 | move 后只能重新赋值或销毁，不能读值 |
| 用 `std::vector<T*>` 存 `new` 出来的对象 | 容器销毁不释放元素 | 存 `std::unique_ptr<T>` 或直接存值 |
| 自定义类持有裸指针成员却不写析构 | 泄漏或重复释放 | 优先用成员对象 / 智能指针，遵循 Rule of Zero |
| `delete` 后指针仍被使用 | 悬空指针，随机崩溃 | `delete` 后置 `= nullptr`，或用智能指针 |
| 大对象按值传参 | 多余拷贝，性能下降 | 只读传 `const T&`，需要转移时按值 + `std::move` |

## 工具速查

| 工具 | 能发现的问题 | 使用方式 |
| --- | --- | --- |
| `-fsanitize=address`（ASan） | 越界、UAF、内存泄漏 | 编译加参数后运行程序 |
| `-fsanitize=undefined`（UBSan） | 整数溢出、空指针解引用等 UB | 常与 ASan 同时开启 |
| `valgrind --leak-check=full` | 泄漏、非法访问（无需重编译） | 运行变慢，适合调试 |
| `-Wall -Wextra` | 未使用变量、可疑比较 | 编译期即可发现 |
| `clang-tidy` | 现代 C++ 反模式、可读性问题 | 静态检查，接入 CI |

## 自测清单

- [ ] 能说明 `unique_ptr`、`shared_ptr`、`weak_ptr` 的所有权差异。
- [ ] 创建共享对象时使用 `make_shared`，不用裸 `new`。
- [ ] 知道 `shared_ptr` 循环引用要用 `weak_ptr` 打破。
- [ ] 记得 `std::move` 之后源对象只能重新赋值。
- [ ] 调试内存问题时知道用 ASan 或 Valgrind。
