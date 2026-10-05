# TypeScript 工具类型与声明文件

![常用工具类型与声明文件](images/diagram_ts_utility_types.webp)

![TypeScript 工具类型与声明文件](images/remaining_ts_utility_types.webp)

> 内容更新时间：2026-10-03 · 学习阶段：入门 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「TypeScript 工具类型与声明文件」解决了什么问题，而不是只背术语。
- 能说清 「TypeScript」、「工具类型」、「映射类型」、「声明文件」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「TypeScript」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：Partial/Pick/Omit/Record、映射类型与 .d.ts。

## 前置知识

- 先完成上一课《TypeScript 类型收窄与泛型》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：入门。只需要基本计算机操作，不要求编程经验。
- 开始前先复习：TypeScript、工具类型、映射类型。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 内置工具类型

| 工具类型 | 作用 |
| --- | --- |
| `Partial<T>` / `Required<T>` | 全部可选 / 全部必填 |
| `Pick<T, K>` / `Omit<T, K>` | 挑选字段 / 排除字段 |
| `Record<K, V>` | 构造键值映射类型 |
| `Readonly<T>` | 全部只读 |
| `ReturnType<F>` / `Parameters<F>` | 提取函数返回值 / 参数类型 |
| `Awaited<T>` | 提取 Promise 的结果类型 |
| `Exclude` / `Extract` / `NonNullable` | 联合类型的筛选 |

这些工具类型在 API 层非常实用：创建请求 DTO 用 `Pick`，更新接口用 `Partial`，对外隐藏敏感字段用 `Omit`。

## 映射类型与模板字面量类型

映射类型可以批量改造属性（如全部加 `readonly`、把值类型统一替换）；键重映射 `as` 可重命名。模板字面量类型让字符串也具备类型约束，例如 `type EventName = \`on${Capitalize<string>}\``，常用于事件名与 CSS 属性。

## 声明文件

`.d.ts` 为无类型的第三方库补类型：`declare module 'legacy-lib' { export function run(x: string): void }`。全局类型放 `global.d.ts`，通过 `tsconfig` 的 `types`/`include` 引入。

## 工程实践

1. 类型放在 `types/` 或与实现同文件，避免全局污染。
2. 用 `type` 定义联合与工具类型，`interface` 定义对象契约（可扩展、可合并）。
3. 生成类型而非手写：从后端 OpenAPI/GraphQL schema 生成客户端类型，避免契约漂移。
4. 类型也要测试：用 `expectType` 或 `tsd` 校验类型行为。

## 本课小结
工具类型让你**从已有类型派生新类型**，而不是重复声明；声明文件让整个生态可用。二者配合，TypeScript 才能真正成为"可执行的文档"。


## 工具类型速查

| 工具类型 | 作用 | 示例 |
| --- | --- | --- |
| `Partial<T>` | 全部属性可选 | 更新接口的补丁对象 |
| `Required<T>` | 全部属性必填 | 校验后的完整配置 |
| `Readonly<T>` | 全部属性只读 | 不可变数据 |
| `Pick<T, K>` | 只保留指定字段 | 列表项 DTO |
| `Omit<T, K>` | 排除指定字段 | 去敏感字段 |
| `Record<K, V>` | 键值映射 | 字典、枚举映射 |
| `Exclude<T, U>` | 从联合中排除 | 过滤字面量联合 |
| `Extract<T, U>` | 取联合交集 | 挑选特定成员 |
| `NonNullable<T>` | 去掉 null 与 undefined | 校验后的类型 |
| `ReturnType<F>` | 取函数返回值类型 | 复用已有函数签名 |
| `Parameters<F>` | 取参数元组 | 包装函数 |
| `Awaited<T>` | 解开 Promise | 异步返回值 |
| `T[K]` | 索引访问类型 | 取某字段的类型 |
| `keyof T` | 键的联合 | 动态访问字段 |

