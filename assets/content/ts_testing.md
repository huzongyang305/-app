# TypeScript 测试策略

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：50 分钟

![Vitest、Testing Library 与 MSW 的组合](images/diagram_ts_testing.webp)

![TypeScript 测试策略](images/remaining_ts_testing.webp)

## 本节知识框架

**课程定位**：所属分类为「TypeScript」，课程主题为「TypeScript 测试策略」，学习阶段为「进阶」，建议用时 50 分钟。

**本课要解决的主问题**：Vitest、Testing Library 与 MSW 的组合用法。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「TypeScript 测试策略」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「TypeScript 测试策略」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「Vitest」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《Monorepo 工程实践》

**学习位置**：本课位于《Monorepo 工程实践》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《TypeScript 实战：全栈类型安全》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释TypeScript 测试策略解决了什么问题，而不是只背术语。
- 能说清 「Vitest」、「TestingLibrary」、「MSW」、「组件测试」 之间的关系，并分别举出一个例子。
- 能把 Vitest 放回「TypeScript 测试策略」的知识体系，说明它和 TestingLibrary 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：Vitest、Testing Library 与 MSW 的组合用法。

**教材衔接：前置知识**

- 先完成上一课《Monorepo 工程实践》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「Monorepo 工程实践」，或确认自己能独立跑通正文里的 onUnhandledRequest 示例。
- 开始前先复习：Vitest、TestingLibrary、MSW。
- 如果 工具选型速查 这一步看不懂，先记录具体卡点，再用 onUnhandledRequest 复现一遍。

**教材衔接：本课小结**

- 核心问题：TypeScript 测试策略不是孤立术语，而是在「TypeScript」中解决一类具体问题。
- 关键关系：先分清「Vitest」与「TestingLibrary」的职责，再理解「MSW」的适用边界。
- 判断标准：能说清 onUnhandledRequest 在正常与异常输入下的差别。
- 下一步：把 onUnhandledRequest 的实验结论记成三句话，然后进入测验。

## 核心概念定义

> 阅读约定：本课先给「TypeScript 测试策略」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| 覆盖率 | 测试执行到的代码、分支或需求占总量的比例。 | 仅在「TypeScript 测试策略」明确给出的输入、版本与资源条件下成立。 |
| Mock | 测试替身：模拟外部依赖或慢操作，只在边界使用，避免把内部实现也一起 mock。 | 仅在「TypeScript 测试策略」明确给出的输入、版本与资源条件下成立。 |
| 单元测试边界 | 优先覆盖空值、越界与错误分支，只测正常路径的覆盖率没有意义。 | 仅在「TypeScript 测试策略」明确给出的输入、版本与资源条件下成立。 |
| 快照测试 | 把输出与基线快照比对，适合稳定的结构化输出，更新快照必须经过评审。 | 仅在「TypeScript 测试策略」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「TypeScript 测试策略」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「覆盖率」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「Mock」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「单元测试边界」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「TypeScript 测试策略」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | 覆盖率 | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | Mock | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 单元测试边界 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「TypeScript 测试策略」自己的示例验证。「TypeScript 测试策略」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：工具选型速查**

| 需求 | 工具 | 说明 |
| --- | --- | --- |
| 单元测试 | Vitest | 快、与 Vite 共享配置 |
| 组件测试 | Testing Library | 面向用户行为断言 |
| 接口模拟 | MSW | 在网络层拦截，前后端一致 |
| 端到端 | Playwright | 多浏览器与自动等待 |
| 属性测试 | fast-check | 自动生成边界输入 |
| 覆盖率 | c8 / istanbul | 关注未覆盖分支 |

**教材衔接：版本与时效**

- 版本提示：Vitest 的行为在最近几个大版本里有过调整，升级「TypeScript 测试策略」前先用 onUnhandledRequest 复现当前输出，再对照官方发布说明逐条核对。
- 升级前先用 onUnhandledRequest 建立基线：记录版本、命令和输出，升级后只比较这些可观察量。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改 Vitest 的版本变量，记录编译、测试与产物体积的变化。
- 升级后重点回归 Vitest 的默认值、警告信息与错误格式。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 Vitest 的版本变化。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 Vitest、TestingLibrary | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「TypeScript 测试策略」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「TypeScript 测试策略」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:typescript`，用于动手验证《TypeScript 测试策略》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《TypeScript 测试策略》原文中的最小示例。先预测《TypeScript 测试策略》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```ts
import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, userEvent } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { setupServer } from "msw/node";

