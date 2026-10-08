# TypeScript 类型体操进阶

![类型体操的四类核心工具](images/diagram_ts_type_challenges.webp)

![TypeScript 类型体操进阶](images/remaining_ts_type_challenges.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：50 分钟

## 本节知识框架

**课程定位**：所属分类为「TypeScript」，课程主题为「TypeScript 类型体操进阶」，学习阶段为「高级」，建议用时 50 分钟。

**本课要解决的主问题**：条件类型、infer、映射类型与模板字面量类型的组合用法。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「TypeScript 类型体操进阶」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「TypeScript 类型体操进阶」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「条件类型」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《TypeScript 实战：全栈类型安全》

**学习位置**：本课位于《TypeScript 实战：全栈类型安全》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《类型检查与构建性能优化》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释TypeScript 类型体操进阶解决了什么问题，而不是只背术语。
- 能说清 「条件类型」、「infer」、「映射类型」、「模板字面量类型」 之间的关系，并分别举出一个例子。
- 能把 条件类型 放回「TypeScript 类型体操进阶」的知识体系，说明它和 infer 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：条件类型、infer、映射类型与模板字面量类型的组合用法。

**教材衔接：前置知识**

- 先完成上一课《TypeScript 实战：全栈类型安全》；如果已经掌握，可以直接用本课练习自测。
- 开始前先复习：条件类型、infer、映射类型。
- 卡在 条件类型 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

**教材衔接：本课小结**

- 核心问题：TypeScript 类型体操进阶不是孤立术语，而是在「TypeScript」中解决一类具体问题。
- 关键关系：先分清「条件类型」与「infer」的职责，再理解「映射类型」的适用边界。
- 判断标准：能说清 DeepReadonly 在正常与异常输入下的差别。
- 下一步：先复述 infer 的边界，再开始本课测验。

## 核心概念定义

> 阅读约定：本课先给「TypeScript 类型体操进阶」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| 条件类型 | TypeScript 根据类型关系在编译期选择结果类型的类型运算。 | 仅在「TypeScript 类型体操进阶」明确给出的输入、版本与资源条件下成立。 |
| 映射类型 | TypeScript 根据已有类型批量生成属性变换后的新类型。 | 仅在「TypeScript 类型体操进阶」明确给出的输入、版本与资源条件下成立。 |
| infer | 在条件类型里声明待推断的类型变量，用来实现 ReturnType 一类工具类型。 | 仅在「TypeScript 类型体操进阶」明确给出的输入、版本与资源条件下成立。 |
| 模板字面量类型 | 用反引号把字符串类型拼起来，可以对路由参数或事件名做类型约束。 | 仅在「TypeScript 类型体操进阶」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「TypeScript 类型体操进阶」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

**教材衔接：四种类型构造速查**

| 构造 | 作用 | 示例 |
| --- | --- | --- |
| 条件类型 | 按条件选择类型 | `T extends string ? A : B` |
| `infer` | 在条件类型中提取类型 | `T extends Array<infer U> ? U : never` |
| 映射类型 | 批量改造属性 | `{ [K in keyof T]: T[K] \| null }` |
| 模板字面量类型 | 在类型层拼字符串 | `` `get${Capitalize<K>}` `` |

这四种组合起来就能做「类型级编程」，但工程上要克制：类型越复杂，编译越慢、报错越难懂。

```ts
// 1. 条件类型 + infer：取出函数返回类型与 Promise 内部类型
type Unwrap<T> = T extends Promise<infer U> ? Unwrap<U> : T;
type Value = Unwrap<Promise<Promise<number>>>;   // number
// 2. 映射类型 + 键重映射：把字段改成 getX 形式
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};
interface User {
  id: string;
  name: string;
}
type UserGetters = Getters<User>;
// { getId: () => string; getName: () => string }
// 3. 递归条件类型：深层只读
type DeepReadonly<T> = {
  readonly [K in keyof T]: T[K] extends object ? DeepReadonly<T[K]> : T[K];
};
// 4. 联合类型分配：自动对每个成员生效
type ToArray<T> = T extends unknown ? T[] : never;
type Result = ToArray<"a" | "b">;                // "a"[] | "b"[]
// 5. 模板字面量类型 + 映射：为事件总线生成类型安全的方法
type EventMap = { userCreated: { id: string }; userDeleted: { id: string } };
type Listeners = {
  [K in keyof EventMap as `on${Capitalize<string & K>}`]: (payload: EventMap[K]) => void;
};
```

**教材衔接：类型优先级速查**

| 目标 | 选择 |
| --- | --- |
| 只需要复用已有类型的部分字段 | `Pick` / `Omit` |
| 需要按条件分支 | 条件类型 |
| 需要从复杂类型中提取 | `infer` |
| 需要批量转换属性 | 映射类型 |
| 需要构造字符串键 | 模板字面量类型 |
| 需要运行时校验 | zod 等库（类型只在编译期存在） |

**教材衔接：零基础详解：类型体操入门**

### 一句话说清它是什么

类型体操就是用条件类型、映射类型、`infer` 这些工具，**从已有类型推导出新类型**。
它的价值不是炫技，而是让类型跟着实现自动变化，避免重复声明。

### 用生活比喻理解

| 工具 | 比喻 | 说明 |
| --- | --- | --- |
| 条件类型 | if 判断 | `T extends U ? A : B` |
| `infer` | 拆包裹 | 从类型里取出未知部分 |
| 映射类型 | 批量加工 | 对每个字段统一处理 |
| 模板字面量 | 字符串拼接 | `` `on${K}` `` |
| 递归类型 | 逐层剥开 | 处理嵌套结构 |

### 五个基础积木

```typescript
// 1. 条件类型：像 if
type IsString<T> = T extends string ? true : false;
type A = IsString<"hi">;        // true
type B = IsString<42>;          // false

// 2. infer：从类型里取片段
type ElementOf<T> = T extends (infer U)[] ? U : never;
type E = ElementOf<string[]>;   // string

// 3. 映射类型：批量改造字段
type Nullable<T> = { [K in keyof T]: T[K] | null };
type User = { id: number; name: string };
type MaybeUser = Nullable<User>;   // { id: number | null; name: string | null }

// 4. 键重映射
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};
type UserGetters = Getters<User>;  // { getId: () => number; getName: () => string }

// 5. 递归：逐层可选
type DeepPartial<T> = {
  [K in keyof T]?: T[K] extends object ? DeepPartial<T[K]> : T[K];
};
```

### 三个实用例子

```typescript
// 例 1：取函数返回值的 Promise 解包结果
type Unwrap<T> = T extends Promise<infer U> ? Unwrap<U> : T;
type R = Unwrap<Promise<Promise<number>>>;    // number

// 例 2：把联合类型转成「键值都可选」的映射
type Flags<T extends string> = Partial<Record<T, boolean>>;
type FeatureFlags = Flags<"dark" | "beta" | "chat">;

// 例 3：按类型过滤对象字段
type PickByType<T, V> = {
  [K in keyof T as T[K] extends V ? K : never]: T[K];
};
type OnlyStrings = PickByType<{ id: number; name: string; tag: string }, string>;
// { name: string; tag: string }
```

### 什么时候值得用

| 情况 | 建议 |
| --- | --- |
| 从 schema 推导类型 | ✅ 用工具类型 |
| 包装库的类型（如 Result、Option） | ✅ 有条件类型 |
| 只想少写几个字段 | ❌ 直接写更清楚 |
| 团队没人看得懂 | ❌ 退回到简单写法 |

**判断标准：如果写完后没人能在 10 秒内说出它的含义，就该拆成命名类型或直接写出来。**

### 常用内置工具类型对照

| 工具 | 作用 |
| --- | --- |
| `Partial<T>` | 全部可选 |
| `Required<T>` | 全部必填 |
| `Readonly<T>` | 全部只读 |
| `Pick<T, K>` | 保留指定字段 |
| `Omit<T, K>` | 排除指定字段 |
| `Record<K, V>` | 构造映射 |
| `Exclude<T, U>` | 从联合中排除 |
| `Extract<T, U>` | 从联合中提取 |
| `NonNullable<T>` | 去掉 null 与 undefined |
| `ReturnType<F>` | 取返回类型 |
| `Awaited<T>` | 解开 Promise |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 类型写得太绕 | 报错没人看得懂 | 拆成命名类型并加注释 |
| 忘了 `as const` | 推断成宽泛类型 | 常量加 `as const` |
| 递归层数太深 | 编译器报「实例化过深」 | 限制层数或改实现 |
| 条件类型没写 `never` | 得到意外结果 | 明确不匹配时的分支 |
| 在运行时用类型 | 报错或无效 | 类型只在编译期存在 |
| 用体操处理业务逻辑 | 难维护 | 用普通代码表达 |
| 忽略分配式条件类型 | 联合被逐项处理 | 需要整体判断时用 `[T] extends [U]` |
| 版本差异 | 老版本不支持某些语法 | 先确认 TS 版本 |

### 手把手练习：从 API 响应推导工具类型

```typescript
type ApiResponse<T> =
  | { status: "ok"; data: T }
  | { status: "error"; message: string };

// 1. 取出成功分支的数据类型
type DataOf<R> = R extends { status: "ok"; data: infer D } ? D : never;

// 2. 把字段全部变成异步返回
type Asyncify<T> = { [K in keyof T]: () => Promise<T[K]> };

// 3. 组合使用
type User = { id: number; name: string };
type UserApi = Asyncify<Pick<User, "id" | "name">>;
// { id: () => Promise<number>; name: () => Promise<string> }

type Resp = ApiResponse<User>;
type Payload = DataOf<Resp>;      // User

const response: Resp = { status: "ok", data: { id: 1, name: "小明" } };
if (response.status === "ok") {
  const payload: Payload = response.data;    // 收窄后自动成立
  console.log(payload.name);
}
```

### 学完自测

- [ ] 能写出一个条件类型并解释匹配逻辑。
- [ ] 能说出 `infer` 的用途。
- [ ] 能写出一个把字段变为可选的映射类型。
- [ ] 知道什么时候不该用类型体操。
- [ ] 能说出 `Exclude` 与 `Extract` 的区别。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「条件类型」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「映射类型」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「infer」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「TypeScript 类型体操进阶」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | 条件类型 | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | 映射类型 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | infer | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「TypeScript 类型体操进阶」自己的示例验证。「TypeScript 类型体操进阶」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：工程约束速查**

| 约束 | 原因 |
| --- | --- |
| 给复杂类型写注释与示例 | 后来者要能看懂 |
| 用测试验证类型（类型断言与编译） | 类型逻辑也会出错 |
| 控制深度与递归层数 | 过深会让编译器变慢甚至报错 |
| 导出类型时给语义化别名 | 报错信息更可读 |
| 不用类型体操做业务建模 | 可读性优先于炫技 |

**教材衔接：版本与时效**

- 版本提示：条件类型 的行为在最近几个大版本里有过调整，升级「TypeScript 类型体操进阶」前先用 DeepReadonly 复现当前输出，再对照官方发布说明逐条核对。
- 升级前确认 条件类型 的兼容范围，把不可回退的改动单独拆成一次提交。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改 条件类型 的版本变量，记录编译、测试与产物体积的变化。
- 回归范围锁定 DeepReadonly 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 条件类型 的版本变化。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 条件类型、infer | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「TypeScript 类型体操进阶」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「TypeScript 类型体操进阶」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:typescript`，用于动手验证《TypeScript 类型体操进阶》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《TypeScript 类型体操进阶》原文中的最小示例。先预测《TypeScript 类型体操进阶》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```ts
// 1. 条件类型 + infer：取出函数返回类型与 Promise 内部类型
type Unwrap<T> = T extends Promise<infer U> ? Unwrap<U> : T;
type Value = Unwrap<Promise<Promise<number>>>;   // number
// 2. 映射类型 + 键重映射：把字段改成 getX 形式
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};
interface User {
  id: string;
  name: string;
}
type UserGetters = Getters<User>;
// { getId: () => string; getName: () => string }
// 3. 递归条件类型：深层只读
type DeepReadonly<T> = {
  readonly [K in keyof T]: T[K] extends object ? DeepReadonly<T[K]> : T[K];
};
// 4. 联合类型分配：自动对每个成员生效
type ToArray<T> = T extends unknown ? T[] : never;
type Result = ToArray<"a" | "b">;                // "a"[] | "b"[]
// 5. 模板字面量类型 + 映射：为事件总线生成类型安全的方法
type EventMap = { userCreated: { id: string }; userDeleted: { id: string } };
type Listeners = {
  [K in keyof EventMap as `on${Capitalize<string & K>}`]: (payload: EventMap[K]) => void;
};
```

**教材衔接：原文最小示例**

```ts
// 1. 条件类型 + infer：取出函数返回类型与 Promise 内部类型
type Unwrap<T> = T extends Promise<infer U> ? Unwrap<U> : T;
type Value = Unwrap<Promise<Promise<number>>>;   // number
// 2. 映射类型 + 键重映射：把字段改成 getX 形式
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};
interface User {
  id: string;
  name: string;
}
type UserGetters = Getters<User>;
// { getId: () => string; getName: () => string }
// 3. 递归条件类型：深层只读
type DeepReadonly<T> = {
  readonly [K in keyof T]: T[K] extends object ? DeepReadonly<T[K]> : T[K];
};
// 4. 联合类型分配：自动对每个成员生效
type ToArray<T> = T extends unknown ? T[] : never;
type Result = ToArray<"a" | "b">;                // "a"[] | "b"[]
// 5. 模板字面量类型 + 映射：为事件总线生成类型安全的方法
type EventMap = { userCreated: { id: string }; userDeleted: { id: string } };
type Listeners = {
  [K in keyof EventMap as `on${Capitalize<string & K>}`]: (payload: EventMap[K]) => void;
};
```

## 时间/空间复杂度或性能分析

**复杂度证据**：「TypeScript 类型体操进阶」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「TypeScript 类型体操进阶」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「TypeScript 类型体操进阶」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《TypeScript 类型体操进阶》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「TypeScript 类型体操进阶」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 嵌套过深的条件类型 | 编译变慢、报错难读 | 拆成多个命名类型 |
| 忘记分布式联合类型行为 | 结果与预期不符 | 用 `[T] extends [U]` 阻断分配 |
| 在类型里做运行时判断 | 无法实现 | 类型编译后消失，运行时用校验库 |
| 递归类型无终止条件 | 编译报错或超深 | 设计明确的递归出口 |
| 用 `any` 兜底复杂类型 | 类型安全失效 | 用 `unknown` 加收窄 |
| 没有类型测试 | 类型改动悄悄破坏调用方 | 用类型断言与 CI 编译检查 |

**教材衔接：故障现场**

### 现场 1：嵌套过深的条件类型

**症状**：在《TypeScript 类型体操进阶》的复现场景中，编译变慢、报错难读。

**根因**：触发点是把“嵌套过深的条件类型”当成安全做法。它没有满足《TypeScript 类型体操进阶》要求的前提，因此先表现为“编译变慢、报错难读”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《TypeScript 类型体操进阶》的问题，拆成多个命名类型。

**验证**：在《TypeScript 类型体操进阶》中按“拆成多个命名类型”调整后，从“嵌套过深的条件类型”的触发条件重放同一条路径，确认“编译变慢、报错难读”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：忘记分布式联合类型行为

**症状**：在《TypeScript 类型体操进阶》的复现场景中，结果与预期不符。

**根因**：触发点是把“忘记分布式联合类型行为”当成安全做法。它没有满足《TypeScript 类型体操进阶》要求的前提，因此先表现为“结果与预期不符”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《TypeScript 类型体操进阶》的问题，用 [T] extends [U] 阻断分配。

**验证**：在《TypeScript 类型体操进阶》中按“用 [T] extends [U] 阻断分配”调整后，从“忘记分布式联合类型行为”的触发条件重放同一条路径，确认“结果与预期不符”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 3：递归类型无终止条件

**症状**：在《TypeScript 类型体操进阶》的复现场景中，编译报错或超深。

**根因**：当出现“递归类型无终止条件”时，执行路径已经绕过了《TypeScript 类型体操进阶》的关键约束，最终以“编译报错或超深”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《TypeScript 类型体操进阶》的问题，设计明确的递归出口。

**验证**：保留《TypeScript 类型体操进阶》里触发“编译报错或超深”的输入、版本和日志，按“设计明确的递归出口”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《TypeScript 实战：全栈类型安全》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《TypeScript Node 后端开发》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《TypeScript 实战：全栈类型安全》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《类型检查与构建性能优化》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「TypeScript 类型体操进阶」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《TypeScript 类型体操进阶》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

围绕“TypeScript 类型体操进阶”中的 条件类型、infer、映射类型，下列哪两项是本课强调的实践判断？

A. 把 infer 的单次运行结果当成所有版本和规模都成立
B. 学习 条件类型 时要同时说明输入、输出和失败路径，不能只看正常流程
C. 只要 条件类型 的常规示例通过，就可以跳过边界与异常路径
D. 验证 infer 时要固定版本并覆盖边界输入，结论才可复现

**参考答案**：学习 条件类型 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 infer 时要固定版本并覆盖边界输入，结论才可复现

**解析**：本课把TypeScript 类型体操进阶拆成概念、示例与故障现场三部分，因此判断 条件类型 时必须同时交代输入、输出和失败路径，这使“学习 条件类型 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在TypeScript 类型体操进阶里，判断 infer 时要固定版本与边界输入，所以“验证 infer 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 2

阅读「TypeScript 类型体操进阶」正文里的这段 TypeScript 代码，下面哪一项判断是正确的？

```typescript
// 1. 条件类型：像 if
type IsString<T> = T extends string ? true : false;
type A = IsString<"hi">;        // true
type B = IsString<42>;          // false

