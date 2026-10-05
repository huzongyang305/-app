# TypeScript 进阶类型与框架实践

![TypeScript 进阶类型与框架实践](images/remaining_ts_decorators_pro.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「TypeScript 进阶类型与框架实践」解决了什么问题，而不是只背术语。
- 能说清 「TypeScript」、「装饰器」、「类型体操」、「React」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「TypeScript」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：装饰器、类型体操进阶与 React/Node 类型实践。

## 前置知识

- 先完成上一课《TypeScript 工程配置与实践》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：TypeScript、装饰器、类型体操。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 装饰器

装饰器是函数，用于在类、方法、属性、参数上附加行为：`@Component`、`@Injectable`、`@Get('/users')`。经典用途是依赖注入、路由注册与元数据标注。

注意：装饰器曾是实验特性（experimentalDecorators），TC39 标准装饰器语义不同。使用 Angular/NestJS 时按框架要求配置；新项目若不依赖框架，优先用高阶函数或组合替代。

## 类型体操进阶

| 技巧 | 用途 |
| --- | --- |
| 递归条件类型 | 深层 Readonly、路径类型、数组转联合 |
| 分布式条件类型 | 对联合类型逐项处理 |
| 模板字面量类型 | 生成事件名、CSS 属性、路由参数类型 |
| 协变/逆变位置 | 理解函数参数为何是逆变的 |

类型体操要克制：能表达业务约束即可，过度复杂的类型会拖慢编译并让团队难以维护。必要时写类型测试（tsd/expect-type）固定行为。

## React 类型实践

1. 组件 props 显式声明接口，避免 `React.FC`（隐式 children 已不推荐）。
2. 事件用 `React.ChangeEvent<HTMLInputElement>` 等内置类型，不要手写。
3. `useState` 泛型标注复杂状态；`useRef<HTMLDivElement>(null)` 明确可空。
4. 泛型组件：`function List<T>({ items, render }: Props<T>)`。
5. 严格模式下 `children: React.ReactNode`，不要用 `JSX.Element`。

## Node 类型实践

1. 安装 `@types/node`，注意 ESM/CJS 的模块解析差异（moduleResolution: node16）。
2. 环境变量用 zod 校验后再使用，避免 `process.env.X!` 满天飞。
3. Express/Fastify 的请求体校验同样在边界用 zod，类型交给推导。
4. 用 `NodeJS.Timeout` 标注定时器，避免与 DOM 类型冲突。

## 本课小结
TypeScript 进阶的边界是**可维护性**：装饰器与类型体操解决特定问题，框架集成靠内置类型与边界校验。


## 装饰器速查

| 类型 | 作用位置 | 典型用途 |
| --- | --- | --- |
| 类装饰器 | 类声明 | 注册、注入元数据 |
| 方法装饰器 | 方法 | 日志、缓存、权限校验 |
| 属性装饰器 | 属性 | 校验规则、序列化映射 |
| 参数装饰器 | 方法参数 | 依赖注入、参数校验 |
| 访问器装饰器 | getter / setter | 拦截读取与赋值 |

```ts
// 方法装饰器：记录耗时（标准装饰器语法）
function timed(
  target: unknown,
  context: ClassMethodDecoratorContext,
) {
  const name = String(context.name);
  return function (this: unknown, ...args: unknown[]) {
    const start = performance.now();
    try {
      return (this as Record<string, Function>)[name](...args);
    } finally {
      console.log(`${name} 耗时 ${(performance.now() - start).toFixed(1)}ms`);
    }
  };
}

class Service {
  @timed
  handle(id: string) {
    return `handled ${id}`;
  }
}
```

注意：TypeScript 有两套装饰器语义。旧版「实验性装饰器」需要 `experimentalDecorators: true`（NestJS、TypeORM 使用）；TC39 标准装饰器在新版 TS 中默认可用。两者不能混用，取决于框架要求。

## React 与类型速查

| 场景 | 写法 |
| --- | --- |
| 组件 props | `type Props = { id: string; onSelect?: (id: string) => void }` |
| 函数组件 | `function Card({ id }: Props) { ... }` |
| 子节点 | `children: React.ReactNode` |
| 事件处理 | `(e: React.ChangeEvent<HTMLInputElement>) => void` |
| 泛型组件 | `function List<T>({ items }: { items: T[] }) { ... }` |
| 状态 | `useState<User \| null>(null)` |
| Ref | `useRef<HTMLInputElement>(null)` |
| 上下文 | `createContext<Auth \| null>(null)` + 自定义 hook 校验 |

## 环境变量速查

| 场景 | 做法 |
| --- | --- |
| 前端读取 | 仅 `VITE_` 前缀会暴露给浏览器 |
| Node 读取 | `process.env.NODE_ENV`，缺省需判空 |
| 校验必填 | 启动时集中校验，缺失直接抛错 |
| 类型声明 | `declare global { namespace NodeJS { interface ProcessEnv { DATABASE_URL: string } } }` |
| 禁止 | 把密钥放前端环境变量（会被打包进产物） |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 装饰器两套语义混用 | 编译错误或行为异常 | 按框架要求统一开启或关闭 `experimentalDecorators` |
| 装饰器做重业务逻辑 | 行为隐蔽、难以调试 | 只做元数据与横切关注点 |
| props 类型用 `any` | 失去检查 | 明确字段类型，可选字段用 `?` |
| 可选 props 不设默认值 | 运行时 `undefined` 报错 | 用默认参数或判空 |
| 直接把 `process.env` 传给前端 | 值为 undefined | 用构建工具的注入机制 |
| 上下文类型不校验 | 忘记 Provider 导致运行时报错 | 自定义 hook 在为空时抛错 |
| 事件类型写 `any` | 失去自动补全 | 用 React 提供的具体事件类型 |
| 泛型组件写成 `any[]` | 丢失元素类型 | 用 `<T,>` 泛型语法 |
| 用装饰器替代依赖注入显式声明 | 依赖关系不可见 | 显式构造或框架标准写法 |
| 忘记给环境变量声明类型 | `Property 'X' does not exist` | 补 `ProcessEnv` 声明 |

## 自测清单

- [ ] 明确项目使用哪套装饰器语义，并统一配置。
- [ ] 组件 props 有明确类型，可选字段有默认处理。
- [ ] 上下文通过自定义 hook 读取并在缺失时报错。
- [ ] 环境变量在启动时校验，密钥绝不放前端。
- [ ] 装饰器只承载元数据与横切逻辑。


## 零基础详解：装饰器、运行时校验与工程实践

### 一句话说清它是什么

装饰器是「贴在类或方法上的元数据标签」，本身不干活，真正干活的是读取标签的框架。
而**运行时校验**解决类型系统管不到的那一半：接口返回的数据到底长什么样。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 装饰器 | 贴在箱子上的标签 | 只描述信息，不改变内容 |
| 框架 | 读标签的人 | 启动或请求时读取并执行 |
| 类型系统 | 编译期合同 | 运行时完全不存在 |
| 运行时校验 | 开箱验货 | 真的检查数据是否符合合同 |
| schema 优先 | 一份图纸两用 | 校验规则反推出类型 |

### 装饰器的三种写法

```typescript
// 1. 类装饰器
function Injectable(): ClassDecorator {
  return (target) => {
    Reflect.defineMetadata("injectable", true, target);
  };
}

// 2. 方法装饰器
function Log(): MethodDecorator {
  return (target, key, descriptor: PropertyDescriptor) => {
    const original = descriptor.value;
    descriptor.value = function (...args: unknown[]) {
      console.log(`调用 ${String(key)}`, args);
      return original.apply(this, args);
    };
  };
}

// 3. 参数装饰器
function Body(): ParameterDecorator {
  return (target, key, index) => {
    Reflect.defineMetadata("body", index, target, key!);
  };
}

@Injectable()
class UserService {
  @Log()
  find(@Body() id: number) {
    return { id };
  }
}
```

**注意**：传统装饰器需要 `experimentalDecorators: true`；新标准装饰器的语义不同，混用会踩坑。

### 什么时候该用装饰器

| 场景 | 适合用装饰器 | 建议 |
| --- | --- | --- |
| 声明路由 | ✅ | NestJS 风格，元数据驱动 |
| 依赖注入 | ✅ | 框架统一读取 |
| 参数校验 | ✅ | 需要配合校验库 |
| 简单日志 | ⚠️ | 显式包装函数更易调试 |
| 业务逻辑 | ❌ | 藏在装饰器里最难排查 |

### 运行时校验：类型管不到的地方

```typescript
import { z } from "zod";

const UserSchema = z.object({
  id: z.number().int().positive(),
  name: z.string().min(1).max(50),
  email: z.string().email().optional(),
  role: z.enum(["admin", "user"]).default("user"),
});

type User = z.infer<typeof UserSchema>;      // 类型由 schema 推导，永不漂移

function parseUser(input: unknown): User {
  return UserSchema.parse(input);             // 失败会抛 ZodError
}

// 安全解析：不抛异常，返回结果对象
const result = UserSchema.safeParse(payload);
if (!result.success) {
  console.error(result.error.issues);
} else {
  console.log(result.data.role);              // 已应用默认值
}
```

**好处**：一份 schema 同时提供运行时校验和静态类型，不会出现「类型写对了但数据不对」。

### 环境变量必须校验

```typescript
const EnvSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]),
  PORT: z.coerce.number().int().min(1).max(65535),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
});

export const env = EnvSchema.parse(process.env);
// 缺失或格式错误会在启动时立刻失败，而不是运行到一半才崩
```

### NestJS 里的四类装饰器

| 装饰器 | 挂在哪 | 作用 |
| --- | --- | --- |
| `@Controller("/users")` | 类 | 声明路由前缀 |
| `@Get(":id")` | 方法 | 声明 HTTP 方法与路径 |
| `@Injectable()` | 类 | 允许被依赖注入 |
| `@Body()` / `@Param()` | 参数 | 从请求中取值 |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 以为装饰器能做运行时类型检查 | 数据照样出错 | 用 zod 等显式校验 |
| 把业务逻辑写进装饰器 | 排查困难 | 只做横切关注点 |
| 忘记开 `experimentalDecorators` | 编译报错 | 按框架要求配置 |
| 装饰器执行顺序搞混 | 元数据被覆盖 | 记住：由下往上、由内往外 |
| 只校验入参不校验出参 | 脏数据流向下游 | 两端都校验 |
| 用 `as User` 代替校验 | 运行时崩溃 | 用 `parse` 或 `safeParse` |
| 环境变量直接用 `process.env.X!` | 缺失时静默出错 | 启动时统一校验 |
| 校验错误直接抛给用户 | 泄露内部结构 | 转成统一错误响应 |

### 手把手练习：带校验的创建接口

```typescript
import { z } from "zod";

const CreateUserSchema = z.object({
  name: z.string().min(1, "姓名不能为空"),
  email: z.string().email("邮箱格式不正确"),
  age: z.number().int().min(0).max(150).optional(),
});

type CreateUserInput = z.infer<typeof CreateUserSchema>;

function createUser(raw: unknown): { ok: true; data: CreateUserInput } | { ok: false; errors: string[] } {
  const parsed = CreateUserSchema.safeParse(raw);
  if (!parsed.success) {
    return {
      ok: false,
      errors: parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`),
    };
  }
  return { ok: true, data: parsed.data };
}

