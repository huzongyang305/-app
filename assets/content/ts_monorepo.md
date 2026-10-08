# Monorepo 工程实践

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：50 分钟

![Monorepo 的包结构与依赖方向](images/diagram_ts_monorepo.webp)

![Monorepo 工程实践](images/remaining_ts_monorepo.webp)

## 本节知识框架

**课程定位**：所属分类为「TypeScript」，课程主题为「Monorepo 工程实践」，学习阶段为「进阶」，建议用时 50 分钟。

**本课要解决的主问题**：workspace 依赖方向、任务缓存与版本发布流程。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「Monorepo 工程实践」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「Monorepo 工程实践」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「Monorepo」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《TypeScript Node 后端开发》

**学习位置**：本课位于《TypeScript Node 后端开发》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《TypeScript 测试策略》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释Monorepo 工程实践解决了什么问题，而不是只背术语。
- 能说清 「Monorepo」、「pnpm」、「Turborepo」、「Changesets」 之间的关系，并分别举出一个例子。
- 能把 Monorepo 放回「Monorepo 工程实践」的知识体系，说明它和 pnpm 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：workspace 依赖方向、任务缓存与版本发布流程。

**教材衔接：前置知识**

- 先完成上一课《TypeScript Node 后端开发》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「TypeScript Node 后端开发」，或确认自己能独立跑通正文里的 packageManager 示例。
- 开始前先复习：Monorepo、pnpm、Turborepo。
- 如果 工具选型速查 这一步看不懂，先记录具体卡点，再用 packageManager 复现一遍。

**教材衔接：本课小结**

- 核心问题：Monorepo 工程实践不是孤立术语，而是在「TypeScript」中解决一类具体问题。
- 关键关系：先分清「Monorepo」与「pnpm」的职责，再理解「Turborepo」的适用边界。
- 判断标准：能解释 Monorepo 的正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：先复述 pnpm 的边界，再开始本课测验。

## 核心概念定义

> 阅读约定：本课先给「Monorepo 工程实践」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| Monorepo | Monorepo 是「把多个包放进同一个仓库」的组织方式。 | 仅在「Monorepo 工程实践」明确给出的输入、版本与资源条件下成立。 |
| 缓存 | 把计算或读取结果暂存到更快存储，后续请求直接复用。 | 仅在「Monorepo 工程实践」明确给出的输入、版本与资源条件下成立。 |
| 工作区 | monorepo 里用 workspaces 声明各个包，包之间用包名互相引用，由统一工具链解析与构建。 | 仅在「Monorepo 工程实践」明确给出的输入、版本与资源条件下成立。 |
| 任务编排 | 用 Turborepo 或 Nx 描述任务之间的依赖与缓存，只重建受影响的包。 | 仅在「Monorepo 工程实践」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「Monorepo 工程实践」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「Monorepo」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「缓存」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「工作区」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「Monorepo 工程实践」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | Monorepo | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | 缓存 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 工作区 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「Monorepo 工程实践」自己的示例验证。「Monorepo 工程实践」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：工具选型速查**

| 工具 | 定位 | 特点 |
| --- | --- | --- |
| pnpm workspace | 包管理与链接 | 硬链接节省磁盘，workspace 协议清晰 |
| Turborepo | 任务编排与缓存 | 声明式 pipeline，远程缓存 |
| Nx | 全功能工作区 | 依赖图、代码生成、插件丰富 |
| Changesets | 版本与发布 | 变更记录生成版本号与 CHANGELOG |

最小可用组合：**pnpm workspace（链接）+ Turborepo（任务与缓存）+ Changesets（发布）**。

**教材衔接：关键收益与风险**

| 收益 | 说明 |
| --- | --- |
| 原子提交 | 一次 PR 同时改共享包与使用方 |
| 统一工具链 | lint、测试、构建配置集中 |
| 缓存复用 | 只重建受影响的包 |
| 类型共享 | 前后端共用 schema，减少漂移 |

