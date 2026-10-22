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
