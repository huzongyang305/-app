# Rust Ownership, Loan and Life Cycle

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Introduction Expected duration: 16 minutes

## Learning objectives

- It's possible to explain in its own words what "Rust Ownership, Leverage and Life Cycle" solves, not just the term.
- The relationship between "Rust", "ownership," "loaning" and "life cycle" is clear.
- It's a way to put this subject back into Rust's knowledge system, and it shows the boundaries of an adjacent theme.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentence: Move/Copy, borrowing rules and life-cycle indications.

## Pre-knowledge

- One lesson, "Rust Bases", is completed; if available, you can use this course to test yourself.
- This course stage: Introduction. Basic computer operations are required, and programming experience is not required.
- Read it first: Rust, ownership, loan.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Three rules on ownership

1. There's only one person for each value.
2. There can only be one owner at the same time.
3. The owner leaves the field and the value is released (auto call Drop).

Therefore, the assigned value and pass-through default is ** move (Move)**. The original variable is invalid; ⟦0 type (integer number, Boolean, character, structure with Copy field only) is copied by value.

## Loan and loan check.

|Form|Rule|
| --- | --- |
|It's not gonna change.|But there's more than one.|
|Zero, it's variable.|There's only one field, and it can't be borrowed.|
|Life cycle|Mark the valid scope of the reference and ensure that it is not suspended|

Use the checker to get rid of ** data in time for compilation, at a cost of "fighting" with it all the time.

## Common sense.

1. Need to share read-only: multiple ⟦0.
2. Modification required: Reduce the variable loan range or replace it with a return value transfer.
3. The structure itself is difficult to quote: the index (e.g. ⟦ lower mark) or 1⟧ (one-way range)/ 2 (multiple threads).
4. The life-cycle label is only written when the compiler needs help.

## Comparison to GC Language

GC language recovered while running and Rust decided the release point during the compilation period:** There was no pause, there were no additional memory costs** but programmers were required to express ownership.And that's why Rust is suitable for system programming and high performance.

## Common translation errors and fixes

|Error message keyword|Meaning|Repair|
| --- | --- | --- |
| `value borrowed here after move` |Value moved, original variable expired|Use ⟦0, rephrase 1 or adjust title|
| `cannot borrow as mutable` |And there's no change to borrow.|Reduce the variable-love range, or run a check with ⟦0/=1|
| `does not live long enough` |Reference life cycle shorter than use|Extension of the data owner domain, return to ownership|
| `cannot move out of ... which is behind a shared reference` |Trying to move value from unmovable|Use ⟦, 1 or convert to|
| `borrowed value does not live long enough` |Provisional value released after statement|We'll tie it down with a variable, then we'll take the reference.|

Debugging: ** Reads the help given by the compiler (help: ...) and often gives a direct change; then looks at life-cycle suggestions; lastly, considers introducing zero.The majority of the mistakes can be solved by "spreading, not passing."

## When do you need it, Cline?

⟦0 is a legitimate way to get the code running first, but the point is that** you know what you're replicating.** The cost of copying small objects can be negligible.The approach is to rationalize the logic first, then use pprof/benchmark to find out what's really hot, and gradually replace it with a loan or three.

## Scene selection: pass values, quotes or shares

|Scenes|Recommended|Rationale|
| --- | --- | --- |
|Small and complete Copy type (i32, bool)|Direct transfer value|It's a very low cost of copying. The simplest code.|
|Large read-only objects (String, Vec, Structure)|Pass.|Avoid copying and do not transfer ownership|
|Need to modify the caller 's data|Pass.|Clear variable intent, exclusive borrowing|
|Function requires long-term possession of the data|Transfer value (ownership)|Life cycle is clearest|
|Multiple read-only| `Rc<T>` / `Arc<T>` |Quoted Share Ownership|
|Multi-range variable (one / multiple)| `RefCell<T>` / `Mutex<T>` |Run-in check / Crust|
|Cross-references within the structure|Change to Index or ID|The self-referenced structure is extremely difficult to express in Rust|

Project proposal: ** Write "Application" and change to pass or share only when the compiler requests ownership. This avoids going around in a cline or Arc, with codes closer to Rust's usage.In the face of an unspoken self-referenced structure, priority is given to reconfiguring data structures (as indexed) rather than rigid ⟦0.

## It's the end of this class.
Ownership can be achieved only by bearing in mind the following sentence: ** A person is worth a non-disposal of power and may become monopolized; the remaining rules are its reasoning.

