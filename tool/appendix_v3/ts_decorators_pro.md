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
