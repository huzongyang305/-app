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

