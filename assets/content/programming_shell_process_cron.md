# Shell 进程控制、定时任务与日志

![Shell 进程控制、定时任务与日志](images/remaining_shell_process_cron.webp)

> 内容更新时间：2026-10-03 · 学习阶段：基础 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「Shell 进程控制、定时任务与日志」解决了什么问题，而不是只背术语。
- 能说清 「Shell」、「进程」、「trap」、「cron」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Shell」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：作业控制、信号与 trap、cron/systemd timer 与日志轮转。

## 前置知识

- 先完成上一课《健壮与可移植的 Shell 脚本》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议会读写简单代码或命令，并理解变量、输入输出等基本概念。
- 开始前先复习：Shell、进程、trap。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 进程与作业控制

| 命令 | 用途 |
| --- | --- |
| `ps aux` / `pgrep -af name` | 查看进程 |
| `kill -TERM <pid>` | 优雅终止（先 TERM 再 KILL） |
| `jobs` / `bg` / `fg` / `wait` | 作业控制 |
| `nohup cmd &` | 退出终端后继续运行 |
| `timeout 30 cmd` | 超时强制结束 |
| `nproc` / `ulimit -n` | 查看 CPU 数与文件描述符上限 |

脚本中等待并行任务：启动多个后台任务后统一 `wait`；捕获退出码用 `wait $pid || echo failed`。信号处理用 `trap 'cleanup' TERM INT`，收到终止信号时先清理再退出。

## cron 与 systemd timer

cron 表达式五个字段：分 时 日 月 周。例如 `0 3 * * *` 表示每天 3 点。

要点：

1. 脚本里用**绝对路径**，cron 的 PATH 与登录 shell 不同。
2. 显式设置环境变量与工作目录，别依赖 shell 配置。
3. 输出重定向到文件或日志系统，否则邮件会被塞满。
4. 并发保护：用 flock 防止上一次任务未结束又启动。
5. 现代系统优先用 systemd timer（依赖管理、日志与失败重试更完善）。

## 日志轮转与清理

应用日志要按天/大小切分，避免单文件无限增长：`logrotate` 配置保留天数与压缩；临时文件清理用 `find /tmp -type f -mtime +7 -delete`（务必先 `-print` 预览）。

## 排查命令组合

```text
ps aux --sort=-%cpu | head -10      # CPU 占用 Top10
ss -lntp | grep 8080                # 谁占了端口
lsof -p <pid> | wc -l               # 进程打开的文件数
```

## 本课小结
Shell 的进程与定时能力要配"安全带"：**作业控制 + 信号清理 + 并发保护（flock）+ 日志轮转**，才能让脚本长期稳定运行。


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


## 动手练习

### 练习 1：概念复述（10 分钟）

合上教程，用 3～5 句话解释「Shell 进程控制、定时任务与日志」解决什么问题，并写出一个边界条件。

**验收标准**：至少使用一个本课关键词，并给出一个反例。

### 练习 2：示例改写（20 分钟）

从正文选一个最小示例，先预测修改一个输入后的结果，再实际验证并记录差异。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：迁移任务（30 分钟）

写一个带 `set -euo pipefail` 的脚本，并用临时目录验证成功与失败路径。

- 至少覆盖「Shell」和「进程」两个关键词。
- 产出一个别人可以检查的结果。
- 写出一个仍不确定的问题和验证方法。


## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：终止进程时推荐的顺序是？

- **正确判断**：先 kill -TERM 优雅退出
- **判断依据**：TERM 给程序清理资源的机会，KILL 无法被捕获。其他选项：kill -1 只是发送挂断信号，killall 会波及同名进程，直接 -9 会跳过清理。正确顺序是先 TERM 优雅退出，超时再 KILL。正确项「先 kill -TERM 优雅退出」与本课示例和结论一致，可以直接用于实际编码。错误项「用 killall」只看到了表面现象，没有解释题干真正考查的机制。错误项「直接 kill -9」在边界或失败路径上会得出错误结果。错误项「先 kill -1」把因果关系颠倒了，不能作为正确结论。把题干「终止进程时推荐的顺序是？」放回《Shell 进程控制、定时任务与日志》的「作业控制、信号与 trap、cron/systemd timer 与日志轮转」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 2：cron 任务最容易踩的坑是？

