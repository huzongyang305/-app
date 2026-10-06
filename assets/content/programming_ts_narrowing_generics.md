# TypeScript 类型收窄与泛型

![五种类型收窄手段](images/diagram_ts_narrowing.webp)

![TypeScript 类型收窄与泛型](images/remaining_ts_narrowing_generics.webp)

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：35 分钟

## 学习目标

- 能用自己的话解释TypeScript 类型收窄与泛型解决了什么问题，而不是只背术语。
- 能说清 「TypeScript」、「类型收窄」、「泛型」、「可辨识联合」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「TypeScript」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：五种收窄手段、可辨识联合、泛型约束与 infer。

## 前置知识

- 先完成上一课《TypeScript 类型系统》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：入门。只需要基本计算机操作，不要求编程经验。
- 开始前先复习：TypeScript、类型收窄、泛型。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。

## 类型收窄的五种手段

| 手段 | 用法 |
| --- | --- |
| typeof | 区分 string/number/boolean 等原始类型 |
| instanceof | 区分类实例 |
| in | 判断属性是否存在 |
| 可辨识联合 | 用共同字段（如 `type`）区分成员，配合 switch 穷尽检查 |
| 类型守卫 | 自定义 `x is T` 函数或断言函数 `asserts x is T` |

可辨识联合 + switch 是建模业务状态最实用的模式：订单状态、请求结果、表单校验结果都可以这样写，新增一种状态时编译器会提示所有需要处理的位置。

## 泛型与约束

泛型让函数与组件在保持类型安全的前提下复用：`function first<T>(list: T[]): T | undefined`。约束用 `extends`：`<T extends { id: number }>` 要求必须有 id；默认类型参数 `<T = string>` 提供缺省。

## 条件类型与 infer

`T extends U ? X : Y` 在类型层面做分支；`infer` 用于提取类型片段，例如提取函数返回类型、数组元素类型、Promise 的结果类型。这是工具类型的实现基础。

## 常见错误与排查

1. 滥用 `any` 让检查失效——外部数据先用 `unknown`，校验后再收窄。
2. 过度断言 `as` 会掩盖错误，优先用类型守卫。
3. 非空断言 `!` 只是让编译器闭嘴，运行时该崩还是崩。
4. 泛型嵌套过深会降低可读性，必要时拆成命名类型。
| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `JSON.parse(text) as User` | 编译通过，运行时字段缺失报错 | 断言不校验数据，外部输入要用 zod 等做运行时校验 |
| 到处写 `any` | 类型检查失效，错误延后到线上 | 用 `unknown` + 类型守卫逐层收窄 |
| `obj!.field` 滥用非空断言 | 运行时 `TypeError` | 用 `if (!obj) return;` 先收窄 |
| `as string` 强转 | 掩盖真实的类型不匹配 | 优先改类型定义，只在校验之后断言 |
| 函数返回 `T \| undefined` 却不处理 | 调用方忘记判空 | 用可辨识联合表达结果，或抛异常 |
| 泛型约束太宽 | 函数体里访问属性报错 | 加 `T extends { ... }` 约束 |
| 用 `Object.keys(obj)` 得到 `string[]` | 遍历时索引报错 | 明确断言为 `(keyof T)[]`，或改用 `Record` 设计 |
| 数组 `find` 结果直接用 | 可能是 `undefined` | 先判空，或用可辨识联合包装 |
| 类型断言在循环里反复写 | 代码噪声大 | 把校验抽成类型守卫函数复用 |

## 本课小结

TypeScript 的类型能力集中在两处：**收窄（把宽类型变窄）** 与 **泛型（让类型随输入变化）**；掌握这两点，就能用类型把业务约束表达清楚。

## 类型收窄速查

