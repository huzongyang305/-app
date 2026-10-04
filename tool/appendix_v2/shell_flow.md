## 零基础详解：分支、循环、函数与参数解析

### 一句话说清它是什么

Shell 的控制流很像其它语言，但**符号和空格规则特别严格**：
方括号内侧必须有空格、数字比较不能用 `>`、函数用 `return` 只能返回状态码。

### 判断：三种括号别用错

| 写法 | 支持 | 建议 |
| --- | --- | --- |
| `[ "$a" = "$b" ]` | POSIX，所有 shell | 可移植，注意内侧空格 |
| `[[ "$a" == "$b" ]]` | bash / zsh 扩展 | 更安全，不怕空变量，**脚本首选** |
| `(( a > b ))` | 算术比较 | 数字专用，写法最像其它语言 |

```bash
score=85

if [[ $score -ge 90 ]]; then
  echo "优秀"
elif (( score >= 60 )); then
  echo "及格"
else
  echo "不及格"
fi
```

数字比较必须用 `-gt -lt -ge -le -eq -ne`，或直接用 `(( ))`。

### 三种循环与 `case`

```bash
# for：遍历列表
for f in *.log; do
  echo "处理 $f"
done

# while read：按行读取文件（最稳的写法）
while IFS= read -r line; do
  echo "行内容：$line"
done < input.txt

# while：条件驱动
count=0
while (( count < 3 )); do
  echo "第 $((count + 1)) 次"
  ((count++))
done

# case：多分支匹配
case "$1" in
  start)  echo "启动" ;;
  stop)   echo "停止" ;;
  status) echo "查看状态" ;;
  *)      echo "用法：$0 {start|stop|status}" >&2; exit 1 ;;
esac
```

**遍历文件内容一定要用 `while IFS= read -r`**，`for x in $(cat file)` 会按空白拆分，遇到空格就错。

### 函数：参数用 `$1`，结果用 `echo`

```bash
log() {
  local level="$1"; shift          # local 限定作用域；shift 把参数前移
  local message="$*"
  printf '[%s] %s\n' "$level" "$message" >&2
}

is_number() {
  [[ "$1" =~ ^[0-9]+$ ]]           # 返回值就是条件结果
}

log INFO "服务已启动"
if is_number "123"; then echo "是数字"; fi
```

| 要点 | 说明 |
| --- | --- |
| `local` | 声明函数内局部变量，避免污染全局 |
| `shift` | 把参数列表往前移一位，便于逐个处理 |
| `return N` | 只能返回 0~255 的状态码，不能返回字符串 |
| `echo` + `$(...)` | 函数要「返回数据」的正确方式 |

### 参数解析：手动 + `getopts`

```bash
verbose=0
output=""

while getopts ":vo:h" opt; do
  case "$opt" in
    v) verbose=1 ;;
    o) output="$OPTARG" ;;
    h) echo "用法：$0 [-v] [-o 输出文件]"; exit 0 ;;
    \?) echo "未知选项：-$OPTARG" >&2; exit 1 ;;
    :)  echo "选项 -$OPTARG 需要参数" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))     # 剩下的是位置参数
```

`getopts` 是 POSIX 内建，能自动处理「选项需要值」的情况；长选项则需要 `getopt` 或手动解析。

### 新手最容易踩的七个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 方括号内侧少空格 | `[: command not found` | 写成 `[ "$a" = "$b" ]` |
| 数字用 `>` 比较 | 变成重定向，产生怪文件 | 用 `-gt` 或 `(( ))` |
| `for` 遍历命令输出 | 含空格的项被拆开 | 用 `while read -r` 或数组 |
| 函数忘了 `local` | 变量污染全局 | 一律 `local` |
| 用 `return` 返回字符串 | 报错或只拿到状态码 | 用 `echo` + 命令替换 |
| `$(...)` 不加引号 | 输出被拆分 | `result="$(func)"` |
| `case` 忘了 `esac` | 语法错误 | 检查 `case ... esac` 配对 |

### 手把手练习：带子命令的脚本骨架

```bash
#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "用法：$0 <init|build|clean>" >&2
  exit 1
}

cmd_init()  { echo "初始化……"; }
cmd_build() { echo "构建中……"; }
cmd_clean() { echo "清理完成"; }

main() {
  [[ $# -ge 1 ]] || usage
  case "$1" in
    init)  cmd_init ;;
    build) cmd_build ;;
    clean) cmd_clean ;;
    *)     usage ;;
  esac
}

main "$@"
```

`main "$@"` 加引号很重要：保证参数里的空格不被拆开。

### 学完自测

- [ ] 能说出 `[ ]`、`[[ ]]`、`(( ))` 各自适合什么。
- [ ] 知道数字比较为什么不能用 `>`。
- [ ] 能写出按行读文件的正确循环。
- [ ] 知道函数里 `local` 的作用。
- [ ] 能用 `case` 写出带子命令的脚本骨架。