| 风险 | 对策 |
| --- | --- |
| 仓库变大、克隆慢 | 浅克隆、稀疏检出、CI 用远程缓存 |
| 依赖方向失控 | 用工具检查依赖图与循环 |
| 一次改动影响多个应用 | 明确 CODEOWNERS 与影响面检查 |
| 本地全量构建慢 | 用受影响范围构建（`--filter`） |

**教材衔接：版本与时效**

- 版本提示：Monorepo 的行为在最近几个大版本里有过调整，升级「Monorepo 工程实践」前先用 packageManager 复现当前输出，再对照官方发布说明逐条核对。
- 升级「Monorepo 工程实践」涉及的依赖前，先用 packageManager 复现当前行为，再逐项核对版本说明与破坏性变更。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改 Monorepo 的版本变量，记录编译、测试与产物体积的变化。
- 先回归 Monorepo 与 pnpm 的默认行为和错误信息，再扩大测试范围。
- 升级后把 packageManager 的实测版本写进「内容元数据」，再更新复核日期。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 Monorepo、pnpm | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「Monorepo 工程实践」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「Monorepo 工程实践」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:typescript`，用于动手验证《Monorepo 工程实践》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《Monorepo 工程实践》原文中的最小示例。先预测《Monorepo 工程实践》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```json
{
  "name": "my-workspace",
  "private": true,
  "packageManager": "pnpm@9.0.0",
  "scripts": {
    "build": "turbo run build",
    "test": "turbo run test",
    "lint": "turbo run lint",
    "typecheck": "turbo run typecheck",
    "changeset": "changeset",
    "release": "changeset publish"
  },
  "devDependencies": {
    "turbo": "^2.0.0",
    "@changesets/cli": "^2.27.0"
  }
}
```

**教材衔接：目录与依赖约定**

| 目录 | 职责 | 约束 |
| --- | --- | --- |
| `apps/` | 可部署应用 | 可以依赖 packages |
| `packages/` | 共享库与组件 | 不依赖 apps，避免循环 |
| `tooling/` | 构建配置与脚本 | 被所有包复用 |
| `packages/shared` | 类型与 schema | 前后端共享事实来源 |

规则：**依赖方向单向，apps 依赖 packages，packages 之间不得循环依赖。**

```json
{
  "name": "my-workspace",
  "private": true,
  "packageManager": "pnpm@9.0.0",
  "scripts": {
    "build": "turbo run build",
    "test": "turbo run test",
    "lint": "turbo run lint",
    "typecheck": "turbo run typecheck",
    "changeset": "changeset",
    "release": "changeset publish"
  },
  "devDependencies": {
    "turbo": "^2.0.0",
    "@changesets/cli": "^2.27.0"
  }
}
```

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**"]
    },
    "test": {
      "dependsOn": ["build"],
      "inputs": ["src/**", "tests/**", "vitest.config.*"]
    },
    "lint": {},
    "typecheck": {
      "dependsOn": ["^build"]
    }
  }
}
```

**教材衔接：零基础详解：Monorepo 与多包协作**

### 一句话说清它是什么

Monorepo 是「把多个包放进同一个仓库」的组织方式。
好处是跨包改动一次提交完成、类型即时联动；代价是**构建与 CI 必须做增量**，否则会越来越慢。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| workspace | 一栋楼里的多个房间 | 同仓库管理多个包 |
| 内部依赖 | 隔壁借东西 | 用 workspace 协议而不是发布到 npm |
| 任务编排 | 施工排期 | 按依赖顺序构建 |
| 受影响分析 | 只修坏掉的那几间 | 只跑相关任务 |
| 缓存 | 复用上次成果 | 没变就不重跑 |

### 什么时候该用 Monorepo

| 场景 | 建议 |
| --- | --- |
| 前后端共享类型定义 | ✅ 收益明显 |
| 多个包需要同步发版 | ✅ 一次提交改完 |
| 只有一个应用 | ❌ 直接单包更简单 |
| 团队完全独立、几乎不共享代码 | ❌ 拆分仓库更合适 |

