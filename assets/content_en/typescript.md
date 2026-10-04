# Type-TypeScript

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Advanced

## Learning objectives

- It is possible to explain in its own words what the TypeScript-type system solves, not just a term.
- The relationship between "TypeScript", "type," "pane" and "shrunk" is clear, with one example.
- It's a way to put this subject back into the "TypeScript" knowledge system, which is an example of how it borders on each other.
- It is possible to complete this course and check its results using acceptance standards.

> Synopsis of a sentence: narrow, broad, tool type and project configuration.

## Pre-knowledge

- The basic file, command line or browser operation is performed; the key words of this course are checked first when there are unfamiliar terms.
- This course stage: Advanced. It is recommended to have a complete basis in the same direction, reading longer code, configuration or system design instructions.
- Before we begin: TypeScript, type, general.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Why would I need a typScript?

JavaScript's type error is only exposed when running.TypeScript performs static checks during the compilation period, while retaining all JS capabilities - type exists only for the translation period and product is still normal JavaSclipt.

## Base Type

|Type|Annotations|
| --- | --- |
|Original Type| string、number、boolean、null、undefined、symbol、bigint |
|Numerical & Quantities|⟦ 0, 1⟧ (long and fixed)|
|Object Type| `{ id: number; name: string }`、interface、type |
|Joint and cross-cutting| `A \| B`、`A & B` |
|Font Type| `'success' \|'error', compress the value into a fixed pool.|
| any / unknown / never |any unknown secure external input; never indicates impossible|

Practice principle: ** Use unknown without any**; external data (interface return, JSON) become unknox and then narrow the type.

## interface with type

Interface is suitable for describing objects and scalable contracts (in support of declarations); type is more flexible, defining the grouping, condition type and map types.The group usually agrees: object structure is interface, complex type.

## Broad and Type Operations

(a) Broad re-use functions and components while maintaining the security of their type;Common tools include Partial, Required, Pick, Omit, Record, ReturnType and Awaited.The condition type matches the pattern at a level of type, and the map type changes properties in bulk (e.g. to make all attributes optional or read-only).

## Zoom in.

Common means: typeof, indiscriminated union, custom type guards (0) and asserted functions.The most practical model for modelling operations is the recognition of joint + switch.

## Project Configuration Points

1. Starts the set of options (strictNullChecks, noImplicitany, strictFunctionTypes).
2. Type check included in CI: 0 ⟦ to avoid type error.
3. Run-time validation is not possible: the type does not exist at running time and interface data still need to be verified like zod/valbot.
4. Avoid the abuse of claims (as) and non-empty allegations (! ), which conceal real mistakes.
5. Declaration documents (.d.ts) are used to fill in non-type third party libraries.

## It's the end of this class.
The value of TypeScript is ** to advance a type error from running until the translation period** and to express business constraints by type.A broad, narrow and tool-type allows for both secure and reconstructable frontends and Node codes.

<!-- appendix:v1 -->

## Quick check

|Type|Writing|Annotations|
| --- | --- | --- |
|Original Type| `string`、`number`、`boolean`、`bigint`、`symbol` |Lowercase, no packing type.|
|Numeric|Zero or one.|It's recommended.|
|Blocks| `[string, number]` |Fixed length and order|
|United| `string \| number` |It could be one of them.|
|Cross| `A & B` |Two sets of attributes at the same time|
|Volume| `"on" \| "off"` |Exact Value|
|Object| `{ id: number; name?: string }` |Zero is optional.|
|Read only| `readonly string[]`、`Readonly<T>` |Compiler period forbids modification|
|Index Signature| `Record<string, number>` |Key set|
|Empty| `string \| null` |It's got to be done.|
|Any| `any` |Close the check and try to avoid it.|
|Unknown| `unknown` |It's a secure version.|
|Never come back.| `never` |Return value for dropping abnormal or dead|
| `void` |No return value|Distinction from ⟦0|

## tsconfig popular check

|Options|Recommendations|Role|
| --- | --- | --- |
| `strict` | `true` |Open all critical checks.|
| `target` |I'll be right back.|Output Syntax:|
| `module` / `moduleResolution` |Click on runtime selection|Decision to Import Parsing|
| `noUncheckedIndexedAccess` | `true` |The result of the below-line interview is probably zero.|
| `exactOptionalPropertyTypes` |Optional|Tighter split between "miss" and "no".|
| `noImplicitOverride` | `true` |We have to rewrite it.|
| `skipLibCheck` | `true` |Skip relying type check, accelerate compilation|
| `noEmit` |C.C. Time|Just type check.|
| `paths` |As required|Path alias. Packer needs to be synchronized|
| `declaration` |Treasury project|Generate ⟦0|

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
|Use ⟦0 or 1 as type|It's almost right. It doesn't make sense.|Use specific interfaces or ⟦0|
|All over the place.|Error delay to run|Definition of narrow or complementary type|
|It's not empty.|Could be 0% on run.|Turn it on, zero and clear.|
|The function attribute defined in ⟦1 and 2 are mixed|The difference between the types is confusing.|Clear semantics, team style.|
|Mixing with string face|Inconsistencies in running behaviour|Simple scenes are combined directly.|
|It's a direct claim.|Reporting error when field does not exist|Run-time validation (zod et al.)|
|The object attribute of the declaration is modified|Unexpected changes in status|Use 0 or 1|
|Turn back to the normal function.|It's missing.|Bind with arrow function or visible|
|Import type used for import|Packing up big.|Use Zero.|
|Ignoring, misreporting.|On the line.|Visible processing ⟦0/ 1⟧|

## Self-Detected List

- [ ] All new items open.
- [ ] Replace the unnecessary listing with a combination of words.
- [ ] External data first, zero and then no direct assertion.
- [ ] Import pure types with ⟦0.
- [ Laughs ] CI executes the type door ban alone.

<!-- appendix:v2 -->

## Zero basis: Type of contract for JavaScript

### What is it?

Type = JavaScript+ System. The type exists only during the compilation period**
Compiled or normal JavaScript. The value of this is to advance "the error you find when running" into the code.

### It's a life metaphor.

|Concept|A metaphor.|Annotations|
| --- | --- | --- |
|Type|Contract terms|What's this variable gonna do?|
|Compiler|Auditor|Compiled to check whether the contract was breached|
|Compiled|Get rid of the note.|All the information is gone, only JS.|
| `any` |Rip off the contract.|Turn it off. It's like no TS.|
| `unknown` |Unverified Packages|You have to check it before you use it.|

### Dismantling the first paragraph by line

```typescript
type User = {                 // type 定义结构
  id: number;
  name: string;
  email?: string;             // ? 表示可选
};

