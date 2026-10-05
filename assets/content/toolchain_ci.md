# CI/CD 与 GitHub Actions

![CI/CD 与 GitHub Actions](images/category_ci_cd.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「CI/CD 与 GitHub Actions」解决了什么问题，而不是只背术语。
- 能说清 「CI」、「CD」、「GitHub Actions」、「workflow」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「工具链」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：流水线结构、缓存、密钥与构建部署实践。

## 前置知识

- 先完成上一课《Docker 容器基础》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：CI、CD、GitHub Actions。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 持续集成与持续交付

- **CI（持续集成）**：每次提交自动构建 + 跑测试，尽早发现问题。
- **CD（持续交付/部署）**：流水线产出可发布版本，或自动部署到环境。

核心原则：**流水线要快、结果要可靠、失败要立刻可见**。

## GitHub Actions 基本结构

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

## 构建与部署示例

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

## 流水线设计建议

1. 先快后慢：lint 与单测在前，集成测试与打包在后。
2. 失败即停止，不要带病继续。
3. 构建产物只产出一次，各环境复用同一份（避免「测试的不是发布的那份」）。
4. 敏感信息只放 Secrets，绝不写进仓库。
5. 主分支保护：必须通过检查才能合并。

## 一份可直接用的完整 workflow

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
      - uses: actions/checkout@v4
      - run: docker build -t app:${{ github.sha }} .
      - run: echo "${{ secrets.REGISTRY_TOKEN }}" | docker login -u ${{ github.actor }} --password-stdin
      - run: docker push app:${{ github.sha }}
```

要点：`npm ci` 与 lock 文件保证可复现；`needs` 建立阶段依赖；镜像用 `github.sha` 做不可变标签；密钥一律走 `secrets`。缓存依赖通常能让 CI 从数分钟压缩到一分钟内。

## 本课小结
CI/CD 把「人肉发布流程」变成可重复的自动化脚本；最小可用版本就是**检出代码 → 装依赖 → 跑测试 → 构建产物**。


## GitHub Actions 速查

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
      - uses: actions/checkout@v4
      - run: npm ci && npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/
```

## 流水线设计速查

| 阶段 | 目标 | 建议 |
| --- | --- | --- |
| 快速反馈 | 秒级发现问题 | 先跑格式与 lint，再跑单元测试 |
| 构建 | 产出不可变制品 | 只构建一次，后续环境复用同一产物 |
| 集成测试 | 验证跨组件 | 用容器起依赖，测试可重复 |
| 安全扫描 | 依赖漏洞与密钥 | 依赖扫描、SAST、密钥扫描接入门禁 |
| 部署 | 灰度到全量 | 先 staging 再生产，带自动回滚条件 |
| 观测 | 部署后验证 | 关注错误率与关键业务指标 |

## 常见错误对照表

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

## 自测清单

- [ ] PR 触发测试，合并前必须通过门禁。
- [ ] 构建一次，多环境复用同一制品。
- [ ] 依赖缓存 key 包含 lock 文件哈希。
- [ ] secrets 只通过环境变量注入，绝不写入日志。
- [ ] 部署配有健康检查与回滚条件。

## 动手练习


> 本课练习重点：围绕「CI、CD、GitHub Actions」完成复述、实验和交付，每个结果都要能被别人检查。

先在临时环境执行完整命令链，再模拟失败，最后验证回滚和清理。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「CI/CD 与 GitHub Actions」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「CD」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

在一个临时目录或本地仓库执行完整命令链，并记录失败时的回滚办法。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「CI」和「CD」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：持续集成（CI）的核心目的是？

- **正确判断**：每次提交自动构建与测试
- **判断依据**：CI 让问题在提交后几分钟内暴露，而不是等到发布前。其他选项：CI 不会减少代码量、不自动写文档，也不能替代代码评审。它通过每次提交自动构建与测试，让问题尽早暴露。正确项「每次提交自动构建与测试」正面回答了题目所问，符合课程给出的定义与适用范围。把题干「持续集成（CI）的核心目的是？」放回《CI/CD 与 GitHub Actions》的「流水线结构、缓存、密钥与构建部署实践」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 2：GitHub Actions 中 secrets 用于？

- **正确判断**：存放加密的敏感配置
- **判断依据**：令牌、密码等敏感信息放 secrets，通过 ${{ secrets.X }} 引用，不能写进仓库。 其他选项：缓存依赖用 cache，job 依赖用 needs，运行环境由 runs-on 指定；secrets 专用于存放加密的敏感配置，并以变量方式引用。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 3：job 中使用 needs 关键字的作用是？

- **正确判断**：声明依赖的 job，等待其完成
- **判断依据**：needs 建立 job 之间的依赖顺序，例如测试通过后再构建部署。其他选项：指定 runner 用 runs-on，启用缓存用 cache 步骤，安装依赖是普通步骤。needs 用来声明 job 之间的依赖顺序。正确项「声明依赖的 job，等待其完成」描述正确，能够解释题干场景中的现象与结果。错误项「安装依赖包」在边界或失败路径上会得出错误结果。把题干「job 中使用 needs 关键字的作用是？」放回《CI/CD 与 GitHub Actions》的「流水线结构、缓存、密钥与构建部署实践」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：CI 中配置依赖缓存的价值是？

- **正确判断**：复用已下载的依赖
- **判断依据**：缓存键要包含锁文件哈希，依赖变更时自动失效，避免用到过期缓存。其他选项：缓存不改变构建结果的安全性，不提升覆盖率，也减小不了代码体积。它复用已下载依赖，直接缩短流水线执行时间。正确项「复用已下载的依赖」与本课示例和结论一致，可以直接用于实际编码。错误项「提升测试覆盖率」只看到了表面现象，没有解释题干真正考查的机制。错误项「减少代码体积」在边界或失败路径上会得出错误结果。错误项「让构建结果更安全」把因果关系颠倒了，不能作为正确结论。把题干「CI 中配置依赖缓存的价值是？」放回《CI/CD 与 GitHub Actions》的「流水线结构、缓存、密钥与构建部署实践」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：把测试拆成多个并行 job 的代价是？

- **正确判断**：需要额外传递构建产物
- **判断依据**：并行度、缓存与制品传递策略共同决定流水线的总时长。其他选项：并行拆分本身就是为了能并行，也不会降低测试准确性，自建 Runner 并非必需。代价在于制品传递与每个 job 都要准备环境。正确项「需要额外传递构建产物」是该问题的规范说法，换成其他表述都会丢失条件。错误项「必须使用自建 Runner」把因果关系颠倒了，不能作为正确结论。错误项「无法并行执行」忽略了题目中的限制条件，因此不成立。把题干「把测试拆成多个并行 job 的代价是？」放回《CI/CD 与 GitHub Actions》的「流水线结构、缓存、密钥与构建部署实践」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「持续集成（CI）的核心目的是？」的判断依据。
- [ ] 不看解析，能说出「GitHub Actions 中 secrets 用于？」的判断依据。
- [ ] 不看解析，能说出「job 中使用 needs 关键字的作用是？」的判断依据。
- [ ] 不看解析，能说出「CI 中配置依赖缓存的价值是？」的判断依据。
- [ ] 不看解析，能说出「把测试拆成多个并行 job 的代价是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** CI/CD & GitHub Actions

**Summary:** Pipelines, caching, secrets and deployment.

**Category:** Toolchain  
**Level:** 进阶  
**Key terms:** CI, CD, GitHub Actions, workflow, secrets

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：Git / Docker / Kubernetes / CI 平台
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：CI、CD、GitHub Actions、workflow、secrets
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Git 文档](https://git-scm.com/doc) | 版本控制与协作 |
| [Docker 文档](https://docs.docker.com/) | 容器与镜像 |
| [Kubernetes 文档](https://kubernetes.io/docs/) | 编排与运维 |

> 本课主题：流水线结构、缓存、密钥与构建部署实践。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

