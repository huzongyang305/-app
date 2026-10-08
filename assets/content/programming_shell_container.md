# Shell 与 Docker/K8s 交互

![Shell 脚本在容器与集群中的位置](images/diagram_shell_container.webp)

![Shell 与 Docker/K8s 交互](images/remaining_shell_container.webp)

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：50 分钟

## 本节知识框架

**课程定位**：所属分类为「Shell」，课程主题为「Shell 与 Docker/K8s 交互」，学习阶段为「基础」，建议用时 50 分钟。

**本课要解决的主问题**：镜像标签、entrypoint 要点与 kubectl 排查顺序。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「Shell 与 Docker/K8s 交互」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「Shell 与 Docker/K8s 交互」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「Shell」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《Shell 脚本工程化》

**学习位置**：本课位于《Shell 脚本工程化》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《文本处理进阶：awk、sed 与正则》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释Shell 与 Docker/K8s 交互解决了什么问题，而不是只背术语。
- 能说清 「Shell」、「Docker」、「Kubernetes」、「entrypoint」 之间的关系，并分别举出一个例子。
- 能把 Shell 放回「Shell 与 Docker/K8s 交互」的知识体系，说明它和 Docker 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：镜像标签、entrypoint 要点与 kubectl 排查顺序。

**教材衔接：前置知识**

- 先完成上一课《Shell 脚本工程化》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议先完成「Shell 脚本工程化」，或确认自己能独立跑通正文里的 wait_for 示例。
- 开始前先复习：Shell、Docker、Kubernetes。
- 卡在 Shell 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

**教材衔接：本课小结**

Shell 与容器的结合点是**可重复的构建/部署/排查流程**：镜像用不可变标签、entrypoint 用 exec 传递信号、排查按 get→describe→logs→exec 顺序进行。

## 核心概念定义

> 阅读约定：本课先给「Shell 与 Docker/K8s 交互」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| Docker | 把应用及依赖封装成镜像并在容器中运行的平台。 | 仅在「Shell 与 Docker/K8s 交互」明确给出的输入、版本与资源条件下成立。 |
| Kubernetes | 开始前先复习：Shell、Docker、Kubernetes。 | 仅在「Shell 与 Docker/K8s 交互」明确给出的输入、版本与资源条件下成立。 |
| 健康检查 | 周期性探测进程或依赖是否可服务，并据此摘除或重启实例。 | 仅在「Shell 与 Docker/K8s 交互」明确给出的输入、版本与资源条件下成立。 |
| 镜像分层 | 每条 Dockerfile 指令生成一层并被缓存，把少变的依赖放前面能显著加快构建。 | 仅在「Shell 与 Docker/K8s 交互」明确给出的输入、版本与资源条件下成立。 |
| Shell | 接收命令并调用操作系统程序的命令行解释器与脚本环境 | 仅在「Shell 与 Docker/K8s 交互」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「Shell 与 Docker/K8s 交互」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「Docker」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「Kubernetes」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「健康检查」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「Shell 与 Docker/K8s 交互」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | Docker | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | Kubernetes | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 健康检查 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「Shell 与 Docker/K8s 交互」自己的示例验证。「Shell 与 Docker/K8s 交互」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：容器内的 entrypoint 脚本**

要点：① 用 `exec "$@"` 让主进程成为 PID 1，才能正确接收信号；② 用 `set -euo pipefail`；③ 等待依赖（数据库）时用循环 + 超时，而不是固定 sleep；④ 不在 entrypoint 里做需要人工确认的破坏性操作。

**教材衔接：健康检查与就绪脚本**

在容器里写一个 healthcheck 脚本：检查进程存活、端口可连、关键依赖可用，返回 0/1。区分 liveness（失败重启）与 readiness（失败摘流量）——**依赖不可用时只应影响 readiness**，避免全量重启引发雪崩。

**教材衔接：Kubernetes 交互速查**

