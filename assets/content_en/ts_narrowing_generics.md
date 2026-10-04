# Type TypeScript

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Introduction Expected duration: 16 minutes

## Learning objectives

- I can explain in my own words what the "TypeScript-type narrow and broad" solution is, not just a term.
- The relationship between "TypeScript", "type narrow," "pane" and "discoverable combinations" is clear, with one example.
- It's a way to put this subject back into the "TypeScript" knowledge system, which is an example of how it borders on each other.
- It is possible to complete this course and check its results using acceptance standards.

> Synopsis of sentence: five narrow instruments, identifiable combinations, broad binding and infer.

## Pre-knowledge

- One lesson, the TypeScript-type system, is completed; if available, this course can be used to test itself.
- This course stage: Introduction. Basic computer operations are required, and programming experience is not required.
- Read it first: TypeScript, narrow and broad.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Five tools to narrow down.

|Means|Usage|
| --- | --- |
| typeof |Distinguishing original types|
| instanceof |Examples of sector classification|
| in |To determine if the attribute exists.|
|Visible Union|Distinguishing members with common fields (e. g. ⟦)|
|Guard type|Custom ⟦0 function or asserted function ⟦1|

The most useful model for modelling is the recognition of joints + switch: it can be written in order, request results and form validation. A new state compiler will point to all locations that need to be processed.

## Broad and binding

Pandemic re-uses with components while maintaining the security of type: ⟦0. The binding requirement is to have id; the default parameter ⟦3.

## Condition type and infer

⟦ Branches at the level of type; 1 is used to extract fragments of types, such as the extraction function returns the type of array elements and the result type for Promise. This is the basis on which tool types are achieved.

## Common trap.

1. Misuse ⟦ and render the check ineffective - external data first, then narrow.
2. It's too much to say that ⟦ will cover up the error and give priority to a type of guard.
3. It's not empty, it's just to keep the compiler shut and run or fall.
4. A broad-based frame reduces readability and is broken down to a named type if necessary.

## It's the end of this class.
The type capacity of TypeScript is concentrated in two places:** narrowness (blank-type)** and ** panoramic (transformation);** mastering these points makes it possible to express operational constraints clearly.

<!-- appendix:v1 -->

## Quick check.

|It's a narrow way.|Writing|Apply scene|
| --- | --- | --- |
| `typeof` | `if (typeof v === "string")` |Original Type|
|It's worth it.| `if (v) {}` |Discrepancies `undefined`23⟧|
|Empty value judgement| `if (v != null)` |Also exclude ⟦1|
|⟦Operator| `if ("id" in v)` |Distinguished by field in joint type|
| `instanceof` | `if (e instanceof Error)` |Class Examples|
|Literally| `if (r.status === "ok")` |Visible unions (recommended)|
|Custom type of guard| `function isUser(v: unknown): v is User` |Validate External Data|
|Accusations| `function assert(cond: unknown): asserts cond` |Shrink if you're wrong.|
| `Array.isArray` | `if (Array.isArray(v))` |Numerical judgement|
|Overtaken.| `default: const _x: never = v;` |Make sure it's done.|

We'll find out what it is.

```ts
type Result =
  | { status: "ok"; data: string }
  | { status: "error"; message: string };

function render(result: Result): string {
  switch (result.status) {
    case "ok":
      return result.data;        // 自动收窄到 ok 分支
    case "error":
      return result.message;
    default: {
      const never: never = result;   // 新增成员时这里会编译报错
      return never;
    }
  }
}
```

## Pancreas.

|Writing|Meaning|
| --- | --- |
| `<T>` |Any type|
| `<T extends object>` |Must be the object type|
| `<T extends { id: string }>` |At least that's the shape.|
| `<T extends keyof U>` |Only U keys|
| `<T = string>` |Provide default type parameters|
| `<T extends string \| number>` |Joint binding|
| `function f<T>(x: T): T` |Return value to reference type|
| `ReturnType<typeof f>` |Retrieve value|
| `Parameters<typeof f>[0]` |Take First Parameter Type|
| `as const` |Let's narrow it down.|

