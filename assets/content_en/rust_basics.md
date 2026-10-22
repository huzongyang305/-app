# Rust Base

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Foundations -- Expected duration: 16 minutes

## Learning objectives

- I can explain what Rust Base is about, not just the term.
- The relationship between "Rust", "ownership," "loaning" and "life cycle" is clear.
- It's a way to put this subject back into Rust's knowledge system, and it shows the boundaries of an adjacent theme.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentence: Ownership, loan checking, Result and co-security.

## Pre-knowledge

- The basic file, command line or browser operation is performed; the key words of this course are checked first when there are unfamiliar terms.
- This course stage: Foundation. It is recommended to read and write simple codes or commands, with basic concepts such as variables, input output, etc.
- Read it first: Rust, ownership, loan.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Language positioning

Rust is a system-level language that replaces garbage recovery with ** compilation period check, making memory safe and zero cost abstract.It is suitable for operating systems, embedded, network intermediates and high performance CLI (Firefox, Linux kernel), Deno has Rust codes.

## Ownership: core

Three rules: there is only one owner for each value; at the same time, there can be only one ownership; the owners are released when they leave their area of operation.

|Concept|Annotations|
| --- | --- |
| Move |Transfer of ownership by value or pass, original variable not valid|
| Borrow |♪ Can't be borrowed, can be borrowed|
|I'm borrowing the rules.|Either it's unalterable, or one can't exist together.|
|Life cycle|Tell the compiler of a valid range|

This set of rules eliminates precipitous guidelines, repeat releases and data competition during the compilation period.

## Type System

|Type|Purpose|
| --- | --- |
| Option<T> |It's probably not worth it.|
| Result<T, E> |It's a possibility of failure.|
| struct / enum |Data modelling, enum carryable data (similar to algebra type)|
| trait |Define shared behaviour, which can be distributed staticly (blank) or dynamically (dyn)|
|Smart Pointer|Box, Rc, Arc, RefCell for distribution and sharing of ownership|

Mode Match with enum is a common way for Rust to express business, and requires that all branches be exhausted.

## We're safe.

Rust secures the thread with a type of system: ⟦ 0= is transective, 1= can be referred to as multi-linear.The Standard Library provides thread, channel (mpsc), Mutex, RwLock and atom types; ⟦2 is a classic combination of trans-linear variable status.

## Engineering practice

1. Cargo relies on, constructs, tests and documents (Cargo.toml).
2. Error processing: The library defines the error type and applies anyhow to disseminate it.
3. It's a standard three set.
4. Interoperating with C FFI/ bindgen; embedded in no_std.
5. Performance sensitive scenes can be used in unsafe, provided that security prerequisites are spelled out and as far as possible enclosed.

## Learning Curves

It's easier for a beginner to get stuck in the "loaner" system.Reads the full tip with a translation error (Rust is of high quality) and uses the code to run first, before phasing out unnecessary copies.

## It's the end of this class.
Rust moves memory to the translation period by ** ownership + type of system. ** Pre-learning costs are high, in exchange for security at almost zero running cost.

<!-- appendix:v1 -->

## Basic Syntax:

|Concept|Writing|Annotations|
| --- | --- | --- |
|It's not bound.| `let x = 1;` |Default Non-change|
|Variable binding| `let mut x = 1;` |Visible declaration if change is required|
|Constant| `const MAX: u32 = 100;` |Type to be indicated|
|Static Variables| `static NAME: &str = "app";` |All the way.|
|Blocks| `let (a, b) = (1, "x");` |Decomposition|
|Numeric| `let a = [1, 2, 3];` |Fixed length|
|Slice| `&a[1..3]` |I'll borrow some of it.|
|String| `String` / `&str` |_Other Organiser|
|Enumeration| `enum Status { Ok, Err(String) }` |Portable data|
|Mode Match| `match value { ... }` |It has to be exhausted.|
| `if let` |It's just one branch.|Simplify|