```ts
interface User {
  id: string;
  name: string;
  password: string;
  createdAt: Date;
}

// 对外返回去掉密码，创建时不需要 id 与时间
type UserDto = Omit<User, "password">;
type CreateUserInput = Omit<User, "id" | "createdAt" | "password"> & {
  password: string;
};

// 补丁更新：只允许传需要改的字段
type UserPatch = Partial<Pick<User, "name" | "password">>;

// 用映射类型批量转换：把字段都变成可空的
type Nullable<T> = { [K in keyof T]: T[K] | null };

// 条件类型 + infer：取 Promise 内部类型
type Unwrap<T> = T extends Promise<infer U> ? U : T;
type Value = Awaited<Promise<number>>;   // number
```

## .d.ts 声明速查

| 场景 | 写法 |
| --- | --- |
| 声明全局函数 | `declare function greet(name: string): void;` |
| 声明模块 | `declare module "my-lib" { export const version: string; }` |
| 声明命名空间 | `declare namespace NodeJS { interface ProcessEnv { ... } }` |
| 扩展第三方类型 | 新建 `types/xxx.d.ts` 用 `declare module` 增强 |
| 只声明类型 | `export type { Foo };` |
| 声明资源模块 | `declare module "*.svg" { const url: string; export default url; }` |
| 全局类型 | `declare global { interface Window { __APP__: AppConfig } }` |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 全用 `Partial<T>` 表达入参 | 关键字段变成可空，校验缺失 | 用 `Pick` / `Omit` 精确表达必填项 |
| `Omit` 的键拼错 | 编译不报错（键类型不匹配会报，但字符串自由） | 用 `satisfies` 或常量联合约束键 |
| `.d.ts` 里写实现代码 | 编译错误或语义混乱 | 声明文件只放类型与签名 |
| 修改 node_modules 里的类型 | 重新安装即丢失 | 用模块增强写在项目内 |
| 用 `any` 绕过工具类型 | 失去检查能力 | 用 `unknown` + 收窄 |
| 深层嵌套类型硬写 | 难维护 | 组合工具类型或抽公共类型 |
| `Record<string, any>` 到处用 | 任意键任意值，无检查 | 明确键与值类型 |
| 忽略 `strictNullChecks` | 运行时空值错误 | 开启严格模式并处理 `null` |
| 类型断言覆盖不兼容类型 | 运行时报错 | 先校验再断言 |
| 在运行时依赖类型 | 类型在编译后被擦除 | 需要运行时校验时用 zod 等 |

## 自测清单

- [ ] 会用 `Pick` / `Omit` / `Partial` 精准定义 DTO。
- [ ] 会用映射类型批量改造字段。
- [ ] 会用条件类型 + `infer` 提取内部类型。
- [ ] 为第三方库补充类型时写在项目内的 `.d.ts`。
- [ ] 类型只在编译期存在，运行时要另做校验。


## 零基础详解：工具类型与类型组合

### 一句话说清它是什么

工具类型是 TypeScript 内置的「类型加工机」：
从已有类型**派生出新类型**，避免到处复制字段定义，字段改名时也就不会漏改。

### 用生活比喻理解

| 工具类型 | 比喻 | 说明 |
| --- | --- | --- |
| `Partial<T>` | 全部选项变成「可填可不填」 | 用于更新接口 |
| `Required<T>` | 全部变成必填 | 用于校验后的数据 |
| `Pick<T, K>` | 只保留几项 | 列表页只取少量字段 |
| `Omit<T, K>` | 去掉几项 | 去掉密码等敏感字段 |
| `Record<K, V>` | 建一张映射表 | 字典、配置集合 |
| `Readonly<T>` | 全部只读 | 防止意外修改 |

### 一个模型派生五种类型

```typescript
type User = {
  id: number;
  name: string;
  email: string;
  password: string;
  createdAt: Date;
};

type UserUpdate = Partial<Omit<User, "id" | "createdAt">>;   // 更新：字段可选且不能改 id
type UserPublic = Omit<User, "password">;                    // 对外：去掉密码
type UserListItem = Pick<User, "id" | "name">;               // 列表：只要两项
type UserMap = Record<string, UserPublic>;                   // 索引：按 id 存
type FrozenUser = Readonly<UserPublic>;                       // 只读
```

**一处改动，五处同步**：给 `User` 加字段，上面的类型自动跟上。