| 目的 | 命令 |
| --- | --- |
| 查看 Pod 列表 | `kubectl get pods -n prod -o wide` |
| 查看事件 | `kubectl describe pod <name>` |
| 查看日志 | `kubectl logs -f <pod> -c <container> --tail=200` |
| 进入容器 | `kubectl exec -it <pod> -- sh` |
| 拷贝文件 | `kubectl cp <pod>:/path ./local` |
| 端口转发 | `kubectl port-forward svc/api 8080:80` |
| 查看资源占用 | `kubectl top pod` |
| 触发滚动重启 | `kubectl rollout restart deploy/api` |
| 查看发布状态 | `kubectl rollout status deploy/api` |
| 回滚 | `kubectl rollout undo deploy/api` |

**教材衔接：版本与时效**

- 版本提示：Shell 的行为在最近几个大版本里有过调整，升级「Shell 与 Docker/K8s 交互」前先用 wait_for 复现当前输出，再对照官方发布说明逐条核对。
- 升级前先用 wait_for 建立基线：记录版本、命令和输出，升级后只比较这些可观察量。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改 Shell 的版本变量，记录编译、测试与产物体积的变化。
- 先回归 Shell 与 Docker 的默认行为和错误信息，再扩大测试范围。
- 升级后把 wait_for 的实测版本写进「内容元数据」，再更新复核日期。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 Shell、Docker | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「Shell 与 Docker/K8s 交互」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「Shell 与 Docker/K8s 交互」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:bash`，用于动手验证《Shell 与 Docker/K8s 交互》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《Shell 与 Docker/K8s 交互》原文中的最小示例。先预测《Shell 与 Docker/K8s 交互》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```text
kubectl get pods -o wide                  # 状态与节点
kubectl describe pod <name>               # 事件（调度/镜像/探针失败）
kubectl logs -f <pod> --tail=200          # 日志
kubectl exec -it <pod> -- sh              # 进入容器
kubectl rollout status deploy/app         # 观察滚动更新
kubectl rollout undo deploy/app           # 回滚
kubectl port-forward svc/app 8080:80      # 本地调试
```

**教材衔接：常用 Docker 命令脚本化**

| 场景 | 命令要点 |
| --- | --- |
| 构建 | `docker build -t app:$GIT_SHA .`，用提交号做标签便于回滚 |
| 运行 | `docker run -d --name app -p 8080:8080 --env-file .env app:$SHA` |
| 查看 | `docker logs -f --tail 100 app`、`docker stats` |
| 进容器 | `docker exec -it app sh`（生产容器通常不带 bash） |
| 清理 | `docker system prune -f`（谨慎，先 `docker ps -a` 确认） |

脚本里要判断容器是否存在（`docker ps -aq -f name=app`），并处理"已存在则先删"的逻辑；退出码检查不可省。

**教材衔接：kubectl 常用操作**

```text
kubectl get pods -o wide                  # 状态与节点
kubectl describe pod <name>               # 事件（调度/镜像/探针失败）
kubectl logs -f <pod> --tail=200          # 日志
kubectl exec -it <pod> -- sh              # 进入容器
kubectl rollout status deploy/app         # 观察滚动更新
kubectl rollout undo deploy/app           # 回滚
kubectl port-forward svc/app 8080:80      # 本地调试
```

排查顺序固定：`get`（看状态）→ `describe`（看事件）→ `logs`（看应用日志）→ `exec`（进容器验证）。

**教材衔接：容器脚本速查**

| 场景 | 推荐写法 |
| --- | --- |
| 启动主进程 | 脚本末尾 `exec "$@"`，让主进程成为 PID 1 |
| 等待依赖就绪 | 循环探测 + 超时 + 退出码，不在 entrypoint 里无限阻塞 |
| 初始化数据 | 幂等判断（已存在则跳过） |
| 配置模板 | `envsubst` 渲染模板到临时目录再启动 |
| 信号处理 | 用 `exec` 或 `tini` / `--init` 代理信号 |
| 日志 | 输出到 stdout / stderr，由容器运行时收集 |
| 时区 | 通过环境变量 `TZ` 或挂载 `/etc/localtime` |
| 用户权限 | 以非 root 运行，需要写权限的目录提前 chown |

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# 若以 root 启动且挂载了数据卷，先把属主改好再降权
if [[ "$(id -u)" == "0" ]]; then
  chown -R app:app /data /var/log/myapp
  exec gosu app "$0" "$@"        # 降权后重新执行自己
fi

wait_for() {
  local host="$1" port="$2" timeout="${3:-30}"
  local start=$SECONDS
  until (echo > "/dev/tcp/${host}/${port}") 2>/dev/null; do
    (( SECONDS - start < timeout )) || {
      echo "等待 ${host}:${port} 超时" >&2
      return 1
    }
    sleep 1
  done
}

# 仅对初始化类容器等待依赖；业务容器交给编排的重试与探针
if [[ "${WAIT_FOR_DB:-0}" == "1" ]]; then
  wait_for "${DB_HOST:?}" "${DB_PORT:-5432}" "${DB_TIMEOUT:-30}"
fi

mkdir -p /var/log/myapp

exec "$@"                          # 交给主进程，正确接收 SIGTERM
```

