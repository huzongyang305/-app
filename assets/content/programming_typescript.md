# TypeScript 类型系统

![TypeScript 类型系统的五个层次](images/diagram_ts_type_system.webp)

![TypeScript 类型系统](images/remaining_typescript.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「TypeScript 类型系统」解决了什么问题，而不是只背术语。
- 能说清 「TypeScript」、「类型」、「泛型」、「类型收窄」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「TypeScript」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：类型收窄、泛型、工具类型与工程配置。

## 前置知识

- 会进行基本的文件、命令行或浏览器操作；遇到不熟悉的术语先查本课关键词。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：TypeScript、类型、泛型。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 为什么需要 TypeScript

JavaScript 的类型错误只在运行时暴露。TypeScript 在编译期做静态检查，同时保留 JS 的全部能力——类型只在编译期存在，产物仍是普通 JavaScript。

## 基础类型

| 类型 | 说明 |
| --- | --- |
| 原始类型 | string、number、boolean、null、undefined、symbol、bigint |
| 数组与元组 | `string[]`、`[number, string]`（定长且按位定型） |
| 对象类型 | `{ id: number; name: string }`、interface、type |
| 联合与交叉 | `A \| B`、`A & B` |
| 字面量类型 | `'success' \| 'error'`，把取值收敛为固定集合 |
| any / unknown / never | any 放弃检查；unknown 安全的外部输入；never 表示不可能 |

实践原则：**能用 unknown 就不用 any**；外部数据（接口返回、JSON）先当 unknown，校验后再收窄类型。

## interface 与 type

interface 适合描述对象与可扩展的契约（支持声明合并）；type 更灵活，可定义联合、元组、条件类型与映射类型。团队里通常约定：对象结构用 interface，复杂类型运算用 type。

## 泛型与类型运算

泛型让函数与组件在保持类型安全的前提下复用；常用工具类型包括 Partial、Required、Pick、Omit、Record、ReturnType、Awaited。条件类型与 infer 可以在类型层面做模式匹配，映射类型能批量改造属性（如把全部属性变为可选或只读）。

## 类型收窄

常见手段：typeof、instanceof、in、可辨识联合（discriminated union，用共同字段区分成员）、自定义类型守卫（`x is T`）以及断言函数。可辨识联合 + switch 穷尽检查是建模业务状态最实用的模式。

## 工程配置要点

1. 开启 strict 系列选项（strictNullChecks、noImplicitAny、strictFunctionTypes）。
2. 类型检查纳入 CI：`tsc --noEmit`，避免类型错误进主干。
3. 运行时校验不能省：类型在运行时不存在，接口数据仍需 zod/valibot 之类做校验。
4. 避免滥用断言（as）与非空断言（!），它们会掩盖真实错误。
5. 声明文件（.d.ts）用于给无类型的第三方库补类型。

## 本课小结
TypeScript 的价值是**把类型错误从运行时提前到编译期**，并用类型表达业务约束。掌握泛型、收窄与工具类型，就能写出既安全又易重构的前端与 Node 代码。


## 类型速查

| 类型 | 写法 | 说明 |
| --- | --- | --- |
| 原始类型 | `string`、`number`、`boolean`、`bigint`、`symbol` | 小写，不用包装类型 |
| 数组 | `string[]` 或 `Array<string>` | 推荐前者 |
| 元组 | `[string, number]` | 固定长度与顺序 |
| 联合 | `string \| number` | 值可以是其中之一 |
| 交叉 | `A & B` | 同时具备两组属性 |
| 字面量 | `"on" \| "off"` | 精确取值 |
| 对象 | `{ id: number; name?: string }` | `?` 表示可选 |
| 只读 | `readonly string[]`、`Readonly<T>` | 编译期禁止修改 |
| 索引签名 | `Record<string, number>` | 键值集合 |
| 可空 | `string \| null` | 开启 `strictNullChecks` 后必须显式处理 |
| 任意 | `any` | 关闭检查，尽量避免 |
| 未知 | `unknown` | 安全版 `any`，需收窄后使用 |
| 永远不返回 | `never` | 抛异常或死循环的返回值 |
| `void` | 无返回值 | 与 `undefined` 区分 |

## tsconfig 常用选项速查

| 选项 | 建议 | 作用 |
| --- | --- | --- |
| `strict` | `true` | 开启全部严格检查 |
| `target` | `ES2022` 起 | 输出语法版本 |
| `module` / `moduleResolution` | 按运行时选择 | 决定导入解析方式 |
| `noUncheckedIndexedAccess` | `true` | 下标访问结果可能是 `undefined` |
| `exactOptionalPropertyTypes` | 可选开启 | 更严格地区分「缺失」与 `undefined` |
| `noImplicitOverride` | `true` | 重写方法必须写 `override` |
| `skipLibCheck` | `true` | 跳过依赖类型检查，加速编译 |
| `noEmit` | CI 时 `true` | 只做类型检查 |
| `paths` | 按需 | 路径别名，打包器需同步配置 |
| `declaration` | 库项目 `true` | 生成 `.d.ts` |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `Object` 或 `{}` 当类型 | 几乎不报错，失去检查意义 | 用具体接口或 `Record<string, unknown>` |
| 到处 `as any` | 错误延后到运行时 | 收窄类型或补类型定义 |
| `arr[i]` 直接当非空 | 运行时可能 `undefined` | 开启 `noUncheckedIndexedAccess` 并判空 |
| `interface` 里定义函数属性写 `method(): void` 与 `method: () => void` 混用 | 类型兼容差异导致困惑 | 明确语义，团队内统一风格 |
| 用 `enum` 与字符串字面量混用 | 运行时行为不一致 | 简单场景直接用字面量联合 |
| `JSON.parse` 结果直接断言类型 | 字段不存在时报错 | 运行时校验（zod 等） |
| `const` 声明的对象属性被改 | 意料之外的状态变化 | 用 `as const` 或 `Object.freeze` |
| 回调里用普通函数访问 `this` | `this` 指向丢失 | 用箭头函数或显式绑定 |
| 导入类型用了值导入 | 打包体积变大 | 用 `import type { Foo } from "..."` |
| 忽略 `strictNullChecks` 报错 | 线上 `Cannot read properties of undefined` | 显式处理 `null` / `undefined` |

## 自测清单

- [ ] 新项目一律开启 `strict`。
- [ ] 用字面量联合替代不必要的枚举。
- [ ] 外部数据先 `unknown` 再校验，不直接断言。
- [ ] 用 `import type` 导入纯类型。
- [ ] CI 中单独执行 `tsc --noEmit` 做类型门禁。


## 零基础详解：类型是「给 JavaScript 加的合同」

### 一句话说清它是什么

TypeScript = JavaScript + 类型系统。类型只在**编译期**存在，
编译产物还是普通 JavaScript。它的价值是：把「运行时才发现的错误」提前到写代码时。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 类型 | 合同条款 | 约定这个变量能做什么 |
| 编译器 | 审核员 | 编译期检查合同是否被违反 |
| 编译产物 | 去掉批注的正文 | 类型信息全部消失，只剩 JS |
| `any` | 撕掉合同 | 关掉检查，等于没写 TS |
| `unknown` | 未核验的包裹 | 用之前必须先检查 |

### 逐行拆解第一段代码

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

| 语法 | 含义 |
| --- | --- |
| `type User = {...}` | 定义一个类型别名 |
| `id: number` | 字段类型约定 |
| `email?: string` | 可选字段，可能不存在 |
| `: string`（函数后） | 函数返回值类型 |
| `const u: User = ...` | 对象必须符合 User 的约定 |

### `interface` 与 `type` 怎么选

| 对比 | `interface` | `type` |
| --- | --- | --- |
| 描述对象 | 擅长 | 擅长 |
| 联合类型 | 不能 | `type A = B \| C` |
| 条件类型 / 映射类型 | 不能 | 可以 |
| 声明合并 | 支持（同名自动合并） | 不支持 |
| 建议 | 对外暴露的对象契约、需要扩展时 | 联合、工具类型、组合类型 |

### 类型推断与注解的取舍

```typescript
const count = 3;                    // 推断为 number，不用手写
const name: string = "小明";         // 类型不明显时写出来更清楚

function add(a: number, b: number) { // 参数必须标注
  return a + b;                      // 返回值自动推断为 number
}
```

规则：**能推断出来的不写，推断不出来的（参数、公共 API）必须写。**

### `any`、`unknown`、`never` 三个特殊类型

| 类型 | 含义 | 使用建议 |
| --- | --- | --- |
| `any` | 关闭检查 | 尽量避免，用 `unknown` 代替 |
| `unknown` | 未知，用前必须收窄 | 处理外部输入的首选 |
| `never` | 永远不会有值 | 表示不会返回的函数、穷尽检查 |
| `void` | 没有返回值 | 事件处理、打印类函数 |

```typescript
function parse(input: unknown): number {
  if (typeof input === "number") return input;      // 收窄
  if (typeof input === "string") return Number(input);
  throw new Error("不支持的输入类型");
}
```

### 配置：三行决定项目质量

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true
  }
}
```

`strict: true` 会一次性打开 `strictNullChecks`、`noImplicitAny` 等一组检查，新项目务必开启。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `any` 图省事 | 类型检查形同虚设 | 换 `unknown` 并收窄 |
| 直接断言 `as User` | 运行时还是可能崩 | 用 zod 等做运行时校验 |
| 以为类型能保护运行时 | 接口数据照样出错 | 边界做真实校验 |
| 忘了可选链 | 空值报错 | 用 `?.` 与 `??` |
| 只用 `tsc` 却以为打包会检查 | 类型错误照样上线 | CI 单独跑 `tsc --noEmit` |
| 忽略索引越界 | 数组取值可能 undefined | 开 `noUncheckedIndexedAccess` |
| 类型写得太复杂 | 没人看得懂 | 拆成小的命名类型 |
| 函数参数不标类型 | 隐式 any 报错 | 显式标注参数与返回值 |

### 手把手练习：安全解析接口返回

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

`unknown` + 类型守卫，是处理外部数据最稳的组合。

### 学完自测

- [ ] 能说出 TypeScript 类型在运行时是否存在。
- [ ] 能解释 `unknown` 比 `any` 安全在哪里。
- [ ] 能写出一个类型守卫函数。
- [ ] 知道 `strict: true` 大致开启哪些检查。
- [ ] 能说出 `interface` 与 `type` 各自擅长的场景。

## 动手练习


> 本课练习重点：围绕「TypeScript、类型、泛型」完成复述、实验和交付，每个结果都要能被别人检查。

先让类型检查通过，再制造一次类型错误，最后补运行时校验与测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「TypeScript 类型系统」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「类型」是什么关系？

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
- 至少覆盖「TypeScript」和「类型」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。



## 可运行练习

下面 3 个任务围绕“TypeScript 类型系统”展开，代码可以直接粘贴到 App 的离线沙箱里运行；如果示例会读取标准输入，请按代码注释在沙箱的 stdin 区域填入同样格式的数据。

### 任务 1：先跑通，再解释

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

**预期输出**：运行后会输出与“TypeScript 类型系统”相关的关键结果；请重点核对输出行数、最后一个数值和异常提示。

**验收标准**：代码能正常运行；逐行解释每个变量的值如何变化，并指出哪一行决定了最终结果。

### 任务 2：只改一个条件

复制上面的代码，只修改一个输入、边界或参数（例如空值、最大值、循环次数、过滤条件），先写出你的预测，再实际运行。

**验收标准**：留下“原结果 → 改动 → 预测 → 实际结果 → 差异原因”五步记录；如果预测错误，要写出修正后的心智模型。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

**验收标准**：代码不少于 10 行，至少包含 1 个边界检查；把代码和运行结果保存到笔记或片段库。


## 故障现场

这一节把“TypeScript 类型系统”最常见的失败方式还原成现场记录，练习时按“症状 → 复现 → 定位 → 修复 → 预防”的顺序排查。

### 现场 1：“TypeScript 类型系统”的 TypeScript 常规用例通过，但边界用例失败

**症状**：在“TypeScript 类型系统”的练习或生产场景里出现““TypeScript 类型系统”的 TypeScript 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发““TypeScript 类型系统”的 TypeScript 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“TypeScript 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：为“TypeScript 类型系统”补一条空值或极值用例，把前置条件写成断言，并让失败信息直接指出是哪个输入越界

**预防**：把““TypeScript 类型系统”的 TypeScript 常规用例通过，但边界用例失败”写成一条自动化用例，并在“TypeScript 类型系统”的验收清单里保留对应检查项。


### 现场 2：“TypeScript 类型系统”的 类型 结果在两次运行之间不一致

**症状**：在“TypeScript 类型系统”的练习或生产场景里出现““TypeScript 类型系统”的 类型 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发““TypeScript 类型系统”的 类型 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“类型 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：固定“TypeScript 类型系统”使用的版本与随机种子，记录两次运行的完整输入和输出，再逐项消除非确定性来源

**预防**：把““TypeScript 类型系统”的 类型 结果在两次运行之间不一致”写成一条自动化用例，并在“TypeScript 类型系统”的验收清单里保留对应检查项。


### 现场 3：“TypeScript 类型系统”的验证只在开发机通过

**症状**：在“TypeScript 类型系统”的练习或生产场景里出现““TypeScript 类型系统”的验证只在开发机通过”。

**复现**：准备一组最小输入，只保留触发““TypeScript 类型系统”的验证只在开发机通过”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，TypeScript 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：把“TypeScript 类型系统”的运行环境、输入样本和预期输出写成清单，并在另一套环境复跑同一条命令

**预防**：把““TypeScript 类型系统”的验证只在开发机通过”写成一条自动化用例，并在“TypeScript 类型系统”的验收清单里保留对应检查项。



## 版本与时效

这一节记录“TypeScript 类型系统”涉及的版本基线与升级检查点，避免把某个版本的默认行为当成永久结论。

- TypeScript 5.x 主线持续收紧类型推导、装饰器与模块解析行为
- strict、noUncheckedIndexedAccess、verbatimModuleSyntax 建议逐步打开
- 升级前先跑 tsc --noEmit，再处理构建工具与 ESLint 规则差异
- 官方发布说明：https://devblogs.microsoft.com/typescript/

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改一个版本变量，记录编译、测试、性能与产物体积的变化。
- 重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。
- 升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：TypeScript 的类型检查发生在什么时候？

- **正确判断**：编译期
- **判断依据**：类型只在编译期存在，产物是普通 JavaScript，运行时数据仍需校验。其他选项：类型只在编译期存在，运行时数据仍需校验。针对「TypeScript 的类型检查发生在什么时候，」，本课在「本课小结」中说明：TypeScript 的价值是把类型错误从运行时提前到编译期，并用类型表达业务约束。本课还在「为什么需要 TypeScript」中说明：TypeScript 在编译期做静态检查，同时保留 JS 的全部能力——类型只在编译期存在，产物仍是普通 JavaScript。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 2：相比 any，unknown 的优势是？

- **正确判断**：更安全：使用前必须收窄类型
- **判断依据**：正确答案是「更安全：使用前必须收窄类型」，本课在「基础类型」中说明：外部数据（接口返回、JSON）先当 unknown，校验后再收窄类型。unknown 表示未知类型，必须先判断或断言才能使用。本课还在「零基础详解：类型是「给 JavaScript 加的合同」」中说明：TypeScript = JavaScript + 类型系统。本课还在「零基础详解：类型是「给 JavaScript 加的合同」」中说明：能解释 unknown 比 any 安全在哪里。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：接口返回的数据还需要运行时校验吗？

- **正确判断**：需要，类型在运行时不存在
- **判断依据**：正确答案是「需要，类型在运行时不存在」，本课在「工程配置要点」中说明：运行时校验不能省：类型在运行时不存在，接口数据仍需 zod/valibot 之类做校验。类型断言不改变运行时数据，接口数据要用 zod 等做校验。本课还在「零基础详解：类型是「给 JavaScript 加的合同」」中说明：能说出 TypeScript 类型在运行时是否存在。本课还在「为什么需要 TypeScript」中说明：JavaScript 的类型错误只在运行时暴露。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：type 与 interface 的主要差别是？

- **正确判断**：interface 支持声明合并
- **判断依据**：正确答案是「interface 支持声明合并」，本课在「interface 与 type」中说明：interface 适合描述对象与可扩展的契约（支持声明合并）。对外发布的库常用 interface 便于使用者扩展，内部组合类型多用 type。本课还在「interface 与 type」中说明：团队里通常约定：对象结构用 interface，复杂类型运算用 type。本课还在「零基础详解：类型是「给 JavaScript 加的合同」」中说明：TypeScript = JavaScript + 类型系统。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 5：as const 的作用是？

- **正确判断**：把值推断为最窄的只读字面量类型（readonly 元组/字面量）
- **判断依据**：正确答案是「把值推断为最窄的只读字面量类型（readonly 元组/字面量）」，本课在「工程配置要点」中说明：类型检查纳入 CI：tsc --noEmit，避免类型错误进主干。它只影响类型推断，运行时仍可被修改（需要 Object.freeze 才真正冻结）。本课还在「为什么需要 TypeScript」中说明：JavaScript 的类型错误只在运行时暴露。本课还在「工程配置要点」中说明：运行时校验不能省：类型在运行时不存在，接口数据仍需 zod/valibot 之类做校验。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 6：补全代码：「TypeScript 类型系统」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `"____": true,`

- **正确判断**：noUncheckedIndexedAccess / nouncheckedindexedaccess
- **判断依据**：正确答案是「noUncheckedIndexedAccess」，本课在「本课小结」中说明：掌握泛型、收窄与工具类型，就能写出既安全又易重构的前端与 Node 代码。本课还在「零基础详解：类型是「给 JavaScript 加的合同」」中说明：strict: true 会一次性打开 strictNullChecks、noImplicitAny 等一组检查，新项目务必开启。本课还在「零基础详解：类型是「给 JavaScript 加的合同」」中说明：知道 strict: true 大致开启哪些检查。
- **迁移检查**：不看题干，用自己的话补全这句话，再与标准答案对照。

### 补充自测（2 题）

1. 围绕“TypeScript 类型系统”中的 TypeScript、类型、泛型，下列哪两项是本课强调的实践判断？
2. 下面这段 JavaScript 代码复现了“TypeScript 类型系统”中 TypeScript、类型、泛型 相关的一个常见故障，哪一项最准确地解释了问题？

这些题按“先定位概念、再排除边界错误、最后核对答案”的顺序作答；每题解析都给出了判断依据。


## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「TypeScript 的类型检查发生在什么时候？」的判断依据。
- [ ] 不看解析，能说出「相比 any，unknown 的优势是？」的判断依据。
- [ ] 不看解析，能说出「接口返回的数据还需要运行时校验吗？」的判断依据。
- [ ] 不看解析，能说出「type 与 interface 的主要差别是？」的判断依据。
- [ ] 不看解析，能说出「as const 的作用是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「TypeScript 类型系统」示例中，下面这行代码缺少哪个关键字或…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把本课反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `string[]` | \| 数组与元组 \| `string[]`、`[number, string]`（定长且按位定型） \| |
| `[number, string]` | \| 数组与元组 \| `string[]`、`[number, string]`（定长且按位定型） \| |
| `{ id: number; name: string }` | \| 对象类型 \| `{ id: number; name: string }`、interface、type \| |
| `A \| B` | \| 联合与交叉 \| `A \\| B`、`A & B` \| |
| `A & B` | \| 联合与交叉 \| `A \\| B`、`A & B` \| |
| `'success' \| 'error'` | \| 字面量类型 \| `'success' \\| 'error'`，把取值收敛为固定集合 \| |
| `x is T` | 常见手段：typeof、instanceof、in、可辨识联合（discriminated union，用共同字段区分成员）、自定义类型守卫（`x is T`）以及断言函数。可辨识联合 + switch 穷尽检查是建模业… |
| `tsc --noEmit` | 类型检查纳入 CI：`tsc --noEmit`，避免类型错误进主干。 |
| `string` | \| 原始类型 \| `string`、`number`、`boolean`、`bigint`、`symbol` \| 小写，不用包装类型 \| |
| `number` | \| 原始类型 \| `string`、`number`、`boolean`、`bigint`、`symbol` \| 小写，不用包装类型 \| |
| `boolean` | \| 原始类型 \| `string`、`number`、`boolean`、`bigint`、`symbol` \| 小写，不用包装类型 \| |
| `bigint` | \| 原始类型 \| `string`、`number`、`boolean`、`bigint`、`symbol` \| 小写，不用包装类型 \| |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：TypeScript 的类型检查发生在什么时候？

**参考回答**：类型只在编译期存在，产物是普通 JavaScript，运行时数据仍需校验。其他选项：类型只在编译期存在，运行时数据仍需校验。针对「TypeScript 的类型检查发生在什么时候，」，本课在「本课小结」中说明：TypeScript 的价值是把类型错误从运行时提前到编译期，并用类型表达业务约束。本课还在「为什么需要 TypeScript」中说明：TypeScript 在编译期做静态检查，同时保留 JS 的全部能力——类型只在编译期存在，产物仍是普通 JavaScript。

### 追问 2：相比 any，unknown 的优势是？

**参考回答**：正确答案是「更安全：使用前必须收窄类型」，本课在「基础类型」中说明：外部数据（接口返回、JSON）先当 unknown，校验后再收窄类型。unknown 表示未知类型，必须先判断或断言才能使用。本课还在「零基础详解·类型是「给 JavaScript 加的合同」」中说明：TypeScript = JavaScript + 类型系统。本课还在「零基础详解·类型是「给 JavaScript 加的合同」」中说明：能解释 unknown 比 any 安全在哪里。

### 追问 3：接口返回的数据还需要运行时校验吗？

**参考回答**：正确答案是「需要，类型在运行时不存在」，本课在「工程配置要点」中说明：运行时校验不能省：类型在运行时不存在，接口数据仍需 zod/valibot 之类做校验。类型断言不改变运行时数据，接口数据要用 zod 等做校验。本课还在「零基础详解·类型是「给 JavaScript 加的合同」」中说明：能说出 TypeScript 类型在运行时是否存在。本课还在「为什么需要 TypeScript」中说明：JavaScript 的类型错误只在运行时暴露。

### 追问 4：type 与 interface 的主要差别是？

**参考回答**：正确答案是「interface 支持声明合并」，本课在「interface 与 type」中说明：interface 适合描述对象与可扩展的契约（支持声明合并）。对外发布的库常用 interface 便于使用者扩展，内部组合类型多用 type。本课还在「interface 与 type」中说明：团队里通常约定：对象结构用 interface，复杂类型运算用 type。本课还在「零基础详解·类型是「给 JavaScript 加的合同」」中说明：TypeScript = JavaScript + 类型系统。

### 追问 5：as const 的作用是？

**参考回答**：正确答案是「把值推断为最窄的只读字面量类型（readonly 元组/字面量）」，本课在「工程配置要点」中说明：类型检查纳入 CI：tsc --noEmit，避免类型错误进主干。它只影响类型推断，运行时仍可被修改（需要 Object.freeze 才真正冻结）。本课还在「为什么需要 TypeScript」中说明：JavaScript 的类型错误只在运行时暴露。本课还在「工程配置要点」中说明：运行时校验不能省：类型在运行时不存在，接口数据仍需 zod/valibot 之类做校验。

## English Overview

**Title:** TypeScript Types

**Summary:** Narrowing, generics, utility types and strict mode.

**Category:** TypeScript  
**Level:** 高级  
**Key terms:** TypeScript, 类型, 泛型, 类型收窄, strict

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：TypeScript 5.x / Node.js 22+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：TypeScript、类型、泛型、类型收窄、strict
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


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
- Related terms: TypeScript, 类型, 泛型, 类型收窄
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.


## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 为什么需要 TypeScript | 为什么需要 TypeScript |
| 基础类型 | 基础Types |
| interface 与 type | interface 与 type |
| 泛型与类型运算 | 泛型与Types运算 |
| 类型收窄 | Types收窄 |
| 工程配置要点 | 工程配置要点 |
| 本课小结 | Summary |
| 类型速查 | Types速查 |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) | 类型系统与编译配置 |
| [Decorators 与模块](https://www.typescriptlang.org/docs/) | 语言特性与生态集成 |

> 本课主题：类型收窄、泛型、工具类型与工程配置。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
