# Python 基础语法

![Python 基础语法](images/remaining_python_basics.webp)

> 内容更新时间：2026-10-03 · 学习阶段：基础 · 预计用时：12 分钟

## 学习目标

- 能用自己的话解释「Python 基础语法」解决了什么问题，而不是只背术语。
- 能说清 「python」、「缩进」、「print」、「input」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Python」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：从第一个程序开始，掌握缩进、注释与输入输出。

## 前置知识

- 会进行基本的文件、命令行或浏览器操作；遇到不熟悉的术语先查本课关键词。
- 本课阶段：基础。建议会读写简单代码或命令，并理解变量、输入输出等基本概念。
- 开始前先复习：python、缩进、print。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 为什么先学 Python

Python 语法接近自然语言，缩进即结构，能让你把注意力放在「解决问题」而不是「讨好编译器」上。它被广泛用于数据分析、人工智能、后端服务和自动化脚本。

## 第一段程序

```python
# 第一个 Python 程序
print("Hello, World!")

name = input("请输入你的名字：")
print(f"你好，{name}！")
```

要点：

- `print()` 负责向屏幕输出内容。
- `input()` 读取用户输入，**返回的永远是字符串**。
- `#` 开头的行是注释，不会被执行。

## 缩进就是语法

Python 用缩进表示代码块，同一代码块必须使用相同数量的空格。官方推荐 **4 个空格**，不要混用 Tab 和空格。

```python
score = 85

if score >= 60:
    print("及格")   # 缩进的这行属于 if 分支
else:
    print("不及格")

print("程序结束")   # 没有缩进，无论条件是否成立都会执行
```

## 基本输入输出

```python
# input 返回字符串，需要数字时要显式转换
age_text = input("请输入年龄：")
age = int(age_text)

print("明年你", age + 1, "岁")
print(f"类型是 {type(age).__name__}")
```

常见错误：直接对 `input()` 的结果做加法会得到字符串拼接，`"18" + 1` 会抛出 `TypeError`。

## 代码风格建议

1. 变量名用小写字母加下划线，例如 `user_name`。
2. 每行尽量不超过 79~100 个字符，方便阅读。
3. 用空行分隔逻辑段落。
4. 给复杂的判断写注释，解释「为什么」而不是「做了什么」。

## 常见错误速查

| 现象 | 原因 | 修正 |
| --- | --- | --- |
| `IndentationError` | 混用 Tab 与空格、缩进不一致 | 统一 4 个空格，编辑器显示空白符 |
| `"18" + 1` 报 TypeError | input 返回字符串 | 先用 `int()` 转换 |
| 函数默认值在多次调用间"记住了"旧数据 | 可变对象作默认参数 | 用 `None` 占位并在函数内创建 |
| 判断相等结果不符预期 | 用了 `is` 比较值 | 值比较用 `==`，`is` 只判断同一对象 |
| 循环里删元素漏项 | 遍历时修改列表 | 遍历副本 `for x in nums[:]` |

## 本课小结
Python 的三大基础是：**缩进、变量、输入输出**。掌握它们之后，就可以开始写带分支和循环的小程序了。


## 语法速查

| 语法 | 写法 | 说明 |
| --- | --- | --- |
| 缩进 | 4 个空格 | 同一代码块必须一致，禁止 Tab 与空格混用 |
| 单行注释 | `# 说明` | 解释「为什么」，而不是复述代码 |
| 多行注释 | `"""说明"""` | 实际是字符串，放在函数首行即文档字符串 |
| 变量赋值 | `x = 10` | 等号两边加空格更易读 |
| 多重赋值 | `a, b = 1, 2` | 一行初始化多个变量 |
| 交换变量 | `a, b = b, a` | 不需要临时变量 |
| 输入 | `input("提示：")` | 返回值永远是 `str` |
| 输出 | `print(a, b, sep="-")` | `sep` 控制分隔符，`end` 控制结尾 |

字符串格式化速查：

| 方式 | 写法 | 建议 |
| --- | --- | --- |
| f-string | `f"{name} 今年 {age} 岁"` | **首选**，直观且性能好 |
| 格式控制 | `f"{pi:.2f}"`、`f"{n:04d}"` | 保留小数、补零 |
| `str.format` | `"{} {}".format(a, b)` | 老代码常见，可读性略差 |
| `%` 格式化 | `"%s %d" % (a, b)` | 已过时，仅用于阅读旧代码 |

