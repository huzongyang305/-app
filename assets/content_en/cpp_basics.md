# C++ Environment and compilation process

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Foundation = Projected duration: 15 minutes

## Learning objectives

- It is possible to explain in its own words what "environment and the process of translation" solves, not just a term.
- The relationship between "C++", "g++," "compilation" and "links" is clarified, with one example.
- It's a good way to put this subject back into the "C++" knowledge system, which shows how it borders on adjacent themes.
- It is possible to complete this course and check its results using acceptance standards.

> Synopsis of a sentence: Pre-processed compilation links, head files and naming spaces.

## Pre-knowledge

- The basic file, command line or browser operation is performed; the key words of this course are checked first when there are unfamiliar terms.
- This course stage: Foundation. It is recommended to read and write simple codes or commands, with basic concepts such as variables, input output, etc.
- Review before starting: C++, g++, compile.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## From Source to Executable

```text
hello.cpp
   ↓ 预处理（展开 #include、#define，生成 .i）
   ↓ 编译（翻译成汇编，生成 .s）
   ↓ 汇编（生成目标文件 .o / .obj）
   ↓ 链接（合并目标文件与库，生成可执行文件）
hello.exe
```

Understanding this chain explains a number of problems: the definition of function is not found** in error in connection with links, grammatical issues** and macro-expanding occurs during preprocessing**.

## First program.

```cpp
#include <iostream>      // 输入输出流

int main() {             // 程序入口，返回 int
    std::cout << "Hello, C++!" << std::endl;
    return 0;            // 0 表示正常退出
}
```

_Other Organiser

```bash
g++ -std=c++20 -Wall -Wextra -O2 hello.cpp -o hello
./hello

clang++ -std=c++20 hello.cpp -o hello     # Clang
cl /std:c++20 /EHsc hello.cpp             # MSVC
```

Common options: ⟦0 specify the standard, 1 open the warning and 2 optimise it to generate debugging information.

## Headers and Sources

```cpp
// math_utils.h —— 声明
#pragma once
int add(int a, int b);

// math_utils.cpp —— 定义
#include "math_utils.h"
int add(int a, int b) { return a + b; }

// main.cpp
#include <iostream>
#include "math_utils.h"
int main() { std::cout << add(1, 2); }
```

Agreed:** Declare headers, define release files; headers are used to prevent repetition of inclusion.

## Namespace and Standard Library

```cpp
#include <iostream>
#include <string>

namespace app {
    std::string name = "demo";
}

int main() {
    std::cout << app::name << '\n';
    // 不推荐在头文件里写 using namespace std;
}
```

## Common pits

1. The C++ returns zero when it is forgotten, but the other functions with a return value do not write ⟦2 as an undefined act.
2. Defines the global variable in the header file, which leads to multiple definitions using ⟦0 or 1 declarations.
3. The basic type of variable that is not initialized is random and must be initiated in a visible manner.

## It's the end of this class.
"Pre-processing, compilation and link" in four steps with a zero that eliminates many problems ahead of time.

<!-- appendix:v1 -->

## Quick check of the compilation process

|Phase|Enter|Output|Common questions|
| --- | --- | --- | --- |
|Pre-treatment|+ Header|Source after Extension|Macro defined error, repeat inclusion|
|Compile|Results of pre-treatment|Compiler Code|Syntax Error, type error|
|Compilation|Compiler Code|Target file|It's rare.|
|Link|Multiple ⟦0 + library|Executable|Zero, repeat definition|

Common command speed check:

|Purpose|Command|
| --- | --- |
|One step to compile| `g++ -std=c++20 -Wall -Wextra -O2 main.cpp -o app` |
|_Other Organiser| `g++ -c main.cpp -o main.o` |
|Multi-file Link| `g++ main.o util.o -o app` |
|Bring debugging information| `g++ -g main.cpp -o app` |
|Preprocessed View| `g++ -E main.cpp \| less` |
|Generate a compendium| `g++ -S main.cpp` |
|Link Library| `g++ main.cpp -lm -lpthread` |
|View Symbols| `nm -C app \| head` |
|View Dynamic Dependencies| `ldd app` |
|Invert| `objdump -d -M intel app` |
|Static check| `clang-tidy main.cpp -- -std=c++20` |
|Formatting| `clang-format -i main.cpp` |

