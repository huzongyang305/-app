# JavaScript and Operating Environment

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning phase: Foundation = Projected duration: 12 minutes

## Learning objectives

- It's not like you can explain in your own words what the problem is with JavaScript and the operating environment.
- The relationship between JavaScript, Node, Browser and Console is clear.
- It's a way to put back the knowledge of JavaScript, which is how it works with each other.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentence: Discrepancies between browsers and Node, ways to run them, strict patterns and code quality tools.

## Pre-knowledge

- The basic file, command line or browser operation is performed; the key words of this course are checked first when there are unfamiliar terms.
- This course stage: Foundation. It is recommended to read and write simple codes or commands, with basic concepts such as variables, input output, etc.
- Read it first: JavaScript, Node, Browser.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## What's JavaScript?

JavaScript is the dynamic type** based on prototype** script language, standard name CMAScript.It can run pages in a browser, and it can use the Node.js writing server, command line and desktop applications.

## Two operating environments

|Environment|Capacity provided|
| --- | --- |
|Browser|DOM, Events, Fetch, LocalStorage, Canvas|
| Node.js |File system, process, network, npm ecology|

Language core (variables, functions, objects) is common on both sides and host API is different.

## Run with

```html
<!-- 浏览器：defer 表示解析完 HTML 再执行，避免阻塞 -->
<script src="app.js" defer></script>
```

```bash
node app.js      # 运行脚本
node             # 进入 REPL 交互模式
```

```javascript
console.log('Hello, JavaScript!');
console.warn('警告');
console.error('错误');
console.table([{ a: 1 }, { a: 2 }]);   // 以表格展示
```

## Strict Mode

```javascript
'use strict';    // 禁止隐式全局变量、静默失败等历史行为
```

ES Module default is a strict mode; the new code suggests using modules rather than global scripts.

## Code quality tool

```bash
npm install --save-dev eslint prettier
npx eslint . --fix
npx prettier --write .
```

ESLint captures potential errors, which are aligned with the standard configuration of front-end projects.

## It's the end of this class.
Distinguishing between a browser or Node, then checking the corresponding API; both of them are common.

<!-- appendix:v1 -->

## Quick check.

|Capacity|Browser| Node.js |
| --- | --- | --- |
|Operation DOM|Yes.|None|
|Get user events|Yes.|None|
|Read and write local files|Limited (File API)|Yes.|
|Launching Network Request| `fetch` |⟦ (18+ built)|
|Timer| `setTimeout` / `setInterval` |Same thing.|
|Global| `window` | `globalThis` |
|Modular System|ESM is the master.|ESM and CommonJS support|
|Environmental variables|None (injected during construction)| `process.env` |

Script by Quick Check:

|Writing|Parsing Blockage|Time for implementation|
| --- | --- | --- |
| `<script src="a.js">` |Block Parsing|Immediately and sequentially.|
| `<script async src="a.js">` |No blocking.|Execute immediately after downloading (in uncertain order)|
| `<script defer src="a.js">` |No blocking.|DOM executes sequentially after resolution|
| `type="module"` |No blocking.|Default defer semantics, domain independent|

## Console!

|Purpose|Writing|
| --- | --- |
|Print Value| `console.log(a, b)` |
|Print Object Structure| `console.dir(obj, { depth: null })` |
|Show arrays| `console.table(list)` |
|Group Output| `console.group()` / `console.groupEnd()` |
|Time| `console.time("t")` / `console.timeEnd("t")` |
|I don't know.|Zero.|
|Call Inn| `console.trace()` |
|Breakpoint|It's in the code.|

## Common Error Table

|Misreporting or phenomena|Meaning|Treatment|
| --- | --- | --- |
| `ReferenceError: x is not defined` |Use variable without declaration|Check spell and field, then use|
| `TypeError: Cannot read properties of undefined` |Visited properties of ⟦0|Use an optional chain or pre-empt it.|
| `SyntaxError: Unexpected token` |Syntax Error (often missing brackets or comma)|Check if the last line is complete.|
|Page Report|Cannot initialise Evolution's mail component.|Change to ESM's ⟦|
| `process is not defined` |Node API on the browser|Change the front-end scheme or inject it on construction|
|Scripts are running in zero, but they can't get the elements.|Script Before DOM|Plus zero or before one.|
|It's a mess.|No, it's not.|Change to ⟦0 or module when dependent|
|Variable modified but not updated|Lack of rendering logic|Modify Data Visible Update or Trim Frame Rendering|
|Zero, repeat.| `SyntaxError: Identifier has already been declared` |Do not repeat statements in the same field|
|Error reported in strict mode (e.g. undeclared value)|Silently failed.|Exposure with ESM or ⟦0|

## Self-Detected List

- [ ] Can you tell me what the browser and Node are offering each other?
- [ ] Know the difference between ⟦ and 1 and use the scene.
- [ ] It'll be debugged with ⟦,  and 2.
- [ ] There's an error in reporting the empty value on the chain.
- [ ] Front-end code is used for ESM import, without mixing ⟦0.

<!-- appendix:v2 -->

## Zero base details: Where does JavaScript run?

### What is it?

JavaScript is** script language: need not be compiled in advance and implemented by the operating environment immediately.
It has two main hosts: a browser (capable of operating the page) and Node.js (reading and writing documents, starting services).

### It's a life metaphor.

