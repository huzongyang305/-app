# Memory Management & Smart Pointer

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: progress

## Learning objectives

- It is possible to explain in its own words what memory management and intelligence pointers solve, not just the term.
- The relationship between memory, RAII, unique_ptr and shared_pstr is clear.
- It's a good way to put this subject back into the "C++" knowledge system, which shows how it borders on adjacent themes.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentences: stacks and piles, RAII, unique_ptr/shared_pr/weak_ptri and memory problems.

## Pre-knowledge

- The first lesson, " Pointers and Quotes " , is completed; if available, this course can be used for self-examination.
- This course stage: Progress. It is recommended to have a basic curriculum for the same classification and to be able to run the smallest examples in the text independently.
- Read it first: Memory, RAII, unque_ptr.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Stacks and stacks

```cpp
void demo() {
    int stack_value = 1;             // 栈：自动分配、离开作用域自动释放
    int* heap_value = new int(2);    // 堆：手动申请
    delete heap_value;               // 必须手动释放，否则内存泄漏
    heap_value = nullptr;            // 释放后置空，避免悬垂指针
}
```

The array should be paired with ⟦0/ 1:

```cpp
int* arr = new int[10];
delete[] arr;
```

## RAII: Resource management thinking for C++

** Access to resources is initialized.**: Linking the resource ' s life cycle into that of an object, and a solvency function is automatically released. It serves as a common basis for intelligence points, locks, document flows.

```cpp
class FileHandle {
public:
    explicit FileHandle(const char* path) : file_(std::fopen(path, "r")) {}
    ~FileHandle() { if (file_) std::fclose(file_); }

    FileHandle(const FileHandle&) = delete;             // 禁止拷贝
    FileHandle& operator=(const FileHandle&) = delete;
private:
    std::FILE* file_;
};
```

## Three Smart Pointers

```cpp
#include <memory>

// 独占所有权：不能拷贝，只能移动
std::unique_ptr<int> u = std::make_unique<int>(10);
std::unique_ptr<int> u2 = std::move(u);

// 共享所有权：引用计数为 0 时释放
std::shared_ptr<int> s = std::make_shared<int>(20);
std::shared_ptr<int> s2 = s;          // 计数变为 2
std::cout << s.use_count();

// 弱引用：不增加计数，用于打破循环引用
std::weak_ptr<int> w = s;
if (auto locked = w.lock()) {
    std::cout << *locked;
}
```

Select order: ⟦ 0,  1 and  2 if you need to share.

## Common memory problems

|Problem|Annotations|
| --- | --- |
|Memory Leak|♪ And then forget about 1 or 2 ♪|
|Suspended Pointer|The object is still in use|
|Repeated release|Same memory.|
|Cross-border visits|The subscript goes beyond the array|

## rule of zero / three / five

- **rule of Zero**: do not write resolution, copy and move functions when no manual management is required.
- **rule of three**: One of the values that require a customized analysis, copy construction and copying is usually required.
- **rule of five**: Add mobile structures and moving values.

## Queries

```bash
g++ -fsanitize=address,undefined -g main.cpp -o main   # ASan + UBSan
valgrind --leak-check=full ./main                      # Linux
```

## It's the end of this class.
The modern C++ principle is that** can use a stack and an intelligent pointer without new/delete**, leaving RAII in charge of releasing memory problems to the type system.

<!-- appendix:v1 -->

## Smart Pointer Spacing

|Pointer|Ownership|Copy|Typical uses|Watch it.|
| --- | --- | --- | --- | --- |
| `T obj` / `T* p` |No (near pointers not owned)|Any|Observe, communicate.|Life cycle is guaranteed. It's easy to hang out.|
| `std::unique_ptr<T>` |Occupy.|It's forbidden.|Return value, category exclusive resources|Zero extras, default first|
| `std::shared_ptr<T>` |Share (reference count)|Allow|We've got a lot of things going on here.|I've got expenses. Be careful with the recitation.|
| `std::weak_ptr<T>` |No more count.|Allow|Breaking Zero Rings, Cache Watch|We're gonna have to use it before we get there.|
| `std::string` / `std::vector` |Exclusive and self-contained.|In-depth copy (move as required)|Most data containers|I'd like you to replace it with a hand job.|