## Headline and engineering.

```cpp
// widget.h：声明放头文件，用 include guard 或 #pragma once 防重复包含
#pragma once
#include <string>

class Widget {
public:
    explicit Widget(std::string name);
    void draw() const;

private:
    std::string name_;
};
```

```cpp
// widget.cpp：实现放源文件
#include "widget.h"
#include <iostream>

Widget::Widget(std::string name) : name_(std::move(name)) {}

void Widget::draw() const {
    std::cout << name_ << '\n';
}
```

|A promise.|Annotations|
| --- | --- |
|Declaration and separation|Header statement, source release|
|The header contains only what is necessary|It's not enough to use a pre-declaration.|
|Use ⟦0|It's simple and reliable. The mainstream compiler supports it.|
|Namespace|Avoid global symbol conflicts, do not use ⟦0|
|Compile Options|Development period 0, release period 1|

## Common Error Table

|Wrong message|Meaning|Treatment|
| --- | --- | --- |
| `fatal error: xxx.h: No such file or directory` |Synchronising folder|Use ⟦0 to specify the contents|
| `undefined reference to 'foo()'` |Declares that there are, realizes missing or unconnected libraries|Accomplishment or build-up (note the order of libraries)|
| `multiple definition of 'x'` |The same symbol is defined several times|Variables declare header files to be ⟦, define source files|
| `error: 'x' was not declared in this scope` |Not declared or header not included|Check Spelling, Fields and Include|
| `expected ';' after ...` |Syntax Error|See if the line number is missing.|
| `redefinition of 'struct X'` |The head file is not duplicated.|Plus zero.|
| `invalid conversion from 'const char*' to 'char*'` |String-only|Use 0 or 1|
| `warning: comparison of integer expressions of different signedness` |With and without symbols|Harmonize type, or convert explicitly with ⟦0|
|Program crashed but compiled|Runtime Error|Use ⟦0+gdb, or Asan|

## Self-Detected List

- [ ] The four stages of pre-processing, compilation and linking can be described.
- [ ] It's gonna be done separately, then unified.
- [ ] Knows that ⟦0 is a link error.
- [ ] Head file with zero, declaration and separation.
- [ ] The development period opens ⟦, the commissioning period adds 1.

<!-- appendix:v2 -->

## Zero base details: C++ from text to enforceable document

### What is it?

C++ is** compiled** language: you have to write a whole "translation" to run it.
The benefits are speed and control; the cost is that it has to be done first, without a grammatical error.

### Use a life metaphor to understand the process.

|Phase|A metaphor.|What did you actually do?|
| --- | --- | --- |
|Pre-treatment|Clip the reference to the body|Let's go.|
|Compile|Turn Chinese into English|Source → Compilation code, check syntax|
|Compilation|It's a machine-readable format.|Compiled code, target file, zero.|
|Link|We'll make it into a book.|Merge target files with libraries to generate executables|

One sentence: ** Compiled syntax, link pipe "is this guy in?"**

### Dismantling first program by line

```cpp
#include <iostream>          // 引入输入输出库

int main() {                 // 程序入口，必须有且只有一个
    std::cout << "Hello\n";  // 向屏幕输出
    return 0;                // 返回 0 表示正常结束
}
```

|Okay.|Code|What are you doing?|Why do you say that?|
| --- | --- | --- | --- |
| 1 | `#include <iostream>` |Tell the compiler I'm going to use input.|It's a pre-treatment order, no semicolon.|
| 3 | `int main()` |Define Program Entry|The operating system starts with this function.|
| 4 | `std::cout << ...` |Send content to standard output|It's going in the direction of "Data to Screen."|
| 4 | `"Hello\n"` |It's a line change.|No, no. The output will be linked to the back.|
| 5 | `return 0;` |Tell the system it's over.|We need to split every word.|