### 目录结构

```text
repo/
  apps/
    web/                 前端应用
    api/                 后端服务
  packages/
    ui/                  共享组件
    types/               共享类型
    config/              共享配置（eslint、tsconfig）
  pnpm-workspace.yaml
  turbo.json
  package.json
```

### 两个关键配置文件

```yaml
# pnpm-workspace.yaml
packages:
  - "apps/*"
  - "packages/*"
```

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**"]
    },
    "typecheck": { "dependsOn": ["^build"] },
    "test": { "dependsOn": ["build"], "outputs": ["coverage/**"] },
    "lint": {}
  }
}
```

| 配置 | 作用 |
| --- | --- |
| `dependsOn: ["^build"]` | 先构建依赖的包 |
| `outputs` | 声明产物路径，用于缓存 |
| 根 `package.json` 脚本 | 用 `turbo run build` 一键跑全部 |

### 内部依赖怎么写

```json
// packages/ui/package.json
{
  "name": "@myapp/ui",
  "version": "0.0.0",
  "private": true,
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": { "types": "./dist/index.d.ts", "import": "./dist/index.js" }
  }
}
```

```json
// apps/web/package.json
{
  "dependencies": {
    "@myapp/ui": "workspace:*"
  }
}
```

`workspace:*` 让本地包直接链接，不用先发布到 npm。

### CI 里只跑受影响的包

```yaml
- run: pnpm install --frozen-lockfile
- run: pnpm turbo run lint typecheck test build --filter='...[origin/main]'
```

| 过滤写法 | 含义 |
| --- | --- |
| `--filter=web` | 只跑 web 包 |
| `--filter='...[origin/main]'` | 只跑相对 main 有变化的包及其依赖者 |
| `--filter=@myapp/ui...` | ui 包及其依赖 |
| `--filter=...^build` | 只跑构建任务 |

### 三个必须守住的约定

```text
1. 每个包自己声明依赖，不靠「根目录恰好装了」这种巧合
2. 共享配置抽成 @myapp/config，各处 extends 它，避免规则漂移
3. 内部包设为 private，避免误发布到公共仓库
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 依赖靠提升「碰巧能用」 | 别人机器上装不起来 | 每个包显式声明依赖 |
| 忘记声明 outputs | 缓存失效，每次都重跑 | 在 turbo.json 写清产物 |
| 全量跑 CI | 一小时起步 | 用 `--filter` 只跑受影响 |
| 用 `*` 版本引用内部包 | 装到旧的远端版本 | 用 `workspace:*` |
| 内部包被误发布 | 公开仓库出现私有代码 | 加 `"private": true` |
| 循环依赖 | 构建顺序无法确定 | 拆出公共包打破环 |
| tsconfig 各写一套 | 类型行为不一致 | 抽共享配置 |
| lockfile 未提交 | 版本不一致 | 提交并 CI 用 frozen-lockfile |

### 手把手练习：加一个共享类型包

```json
// packages/types/package.json
{
  "name": "@myapp/types",
  "version": "0.0.0",
  "private": true,
  "types": "./src/index.ts",
  "exports": { ".": "./src/index.ts" }
}
```

```typescript
// packages/types/src/index.ts
export type User = {
  id: number;
  name: string;
  email?: string;
};

export type ApiResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: string };
```

```typescript
// apps/api/src/handler.ts
import type { ApiResult, User } from "@myapp/types";

export function getUser(id: number): ApiResult<User> {
  if (id <= 0) return { ok: false, error: "id 不合法" };
  return { ok: true, data: { id, name: "小明" } };
}
```

```bash
pnpm install
pnpm turbo run typecheck --filter='...[origin/main]'
```

### 学完自测

- [ ] 能说出 Monorepo 的两个收益与两个代价。
- [ ] 知道 `workspace:*` 解决什么问题。
- [ ] 能说出 `dependsOn: ["^build"]` 的含义。
- [ ] 知道 CI 为什么要用 `--filter=...[origin/main]`。
- [ ] 能说出内部包必须加 `private` 的原因。