// 2. infer：从类型里取片段
type ElementOf<T> = T extends (infer U)[] ? U : never;
type E = ElementOf<string[]>;   // string

// 3. 映射类型：批量改造字段
type Nullable<T> = { [K in keyof T]: T[K] | null };
type User = { id: number; name: string };
type MaybeUser = Nullable<User>;   // { id: number | null; name: string | null }

// 4. 键重映射
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};
type UserGetters = Getters<User>;  // { getId: () => number; getName: () => string }

// 5. 递归：逐层可选
type DeepPartial<T> = {
  [K in keyof T]?: T[K] extends object ? DeepPartial<T[K]> : T[K];
};
```

A. 这段代码会读取外部输入，结果依赖传入的数据。
B. 这段代码会产生可观察的输出，运行后能看到结果。
C. 这段代码只做静态声明，没有循环、分支或可观察输出。
D. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**参考答案**：这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**解析**：在「TypeScript 类型体操进阶」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「TypeScript 类型体操进阶」的正文示例，围绕条件类型、infer、映射类型展开；把输入或边界换成空值、极值或失败情况后，结论要以「TypeScript 类型体操进阶」的实际运行结果为准。

### 自测 3

条件类型对联合类型会自动「分配」，想阻断这种分配应该？

A. 用 [T] extends [U] 这种方括号写法
B. 把联合改成交叉类型，但这会引入新的复杂度，需要额外的验证与维护
C. 加 readonly
D. 用 any 包一层

**参考答案**：用 [T] extends [U] 这种方括号写法

**解析**：在「TypeScript 类型体操进阶」里，用 [T] extends [U] 这种方括号写法。方括号让类型不再是被检查的裸类型参数，从而阻止分布式行为，这是控制联合分支的常用技巧。这道题的关键在「TypeScript 类型体操进阶」的条件类型、infer、映射类型：先确认题干“条件类型对联合类型会自动分配”问的是哪一步，再排除偷换前提的选项。

**教材衔接：复习与自测**

- [ ] 会用条件类型与 `infer` 提取类型。
- [ ] 会用映射类型与键重映射批量改造属性。
- [ ] 会用模板字面量类型约束字符串键。
- [ ] 知道用 `[T] extends [U]` 阻断联合分配。
- [ ] 类型逻辑有注释与类型测试，且控制复杂度。

**教材衔接：动手练习**

> 本课练习重点：围绕「条件类型、infer、映射类型」完成复述、实验和交付，每个结果都要能被别人检查。

把 infer 的边界写成类型或断言，让错误在编译期暴露。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. TypeScript 类型体操进阶解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「infer」是什么关系？

验收标准：说明 条件类型 与 infer 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：五步记录要写进笔记——原例是 DeepReadonly，改动落在条件类型上，结论必须能被他人在同一环境里复现。

### 练习 3：交付一个小结果（30 分钟）

写一个只包含 条件类型 的最小程序，先验证正常路径，再制造一次失败。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「条件类型」和「infer」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```typescript
type ApiResponse<T> =
  | { status: "ok"; data: T }
  | { status: "error"; message: string };

