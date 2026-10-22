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