**教材衔接：零基础详解：容器里的 shell 脚本**

### 一句话说清它是什么

容器里的启动脚本有两个特殊任务：**把主进程交给应用（exec）**、**配合探针让编排系统正确判断健康状态**。
做错了就会出现「kill 没反应」「重启风暴」「流量打到没准备好的实例」。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| PID 1 | 值班负责人 | 要负责收信号、带新人 |
| `exec` | 交班 | 把自己换成应用进程，成为 PID 1 |
| liveness | 体检 | 不过关就重启 |
| readiness | 上岗证 | 不过关只摘流量，不重启 |
| distroless | 无工具车间 | 镜像里没有 shell，排查要靠日志与指标 |

### entrypoint 脚本的正确写法

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. 准备工作：等待依赖、建目录
if [[ -n "${WAIT_FOR:-}" ]]; then
  until pg_isready -h "$WAIT_FOR" -p 5432 >/dev/null 2>&1; do
    echo "等待数据库 $WAIT_FOR …"
    sleep 1
  done
fi

mkdir -p /app/tmp

# 2. 交班：让应用成为 PID 1，正确接收 SIGTERM
exec "$@"
```

对应 Dockerfile：

```dockerfile
FROM python:3.13-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN chmod +x docker/entrypoint.sh
ENTRYPOINT ["/app/docker/entrypoint.sh"]
CMD ["python", "-m", "app"]
```

**关键点**：用 exec 形式（方括号数组），不要用 shell 形式（`CMD python -m app`），否则信号传不到应用。

### 没有 exec 会发生什么

```text
错误：sh 是 PID 1，python 是它的子进程
kubectl delete pod → 发送 SIGTERM 给 sh → sh 不转发 → 超时后被 SIGKILL
结果：请求被硬中断，数据可能丢失，每次发布都要等 30 秒
```

### 三种探针的分工

| 探针 | 失败后果 | 用来检查 |
| --- | --- | --- |
| `startupProbe` | 重启容器 | 启动慢的服务是否完成初始化 |
| `livenessProbe` | 重启容器 | 进程是否还活着 |
| `readinessProbe` | 只摘流量 | 是否准备好接请求 |

```yaml
readinessProbe:
  httpGet: { path: /healthz/ready, port: 8080 }
  periodSeconds: 5

livenessProbe:
  httpGet: { path: /healthz/live, port: 8080 }
  initialDelaySeconds: 15
  periodSeconds: 10
```

**依赖服务（数据库、下游接口）不可用时，应该影响 readiness，不要影响 liveness。**

### 优雅下线要做的四件事

```text
1. 收到 SIGTERM 后先停止接收新请求
2. 等在途请求处理完
3. 关闭数据库连接、刷缓冲
4. 主动退出，退出码 0
```

```yaml
terminationGracePeriodSeconds: 30
lifecycle:
  preStop:
    exec:
      command: ["/bin/sh", "-c", "sleep 5"]   # 给负载均衡摘流留时间