// 1. 取出成功分支的数据类型
type DataOf<R> = R extends { status: "ok"; data: infer D } ? D : never;

// 2. 把字段全部变成异步返回
type Asyncify<T> = { [K in keyof T]: () => Promise<T[K]> };

// 3. 组合使用
type User = { id: number; name: string };
type UserApi = Asyncify<Pick<User, "id" | "name">>;
// { id: () => Promise<number>; name: () => Promise<string> }

type Resp = ApiResponse<User>;
type Payload = DataOf<Resp>;      // User

const response: Resp = { status: "ok", data: { id: 1, name: "小明" } };
if (response.status === "ok") {
  const payload: Payload = response.data;    // 收窄后自动成立
  console.log(payload.name);
}
```

### 任务 2：只改一个条件

把「TypeScript 类型体操进阶」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只把 条件类型 的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「TypeScript 类型体操进阶」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响条件类型。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的 条件类型 数据，保持输出格式与任务 1 一致。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「想在条件类型中「取出」数组元素类型，应该用？」的判断依据。
- [ ] 不看解析，能说出「条件类型对联合类型会自动「分配」，想阻断这种分配应该？」的判断依据。
- [ ] 不看解析，能说出「关于类型体操的工程建议，正确的是？」的判断依据。
- [ ] 不看解析，能说出「模板字面量类型最典型的用途是？」的判断依据。
- [ ] 跑通「TypeScript 类型体操进阶」的最小示例，并记录一次失败输入的处理方式。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `条件类型` | TypeScript 根据类型关系在编译期选择结果类型的类型运算。 |
| `映射类型` | TypeScript 根据已有类型批量生成属性变换后的新类型。 |
| `infer` | 在条件类型里声明待推断的类型变量，用来实现 ReturnType 一类工具类型。 |
| `模板字面量类型` | 用反引号把字符串类型拼起来，可以对路由参数或事件名做类型约束。 |

## 考点精讲

### 考点 1：多选辨析·条件类型

- **题目**：围绕“TypeScript 类型体操进阶”中的 条件类型、infer、映射类型，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把TypeScript 类型体操进阶拆成概念、示例与故障现场三部分，因此判断 条件类型 时必须同时交代输入、输出和失败路径，这使“学习 条件类型 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在TypeScript 类型体操进阶里，判断 infer 时要固定版本与边界输入，所以“验证 infer 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：代码补全·条件类型

- **题目**：阅读「TypeScript 类型体操进阶」正文里的这段 TypeScript 代码，下面哪一项判断是正确的？
- **判断依据**：在「TypeScript 类型体操进阶」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「TypeScript 类型体操进阶」的正文示例，围绕条件类型、infer、映射类型展开；把输入或边界换成空值、极值或失败情况后，结论要以「TypeScript 类型体操进阶」的实际运行结果为准。

### 考点 3：概念判断·分配

- **题目**：条件类型对联合类型会自动「分配」，想阻断这种分配应该？
- **判断依据**：在「TypeScript 类型体操进阶」里，用 [T] extends [U] 这种方括号写法。方括号让类型不再是被检查的裸类型参数，从而阻止分布式行为，这是控制联合分支的常用技巧。这道题的关键在「TypeScript 类型体操进阶」的条件类型、infer、映射类型：先确认题干“条件类型对联合类型会自动分配”问的是哪一步，再排除偷换前提的选项。

### 考点 4：概念判断·条件类型

- **题目**：关于类型体操的工程建议，正确的是？
- **判断依据**：在「TypeScript 类型体操进阶」里，结论应落在「拆分命名类型，写注释与类型测试」。复杂类型会拖慢编译并让报错难懂，需要拆分、注释与类型级测试。在「TypeScript 类型体操进阶」里，这道题要求区分概念与边界，「拆分命名类型，写注释与类型测试」只有在题干给出的前提下才成立，而「越复杂越能体现水平」、「所有类型都用 any 兜底」缺少同一组条件。

### 考点 5：概念判断·条件类型

- **题目**：模板字面量类型最典型的用途是？
- **判断依据**：在「TypeScript 类型体操进阶」里，约束字符串键的命名格式（如 getX、onX）。模板字面量类型能在类型层拼装与约束字符串形态，配合映射类型可自动生成访问器或事件方法签名。把“约束字符串键的命名格式（如 getX”代回「TypeScript 类型体操进阶」里“模板字面量类型最典型的用途是”的例子核对，条件一旦改变，结论就要用条件类型、infer、映射类型重新推导。

### 考点 6：填空·[K in keyof T as

- **题目**：补全代码：「TypeScript 类型体操进阶」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `[K in keyof T as `get${____<string & K>}`]: => T[K];`
- **判断依据**：在「TypeScript 类型体操进阶」里，Capitalize。在「TypeScript 类型体操进阶」里判断这道题，要把条件类型、infer、映射类型的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。回到「TypeScript 类型体操进阶」的正文示例，用“补全代码”走一遍条件类型、infer、映射类型的完整流程，能复现的结论才可以保留。

## English Overview

**Title:** Advanced Type Programming

**Summary:** Conditional types, infer, mapped and template literal types.

**Category:** TypeScript
**Level:** 高级
**Key terms:** 条件类型, infer, 映射类型, 模板字面量类型, 类型体操

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：TypeScript 5.x / Node.js 22+
；本课聚焦 条件类型。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：条件类型、infer、映射类型、模板字面量类型、类型体操
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-03-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Utility Types](https://www.typescriptlang.org/docs/handbook/utility-types.html) | 内置类型变换 |
| [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) | 类型系统与语言指南 |
| [TypeScript 发布说明](https://www.typescriptlang.org/docs/release-notes/) | 版本变化与兼容性 |

> 「TypeScript 类型体操进阶」的链接用于离线阅读后的延伸核对；App 不会自动联网。
