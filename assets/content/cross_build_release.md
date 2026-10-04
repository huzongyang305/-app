# 构建与发布产物：九种生态横向对照

![构建与发布产物：九种生态横向对照](images/category_cross_build_release.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：20 分钟

## 学习目标

- 能用自己的话解释「构建与发布产物：九种生态横向对照」解决了什么问题，而不是只背术语。
- 能说清 「构建」、「制品」、「可复现」、「发布」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「跨语言对照」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：各生态的产物形态、构建流水线、可复现构建与体积优化。

## 前置知识

- 先完成上一课《包管理与依赖：九种生态横向对照》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：构建、制品、可复现。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 一句话说清

构建负责把源码变成**可分发的产物**，发布负责把产物**送到目标环境**。
各生态的产物形态不同，但「构建一次、处处复用」的原则完全相同。

## 产物形态对照

| 语言 | 构建命令 | 典型产物 | 运行方式 |
| --- | --- | --- | --- |
| Python | `python -m build` | `.whl` / `.tar.gz` | `pip install` 后运行模块 |
| JavaScript | `npm run build` | `dist/` 目录 | Node 或浏览器加载 |
| TypeScript | `tsc` / `tsup` | `.js` + `.d.ts` | 同 JavaScript，类型另发 |
| Java | `mvn package` / `gradle build` | `.jar` / `.war` | `java -jar` |
| C# | `dotnet publish` | 目录 + `.dll` | `dotnet App.dll` |
| C++ | `cmake --build` | 可执行文件 / `.so` | 直接运行 |
| Go | `go build` | 单个静态可执行文件 | 直接运行 |
| Rust | `cargo build --release` | 单个可执行文件 | 直接运行 |
| Shell | 无需编译 | 脚本本身 | `bash script.sh` |

## 一张图看懂构建流水线

```text
源码 + 依赖
     │
     ▼
① 依赖安装（按锁文件）           ← 保证可复现
     │
     ▼
② 静态检查（lint / 类型检查）    ← 提前发现问题
     │
     ▼
③ 单元测试                      ← 快速反馈
     │
     ▼
④ 编译 / 打包                   ← 产出制品
     │
     ▼
⑤ 制品打标签（commit SHA）       ← 可追溯
     │
     ▼
⑥ 归档 / 推送到制品库
     │
     ▼
⑦ 部署到各环境（复用同一制品）
```

## 开发模式与生产模式的区别

| 维度 | 开发模式 | 生产模式 |
| --- | --- | --- |
| 目标 | 改完立刻看到效果 | 体积小、启动快、可观测 |
| 优化 | 关闭（便于调试） | 开启（`-O2`、`--release`） |
| 类型检查 | 编辑器里即可 | CI 强制 |
| 源码映射 | 完整 | 上传到错误监控，不公开 |
| 日志级别 | debug | info 或 warn |
| 环境变量 | 本地值 | 密钥服务注入 |

```bash
# C++：Debug 与 Release 都要测
cmake -S . -B build/debug -DCMAKE_BUILD_TYPE=Debug
cmake -S . -B build/release -DCMAKE_BUILD_TYPE=Release

# Rust：发布构建会自动开启优化
cargo build --release

# Go：交叉编译 + 去掉符号表
CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o app
```

## 制品命名的通用规则

```text
推荐：app-1.4.2-a1b2c3d.tar.gz
      │    │     └── commit SHA 前 7 位，可追溯
      │    └──────── 语义化版本
      └───────────── 应用名

不推荐：app-latest.tar.gz
      「latest」无法追溯，也无法判断回滚到哪一版
```

## 可复现构建的三个条件

```text
1. 依赖可复现：使用锁文件与固定基础镜像
2. 环境可复现：版本、编译参数、时区都显式声明
3. 产物可追溯：制品带 commit SHA 与构建时间
```

```dockerfile
# 固定基础镜像的精确版本，不用 latest
FROM node:22.11.0-alpine3.20 AS build
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:22.11.0-alpine3.20
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
USER node
CMD ["node", "dist/index.js"]
```

## 各生态的常见体积优化

| 生态 | 手段 |
| --- | --- |
| JavaScript / TS | 代码分割、tree shaking、压缩、按需引入 |
| Java | 精简依赖、使用 jlink 或分层镜像 |
| C# | 裁剪（trim）、AOT、ReadyToRun |
| C++ | `-O2 -s`、strip 符号、链接时优化 LTO |
| Go | `-ldflags "-s -w"`、`CGO_ENABLED=0` |
| Rust | `opt-level`、`lto`、`strip`、`panic=abort` |
| Python | 只装生产依赖、用 slim 基础镜像 |

## 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 每个环境各构建一次 | 测试的不是发布的 | 构建一次，处处复用 |
| 制品名用 latest | 无法追溯与回滚 | 用版本加 commit SHA |
| 基础镜像用 latest | 今天能跑明天不行 | 固定到精确版本 |
| 只在 Release 测 | Debug 特有的问题漏掉 | 两种配置都测 |
| 把源码映射公开 | 泄露源码 | 只上传到监控平台 |
| 产物里带调试依赖 | 体积与风险变大 | 只打包运行时依赖 |
| 忘了剥离符号 | 体积大 | 发布构建开启 strip |
| 构建脚本依赖个人环境 | 换机器就失败 | 容器化构建 |

## 本课小结
- 构建的核心是**可复现**：依赖、环境、产物三件事都固定下来。
- 发布的铁律是**只构建一次**，各环境复用同一份制品。
- 制品名要能回答两个问题：这是哪个版本、对应哪次提交。

<!-- appendix:v4 -->

## 补充：制品矩阵、构建缓存与可复现验证

### 各生态的制品矩阵

| 语言 | 发布到仓库 | 本地部署 | 容器内运行 |
| --- | --- | --- | --- |
| Python | wheel（`.whl`） | 虚拟环境 + `.whl` | 基础镜像 + 依赖层 |
| JavaScript | npm 包 | `dist/` + node_modules | 多阶段构建产物层 |
| TypeScript | npm 包（JS + `.d.ts`） | 同上 | 同上 |
| Java | jar 上传私服 | 可执行 jar | JRE 基础镜像 |
| C# | NuGet 包 | `publish` 目录 | ASP.NET 运行时镜像 |
| C++ | 无标准仓库 | 可执行文件 / `.so` | 最小运行时镜像 |
| Go | 模块代理 | **单个静态二进制** | `scratch` 镜像 |
| Rust | crates.io | 单个二进制 | `scratch` 镜像 |
| Shell | 无 | 脚本 + 依赖说明 | 含 shell 的基础镜像 |

```text
两种发布形态的选择
  · 二进制 / 静态可执行：启动快、依赖少、镜像最小（Go、Rust）
  · 中间码 / 解释执行：跨平台方便、可热更新（Java、Python）
```

### 构建缓存的四层

| 层级 | 缓存什么 | 失效条件 |
| --- | --- | --- |
| 依赖缓存 | 下载的包 | 锁文件变化 |
| 编译缓存 | 目标文件 / 增量信息 | 源码或编译参数变化 |
| 镜像层缓存 | Docker 每一层 | 该层指令或其输入变化 |
| 任务缓存 | 整个构建任务的输出 | 输入哈希变化（Turbo、Bazel） |

```dockerfile
# 正确顺序：先装依赖（变化少），再拷源码（变化多）
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile      # 这一层只有锁文件变了才重建
COPY . .
RUN pnpm build                          # 源码改了才重建
```

```text
反例：先 COPY . 再装依赖
  任何源码改动都会让依赖层失效 → 每次都重新下载依赖
```

### 可复现构建怎么验证

```bash
# 方法一：两次构建对比哈希
docker build -t app:run1 .
docker build --no-cache -t app:run2 .
docker inspect --format='{{.Id}}' app:run1
docker inspect --format='{{.Id}}' app:run2
# 两个 Id 相同说明构建可复现（需固定时间戳与排序）

# 方法二：对比构建产物的哈希
sha256sum dist/app.js
```

```text
破坏可复现的四个常见原因
  · 基础镜像用了 latest
  · 构建时写入时间戳或随机版本号
  · 文件遍历顺序不稳定（未排序）
  · 依赖版本范围过宽且未锁
```

### 制品签名与来源证明

| 手段 | 作用 |
| --- | --- |
| 镜像签名（cosign） | 证明镜像由可信流程构建 |
| SBOM（软件物料清单） | 列出全部依赖及版本，便于漏洞排查 |
| SLSA 级别 | 描述构建流程的防篡改程度 |
| 制品哈希归档 | 发布后校验，防止被替换 |

```bash
# 生成 SBOM 并签名的典型流水线
syft packages dir:. -o spdx-json > sbom.json
cosign sign --key cosign.key registry.example.com/app:${GIT_SHA}
cosign attach sbom --sbom sbom.json registry.example.com/app:${GIT_SHA}
```

### 一次完整的发布流水线

```text
① 按锁文件装依赖（缓存命中）
② 静态检查 + 类型检查
③ 测试（单元 + 集成）
④ 构建制品（用 commit SHA 打标签）
⑤ 生成并附加 SBOM
⑥ 签名并推送制品库
⑦ 部署预发 → 冒烟测试 → 灰度 → 全量

全程只构建一次，各环境复用同一份制品
```

### 自查清单

- [ ] 依赖安装在 COPY 源码之前，缓存生效
- [ ] 基础镜像固定到精确版本
- [ ] 验证过两次构建产物一致（可复现）
- [ ] 制品带 commit SHA 标签并签名
- [ ] 生成 SBOM 以便漏洞追溯

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「构建、制品、可复现」完成复述、实验和交付，每个结果都要能被别人检查。

用两种语言实现同一行为，再对比语法、错误、性能和生态差异。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「构建与发布产物：九种生态横向对照」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「制品」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

选两种语言实现同一行为，列出语法、错误处理、性能和生态差异。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「构建」和「制品」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Build and Release Artifacts

**Summary:** Artifact types, pipelines, reproducible builds and size tuning.

**Category:** Cross-Language Comparison  
**Level:** 进阶  
**Key terms:** 构建, 制品, 可复现, 发布, 体积优化

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：九种主流语言生态横向对照
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：构建、制品、可复现、发布、体积优化
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [DevDocs](https://devdocs.io/) | 多语言 API 快速检索 |
| [官方语言文档](https://developer.mozilla.org/docs/Web) | 跨语言语义对照 |

> 本课主题：各生态的产物形态、构建流水线、可复现构建与体积优化。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

