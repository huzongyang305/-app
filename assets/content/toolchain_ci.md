# CI/CD 与 GitHub Actions

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：35 分钟

![持续集成流水线的五个阶段](images/diagram_ci_pipeline.webp)

![CI/CD 与 GitHub Actions](images/category_ci_cd.webp)

## 本节知识框架

**课程定位**：所属分类为「工具链」，课程主题为「CI/CD 与 GitHub Actions」，学习阶段为「进阶」，建议用时 35 分钟。

**本课要解决的主问题**：流水线结构、缓存、密钥与构建部署实践。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「CI/CD 与 GitHub Actions」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「CI/CD 与 GitHub Actions」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「CI」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《Docker 容器基础》

**学习位置**：本课位于《Docker 容器基础》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《可观测性：日志、指标与链路》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释CI/CD 与 GitHub Actions解决了什么问题，而不是只背术语。
- 能说清 「CI」、「CD」、「GitHub Actions」、「workflow」 之间的关系，并分别举出一个例子。
- 能把 CI 放回「CI/CD 与 GitHub Actions」的知识体系，说明它和 CD 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：流水线结构、缓存、密钥与构建部署实践。

**教材衔接：前置知识**

- 先完成上一课《Docker 容器基础》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「Docker 容器基础」，或确认自己能独立跑通正文里的 pull_request 示例。
- 开始前先复习：CI、CD、GitHub Actions。
- 看不懂就直接缩小例子：只保留 CI 相关的两行输入，跑通后再加回其余部分。

**教材衔接：本课小结**

CI/CD 把「人肉发布流程」变成可重复的自动化脚本；最小可用版本就是**检出代码 → 装依赖 → 跑测试 → 构建产物**。

## 核心概念定义

> 在阅读《CI/CD 与 GitHub Actions》时，术语第一次出现先给操作性定义，再给边界；正文说法与这里冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| npm ci | 要点：npm ci 与 lock 文件保证可复现；needs 建立阶段依赖；镜像用 github.sha 做不可变标签；密钥一律走 secrets。缓存依赖通常能让 CI 从数分钟压缩到一分钟内。 | 仅在「CI/CD 与 GitHub Actions」明确给出的输入、版本与资源条件下成立。 |
| CD | CI/CD 把「人肉发布流程」变成可重复的自动化脚本。 | 仅在「CI/CD 与 GitHub Actions」明确给出的输入、版本与资源条件下成立。 |
| 缓存 | 把依赖与构建产物按 key 复用，key 要包含锁文件哈希，否则会用到过期依赖。 | 仅在「CI/CD 与 GitHub Actions」明确给出的输入、版本与资源条件下成立。 |
| 密钥管理 | 密钥只在运行时注入且不回显，令牌按最小权限发放并定期轮换。 | 仅在「CI/CD 与 GitHub Actions」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「CI/CD 与 GitHub Actions」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「npm ci」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「CD」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「缓存」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「CI/CD 与 GitHub Actions」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | npm ci | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | CD | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 缓存 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「CI/CD 与 GitHub Actions」自己的示例验证。「CI/CD 与 GitHub Actions」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：持续集成与持续交付**

- **CI（持续集成）**：每次提交自动构建 + 跑测试，尽早发现问题。
- **CD（持续交付/部署）**：流水线产出可发布版本，或自动部署到环境。

核心原则：**流水线要快、结果要可靠、失败要立刻可见**。

**教材衔接：GitHub Actions 基本结构**

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npm run lint
      - run: npm test -- --coverage
