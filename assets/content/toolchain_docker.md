# Docker 容器基础

![Docker 容器基础](images/category_docker.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「Docker 容器基础」解决了什么问题，而不是只背术语。
- 能说清 「Docker」、「容器」、「镜像」、「Dockerfile」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「工具链」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：镜像、容器、Dockerfile 与数据卷。

## 前置知识

- 先完成上一课《调试与日志》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：Docker、容器、镜像。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 容器与虚拟机

| 对比 | 虚拟机 | 容器 |
| --- | --- | --- |
| 隔离级别 | 硬件虚拟化，各自一套内核 | 进程级隔离，共享宿主内核 |
| 启动速度 | 秒到分钟 | 毫秒到秒 |
| 体积 | GB 级 | MB 级 |
| 典型实现 | VMware、KVM | Docker、containerd |

容器打包的是**应用 + 依赖 + 运行时**，因此「在我机器上能跑」的问题基本消失。

## 核心概念

- **镜像（image）**：只读模板，分层存储。
- **容器（container）**：镜像的运行实例，可读写最上层。
- **仓库（registry）**：存放镜像，如 Docker Hub。
- **卷（volume）**：持久化数据，独立于容器生命周期。

## 常用命令

```bash
docker build -t myapp:1.0 .        # 构建镜像
docker run -d -p 8080:80 myapp:1.0 # 后台运行并映射端口
docker ps                          # 查看运行中的容器
docker logs -f <container>         # 查看日志
docker exec -it <container> sh     # 进入容器
docker stop <container> && docker rm <container>
docker images && docker rmi <image>
docker volume create data          # 创建数据卷
```

## Dockerfile

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

最佳实践：

1. 使用多阶段构建，减小最终镜像体积。
2. 先复制依赖清单再复制源码，充分利用构建缓存。
3. 用 `.dockerignore` 排除 `node_modules`、`.git`、构建产物。
4. 容器内不要用 root 运行，加 `USER` 指令。
5. 一个容器一个进程，日志输出到 stdout。

## 数据与网络

```bash
docker run -v mydata:/var/lib/mysql mysql:8     # 挂载数据卷
docker network create app-net                   # 自定义网络
docker run --network app-net --name db mysql:8
```

同一自定义网络中的容器可以用容器名互相访问（DNS 解析）。

## 多阶段构建的体积对比

以一个 Node 前端项目为例：

| 构建方式 | 镜像内容 | 典型体积 |
| --- | --- | --- |
| 单阶段（node 基础镜像 + 源码 + node_modules） | 编译工具链与源码全带上 | 900 MB ~ 1.2 GB |
| 多阶段（builder 编译 + nginx 托管 dist） | 只留静态产物与 nginx | 25 ~ 50 MB |
| 多阶段 + Alpine 基础镜像 | 更小的基础层 | 15 ~ 25 MB |
| 多阶段 + distroless/scratch（Go/Rust 静态二进制） | 仅二进制与证书 | 5 ~ 20 MB |

体积下降带来的直接收益：拉取更快（CI 与扩容更快）、攻击面更小（无包管理器与 shell）、镜像仓库成本更低。

## 构建缓存与层顺序

Docker 按层缓存，**只要某一层内容变化，其后所有层都会失效**。因此顺序应当从「最稳定」到「最易变」：

1. `FROM` 基础镜像
2. 复制依赖清单（package.json / go.mod / requirements.txt）
3. 安装依赖（这一步能被长期缓存）
4. 复制源码
5. 构建/编译

反例：先 `COPY . .` 再 `npm install`，任何一次源码改动都会导致依赖重新下载。

## 常用排查命令

| 问题 | 命令 |
| --- | --- |
| 镜像为什么这么大 | `docker history <image>` 逐层看体积 |
| 容器为什么起不来 | `docker logs <container>`，再看 `docker inspect` 的退出码 |
| 构建为什么慢 | 构建输出看哪一步没命中缓存 |
| 容器里没有工具排查 | 用 `docker exec` 进临时调试容器，或临时改用 alpine 版本 |

## Docker Compose：多容器编排

Compose 用一个 YAML 描述多容器应用，适合本地开发与单机部署：

| 顶层字段 | 作用 |
| --- | --- |
| services | 各容器（镜像/构建、端口、环境变量、依赖） |
| volumes | 命名卷，保证数据在容器重建后仍存在 |
| networks | 自定义网络，容器可用服务名互相访问 |
| configs / secrets | 挂载配置与敏感信息，避免写进镜像 |

关键实践：

1. 用 `depends_on` 配 `condition: service_healthy` 等待依赖就绪，而不是固定 sleep。
2. 给数据库配 healthcheck（如 `pg_isready`），否则应用会先于数据库启动而崩溃。
3. 环境变量用 `.env` 文件，敏感值不入库；`.env.example` 提供模板。
4. 开发用 `docker compose up -d`，只重建变更服务用 `up -d --build <service>`。
5. 生产单机可用 Compose，多机与自动扩缩容才需要 Kubernetes。

常见坑：容器内用 `localhost` 连不到其他服务（应使用服务名）；卷没配导致数据丢失；`ports` 与 `expose` 混淆（前者对宿主开放，后者仅容器间可见）。

## 本课小结
Docker 的三件套是**镜像（怎么打包）、容器（怎么运行）、卷与网络（数据与通信）**；配合 Compose 可以一条命令启动多容器应用。

<!-- appendix:v1 -->

## Dockerfile 指令速查

| 指令 | 作用 | 最佳实践 |
| --- | --- | --- |
| `FROM` | 指定基础镜像 | 固定具体标签（如 `python:3.12-slim`），避免 `latest` |
| `WORKDIR` | 设置工作目录 | 后续指令都在该目录执行 |
| `COPY` | 复制文件进镜像 | 先复制依赖清单，再复制源码，充分利用缓存 |
| `RUN` | 构建期执行命令 | 多条命令用 `&&` 合并，结尾清理缓存 |
| `ENV` | 设置环境变量 | 不要在镜像里写密钥 |
| `ARG` | 构建参数 | 只用于构建期，不进入运行时环境 |
| `EXPOSE` | 声明端口 | 只是文档性声明，真正映射用 `-p` |
| `USER` | 切换运行用户 | 生产镜像应使用非 root 用户 |
| `VOLUME` | 声明数据卷 | 需要持久化的目录放在这里 |
| `ENTRYPOINT` | 固定入口 | 常与 `CMD` 配合：入口固定，参数可覆盖 |
| `CMD` | 默认命令或参数 | 用 exec 形式 `["sh", "-c", "..."]` |
| `HEALTHCHECK` | 健康检查 | 配合编排系统自动重启 |
| `ONBUILD` | 延迟触发指令 | 现在普遍不推荐使用 |

## 常用命令速查

| 目的 | 命令 |
| --- | --- |
| 构建镜像 | `docker build -t app:1.0 .` |
| 查看镜像分层 | `docker history app:1.0` |
| 运行并映射端口 | `docker run -d -p 8080:80 --name app app:1.0` |
| 进入容器 | `docker exec -it app sh` |
| 查看日志 | `docker logs -f --tail 200 app` |
| 查看资源占用 | `docker stats` |
| 查看容器详情 | `docker inspect app` |
| 清理无用资源 | `docker system prune -a` |
| 保存与加载镜像 | `docker save` / `docker load` |
| 多阶段构建 | `FROM builder AS build` 后 `COPY --from=build /app/out .` |

```dockerfile
# 多阶段构建：产物只保留运行时依赖，镜像更小
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
USER nginx
```

## 镜像瘦身速查

| 手段 | 效果 | 说明 |
| --- | --- | --- |
| 换 slim / alpine 基础镜像 | 显著减小 | 注意 glibc 与 musl 差异 |
| 多阶段构建 | 只保留运行产物 | 编译工具链不进最终镜像 |
| 合并 `RUN` 并清理缓存 | 减少层数与体积 | `apt-get clean`、删 `pip` 缓存 |
| 使用 `.dockerignore` | 避免把无关文件打进上下文 | 排除 `.git`、`node_modules`、测试数据 |
| 固定依赖版本 | 构建可复现 | 用 lock 文件（`npm ci`、`poetry install`） |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `COPY . .` 写在安装依赖之前 | 改一行代码就要重装依赖 | 先复制依赖清单并安装，再复制源码 |
| 容器里跑多个前台进程 | 只有一个能收到信号 | 一个容器一个主进程，用 `exec` 或进程管理器 |
| 数据写在容器可写层 | 重建容器后数据丢失 | 挂载卷（volume）持久化 |
| 用 `latest` 标签 | 不同时间构建结果不一致 | 固定版本标签或摘要（digest） |
| 镜像里写数据库密码 | 泄漏，且无法轮换 | 用环境变量、Secret 或密钥服务注入 |
| 以 root 运行应用 | 安全风险高 | `USER` 切到非特权用户 |
| 容器内时区为 UTC | 日志时间与业务时区不一致 | 设置 `TZ` 或挂载 `/etc/localtime` |
| 用 `docker exec` 改容器内文件 | 重建即丢失，且与镜像不一致 | 改 Dockerfile 重新构建 |
| 容器频繁重启却不看退出码 | 无法定位问题 | `docker inspect` 看 `ExitCode`，`docker logs` 看原因 |
| 依赖容器间 `localhost` 互访 | 连不上 | 同一网络内用服务名（compose 的 service name） |
| 忘记 `.dockerignore` | 构建上下文巨大、构建慢 | 排除无关文件，加速传输与缓存 |

## 自测清单

- [ ] 能写出利用层缓存的多阶段 Dockerfile。
- [ ] 知道容器内数据要用卷持久化。
- [ ] 生产镜像使用非 root 用户并固定基础镜像版本。
- [ ] 会用 `docker logs`、`docker inspect`、`docker stats` 排查问题。
- [ ] 配置了 `.dockerignore` 与依赖 lock 文件。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「Docker、容器、镜像」完成复述、实验和交付，每个结果都要能被别人检查。

先在临时环境执行完整命令链，再模拟失败，最后验证回滚和清理。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「Docker 容器基础」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「容器」是什么关系？

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
- 至少覆盖「Docker」和「容器」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Docker Basics

**Summary:** Images, containers, Dockerfile and volumes.

**Category:** Toolchain  
**Level:** 进阶  
**Key terms:** Docker, 容器, 镜像, Dockerfile, volume

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：Git / Docker / Kubernetes / CI 平台
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Docker、容器、镜像、Dockerfile、volume
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- p2-references:v1 -->

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

> 本课主题：镜像、容器、Dockerfile 与数据卷。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

