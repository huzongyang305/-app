## 零基础详解：分支、循环与函数的配合方式

### 一句话说清它是什么

函数负责「把问题拆小」，分支负责「不同情况走不同路」，循环负责「重复做同一件事」。
这三样凑齐，就能写出结构清晰的程序。

### 三种循环怎么选

| 循环 | 适合场景 | 特点 |
| --- | --- | --- |
| `for` | 次数明确、遍历容器 | 初始化、条件、更新写在一行 |
| `while` | 不知道循环几次，靠条件停 | 条件为假一次都不执行 |
| `do...while` | 至少要执行一次 | 先做后判断，例如重试输入 |

```cpp
// 遍历容器：现代写法，不用管下标
for (const auto& item : items) {
    std::cout << item << '\n';
}

// 重试输入：至少问一次
int n = 0;
do {
    std::cout << "请输入 1~100：";
    std::cin >> n;
} while (n < 1 || n > 100);
```

### `switch` 与 `if` 的取舍

| 情况 | 用哪个 |
| --- | --- |
| 判断范围、组合条件 | `if / else if` |
| 对一个整数或枚举的多个固定值分流 | `switch` |
| 分支很多且各自逻辑较长 | `switch` + 抽函数 |

```cpp
switch (grade) {
    case 'A':
        std::cout << "优秀\n";
        break;              // 忘了 break 会「穿透」到下一个分支
    case 'B':
        std::cout << "良好\n";
        break;
    default:
        std::cout << "未知等级\n";
        break;
}
```

### 函数：值传递、引用传递、常量引用

| 传参方式 | 写法 | 是否拷贝 | 能否修改原值 | 什么时候用 |
| --- | --- | --- | --- | --- |
| 值传递 | `void f(int x)` | 拷贝 | 不能 | 小类型、只读 |
| 引用传递 | `void f(int& x)` | 不拷贝 | 能 | 需要把结果写回 |
| 常量引用 | `void f(const Foo& x)` | 不拷贝 | 不能 | 传大对象只读，**首选** |
| 指针传递 | `void f(Foo* p)` | 拷贝指针 | 能 | 允许为空、需要改指向 |

```cpp
void addOne(int x)  { x += 1; }        // 改了副本，外面不变
void addOne(int& x) { x += 1; }        // 改了本体，外面跟着变

int n = 1;
addOne(n);
std::cout << n;                        // 2
```

### 声明与定义：编译器和链接器各管一段

```cpp
// 声明：告诉编译器「有这么个函数」
int add(int a, int b);

// 定义：告诉链接器「它的实现在这里」
int add(int a, int b) { return a + b; }
```

多文件项目里，声明放头文件、定义放源文件，这是 C++ 的基本分工。

### 函数重载与默认参数

```cpp
void print(int n);
void print(const std::string& s);      // 同名不同参：重载

void greet(const std::string& name = "朋友");   // 默认参数
greet();          // 朋友
greet("小明");    // 小明
```

重载靠参数列表区分，**返回值不同不算重载**；默认参数要写在声明处，别在声明和定义里各写一次。

### 新手最容易踩的六个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| `if (a = b)` | 赋值被当成条件，永远为真 | 写 `if (a == b)`，或把常量写左边 |
| 循环条件写死 | 程序卡住 | 检查循环变量是否真的在变化 |
| `continue` 与 `break` 混用 | 逻辑提前结束 | `break` 跳出整体，`continue` 只跳本轮 |
| 忘了 `return` | 返回值是随机值 | 有返回类型的函数所有分支都要返回 |
| 递归没有终止条件 | 栈溢出崩溃 | 先写终止条件，再写递归调用 |
| 函数太长 | 难以阅读和测试 | 超过一屏就按职责拆分 |

### 手把手练习：判断成绩等级并统计

```cpp
#include <iostream>
#include <vector>

char levelOf(int score) {
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 60) return 'C';
    return 'D';
}

int main() {
    std::vector<int> scores{95, 82, 60, 41};
    int aCount = 0;
    for (int s : scores) {
        const char level = levelOf(s);
        if (level == 'A') ++aCount;
        std::cout << s << " -> " << level << '\n';
    }
    std::cout << "A 等级共 " << aCount << " 人\n";
    return 0;
}
```

### 学完自测

- [ ] 能说出三种循环各自最适合的场景。
- [ ] 能解释 `switch` 里漏写 `break` 会发生什么。
- [ ] 能说清值传递和引用传递的区别。
- [ ] 知道声明和定义分别解决什么问题。
- [ ] 能把一个 50 行的 `main` 拆成 3 个小函数。
