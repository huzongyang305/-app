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