```python
name = input("姓名：").strip()
age = 18
print(f"{name} 今年 {age} 岁")
print(f"圆周率约等于 {3.14159:.2f}")     # 3.14
print(f"编号 {7:04d}")                   # 编号 0007
print("a", "b", sep="-", end="!\n")      # a-b!
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| Tab 与空格混用缩进 | `TabError: inconsistent use of tabs and spaces` | 统一用 4 个空格，编辑器设置「Tab 转空格」 |
| 忘了冒号 | `SyntaxError: expected ':'` | `if`、`for`、`while`、`def`、`class` 行末都要冒号 |
| 用中文标点 | `SyntaxError: invalid character '：'` | 代码里的括号、引号、冒号必须用英文半角 |
| `input()` 直接参与算术 | `TypeError: can only concatenate str` | `input()` 返回字符串，先 `int()` / `float()` |
| `print "hello"` | `SyntaxError` | Python 3 中 `print` 是函数，必须加括号 |
| 变量未定义就使用 | `NameError: name 'x' is not defined` | 先赋值再使用，注意拼写一致 |
| 使用保留字作变量名 | `SyntaxError` | 避开 `class`、`def`、`lambda`、`None` 等关键字 |
| 用 `=` 做比较 | `SyntaxError` | 比较相等用 `==` |
| 字符串里出现未转义的引号 | `SyntaxError: unterminated string literal` | 用另一种引号包裹，或写 `\'` |
| 代码块下没有内容 | `IndentationError: expected an indented block` | 至少写 `pass` 或实际语句 |

## 入门第一周练习清单

- [ ] 写一个「输入姓名与年龄，输出问候语」的小程序。
- [ ] 用 f-string 输出保留两位小数的金额。
- [ ] 能解释 `input()` 为什么必须做类型转换。
- [ ] 遇到报错先看最后一行，再定位行号与类型。
- [ ] 代码里不出现 Tab 与中文标点。


## 零基础详解：把 Python 当成「写给电脑的菜谱」

### 一句话说清它是什么

Python 是一门**把想法直接写成代码**的语言：它用缩进划分层次、不需要分号结尾、
不需要先声明类型。你写的一行代码，几乎就是你想让电脑做的那件事。

### 用生活比喻理解四个词

| 代码里的词 | 生活里的对应物 | 一句话解释 |
| --- | --- | --- |
| 变量 | 贴了标签的盒子 | 起个名字，把数据放进去，之后用名字取 |
| 语句 | 菜谱里的一步 | 电脑会按顺序一步一步做 |
| 缩进 | 步骤属于哪道菜 | 缩进相同的行属于同一个代码块 |
| 注释 | 给未来的自己留的便签 | 电脑完全不理它，只给人看 |

### 逐行拆解第一段程序

```python
# 第一个 Python 程序
print("Hello, World!")

name = input("请输入你的名字：")
print(f"你好，{name}！")
```

| 行 | 代码 | 在做什么 | 为什么这么写 |
| --- | --- | --- | --- |
| 1 | `# 第一个 Python 程序` | 写给人看的说明 | `#` 之后的内容电脑直接跳过 |
| 2 | `print("Hello, World!")` | 把括号里的内容显示到屏幕 | 文字要用引号包起来，表示「这是一段文本」 |
| 3 | 空行 | 让代码分段 | Python 允许空行，可读性更好 |
| 4 | `name = input("请输入你的名字：")` | 先弹出提示，等用户敲字并回车 | `input()` 的返回值是用户输入的内容 |
| 5 | `print(f"你好，{name}！")` | 把变量嵌进字符串后输出 | f-string 里的 `{}` 会被替换成变量的值 |

### 三件必须刻进肌肉记忆的事

1. **缩进是语法，不是排版。** 少一个空格、多一个 Tab，程序可能直接报错或逻辑完全不同。
2. **`input()` 拿回来的永远是字符串。** 想要数字必须自己 `int()` 或 `float()` 转换。
3. **报错不可怕，先看最后一行。** 最后一行写着错误类型和原因，上面几行写着出错位置。

### 把程序跑起来的三个动作