```

关键概念：

| 概念 | 说明 |
| --- | --- |
| workflow | `.github/workflows/*.yml` 定义的一条流水线 |
| job | 一组步骤，默认并行执行，可声明依赖 |
| step | 单个命令或 action |
| runner | 执行环境（GitHub 托管或自建） |
| secrets | 加密的敏感配置，如 `${{ secrets.TOKEN }}` |
| cache | 缓存依赖目录，显著缩短构建时间 |

**教材衔接：流水线设计建议**

1. 先快后慢：lint 与单测在前，集成测试与打包在后。
2. 失败即停止，不要带病继续。
3. 构建产物只产出一次，各环境复用同一份（避免「测试的不是发布的那份」）。
4. 敏感信息只放 Secrets，绝不写进仓库。
5. 主分支保护：必须通过检查才能合并。

**教材衔接：流水线设计速查**

| 阶段 | 目标 | 建议 |
| --- | --- | --- |
| 快速反馈 | 秒级发现问题 | 先跑格式与 lint，再跑单元测试 |
| 构建 | 产出不可变制品 | 只构建一次，后续环境复用同一产物 |
| 集成测试 | 验证跨组件 | 用容器起依赖，测试可重复 |
| 安全扫描 | 依赖漏洞与密钥 | 依赖扫描、SAST、密钥扫描接入门禁 |
| 部署 | 灰度到全量 | 先 staging 再生产，带自动回滚条件 |
| 观测 | 部署后验证 | 关注错误率与关键业务指标 |

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 CI、CD | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「CI/CD 与 GitHub Actions」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「CI/CD 与 GitHub Actions」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

## 代码/协议/SQL 示例

以下代码、协议或 SQL 片段来自《CI/CD 与 GitHub Actions》原文，保留原有语言标记与上下文；先预测《CI/CD 与 GitHub Actions》示例的输出，再按正文步骤运行或推演，示例依赖外部环境时同时记录版本与输入。

**教材衔接：构建与部署示例**

```yaml
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker build -t ghcr.io/${{ github.repository }}:${{ github.sha }} .
      - run: echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
      - run: docker push ghcr.io/${{ github.repository }}:${{ github.sha }}
```

生产部署建议使用**环境（environment）**加人工审批，并保留可回滚的镜像标签。

**教材衔接：一份可直接用的完整 workflow**

```yaml
name: CI
on:
  push: { branches: [main] }
  pull_request:
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm                       # 自动缓存 npm 依赖
      - run: npm ci                        # 用 lock 文件安装，保证可复现
      - run: npm run lint
      - run: npx tsc --noEmit              # 类型检查（打包器不做）
      - run: npm test -- --coverage
      - uses: actions/upload-artifact@v4
        if: always()                       # 失败也保留覆盖率报告
        with: { name: coverage, path: coverage/ }

  build:
    needs: quality                         # 质量通过才构建
    runs-on: ubuntu-latest
    steps:
      - run: docker build -t app:${{ github.sha }} .
      - run: echo "${{ secrets.REGISTRY_TOKEN }}" | docker login -u ${{ github.actor }} --password-stdin
      - run: docker push app:${{ github.sha }}
```

要点：`npm ci` 与 lock 文件保证可复现；`needs` 建立阶段依赖；镜像用 `github.sha` 做不可变标签；密钥一律走 `secrets`。缓存依赖通常能让 CI 从数分钟压缩到一分钟内。

**教材衔接：GitHub Actions 速查**

| 概念 | 作用 | 示例 |
| --- | --- | --- |
| `on` | 触发条件 | `push`、`pull_request`、`schedule`、`workflow_dispatch` |
| `jobs` | 并行任务集合 | 测试、构建、部署各自一个 job |
| `needs` | 依赖关系 | `deploy` 依赖 `test` |
| `runs-on` | 运行环境 | `ubuntu-latest`、`windows-latest` |
| `steps` | 顺序步骤 | 每个 `run` 或 `uses` 一步 |
| `actions/checkout` | 拉取代码 | 必装第一步 |
| `actions/setup-node` | 安装语言环境 | 配合 `cache: npm` |
| `actions/cache` | 缓存依赖 | key 包含 lock 文件哈希 |
| `secrets` | 密钥 | 只注入环境变量，不落盘 |
| `matrix` | 多版本并行 | 一次跑 Node 18/20/22 |
| `concurrency` | 并发控制 | 同一分支只保留最新一次运行 |
| `if` | 条件执行 | `if: github.ref == 'refs/heads/main'` |
| `environment` | 部署环境 | 配置审批与环境保护规则 |
| `artifacts` | 传递产物 | `actions/upload-artifact` / `download-artifact` |

```yaml
name: ci
on:
  push: { branches: [main] }
  pull_request:

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node: [20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          cache: npm
      - run: npm ci
      - run: npm run lint
      - run: npm test -- --coverage

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - run: npm ci && npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/
```

## 时间/空间复杂度或性能分析

**复杂度证据**：「CI/CD 与 GitHub Actions」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「CI/CD 与 GitHub Actions」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「CI/CD 与 GitHub Actions」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《CI/CD 与 GitHub Actions》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「CI/CD 与 GitHub Actions」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 在 workflow 里打印 secrets | 日志泄漏密钥 | Actions 会自动打码，但仍禁止主动输出；用 `add-mask` 处理派生值 |
| 每个 job 重复构建 | 流水线时间长 | 构建一次，用 artifacts 传递产物 |
| 缓存 key 不含 lock 文件哈希 | 用到过期依赖 | key 用 `hashFiles('**/package-lock.json')` |
| `npm install` 代替 `npm ci` | 依赖版本漂移 | CI 中用 `npm ci` 保证可复现 |
| 未设置 `concurrency` | 同分支多次运行互相干扰 | 加并发组并取消旧运行 |
| 部署不等测试完成 | 带缺陷上线 | 用 `needs` 明确依赖 |
| 用 `pull_request_target` 跑不可信代码 | 严重安全风险 | 避免它对 PR 代码执行，或用最小权限 |
| 权限没限制 | 令牌权限过大 | 显式 `permissions: contents: read` |
| 用例偶发失败直接重试 | 掩盖真实问题 | 先定位不稳定原因，必要时隔离标记 |
| 只在 main 上测试 | 问题合并后才暴露 | PR 阶段就跑测试 |