## 时间/空间复杂度或性能分析

**复杂度证据**：「Monorepo 工程实践」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「Monorepo 工程实践」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「Monorepo 工程实践」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《Monorepo 工程实践》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「Monorepo 工程实践」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 包之间互相依赖 | 循环依赖、构建顺序混乱 | 单向依赖，公共逻辑下沉 |
| 不使用 workspace 协议 | 误装发布版而非本地包 | 用 `workspace:*` |
| CI 每次都全量构建 | 流水线很慢 | 依赖图加缓存，只构建受影响包 |
| 共享包直接发布到 npm | 版本与内部状态不同步 | 私有包不发布或用 changesets 管理 |
| 本地用 `npm install` | lock 文件冲突 | 统一包管理器并用 `--frozen-lockfile` |
| 没有影响面检查 | 改共享包导致多个应用故障 | CI 跑下游测试并在 PR 标注影响面 |

**教材衔接：故障现场**

### 现场 1：包之间互相依赖

**症状**：在《Monorepo 工程实践》的复现场景中，循环依赖、构建顺序混乱。

**根因**：当出现“包之间互相依赖”时，执行路径已经绕过了《Monorepo 工程实践》的关键约束，最终以“循环依赖、构建顺序混乱”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《Monorepo 工程实践》的问题，单向依赖，公共逻辑下沉。

**验证**：在《Monorepo 工程实践》中按“单向依赖，公共逻辑下沉”调整后，从“包之间互相依赖”的触发条件重放同一条路径，确认“循环依赖、构建顺序混乱”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：不使用 workspace 协议

**症状**：在《Monorepo 工程实践》的复现场景中，误装发布版而非本地包。

**根因**：触发点是把“不使用 workspace 协议”当成安全做法。它没有满足《Monorepo 工程实践》要求的前提，因此先表现为“误装发布版而非本地包”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Monorepo 工程实践》的问题，用 workspace:*。

**验证**：在《Monorepo 工程实践》中按“用 workspace:*”调整后，从“不使用 workspace 协议”的触发条件重放同一条路径，确认“误装发布版而非本地包”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 3：共享包直接发布到 npm

**症状**：在《Monorepo 工程实践》的复现场景中，版本与内部状态不同步。

**根因**：“版本与内部状态不同步”只是表层结果。向上追溯会落到“共享包直接发布到 npm”这一步，因为它省略了《Monorepo 工程实践》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《Monorepo 工程实践》的问题，私有包不发布或用 changesets 管理。

**验证**：保留《Monorepo 工程实践》里触发“版本与内部状态不同步”的输入、版本和日志，按“私有包不发布或用 changesets 管理”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《TypeScript Node 后端开发》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《TypeScript 测试策略》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《TypeScript Node 后端开发》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《TypeScript 测试策略》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「Monorepo 工程实践」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《Monorepo 工程实践》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

下面这段 TypeScript 代码摘自「Monorepo 工程实践」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？

```typescript
// packages/types/src/index.ts
export type User = {
  id: number;
  name: string;
  email?: string;
};

export type ApiResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: string };
```

A. 这段代码会产生可观察的输出，运行后能看到结果。
B. 这段代码只做静态声明，没有循环、分支或可观察输出。
C. 这段代码包含异常处理分支，失败时会走专门的补救路径。
D. 这段代码会读取外部输入，结果依赖传入的数据。

**参考答案**：这段代码只做静态声明，没有循环、分支或可观察输出。

**解析**：在「Monorepo 工程实践」里，这段代码只做静态声明，没有循环、分支或可观察输出。这段代码出自「Monorepo 工程实践」的正文示例，围绕Monorepo、pnpm、Turborepo展开；把输入或边界换成空值、极值或失败情况后，结论要以「Monorepo 工程实践」的实际运行结果为准。

### 自测 2

围绕“Monorepo 工程实践”中的 Monorepo、pnpm、Turborepo，下列哪两项是本课强调的实践判断？