function greet(user: User): string {
  return `你好，${user.name}`;
}

const u: User = { id: 1, name: "小明" };
console.log(greet(u));
```

|Syntax:|Meaning|
| --- | --- |
| `type User = {...}` |Define a type alias|
| `id: number` |Field type engagement|
| `email?: string` |Optional fields, probably not available|
|⟦ (after function)|Function returns value|
| `const u: User = ...` |The object must meet the agreement of User|

### What's the choice?

|Contrast| `interface` | `type` |
| --- | --- | --- |
|Synchronising folder|That's good.|That's good.|
|Joint Type|I can't.| `type A = B \| C` |
|Condition type/ map|I can't.|Yeah.|
|Declaration Merge|Support (auto-merger)|Not supported|
|Recommendations|When the subject is exposed, it needs to be expanded.|Joint, tool type, group type|

### Type extrapolation and Notes

```typescript
const count = 3;                    // 推断为 number，不用手写
const name: string = "小明";         // 类型不明显时写出来更清楚

function add(a: number, b: number) { // 参数必须标注
  return a + b;                      // 返回值自动推断为 number
}
```

Rule: ** Inferences must not be made (parameters, public API).

### It's three special types: 0, 1 and 2

|Type|Meaning|Use Recommendations|
| --- | --- | --- |
| `any` |Close Check|Try to avoid it and replace it with zero.|
| `unknown` |I don't know. We have to narrow it down before we use it.|Handle external input preferences|
| `never` |It's never worth it.|The function that you do not want to return, check it out|
| `void` |No return value|Event Handling, Print Class Functions|

```typescript
function parse(input: unknown): number {
  if (typeof input === "number") return input;      // 收窄
  if (typeof input === "string") return Number(input);
  throw new Error("不支持的输入类型");
}
```

### Configure: 3 lines to determine the quality of projects

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true
  }
}
```

It's gonna be a one-time check of `strictNullChecks`, 2 and so on.

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|It's not a good idea.|Type check is false|I'm going to take it easy.|
|It's a direct call.|It's still possible to crash.|Use zod to check while running|
|♪ Thinks the type can protect the running|Error with interface data|Do a true check on the boundary.|
|Forget about the chain.|Error in empty value|Use 0 and 1|
|It's only a zero, but I thought it would be checked.|Type error on line|C.I., run alone!|
|Ignore Index Crossing|Numerical values may be available|Let's go.|
|It's too complicated.|No one can understand.|Split to Small Naming Type|
|Function Parameters Do Not Mark Type|Implicitly any|Visible Parameters and Return Value|

### Handheld practice: Safely deciphered interface back

```typescript
type ApiUser = { id: number; name: string };

function isApiUser(value: unknown): value is ApiUser {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return typeof v.id === "number" && typeof v.name === "string";
}

async function fetchUser(url: string): Promise<ApiUser> {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`请求失败：${res.status}`);
  const data: unknown = await res.json();
  if (!isApiUser(data)) throw new Error("返回结构不符合预期");
  return data;
}
```

⟦-type guards are the most stable combination of external data processing.

### Learn how to measure yourself.

- [ ] Can you tell me if the TypeScript type exists while running?
- [ Chuckles ] Can explain where the zero is safer than the one that's safe.
- [ ] Can write a kind of guard function.
- [ Laughs ] Know what about the check.
- [ Laughs ] Can you tell me about the scenes with the two of them?

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeats, experiments and deliveries around "TypeScript, Type, Broad" each result is subject to scrutiny.

The type check is first passed, then a type error is created and the final validation and testing takes place.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with TypeScript?
2. Without it, what concrete consequences would there be?
3. What's it got to do with "type"?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Write a minimum example of the type that lets ⟦ pass, then intentionally creates an error.

Mission requests:

- The result must be checked, not just “I understand”.
- "TypeScript" and "type," at least.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** TypeScript Types

**Summary:** Narrowing, generics, utility types and strict mode.

**Category:** TypeScript  
**Level:** Advanced
**Key terms:** TypeScript, type, broad, category narrow

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: advanced
- Applicable environment: TypeScript 5.x / Node.js 22+
- Source: Internal structured curriculum and engineering practices
- Related themes: TypeScript, broad, narrow
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**TypeScript Types** focuses on Narrowing, generics, utility types and strict mode.

### Learning Outcomes

- Explain what **TypeScript Types** solves and when it should be used.
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

- Topic: **TypeScript Types**
- Relaid terms: TypeScript, Type, Panetype
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Why would I need a typScript?|Why would I need a typScript?|
|Base Type|Basic Types|
|interface with type|interface with type|
|Broad and Type Operations|Pan/Types|
|Zoom in.|Types narrow down.|
|Project Configuration Points|Project Configuration Points|
|It's the end of this class.| Summary |
|Quick check|Types, check.|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