// 用 MSW 在 HTTP 层模拟接口，测试代码不感知网络细节
const server = setupServer(
  http.get("/api/lessons", () =>
    HttpResponse.json([{ id: "1", title: "Python 基础" }]),
  ),
);

beforeEach(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe("LessonList", () => {
  it("加载后展示课程标题", async () => {
    render(<LessonList />);
    // 断言用户可见的结果，而不是内部实现
    expect(await screen.findByText("Python 基础")).toBeInTheDocument();
  });

  it("接口失败时展示错误提示", async () => {
    server.use(
      http.get("/api/lessons", () => HttpResponse.json({}, { status: 500 })),
    );
    render(<LessonList />);
    expect(await screen.findByRole("alert")).toHaveTextContent("加载失败");
  });
});

// 纯函数测试：边界与错误输入优先
describe("parseAmount", () => {
  it.each([
    ["100", 100],
    [" 42 ", 42],
  ])("解析 %s", (input, expected) => {
    expect(parseAmount(input)).toBe(expected);
  });

  it("非法输入抛错", () => {
    expect(() => parseAmount("abc")).toThrowError(/无效金额/);
  });
});
```

**教材衔接：测试层级与比例**

| 层级 | 比例建议 | 关注点 |
| --- | --- | --- |
| 单元 | 约 70% | 纯函数、边界与错误分支 |
| 集成 | 约 20% | 模块协作、数据访问、接口 |
| 端到端 | 约 10% | 核心用户旅程 |

```ts
import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, userEvent } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { setupServer } from "msw/node";

// 用 MSW 在 HTTP 层模拟接口，测试代码不感知网络细节
const server = setupServer(
  http.get("/api/lessons", () =>
    HttpResponse.json([{ id: "1", title: "Python 基础" }]),
  ),
);