```

### 排查顺序：get → describe → logs → exec

```bash
kubectl get pods -o wide                 # 1. 状态、重启次数、节点
kubectl describe pod myapp-xxx           # 2. 事件：拉镜像失败、探针失败
kubectl logs myapp-xxx --previous        # 3. 崩溃前的日志
kubectl exec -it myapp-xxx -- sh         # 4. 进容器验证（镜像里得有 shell）
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 启动脚本不用 exec | 信号丢失，优雅退出失效 | 末尾 `exec "$@"` |
| 用 shell 形式的 CMD | 同上 | 用 exec 数组形式 |
| liveness 检查依赖服务 | 下游抖动引发全员重启 | 依赖放 readiness |
| 探针路径用真实业务接口 | 探测自身产生副作用 | 单独写轻量健康检查接口 |
| 忘了 `terminationGracePeriodSeconds` | 请求被硬中断 | 设成大于最长请求时间 |
| 容器里以 root 运行 | 安全风险 | 建普通用户并 `USER` 切换 |
| 脚本里写相对路径 | 工作目录不同就失败 | 显式 `cd /app` 或用绝对路径 |
| distroless 里 exec 失败 | 没有 shell | 改为只依赖日志与指标 |

### 手把手练习：完整的 entrypoint

```bash
#!/usr/bin/env bash
set -euo pipefail

log() { printf '[entrypoint] %s\n' "$*" >&2; }

cleanup() {
  log "收到退出信号，等待应用结束"
  if [[ -n "${child_pid:-}" ]]; then
    kill -TERM "$child_pid" 2>/dev/null || true
    wait "$child_pid"
  fi
}
trap cleanup TERM INT

if [[ "${ENABLE_MIGRATION:-false}" == "true" ]]; then
  log "执行数据库迁移"
  python -m app.migrate
fi

log "应用启动：$*"
exec "$@"
```

### 学完自测

- [ ] 能解释 `exec "$@"` 为什么重要。
- [ ] 能说出三种探针分别失败会发生什么。
- [ ] 知道依赖服务不可用该影响哪个探针。
- [ ] 能说出 K8s 排查的四步顺序。
- [ ] 知道为什么容器里推荐用非 root 用户。

## 时间/空间复杂度或性能分析

**复杂度证据**：「Shell 与 Docker/K8s 交互」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「Shell 与 Docker/K8s 交互」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「Shell 与 Docker/K8s 交互」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《Shell 与 Docker/K8s 交互》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「Shell 与 Docker/K8s 交互」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| entrypoint 不写 `exec` | `SIGTERM` 收不到，容器 30 秒后被强杀 | 用 `exec "$@"` |
| entrypoint 里 sleep 等依赖 | 启动慢、就绪探针失败 | 依赖交给 readiness 探针与重试 |
| 用 `kubectl exec` 改容器内文件 | 重建后丢失 | 改镜像与配置清单 |
| 容器里写日志文件 | 日志丢失、磁盘占用 | 输出到 stdout / stderr |
| 以 root 运行 | 安全风险高 | 非 root 用户 + 只读根文件系统 |
| distroless 镜像里 `kubectl exec sh` | 找不到 shell | 用 debug 容器或临时 sidecar |
| 本地时区正常、容器为 UTC | 日志时间错位 | 设置 `TZ` |
| 依赖 service 名称写成 localhost | 连接被拒 | 同一网络内用服务名 |
| 初始化脚本不幂等 | 重启后重复执行导致数据错乱 | 先检查状态再操作 |
| 用 `latest` 镜像标签 | 版本不可追溯 | 固定版本或 digest |

**教材衔接：故障现场**

### 现场 1：entrypoint 不写 exec

**症状**：在《Shell 与 Docker/K8s 交互》的复现场景中，SIGTERM 收不到，容器 30 秒后被强杀。

**根因**：当出现“entrypoint 不写 exec”时，执行路径已经绕过了《Shell 与 Docker/K8s 交互》的关键约束，最终以“SIGTERM 收不到，容器 30 秒后被强杀”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《Shell 与 Docker/K8s 交互》的问题，用 exec "$@"。

**验证**：保留《Shell 与 Docker/K8s 交互》里触发“SIGTERM 收不到，容器 30 秒后被强杀”的输入、版本和日志，按“用 exec "$@"”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 2：entrypoint 里 sleep 等依赖

**症状**：在《Shell 与 Docker/K8s 交互》的复现场景中，启动慢、就绪探针失败。