**教材衔接：故障现场**

### 现场 1：在 workflow 里打印 secrets

**症状**：在《CI/CD 与 GitHub Actions》的复现场景中，日志泄漏密钥。

**根因**：当出现“在 workflow 里打印 secrets”时，执行路径已经绕过了《CI/CD 与 GitHub Actions》的关键约束，最终以“日志泄漏密钥”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《CI/CD 与 GitHub Actions》的问题，Actions 会自动打码，但仍禁止主动输出；用 add-mask 处理派生值。

**验证**：先在《CI/CD 与 GitHub Actions》中记录“在 workflow 里打印 secrets”留下的失败证据，再执行“Actions 会自动打码，但仍禁止主动输出；用 add-mask 处理派生值”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 2：每个 job 重复构建

**症状**：在《CI/CD 与 GitHub Actions》的复现场景中，流水线时间长。

**根因**：“流水线时间长”只是表层结果。向上追溯会落到“每个 job 重复构建”这一步，因为它省略了《CI/CD 与 GitHub Actions》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《CI/CD 与 GitHub Actions》的问题，构建一次，用 artifacts 传递产物。

**验证**：在《CI/CD 与 GitHub Actions》中按“构建一次，用 artifacts 传递产物”调整后，从“每个 job 重复构建”的触发条件重放同一条路径，确认“流水线时间长”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 3：缓存 key 不含 lock 文件哈希

**症状**：在《CI/CD 与 GitHub Actions》的复现场景中，用到过期依赖。

**根因**：当出现“缓存 key 不含 lock 文件哈希”时，执行路径已经绕过了《CI/CD 与 GitHub Actions》的关键约束，最终以“用到过期依赖”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《CI/CD 与 GitHub Actions》的问题，key 用 hashFiles('**/package-lock.json')。

**验证**：先在《CI/CD 与 GitHub Actions》中记录“缓存 key 不含 lock 文件哈希”留下的失败证据，再执行“key 用 hashFiles('**/package-lock.json')”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《Docker 容器基础》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《Kubernetes 基础》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《Docker 容器基础》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《可观测性：日志、指标与链路》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「CI/CD 与 GitHub Actions」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立完成《CI/CD 与 GitHub Actions》的自测，再核对答案与解析。答案必须能在本课正文或示例中找到依据，不能只凭语感。

### 自测 1

按“CI/CD 与 GitHub Actions”中 CI、CD、GitHub Actions 的实践顺序，把四个步骤排成从准备到复盘的合理顺序。

A. 写出最小示例并核对 CD 的基线结果
B. 只改一个变量，记录边界与失败路径的变化
C. 固定版本与证据，把“CI/CD 与 GitHub Actions”的结论写成可复现记录
D. 先明确 CI 的输入、输出与约束

**参考答案**：先明确 CI 的输入、输出与约束 → 写出最小示例并核对 CD 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把“CI/CD 与 GitHub Actions”的结论写成可复现记录

