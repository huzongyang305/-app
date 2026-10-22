## 进程管理速查

| 目的 | 命令 |
| --- | --- |
| 查看进程列表 | `ps aux`、`ps -ef` |
| 按名称查找 | `pgrep -af 'java.*app'` |
| 查看进程树 | `pstree -p <pid>` |
| 查看端口占用 | `ss -tlnp`、`lsof -i :8080` |
| 优雅停止 | `kill -TERM <pid>` |
| 强制停止 | `kill -KILL <pid>` |
| 停止一组进程 | `pkill -TERM -f 'pattern'` |
| 前台转后台 | `Ctrl+Z` 后 `bg`，或启动时加 `&` |
| 断开终端仍运行 | `nohup cmd &`，或交给 systemd |
| 等待进程结束 | `wait <pid>` |
| 限制执行时间 | `timeout 30s cmd` |
| 查看资源占用 | `top -p <pid>`、`pidstat -p <pid> 1` |

停止服务的推荐顺序：先发 `SIGTERM`（应用可优雅关闭），等待若干秒，仍未退出再发 `SIGKILL`。

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

readonly PID_FILE="/run/myapp.pid"

stop_app() {
  [[ -f "$PID_FILE" ]] || { echo "未找到 pid 文件"; return 0; }
  local pid
  pid="$(<"$PID_FILE")"

  if ! kill -0 "$pid" 2>/dev/null; then
    echo "进程 $pid 已不存在，清理 pid 文件"
    rm -f -- "$PID_FILE"
    return 0
  fi

  kill -TERM "$pid"                      # 先优雅停止
  for _ in {1..30}; do
    kill -0 "$pid" 2>/dev/null || { rm -f -- "$PID_FILE"; return 0; }
    sleep 1
  done

  echo "30 秒内未退出，强制结束" >&2
  kill -KILL "$pid" 2>/dev/null || true
  rm -f -- "$PID_FILE"
}

stop_app
```

## cron 速查

| 字段 | 含义 | 取值范围 |
| --- | --- | --- |
| 第 1 个 | 分钟 | 0-59 |
| 第 2 个 | 小时 | 0-23 |
| 第 3 个 | 日 | 1-31 |
| 第 4 个 | 月 | 1-12 |
| 第 5 个 | 星期 | 0-7（0 与 7 都是周日） |

```cron
# 每天 02:30 备份
30 2 * * * /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1

# 每 5 分钟检查一次
*/5 * * * * /usr/local/bin/check.sh >/dev/null 2>&1

# 工作日 9 点到 18 点每小时
0 9-18 * * 1-5 /usr/local/bin/sync.sh
```

cron 环境注意点：

| 注意点 | 说明 |
| --- | --- |
| PATH 很小 | 命令一律用绝对路径，或脚本内显式设置 PATH |
| 无交互环境 | 不要依赖 shell 配置文件（`.bashrc`） |
| 输出会发邮件 | 明确重定向到日志文件 |
| 时区 | 与服务器时区一致，跨时区要显式换算 |
| 并发 | 用锁文件防止上一次未结束又启动 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 直接用 `kill -9` | 数据未落盘、连接未释放 | 先 `SIGTERM`，超时再 `SIGKILL` |
| `kill -0` 前不检查进程存在 | 误判状态 | `kill -0` 只探测存在性，不发送信号 |
| cron 里用相对路径 | 命令找不到 | 用绝对路径并设置 PATH |
| cron 任务不重定向输出 | 邮件堆积或错误丢失 | 重定向到日志并配置轮转 |
| 无锁直接跑定时任务 | 任务重叠、数据错乱 | 用 `flock` 或 pid 文件加锁 |
| 脚本没有超时 | 卡死的任务长期占用 | 用 `timeout` 包裹 |
| 把长任务交给 cron 且不监控 | 失败无人知 | 加告警与执行结果检查 |
| 忘记日志轮转 | 磁盘被写满 | 用 `logrotate` |
| 用 `nohup` 启动长期服务 | 重启后不会自愈 | 用 systemd 管理 |
| pid 文件残留 | 误判服务在运行 | 停止后清理并校验进程身份 |

## 自测清单

- [ ] 停止服务先用 `SIGTERM`，超时再 `SIGKILL`。
- [ ] 用 pid 文件或 `flock` 防止任务重叠。
- [ ] cron 命令使用绝对路径并重定向日志。
- [ ] 定时任务有超时与失败告警。
- [ ] 长期服务用 systemd 管理而非 `nohup`。