### 联合类型的加工

```typescript
type Status = "pending" | "running" | "done" | "failed";

type FinalStatus = Extract<Status, "done" | "failed">;    // "done" | "failed"
type ActiveStatus = Exclude<Status, FinalStatus>;          // "pending" | "running"

type EventName = `on${Capitalize<Status>}`;                // 模板字面量类型
// "onPending" | "onRunning" | "onDone" | "onFailed"
```

| 工具 | 作用 |
| --- | --- |
| `Extract<T, U>` | 取出 T 中属于 U 的部分 |
| `Exclude<T, U>` | 从 T 中排除 U |
| `NonNullable<T>` | 去掉 null 与 undefined |
| `ReturnType<F>` | 取函数返回值类型 |
| `Parameters<F>` | 取函数参数类型元组 |
| `Awaited<T>` | 解开 Promise 的包裹 |

### 类型推导要跟着实现走

```typescript
const ROLES = ["admin", "editor", "viewer"] as const;
type Role = (typeof ROLES)[number];        // "admin" | "editor" | "viewer"

// 运行时校验与静态类型同源，永远不会漂移
function isRole(value: string): value is Role {
  return (ROLES as readonly string[]).includes(value);
}
```

### 新手最容易踩的七个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 到处复制字段 | 加字段时漏改 | 用工具类型派生 |
| 用 `Omit` 去掉必填字段后忘了补 | 结构不完整 | 明确组合，如 `Omit` 加 `Partial` |
| 索引签名写成 `any` | 失去检查 | 用 `Record<string, T>` |
| 误以为 `Readonly` 是深层的 | 内层仍可改 | 深层只读需自定义递归类型 |
| 用 `Partial` 当返回值 | 调用方到处判 undefined | 只在输入侧用 |
| 模板字面量类型滥用 | 类型报错难读 | 复杂场景退回普通联合 |
| 忘了 `as const` | 推断成 string 而不是字面量 | 常量数组加 `as const` |

### 手把手练习：从实体派生 API 类型

```typescript
type Product = {
  id: string;
  title: string;
  price: number;
  stock: number;
  internalNote: string;
};

type ProductCreate = Omit<Product, "id" | "internalNote">;
type ProductPatch = Partial<ProductCreate>;
type ProductPublic = Omit<Product, "internalNote">;
type ProductIndex = Record<Product["id"], ProductPublic>;

function applyPatch(base: ProductPublic, patch: ProductPatch): ProductPublic {
  return { ...base, ...patch };
}

const item: ProductPublic = { id: "p1", title: "键盘", price: 199, stock: 5 };
const updated = applyPatch(item, { price: 179 });

const index: ProductIndex = { [item.id]: updated };
console.log(JSON.stringify(index, null, 2));
```

### 学完自测

- [ ] 能说出 `Pick` 与 `Omit` 的区别。
- [ ] 知道为什么更新接口常用 `Partial<Omit<T, "id">>`。
- [ ] 能说出 `Extract` 与 `Exclude` 的区别。
- [ ] 知道 `as const` 解决了什么问题。
- [ ] 能用工具类型从实体派生出对外与创建用的类型。

## 动手练习


> 本课练习重点：围绕「TypeScript、工具类型、映射类型」完成复述、实验和交付，每个结果都要能被别人检查。

先让类型检查通过，再制造一次类型错误，最后补运行时校验与测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「TypeScript 工具类型与声明文件」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「工具类型」是什么关系？

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
- 至少覆盖「TypeScript」和「工具类型」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：从类型中排除若干字段应使用？

- **正确判断**：Omit
- **判断依据**：Omit 用于隐藏敏感字段或裁剪 DTO。其他选项：Partial 让字段可选，Record 构造映射类型，Pick 是保留字段。针对「从类型中排除若干字段应使用，」，本课在「内置工具类型」中说明：这些工具类型在 API 层非常实用：创建请求 DTO 用 Pick，更新接口用 Partial，对外隐藏敏感字段用 Omit。本课还在「本课小结」中说明：工具类型让你从已有类型派生新类型，而不是重复声明。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：把类型所有属性变为可选应使用？

