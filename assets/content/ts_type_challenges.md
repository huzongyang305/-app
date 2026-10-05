# TypeScript 类型体操进阶

![TypeScript 类型体操进阶](images/remaining_ts_type_challenges.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：18 分钟

## 学习目标

- 能用自己的话解释「TypeScript 类型体操进阶」解决了什么问题，而不是只背术语。
- 能说清 「条件类型」、「infer」、「映射类型」、「模板字面量类型」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「TypeScript」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：条件类型、infer、映射类型与模板字面量类型的组合用法。

## 前置知识

- 先完成上一课《TypeScript 实战：全栈类型安全》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：条件类型、infer、映射类型。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 四种类型构造速查

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

## 类型优先级速查

| 目标 | 选择 |
| --- | --- |
| 只需要复用已有类型的部分字段 | `Pick` / `Omit` |
| 需要按条件分支 | 条件类型 |
| 需要从复杂类型中提取 | `infer` |
| 需要批量转换属性 | 映射类型 |
| 需要构造字符串键 | 模板字面量类型 |
| 需要运行时校验 | zod 等库（类型只在编译期存在） |

## 工程约束速查

| 约束 | 原因 |
| --- | --- |
| 给复杂类型写注释与示例 | 后来者要能看懂 |
| 用测试验证类型（类型断言与编译） | 类型逻辑也会出错 |
| 控制深度与递归层数 | 过深会让编译器变慢甚至报错 |
| 导出类型时给语义化别名 | 报错信息更可读 |
| 不用类型体操做业务建模 | 可读性优先于炫技 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 嵌套过深的条件类型 | 编译变慢、报错难读 | 拆成多个命名类型 |
| 忘记分布式联合类型行为 | 结果与预期不符 | 用 `[T] extends [U]` 阻断分配 |
| 在类型里做运行时判断 | 无法实现 | 类型编译后消失，运行时用校验库 |
| 递归类型无终止条件 | 编译报错或超深 | 设计明确的递归出口 |
| 用 `any` 兜底复杂类型 | 类型安全失效 | 用 `unknown` 加收窄 |
| 没有类型测试 | 类型改动悄悄破坏调用方 | 用类型断言与 CI 编译检查 |

## 自测清单

- [ ] 会用条件类型与 `infer` 提取类型。
- [ ] 会用映射类型与键重映射批量改造属性。
- [ ] 会用模板字面量类型约束字符串键。
- [ ] 知道用 `[T] extends [U]` 阻断联合分配。
- [ ] 类型逻辑有注释与类型测试，且控制复杂度。


## 零基础详解：类型体操入门

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

## 动手练习


> 本课练习重点：围绕「条件类型、infer、映射类型」完成复述、实验和交付，每个结果都要能被别人检查。

先让类型检查通过，再制造一次类型错误，最后补运行时校验与测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「TypeScript 类型体操进阶」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「infer」是什么关系？

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
- 至少覆盖「条件类型」和「infer」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 本课小结

- 核心问题：「TypeScript 类型体操进阶」不是孤立术语，而是在「TypeScript」中解决一类具体问题。
- 关键关系：先分清「条件类型」与「infer」的职责，再理解「映射类型」的适用边界。
- 判断标准：能解释正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：完成练习后，用自己的话写下 3 条要点，再去做本课测验。


## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：想在条件类型中「取出」数组元素类型，应该用？

- **正确判断**：T extends Array<infer U> ? U : never
- **判断依据**：infer 用于在条件类型中声明并捕获待推断的类型变量，这是提取类型信息的标准手法。选项二返回数组类型本身而没有取出元素。选项四用于取函数返回类型。正确项「T extends Array<infer U> ? U : never」抓住了题干的核心条件，是经得起边界检验的表述。错误项「ReturnType<T>」把不同概念混在一起，缺少题干限定的前提。错误项「T extends any[] ? T : never（仅部分场景成立）」只看到了表面现象，没有解释题干真正考查的机制。错误项「keyof T」在边界或失败路径上会得出错误结果。把题干「想在条件类型中「取出」数组元素类型，应该用？」放回《TypeScript 类型体操进阶》的「条件类型、infer、映射类型与模板字面量类型的组合用法」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 2：映射类型中 `[K in keyof T as ...]` 的 as 子句作用是？

- **正确判断**：键重映射，可改名或过滤键
- **判断依据**：as 子句能把原键映射成新键（如 getX），返回 never 还能过滤掉该键。选项一是运行期断言，与类型层构造无关。选项三、四不是 as 的语义。正确项「键重映射，可改名或过滤键」完整覆盖了题目要求的关键点，没有遗漏前提。错误项「继承其他接口」在边界或失败路径上会得出错误结果。错误项「类型断言」适用于其他场景，但与本题的前提不匹配。错误项「声明默认值」忽略了题目中的限制条件，因此不成立。把题干「映射类型中 `[K in keyof T as ...]` 的 as 子句作用是？」放回《TypeScript 类型体操进阶》的「条件类型、infer、映射类型与模板字面量类型的组合用法」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 3：条件类型对联合类型会自动「分配」，想阻断这种分配应该？

- **正确判断**：用 [T] extends [U] 这种方括号写法
- **判断依据**：方括号让类型不再是被检查的裸类型参数，从而阻止分布式行为，这是控制联合分支的常用技巧。正确项「用 [T] extends [U] 这种方括号写法」完整覆盖了题目要求的关键点，没有遗漏前提。错误项「把联合改成交叉类型」适用于其他场景，但与本题的前提不匹配。错误项「加 readonly（仅部分场景成立）」把因果关系颠倒了，不能作为正确结论。错误项「用 any 包一层」忽略了题目中的限制条件，因此不成立。把题干「条件类型对联合类型会自动「分配」，想阻断这种分配应该？」放回《TypeScript 类型体操进阶》的「条件类型、infer、映射类型与模板字面量类型的组合用法」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 4：关于类型体操的工程建议，正确的是？

- **正确判断**：拆分命名类型，写注释与类型测试
- **判断依据**：复杂类型会拖慢编译并让报错难懂，需要拆分、注释与类型级测试。选项四错误，类型在编译后消失。正确项「拆分命名类型，写注释与类型测试」描述正确，能够解释题干场景中的现象与结果。错误项「越复杂越能体现水平」与课程给出的定义相冲突，不能回答题目所问。错误项「所有类型都用 any 兜底」在边界或失败路径上会得出错误结果。错误项「类型逻辑可以替代运行时校验」适用于其他场景，但与本题的前提不匹配。把题干「关于类型体操的工程建议，正确的是？」放回《TypeScript 类型体操进阶》的「条件类型、infer、映射类型与模板字面量类型的组合用法」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 5：模板字面量类型最典型的用途是？

- **正确判断**：约束字符串键的命名格式（如 getX、onX）
- **判断依据**：模板字面量类型能在类型层拼装与约束字符串形态，配合映射类型可自动生成访问器或事件方法签名。选项一正是其典型用途之外的错误描述（正确项是约束键名）。选项二、三、四都属于运行期能力。正确项「约束字符串键的命名格式（如 getX、onX）」与题干要求一致，是本课知识点的准确定义。错误项「替代正则表达式」忽略了题目中的限制条件，因此不成立。错误项「加密字符串」属于相邻主题的说法，范围与本题要求不一致。错误项「在运行时拼接字符串（仅部分场景成立）」与课程给出的定义相冲突，不能回答题目所问。把题干「模板字面量类型最典型的用途是？」放回《TypeScript 类型体操进阶》的「条件类型、infer、映射类型与模板字面量类型的组合用法」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「想在条件类型中「取出」数组元素类型，应该用？」的判断依据。
- [ ] 不看解析，能说出「映射类型中 `[K in keyof T as ...]` 的 as 子句作用是…」的判断依据。
- [ ] 不看解析，能说出「条件类型对联合类型会自动「分配」，想阻断这种分配应该？」的判断依据。
- [ ] 不看解析，能说出「关于类型体操的工程建议，正确的是？」的判断依据。
- [ ] 不看解析，能说出「模板字面量类型最典型的用途是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** Advanced Type Programming

**Summary:** Conditional types, infer, mapped and template literal types.

**Category:** TypeScript  
**Level:** 高级  
**Key terms:** 条件类型, infer, 映射类型, 模板字面量类型, 类型体操

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：TypeScript 5.x / Node.js 22+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：条件类型、infer、映射类型、模板字面量类型、类型体操
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) | 类型系统与编译配置 |
| [Decorators 与模块](https://www.typescriptlang.org/docs/) | 语言特性与生态集成 |

> 本课主题：条件类型、infer、映射类型与模板字面量类型的组合用法。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