**根因**：触发点是把“entrypoint 里 sleep 等依赖”当成安全做法。它没有满足《Shell 与 Docker/K8s 交互》要求的前提，因此先表现为“启动慢、就绪探针失败”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Shell 与 Docker/K8s 交互》的问题，依赖交给 readiness 探针与重试。

**验证**：在《Shell 与 Docker/K8s 交互》中按“依赖交给 readiness 探针与重试”调整后，从“entrypoint 里 sleep 等依赖”的触发条件重放同一条路径，确认“启动慢、就绪探针失败”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 3：容器里写日志文件

**症状**：在《Shell 与 Docker/K8s 交互》的复现场景中，日志丢失、磁盘占用。

**根因**：触发点是把“容器里写日志文件”当成安全做法。它没有满足《Shell 与 Docker/K8s 交互》要求的前提，因此先表现为“日志丢失、磁盘占用”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Shell 与 Docker/K8s 交互》的问题，输出到 stdout / stderr。

**验证**：在《Shell 与 Docker/K8s 交互》中按“输出到 stdout / stderr”调整后，从“容器里写日志文件”的触发条件重放同一条路径，确认“日志丢失、磁盘占用”不再出现，并补一个相邻边界用例检查没有引入新问题。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《Shell 脚本工程化》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《文本处理进阶：awk、sed 与正则》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《Shell 脚本工程化》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《文本处理进阶：awk、sed 与正则》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「Shell 与 Docker/K8s 交互」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《Shell 与 Docker/K8s 交互》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

围绕“Shell 与 Docker/K8s 交互”中的 Shell、Docker、Kubernetes，下列哪两项是本课强调的实践判断？

A. 学习 Shell 时要同时说明输入、输出和失败路径，不能只看正常流程
B. 只要 Shell 的常规示例通过，就可以跳过边界与异常路径
C. 验证 Docker 时要固定版本并覆盖边界输入，结论才可复现
D. 把 Docker 的单次运行结果当成所有版本和规模都成立

**参考答案**：学习 Shell 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 Docker 时要固定版本并覆盖边界输入，结论才可复现

**解析**：在「Shell 与 Docker/K8s 交互」里，学习 Shell 时要同时说明输入、输出和失败路径，不能只看正常流程。在Shell 与 Docker/K8s 交互里，判断 Docker 时要固定版本与边界输入，所以“验证 Docker 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 2

依赖服务暂时不可用时，应该影响哪种探针？

A. liveness
B. readiness
C. 两者都要
D. 都不影响

**参考答案**：readiness

**解析**：在「Shell 与 Docker/K8s 交互」里，让 liveness 失败会引发全量重启。在「Shell 与 Docker/K8s 交互」里，作答时，先用Shell建立输入与输出的基线，再把readiness代入边界条件核对，结论才能复现。回到「Shell 与 Docker/K8s 交互」的正文示例，用“依赖服务暂时不可用时”走一遍Shell、Docker、Kubernetes的完整流程，能复现的结论才可以保留。

### 自测 3

阅读「Shell 与 Docker/K8s 交互」中的这段 Shell 代码，下面哪项判断最准确？

```shell
#!/usr/bin/env bash
set -euo pipefail

log() { printf '[entrypoint] %s\n' "$*" >&2; }

cleanup() {
  log "收到退出信号，等待应用结束"
  if [[ -n "${child_pid:-}" ]]; then
    kill -TERM "$child_pid" 2>/dev/null || true
    wait "$child_pid"
  fi
}
trap cleanup TERM INT

if [[ "${ENABLE_MIGRATION:-false}" == "true" ]]; then
  log "执行数据库迁移"
  python -m app.migrate
fi

log "应用启动：$*"
exec "$@"
```

A. 这段 Shell 代码只展示语法，不会读取任何输入或产生可验证输出。
B. Shell、Docker、Kubernetes 的结论只取决于关键字数量，与代码的控制流和边界条件无关。
C. 这段 Shell 代码可以跳过错误处理，因为运行成功后就不会再出现异常。
D. 镜像标签、entrypoint 要点与 kubectl 排查顺序。

**参考答案**：镜像标签、entrypoint 要点与 kubectl 排查顺序。

