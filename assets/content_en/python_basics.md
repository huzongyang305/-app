# Python Basic Syntax:

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning phase: Foundation = Projected duration: 12 minutes

## Learning objectives

- It's not like you can explain in your own words what the Python basic syntax solves, but it doesn't.
- The relationship between "python", "indent," and "input" is clear, with one example.
- It's a way to put this subject back into the "Python" system of knowledge, and it shows how much it has to do with each other.
- It is possible to complete this course and check its results using acceptance standards.

> Synopsis of a sentence: from the first application, master indentation, comment and input.

## Pre-knowledge

- The basic file, command line or browser operation is performed; the key words of this course are checked first when there are unfamiliar terms.
- This course stage: Foundation. It is recommended to read and write simple codes or commands, with basic concepts such as variables, input output, etc.
- Review before starting: python, indent, print.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Why first, Python?

The Python syntax is close to the natural language, and indents it into a structure that allows you to focus on "problem" rather than "composer." It's used extensively for data analysis, artificial intelligence, back-end services and automated scripts.

## The first procedure

```python
# 第一个 Python 程序
print("Hello, World!")

name = input("请输入你的名字：")
print(f"你好，{name}！")
```

Points:

- Zero is responsible for output to the screen.
- ** Read user input,** returns always a string.
- The line starting with the note will not be executed.

## Indentation is grammar.

Python indicates the code block, which must use an equal number of spaces. Officially recommends **4 spaces** and does not mix Tab with space.

```python
score = 85

if score >= 60:
    print("及格")   # 缩进的这行属于 if 分支
else:
    print("不及格")

print("程序结束")   # 没有缩进，无论条件是否成立都会执行
```

## Basic Input Output

```python
# input 返回字符串，需要数字时要显式转换
age_text = input("请输入年龄：")
age = int(age_text)

print("明年你", age + 1, "岁")
print(f"类型是 {type(age).__name__}")
```

Common error: Adding the results directly to ⟦0 will result in a string of strings, and 1 will throw out two.

## Code style advice

1. Variables are underlined by lowercase letters, such as ⟦0.
2. Each line does not exceed 79-100 characters, which are easy to read.
3. Use an empty line to separate the logical paragraphs.
4. It's not about "why" but "what."

## Frequent error check

|phenomena|Reason|Amendments|
| --- | --- | --- |
| `IndentationError` |Combining Tab with Space, Indentation|Uniform 4 spaces, editor displaying blanks|
|Zero, TypeError.|Input Return String|First use of ⟦0 conversion|
|Function Default "Remembered" in multiple calls|Variables as Default|Use ⟦0 and create it in a function|
|It's not what I expected.|It's a comparison.|The value compares with the same object.|
|Missing elements in the cycle|Change the list every time|All over the place.|

## It's the end of this class.
Python is based on three fundamentals: ** indent, variable, input and output.

<!-- appendix:v1 -->

## Syntax:

|Syntax:|Writing|Annotations|
| --- | --- | --- |
|Indent|4 Spaces|The same code block must be consistent. Tab is forbidden to mix with space|
|Single-line Comment|Zero.|Explain why, not repeat the code.|
|Multiline Comment|Zero.|Actual string, in the first line of a function|
|Variable Values| `x = 10` |The equals are easier to read.|
|Multiple Values| `a, b = 1, 2` |Start multiple variables in one row|
|Exchange Variables| `a, b = b, a` |No temporary variable required|
|Enter|Zero.|Return value is always zero.|
|Output| `print(a, b, sep="-")` |Zero control separator, one control ending|

String formatting quick check:

|Method|Writing|Recommendations|
| --- | --- | --- |
| f-string |Zero.|**Present**, visual and performance|
|Format Control| `f"{pi:.2f}"`、`f"{n:04d}"` |Keep decimals, add zeroes|
| `str.format` | `"{} {}".format(a, b)` |The old code is common. It's a little bad readability.|
|Formatting| `"%s %d" % (a, b)` |Obsolete, only for reading old codes|

```python
name = input("姓名：").strip()
age = 18
print(f"{name} 今年 {age} 岁")
print(f"圆周率约等于 {3.14159:.2f}")     # 3.14
print(f"编号 {7:04d}")                   # 编号 0007
print("a", "b", sep="-", end="!\n")      # a-b!
```

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
|Tab Indent with Space| `TabError: inconsistent use of tabs and spaces` |Use 4 spaces in a uniform format, and the editor sets "Tab"|
|Forget the fake.| `SyntaxError: expected ':'` |It's gonna be a fake at the end.|
|Point in Chinese| `SyntaxError: invalid character '：'` |The brackets, quotes and colones in the code must be in half English.|
|I'm going to do a lot of math.| `TypeError: can only concatenate str` |⟦0 returns the string with 1⟧/ 2|
| `print "hello"` | `SyntaxError` |Python 3 is a function with brackets|
|Use variable without definition| `NameError: name 'x' is not defined` |Give it to me before you use it.|
|Use reserved word as variable name| `SyntaxError` |You can't do that.|
|I'll make a comparison.| `SyntaxError` |It's more like a zero.|
|Unconverted quotes in string| `SyntaxError: unterminated string literal` |"Package with another quote, or write ⟦0"|
|Nothing under the code block.| `IndentationError: expected an indented block` |At least write ⟦ or actual statements|

## First week of practice.

- [ ] Write a little "Input names and ages, output greeting."
- [ ] Retain the amount of two decimals in f-string.
- [ Chuckles ] Can explain why you have to do the type conversion.
- [ ] Read the last line of error before locating the row number and type.
- [ ] There are no Tab points in the code.

<!-- appendix:v2 -->

## Zero basics: Python is a recipe for computers.

### What is it?

