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
