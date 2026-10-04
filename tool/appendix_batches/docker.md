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
