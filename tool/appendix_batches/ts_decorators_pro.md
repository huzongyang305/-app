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