_Other Organiser

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

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
|♪ And then one branch ahead ♪|Memory Leak|Management with smart pointer or container, auto-execution|
|⟦0/ 1 with 2 3|Undefined behaviour, possible collapse|Tight match: 123|
|Two, zero, one each.|Double release.|I can only copy it from ⟦0 or another one.|
|I'll hold on to it.|Quote never zero, memory leak.|Turn one side to zero.|
|Return local variable reference or pointer|Suspended references, behaviour not defined|Returns by value, or smart pointer / container|
|Use source object after ⟦0|I don't know.|Move can only be revalued or destroyed, not readable|
|We're gonna use a zero, we're going to save one.|Containment destruction of non-release elements|Save ⟦ or directly|
|The custom class has a nudity pointer, but it doesn't work.|Leaking or repeated releases|Prioritize the member objects / smart pointer, following Rule of Zero|
|The posterior is still in use.|Suspended pointers, random collapses.|Zero, back one, or a smart pointer.|
|Large object by value transfer|It's an extra copy, it's down.|Read-only ⟦0, at value of + ⟦1|

## Quick check.

|Tools|It's a problem.|Usage|
| --- | --- | --- |
| `-fsanitize=address`（ASan） |Cross-border, UAF, memory leaks|Run the program after adding parameters|
| `-fsanitize=undefined`（UBSan） |Integer spill, empty pointer citation, etc.|Always open with Asan.|
| `valgrind --leak-check=full` |Leakage, illegal access (does not require re-translation)|Slower, fit for debugging|
| `-Wall -Wextra` |Unused Variables, Suspicious Comparison|We'll find out.|
| `clang-tidy` |Modern C++ Anti-Model, Readability Issues|Static check, access to CI.|

## Self-Detected List

- [ ] Describes the difference in ownership between ⟦,  and .
- [ ] When creating the shared object, use ⟦0 and not nudium1⟧.
- [ Chuckles ] Know that the loop reference is to be broken with a twilight.
- [ ] Remember that the source object can only be revalued after ⟦0.
- [ ] Debug memory to use ASan or Valgrind.

<!-- appendix:v3 -->

## Zero-basic details: stack, pile and RAII

### What is it?

The memory of the program is divided into several areas, most commonly ** (automated management, speed, small space) and ** stacks (manual applications, large spaces that need to be managed).
RAII is the core idea for managing resources:** The life cycle of resources is tied to targets.**

### It's a life metaphor.

|Regional|A metaphor.|Features|
| --- | --- | --- |
|Inn.|The fast-food tray.|Take it, take it out of the house. It's limited in capacity.|
|Stack|Self-leased warehouse|You need to apply for it and you lose the rent. It's too much space to forget.|
|Static Area|Fixed assets of the company|The program is in place until it's over.|
|Constant|It's an engraving.|Read-only, for example|
| RAII |Hosting services for automatic renewal|Automatically release resources at object destruction|

### Bark-to-Package

|Contrast|Inn.|Stack|
| --- | --- | --- |
|Distribution speed|Extremely fast (mobile pointer)|Slower.|
|Life cycle|Automatically released from the field|Manual or Smart Pointer Management|
|Space Size|What's your average MB?|Limited to Available Memory|
|Typical| `int x = 1;` |Zero or one.|
|Common questions|It's too deep.|Leaks, hangers, pieces.|

### A code that sees the life cycle.

```cpp
#include <iostream>
#include <string>

struct Tracer {
    std::string name;
    explicit Tracer(std::string n) : name(std::move(n)) {
        std::cout << "构造 " << name << '\n';
    }
    ~Tracer() {
        std::cout << "析构 " << name << '\n';   // 离开作用域自动执行
    }
};

void demo() {
    Tracer a("a");
    {
        Tracer b("b");
    }                       // 先析构 b
    Tracer c("c");
}                           // 再析构 c，最后析构 a

int main() { demo(); }
```

The order of output reflects two rules:** the structure of the post-deposition**,** the composition of the function**.

### RAII: Resources entrusted to the subject

```cpp
#include <fstream>
#include <memory>
#include <mutex>

{
    std::ofstream file("out.txt");       // 构造时打开
    file << "hello\n";
}                                        // 析构时自动关闭

{
    std::lock_guard<std::mutex> lock(mtx);   // 构造时加锁
    // 临界区
}                                        // 析构时自动解锁

auto buf = std::make_unique<char[]>(1024);   // 独占所有权
// 函数结束自动释放，不需要 delete
```

