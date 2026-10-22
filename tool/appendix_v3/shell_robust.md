## 零基础详解：让脚本「出错就停、跑完就清」

### 一句话说清它是什么

生产脚本和随手写的脚本差别只有三点：
**出错要停**、**变量要防呆**、**资源要清理**。这三件事各有对应的标准写法。

### 用生活比喻理解

| 机制 | 比喻 | 说明 |
| --- | --- | --- |
| `set -e` | 安全检查 | 一步失败就停工，不带病继续 |
| `set -u` | 点名 | 用到没定义的变量立刻报错 |
| `pipefail` | 全链路质检 | 管道任一环失败就算失败 |
| `trap` | 离场清单 | 无论怎么退出都收拾干净 |
| `mktemp` | 领取专用工具 | 生成唯一临时文件，避免抢占 |

### 健壮性三件套 + 清理

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly WORKDIR="$(mktemp -d)"
readonly LOGFILE="$WORKDIR/run.log"

cleanup() {
  local exit_code=$?
  rm -rf -- "$WORKDIR"
  exit "$exit_code"          # 保留原始退出码
}
trap cleanup EXIT INT TERM
```

注意 `cleanup` 里要先保存 `$?`，否则后续命令会覆盖真正的退出码。

### 变量防呆的四个写法

```bash
: "${TARGET:?必须指定 TARGET}"          # 为空或未定义就退出
readonly DIR="${1:-./default}"          # 有默认值
readonly NAME="${1:?用法：$0 <名称>}"    # 必填参数
readonly COUNT="${COUNT:-1}"

if [[ ! -d "$DIR" ]]; then
  echo "目录不存在：$DIR" >&2
  exit 1
fi
```

| 写法 | 为空或未定义时 |
| --- | --- |
| `${var:-默认}` | 用默认值 |
| `${var:=默认}` | 用默认值并赋值给 var |
| `${var:?报错信息}` | 报错并退出 |
| `${#var}` | 取长度 |
| `${var##*/}` | 去掉最长前缀（取文件名） |

### 安全删除的三条纪律

```bash
# 1. 变量必须非空校验
: "${TARGET:?拒绝执行：TARGET 为空}"

# 2. 引号 + -- 终止选项解析
rm -rf -- "$TARGET"

# 3. 危险操作先打印再执行
echo "将删除：$TARGET"
read -r -p "确认？(yes/no) " answer
[[ "$answer" == "yes" ]] || exit 1
```

**永远不要写 `rm -rf $DIR/`**：变量为空时命令会变成 `rm -rf /`。

### 用 shellcheck 做静态检查

```bash
# 安装后直接用，能拦掉大量低级事故
shellcheck script.sh

# CI 里当作门禁
shellcheck -S warning scripts/*.sh
```

它最常帮你发现：变量没加引号、`[ ]` 用法错误、未定义变量、无用的管道。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| `set -e` 遇到管道失效 | 前面失败后面成功就通过 | 加 `set -o pipefail` |
| `cleanup` 覆盖退出码 | CI 判断不出失败 | 先存 `$?` 再 `exit` |
| 临时文件名可预测 | 被抢占或符号链接攻击 | 用 `mktemp` |
| `rm -rf $VAR` 变量为空 | 误删根目录 | 加引号、加 `--`、加非空校验 |
| 用 `cd` 不检查 | 后续命令在错误目录执行 | `cd "$DIR" \|\| exit 1` |
| `trap` 只捕获 EXIT | Ctrl+C 时没清理 | 同时注册 INT、TERM |
| 忘记 `local` | 变量污染全局 | 函数内一律 `local` |
| 脚本不能重复执行 | 第二次报错 | 设计成幂等，存在即跳过 |

### 手把手练习：可重入的部署脚本骨架

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly APP="${1:?用法：$0 <应用名>}"
readonly STAGE="$(mktemp -d)"

cleanup() {
  local code=$?
  rm -rf -- "$STAGE"
  exit "$code"
}
trap cleanup EXIT INT TERM

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" >&2; }

log "准备部署 $APP"
if [[ -f "/opt/$APP/current" ]]; then
  log "已存在部署，执行增量更新"
else
  log "首次部署"
fi

log "部署完成，临时目录 $STAGE 将在退出时清理"
```

### 学完自测

- [ ] 能说出 `-e`、`-u`、`pipefail` 各自的作用。
- [ ] 知道 `trap` 里为什么要先保存 `$?`。
- [ ] 能说出 `${var:-默认}` 与 `${var:?提示}` 的区别。
- [ ] 知道 `rm -rf` 的三条安全纪律。
- [ ] 会在 CI 里用 `shellcheck` 当门禁。