```text
1. 写代码        → 在编辑器里输入代码
2. 存成文件      → 文件名用英文与下划线，保存为 hello.py
3. 运行          → 终端里执行 python hello.py
```

> 文件名千万不要叫 `random.py`、`string.py` 这类标准库同名文件，
> 否则 Python 会优先导入你的文件，出现莫名其妙的报错。

### 新手最容易混淆的八组概念

| 容易混的两件事 | 一句话区别 |
| --- | --- |
| `print` 和 `return` | `print` 只是显示给人看；`return` 是把结果交给调用者使用 |
| `=` 和 `==` | `=` 是赋值（放进去）；`==` 是比较（问是否相等） |
| 变量名和字符串 | `name` 是变量；`"name"` 是一段文本，两回事 |
| 单引号与双引号 | 在 Python 里作用完全相同，选一种保持统一即可 |
| 注释与字符串 | `# 说明` 是注释；`"说明"` 是真实的字符串数据 |
| 语句与表达式 | `x = 1` 是语句（做动作）；`x + 1` 是表达式（产出值） |
| 函数与函数调用 | `input` 是函数本身；`input()` 才是调用它并拿到结果 |
| 报错与警告 | 报错会中断程序；警告只是提醒，程序还能继续跑 |

### 常见报错的人话翻译

| 屏幕上的英文 | 人话 | 怎么改 |
| --- | --- | --- |
| `SyntaxError: invalid syntax` | 这行的写法不合语法 | 检查括号、引号、冒号是否配对，是否用了中文标点 |
| `IndentationError` | 缩进乱了 | 统一用 4 个空格，别混 Tab |
| `NameError: name 'x' is not defined` | 这个名字还没被赋值 | 先赋值再使用，并检查拼写 |
| `TypeError: can only concatenate str` | 字符串和数字硬拼在一起了 | 先 `int()` 转换，或用 f-string 拼接 |
| `ValueError: invalid literal for int()` | 想转数字，但内容不是数字 | 判断输入是否合法，或用 `try/except` 兜底 |
| `ModuleNotFoundError` | 找不到这个模块 | 检查名字拼写、是否装了库、文件是否同名冲突 |

### 手把手练习：问候小程序

要求：问用户姓名与出生年份，输出「你好，XX，你大约 XX 岁」。

```python
name = input("请输入你的名字：").strip()
year_text = input("请输入你的出生年份（如 2005）：").strip()

if not year_text.isdigit():
    print("年份只能是数字哦")
else:
    age = 2026 - int(year_text)
    print(f"你好，{name}，你大约 {age} 岁")
```

逐点说明：

- `.strip()` 去掉用户不小心输入的首尾空格。
- `.isdigit()` 先判断「是不是纯数字」，避免程序直接崩掉。
- `2026 - int(year_text)` 先转换再运算，顺序不能反。
- f-string 里的 `{}` 可以直接写变量名，比用 `+` 拼接更清楚。

### 学完自测

- [ ] 能说出为什么 Python 用缩进而不是大括号。
- [ ] 能解释 `input()` 为什么要做类型转换。
- [ ] 看到报错时，知道先看最后一行、再定位行号。
- [ ] 能独立写出「输入两个数字，输出它们的和」。
- [ ] 知道变量名不能以数字开头、不能与关键字重名。



## 动手练习

### 练习 1：概念复述（10 分钟）

合上教程，用 3～5 句话解释「Python 基础语法」解决什么问题，并写出一个边界条件。

**验收标准**：至少使用一个本课关键词，并给出一个反例。

### 练习 2：示例改写（20 分钟）

从正文选一个最小示例，先预测修改一个输入后的结果，再实际验证并记录差异。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：迁移任务（30 分钟）

写一个 20 行以内的小脚本，把本课概念用于处理一份真实文本或列表数据。

- 至少覆盖「python」和「缩进」两个关键词。
- 产出一个别人可以检查的结果。
- 写出一个仍不确定的问题和验证方法。


## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：Python 中 input() 函数的返回值是什么类型？