```rust
#[derive(Debug, Clone, PartialEq)]
enum Command {
    Quit,
    Echo(String),
    Move { x: i32, y: i32 },
}

fn run(cmd: Command) -> String {
    match cmd {
        Command::Quit => "退出".to_string(),
        Command::Echo(text) => text,
        Command::Move { x, y } => format!("移动到 ({x}, {y})"),
    }
}

fn main() {
    println!("{}", run(Command::Move { x: 1, y: 2 }));

    // 错误处理不用异常，用 Result
    let parsed: Result<i32, _> = "42".parse();
    match parsed {
        Ok(n) => println!("解析成功：{n}"),
        Err(e) => eprintln!("解析失败：{e}"),
    }
}
```

## Common command quick check.

|Purpose|Command|
| --- | --- |
|New Item| `cargo new app` / `cargo init` |
|Compile| `cargo build` / `cargo build --release` |
|Run| `cargo run -- args` |
|Test| `cargo test` |
|Format Check| `cargo fmt --check` |
|Static check| `cargo clippy -- -D warnings` |
|Update Dependence| `cargo update` |
|View Dependency Tree| `cargo tree` |
|Documentation| `cargo doc --open` |
|Check not to output binary| `cargo check` |

## Common Error Table

|Compiler error|Meaning|Treatment|
| --- | --- | --- |
| `cannot find value x in this scope` |Variables are not defined or functioning extraterritorially|Check Spelling & Fields|
| `cannot assign twice to immutable variable` |No, no, no.|Add ⟦0 or reset|
| `mismatched types` |Inconsistencies|Visible conversion (,⟦1)|
| `expected &str, found String` |I need to borrow it.|Pass 0 or 1|
| `non-exhaustive patterns` |Zero, not all of them.|Substitute or plus 0|
|I'll call you back.|Variable not used|Use ⟦0 prefix or delete|
| `cannot borrow as mutable` |I'm borrowing the conflict.|Shorten or adjust variability|
| `the trait bound ... is not satisfied` |Type missing|Realize or Change to the Type of Consistency|
|Integer spill (debug)| panic |Use ⟦0/ 1 for explicit behaviour|
|Forget ⟦0 import|It's a mistake.|Zero statement|

## Self-Detected List

- [ ] Variables are non-variable and need to be modified in a visible manner.
- [ ] It's going to be done with ⟦1 .
- [ ] Mishandling with ⟦0 and not abnormal.
- [ ] Common commands ⟦ for quick feedback.
- [ Chuckles ] Before you run with the one.

<!-- appendix:v2 -->

## Zero base details: Cargo, Variables and the first Rust program

### What is it?

Rust is the system-level language where memory security was identified during a compilation period.
It does not rely on recycling, but rather on rules of ownership to ensure that issues such as empty guidelines and data competition do not arise at the codification stage.

### It's a life metaphor.

|Concept|A metaphor.|Annotations|
| --- | --- | --- |
| Cargo |Project Manager|Construction, dependence, compilation, testing and release of the entire system|
| crate |One delivery module|Executable program or library|
| `fn main` |The gate.|Program entrance|
|Ownership|There's only one owner.|The original variable can no longer be used when the value is moved|
|I'm borrowing.|Let's borrow it.|I'll borrow it. I'm out.|

### Dismantling first program by line

```rust
fn main() {                       // 入口函数，无返回值
    let name = "小明";             // 不可变变量（默认就不可变）
    let mut count = 0;            // 需要修改要显式加 mut
    count += 1;

    println!("你好，{name}，计数 {count}");   // 宏，末尾带感叹号
}
```

|Syntax:|Annotations|
| --- | --- |
| `let name = ...` |Default not to change. ** To change the amount must write 0**|
| `{name}` |Inline variables, more intuitive than writing parameters|
| `println!` |This is not a function, so there's Zero.|
|End of statement|It's important that you don't have a semicolon behind it.|

### Cargo Common Commands

```bash
cargo new demo          # 新建可执行项目
cargo new --lib mylib   # 新建库项目
cargo run               # 编译并运行
cargo build --release   # 发布构建，开优化
cargo test              # 跑测试
cargo clippy            # 官方 lint，强烈建议每次提交前跑
cargo fmt               # 统一格式
```

### Variables, Constants and Mask

```rust
const MAX_RETRY: u32 = 3;      // 常量：全大写、必须标类型

let x = 5;
let x = x + 1;                 // 遮蔽（shadowing）：可以换类型
let x = "现在是字符串";          // 合法，因为是新的绑定

let mut y = 5;
y = 6;                         // 同一个变量，类型不能变
```

