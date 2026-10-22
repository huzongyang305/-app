## 类型速查

| 类型 | 写法 | 说明 |
| --- | --- | --- |
| 原始类型 | `string`、`number`、`boolean`、`bigint`、`symbol` | 小写，不用包装类型 |
| 数组 | `string[]` 或 `Array<string>` | 推荐前者 |
| 元组 | `[string, number]` | 固定长度与顺序 |
| 联合 | `string \| number` | 值可以是其中之一 |
| 交叉 | `A & B` | 同时具备两组属性 |
| 字面量 | `"on" \| "off"` | 精确取值 |
| 对象 | `{ id: number; name?: string }` | `?` 表示可选 |
| 只读 | `readonly string[]`、`Readonly<T>` | 编译期禁止修改 |
| 索引签名 | `Record<string, number>` | 键值集合 |
| 可空 | `string \| null` | 开启 `strictNullChecks` 后必须显式处理 |
| 任意 | `any` | 关闭检查，尽量避免 |
| 未知 | `unknown` | 安全版 `any`，需收窄后使用 |
| 永远不返回 | `never` | 抛异常或死循环的返回值 |
| `void` | 无返回值 | 与 `undefined` 区分 |

## tsconfig 常用选项速查

| 选项 | 建议 | 作用 |
| --- | --- | --- |
| `strict` | `true` | 开启全部严格检查 |
| `target` | `ES2022` 起 | 输出语法版本 |
| `module` / `moduleResolution` | 按运行时选择 | 决定导入解析方式 |
| `noUncheckedIndexedAccess` | `true` | 下标访问结果可能是 `undefined` |
| `exactOptionalPropertyTypes` | 可选开启 | 更严格地区分「缺失」与 `undefined` |
| `noImplicitOverride` | `true` | 重写方法必须写 `override` |
| `skipLibCheck` | `true` | 跳过依赖类型检查，加速编译 |
| `noEmit` | CI 时 `true` | 只做类型检查 |
| `paths` | 按需 | 路径别名，打包器需同步配置 |
| `declaration` | 库项目 `true` | 生成 `.d.ts` |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `Object` 或 `{}` 当类型 | 几乎不报错，失去检查意义 | 用具体接口或 `Record<string, unknown>` |
| 到处 `as any` | 错误延后到运行时 | 收窄类型或补类型定义 |
| `arr[i]` 直接当非空 | 运行时可能 `undefined` | 开启 `noUncheckedIndexedAccess` 并判空 |
| `interface` 里定义函数属性写 `method(): void` 与 `method: () => void` 混用 | 类型兼容差异导致困惑 | 明确语义，团队内统一风格 |
| 用 `enum` 与字符串字面量混用 | 运行时行为不一致 | 简单场景直接用字面量联合 |
| `JSON.parse` 结果直接断言类型 | 字段不存在时报错 | 运行时校验（zod 等） |
| `const` 声明的对象属性被改 | 意料之外的状态变化 | 用 `as const` 或 `Object.freeze` |
| 回调里用普通函数访问 `this` | `this` 指向丢失 | 用箭头函数或显式绑定 |
| 导入类型用了值导入 | 打包体积变大 | 用 `import type { Foo } from "..."` |
| 忽略 `strictNullChecks` 报错 | 线上 `Cannot read properties of undefined` | 显式处理 `null` / `undefined` |

## 自测清单

- [ ] 新项目一律开启 `strict`。
- [ ] 用字面量联合替代不必要的枚举。
- [ ] 外部数据先 `unknown` 再校验，不直接断言。
- [ ] 用 `import type` 导入纯类型。
- [ ] CI 中单独执行 `tsc --noEmit` 做类型门禁。