|Concept|A metaphor.|Annotations|
| --- | --- | --- |
|Engine|Translator| V8（Chrome/Node）、JavaScriptCore（Safari） |
|Host Environment|The translator's office.|The browser gave ⟦, Node gave ́s|
|Event Cycle|Get in line.|Synchronize the task and then retrace it.|
|One-way|One window for business.|So it takes time to move, or the interface dies.|

** Same language, available API depends on the host environment** - There's no ⟦1 in the browser and there's not one in Node.

### Dismantling first program by line

```javascript
// 浏览器控制台或 Node 里都能运行
console.log("Hello, World!");   // 打印到控制台

const name = "小明";             // 常量，不能重新赋值
let age = 18;                   // 变量，可以改
age = age + 1;                  // 重新赋值

console.log(`你好，${name}，明年 ${age} 岁`);
```

|Okay.|What are you doing?|Why do you say that?|
| --- | --- | --- |
| `console.log(...)` |Output|The most common means of debugging|
| `const name = ...` |A name you can't revalue.|It's okay, it's safer.|
| `let age = 18` |Declare a variable that can be changed|It really needs to be changed.|
| `` `...${x}...` `` |Template String|Inverted + 0 to insert value|

### It's a bargain.

|Keyword|Can you revalue it?|Scope|Can you repeat the statement?|Recommendations|
| --- | --- | --- | --- | --- |
| `var` |Yes.|Function Fields|Yes.|I'll see you in the old code.|
| `let` |Yes.|Area ⟦0|I can't.|It needs to be changed.|
| `const` |I can't.|Area ⟦0|I can't.|** Default selection**|

Note: 0 is locked in "keep" and not the content.
It's legal, but it'll be wrong.

### How do you get in the browser?

```html
<!DOCTYPE html>
<html lang="zh-CN">
  <head><meta charset="utf-8"><title>JS 入门</title></head>
  <body>
    <p id="out">等待中…</p>
    <script src="main.js"></script>
    <!-- 也可以直接内联：<script>console.log('hi')</script> -->
  </body>
</html>
```

Scripts in front of zero, or with one.

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|Compare with 0|It's true.|I'll take it all.|
|Forget it.|It's Promise, not the result.|In the ⟦0 function, 1|
|In the cycle, use zero.|It's the last one.|Change to "0"|
|Granted without a statement of variable|Rigorous mode of reporting, impregnable pattern of contamination.|Always use 0 / 1|
|Numbers with Strings|♪ I've got one ♪|Let's do it.|
|Read directly the properties of ⟦0| `TypeError: Cannot read properties of undefined` |Use the Zero-Cyclops.|
|I thought it was a copy.|The copy affects the object.|We're gonna use the roll-out, Zero.|
|Chinese Punction| `SyntaxError` |It's all in English.|

### Three types of operating environment to separate.

|Environment|What can I do?|What can't be done?|
| --- | --- | --- |
|Browser|Operation DOM, request, localStorage|Read and write local files|
| Node.js |Read and write files, start HTTP services|Access|
|It's both.|Syntax: Internal, Promise, JSON| —— |

### Hand hands practice: command greetings and simple statistics

```javascript
// Node 环境：node hello.js
const readline = require("node:readline/promises");

async function main() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  const name = (await rl.question("请输入姓名：")).trim();
  const scores = [88, 92, 79];
  const total = scores.reduce((sum, n) => sum + n, 0);
  const avg = (total / scores.length).toFixed(1);

  console.log(`你好，${name || "朋友"}！平均分 ${avg}`);
  rl.close();
}

main();
```

### Learn how to measure yourself.

- [ ] Can you tell me what's going on with the browser and Node?
- [ Laughs ] Can you explain why the array of declarations can still be one?
- [ ] Know the difference between ⟦ and 1 in a loop.
- [ ] Can you tell me the difference between ⟦0 and 1?
- [ Chuckles ] Know why the script was suggested before or with a twilight.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of the course: Repeating, experimenting and delivering around JavaScript, Node, Browser.

Either the Node or the browser is active first, and then rewrite between steps and errors.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with JavaScript and operating environment?
2. Without it, what concrete consequences would there be?
3. What's it got to do with Node?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Writes a minimum example of at least 3 group inputs in the browser console or Node.js.

Mission requests:

- The result must be checked, not just “I understand”.
- This post is part of our special coverage Syria Protests 2011.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** JavaScript & Runtimes

**Summary:** Browser vs Node, running code, strict mode and tooling.

**Category:** JavaScript  
**Level:** Foundation
**Key terms:** JavaScript, Node, browser, console, ECMAScrypt

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: Foundation
- Applicable context: Node.js 22+/ Modern Browser
- Source: Internal structured curriculum and engineering practices
- Related themes: JavaScript, Node, Browser, Console, ECMAScrypt
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**JavaScript & Runtimes** focuses on Browser vs Node, running code, strict mode and tooling.

### Learning Outcomes

- Explain what **JavaScript & Runtimes** solves and when it should be used.
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

- Topic: **JavaScript & Runtimes**
- Relaid terms: JavaScript, Node, browser, console
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|What's JavaScript?|What's JavaScript?|
|Two operating environments|Two operating environments|
|Run with|Run with|
|Strict Mode|Strict Mode|
|Code quality tool|Code MassTools|
|It's the end of this class.| Summary |
|Quick check.|Quick check.|
|Console!|Console!|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