### Compile the actual commands

```bash
g++ -std=c++20 -Wall -Wextra -O2 hello.cpp -o hello
./hello
```

|Parameters|Role|
| --- | --- |
| `-std=c++20` |Use C+20 standard to avoid obsolescence|
| `-Wall -Wextra` |Turn on the usual warning. A lot of bugs are stopped here.|
| `-O2` |Enable Optimization, Release Usual|
| `-o hello` |Specifies the generated executable name|

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|Forget the semicolon.|Mistakes often point to the next line**|Read the last line of the wrong line.|
|Use Chinese Punctuation|A bunch of grammatical errors.|All in brackets, semicolons and commas|
|Variables Not Initialized|Output Random Value|When it's defined, you can give it to me.|
|Forget it.|The tip is missing.|Include corresponding header files as required|
|Only declarations are not defined.|⟦0 Link Error|Add function(s) or compile ⟦0|
|Synchronising folder|Zero, heavy.|Head file plus zero.|
|Integer Division|♪ I've got one ♪|I want to turn the numbers first.|
|Cluster crossed.|Sometimes it's normal.|Use ⟦0 plus 1 or border check|

### Three kinds of mistakes.

|Error type|Emergence|Typical information|Annotations|
| --- | --- | --- | --- |
|Compiler error|Compile| `expected ';'` |That's not true. It's easier to fix.|
|Link Error|Link| `undefined reference to` |Function stated but not achieved|
|Runtime Error|Run|Crash, mess.|Cross-border, empty pointers, uninitiated.|

### Handheld practice: Enter two numbers and output four results

```cpp
#include <iomanip>
#include <iostream>

int main() {
    double a = 0, b = 0;
    std::cout << "请输入两个数：";
    if (!(std::cin >> a >> b)) {
        std::cout << "输入不是数字\n";
        return 1;
    }
    if (b == 0) {
        std::cout << "除数不能为 0\n";
        return 1;
    }
    std::cout << std::fixed << std::setprecision(2)
              << "和=" << a + b << " 差=" << a - b
              << " 积=" << a * b << " 商=" << a / b << '\n';
    return 0;
}
```

### Learn how to measure yourself.

- [ ] Four steps in order of pre-processing, compilation, compilation and linkage.
- [ ] Can explain the difference between a compilation error and a link error.
- [ ] Know what the return value is.
- [ Laughs ] Can you tell me where the three points have to be?
- [ ] Be able to compile and run a source file independently.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeats, experiments and deliveries around "C++, g++", each result being checked.

Start with the minimum program to compile warnings, then verify memory and boundaries, and run it again in Sanitizer.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with Environment and Compilers?
2. Without it, what concrete consequences would there be?
3. What's it got to do with g+?

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

**Title:** Build Pipeline

**Summary:** Preprocess, compile, assemble, link; headers and namespaces.

**Category:** C++  
**Level:** Foundation
**Key terms:**C++, g++, compile, link, header file, namespace

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: Foundation
- Applicable environment: C+20/GMC 13+ or Clang 17+
- Source: Internal structured curriculum and engineering practices
- Related topics: C++, g++, compiler, link, header, namespace
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Build Pipeline** focuses on Preprocess, compile, assemble, link; headers and namespaces.

### Learning Outcomes

- Explain what **Build Pipeline** solves and when it should be used.
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

- Topic: **Build Pipeline**
- Relaid terms: C++, g++, compiled, linked
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning Objectives |
|Pre-knowledge| Pre-knowledge |
|From Source to Executable| From source to executable |
|First program.| First program |
|Headers and Sources| Header and Source Files |
|Namespace and Standard Library| Namespaces and Standard Libraries |
|Common pits| Common pits |
|It's the end of this class.| Lesson Summary |
|Quick check of the compilation process| Quick Look at the Compilation Process |
|Headline and engineering.| Head Documents and Engineering Organization Quick Look |

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

