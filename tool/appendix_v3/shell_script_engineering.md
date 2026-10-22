## 零基础详解：把脚本当工程来做

### 一句话说清它是什么

随手写的脚本只求跑通；工程化的脚本要做到：**能测、能查、能读、能重跑**。
做到这四点，才敢让它在生产里定时或自动执行。

### 用生活比喻理解

| 工具 | 比喻 | 说明 |
| --- | --- | --- |
| shellcheck | 质检员 | 静态发现引号、变量类问题 |
| bats | 验收员 | 自动跑断言 |
| `getopts` | 前台登记 | 规范解析命令行参数 |
| 退出码 | 交接单 | 0 成功，非 0 说明失败原因 |
| 日志函数 | 录音笔 | 统一格式，便于检索 |

### 一个可维护脚本的骨架

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'                       # 收紧分词，减少意外

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*" >&2; }
die() { log "错误：$*"; exit 1; }

usage() {
  cat <<'EOF'
用法：backup.sh -s 源目录 [-d 目标目录] [-h]
  -s  要备份的源目录（必填）
  -d  备份输出目录，默认 ./backup
  -h  显示帮助
EOF
}

main() {
  local src="" dest="./backup"
  while getopts ":s:d:h" opt; do
    case "$opt" in
      s) src="$OPTARG" ;;
      d) dest="$OPTARG" ;;
      h) usage; return 0 ;;
      :)  die "选项 -$OPTARG 需要参数" ;;
      \?) die "未知选项：-$OPTARG" ;;
    esac
  done
  shift $((OPTIND - 1))

  [[ -n "$src" ]] || { usage; die "必须指定 -s"; }
  [[ -d "$src" ]] || die "源目录不存在：$src"

  mkdir -p "$dest"
  local archive="$dest/backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  tar -czf "$archive" -C "$(dirname "$src")" "$(basename "$src")"
  log "完成：$archive"
}

main "$@"
```

### 退出码规范

| 退出码 | 含义 | 使用场景 |
| --- | --- | --- |
| 0 | 成功 | 正常结束 |
| 1 | 通用错误 | 参数不对、文件不存在 |
| 2 | 用法错误 | 缺少必填参数 |
| 126 | 无法执行 | 权限不足 |
| 127 | 命令不存在 | 路径写错 |
| 130 | 被 Ctrl+C 中断 | 128 加上 SIGINT |

**脚本要让自己和调用方都能判断成功与否**：出错就 `exit 1`，别默默继续。

### 用 bats 写测试

```bash
#!/usr/bin/env bats

setup() {
  TMP_DIR="$(mktemp -d)"
  export TMP_DIR
}

teardown() {
  rm -rf "$TMP_DIR"
}

@test "缺少参数时返回用法错误" {
  run ./backup.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"用法"* ]]
}

@test "能生成备份文件" {
  mkdir -p "$TMP_DIR/data"
  echo hello > "$TMP_DIR/data/a.txt"

  run ./backup.sh -s "$TMP_DIR/data" -d "$TMP_DIR/out"
  [ "$status" -eq 0 ]
  run bash -c "ls '$TMP_DIR/out'/*.tar.gz"
  [ "$status" -eq 0 ]
}
```

```bash
bats test/                            # 跑全部用例
shellcheck -S warning scripts/*.sh    # 静态检查
```

### 什么时候该换语言

| 信号 | 建议 |
| --- | --- |
| 超过 300 行且分支复杂 | 拆成多个脚本或换 Python |
| 需要嵌套字典、复杂结构 | 换 Python |
| 需要单元测试与并发 | 换 Python 或 Go |
| 需要分发给别人用 | 编译成 Go 二进制 |
| 只做编排已有命令 | 继续用 Shell |

**经验路径：Shell 做编排，Python 做逻辑，Go 做分发。**

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 不跑 shellcheck | 低级错误上线 | CI 里加静态检查 |
| 没有 `usage` | 同事不会用 | 每个脚本都写帮助 |
| 用 `$1` 直接取参 | 少传参数就出错 | 用 `getopts` 加校验 |
| 出错继续跑 | 结果不完整却报成功 | `set -e` 与显式 `exit` |
| 日志格式不统一 | 排查困难 | 统一 `log()` 函数 |
| 硬编码路径 | 换机器就失败 | 用 `SCRIPT_DIR` 推导 |
| 脚本没有测试 | 改一处坏三处 | 用 bats 覆盖主流程 |
| 变量不加 `readonly` | 被后续误改 | 关键变量声明为 `readonly` |

### 学完自测

- [ ] 能写出带 `usage` 与 `getopts` 的脚本骨架。
- [ ] 知道 0、1、2、130 退出码的含义。
- [ ] 能用 bats 写一个「缺参数应失败」的用例。
- [ ] 知道什么时候该把脚本换成 Python 或 Go。
- [ ] 能在 CI 里同时跑 shellcheck 与 bats。