**解析**：在「Shell 与 Docker/K8s 交互」里，结论应落在「镜像标签、entrypoint 要点与 kubectl 排查顺序」。在「Shell 与 Docker/K8s 交互」里，结论应落在镜像标签、entrypoint 要点与 kubectl 排查顺序。在「Shell 与 Docker/K8s 交互」里，这段 Shell 代码来自本课的本地示例，主要用来核对 Shell、Docker、Kubernetes、entrypoint 之间的输入、处理和输出关系，镜像标签、entrypoint 要点与 kubectl 排查顺序。

**教材衔接：复习与自测**

- [ ] entrypoint 使用 `exec "$@"`，信号能正确传递。
- [ ] 日志输出到标准输出，由平台统一收集。
- [ ] 容器以非 root 用户运行，写权限目录提前准备。
- [ ] 初始化逻辑幂等，可安全重复执行。
- [ ] 排查问题优先用 `logs` / `describe`，不依赖容器内改文件。

**教材衔接：动手练习**

> 本课练习重点：围绕「Shell、Docker、Kubernetes」完成复述、实验和交付，每个结果都要能被别人检查。

先加严格模式，再在临时目录验证成功与失败路径，最后补回滚。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Shell 与 Docker/K8s 交互解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「Docker」是什么关系？

验收标准：回答里必须出现 Shell，并写出一个让结论失效的边界条件。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：先在「常用 Docker 命令脚本化」里找一个可运行的最小输入，再按五步法记录Shell的影响；预测与结果不一致时补写被忽略的前提。

### 练习 3：交付一个小结果（30 分钟）

用 wait_for 构造最小可运行示例，并把输出与「常用 Docker 命令脚本化」的结论对照。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Shell」和「Docker」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# 若以 root 启动且挂载了数据卷，先把属主改好再降权
if [[ "$(id -u)" == "0" ]]; then
  chown -R app:app /data /var/log/myapp
  exec gosu app "$0" "$@"        # 降权后重新执行自己
fi

wait_for() {
  local host="$1" port="$2" timeout="${3:-30}"
  local start=$SECONDS
  until (echo > "/dev/tcp/${host}/${port}") 2>/dev/null; do
    (( SECONDS - start < timeout )) || {
      echo "等待 ${host}:${port} 超时" >&2
      return 1
    }
    sleep 1
  done
}

# 仅对初始化类容器等待依赖；业务容器交给编排的重试与探针
if [[ "${WAIT_FOR_DB:-0}" == "1" ]]; then
  wait_for "${DB_HOST:?}" "${DB_PORT:-5432}" "${DB_TIMEOUT:-30}"
fi

mkdir -p /var/log/myapp

