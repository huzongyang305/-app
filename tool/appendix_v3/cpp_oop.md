## 零基础详解：类、封装、继承与多态

### 一句话说清它是什么

类把数据和操作打包，封装控制谁能访问，继承表达「是一种」，多态让同一句调用在不同对象上产生不同行为。
C++ 的多态有一个关键前提：**基类函数必须是 `virtual`**。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 类与对象 | 图纸与实物 | 图纸只有一份，实物可以很多 |
| 封装 | 仪器外壳 | 只留按钮，内部不让人乱动 |
| 继承 | 家族血脉 | 子类天然拥有父类的公开能力 |
| 虚函数 | 统一接口 | 同一句「叫一声」，猫喵狗汪 |
| 虚析构 | 归还整套工具 | 用基类指针删除时才能完整析构 |

### 三件必写的东西

```cpp
#include <iostream>
#include <memory>
#include <string>

class Shape {
public:
    explicit Shape(std::string name) : name_(std::move(name)) {}

    // 1. 有虚函数就必须有虚析构
    virtual ~Shape() = default;

    // 2. 接口用纯虚函数，形成抽象类
    virtual double area() const = 0;

    // 3. 共性实现放基类
    const std::string& name() const { return name_; }

    virtual void describe() const {
        std::cout << name_ << " 面积 " << area() << '\n';
    }

private:
    std::string name_;                 // 私有：外部不能直接改
};

class Circle : public Shape {
public:
    explicit Circle(double r) : Shape("圆形"), r_(r) {}
    double area() const override { return 3.14159 * r_ * r_; }

private:
    double r_;
};
```

| 关键字 | 作用 |
| --- | --- |
| `explicit` | 禁止隐式转换，避免意外构造 |
| `virtual` | 允许运行时按实际类型调用 |
| `= 0` | 纯虚函数，基类不能实例化 |
| `override` | 让编译器检查是否真的重写成功 |
| `= default` | 使用编译器生成的实现 |

### 多态是怎么发生的

```cpp
std::vector<std::unique_ptr<Shape>> shapes;
shapes.push_back(std::make_unique<Circle>(2.0));

for (const auto& s : shapes) {
    s->describe();        // 实际调用 Circle::area，这就是多态
}
```

前提是**通过指针或引用调用虚函数**。如果把对象按值赋给基类，会发生「对象切片」，多态失效。

### 值语义：三或五法则

```cpp
class Buffer {
public:
    explicit Buffer(std::size_t n) : size_(n), data_(new char[n]) {}
    ~Buffer() { delete[] data_; }                        // 1. 析构
    Buffer(const Buffer& other)                           // 2. 拷贝构造
        : size_(other.size_), data_(new char[other.size_]) {
        std::copy(other.data_, other.data_ + size_, data_);
    }
    Buffer& operator=(const Buffer& other) {              // 3. 拷贝赋值
        if (this != &other) {
            auto tmp = std::make_unique<char[]>(other.size_);
            std::copy(other.data_, other.data_ + other.size_, tmp.get());
            delete[] data_;
            data_ = tmp.release();
            size_ = other.size_;
        }
        return *this;
    }
    Buffer(Buffer&&) noexcept = default;                  // 4. 移动构造
    Buffer& operator=(Buffer&&) noexcept = default;       // 5. 移动赋值

private:
    std::size_t size_;
    char* data_;
};
```

**更省事的做法**：直接用 `std::vector` 或 `std::string`，让标准库替你处理这一切。

### 继承 vs 组合

| 场景 | 选择 | 原因 |
| --- | --- | --- |
| 「是一种」关系 | 公有继承 | 例如 Circle 是一种 Shape |
| 「有一个」关系 | 组合 | 例如 Car 有一个 Engine |
| 只想复用代码 | 组合 | 继承会带来强耦合 |
| 需要运行时多态 | 继承 + 虚函数 | 或考虑 `std::variant` 等替代方案 |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 基类析构不是虚的 | 删除时子类资源泄漏 | 加 `virtual ~Base() = default` |
| 忘了 `override` | 拼错签名变成新函数 | 一律写 `override` |
| 按值传递基类对象 | 对象切片，多态失效 | 用 `Shape&` 或 `Shape*` |
| 在构造函数里调虚函数 | 不会走到子类实现 | 构造完再调用 |
| 友元滥用 | 破坏封装 | 优先提供公开方法 |
| 多重继承菱形问题 | 数据重复、二义性 | 用虚继承或改用组合 |
| 忘了 `const` | 常量对象无法调用 | 不改成员的函数加 `const` |
| 手写拷贝却忘了深拷贝 | 双重释放 | 用容器或智能指针 |

### 手把手练习：员工薪资多态

```cpp
#include <iomanip>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

class Employee {
public:
    explicit Employee(std::string name) : name_(std::move(name)) {}
    virtual ~Employee() = default;
    virtual double monthlyPay() const = 0;

    void print() const {
        std::cout << std::setw(8) << name_ << " 月薪 "
                  << std::fixed << std::setprecision(2)
                  << monthlyPay() << '\n';
    }

private:
    std::string name_;
};

class Salaried : public Employee {
public:
    Salaried(std::string name, double monthly)
        : Employee(std::move(name)), monthly_(monthly) {}
    double monthlyPay() const override { return monthly_; }

private:
    double monthly_;
};

class Hourly : public Employee {
public:
    Hourly(std::string name, double rate, double hours)
        : Employee(std::move(name)), rate_(rate), hours_(hours) {}
    double monthlyPay() const override { return rate_ * hours_; }

private:
    double rate_, hours_;
};

int main() {
    std::vector<std::unique_ptr<Employee>> staff;
    staff.push_back(std::make_unique<Salaried>("小明", 12000));
    staff.push_back(std::make_unique<Hourly>("小红", 80, 160));

    double total = 0;
    for (const auto& e : staff) {
        e->print();
        total += e->monthlyPay();
    }
    std::cout << "合计 " << total << '\n';
}
```

### 学完自测

- [ ] 能解释虚函数与多态的关系。
- [ ] 知道为什么有虚函数就要有虚析构。
- [ ] 能说出对象切片是怎么发生的。
- [ ] 能判断一个场景该用继承还是组合。
- [ ] 知道三或五法则分别指哪几个函数。