```ts
// 约束 + keyof：安全地按字段取值
function pluck<T, K extends keyof T>(items: T[], key: K): T[K][] {
  return items.map((item) => item[key]);
}

const users = [{ id: 1, name: "小明" }];
const names = pluck(users, "name");   // string[]
// pluck(users, "age");               // 编译报错，及时发现问题
```

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
| `JSON.parse(text) as User` |Compiled, run-time fields are missing|Unverified data. External input is checked on Zod|
|All over the place.|Type check failed, error delayed to line|Shrink with ⟦0+type guards|
|It's an abuse of air.|Run-time|We're going to use the oxen.|
|Zero, hard.|Covering the real type doesn't match.|We'll change the definition first, but only after school.|
|The function returns 'T\|♪ And I don't care ♪|Caller forgets emptiness.|I'll tell you what it is.|
|It's too broad.|Error reporting attribute in function|Plus zero.|
|Use the 0 to get a 1|Overtime indexing|Unequivocally claimed to be zero, or modified for one.|
|It's a set of zeroes.|It could be.|First emptied, or co-packaged.|
|Type assertion repeated in cycle|The code's loud.|Reuse verification as a type guard|

## Self-Detected List

- [ ] An interface that can replace the "optional fields" with an identifiable combination.
- [ ] External data first ⟦, then narrow down by type of guard.
- [ ] The type of safe value-taking function is written with ⟦0.
- [ Laughs ] Knows that a zero is not running.
- [ Laughing ] In the ⟦0, we'll run a full check.

<!-- appendix:v3 -->

## Zero-basic details: narrow and broad

### What is it?

It's the "broad" type, and it's a very specific one.
A panoramic function is created for a variety of types without losing type information. Together, it's the skeleton of a Type TypeScript system.

### It's a life metaphor.

|Concept|A metaphor.|Annotations|
| --- | --- | --- |
|Joint Type `A \\| B` |An unopened delivery box.|I don't know what it is.|
|Shrink.|Open the box and check.|We'll figure out what it is.|
|Pan|Modifier|A set of molds that fit multiple dimensions.|
|Zero.|The size of the mold|What's the appropriate type?|
|Guard type|Label|Tell the compiler, it's definitely him now.|

### Five ways to narrow it down.

```typescript
type Shape =
  | { kind: "circle"; radius: number }
  | { kind: "square"; side: number };

function area(shape: Shape): number {
  switch (shape.kind) {                 // 1. 可辨识联合：按字面量字段分流
    case "circle":
      return Math.PI * shape.radius ** 2;   // 这里 shape 已收窄
    case "square":
      return shape.side ** 2;
  }
}

function format(value: string | number | Date): string {
  if (typeof value === "string") return value;        // 2. typeof
  if (value instanceof Date) return value.toISOString();  // 3. instanceof
  return value.toFixed(2);                            // 剩下是 number
}

function isUser(v: unknown): v is { id: number; name: string } {   // 4. 自定义守卫
  return (
    typeof v === "object" && v !== null &&
    typeof (v as any).id === "number" &&
    typeof (v as any).name === "string"
  );
}

const list: (string | null)[] = ["a", null];
const values = list.filter((x): x is string => x !== null);   // 5. 收窄式 filter
```

|Means|Apply scene|
| --- | --- |
| `typeof` |Original type of judgement|
| `instanceof` |Case judgement|
| `in` |To determine whether an attribute exists.|
|Font Fields (Recordable Union)|Status machine, event object|
|Custom type of guard|External data validation|

### Exhaustion: Automatically reporting errors when adding a branch

```typescript
function assertNever(value: never): never {
  throw new Error(`未处理的分支：${JSON.stringify(value)}`);
}

type Status = "pending" | "running" | "done";

function label(s: Status): string {
  switch (s) {
    case "pending": return "等待中";
    case "running": return "运行中";
    case "done": return "已完成";
    default: return assertNever(s);      // 将来新增状态时这里会编译报错
  }
}
```

### It's a four-fold feature.

