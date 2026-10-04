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
