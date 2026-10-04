## 严格模式速查

| 选项 | 作用 | 注意 |
| --- | --- | --- |
| `set -e` | 命令失败即退出 | 在 `if` / `&&` / `\|\|` 中的失败不触发 |
| `set -u` | 使用未定义变量报错 | `"${var:-默认}"` 可安全兜底 |
| `set -o pipefail` | 管道任一环节失败即失败 | 常与 `-e` 搭配 |
| `set -x` | 打印实际执行的命令 | 调试用，注意可能泄漏敏感值 |
| `set -E` | ERR trap 能被继承 | 配合 `trap` 使用 |
| `IFS=$'\n\t'` | 收紧分词 | 减少空格分词带来的意外 |

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly WORK_DIR="$(mktemp -d)"

cleanup() {
  local exit_code=$?
  rm -rf -- "$WORK_DIR"
  if (( exit_code != 0 )); then
    echo "脚本失败，退出码 $exit_code" >&2
  fi
  exit "$exit_code"
}
# EXIT 覆盖正常退出与 set -e 触发的退出
trap cleanup EXIT
trap 'echo "收到中断信号" >&2; exit 130' INT TERM

main() {
  local config="${1:?用法: script.sh <配置文件>}"
  [[ -f "$config" ]] || { echo "配置文件不存在: $config" >&2; return 1; }

  # 失败即退出的场景可直接执行
  cp -- "$config" "$WORK_DIR/backup.conf"

  # 允许失败并自行处理的场景放进 if
  if ! grep -q '^enabled=true' "$config"; then
    echo "功能未启用，跳过" >&2
    return 0
  fi

  echo "处理完成"
}

main "$@"
```

## 安全写法速查

| 危险写法 | 安全写法 | 原因 |
| --- | --- | --- |
| `rm -rf "$dir/"` | `[[ -n "$dir" && "$dir" != "/" ]] && rm -rf -- "$dir"` | 变量为空时避免误删 |
| `cd "$dir"` | `cd -- "$dir" \|\| exit 1` | 失败要立即停止 |
| `eval "$input"` | 避免 `eval`，用数组传参 | 命令注入 |
| `curl ... \| bash` | 下载后校验哈希再执行 | 供应链风险 |
| `chmod 777` | 按需最小权限（如 750） | 权限过大 |
| 密码写在脚本里 | 从环境变量或密钥服务读取 | 泄漏风险 |
| `$RANDOM` 生成密钥 | 用 `openssl rand -hex 32` | 随机性不足 |
| `mktemp` 后不清理 | 配 `trap` 自动清理 | 磁盘堆积 |
| `echo $var` | `printf '%s\n' "$var"` | 转义与选项注入 |
| 日志包含敏感值 | 脱敏后记录 | 合规要求 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `set -e` 却依赖失败后继续 | 脚本提前退出 | 把允许失败的命令放进 `if !` 或 `\|\| true` |
| 未设置 `pipefail` | 管道失败被掩盖 | 加 `set -o pipefail` |
| `trap` 里未保存退出码 | 返回值被改写 | 先 `local code=$?` 再清理 |
| `trap` 用单引号与双引号混淆 | 变量提前展开 | 需要延迟展开时用单引号 |
| `mktemp -d` 忘记加 `--` | 路径以 `-` 开头时被当选项 | 加 `--` 结束选项 |
| 用 `cd` 后不检查 | 后续操作在错误目录执行 | `cd -- "$dir" \|\| exit 1` |
| 调试时 `set -x` 打印令牌 | 日志泄漏 | 用 `set +x` 临时关闭或脱敏 |
| `IFS` 改得太激进 | 破坏了需要空格的场景 | 仅在解析阶段临时调整 |
| 删除前不校验路径 | 误删系统目录 | 断言路径前缀与存在性 |
| 覆盖已有文件 | 数据丢失 | 默认拒绝，提供 `--force` |

## 自测清单

- [ ] 脚本开头 `set -Eeuo pipefail` 并设置 `IFS`。
- [ ] 用 `mktemp` 创建临时资源，`trap EXIT` 清理。
- [ ] 删除前校验变量非空且路径符合预期。
- [ ] 不使用 `eval` 与「下载即执行」。
- [ ] 调试输出注意脱敏，不泄漏密钥。
