## Bash 语法速查

| 场景 | 写法 | 说明 |
| --- | --- | --- |
| 变量赋值 | `name="tom"` | 等号两侧不能有空格 |
| 引用变量 | `"$name"` | 双引号保留空格，避免分词 |
| 默认值 | `${name:-默认}` | 未设置或为空时使用默认值 |
| 必填校验 | `${name:?请设置 name}` | 未设置直接报错退出 |
| 长度 | `${#name}` | 字符串长度 |
| 截取 | `${name:0:3}` | 子串 |
| 替换 | `${path//a/b}` | 全部替换 |
| 命令结果 | `now=$(date +%F)` | `$()` 优于反引号 |
| 算术 | `$((a + b))` | 整数运算 |
| 条件 | `if [[ -f "$file" ]]; then ... fi` | 推荐 `[[ ]]` |
| 文件判断 | `-f` 文件、`-d` 目录、`-x` 可执行、`-s` 非空 | 常用测试符 |
| 循环 | `for f in *.log; do ... done` | 注意通配符与空格 |
| 逐行读文件 | `while IFS= read -r line; do ... done < file` | `-r` 保留反斜杠 |
| 数组 | `arr=(a b c)`、`"${arr[@]}"` | 必须加引号展开 |
| 参数数组 | `"$@"` | 转发参数的正确形式 |
| 函数 | `f() { local x="$1"; }` | 用 `local` 限制作用域 |
| 返回值 | `return 0/1` + `echo` 输出数据 | 状态码与数据分开 |
| 严格模式 | `set -euo pipefail` | 出错即退、未定义变量报错、管道失败可见 |

## 常用工具速查

| 目的 | 命令 |
| --- | --- |
| 过滤行 | `grep -n`、`grep -v`、`grep -c` |
| 取列 | `awk '{print $1, $3}'` |
| 替换 | `sed 's/old/new/g'` |
| 排序去重 | `sort \| uniq -c` |
| 统计行数 | `wc -l` |
| 查看磁盘 | `df -h`、`du -sh *` |
| 查看进程 | `ps aux \| grep app`、`pgrep -af app` |
| 查看端口 | `ss -tlnp` |
| 查看日志尾部 | `tail -f app.log` |
| 定时任务 | `crontab -e`、`systemctl list-timers` |
| 网络请求 | `curl -fsSL`、`curl -o file url` |
| 打包 | `tar -czf a.tgz dir/` |
| 校验 | `sha256sum file` |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `name = "tom"` | `command not found: name` | 赋值不能有空格：`name="tom"` |
| `$file` 不加引号 | 文件名带空格时被拆成多个参数 | 一律写 `"$file"` |
| 用反引号嵌套命令 | 转义复杂、易出错 | 用 `$(...)` |
| `for f in $(ls)` | 空格与换行导致错乱 | 用通配符 `for f in *` 或 `find -print0` |
| 忘了 `set -u` | 变量名打错却静默为空 | 加 `set -euo pipefail` |
| `cd` 失败后继续执行 | 后续命令在错误目录运行 | `cd "$dir" \|\| exit 1` |
| `rm -rf "$dir/"` 且 `dir` 为空 | 误删根目录 | 校验变量非空：`[[ -n "$dir" ]] \|\| exit 1` |
| 用 `echo` 输出带转义内容 | 不同 shell 行为不一致 | 用 `printf '%s\n' "$var"` |
| 临时文件用固定名 | 并发执行互相覆盖 | 用 `mktemp` 并配 `trap` 清理 |
| 管道中失败被忽略 | 前半段失败却继续 | 加 `set -o pipefail` |
| 数字比较用 `[[ $a > $b ]]` | 按字符串比较出错 | 用 `(( a > b ))` 或 `-gt` |
| `cron` 里用相对路径 | 命令找不到 | 用绝对路径并显式设置 PATH |

## 自测清单

- [ ] 脚本开头写 `#!/usr/bin/env bash` 与 `set -euo pipefail`。
- [ ] 所有变量展开都加双引号。
- [ ] 用 `mktemp` 与 `trap` 管理临时资源。
- [ ] 删除前校验目标非空，避免误删。
- [ ] `cron` 任务使用绝对路径并记录日志。