|Resources|Recommended management|
| --- | --- |
|Dynamic Memory| `unique_ptr` / `shared_ptr` |
|Documentation| `std::fstream` |
|Crossing the lock.| `lock_guard` / `unique_lock` |
|Numeric| `std::vector` / `std::array` |
|Handwritten ⟦0=1|Try to avoid it.|

### Three Smart Pointers

|Pointer|Ownership|Can you copy it?|Typical uses|
| --- | --- | --- | --- |
| `unique_ptr` |Occupy.|Cannot (moveable)|** Default selection**|
| `shared_ptr` |Share, quote count|Yes.|Multiplely share objects|
| `weak_ptr` |No more count.| —— |Break Zero Cyclops|

```cpp
auto p = std::make_unique<int>(5);
auto q = std::move(p);          // 所有权转移，p 变成 nullptr

auto s1 = std::make_shared<int>(7);
auto s2 = s1;                   // 引用计数变为 2
std::cout << s1.use_count();    // 2
```

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|I'll forget about it.|Memory Leak|Use a smart pointer.|
|Return pointer for local objects|Suspended Reference|Return value or smart pointer|
|⟦Cyclical Reference|I'll never go back to zero.|We'll change it to a zero.|
|Massive Recursion|Spills|Recycle or increase the stack.|
|Save reference in container|It's not working.|Index or Smart Pointer|
|The old pointer's not working.|Data Fault|I'll leave it to you.|
|A handwritten copy, but a deep copy.|Double release.|Follow three or five rules, or use a smart pointer.|
|Send Big Object By Value|Frequent copies|Use Zero.|

### Handheld practice: Pack a simple resource with RAII

```cpp
#include <iostream>
#include <string>

class FileHandle {
public:
    explicit FileHandle(const std::string& name) : name_(name) {
        std::cout << "打开 " << name_ << '\n';
    }
    ~FileHandle() {
        std::cout << "关闭 " << name_ << '\n';
    }
    FileHandle(const FileHandle&) = delete;             // 不允许复制
    FileHandle& operator=(const FileHandle&) = delete;

private:
    std::string name_;
};

int main() {
    FileHandle f("data.txt");
    std::cout << "处理中……\n";
    // 即使这里抛异常，f 的析构也会执行
}
```

### Learn how to measure yourself.

- [ Laughs ] Can tell the difference between stacks and piles.
- [ ] Can explain the core ideas of RAII.
- [ Chuckles ] Knows the trade-off with the one.
- [ ] Can you tell me what the three smart points are for each other?
- [ ] Know why "construction is the opposite of composition."

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeat, experiment and deliver around "RAM, RAII, UNique_ptr" with each result subject to scrutiny.

Start with the minimum program to compile warnings, then verify memory and boundaries, and run it again in Sanitizer.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with Memory Management and Smart Pointers?
2. Without it, what concrete consequences would there be?
3. What's it got to do with RAII?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Write a program that can be compiled on its own, open ⟦ and make sure there is no warning.

Mission requests:

- The result must be checked, not just “I understand”.
- This post is part of our special coverage Syria Protests 2011.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Memory & Smart Pointers

**Summary:** Stack vs heap, RAII, smart pointers and memory bugs.

**Category:** C++  
**Level:** Progress
**Key terms:** Memory, RAII, unque_ptr, shared_pstr

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: progress
- Applicable environment: C+20/GMC 13+ or Clang 17+
- Source: Internal structured curriculum and engineering practices
- Related themes: memory, RAII, unique_ptr, shared_pstr
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Memory & Smart Pointers** focuses on Stack vs heap, RAII, smart pointers and memory bugs.

### Learning Outcomes

- Explain what **Memory & Smart Pointers** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **Memory & Smart Pointers**
- Relaid terms: Memory, RAII, UNque_ptr, shared_pst
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Stacks and stacks|Stacks and stacks|
|RAII: Resource management thinking for C++|RAII: Resource management thinking for C++|
|Three Smart Pointers|Three Smart Pointers|
|Common memory problems|The usual memolly problem.|
| rule of zero / three / five | rule of zero / three / five |
|Queries|Check Tools|
|It's the end of this class.| Summary |
|Smart Pointer Spacing|Smart Pointer Spacing|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

