## 零基础详解：Shell 脚本是「把命令写成文件」

### 一句话说清它是什么

Shell 脚本就是**把你在终端里一条条敲的命令，按顺序写进文件**。
它的强项是编排已有工具；弱项是复杂数据结构与运算。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| shebang | 说明书第一行 | 告诉系统用哪个解释器 |
| 变量 | 便利贴 | 存个值，后面引用 |
| 引号 | 包装方式 | 决定是否展开变量与通配符 |
| 退出码 | 交接单 | 0 表示成功，非 0 表示失败 |
| 管道 | 流水线 | 上一步的输出交给下一步 |

### 逐行拆解第一个脚本

```bash
#!/usr/bin/env bash
set -euo pipefail                 # 健壮性三件套

readonly NAME="${1:-朋友}"         # 取第一个参数，没给就用默认值

echo "你好，${NAME}！"
echo "当前目录：$(pwd)"
```

| 行 | 说明 |
| --- | --- |
| `#!/usr/bin/env bash` | 用 PATH 里的 bash 执行，比 `/bin/bash` 更可移植 |
| `set -e` | 命令失败立刻退出，不带着错误继续跑 |
| `set -u` | 用到未定义变量时报错 |
| `set -o pipefail` | 管道中任一环失败，整体就算失败 |
| `${1:-朋友}` | 参数默认值写法，比 `if` 更简洁 |
| `$(pwd)` | 命令替换，把命令输出嵌入字符串 |

### 引号：三种写法的区别

| 写法 | 变量是否展开 | 通配符是否展开 | 使用场景 |
| --- | --- | --- | --- |
| `'单引号'` | 否 | 否 | 原样输出、正则表达式 |
| `"双引号"` | 是 | 否 | **默认选择**，包变量 |
| 不加引号 | 是 | 是 | 基本不用，容易出错 |

```bash
name="小明"
echo '$name'      # 输出 $name
echo "$name"      # 输出 小明
echo $name        # 能输出，但遇到空格会拆成多个参数
```

**口诀：变量一律加双引号，除非你非常确定不需要。**

### 变量与参数速查

| 写法 | 含义 |
| --- | --- |
| `name=value` | 赋值，等号两边不能有空格 |
| `"$name"` / `"${name}"` | 引用变量 |
| `"${name:-默认}"` | 为空时用默认值 |
| `"${#name}"` | 字符串长度 |
| `"$1"`、`"$2"` | 第 1、2 个参数 |
| `"$@"` | 全部参数（保留每个参数的边界） |
| `"$#"` | 参数个数 |
| `"$?"` | 上一条命令的退出码 |
| `export NAME=value` | 导出给子进程 |

### 命令执行与判断

```bash
if command -v git >/dev/null 2>&1; then
  echo "已安装 git"
else
  echo "请先安装 git" >&2
  exit 1
fi
```

`>/dev/null 2>&1` 表示把标准输出和标准错误都丢掉，只关心「成功还是失败」。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 赋值时加空格 | `name: command not found` | `name=value`，等号两边不留空格 |
| 变量不加引号 | 遇到空格或空值出错 | 统一写 `"$var"` |
| 用 `=` 比较 | 只适合字符串，且要空格 | `[ "$a" = "$b" ]`，注意方括号内侧空格 |
| 数值用 `>` | 被当成重定向 | 用 `-gt`、`-lt`、`-eq` |
| 忘了 `set -e` | 出错还继续跑 | 开头加 `set -euo pipefail` |
| 临时文件不清理 | 残留垃圾 | `trap 'rm -f "$tmp"' EXIT` |
| 用 `ls \| xargs rm` | 文件名带空格就出事 | `find ... -print0 \| xargs -0` |
| 脚本没有执行权限 | `Permission denied` | `chmod +x script.sh` |

### 手把手练习：带参数与校验的备份脚本

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly SRC="${1:-}"
readonly DEST="${2:-./backup}"

if [[ -z "$SRC" ]]; then
  echo "用法：$0 <源目录> [目标目录]" >&2
  exit 1
fi

if [[ ! -d "$SRC" ]]; then
  echo "源目录不存在：$SRC" >&2
  exit 1
fi

mkdir -p "$DEST"
readonly STAMP="$(date +%Y%m%d-%H%M%S)"
readonly ARCHIVE="$DEST/backup-$STAMP.tar.gz"

tar -czf "$ARCHIVE" -C "$(dirname "$SRC")" "$(basename "$SRC")"
echo "备份完成：$ARCHIVE"
```

### 学完自测

- [ ] 能说出 `set -euo pipefail` 每一项的作用。
- [ ] 能解释单引号与双引号的区别。
- [ ] 知道 `${1:-默认值}` 的含义。
- [ ] 能说出 `$?`、`$#`、`"$@"` 分别表示什么。
- [ ] 能在脚本里用 `trap` 清理临时文件。