A. 把 pnpm 的单次运行结果当成所有版本和规模都成立
B. 学习 Monorepo 时要同时说明输入、输出和失败路径，不能只看正常流程
C. 只要 Monorepo 的常规示例通过，就可以跳过边界与异常路径
D. 验证 pnpm 时要固定版本并覆盖边界输入，结论才可复现

**参考答案**：学习 Monorepo 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 pnpm 时要固定版本并覆盖边界输入，结论才可复现

**解析**：本课把Monorepo 工程实践拆成概念、示例与故障现场三部分，因此判断 Monorepo 时必须同时交代输入、输出和失败路径，这使“学习 Monorepo 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Monorepo 工程实践里，判断 pnpm 时要固定版本与边界输入，所以“验证 pnpm 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 3

CI 中让流水线更快的关键做法是？

A. 每次全量构建所有包，但这会拖慢构建速度
B. 基于依赖图与缓存只跑受影响的任务
C. 关闭测试
D. 减少包数量

**参考答案**：基于依赖图与缓存只跑受影响的任务

**解析**：在「Monorepo 工程实践」里，基于依赖图与缓存只跑受影响的任务。任务编排工具根据输入哈希与依赖图跳过未变化的任务，并复用远程缓存。把“基于依赖图与缓存只跑受影响的任务”代回「Monorepo 工程实践」里“CI 中让流水线更快的关键做法是”的例子核对，条件一旦改变，结论就要用Monorepo、pnpm、Turborepo重新推导。

**教材衔接：复习与自测**

- [ ] 依赖单向：apps 依赖 packages，无循环。
- [ ] 统一包管理器与 lock 文件，CI 使用冻结安装。
- [ ] 用任务编排工具缓存构建产物，只跑受影响任务。
- [ ] 版本与发布由 changesets 管理。
- [ ] 共享包变更会触发下游应用测试。

**教材衔接：动手练习**

> 本课练习重点：围绕「Monorepo、pnpm、Turborepo」完成复述、实验和交付，每个结果都要能被别人检查。

为 packageManager 写出类型签名，然后故意传错一个参数观察编译器报错。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Monorepo 工程实践解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「pnpm」是什么关系？

验收标准：说明 Monorepo 与 pnpm 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：围绕「工具选型速查」小节做一次五步记录，原例取自 packageManager，改动只允许动一处Monorepo，原因要能指回正文的判断依据。

### 练习 3：交付一个小结果（30 分钟）

写一个只包含 Monorepo 的最小程序，先验证正常路径，再制造一次失败。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Monorepo」和「pnpm」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```typescript
// packages/types/src/index.ts
export type User = {
  id: number;
  name: string;
  email?: string;
};

export type ApiResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: string };
```

### 任务 2：只改一个条件

把「Monorepo 工程实践」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 pnpm 换成边界值，其他输入保持原样。
- 预测：先写下「Monorepo 工程实践」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响Monorepo。

### 任务 3：迁移到自己的数据

把 packageManager 换成你自己的输入，先保持步骤不变，再比较输出差异。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Monorepo 中正确的依赖方向是？」的判断依据。
- [ ] 不看解析，能说出「为了引用本地包而不是已发布版本，应该使用？」的判断依据。
- [ ] 不看解析，能说出「CI 中让流水线更快的关键做法是？」的判断依据。
- [ ] 不看解析，能说出「共享包变更后，最需要做什么？」的判断依据。
- [ ] 不看解析，能说出「Monorepo 的主要风险是？」的判断依据。
- [ ] 跑通「Monorepo 工程实践」的最小示例，并记录一次失败输入的处理方式。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `Monorepo` | Monorepo 是「把多个包放进同一个仓库」的组织方式。 |
| `缓存` | 把计算或读取结果暂存到更快存储，后续请求直接复用。 |
| `工作区` | monorepo 里用 workspaces 声明各个包，包之间用包名互相引用，由统一工具链解析与构建。 |
| `任务编排` | 用 Turborepo 或 Nx 描述任务之间的依赖与缓存，只重建受影响的包。 |