- **正确判断**：环境变量与 PATH 不同
- **判断依据**：cron 不加载登录 shell 配置，路径与变量都要显式指定。其他选项：cron 完全可以执行脚本，也不限于 root，表达式写错属于语法问题。最常见的坑是环境变量与 PATH 与登录会话不同。正确项「环境变量与 PATH 不同」正面回答了题目所问，符合课程给出的定义与适用范围。错误项「不能执行脚本」属于相邻主题的说法，范围与本题要求不一致。错误项「只能 root 运行」把不同概念混在一起，缺少题干限定的前提。把题干「cron 任务最容易踩的坑是？」放回《Shell 进程控制、定时任务与日志》的「作业控制、信号与 trap、cron/systemd timer 与日志轮转」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：防止上一次定时任务未结束又启动，常用？

- **正确判断**：flock 加锁
- **判断依据**：flock 提供文件锁，保证同一任务串行执行。其他选项：nohup 与重定向都与互斥无关，sleep 只能延后不能防重入。flock 文件锁才能保证同一任务串行执行。正确项「flock 加锁」与题干要求一致，是本课知识点的准确定义。把题干「防止上一次定时任务未结束又启动，常用？」放回《Shell 进程控制、定时任务与日志》的「作业控制、信号与 trap、cron/systemd timer 与日志轮转」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：nohup 与 & 的区别是？

- **正确判断**：& 只把任务放到后台
- **判断依据**：长期运行的服务更推荐交给 systemd 管理，而不是 nohup 手工启动。其他选项：忽略挂断信号的是 nohup 而不是 &，两者也不等价。& 只是放到后台，nohup 才让进程在退出终端后继续运行。正确项「& 只把任务放到后台」与题干要求一致，是本课知识点的准确定义。错误项「& 会忽略 SIGHUP」忽略了题目中的限制条件，因此不成立。错误项「两者完全等价」把不同概念混在一起，缺少题干限定的前提，在题干「nohup 与 & 的区别是？」的语境下并不成立。错误项「nohup 会把进程放到前台」与课程给出的定义相冲突，不能回答题目所问。把题干「nohup 与 & 的区别是？」放回《Shell 进程控制、定时任务与日志》的「作业控制、信号与 trap、cron/systemd timer 与日志轮转」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：查看 systemd 服务日志的常用命令是？

- **正确判断**：journalctl -u 服务名 -f
- **判断依据**：-u 指定单元，-f 持续跟踪输出，配合 --since 可定位特定时间段。 其他选项：tail /var/log/messages 未必存在且不区分单元，dmesg 只显示内核日志，systemctl log 不是命令；查看单元日志要用 journalctl -u。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「终止进程时推荐的顺序是？」的判断依据。
- [ ] 不看解析，能说出「cron 任务最容易踩的坑是？」的判断依据。
- [ ] 不看解析，能说出「防止上一次定时任务未结束又启动，常用？」的判断依据。
- [ ] 不看解析，能说出「nohup 与 & 的区别是？」的判断依据。
- [ ] 不看解析，能说出「查看 systemd 服务日志的常用命令是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** Processes, Cron & Logs

**Summary:** Jobs, signals, cron and log rotation.

**Category:** Shell  
**Level:** 基础  
**Key terms:** Shell, 进程, trap, cron, 日志轮转

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：基础
- 适用环境：Bash 5 / POSIX Shell
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Shell、进程、trap、cron、日志轮转
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [GNU Bash Manual](https://www.gnu.org/software/bash/manual/) | Bash 语法与行为 |
| [POSIX Shell](https://pubs.opengroup.org/onlinepubs/9799919799/) | 可移植 Shell 标准 |

> 本课主题：作业控制、信号与 trap、cron/systemd timer 与日志轮转。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

