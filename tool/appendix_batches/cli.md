## 常用命令速查

| 目的 | 命令 |
| --- | --- |
| 查看目录内容 | `ls -lah` |
| 递归查找文件 | `find . -type f -name '*.log'` |
| 查找并执行 | `find . -name '*.tmp' -delete` |
| 按内容搜索 | `rg 'pattern' -n` 或 `grep -rn` |
| 查看文件 | `less +F app.log` |
| 查看磁盘占用 | `du -sh * \| sort -h` |
| 查看空间 | `df -hT` |
| 查看进程 | `ps aux \| head`、`pgrep -af app` |
| 查看端口 | `ss -tlnp` |
| 强制结束 | `kill -TERM <pid>`（先优雅，超时再 `-KILL`） |
| 权限 | `chmod 640 f`、`chown app:app f` |
| 打包压缩 | `tar -czf a.tgz dir/`、`tar -xzf a.tgz` |
| 网络请求 | `curl -fsSL -o out url` |
| 校验 | `sha256sum f`、`md5sum f` |

## 重定向与管道速查

| 写法 | 含义 |
| --- | --- |
| `>` | 覆盖写入文件 |
| `>>` | 追加写入 |
| `2>` | 重定向标准错误 |
| `&>` | 同时重定向标准输出与错误 |
| `\|` | 管道，前一命令输出作为后一命令输入 |
| `tee` | 同时写入文件与屏幕 |
| `xargs` | 把输入转换为命令行参数 |
| `$(...)` | 命令替换 |
| `<` | 从文件读入标准输入 |

```bash
# 安全删除：先校验变量与目标路径
target="/data/tmp"
[[ -n "$target" && "$target" != "/" ]] || { echo "目标不合法" >&2; exit 1; }
find "$target" -type f -name '*.tmp' -print -delete | wc -l

# 处理带空格的文件名
find . -name '*.log' -print0 | xargs -0 -n1 gzip

# 日志排查三段式：过滤、统计、定位
grep -c 'ERROR' app.log
awk '/ERROR/ {print $1}' app.log | sort | uniq -c | sort -nr | head
tail -n 200 app.log | grep -A2 -B2 'Exception'

# 批量重命名（先 dry-run 再执行）
for f in ./*.jpeg; do echo mv -- "$f" "${f%.jpeg}.jpg"; done
for f in ./*.jpeg; do mv -- "$f" "${f%.jpeg}.jpg"; done
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `rm -rf $dir/` 且变量为空 | 误删根目录 | 删除前断言变量非空且路径合法 |
| 变量不加引号 | 含空格路径被拆开 | 一律 `"$var"` |
| 用 `for f in $(ls)` | 文件名含空格出错 | 用通配符或 `find -print0` |
| `xargs` 不加 `-0` | 空格文件名被拆分 | 配合 `-print0` 与 `-0` |
| `cd` 失败后继续执行 | 在错误目录操作 | `cd -- "$dir" \|\| exit 1` |
| 直接 `kill -9` | 数据未落盘 | 先 `TERM`，超时再 `KILL` |
| 重定向覆盖重要文件 | 数据丢失 | 追加用 `>>`，重要文件先备份 |
| `>` 与 `\|` 混淆 | 命令行为不符 | 明确输出流向 |
| 忘记 `--` 分隔选项 | 以 `-` 开头的文件被当选项 | 用 `--` 结束选项解析 |
| 不检查退出码 | 失败被忽略 | 用 `$?`、`&&` 或 `set -e` |

## 自测清单

- [ ] 熟悉文件、进程、网络、权限四类常用命令。
- [ ] 处理含空格文件名时使用 `-print0` 与 `-0`。
- [ ] 删除操作前校验变量与路径。
- [ ] 停止进程先优雅后强制。
- [ ] 脚本检查退出码，避免失败被忽略。