- **正确判断**：Partial
- **判断依据**：Partial 常用于更新接口（PATCH）的请求体。其他选项：Readonly 让字段只读，Required 做相反操作，Exclude 作用于联合类型。针对「把类型所有属性变为可选应使用，」，本课在「内置工具类型」中说明：这些工具类型在 API 层非常实用：创建请求 DTO 用 Pick，更新接口用 Partial，对外隐藏敏感字段用 Omit。本课还在「映射类型与模板字面量类型」中说明：映射类型可以批量改造属性（如全部加 readonly、把值类型统一替换）。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 3：.d.ts 文件的作用是？

- **正确判断**：为无类型的第三方库补充类型声明
- **判断依据**：正确答案是「为无类型的第三方库补充类型声明」，本课在「声明文件」中说明：.d.ts 为无类型的第三方库补类型：declare module 'legacy-lib' { export function run(x: string): void }。它让 JS 库也能获得类型提示与检查。本课还在「工程实践」中说明：用 type 定义联合与工具类型，interface 定义对象契约（可扩展、可合并）。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 4：Pick<T, K> 与 Omit<T, K> 的区别是？

- **正确判断**：Pick 只保留 K 指定的字段
- **判断依据**：正确答案是「Pick 只保留 K 指定的字段」，本课在「零基础详解：工具类型与类型组合」中说明：能用工具类型从实体派生出对外与创建用的类型。对外暴露 DTO 时常用 Pick 选字段、Omit 去掉密码等敏感字段。本课还在「零基础详解：工具类型与类型组合」中说明：工具类型是 TypeScript 内置的「类型加工机」。本课还在「工程实践」中说明：用 type 定义联合与工具类型，interface 定义对象契约（可扩展、可合并）。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 5：Record<string, number> 表示？

- **正确判断**：键为 string、值为 number 的对象类型
- **判断依据**：正确答案是「键为 string、值为 number 的对象类型」，本课在「本课小结」中说明：工具类型让你从已有类型派生新类型，而不是重复声明。Record 常用于描述映射表、字典与配置项集合。本课还在「映射类型与模板字面量类型」中说明：映射类型可以批量改造属性（如全部加 readonly、把值类型统一替换）。本课还在「零基础详解：工具类型与类型组合」中说明：工具类型是 TypeScript 内置的「类型加工机」。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 6：补全代码：「TypeScript 工具类型与声明文件」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `type EventName = `on${____<Status>}`; // 模板字面量类型`

- **正确判断**：Capitalize / capitalize
- **判断依据**：正确答案是「Capitalize」，本课在「映射类型与模板字面量类型」中说明：模板字面量类型让字符串也具备类型约束，例如 type EventName = \on${Capitalize<string>}\，常用于事件名与 CSS 属性。本课还在「零基础详解：工具类型与类型组合」中说明：能用工具类型从实体派生出对外与创建用的类型。本课还在「声明文件」中说明：全局类型放 global.d.ts，通过 tsconfig 的 types/include 引入。
- **迁移检查**：不看题干，用自己的话补全这句话，再与标准答案对照。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「从类型中排除若干字段应使用？」的判断依据。
- [ ] 不看解析，能说出「把类型所有属性变为可选应使用？」的判断依据。
- [ ] 不看解析，能说出「.d.ts 文件的作用是？」的判断依据。
- [ ] 不看解析，能说出「Pick<T, K> 与 Omit<T, K> 的区别是？」的判断依据。
- [ ] 不看解析，能说出「Record<string, number> 表示？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「TypeScript 工具类型与声明文件」示例中，下面这行代码缺少哪…」的判断依据。
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
| `Partial<T>` | \| `Partial<T>` / `Required<T>` \| 全部可选 / 全部必填 \| |
| `Required<T>` | \| `Partial<T>` / `Required<T>` \| 全部可选 / 全部必填 \| |
| `Pick<T, K>` | \| `Pick<T, K>` / `Omit<T, K>` \| 挑选字段 / 排除字段 \| |
| `Omit<T, K>` | \| `Pick<T, K>` / `Omit<T, K>` \| 挑选字段 / 排除字段 \| |
| `Record<K, V>` | \| `Record<K, V>` \| 构造键值映射类型 \| |
| `Readonly<T>` | \| `Readonly<T>` \| 全部只读 \| |
| `ReturnType<F>` | \| `ReturnType<F>` / `Parameters<F>` \| 提取函数返回值 / 参数类型 \| |
| `Parameters<F>` | \| `ReturnType<F>` / `Parameters<F>` \| 提取函数返回值 / 参数类型 \| |
| `Awaited<T>` | \| `Awaited<T>` \| 提取 Promise 的结果类型 \| |
| `Exclude` | \| `Exclude` / `Extract` / `NonNullable` \| 联合类型的筛选 \| |
| `Extract` | \| `Exclude` / `Extract` / `NonNullable` \| 联合类型的筛选 \| |
| `NonNullable` | \| `Exclude` / `Extract` / `NonNullable` \| 联合类型的筛选 \| |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：从类型中排除若干字段应使用？