Python is the language ** written directly into code: it ends with an indentation, without a semicolon
There's no need to state the type. You wrote a line of codes that you wanted the computer to do.

### Four words in a life metaphor.

|The words in the code.|It's the equivalent of life.|One explanation.|
| --- | --- | --- |
|Variables|The box with the tag.|Give me a name. Put the data in, then use it.|
|Statement|A step in the recipe.|The computer will do it one by one.|
|Indent|What kind of course is that?|Indent the same line as a block|
|Comment|It's for the future.|The computer doesn't care about it. It's just for people.|

### Dismantling the first procedure by line

```python
# 第一个 Python 程序
print("Hello, World!")

name = input("请输入你的名字：")
print(f"你好，{name}！")
```

|Okay.|Code|What are you doing?|Why do you say that?|
| --- | --- | --- | --- |
| 1 |Zero.|It's for people.|After that, the computer skips.|
| 2 | `print("Hello, World!")` |Show the contents in brackets on screen|Text should be wrapped in quotation marks, meaning "This is a text."|
| 3 |Empty|Let the code segment|Python allows empty lines, readability is better|
| 4 |Zero.|Pop up a hint, wait for the user to type and get back in.|The return value of ⟦ is input by the user|
| 5 |Zero.|Embedding Variables after String Output|⟦0 in f-string is replaced by the value of a variable|

### Three things that have to be engraved in muscle memory.

1. **Indentation is grammar, not layout.** One space less, one Tab, and the program may be either directly wrong or completely different in logic.
2. ** ⟦ always get back a string. ** Wants to have one or two of your own numbers.
3. ** It's not a bad story. ** The last line contains the type and cause of the mistake, and the lines above contain an error position.

### Three moves to run the program.

```text
1. 写代码        → 在编辑器里输入代码
2. 存成文件      → 文件名用英文与下划线，保存为 hello.py
3. 运行          → 终端里执行 python hello.py
```

> Never call a file the same name as any other.
Otherwise, Python will import your files first.

### It's the eight most confusing concepts.

|Two things that are easy to mix.|It's a difference.|
| --- | --- |
|Zero and one.|It's just for show; it's for callers.|
|Zero and one.|Zero is the value; 1 is a comparison|
|Variable Name and String|It's a variable; it's the text.|
|Single and Double Quotes|In Python, it's the same thing.|
|Comment and String|⟦ is a comment; 1 is real string data|
|Statements and Expressions|⟦ is a statement; 1 is an expression (output value)|
|Function & Call|It's the function itself; it's called and got results.|
|Wrongs and warnings|Mistakes interrupt the program; warning is a reminder that programs can continue.|

### People who've been making mistakes.

|English on the screen|Words.|How?|
| --- | --- | --- |
| `SyntaxError: invalid syntax` |It's not grammar.|Check if brackets, quotation marks and colons are paired.|
| `IndentationError` |Indentation's a mess.|Unifiedly use 4 spaces, do not mix Tab|
| `NameError: name 'x' is not defined` |It's not worth it.|Give value and use, and check spelling.|
| `TypeError: can only concatenate str` |The strings and the numbers are together.|First ⟦0 conversion, or f-string|
| `ValueError: invalid literal for int()` |I want to transfer the numbers, but they're not.|Determines whether the input is legal, or using a ⟦0 base|
| `ModuleNotFoundError` |No module found|Check if the name is spelling, whether it's stored in a library or not.|

### Hand hands practice: Say hello to the applet.

Request: Ask the user's name and year of birth to output "Hello, XX. You are about XX."

```python
name = input("请输入你的名字：").strip()
year_text = input("请输入你的出生年份（如 2005）：").strip()

if not year_text.isdigit():
    print("年份只能是数字哦")
else:
    age = 2026 - int(year_text)
    print(f"你好，{name}，你大约 {age} 岁")
```

Point by point:

- Zero, remove the first space that you accidentally entered.
- It's not like we're going to be able to figure out if it's a real number.
- You can't change the order.
- The f-string ⟦ can write the variable name directly, more clearly than using a ⟦1 enzyme.

### Learn how to measure yourself.

- [ ] Can you tell me why Python indents instead of big brackets.
- [ Chuckles ] Can explain why we're going to do the type conversion.
- [ ] When you see a miscalculation, look at the last line.
- [ ] Can write "input two numbers, output them together."
- [ ] Knows that the variable name cannot start with a number and is not renamed by key word.

<!-- scaffold:v1 -->

<!-- exercise-guard:v1 -->

## Let's practice.

### Practice 1: Restatement of Concept (10 mins)

Join the curriculum and explain "Python Basic Syntax" in three or five words, and write a border condition.

**Acceptance standard: at least one lesson keyword is used and an example given.

### Practice 2: Example rewrite (20 minutes)

Select a minimum example from the text to predict changes in an input before actually verifying and recording differences.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Migration assignment (30 minutes)

Writes a small script within 20 lines to use this lesson concept for processing real text or list data.

- I'm not sure if you want me to be able to do this.
- Output of a result that can be checked by others.
- Write about a problem that is still uncertain and how to verify it.

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Python Syntax

**Summary:** Start from the first program and master indentation, comments, I/O.

**Category:** Python  
**Level:** Foundation
**Key terms:** python, pent, input, comment

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: Foundation
- Applicable environment: Python 3.12+
- Source: Internal structured curriculum and engineering practices
- Related themes: python, indent, print, input, comments
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

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
- Relaid terms: python, print, input
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Why first, Python?|Why first, Python?|
|The first procedure|The first procedure|
|Indentation is grammar.|Indentation is grammar.|
|Basic Input Output|Basic Input Output|
|Code style advice|Code style advice|
|Frequent error check|Come on, let's go.|
|It's the end of this class.| Summary |
|Syntax:|Syntax:|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