exec "$@"                          # 交给主进程，正确接收 SIGTERM
```

**预期输出**：等待 ${host}:${port} 超时

### 任务 2：只改一个条件

把「Shell 与 Docker/K8s 交互」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只调整 wait_for 的一个参数，其余条件一律不动。
- 预测：先写下「Shell 与 Docker/K8s 交互」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响Shell。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的 Shell 数据，保持输出格式与任务 1 一致。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「容器 entrypoint 脚本里为什么要用 exec "$@"？」的判断依据。
- [ ] 不看解析，能说出「依赖服务暂时不可用时，应该影响哪种探针？」的判断依据。
- [ ] 不看解析，能说出「K8s 排查问题的推荐顺序是？」的判断依据。
- [ ] 不看解析，能说出「容器里 PID 1 进程的特殊性是？」的判断依据。
- [ ] 不看解析，能说出「kubectl exec -it pod -- sh 的适用场景是？」的判断依据。
- [ ] 用 Shell 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

把「Shell 与 Docker/K8s 交互」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `Docker` | 把应用及依赖封装成镜像并在容器中运行的平台。 |
| `Kubernetes` | 开始前先复习：Shell、Docker、Kubernetes。 |
| `健康检查` | 周期性探测进程或依赖是否可服务，并据此摘除或重启实例。 |
| `镜像分层` | 每条 Dockerfile 指令生成一层并被缓存，把少变的依赖放前面能显著加快构建。 |
| `Shell` | 接收命令并调用操作系统程序的命令行解释器与脚本环境 |

## 考点精讲

### 考点 1：多选辨析·Shell

- **题目**：围绕“Shell 与 Docker/K8s 交互”中的 Shell、Docker、Kubernetes，下列哪两项是本课强调的实践判断？
- **判断依据**：在「Shell 与 Docker/K8s 交互」里，学习 Shell 时要同时说明输入、输出和失败路径，不能只看正常流程。在Shell 与 Docker/K8s 交互里，判断 Docker 时要固定版本与边界输入，所以“验证 Docker 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：概念判断·Shell

- **题目**：依赖服务暂时不可用时，应该影响哪种探针？
- **判断依据**：在「Shell 与 Docker/K8s 交互」里，让 liveness 失败会引发全量重启。在「Shell 与 Docker/K8s 交互」里，作答时，先用Shell建立输入与输出的基线，再把readiness代入边界条件核对，结论才能复现。回到「Shell 与 Docker/K8s 交互」的正文示例，用“依赖服务暂时不可用时”走一遍Shell、Docker、Kubernetes的完整流程，能复现的结论才可以保留。

### 考点 3：概念判断·Shell

- **题目**：K8s 排查问题的推荐顺序是？
- **判断依据**：在「Shell 与 Docker/K8s 交互」里，get → describe → logs → exec。先看状态与事件，再看应用日志，最后进容器验证。回到「Shell 与 Docker/K8s 交互」的正文示例，用“K8s 排查问题的推荐顺序是”走一遍Shell、Docker、Kubernetes的完整流程，能复现的结论才可以保留。

### 考点 4：代码补全·Shell

- **题目**：阅读「Shell 与 Docker/K8s 交互」中的这段 Shell 代码，下面哪项判断最准确？
- **判断依据**：在「Shell 与 Docker/K8s 交互」里，结论应落在「镜像标签、entrypoint 要点与 kubectl 排查顺序」。在「Shell 与 Docker/K8s 交互」里，结论应落在镜像标签、entrypoint 要点与 kubectl 排查顺序。在「Shell 与 Docker/K8s 交互」里，这段 Shell 代码来自本课的本地示例，主要用来核对 Shell、Docker、Kubernetes、entrypoint 之间的输入、处理和输出关系，镜像标签、entrypoint 要点与 kubectl 排查顺序。

### 考点 5：概念判断·Shell

- **题目**：kubectl exec -it pod -- sh 的适用场景是？
- **判断依据**：在「Shell 与 Docker/K8s 交互」里，进入容器内部排查问题。生产环境常使用 distroless 镜像没有 shell，此时要以日志与指标为主要手段。“kubectl”与「Shell 与 Docker/K8s 交互」的术语表相呼应，只有符合Shell、Docker、Kubernetes约束的“进入容器内部排查问题”才是正文支持的结论。

### 考点 6：填空·____: 5

- **题目**：补全代码：「Shell 与 Docker/K8s 交互」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `____: 5`
- **判断依据**：在「Shell 与 Docker/K8s 交互」里，periodSeconds。在「Shell 与 Docker/K8s 交互」里判断这道题，要把Shell、Docker、Kubernetes的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。回到「Shell 与 Docker/K8s 交互」的正文示例，用“补全代码”走一遍Shell、Docker、Kubernetes的完整流程，能复现的结论才可以保留。

## English Overview

**Title:** Shell with Containers

**Summary:** Image tags, entrypoint and kubectl troubleshooting.

**Category:** Shell
**Level:** 基础
**Key terms:** Shell, Docker, Kubernetes, entrypoint, 健康检查

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：Bash 5 / POSIX Shell；本课聚焦 Shell。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Shell、Docker、Kubernetes、entrypoint、健康检查
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [GNU Bash 手册](https://www.gnu.org/software/bash/manual/) | Bash 语法、展开与作业控制 |
| [POSIX Shell 标准](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html) | 可移植 Shell 语法 |
| [ShellCheck 文档](https://www.shellcheck.net/wiki/) | 脚本缺陷与安全写法 |

> 「Shell 与 Docker/K8s 交互」的链接用于离线阅读后的延伸核对；App 不会自动联网。