- **正确判断**：字符串 str
- **判断依据**：input() 始终返回字符串，需要数字时必须用 int() 或 float() 显式转换。其他选项：float 与 int 只有在显式转换后才会出现，Python 也不会根据内容自动推断。input() 永远返回 str。正确项「字符串 str」抓住了题干的核心条件，是经得起边界检验的表述。错误项「整数 int」把不同概念混在一起，缺少题干限定的前提。错误项「根据输入自动推断」与课程给出的定义相冲突，不能回答题目所问。错误项「浮点数 float」只看到了表面现象，没有解释题干真正考查的机制。把题干「Python 中 input() 函数的返回值是什么类型？」放回《Python 基础语法》的「从第一个程序开始，掌握缩进、注释与输入输出」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 2：以下哪组类型全部是不可变类型？

- **正确判断**：int、str、tuple
- **判断依据**：不可变类型创建后不能原地修改内容，int、str 和 tuple 都属于这一类；list、dict、set 都是可变容器。需要特别注意 tuple 中如果嵌套了 list，外层 tuple 仍不可变，但内部 list 的内容仍可能被修改，这是常见的边界问题。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 3：下面哪个是 Python 的单行注释写法？

- **正确判断**：# 注释
- **判断依据**：Python 使用 # 作为单行注释。三引号字符串常被用作多行文档字符串。其他选项：/* */ 属于 C 系语言，// 在 Python 里是整除运算符，-- 会被解析成两个负号，都不是注释。正确项「# 注释」既符合定义也满足题干限定的场景，因此应当选择。错误项「/* 注释 */」把因果关系颠倒了，不能作为正确结论。错误项「// 注释」忽略了题目中的限制条件，因此不成立。错误项「-- 注释」属于相邻主题的说法，范围与本题要求不一致。把题干「下面哪个是 Python 的单行注释写法？」放回《Python 基础语法》的「从第一个程序开始，掌握缩进、注释与输入输出」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 4：同一次缩进中混用 Tab 和空格，Python 会报什么错？

- **正确判断**：IndentationError
- **判断依据**：缩进不一致会抛 IndentationError，规范要求统一使用 4 个空格。 其他选项：SyntaxError 泛指语法问题、TypeError 指类型不匹配；缩进不一致会专门抛 IndentationError（它是 SyntaxError 的子类）。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 5：下列哪些是 Python 的内置不可变类型？请选择所有正确答案。

- **正确判断**：int、tuple
- **判断依据**：不可变表示对象创建后不能原地改变自身内容，因此可以作为字典键或集合元素。int 和 tuple 都属于不可变类型；list 与 dict 可以增删或替换元素，属于可变类型。需要注意，tuple 本身不可变，但如果它内部保存了 list，那么这个 list 的内容仍可被修改，这是“浅层不可变”的常见陷阱。判断时一定要区分外层容器和内部对象。
- **迁移检查**：每个正确项各自成立的条件是什么？有没有互相依赖。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Python 中 input() 函数的返回值是什么类型？」的判断依据。
- [ ] 不看解析，能说出「以下哪组类型全部是不可变类型？」的判断依据。
- [ ] 不看解析，能说出「下面哪个是 Python 的单行注释写法？」的判断依据。
- [ ] 不看解析，能说出「同一次缩进中混用 Tab 和空格，Python 会报什么错？」的判断依据。
- [ ] 不看解析，能说出「下列哪些是 Python 的内置不可变类型？请选择所有正确答案。」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** Python Syntax

**Summary:** Start from the first program and master indentation, comments, I/O.

**Category:** Python  
**Level:** 基础  
**Key terms:** python, 缩进, print, input, 注释

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：基础
- 适用环境：Python 3.12+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：python、缩进、print、input、注释
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## Full English Study Guide

### Overview

**Python Syntax** focuses on Start from the first program and master indentation, comments, I/O.

### Learning Outcomes

- Explain what **Python Syntax** solves and when it should be used.
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

- Topic: **Python Syntax**
- Related terms: python, 缩进, print, input
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.


## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 为什么先学 Python | 为什么先学 Python |
| 第一段程序 | 第一段程序 |
| 缩进就是语法 | 缩进就是语法 |
| 基本输入输出 | 基本输入输出 |
| 代码风格建议 | 代码风格建议 |
| 常见错误速查 | Common mistakes速查 |
| 本课小结 | Summary |
| 语法速查 | 语法速查 |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Python 官方文档](https://docs.python.org/3/) | 语言、标准库与版本行为 |
| [Python Packaging](https://packaging.python.org/) | 包管理与发布 |

> 本课主题：从第一个程序开始，掌握缩进、注释与输入输出。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

