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

## 常见错误对照表

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

## 自测清单

- [ ] 能用可辨识联合替代「可选字段大杂烩」的接口设计。
- [ ] 外部数据先 `unknown`，再通过类型守卫收窄。
- [ ] 会用 `keyof` 与泛型约束写出类型安全的取值函数。
- [ ] 知道 `as` 不做运行时校验。
- [ ] 在 `switch` 里用 `never` 做穷尽检查。