console.log(createUser({ name: "小明", email: "a@b.com" }));
console.log(createUser({ name: "", email: "bad" }));
```

### 学完自测

- [ ] 能说出装饰器与框架的分工。
- [ ] 知道传统装饰器需要哪个编译选项。
- [ ] 能解释为什么类型系统不能替代运行时校验。
- [ ] 能用 zod 推导出 TypeScript 类型。
- [ ] 知道环境变量应该在什么时候校验。

## 动手练习


> 本课练习重点：围绕「TypeScript、装饰器、类型体操」完成复述、实验和交付，每个结果都要能被别人检查。

先让类型检查通过，再制造一次类型错误，最后补运行时校验与测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「TypeScript 进阶类型与框架实践」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「装饰器」是什么关系？

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
- 至少覆盖「TypeScript」和「装饰器」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：关于装饰器，下面说法正确的是？

- **正确判断**：它是实验特性，标准装饰器语义不同
- **判断依据**：正确答案是「它是实验特性，标准装饰器语义不同」，本课在「装饰器」中说明：注意：装饰器曾是实验特性（experimentalDecorators），TC39 标准装饰器语义不同。Angular/NestJS 依赖 experimentalDecorators，新项目应优先用组合。本课还在「本课小结」中说明：TypeScript 进阶的边界是可维护性：装饰器与类型体操解决特定问题，框架集成靠内置类型与边界校验。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：React 组件 props 类型推荐的写法是？

- **正确判断**：显式声明 props 接口
- **判断依据**：正确答案是「显式声明 props 接口」，本课在「本课小结」中说明：TypeScript 进阶的边界是可维护性：装饰器与类型体操解决特定问题，框架集成靠内置类型与边界校验。React.FC 带隐式 children，已不推荐。本课还在「React 类型实践」中说明：组件 props 显式声明接口，避免 React.FC（隐式 children 已不推荐）。本课还在「类型体操进阶」中说明：类型体操要克制：能表达业务约束即可，过度复杂的类型会拖慢编译并让团队难以维护。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 3：Node 中读取环境变量的推荐做法是？

- **正确判断**：先用 zod 等校验再使用
- **判断依据**：正确答案是「先用 zod 等校验再使用」，本课在「Node 类型实践」中说明：环境变量用 zod 校验后再使用，避免 process.env.X! 满天飞。环境变量是外部输入，缺失或格式错误应在启动时就暴露。本课还在「类型体操进阶」中说明：类型体操要克制：能表达业务约束即可，过度复杂的类型会拖慢编译并让团队难以维护。本课还在「零基础详解：装饰器、运行时校验与工程实践」中说明：装饰器是「贴在类或方法上的元数据标签」，本身不干活，真正干活的是读取标签的框架。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 4：zod 与 class-validator 的差别是？

- **正确判断**：zod 是 schema 优先，可从校验规则反推类型
- **判断依据**：正确答案是「zod 是 schema 优先，可从校验规则反推类型」，本课在「装饰器」中说明：新项目若不依赖框架，优先用高阶函数或组合替代。zod 的 schema 可推导出静态类型，天然让运行时校验与类型定义保持一致。本课还在「零基础详解：装饰器、运行时校验与工程实践」中说明：好处：一份 schema 同时提供运行时校验和静态类型，不会出现「类型写对了但数据不对」。本课还在「装饰器」中说明：装饰器是函数，用于在类、方法、属性、参数上附加行为：@Component、@Injectable、@Get('/users')。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：NestJS 中装饰器主要承载什么职责？

- **正确判断**：声明式地标注路由
- **判断依据**：正确答案是「声明式地标注路由」，本课在「零基础详解：装饰器、运行时校验与工程实践」中说明：而运行时校验解决类型系统管不到的那一半：接口返回的数据到底长什么样。装饰器本质是元数据，真正的行为由框架在启动或请求时读取元数据后执行。本课还在「装饰器速查」中说明：注意：TypeScript 有两套装饰器语义。本课还在「装饰器速查」中说明：旧版「实验性装饰器」需要 experimentalDecorators: true（NestJS、TypeORM 使用）。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 6：补全代码：「TypeScript 进阶类型与框架实践」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `const result = UserSchema.____(payload);`

- **正确判断**：safeParse / safeparse
- **判断依据**：正确答案是「safeParse」，本课在「装饰器速查」中说明：TC39 标准装饰器在新版 TS 中默认可用。本课还在「零基础详解：装饰器、运行时校验与工程实践」中说明：注意：传统装饰器需要 experimentalDecorators: true。本课还在「装饰器」中说明：装饰器是函数，用于在类、方法、属性、参数上附加行为：@Component、@Injectable、@Get('/users')。
- **迁移检查**：把答案换成另一种等价写法，是否仍然正确？说明依据。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「关于装饰器，下面说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「React 组件 props 类型推荐的写法是？」的判断依据。
- [ ] 不看解析，能说出「Node 中读取环境变量的推荐做法是？」的判断依据。
- [ ] 不看解析，能说出「zod 与 class-validator 的差别是？」的判断依据。
- [ ] 不看解析，能说出「NestJS 中装饰器主要承载什么职责？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「TypeScript 进阶类型与框架实践」示例中，下面这行代码缺少哪…」的判断依据。
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
| `@Component` | 装饰器是函数，用于在类、方法、属性、参数上附加行为：`@Component`、`@Injectable`、`@Get('/users')`。经典用途是依赖注入、路由注册与元数据标注。 |
| `@Injectable` | 装饰器是函数，用于在类、方法、属性、参数上附加行为：`@Component`、`@Injectable`、`@Get('/users')`。经典用途是依赖注入、路由注册与元数据标注。 |
| `@Get('/users')` | 装饰器是函数，用于在类、方法、属性、参数上附加行为：`@Component`、`@Injectable`、`@Get('/users')`。经典用途是依赖注入、路由注册与元数据标注。 |
| `React.FC` | 组件 props 显式声明接口，避免 `React.FC`（隐式 children 已不推荐）。 |
| `React.ChangeEvent<HTMLInputElement>` | 事件用 `React.ChangeEvent<HTMLInputElement>` 等内置类型，不要手写。 |
| `useState` | `useState` 泛型标注复杂状态；`useRef<HTMLDivElement>(null)` 明确可空。 |
| `useRef<HTMLDivElement>(null)` | `useState` 泛型标注复杂状态；`useRef<HTMLDivElement>(null)` 明确可空。 |
| `children: React.ReactNode` | 严格模式下 `children: React.ReactNode`，不要用 `JSX.Element`。 |
| `JSX.Element` | 严格模式下 `children: React.ReactNode`，不要用 `JSX.Element`。 |
| `@types/node` | 安装 `@types/node`，注意 ESM/CJS 的模块解析差异（moduleResolution: node16）。 |
| `process.env.X!` | 环境变量用 zod 校验后再使用，避免 `process.env.X!` 满天飞。 |
| `NodeJS.Timeout` | 用 `NodeJS.Timeout` 标注定时器，避免与 DOM 类型冲突。 |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：关于装饰器，下面说法正确的是？

**参考回答**：正确答案是「它是实验特性，标准装饰器语义不同」，本课在「装饰器」中说明：注意：装饰器曾是实验特性（experimentalDecorators），TC39 标准装饰器语义不同。Angular/NestJS 依赖 experimentalDecorators，新项目应优先用组合。本课还在「本课小结」中说明：TypeScript 进阶的边界是可维护性：装饰器与类型体操解决特定问题，框架集成靠内置类型与边界校验。

### 追问 2：React 组件 props 类型推荐的写法是？

**参考回答**：正确答案是「显式声明 props 接口」，本课在「本课小结」中说明：TypeScript 进阶的边界是可维护性：装饰器与类型体操解决特定问题，框架集成靠内置类型与边界校验。React.FC 带隐式 children，已不推荐。本课还在「React 类型实践」中说明：组件 props 显式声明接口，避免 React.FC（隐式 children 已不推荐）。本课还在「类型体操进阶」中说明：类型体操要克制：能表达业务约束即可，过度复杂的类型会拖慢编译并让团队难以维护。

### 追问 3：Node 中读取环境变量的推荐做法是？

**参考回答**：正确答案是「先用 zod 等校验再使用」，本课在「Node 类型实践」中说明：环境变量用 zod 校验后再使用，避免 process.env.X! 满天飞。环境变量是外部输入，缺失或格式错误应在启动时就暴露。本课还在「类型体操进阶」中说明：类型体操要克制：能表达业务约束即可，过度复杂的类型会拖慢编译并让团队难以维护。本课还在「零基础详解·装饰器、运行时校验与工程实践」中说明：装饰器是「贴在类或方法上的元数据标签」，本身不干活，真正干活的是读取标签的框架。

### 追问 4：zod 与 class-validator 的差别是？

**参考回答**：正确答案是「zod 是 schema 优先，可从校验规则反推类型」，本课在「装饰器」中说明：新项目若不依赖框架，优先用高阶函数或组合替代。zod 的 schema 可推导出静态类型，天然让运行时校验与类型定义保持一致。本课还在「零基础详解·装饰器、运行时校验与工程实践」中说明：好处：一份 schema 同时提供运行时校验和静态类型，不会出现「类型写对了但数据不对」。本课还在「装饰器」中说明：装饰器是函数，用于在类、方法、属性、参数上附加行为：@Component、@Injectable、@Get('/users')。

### 追问 5：NestJS 中装饰器主要承载什么职责？

**参考回答**：正确答案是「声明式地标注路由」，本课在「零基础详解·装饰器、运行时校验与工程实践」中说明：而运行时校验解决类型系统管不到的那一半：接口返回的数据到底长什么样。装饰器本质是元数据，真正的行为由框架在启动或请求时读取元数据后执行。本课还在「装饰器速查」中说明：注意：TypeScript 有两套装饰器语义。本课还在「装饰器速查」中说明：旧版「实验性装饰器」需要 experimentalDecorators: true（NestJS、TypeORM 使用）。

## English Overview

**Title:** Decorators & Framework Types

**Summary:** Decorators, advanced types and framework typing.

**Category:** TypeScript  
**Level:** 进阶  
**Key terms:** TypeScript, 装饰器, 类型体操, React, Node

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：TypeScript 5.x / Node.js 22+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：TypeScript、装饰器、类型体操、React、Node
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

> 本课主题：装饰器、类型体操进阶与 React/Node 类型实践。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