**解析**：在「CI/CD 与 GitHub Actions」里，在本课的练习里，顺序应当是：先明确 CI 的输入、输出与约束 → 写出最小示例并核对 CD 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把本课的结论写成可复现记录。这个顺序把 CI 的输入、输出和约束放在最前面，在CI/CD 与 GitHub Actions里避免概念没对齐就开始调参。第二步用 CD 建立可核对的基线，在CI/CD 与 GitHub Actions里第三步才允许改变一个变量并观察失败路径。

### 自测 2

围绕“CI/CD 与 GitHub Actions”中的 CI、CD、GitHub Actions，下列哪两项是本课强调的实践判断？

A. 学习 CI 时要同时说明输入、输出和失败路径，不能只看正常流程
B. 只要 CI 的常规示例通过，就可以跳过边界与异常路径
C. 验证 CD 时要固定版本并覆盖边界输入，结论才可复现
D. 把 CD 的单次运行结果当成所有版本和规模都成立

**参考答案**：学习 CI 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 CD 时要固定版本并覆盖边界输入，结论才可复现

**解析**：本课把CI/CD 与 GitHub Actions拆成概念、示例与故障现场三部分，因此判断 CI 时必须同时交代输入、输出和失败路径，这使“学习 CI 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在CI/CD 与 GitHub Actions里，判断 CD 时要固定版本与边界输入，所以“验证 CD 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 3

job 中使用 needs 关键字的作用是？

A. 声明依赖的 job
B. 安装依赖包
C. 指定 runner
D. 启用缓存

**参考答案**：声明依赖的 job

**解析**：在「CI/CD 与 GitHub Actions」里，声明依赖的 job。needs 建立 job 之间的依赖顺序，例如测试通过后再构建部署。回到「CI/CD 与 GitHub Actions」的正文示例，用“job 中使用 needs 关键字的”走一遍CI、CD、GitHub Actions的完整流程，能复现的结论才可以保留。

**教材衔接：复习与自测**

- [ ] PR 触发测试，合并前必须通过门禁。
- [ ] 构建一次，多环境复用同一制品。
- [ ] 依赖缓存 key 包含 lock 文件哈希。
- [ ] secrets 只通过环境变量注入，绝不写入日志。
- [ ] 部署配有健康检查与回滚条件。

**教材衔接：动手练习**

> 本课练习重点：围绕「CI、CD、GitHub Actions」完成复述、实验和交付，每个结果都要能被别人检查。

把 pull_request 的部署命令在临时环境跑通，再注入一次失败。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. CI/CD 与 GitHub Actions解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「CD」是什么关系？

验收标准：用自己的话解释 CI，并给出一个它不成立的反例。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：先原样跑通正文里的 `pull_request`，再只改CI相关的输入，按「原例 → 改动 → 预测 → 结果 → 原因」记录；预测必须写在实际运行之前。

### 练习 3：交付一个小结果（30 分钟）

先记录 CD 的失败回滚步骤，再执行变更。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「CI」和「CD」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

本节围绕CI/CD 与 GitHub Actions安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「CI/CD 与 GitHub Actions」的结构，画完再对照骨架：

- 主干：持续集成与持续交付 → GitHub Actions 基本结构 → 构建与部署示例 → 流水线设计建议
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明CI与CD的关系？

### 任务 2：做一次对比实验

**验收标准**：两个方案的差异必须落在「CI/CD 与 GitHub Actions」的实际约束上；写清当CI越过哪条边界时应该换方案。

### 任务 3：迁移到自己的场景

**验收标准**：换一个人按你的记录重跑 pull_request，能得到相同输出；得不到就补写缺失的前提。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「持续集成（CI）的核心目的是？」的判断依据。
- [ ] 不看解析，能说出「GitHub Actions 中 secrets 用于？」的判断依据。
- [ ] 不看解析，能说出「job 中使用 needs 关键字的作用是？」的判断依据。
- [ ] 不看解析，能说出「CI 中配置依赖缓存的价值是？」的判断依据。
- [ ] 不看解析，能说出「把测试拆成多个并行 job 的代价是？」的判断依据。
- [ ] 至少运行一次 pull_request 的示例，记录输入、输出和 CI 的边界情况。
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
| `npm ci` | 要点：`npm ci` 与 lock 文件保证可复现；`needs` 建立阶段依赖；镜像用 `github.sha` 做不可变标签；密钥一律走 `secrets`。缓存依赖通常能让 CI 从数分钟压缩到一分钟内。 |
| `CD` | CI/CD 把「人肉发布流程」变成可重复的自动化脚本。 |
| `缓存` | 把依赖与构建产物按 key 复用，key 要包含锁文件哈希，否则会用到过期依赖。 |
| `密钥管理` | 密钥只在运行时注入且不回显，令牌按最小权限发放并定期轮换。 |