|Concept|Keyword|Can you change it?|Can you change the type?|
| --- | --- | --- | --- |
|Non-variable variables| `let` |I can't.|You can do it by covering up.|
|Variables| `let mut` |Yes.|I can't.|
|Constant| `const` |I can't.|I can't. It has to be the type.|

### Type and Integer Family

|Type|Annotations|Default|
| --- | --- | --- |
| `i32` / `i64` |Integer with symbol| `i32` |
| `u32` / `usize` |Unsigned Integer|⟦0 for subscript|
| `f64` |Floating Point| `f64` |
| `bool` |Boolean.|Can't switch with the numbers.|
| `char` |4 byte Unicode characters|Single quote|
| `String` / `&str` |Variable String / String Slice|It's a title piece.|

### The eight most easy pits for freshmen.

|The pit.|Wrong message|The right thing to do.|
| --- | --- | --- |
|Forget it.| `cannot assign twice to immutable variable` |Add ⟦0 or change to a new binding.|
|Use ⟦0 for inverted numbers| `cannot apply unary operator` |Rust's ⟦ is a bit counterproductive, and the logic isn't just for bool.|
|Integer and Floating Point| `mismatched types` |Visible ⟦ or change to the same type|
|String ⟦0 to compare different types|Type does not match|It's better to use ⟦2, but be careful with the quote.|
|It's wrong to forget the semicolon.| `expected ()` |Checks if expressions are unexpectedly returned values|
|The bottom line is crossed.|Runtimepanic|Use 0 to return 1|
|Integer spill|Debug down panic, release next|Use ⟦0 for the same thing.|
|♪ Forget, after the macro ♪|Syntax Error|We're gonna need a semicolon.|

### Handheld practice: pure logic of guessing numbers

```rust
use std::cmp::Ordering;

fn compare(secret: i32, guess: i32) -> &'static str {
    match guess.cmp(&secret) {
        Ordering::Less => "小了",
        Ordering::Greater => "大了",
        Ordering::Equal => "猜对了",
    }
}

fn main() {
    let secret = 7;
    for guess in [3, 9, 7] {
        println!("猜 {guess}：{}", compare(secret, guess));
    }
}
```

Zero must cover everything, and the compiler will check if it's missing a branch -- this is Rust's source of security.

### Learn how to measure yourself.

- [ Chuckles ] Can you tell the difference between zero, one thousand and two hundred?
- [ Laughs ] Can you explain why the rust has an exclamation mark?
- [ ] Know the difference between masking and revalidation of variables.
- [ ] Can you tell me the difference between ⟦ and ?
- [ ] Read the "help" advice from the compiler in case of a translation error.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of the course: Repeats, experiments and deliveries around "Rust, Ownership, Loan" each result is subject to scrutiny.

Let's get the cargo check through, then fill up ownership, wrong and parallel borders, and finally run clippy.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's Rust Base up to?
2. Without it, what concrete consequences would there be?
3. What's it got to do with ownership?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Writes a smallest example of Cargo, first with ⟦0 and then a border test.

Mission requests:

- The result must be checked, not just “I understand”.
- I'm not sure if you want to go out there, but it's just a matter of time before.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Rust Basics

**Summary:** Ownership, borrowing, Result and thread safety.

**Category:** Rust  
**Level:** Foundation
**Key terms:** Rust, Ownership, Loan, Cargo

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: Foundation
- Applicable environment: Rust 1.85+ / Cargo
- Source: Internal structured curriculum and engineering practices
- Related themes: Rust, Ownership, Leverage, Cargo
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Rust Basics** focuses on Ownership, borrowing, Result and thread safety.

### Learning Outcomes

- Explain what **Rust Basics** solves and when it should be used.
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

- Topic: **Rust Basics**
- Relaid terms: Rust, Ownership, Loan, Life Cycle
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning Objectives |
|Pre-knowledge| Pre-knowledge |
|Language positioning| Language targeting |
|Ownership: core| Ownership: Core in Core |
|Type System| Type System |
|We're safe.| Concurrent security |
|Engineering practice| Engineering Practice |
|Learning Curves| Learning Curve Tips |
|It's the end of this class.| Lesson Summary |
|Basic Syntax:| Basic Grammar Quick Lookup |

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