**参考回答**：Omit 用于隐藏敏感字段或裁剪 DTO。其他选项：Partial 让字段可选，Record 构造映射类型，Pick 是保留字段。针对「从类型中排除若干字段应使用，」，本课在「内置工具类型」中说明：这些工具类型在 API 层非常实用：创建请求 DTO 用 Pick，更新接口用 Partial，对外隐藏敏感字段用 Omit。本课还在「本课小结」中说明：工具类型让你从已有类型派生新类型，而不是重复声明。

### 追问 2：把类型所有属性变为可选应使用？

**参考回答**：Partial 常用于更新接口（PATCH）的请求体。其他选项：Readonly 让字段只读，Required 做相反操作，Exclude 作用于联合类型。针对「把类型所有属性变为可选应使用，」，本课在「内置工具类型」中说明：这些工具类型在 API 层非常实用：创建请求 DTO 用 Pick，更新接口用 Partial，对外隐藏敏感字段用 Omit。本课还在「映射类型与模板字面量类型」中说明：映射类型可以批量改造属性（如全部加 readonly、把值类型统一替换）。

### 追问 3：.d.ts 文件的作用是？

**参考回答**：正确答案是「为无类型的第三方库补充类型声明」，本课在「声明文件」中说明：.d.ts 为无类型的第三方库补类型：declare module 'legacy-lib' { export function run(x: string): void }。它让 JS 库也能获得类型提示与检查。本课还在「工程实践」中说明：用 type 定义联合与工具类型，interface 定义对象契约（可扩展、可合并）。

### 追问 4：Pick<T, K> 与 Omit<T, K> 的区别是？

**参考回答**：正确答案是「Pick 只保留 K 指定的字段」，本课在「零基础详解·工具类型与类型组合」中说明：能用工具类型从实体派生出对外与创建用的类型。对外暴露 DTO 时常用 Pick 选字段、Omit 去掉密码等敏感字段。本课还在「零基础详解·工具类型与类型组合」中说明：工具类型是 TypeScript 内置的「类型加工机」。本课还在「工程实践」中说明：用 type 定义联合与工具类型，interface 定义对象契约（可扩展、可合并）。

### 追问 5：Record<string, number> 表示？

**参考回答**：正确答案是「键为 string、值为 number 的对象类型」，本课在「本课小结」中说明：工具类型让你从已有类型派生新类型，而不是重复声明。Record 常用于描述映射表、字典与配置项集合。本课还在「映射类型与模板字面量类型」中说明：映射类型可以批量改造属性（如全部加 readonly、把值类型统一替换）。本课还在「零基础详解·工具类型与类型组合」中说明：工具类型是 TypeScript 内置的「类型加工机」。

## English Overview

**Title:** Utility Types & Declarations

**Summary:** Partial/Pick/Omit/Record, mapped types and .d.ts.

**Category:** TypeScript  
**Level:** 入门  
**Key terms:** TypeScript, 工具类型, 映射类型, 声明文件

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：入门
- 适用环境：TypeScript 5.x / Node.js 22+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：TypeScript、工具类型、映射类型、声明文件
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

> 本课主题：Partial/Pick/Omit/Record、映射类型与 .d.ts。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