beforeEach(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

describe("LessonList", () => {
  it("加载后展示课程标题", async () => {
    render(<LessonList />);
    // 断言用户可见的结果，而不是内部实现
    expect(await screen.findByText("Python 基础")).toBeInTheDocument();
  });

  it("接口失败时展示错误提示", async () => {
    server.use(
      http.get("/api/lessons", () => HttpResponse.json({}, { status: 500 })),
    );
    render(<LessonList />);
    expect(await screen.findByRole("alert")).toHaveTextContent("加载失败");
  });
});

// 纯函数测试：边界与错误输入优先
describe("parseAmount", () => {
  it.each([
    ["100", 100],
    [" 42 ", 42],
  ])("解析 %s", (input, expected) => {
    expect(parseAmount(input)).toBe(expected);
  });

  it("非法输入抛错", () => {
    expect(() => parseAmount("abc")).toThrowError(/无效金额/);
  });
});
```

**教材衔接：测试替身速查**

| 替身 | 用途 | 注意 |
| --- | --- | --- |
| stub | 返回固定值 | 只验证一条路径 |
| spy | 记录调用 | 用于验证副作用 |
| mock 模块 | 替换整个模块 | 容易与实现耦合 |
| fake | 简化实现（内存版仓储） | 保留部分真实行为 |
| MSW | 拦截网络 | 最接近真实调用链 |

原则：**优先替身外部依赖，核心业务逻辑用真实实现。**

**教材衔接：零基础详解：前端与 Node 的测试实践**

### 一句话说清它是什么

TypeScript 项目常用 **Vitest 做单元与集成测试**、**Playwright 做端到端测试**。
写测试的核心不是覆盖率数字，而是**断言行为、隔离依赖、可重复运行**。

### 用生活比喻理解

| 类型 | 比喻 | 说明 |
| --- | --- | --- |
| 单元测试 | 零件检验 | 纯函数与规则，毫秒级 |
| 组件测试 | 装配检验 | 渲染、交互、可见性 |
| 集成测试 | 联调 | 多个模块 + 真实数据库 |
| E2E | 用户试用 | 浏览器里走完整流程 |
| Mock | 替身演员 | 隔离外部依赖 |

### 一个 Vitest 单元测试

```typescript
import { describe, expect, it } from "vitest";
import { formatPrice, parseTags } from "../src/format";

describe("formatPrice", () => {
  it("保留两位小数", () => {
    expect(formatPrice(19.9)).toBe("¥19.90");
  });

  it("负数抛错", () => {
    expect(() => formatPrice(-1)).toThrowError("金额不能为负");
  });
});

describe("parseTags", () => {
  it.each([
    ["a,b", ["a", "b"]],
    [" a , b ", ["a", "b"]],
    ["", []],
  ])("解析 %s", (input, expected) => {
    expect(parseTags(input)).toEqual(expected);
  });
});
```

### Mock：只在边界用

```typescript
import { vi, expect, it } from "vitest";
import { sendWelcome } from "../src/notify";

it("注册成功后发送欢迎邮件", async () => {
  const mailer = { send: vi.fn().mockResolvedValue({ ok: true }) };

  await sendWelcome({ email: "a@b.com" }, mailer);

  expect(mailer.send).toHaveBeenCalledOnce();
  expect(mailer.send).toHaveBeenCalledWith(
    expect.objectContaining({ to: "a@b.com" }),
  );
});
```

| 替身 | 用途 |
| --- | --- |
| `vi.fn()` | 记录调用、返回指定值 |
| `vi.spyOn(obj, "m")` | 监视真实对象的方法 |
| `vi.mock("module")` | 替换整个模块 |
| msw | 拦截网络请求（推荐） |

**原则**：只 mock 外部边界（网络、时间、随机、支付），不要 mock 自己的业务函数。

### 组件测试的三个关注点

```typescript
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

it("输入后点击按钮显示问候", async () => {
  render(<Greeter />);

  await userEvent.type(screen.getByLabelText("姓名"), "小明");
  await userEvent.click(screen.getByRole("button", { name: "打招呼" }));

  expect(screen.getByText("你好，小明")).toBeInTheDocument();
});

it("名称为空时按钮禁用", () => {
  render(<Greeter />);
  expect(screen.getByRole("button", { name: "打招呼" })).toBeDisabled();
});
```

| 关注点 | 做法 |
| --- | --- |
| 用户能看到什么 | 用 `getByRole`、`getByLabelText` |
| 用户能做什么 | 用 `userEvent` 而不是直接触发事件 |
| 不该测什么 | 内部 state、私有方法、class 名 |

### E2E：只覆盖关键路径

```typescript
import { expect, test } from "@playwright/test";

test("用户可以注册并登录", async ({ page }) => {
  await page.goto("/register");
  await page.getByLabel("邮箱").fill(`test${Date.now()}@example.com`);
  await page.getByLabel("密码").fill("Passw0rd!");
  await page.getByRole("button", { name: "注册" }).click();

  await expect(page).toHaveURL("/dashboard");
  await expect(page.getByText("欢迎回来")).toBeVisible();
});
```

```bash
npx playwright test                    # 跑全部
npx playwright test --ui               # 可视化调试
npx playwright test --trace on         # 记录轨迹，失败可回放
```

### 测试数据的三条纪律

```text
1. 每个用例自己造数据，不依赖别人留下的
2. 用时间戳或随机后缀避免唯一键冲突
3. 用例结束清理（或每次跑在独立数据库/事务里）
```

```typescript
// 冻结时间，避免「今天过了就失败」
import { vi } from "vitest";
vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 依赖当前时间 | 换天就失败 | 冻结时间或注入时钟 |
| 用 `getByTestId` 满天飞 | 测的是实现 | 优先用语义化查询 |
| 只断言「不为空」 | 出错也通过 | 断言具体值 |
| mock 业务内部函数 | 重构即全红 | 只 mock 外部边界 |
| 测试之间共享状态 | 单独跑就挂 | 每个用例独立准备与清理 |
| 用 `sleep` 等异步 | 慢且不稳定 | 用 `waitFor` 或 `findBy` |
| E2E 覆盖所有细节 | 跑一次十几分钟 | 只保留关键路径 |
| 记得清理忘了断言 | 测试看似通过 | 清理后再补一次断言 |

### 手把手练习：给表单写三层测试

```typescript
// 1. 单元：校验函数
it("邮箱不合法时报错", () => {
  expect(validateEmail("bad")).toBe("邮箱格式不正确");
  expect(validateEmail("a@b.com")).toBeNull();
});

// 2. 组件：错误提示是否显示
it("输入非法邮箱时显示提示", async () => {
  render(<SignupForm />);
  await userEvent.type(screen.getByLabel("邮箱"), "bad");
  await userEvent.click(screen.getByRole("button", { name: "提交" }));
  expect(await screen.findByText("邮箱格式不正确")).toBeVisible();
});

// 3. E2E：完整注册流程
test("注册成功后跳转", async ({ page }) => {
  await page.goto("/register");
  await page.getByLabel("邮箱").fill(`u${Date.now()}@example.com`);
  await page.getByLabel("密码").fill("Passw0rd!");
  await page.getByRole("button", { name: "注册" }).click();
  await expect(page).toHaveURL("/dashboard");
});
```

### 学完自测

- [ ] 能说出单元、组件、集成、E2E 的分工。
- [ ] 知道什么时候才该用 mock。
- [ ] 能说出语义化查询为什么优于 test id。
- [ ] 知道测试依赖时间会带来什么问题。
- [ ] 能说出 E2E 只覆盖关键路径的原因。

## 时间/空间复杂度或性能分析

**复杂度证据**：「TypeScript 测试策略」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「TypeScript 测试策略」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「TypeScript 测试策略」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《TypeScript 测试策略》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「TypeScript 测试策略」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

> 说明：本表由《TypeScript 测试策略》的核心知识整理（2026-10-07），人工复核进度见 docs/content_review_batches.md。

| 易错点 | 容易踩的做法 | 正确结论 |
| --- | --- | --- |
| 只测实现细节 | 重构一次就大量失败 | 面向行为与契约编写测试 |
| 测试与运行时脱节 | 编译通过但运行失败 | 覆盖真实运行时路径与边界 |
| 没有覆盖率要求 | 关键路径没有测试保护 | 对关键模块设定覆盖率目标 |

**教材衔接：故障现场**

### 现场 1：只测实现细节

**症状**：在《TypeScript 测试策略》的复现场景中，重构一次就大量失败。

**根因**：“重构一次就大量失败”只是表层结果。向上追溯会落到“只测实现细节”这一步，因为它省略了《TypeScript 测试策略》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《TypeScript 测试策略》的问题，面向行为与契约编写测试。

**验证**：先在《TypeScript 测试策略》中记录“只测实现细节”留下的失败证据，再执行“面向行为与契约编写测试”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 2：测试与运行时脱节

**症状**：在《TypeScript 测试策略》的复现场景中，编译通过但运行失败。

**根因**：当出现“测试与运行时脱节”时，执行路径已经绕过了《TypeScript 测试策略》的关键约束，最终以“编译通过但运行失败”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《TypeScript 测试策略》的问题，覆盖真实运行时路径与边界。

**验证**：保留《TypeScript 测试策略》里触发“编译通过但运行失败”的输入、版本和日志，按“覆盖真实运行时路径与边界”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：没有覆盖率要求

**症状**：在《TypeScript 测试策略》的复现场景中，关键路径没有测试保护。

**根因**：“关键路径没有测试保护”只是表层结果。向上追溯会落到“没有覆盖率要求”这一步，因为它省略了《TypeScript 测试策略》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《TypeScript 测试策略》的问题，对关键模块设定覆盖率目标。

**验证**：在《TypeScript 测试策略》中按“对关键模块设定覆盖率目标”调整后，从“没有覆盖率要求”的触发条件重放同一条路径，确认“关键路径没有测试保护”不再出现，并补一个相邻边界用例检查没有引入新问题。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《Monorepo 工程实践》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《类型检查与构建性能优化》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《Monorepo 工程实践》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《TypeScript 实战：全栈类型安全》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「TypeScript 测试策略」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《TypeScript 测试策略》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

阅读「TypeScript 测试策略」正文里的这段 TypeScript 代码，下面哪一项判断是正确的？

```typescript
import { vi, expect, it } from "vitest";
import { sendWelcome } from "../src/notify";

it("注册成功后发送欢迎邮件", async () => {
  const mailer = { send: vi.fn().mockResolvedValue({ ok: true }) };

  await sendWelcome({ email: "a@b.com" }, mailer);

  expect(mailer.send).toHaveBeenCalledOnce();
  expect(mailer.send).toHaveBeenCalledWith(
    expect.objectContaining({ to: "a@b.com" }),
  );
});
```

A. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。
B. 这段代码会产生可观察的输出，运行后能看到结果。
C. 这段代码只做静态声明，没有循环、分支或可观察输出。
D. 这段代码包含循环结构，同一段逻辑会被重复执行。

**参考答案**：这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**解析**：在「TypeScript 测试策略」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「TypeScript 测试策略」的正文示例，围绕Vitest、TestingLibrary、MSW展开；把输入或边界换成空值、极值或失败情况后，结论要以「TypeScript 测试策略」的实际运行结果为准。

### 自测 2

组件测试应该断言什么？

A. 用户可见的行为与文本
B. 私有方法的调用次数
C. 样式类的具体字符串
D. 组件内部 state 的值

**参考答案**：用户可见的行为与文本

**解析**：在「TypeScript 测试策略」里，作答时，先用Vitest建立输入与输出的基线，再把用户可见的行为与文本代入边界条件核对，结论才能复现。这道题的关键在「TypeScript 测试策略」的Vitest、TestingLibrary、MSW：先确认题干“组件测试应该断言什么”问的是哪一步，再排除偷换前提的选项。

### 自测 3

围绕“TypeScript 测试策略”中的 Vitest、TestingLibrary、MSW，下列哪两项是本课强调的实践判断？

A. 验证 TestingLibrary 时要固定版本并覆盖边界输入，结论才可复现
B. 把 TestingLibrary 的单次运行结果当成所有版本和规模都成立
C. 学习 Vitest 时要同时说明输入、输出和失败路径，不能只看正常流程
D. 只要 Vitest 的常规示例通过，就可以跳过边界与异常路径

**参考答案**：验证 TestingLibrary 时要固定版本并覆盖边界输入，结论才可复现；学习 Vitest 时要同时说明输入、输出和失败路径，不能只看正常流程

**解析**：结论应落在验证 TestingLibrary 时要固定版本并覆盖边界输入。本课把TypeScript 测试策略拆成概念、示例与故障现场三部分，因此判断 Vitest 时必须同时交代输入、输出和失败路径，这使“学习 Vitest 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在TypeScript 测试策略里，判断 TestingLibrary 时要固定版本与边界输入，所以“验证 TestingLibrary 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

**教材衔接：复习与自测**

- [ ] 单元测试覆盖边界与异常分支。
- [ ] 组件测试断言用户可见行为。
- [ ] 网络用 MSW 在 HTTP 层模拟，未处理请求会报错。
- [ ] 端到端只覆盖核心旅程，保持稳定。
- [ ] 覆盖率看未覆盖分支而非数字高低。

**教材衔接：动手练习**

> 本课练习重点：围绕「Vitest、TestingLibrary、MSW」完成复述、实验和交付，每个结果都要能被别人检查。

为 onUnhandledRequest 写出类型签名，然后故意传错一个参数观察编译器报错。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. TypeScript 测试策略解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「TestingLibrary」是什么关系？

验收标准：回答里必须出现 Vitest，并写出一个让结论失效的边界条件。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：先原样跑通正文里的 `onUnhandledRequest`，再只改Vitest相关的输入，按「原例 → 改动 → 预测 → 结果 → 原因」记录；预测必须写在实际运行之前。

### 练习 3：交付一个小结果（30 分钟）

围绕 Vitest 写一个最小示例，先用 onUnhandledRequest 跑通，再补一个边界输入。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Vitest」和「TestingLibrary」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```typescript
import { describe, expect, it } from "vitest";
import { formatPrice, parseTags } from "../src/format";

describe("formatPrice", () => {
  it("保留两位小数", () => {
    expect(formatPrice(19.9)).toBe("¥19.90");
  });

  it("负数抛错", () => {
    expect(() => formatPrice(-1)).toThrowError("金额不能为负");
  });
});

describe("parseTags", () => {
  it.each([
    ["a,b", ["a", "b"]],
    [" a , b ", ["a", "b"]],
    ["", []],
  ])("解析 %s", (input, expected) => {
    expect(parseTags(input)).toEqual(expected);
  });
});
```

### 任务 2：只改一个条件

把「TypeScript 测试策略」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 TestingLibrary 换成边界值，其他输入保持原样。
- 预测：先写下「TypeScript 测试策略」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响Vitest。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的 Vitest 数据，保持输出格式与任务 1 一致。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「模拟后端接口时，最贴近真实调用链的做法是？」的判断依据。
- [ ] 不看解析，能说出「组件测试应该断言什么？」的判断依据。
- [ ] 不看解析，能说出「测试里等待异步结果，推荐使用？」的判断依据。
- [ ] 不看解析，能说出「测试资源分层建议是？」的判断依据。
- [ ] 不看解析，能说出「关于覆盖率，正确的理解是？」的判断依据。
- [ ] 至少运行一次 onUnhandledRequest 的示例，记录输入、输出和 Vitest 的边界情况。
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
| `覆盖率` | 测试执行到的代码、分支或需求占总量的比例。 |
| `Mock` | 测试替身：模拟外部依赖或慢操作，只在边界使用，避免把内部实现也一起 mock。 |
| `单元测试边界` | 优先覆盖空值、越界与错误分支，只测正常路径的覆盖率没有意义。 |
| `快照测试` | 把输出与基线快照比对，适合稳定的结构化输出，更新快照必须经过评审。 |

## 考点精讲

### 考点 1：代码补全·Vitest

- **题目**：阅读「TypeScript 测试策略」正文里的这段 TypeScript 代码，下面哪一项判断是正确的？
- **判断依据**：在「TypeScript 测试策略」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「TypeScript 测试策略」的正文示例，围绕Vitest、TestingLibrary、MSW展开；把输入或边界换成空值、极值或失败情况后，结论要以「TypeScript 测试策略」的实际运行结果为准。

### 考点 2：概念判断·Vitest

- **题目**：组件测试应该断言什么？
- **判断依据**：在「TypeScript 测试策略」里，作答时，先用Vitest建立输入与输出的基线，再把用户可见的行为与文本代入边界条件核对，结论才能复现。这道题的关键在「TypeScript 测试策略」的Vitest、TestingLibrary、MSW：先确认题干“组件测试应该断言什么”问的是哪一步，再排除偷换前提的选项。

### 考点 3：概念判断·Vitest

- **题目**：测试里等待异步结果，推荐使用？
- **判断依据**：在「TypeScript 测试策略」里，findBy 系列查询或带轮询的断言（自动等待）。自动等待的查询会在超时前持续重试，既快又稳。“测试里等待异步结果”与「TypeScript 测试策略」的术语表相呼应，只有符合Vitest、TestingLibrary、MSW约束的“findBy 系列查询或带轮询的断言（自”才是正文支持的结论。

### 考点 4：多选辨析·Vitest

- **题目**：围绕“TypeScript 测试策略”中的 Vitest、TestingLibrary、MSW，下列哪两项是本课强调的实践判断？
- **判断依据**：结论应落在验证 TestingLibrary 时要固定版本并覆盖边界输入。本课把TypeScript 测试策略拆成概念、示例与故障现场三部分，因此判断 Vitest 时必须同时交代输入、输出和失败路径，这使“学习 Vitest 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在TypeScript 测试策略里，判断 TestingLibrary 时要固定版本与边界输入，所以“验证 TestingLibrary 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 5：概念判断·Vitest

- **题目**：关于覆盖率，正确的理解是？
- **判断依据**：在「TypeScript 测试策略」里，作答时，先用Vitest建立输入与输出的基线，再把无断言的测试也能拉高覆盖率代入边界条件核对，结论才能复现。把“无断言的测试也能拉高覆盖率”代回「TypeScript 测试策略」里“正确的理解是”的例子核对，条件一旦改变，结论就要用Vitest、TestingLibrary、MSW重新推导。

### 考点 6：填空·Vitest

- **题目**：补全代码：「TypeScript 测试策略」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `beforeEach( => server.listen({ ____: "error" }));`
- **判断依据**：空格应填写「onUnhandledRequest」、「onunhandledrequest」。这道题的关键在「TypeScript 测试策略」的Vitest、TestingLibrary、MSW：先确认题干“补全代码”问的是哪一步，再排除偷换前提的选项。

## English Overview

**Title:** Testing in TypeScript

**Summary:** Vitest, Testing Library and MSW in practice.

**Category:** TypeScript
**Level:** 进阶
**Key terms:** Vitest, TestingLibrary, MSW, 组件测试, 覆盖率

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：TypeScript 5.x / Node.js 22+
；本课聚焦 Vitest。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Vitest、TestingLibrary、MSW、组件测试、覆盖率
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-03-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) | 类型系统与语言指南 |
| [Everyday Types](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html) | 常用类型与收窄 |
| [装饰器文档](https://www.typescriptlang.org/docs/handbook/decorators.html) | 装饰器与元数据 |

> 「TypeScript 测试策略」的链接用于离线阅读后的延伸核对；App 不会自动联网。