<!-- appendix:v1 -->

## Ownership and borrowing

|Concept|Rule|Example:|
| --- | --- | --- |
|Ownership|There's only one person for each value, and the owner is released.| `let s = String::from("a");` |
|Move|Could not close temporary folder: %s|After that, it's not working.|
|Copy|Getting ⟦0 in place to copy|It's still working.|
|I can't borrow it.|There's more than one.| `let a = &s; let b = &s;` |
|Variables|There's only one at the same time and it can't be borrowed.| `let m = &mut s;` |
|Life cycle|Mark the loan relationship and make sure you don't miss it.| `fn f<'a>(x: &'a str) -> &'a str` |
|Slice|A part of the container.| `&v[1..3]` |

```rust
fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() { a } else { b }
}

fn main() {
    let mut data = String::from("hello");

    {
        let r1 = &data;              // 不可变借用
        let r2 = &data;              // 可以同时有多个
        println!("{r1} {r2}");
    }                                // 借用在这里结束

    data.push_str(" world");         // 现在可以可变借用

    let s = String::from("abc");
    let t = s;                       // 所有权移动
    // println!("{s}");              // 编译错误：s 已被移动
    println!("{t}");
}
```

## Common Error Table

|Compiler error|Meaning|Treatment|
| --- | --- | --- |
| `borrow of moved value` |Value moved and used|Change to loan (0⟧) or ⟦1, or adjust life cycle|
| `cannot borrow as mutable, as it is also borrowed as immutable` |It's a conflict between variable and immutable.|Shorten the borrowing field or end it.|
| `cannot borrow as mutable more than once` |There are two variable loans.|Separating with a field, or using ⟦0/ 1|
| `missing lifetime specifier` |The compiler cannot extrapolate which reference is relevant|Visible Mark Life Cycle|
| `does not live long enough` |Quoted Object Destruction Earlier|Hand over ownership, extend the field or use zero.|
| `cannot move out of borrowed content` |Trying to move value from loan|Use ⟦0 or 1/ 2 to remove|
| `value borrowed here after move` |Use after moving|Zero or transliterate|
| `cannot assign twice to immutable variable` |Undeclared|Add ⟦0 or reset.|

## When will you choose?

|Requirements|Select|
| --- | --- |
|Read-only string parameters| `&str` |
|Requires possession and modification of strings| `String` |
|Read-only access sequence| `&[T]` |
|Need to own, grow.| `Vec<T>` |
|Sharing non-variable data|⟦0 or 1⟧ (overline)|
|Need internal variability|⟦0 / ⟦1  (one-way), 2  3|
|It's probably not worth it.| `Option<T>` |
|Could be a failure.| `Result<T, E>` |

## Self-Detected List

- [ ] Can explain the difference between "move" and "replicate" and know which types achieve zero.
- [ ] Remember the rule of `variable monopolization' in the same field.
- [ ] It's a role contraction that solves conflicts rather than brainless zero.
- [ ] Can read ⟦ and locate life cycle problems.
- [ ] Need to use ⟦0 for cross-line sharing.

<!-- appendix:v2 -->

## Zero basis: Ownership, understanding Rust's core rules

### What is it?

Ownership is the way Rust manages memory:** Each value has one owner.**
The owner leaves the field and the value is automatically released. This requires neither recycling nor leakage of memory.

### Three rules.

1. Rust has a variable for each value**.
2. At the same time** there can only be one owner.
3. The value is automatically discarded when the owner leaves the area.

### "Leave" for movement and cloning.

|Operation|A metaphor.|Code|Is the original variable still working?|
| --- | --- | --- | --- |
|Move|Give it to someone else.| `let b = a;` |I can't.|
|Cloning|Copy it to each other.| `let b = a.clone();` |Yes.|
|Copy copy|Give each other a note.| `let b = n;`（i32） |Yes.|
|Use it, Borrow.|I'll borrow it. No transfer.| `let b = &a;` |Yes.|
|Variables|I'm gonna borrow it, and I can do it all by myself.| `let b = &mut a;` |Can't use it again during the loan period|

```rust
let s1 = String::from("hello");
let s2 = s1;                    // 所有权移动，s1 失效
// println!("{s1}");            // 编译错误：value borrowed here after move

let s3 = s2.clone();            // 深拷贝，两边都能用
println!("{s2} {s3}");

let n1 = 5;
let n2 = n1;                    // i32 实现了 Copy，n1 仍可用
println!("{n1} {n2}");
```