## 考点精讲

### 考点 1：代码补全·Monorepo

- **题目**：下面这段 TypeScript 代码摘自「Monorepo 工程实践」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？
- **判断依据**：在「Monorepo 工程实践」里，这段代码只做静态声明，没有循环、分支或可观察输出。这段代码出自「Monorepo 工程实践」的正文示例，围绕Monorepo、pnpm、Turborepo展开；把输入或边界换成空值、极值或失败情况后，结论要以「Monorepo 工程实践」的实际运行结果为准。

### 考点 2：多选辨析·Monorepo

- **题目**：围绕“Monorepo 工程实践”中的 Monorepo、pnpm、Turborepo，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把Monorepo 工程实践拆成概念、示例与故障现场三部分，因此判断 Monorepo 时必须同时交代输入、输出和失败路径，这使“学习 Monorepo 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Monorepo 工程实践里，判断 pnpm 时要固定版本与边界输入，所以“验证 pnpm 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 3：概念判断·Monorepo

- **题目**：CI 中让流水线更快的关键做法是？
- **判断依据**：在「Monorepo 工程实践」里，基于依赖图与缓存只跑受影响的任务。任务编排工具根据输入哈希与依赖图跳过未变化的任务，并复用远程缓存。把“基于依赖图与缓存只跑受影响的任务”代回「Monorepo 工程实践」里“CI 中让流水线更快的关键做法是”的例子核对，条件一旦改变，结论就要用Monorepo、pnpm、Turborepo重新推导。

### 考点 4：概念判断·Monorepo

- **题目**：共享包变更后，最需要做什么？
- **判断依据**：在「Monorepo 工程实践」里，结论应落在「触发下游应用的测试并标注影响面」。共享包变更影响面大，CI 需要跑下游测试并让评审者看到影响范围。在「Monorepo 工程实践」里，这道题要求区分概念与边界，「触发下游应用的测试并标注影响面」只有在题干给出的前提下才成立，而「等上线后观察」、「直接发布到 npm，但这会让包体更大」缺少同一组条件。

### 考点 5：概念判断·Monorepo

- **题目**：Monorepo 的主要风险是？
- **判断依据**：在「Monorepo 工程实践」里，仓库变大，依赖方向易失控。这些是 Monorepo 的典型代价，需要通过依赖约束、受影响范围构建与 CODEOWNERS 缓解。这道题的关键在「Monorepo 工程实践」的Monorepo、pnpm、Turborepo：先确认题干“Monorepo 的主要风险是”问的是哪一步，再排除偷换前提的选项。

### 考点 6：填空·pnpm-____.yaml

- **题目**：补全代码：「Monorepo 工程实践」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `pnpm-____.yaml`
- **判断依据**：把“workspace”代回「Monorepo 工程实践」里“Monorepo 工程实践示例中”的例子核对，条件一旦改变，结论就要用Monorepo、pnpm、Turborepo重新推导。「Monorepo 工程实践」要求先交代Monorepo、pnpm、Turborepo的前提再下结论，所以“workspace”只在题干“Monorepo”给定的条件下成立。

## English Overview

**Title:** Monorepo Engineering

**Summary:** Workspace dependency rules, task caching and releases.

**Category:** TypeScript
**Level:** 进阶
**Key terms:** Monorepo, pnpm, Turborepo, Changesets, 依赖图, 缓存

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：TypeScript 5.x / Node.js 22+
；本课聚焦 Monorepo。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Monorepo、pnpm、Turborepo、Changesets、依赖图、缓存
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-03-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [项目引用](https://www.typescriptlang.org/docs/handbook/project-references.html) | 大型项目拆分与增量构建 |
| [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) | 类型系统与语言指南 |
| [Everyday Types](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html) | 常用类型与收窄 |

> 「Monorepo 工程实践」的链接用于离线阅读后的延伸核对；App 不会自动联网。