## 考点精讲

### 考点 1：顺序排列·CI

- **题目**：按“CI/CD 与 GitHub Actions”中 CI、CD、GitHub Actions 的实践顺序，把四个步骤排成从准备到复盘的合理顺序。
- **判断依据**：在「CI/CD 与 GitHub Actions」里，在本课的练习里，顺序应当是：先明确 CI 的输入、输出与约束 → 写出最小示例并核对 CD 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把本课的结论写成可复现记录。这个顺序把 CI 的输入、输出和约束放在最前面，在CI/CD 与 GitHub Actions里避免概念没对齐就开始调参。第二步用 CD 建立可核对的基线，在CI/CD 与 GitHub Actions里第三步才允许改变一个变量并观察失败路径。

### 考点 2：多选辨析·CI

- **题目**：围绕“CI/CD 与 GitHub Actions”中的 CI、CD、GitHub Actions，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把CI/CD 与 GitHub Actions拆成概念、示例与故障现场三部分，因此判断 CI 时必须同时交代输入、输出和失败路径，这使“学习 CI 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在CI/CD 与 GitHub Actions里，判断 CD 时要固定版本与边界输入，所以“验证 CD 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 3：概念判断·CI

- **题目**：job 中使用 needs 关键字的作用是？
- **判断依据**：在「CI/CD 与 GitHub Actions」里，声明依赖的 job。needs 建立 job 之间的依赖顺序，例如测试通过后再构建部署。回到「CI/CD 与 GitHub Actions」的正文示例，用“job 中使用 needs 关键字的”走一遍CI、CD、GitHub Actions的完整流程，能复现的结论才可以保留。

### 考点 4：概念判断·CI

- **题目**：CI 中配置依赖缓存的价值是？
- **判断依据**：缓存键要包含锁文件哈希，依赖变更时自动失效，避免用到过期缓存。在「CI/CD 与 GitHub Actions」里，作答时，先用CI建立输入与输出的基线，再把复用已下载的依赖代入边界条件核对，结论才能复现。在「CI/CD 与 GitHub Actions」里，这道题要求区分概念与边界，「复用已下载的依赖」只有在题干给出的前提下才成立，而「提升测试覆盖率」、「减少代码体积」缺少同一组条件。

### 考点 5：概念判断·CI

- **题目**：把测试拆成多个并行 job 的代价是？
- **判断依据**：在「CI/CD 与 GitHub Actions」里，需要额外传递构建产物。并行度、缓存与制品传递策略共同决定流水线的总时长。「CI/CD 与 GitHub Actions」要求先交代CI、CD、GitHub Actions的前提再下结论，所以“需要额外传递构建产物”只在题干“把测试拆成多个并行 job 的代价是”给定的条件下成立。

### 考点 6：排错·CI

- **题目**：阅读「CI/CD 与 GitHub Actions」的代码片段，下面哪项判断是正确的？
- **判断依据**：在「CI/CD 与 GitHub Actions」里，每次提交自动构建与测试。CI 让问题在提交后几分钟内暴露，而不是等到发布前。「CI/CD 与 GitHub Actions」要求先交代CI、CD、GitHub Actions的前提再下结论，所以“每次提交自动构建与测试”只在题干“阅读CI/CD 与 GitHub Actions的代码片段”给定的条件下成立。

## English Overview

**Title:** CI/CD & GitHub Actions

**Summary:** Pipelines, caching, secrets and deployment.

**Category:** Toolchain
**Level:** 进阶
**Key terms:** CI, CD, GitHub Actions, workflow, secrets

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Git / Docker / Kubernetes / CI 平台
；本课聚焦 CI。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：CI、CD、GitHub Actions、workflow、secrets
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-08-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [GitHub Actions](https://docs.github.com/actions) | CI/CD 工作流 |
| [CMake 文档](https://cmake.org/documentation/) | 跨平台构建与依赖 |
| [Maven 指南](https://maven.apache.org/guides/) | Java 构建与依赖 |

> 「CI/CD 与 GitHub Actions」的链接用于离线阅读后的延伸核对；App 不会自动联网。