| 收窄手段 | 写法 | 适用场景 |
| --- | --- | --- |
| `typeof` | `if (typeof v === "string")` | 原始类型 |
| 真值判断 | `if (v) {}` | 排除 `null` / `undefined` / `""` / `0` |
| 空值判断 | `if (v != null)` | 同时排除 `null` 与 `undefined` |
| `in` 运算符 | `if ("id" in v)` | 联合类型中按字段区分 |
| `instanceof` | `if (e instanceof Error)` | 类实例 |
| 字面量判别 | `if (r.status === "ok")` | 可辨识联合（推荐） |
| 自定义类型守卫 | `function isUser(v: unknown): v is User` | 校验外部数据 |
| 断言函数 | `function assert(cond: unknown): asserts cond` | 抛错即收窄 |
| `Array.isArray` | `if (Array.isArray(v))` | 数组判断 |
| 穷尽检查 | `default: const _x: never = v;` | 编译期确保分支齐全 |

可辨识联合的标准写法：

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

## 泛型约束速查

| 写法 | 含义 |
| --- | --- |
| `<T>` | 任意类型 |
| `<T extends object>` | 必须是对象类型 |
| `<T extends { id: string }>` | 至少具备该形状 |
| `<T extends keyof U>` | 只能是 U 的键 |
| `<T = string>` | 提供默认类型参数 |
| `<T extends string \| number>` | 联合约束 |
| `function f<T>(x: T): T` | 返回值与入参类型联动 |
| `ReturnType<typeof f>` | 取函数返回值类型 |
| `Parameters<typeof f>[0]` | 取第一个参数类型 |
| `as const` | 让字面量推断变窄 |

```ts
// 约束 + keyof：安全地按字段取值
function pluck<T, K extends keyof T>(items: T[], key: K): T[K][] {
  return items.map((item) => item[key]);
}

const users = [{ id: 1, name: "小明" }];
const names = pluck(users, "name");   // string[]
// pluck(users, "age");               // 编译报错，及时发现问题
```

## 复习与自测

- [ ] 能用可辨识联合替代「可选字段大杂烩」的接口设计。
- [ ] 外部数据先 `unknown`，再通过类型守卫收窄。
- [ ] 会用 `keyof` 与泛型约束写出类型安全的取值函数。
- [ ] 知道 `as` 不做运行时校验。
- [ ] 在 `switch` 里用 `never` 做穷尽检查。

## 零基础详解：类型收窄与泛型

### 一句话说清它是什么

收窄是把「很宽的类型」逐步判断成「很具体的类型」；
泛型是让函数对多种类型都成立，同时不丢类型信息。两者合起来，就是 TypeScript 类型系统的骨架。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 联合类型 `A \| B` | 一个没拆的快递箱 | 不知道里面是什么 |
| 收窄 | 开箱验货 | 判断后才知道是哪种 |
| 泛型 | 可调模具 | 一套模具适配多种尺寸 |
| 约束 `extends` | 模具的尺寸范围 | 限定能适配哪些类型 |
| 类型守卫 | 贴标签 | 告诉编译器「现在确定是它」 |

### 收窄的五种手段

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

| 手段 | 适用场景 |
| --- | --- |
| `typeof` | 原始类型判断 |
| `instanceof` | 类实例判断 |
| `in` | 判断某个属性是否存在 |
| 字面量字段（可辨识联合） | 状态机、事件对象 |
| 自定义类型守卫 | 外部数据校验 |

### 穷尽检查：新增分支时自动报错

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

### 泛型常用的四个写法

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

### `keyof` 与索引访问

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

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `as` 强行断言 | 运行时照样出错 | 用类型守卫真校验 |
| 泛型没用上参数 | 推断成 unknown | 让 T 出现在参数位置 |
| 约束写太死 | 调用方传不进去 | 用 `keyof` 等结构性约束 |
| 忘了处理 `null` | `strictNullChecks` 报错 | 先判空或用 `?.` |
| 类型守卫只判一层 | 嵌套字段仍报错 | 逐层校验 |
| 用 `any` 绕过报错 | 类型安全全丢 | 用 `unknown` 加守卫 |
| 默认分支不写 `assertNever` | 新增状态漏处理 | 用穷尽检查兜底 |
| 泛型嵌套太深 | 没人看得懂 | 拆成命名类型 |

