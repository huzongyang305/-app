## 文本处理速查

| 工具 | 常用写法 | 用途 |
| --- | --- | --- |
| `grep` | `grep -inE "error\|warn" app.log` | 过滤行 |
| `grep -v` | `grep -v "^#" config` | 排除行 |
| `cut` | `cut -d: -f1,7 /etc/passwd` | 按分隔符取列 |
| `awk` | `awk -F, '{sum += $3} END {print sum}'` | 按列统计 |
| `sed` | `sed -E 's/old/new/g'` | 替换 |
| `sort` | `sort -k2 -n -r` | 按第 2 列数值倒序 |
| `uniq -c` | `sort \| uniq -c` | 计数（需先排序） |
| `tr` | `tr 'A-Z' 'a-z'` | 字符转换 |
| `wc -l` | `wc -l < file` | 计数 |
| `head` / `tail` | `tail -n 100 -f app.log` | 首尾与实时查看 |
| `jq` | `jq -r '.items[].name'` | 处理 JSON |
| `xargs` | `find . -name '*.tmp' -print0 \| xargs -0 rm` | 批量处理 |
| `tee` | `cmd \| tee -a out.log` | 分流保存 |

常用组合示例：

```bash
# 统计访问量 Top 10 的 IP
awk '{print $1}' access.log \
  | sort | uniq -c | sort -nr | head -n 10

# 找出大于 100MB 的文件并按大小排序
find /var/log -type f -size +100M -printf '%s %p\n' \
  | sort -nr | awk '{printf "%.1f MB\t%s\n", $1/1048576, $2}'

# 处理 JSON 数组并生成 SQL
jq -r '.users[] | "INSERT INTO users(id,name) VALUES (\(.id), \(.name|@json));"' users.json

# 并行处理（-P 4 表示最多 4 个并发）
find . -name '*.png' -print0 | xargs -0 -n1 -P4 optipng -quiet
```

## 性能与安全速查

| 关注点 | 建议 |
| --- | --- |
| 大文件 | 用流式管道，避免 `$(cat file)` 全量载入 |
| 减少进程 | 能用一次 `awk` 完成就不串联多个命令 |
| 状态码 | `set -o pipefail` 让管道失败可见 |
| 特殊文件名 | 用 `-print0` + `xargs -0` |
| 注入风险 | 不拼接用户输入到命令，使用参数数组 |
| 编码 | 统一 UTF-8，`LC_ALL=C` 可提升 sort 速度（纯 ASCII 场景） |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `uniq -c` 前不排序 | 相同行不相邻，计数分散 | 先 `sort` 再 `uniq -c` |
| `for f in $(ls)` | 空格与换行导致文件名错乱 | 用通配符或 `find -print0` |
| `xargs` 不加 `-0` | 含空格文件名被拆 | `find -print0 \| xargs -0` |
| `grep` 忘了 `-F` | 内容含正则元字符导致误匹配 | 纯字符串搜索加 `-F` |
| 用 `sed -i` 跨平台 | macOS 需 `-i ''` 参数 | 用 `sed -i.bak` 或封装函数 |
| 管道前半失败被忽略 | 错误未暴露 | 加 `set -o pipefail` |
| `awk` 默认分隔符不适用 | 取列错位 | 显式 `-F','` |
| `$(...)` 结果含换行被当作多个参数 | 参数数量错误 | 加引号 `"$(...)"` 或用数组 |
| 对二进制文件跑文本工具 | 输出乱码、性能差 | 先判断文件类型 |
| 把用户输入直接拼进命令 | 命令注入 | 用数组参数或白名单校验 |

## 自测清单

- [ ] 会用 `awk` 按列统计并输出汇总。
- [ ] 计数前先排序，用 `uniq -c` 得到频次。
- [ ] 处理文件名一律 `-print0` 与 `xargs -0`。
- [ ] 管道场景开启了 `pipefail`。
- [ ] 纯文本搜索用 `grep -F`，复杂匹配才用正则。
