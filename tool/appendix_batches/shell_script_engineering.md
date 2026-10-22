## 质量工具速查

| 工具 | 用途 | 常用命令 |
| --- | --- | --- |
| ShellCheck | 静态检查 | `shellcheck -x script.sh` |
| shfmt | 格式化 | `shfmt -w -i 2 script.sh` |
| bats-core | 单元测试 | `bats tests/` |
| bats-assert | 断言库 | `assert_output`、`assert_success` |
| shunit2 | 轻量测试框架 | `. shunit2` |
| shellspec | BDD 风格测试 | `shellspec` |
| make | 任务编排 | `make lint test` |

```bash
#!/usr/bin/env bats
# tests/deploy.bats

setup() {
  load '../lib/utils.sh'
  TMP_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf -- "$TMP_DIR"
}

@test "缺少参数时返回错误码 2" {
  run main_deploy
  [ "$status" -eq 2 ]
  [[ "$output" == *"用法"* ]]
}

@test "dry-run 不会创建文件" {
  run main_deploy -n "$TMP_DIR"
  [ "$status" -eq 0 ]
  [ ! -e "$TMP_DIR/app" ]
}
```

## 工程化约定速查

| 约定 | 说明 |
| --- | --- |
| 单一职责 | 一个脚本做一件事，复杂流程拆多个脚本 + 编排 |
| 可重复执行 | 幂等设计，重复运行结果一致 |
| 明确退出码 | 0 成功、1 业务失败、2 用法错误 |
| 统一日志 | `log_info` / `log_warn` / `log_error` 函数封装 |
| 支持 `--dry-run` | 破坏性操作先演练 |
| 支持 `--help` | 自动打印用法 |
| 参数校验 | 入口处一次性校验 |
| 目录约定 | `bin/` 脚本、`lib/` 公共函数、`tests/` 测试 |
| 版本管理 | 脚本进仓库，改动走评审 |
| CI 检查 | shellcheck + shfmt + bats 全绿才合并 |

```bash
# lib/log.sh：统一日志格式
log() {
  local level="$1"; shift
  printf '%s [%s] %s\n' "$(date '+%F %T')" "$level" "$*" >&2
}
log_info()  { log INFO  "$@"; }
log_warn()  { log WARN  "$@"; }
log_error() { log ERROR "$@"; }

# lib/utils.sh：幂等安装目录
ensure_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || mkdir -p -- "$dir"
}
```

## 何时换语言速查

| 信号 | 建议 |
| --- | --- |
| 超过 300 行且分支复杂 | 换 Python / Go |
| 大量 JSON / YAML 结构化处理 | 换 Python（有成熟库） |
| 需要并发与错误处理 | 换 Go |
| 需要复杂数据结构与算法 | 换通用语言 |
| 只是调用几个命令做编排 | Shell 合适 |
| 需要在 CI 里做轻量判断 | Shell 合适 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 不跑 ShellCheck | 未引用变量、拼写错误流入生产 | CI 加 `shellcheck -x` |
| 脚本无法重复执行 | 第二次运行报错或重复插入 | 设计成幂等：先检查再操作 |
| 退出码含义混乱 | 调用方无法区分失败类型 | 约定 0/1/2 并写进文档 |
| 日志格式各写各的 | 无法统一检索 | 用统一日志函数 |
| 测试靠手工执行 | 回归无人覆盖 | 用 bats 写自动化用例 |
| 破坏性操作没有 dry-run | 误操作造成事故 | 提供 `--dry-run` 并默认安全 |
| 一个脚本几百行 | 难以维护与测试 | 拆分为库函数 + 编排脚本 |
| 依赖外部命令却不检查 | 环境缺少工具时报错难懂 | 入口处 `command -v` 校验 |
| 把配置写死在脚本 | 无法复用 | 通过参数或环境变量传入 |
| 脚本没进版本控制 | 无法追溯改动 | 与代码同仓管理 |

## 自测清单

- [ ] 脚本接入 ShellCheck、shfmt 与 bats。
- [ ] 复杂逻辑按库函数与编排脚本拆分。
- [ ] 破坏性操作支持 `--dry-run` 且默认安全。
- [ ] 退出码与日志格式有统一约定。
- [ ] 脚本进入版本管理，改动经过评审与 CI。
