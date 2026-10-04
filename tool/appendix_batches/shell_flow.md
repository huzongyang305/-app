## 变量与参数速查

| 写法 | 含义 |
| --- | --- |
| `name="tom"` | 赋值（等号两侧不能有空格） |
| `"${name}"` | 引用变量，加引号防分词 |
| `${name:-默认}` | 未设置或为空时用默认值 |
| `${name:=默认}` | 未设置时赋值并返回 |
| `${name:?错误提示}` | 未设置时报错退出 |
| `${#name}` | 字符串长度 |
| `${name:0:3}` | 截取子串 |
| `${name%.*}` | 去掉最后一个点之后的部分 |
| `${name##*/}` | 取路径中的文件名 |
| `$#` | 参数个数 |
| `$1`、`$@`、`$*` | 位置参数；`"$@"` 保留参数边界 |
| `shift` | 左移参数，消费第一个 |
| `getopts` | 解析短选项 |
| `$?` | 上一条命令的退出码 |
| `$$` | 当前进程 PID |

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly LOG_DIR="${LOG_DIR:-/var/log/myapp}"
: "${API_TOKEN:?必须设置 API_TOKEN}"

usage() {
  cat <<'EOF'
用法: deploy.sh [-e 环境] [-n] 目标
  -e 环境   指定部署环境（dev/staging/prod）
  -n        只演练不真正执行
EOF
}

env="dev"
dry_run=0
while getopts ":e:nh" opt; do
  case "$opt" in
    e) env="$OPTARG" ;;
    n) dry_run=1 ;;
    h) usage; exit 0 ;;
    :) echo "缺少 -$OPTARG 的参数" >&2; exit 2 ;;
    \?) echo "未知选项 -$OPTARG" >&2; usage >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

target="${1:-}"
[[ -n "$target" ]] || { usage >&2; exit 2; }
echo "环境=$env 目标=$target 演练=$dry_run"
```

## 流程控制速查

| 结构 | 写法 |
| --- | --- |
| 条件 | `if [[ "$env" == "prod" ]]; then ... fi` |
| 数值比较 | `if (( count > 10 )); then ... fi` |
| 文件判断 | `[[ -f "$f" ]]`、`[[ -d "$d" ]]`、`[[ -x "$bin" ]]` |
| for 遍历列表 | `for f in "$@"; do ... done` |
| for 遍历目录 | `for f in ./*.log; do ... done` |
| while 读文件 | `while IFS= read -r line; do ... done < "$file"` |
| case 分支 | `case "$1" in start) ... ;; stop) ... ;; *) ... ;; esac` |
| 函数返回数据 | `printf '%s\n' "$value"` + `result="$(fn)"` |
| 函数返回状态 | `return 0/1`，用 `if fn; then` 判断 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `$1` 未引号 | 参数含空格被拆分 | 写 `"$1"` 或 `"$@"` |
| `[[ $a = $b ]]` 未加引号 | 空值导致语法错误 | 写 `[[ "$a" == "$b" ]]` |
| 用 `[ ]` 又用 `&&` | 语法错误 | 用 `[[ ]]` 或 `[ ] -a` |
| `$((...))` 里用浮点 | 报错 | Shell 只支持整数，用 `awk` / `bc` |
| 函数里用 `exit` | 整个脚本退出 | 需要返回上层时用 `return` |
| 全局变量当作函数返回值 | 并发调用互相覆盖 | 用 `printf` 输出 + 命令替换 |
| `local` 用在函数外 | 报错 | 只在函数内使用 |
| 忘记 `shift` | 参数被重复处理 | 用 `getopts` 后 `shift $((OPTIND-1))` |
| 用 `==` 在 `[ ]` 中 | 兼容性问题 | `[[ ]]` 允许 `==`，`[ ]` 用 `=` |
| 未处理未知选项 | 静默忽略错误参数 | `case` 中加 `\?` 分支报错 |

## 自测清单

- [ ] 变量与参数展开一律加双引号。
- [ ] 用 `: "${VAR:?msg}"` 校验必填变量。
- [ ] 用 `getopts` 解析选项并处理错误分支。
- [ ] 函数通过 stdout 返回数据，用 `return` 返回状态。
- [ ] 条件判断统一用 `[[ ]]` / `(( ))`。
