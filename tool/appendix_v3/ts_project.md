## 零基础详解：工程配置、构建与类型检查

### 一句话说清它是什么

TypeScript 项目有三件事必须分清：
**写代码时的类型检查**、**打包器负责的转译**、**CI 里的强制门禁**。
三者混在一起，就会出现「本地能跑、线上报错」。

### 用生活比喻理解

| 环节 | 比喻 | 说明 |
| --- | --- | --- |
| `tsc` | 质检员 | 只查类型，不做打包 |
| 打包器（Vite/esbuild） | 搬运工 | 只转译和合并，**不查类型** |
| CI | 出厂闸门 | 类型检查、测试、构建一起卡住 |
| `tsconfig.json` | 工艺标准 | 严格程度、目标版本、路径别名 |

### 一份可直接用的 tsconfig

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2022", "DOM"],
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noUnusedLocals": true,
    "exactOptionalPropertyTypes": true,
    "verbatimModuleSyntax": true,
    "skipLibCheck": true,
    "noEmit": true,
    "baseUrl": ".",
    "paths": { "@/*": ["src/*"] }
  },
  "include": ["src"]
}
```

| 选项 | 作用 |
| --- | --- |
| `strict` | 打开一组严格检查，新项目必开 |
| `noUncheckedIndexedAccess` | 数组或字典取值可能为 undefined |
| `noUnusedLocals` | 未使用的变量直接报错 |
| `verbatimModuleSyntax` | 明确区分类型导入与值导入 |
| `noEmit` | 只做类型检查，产物交给打包器 |
| `skipLibCheck` | 跳过第三方声明检查，提速 |

### 三条命令各管一段

```bash
tsc --noEmit          # 类型检查：CI 必跑
vite build            # 打包产物：不查类型
tsc --noEmit && vite build   # 组合成真正的发布前检查
```

**记住：Vite、esbuild、swc 都不会因为类型错误而中断构建。**

### 路径别名要同时配两处

```typescript
// tsconfig 里配 paths 只解决「类型解析」
import { api } from "@/lib/api";
```

```javascript
// vite.config.ts 里还要配别名，才能让打包器找到真实文件
import { fileURLToPath, URL } from "node:url";
import { defineConfig } from "vite";

export default defineConfig({
  resolve: {
    alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) },
  },
});
```

### CI 最小门禁

```yaml
- run: npm ci
- run: npx tsc --noEmit
- run: npm run lint
- run: npm test -- --run
- run: npm run build
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 以为打包会查类型 | 类型错误照样上线 | CI 单独跑 `tsc --noEmit` |
| 只配 tsconfig 别名 | 运行时找不到模块 | 打包器同步配置 |
| 关掉 `strict` | 空值错误频发 | 新项目一律开启 |
| 忽略 `noUncheckedIndexedAccess` | 数组取值可能 undefined | 开启并处理 |
| 类型与值混用导入 | 打包产物异常 | 用 `import type` |
| `skipLibCheck` 被误解 | 以为不检查自己的代码 | 它只跳过第三方声明 |
| 依赖版本不锁 | 别人装出来行为不同 | 提交 lockfile，CI 用 `npm ci` |
| 类型检查很慢 | 开发体验差 | 用项目引用与增量构建 |

### 手把手练习：加一个类型检查脚本

```json
{
  "scripts": {
    "typecheck": "tsc --noEmit",
    "build": "tsc --noEmit && vite build",
    "check": "npm run typecheck && npm run lint && npm test -- --run"
  }
}
```

把 `npm run check` 作为提交前与 CI 的统一入口，能避免「忘了跑某一项」。

### 学完自测

- [ ] 能说出 `tsc --noEmit` 与打包器各自负责什么。
- [ ] 知道路径别名为什么要在两处配置。
- [ ] 能说出 `strict` 与 `noUncheckedIndexedAccess` 的作用。
- [ ] 知道 CI 里最少要跑哪几条命令。
- [ ] 能解释为什么要提交 lockfile 并使用 `npm ci`。