### 手把手练习：安全地取嵌套字段

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

### 学完自测

- [ ] 能说出五种收窄手段各自适用什么场景。
- [ ] 能写出一个自定义类型守卫函数。
- [ ] 知道 `assertNever` 为什么要接收 `never`。
- [ ] 能解释 `K extends keyof T` 的含义。
- [ ] 知道为什么不该用 `as` 代替真正的校验。

## 动手练习

> 本课练习重点：围绕「TypeScript、类型收窄、泛型」完成复述、实验和交付，每个结果都要能被别人检查。

先让类型检查通过，再制造一次类型错误，最后补运行时校验与测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. TypeScript 类型收窄与泛型解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「类型收窄」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

写一个最小类型示例，先让 `tsc --noEmit` 通过，再故意制造一次类型错误。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「TypeScript」和「类型收窄」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 可运行练习

### 任务 1：先跑通，再解释

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

### 任务 2：只改一个条件

把「TypeScript 类型收窄与泛型」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只把TypeScript的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「TypeScript 类型收窄与泛型」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响TypeScript。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：本课的 TypeScript 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 TypeScript 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 TypeScript 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“TypeScript 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 TypeScript 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 类型收窄 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 类型收窄 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 类型收窄 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“类型收窄 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 类型收窄 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：本课的验证只在开发机通过

**症状**：在本课的练习或生产场景里出现“本课的验证只在开发机通过”。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，TypeScript 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 版本与时效

- TypeScript 5.x 主线持续收紧类型推导、装饰器与模块解析行为
- 升级前先跑 tsc --noEmit，再处理构建工具与 ESLint 规则差异

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改一个版本变量，记录编译、测试、性能与产物体积的变化。
- 重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。
- 升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「可辨识联合靠什么区分成员？」的判断依据。
- [ ] 不看解析，能说出「外部接口数据最安全的类型标注是？」的判断依据。
- [ ] 不看解析，能说出「infer 关键字用于？」的判断依据。
- [ ] 不看解析，能说出「自定义类型守卫的返回类型应该写成？」的判断依据。
- [ ] 不看解析，能说出「泛型约束 T extends { id: string } 的作用是？」的判断依据。
- [ ] 不看解析，能说出的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把「TypeScript 类型收窄与泛型」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `TypeScript` | 围绕“环境版本、配置和输入规模与目标环境不同，TypeScript 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。 |
| `类型收窄` | 围绕“类型收窄 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。 |
| `泛型` | TypeScript 的类型能力集中在两处：收窄（把宽类型变窄） 与 泛型（让类型随输入变化）；掌握这两点，就能用类型把业务约束表达清楚。 |
| `可辨识联合` | 可辨识联合 + switch 是建模业务状态最实用的模式：订单状态、请求结果、表单校验结果都可以这样写，新增一种状态时编译器会提示所有需要处理的位置。 |
| `infer` | Narrowing & Generics focuses on Narrowing, discriminated unions, generics and infer.。 |

## 考点精讲

### 考点 1：多选辨析·TypeScript

- **题目**：围绕“TypeScript 类型收窄与泛型”中的 TypeScript、类型收窄、泛型，下列哪两项是本课强调的实践判断？
- **判断依据**：在「TypeScript 类型收窄与泛型」里，学习 TypeScript 时要同时说明输入、输出和失败路径，不能只看正常流程。在TypeScript 类型收窄与泛型里，判断 类型收窄 时要固定版本与边界输入，所以“验证 类型收窄 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：代码补全·TypeScript