### ♪ To borrow a rule that makes you love and hate

** At any given time, only one of the following can be satisfied:**

- Any more** cannot be borrowed** ⟦, or
- That's exactly what I want to do.

```rust
let mut data = vec![1, 2, 3];

let a = &data;        // 不可变借用
let b = &data;        // 再来一个也可以
println!("{a:?} {b:?}");   // 最后一次使用后，a、b 的借用结束

let c = &mut data;    // 现在可以可变借用了
c.push(4);
println!("{c:?}");
```

That's why Rust can** eliminate data competition during the compilation period: reading and writing cannot occur simultaneously.

### Quote and unquote

```rust
fn length(s: &str) -> usize { s.len() }        // 借用，不夺走所有权

fn add_one(n: &mut i32) { *n += 1; }           // * 解引用后修改

let mut x = 1;
add_one(&mut x);
println!("{x}");                                // 2
```

The function parameter is used to avoid loss of ownership by ⟦0 instead of 1.

### Intuitive understanding of life cycle

```rust
fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() { a } else { b }
}
```

⟦ means:** The reference to return cannot live longer than the two inputs.**
Only remember at the beginning: when returning to a reference, it must come from parameters rather than temporary values created within functions.

### It's the seven most easy pits for a rookie.

|The pit.|Wrong word.|The right thing to do.|
| --- | --- | --- |
|Continue after moving| `borrow of moved value` |Use ⟦0 or borrow it.|
|Changes during loan| `cannot borrow as mutable` |Let's finish the loan, then fix it.|
|There's also a variable and an immutable loan| `cannot borrow ... more than once` |Shortening the borrowing field|
|Return local variable references| `does not live long enough` |Back to ownership, not one.|
|There's no such thing as conflict.| `already borrowed` |Use subscript, split or collect index|
|Structure holds references|Lack of life cycle parameters|Plus life-cycle label or change of ownership|
|All over the place.|It's been compiled, but it's not working.|Let's see if we can borrow it.|

### Handheld Practice: Secure String Processing

```rust
fn first_word(s: &str) -> &str {
    match s.find(' ') {
        Some(i) => &s[..i],
        None => s,
    }
}

fn append_excited(mut s: String) -> String {
    s.push('!');
    s
}

fn main() {
    let text = String::from("hello rust world");
    println!("第一个词：{}", first_word(&text));   // 只借用，text 还在

    let owned = text;                              // 移动给 owned
    let owned = append_excited(owned);             // 传进去再返回
    println!("{owned}");
}
```

### Learn how to measure yourself.

- [ ] Three rules of silent ownership.
- [ ] It explains the difference between mobile, cloned and duplicated.
- [ ] Can you say two words about the rules?
- [ Laughs ] Know why the original variable is still available after value, and it's not working.
- [ ] The error of "continue after moving" can be changed to a loan or cloning.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of the course: Repeats, experiments and deliveries around "Rust, Ownership, Loan" each result is subject to scrutiny.

Let's get the cargo check through, then fill up ownership, wrong and parallel borders, and finally run clippy.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with Rust?
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

**Title:** Ownership & Borrowing

**Summary:** Move/Copy, borrow rules and lifetimes.

**Category:** Rust  
**Level:** Introduction
**Key terms: ** Rust, Ownership, Loan, Move

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning phase: Introduction
- Applicable environment: Rust 1.85+ / Cargo
- Source: Internal structured curriculum and engineering practices
- Related themes: Rust, Ownership, Leverage, Move
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Ownership & Borrowing** focuses on Move/Copy, borrow rules and lifetimes.

### Learning Outcomes

- Explain what **Ownership & Borrowing** solves and when it should be used.
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

- Topic: **Ownership & Borrowing**
- Relaid terms: Rust, Ownership, Loan, Life Cycle
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Three rules on ownership|The three rules of Ownership|
|Loan and loan check.|Loan and loan check.|
|Common sense.|Common sense.|
|Comparison to GC Language|Comparison to GC Language|
|Common translation errors and fixes|Common translation errors and fixes|
|When do you need it, Cline?|When do you need it, Cline?|
|Scene selection: pass values, quotes or shares|Scene selection: pass values, quotes or shares|
|It's the end of this class.| Summary |

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