```typescript
// 1. 基础泛型：输入什么类型就返回什么类型
function identity<T>(value: T): T {
  return value;
}

// 2. 带约束：要求至少有 id 字段
function pluck<T, K extends keyof T>(items: T[], key: K): T[K][] {
  return items.map((item) => item[key]);
}

// 3. 默认类型参数
type Result<T = unknown> = { ok: true; data: T } | { ok: false; error: string };

// 4. 条件类型 + infer：从类型里提取片段
type ElementType<T> = T extends (infer U)[] ? U : never;
type N = ElementType<number[]>;        // number
```

### ⟦ and index access

```typescript
type User = { id: number; name: string; email?: string };

type Keys = keyof User;                 // "id" | "name" | "email"
type NameType = User["name"];           // string

function get<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}
const u: User = { id: 1, name: "小明" };
const n = get(u, "name");               // 推断为 string
```

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|I'm gonna make it up to you.|Error while running|Check it out with type.|
|Parameters|Unknown|Let T appear in parameter position|
|It's too much.|The caller can't get in.|We're going to use the Zero limit.|
|I forgot to take care of it.|I'm sorry.|Zero or zero first.|
|The type guards will only be given one.|Embedded fields still reporting error|Level by Level|
|I'm going to go around the wrong side of it.|All clear.|We're going to need a few more guards.|
|Default branch does not write ⟦0|Add Status Leaking|We'll take the bottom of it.|
|It's too deep.|No one can understand.|Blank Name Type|

### Handheld practice: Safely remove embedded fields

```typescript
type ApiResponse =
  | { status: "ok"; data: { id: number; tags: string[] } }
  | { status: "error"; message: string };

function handle(res: ApiResponse): string {
  if (res.status === "error") {
    return `失败：${res.message}`;
  }
  return `成功，id=${res.data.id}，标签 ${res.data.tags.join("/")}`;
}

function safeGet<T, K extends keyof T>(obj: T | null, key: K): T[K] | undefined {
  return obj === null ? undefined : obj[key];
}

const user = { id: 1, name: "小明" };
console.log(safeGet(user, "name"));     // string | undefined
console.log(handle({ status: "ok", data: { id: 2, tags: ["a"] } }));
```

### Learn how to measure yourself.

- [ ] It's possible to say which scenarios apply each of the five narrow approaches.
- [ ] Can write a custom-type guard function.
- [ Laughs ] Know why you're receiving the one.
- [ ] Can explain the meaning of ⟦0.
- [ Chuckles ] Know why not use a ⟦0 instead of real verification.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeating, experimenting and delivering around "TypeScript," each result is subject to scrutiny.

The type check is first passed, then a type error is created and the final validation and testing takes place.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the "TypeScript" problem?
2. Without it, what concrete consequences would there be?
3. What's it got to do with being narrow?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Write a minimum-type example of how to get through, make an intentional type error.

Mission requests:

- The result must be checked, not just “I understand”.
- At least cover the two key words "TypeScript" and "type narrowness".
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Narrowing & Generics

**Summary:** Narrowing, discriminated unions, generics and infer.

**Category:** TypeScript  
**Level:** Introduction
**Key terms:** TypeScript, narrow, broad, identifiable combination

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning phase: Introduction
- Applicable environment: TypeScript 5.x / Node.js 22+
- Source: Internal structured curriculum and engineering practices
- Related topics: TypeScript, narrow, broad, identifiable, infer
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Narrowing & Generics** focuses on Narrowing, discriminated unions, generics and infer.

### Learning Outcomes

- Explain what **Narrowing & Generics** solves and when it should be used.
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

- Topic: **Narrowing & Generics**
- Relaid terms: TypeScript, narrow, broad-based, identifiable combination
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Five tools to narrow down.|Types' five methods.|
|Broad and binding|Broad and binding|
|Condition type and infer|Conditions and infer|
|Common trap.|Common trap.|
|It's the end of this class.| Summary |
|Quick check.|Types narrow it down.|
|Pancreas.|Pancreas.|
|Common Error Table|Common mirrors|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