- **题目**：阅读「TypeScript 类型收窄与泛型」正文里的这段 TypeScript 代码，下面哪一项判断是正确的？
- **判断依据**：在「TypeScript 类型收窄与泛型」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「TypeScript 类型收窄与泛型」的正文示例，围绕TypeScript、类型收窄、泛型展开；把输入或边界换成空值、极值或失败情况后，结论要以「TypeScript 类型收窄与泛型」的实际运行结果为准。

### 考点 3：概念判断·TypeScript

- **题目**：infer 关键字用于？
- **判断依据**：在「TypeScript 类型收窄与泛型」里，在条件类型中提取类型片段。它是 ReturnType、Awaited 等工具类型的实现基础。在「TypeScript 类型收窄与泛型」里判断这道题，要把TypeScript、类型收窄、泛型的条件、过程与失败路径逐项对齐，换成“infer 关键字用于”这个场景，只有满足前提的结论才成立。

### 考点 4：概念判断·TypeScript

- **题目**：自定义类型守卫的返回类型应该写成？
- **判断依据**：在「TypeScript 类型收窄与泛型」里，返回 value is Foo 后，调用处在该分支内会被自动收窄为 Foo 类型。在「TypeScript 类型收窄与泛型」里，其他选项：返回 Foo、undefined、typeof Foo 或 boolean 都不会让调用处收窄。在「TypeScript 类型收窄与泛型」里，这道题要求区分概念与边界，「value is Foo」只有在题干给出的前提下才成立，而「typeof Foo」、「boolean」缺少同一组条件。

### 考点 5：概念判断·TypeScript

- **题目**：泛型约束 T extends { id: string } 的作用是？
- **判断依据**：在「TypeScript 类型收窄与泛型」里，要求类型参数至少具备该形状。没有约束时不能访问 T 的成员，约束是泛型里获得类型安全的关键。回到「TypeScript 类型收窄与泛型」的正文示例，用“泛型约束 T extends { i”走一遍TypeScript、类型收窄、泛型的完整流程，能复现的结论才可以保留。

### 考点 6：填空·TypeScript

- **题目**：补全代码：「TypeScript 类型收窄与泛型」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `function ____(value: never): never {`
- **判断依据**：在「TypeScript 类型收窄与泛型」里，assertNever。在「TypeScript 类型收窄与泛型」里判断这道题，要把TypeScript、类型收窄、泛型的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。回到「TypeScript 类型收窄与泛型」的正文示例，用“补全代码”走一遍TypeScript、类型收窄、泛型的完整流程，能复现的结论才可以保留。

## English Overview

**Title:** Narrowing & Generics

**Summary:** Narrowing, discriminated unions, generics and infer.

**Category:** TypeScript
**Level:** 入门
**Key terms:** TypeScript, 类型收窄, 泛型, 可辨识联合, infer

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：TypeScript 5.x / Node.js 22+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：TypeScript、类型收窄、泛型、可辨识联合、infer
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## Full English Study Guide

### Overview

**Narrowing & Generics** focuses on Narrowing, discriminated unions, generics and infer.

### Learning Outcomes

- Explain what **Narrowing & Generics** solves and when it should be used.

### Glossary

- Topic: **Narrowing & Generics**
- Related terms: TypeScript, 类型收窄, 泛型, 可辨识联合

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 类型收窄的五种手段 | Types收窄的五种手段 |
| 泛型与约束 | 泛型与约束 |
| 条件类型与 infer | 条件Types与 infer |
| 常见陷阱 | 常见陷阱 |
| 本课小结 | Summary |
| 类型收窄速查 | Types收窄速查 |
| 泛型约束速查 | 泛型约束速查 |
| 常见错误对照表 | Common mistakes对照表 |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Everyday Types](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html) | 常用类型与收窄 |
| [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) | 类型系统与语言指南 |
| [声明文件](https://www.typescriptlang.org/docs/handbook/declaration-files/introduction.html) | 类型声明与发布 |

> 「TypeScript 类型收窄与泛型」的链接用于离线阅读后的延伸核对；App 不会自动联网。
