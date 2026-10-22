## 零基础详解：容器里的 shell 脚本

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
