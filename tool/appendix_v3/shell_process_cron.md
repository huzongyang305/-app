## 零基础详解：进程、后台任务与定时任务

### 一句话说清它是什么

进程管理解决「谁在跑、怎么停」，定时任务解决「什么时候自动跑」。
两条最容易踩的坑是：**用 kill -9 代替优雅退出**、**以为 cron 里有你登录时的环境变量**。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 进程 | 正在办事的人 | 有 PID 作为工号 |
| `SIGTERM` | 请先收尾再走 | 可以被程序捕获，做清理 |
| `SIGKILL` | 直接断电 | 无法被捕获，进程立刻消失 |
| 后台任务 `&` | 让员工先去干活 | 但你的终端一关它就收到挂断信号 |
| `nohup` | 请无视下班铃声 | 忽略 HUP，退出终端后仍继续 |
| `flock` | 一把门锁 | 保证同一时刻只有一个在跑 |

### 查看与终止进程

```bash
ps aux | grep nginx              # 查看进程
pgrep -af node                  # 按名字找，显示完整命令行
top -p "$(pgrep -f server.py)"  # 只看某个进程

kill -TERM "$pid"               # 先请求优雅退出
sleep 5
kill -0 "$pid" 2>/dev/null && kill -KILL "$pid"   # 还在就强杀
```

**正确顺序永远是：先 TERM，等待，再 KILL。**

### 后台运行三种方式

```bash
# 1. 临时后台：终端关了就停
long_task &

# 2. 忽略挂断：终端关了继续跑
nohup long_task > run.log 2>&1 &

# 3. 交给系统管理（生产推荐）
sudo systemctl start myapp
sudo systemctl enable myapp
journalctl -u myapp -f            # 跟踪日志
```

| 方式 | 终端关闭后 | 开机自启 | 推荐场景 |
| --- | --- | --- | --- |
| `&` | 停止 | 否 | 临时任务 |
| `nohup ... &` | 继续 | 否 | 临时长期任务 |
| `systemd` | 继续 | 可配置 | **生产环境** |

### cron 表达式五个字段

```text
分 时 日 月 周
*  *  *  *  *    每分钟
0  *  *  *  *    每小时整点
30 2  *  *  *    每天 02:30
0  9  *  *  1    每周一 09:00
*/5 * * * *      每 5 分钟
```

```bash
crontab -e                       # 编辑当前用户的定时任务
crontab -l                       # 查看
```

### cron 里必须显式写清楚的东西

```bash
# 环境变量与 PATH 都要手动设置
PATH=/usr/local/bin:/usr/bin:/bin
SHELL=/bin/bash

# 用绝对路径，并把输出重定向到日志
0 2 * * * /usr/bin/flock -n /tmp/backup.lock /opt/scripts/backup.sh >> /var/log/backup.log 2>&1
```

| 注意点 | 原因 |
| --- | --- |
| 用绝对路径 | cron 的 PATH 很短 |
| 显式设置环境变量 | 不加载 `.bashrc`、`.profile` |
| 重定向输出 | 否则日志丢失或被当邮件发送 |
| 加 `flock -n` | 防止上一次没跑完又启动一次 |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 直接 `kill -9` | 数据损坏、临时文件残留 | 先 TERM 再 KILL |
| cron 里用相对命令 | 提示找不到命令 | 写绝对路径并设置 PATH |
| 忘重定向输出 | 排查时没有日志 | `>> log 2>&1` |
| 任务重入 | 数据被处理两次 | `flock -n` 加锁 |
| 用 `&` 跑长任务 | 退出终端就挂掉 | 用 systemd 或 nohup |
| 无限制增长日志 | 磁盘被写满 | 配 logrotate 或按天切割 |
| 时区不对 | 任务在错误时间执行 | 检查系统时区与 cron 时区 |
| 脚本没有执行权限 | 静默不执行 | `chmod +x` 并验证退出码 |

### 手把手练习：带锁的备份定时任务

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly LOCK=/tmp/backup.lock
readonly LOG=/var/log/backup.log

exec 9>"$LOCK"
if ! flock -n 9; then
  echo "$(date -Is) 上一次备份仍在运行，跳过" >> "$LOG"
  exit 0
fi

{
  echo "$(date -Is) 备份开始"
  tar -czf "/backup/data-$(date +%F).tar.gz" /srv/data
  echo "$(date -Is) 备份完成"
} >> "$LOG" 2>&1
```

对应的 crontab 条目：

```bash
0 2 * * * /opt/scripts/backup.sh
```

### 学完自测

- [ ] 能说出 `SIGTERM` 与 `SIGKILL` 的区别。
- [ ] 知道 `&`、`nohup`、`systemd` 三种后台方式的差别。
- [ ] 能读懂 `0 2 * * *` 表示什么。
- [ ] 知道 cron 为什么必须写绝对路径。
- [ ] 会用 `flock -n` 防止任务重入。
