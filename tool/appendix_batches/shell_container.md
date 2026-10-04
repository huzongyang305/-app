## 容器脚本速查

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

## Kubernetes 交互速查

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

## 常见错误对照表

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

## 自测清单

- [ ] entrypoint 使用 `exec "$@"`，信号能正确传递。
- [ ] 日志输出到标准输出，由平台统一收集。
- [ ] 容器以非 root 用户运行，写权限目录提前准备。
- [ ] 初始化逻辑幂等，可安全重复执行。
- [ ] 排查问题优先用 `logs` / `describe`，不依赖容器内改文件。
