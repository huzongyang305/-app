## 零基础详解：运维脚本的六个常见场景

### 一句话说清它是什么

运维脚本的共同要求只有三条：**幂等（能重复跑）**、**可观测（有日志）**、**安全（不误删）**。
下面六个场景覆盖了日常 90% 的需求。

### 场景一：磁盘清理（幂等）

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly TARGET_DIR="${1:?用法：$0 <目录>}"
readonly KEEP_DAYS="${KEEP_DAYS:-7}"

[[ -d "$TARGET_DIR" ]] || { echo "目录不存在：$TARGET_DIR" >&2; exit 1; }

echo "清理 $TARGET_DIR 中 $KEEP_DAYS 天前的文件"
before=$(du -sm "$TARGET_DIR" | cut -f1)

find "$TARGET_DIR" -type f -mtime "+$KEEP_DAYS" -print -delete

after=$(du -sm "$TARGET_DIR" | cut -f1)
echo "释放 $((before - after)) MB"
```

**关键点**：先 `-print` 再 `-delete`，日志里能看到删了什么。

### 场景二：日志轮转

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly LOG_DIR="${1:?用法：$0 <日志目录>}"
readonly KEEP="${KEEP:-5}"
readonly STAMP="$(date +%Y%m%d)"

for log in "$LOG_DIR"/*.log; do
  [[ -f "$log" ]] || continue
  cp "$log" "$log.$STAMP"
  : > "$log"                       # 清空当前日志但保持 inode 不变
done

# 只保留最近 N 份
ls -1t "$LOG_DIR"/*.log.* 2>/dev/null | tail -n "+$((KEEP + 1))" | xargs -r rm -f
```

用 `: > file` 清空而不是 `rm`，能避免正在写日志的进程继续写入已删除文件。

### 场景三：健康检查与告警

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly URL="${1:?用法：$0 <健康检查地址>}"
readonly TIMEOUT="${TIMEOUT:-5}"
readonly RETRIES="${RETRIES:-3}"

fail() {
  echo "健康检查失败：$1" >&2
  # 可以接钉钉、企业微信或邮件告警
  exit 1
}

for i in $(seq 1 "$RETRIES"); do
  code=$(curl -s -o /dev/null -w '%{http_code}' \
    --max-time "$TIMEOUT" "$URL" || echo 000)
  if [[ "$code" == "200" ]]; then
    echo "健康检查通过（第 $i 次）"
    exit 0
  fi
  echo "第 $i 次返回 $code，重试中…" >&2
  sleep 2
done

fail "连续 $RETRIES 次未通过"
```

### 场景四：批量部署（带失败汇总）

```bash
#!/usr/bin/env bash
set -uo pipefail                  # 这里故意不开 -e，需要收集所有失败

readonly HOSTS_FILE="${1:?用法：$0 <主机列表文件>}"
readonly PACKAGE="${2:?用法：$0 <主机列表文件> <包路径>}"

failed=()
succeeded=0

while IFS= read -r host; do
  [[ -z "$host" || "$host" == \#* ]] && continue

  if scp -q "$PACKAGE" "$host:/tmp/" && ssh -o BatchMode=yes "$host" \
      "sudo systemctl stop myapp && sudo dpkg -i /tmp/$(basename "$PACKAGE") && sudo systemctl start myapp"; then
    echo "成功：$host"
    ((succeeded++))
  else
    echo "失败：$host" >&2
    failed+=("$host")
  fi
done < "$HOSTS_FILE"

echo "成功 $succeeded 台，失败 ${#failed[@]} 台"
if ((${#failed[@]} > 0)); then
  printf '失败主机：%s\n' "${failed[*]}" >&2
  exit 1
fi
```

### 场景五：备份校验（不只看退出码）

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly SRC="${1:?用法：$0 <源目录> <备份目录>}"
readonly DEST="${2:?用法：$0 <源目录> <备份目录>}"
readonly STAMP="$(date +%Y%m%d-%H%M%S)"
readonly ARCHIVE="$DEST/data-$STAMP.tar.gz"

mkdir -p "$DEST"
tar -czf "$ARCHIVE" -C "$(dirname "$SRC")" "$(basename "$SRC")"

# 校验：能列出内容且非空，才算真的成功
if ! tar -tzf "$ARCHIVE" >/dev/null; then
  echo "备份损坏：$ARCHIVE" >&2
  exit 1
fi

size=$(du -h "$ARCHIVE" | cut -f1)
sha=$(sha256sum "$ARCHIVE" | cut -d' ' -f1)
echo "备份完成：$ARCHIVE（$size，sha256=${sha:0:12}…）"
```

### 场景六：进程守护（轻量版）

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly APP_CMD="${1:?用法：$0 <启动命令>}"
readonly LOCK=/tmp/guard.lock

exec 9>"$LOCK"
flock -n 9 || { echo "已有守护进程在运行" >&2; exit 1; }

while true; do
  echo "$(date -Is) 启动应用"
  if $APP_CMD; then
    echo "$(date -Is) 应用正常退出，停止守护"
    break
  fi
  echo "$(date -Is) 应用异常退出，5 秒后重启" >&2
  sleep 5
done
```

生产环境更推荐交给 systemd 或容器编排，这个脚本适合临时场景。

### 六个场景的共同要点

| 要点 | 具体做法 |
| --- | --- |
| 幂等 | 存在就跳过、先判断再操作 |
| 可观测 | 统一 `log()`、记录数量与耗时 |
| 安全 | 变量非空校验、`--`、先打印再删 |
| 可重入 | `flock` 加锁避免并发执行 |
| 可恢复 | 先备份再改，校验后再切换 |
| 可退出 | 明确退出码，失败要 `exit 1` |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `rm` 清日志 | 正在写的进程继续占用空间 | 用 `: > file` |
| 只删不记录 | 出事无法追溯 | 先 `-print` 再删 |
| 批量任务开了 `set -e` | 第一台失败就中断 | 用 `set -uo pipefail` 并收集失败 |
| 备份不看内容 | 备份损坏却报成功 | `tar -tzf` 校验 |
| 无锁并发执行 | 同一目录被两个进程操作 | `flock` |
| 健康检查只试一次 | 网络抖动误报 | 加重试与超时 |
| 硬编码主机名 | 换环境就失效 | 从文件或配置读 |
| 无告警出口 | 失败无人知晓 | 接通知渠道或写监控 |

### 学完自测

- [ ] 能说出运维脚本的三条共同要求。
- [ ] 知道清空日志为什么用 `: > file` 而不是 `rm`。
- [ ] 能写出带重试与超时的健康检查。
- [ ] 知道批量任务为什么要关掉 `set -e`。
- [ ] 能用 `flock` 防止脚本并发执行。
