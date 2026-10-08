# Shell 脚本工程化

![Shell 脚本工程化的四个实践](images/diagram_shell_engineering.webp)

![Shell 脚本工程化](images/remaining_shell_script_engineering.webp)

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：30 分钟

## 学习目标

- 能用自己的话解释Shell 脚本工程化解决了什么问题，而不是只背术语。
- 能说清 「Shell」、「bats」、「shellcheck」、「CI」 之间的关系，并分别举出一个例子。
- 能把 Shell 放回「Shell 脚本工程化」的知识体系，说明它和 bats 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：目录结构、bats 测试、shellcheck 与 CI 发布。

## 前置知识

- 先完成上一课《Shell 进程控制、定时任务与日志》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议先完成「Shell 进程控制、定时任务与日志」，或确认自己能独立跑通正文里的 TMP_DIR 示例。
- 开始前先复习：Shell、bats、shellcheck。
- 如果 目录与依赖 这一步看不懂，先记录具体卡点，再用 TMP_DIR 复现一遍。

## 目录与依赖

脚本多了就需要结构：`bin/`（入口）、`lib/`（公共函数）、`test/`（测试）、`README`（用法）。公共函数用 `source` 引入；入口脚本只做参数解析与调用。

依赖管理：检查必需命令（`command -v`），在 README 与 `--help` 中写明依赖；复杂依赖用包管理器或容器固化环境。

## 单元测试：bats

bats（Bash Automated Testing System）提供 `@test` 语法断言命令输出与退出码，是 Shell 最成熟的测试方案。测试要点：把逻辑写成可独立调用的函数、用临时目录隔离副作用、断言退出码而不只是输出。

## 静态检查与格式化

| 工具 | 作用 |
| --- | --- |
| shellcheck | 检测引号、未定义变量、常见陷阱（必装） |
| shfmt | 统一缩进与格式 |
| bashate | Shell 风格检查 |

接入 CI 的命令通常是：`shellcheck bin/* lib/* && shfmt -d . && bats test/`。

## 版本与发布

脚本头部写明用途、作者、版本与用法，重要变更记录 CHANGELOG；发布用 Git tag，配合 CI 打包成单文件（内嵌 lib）或用容器镜像分发，保证运行环境一致。

## 何时改用别的语言

出现以下信号就该迁移：需要复杂数据结构或 JSON 处理、需要并发与重试、脚本超过几百行、多人长期维护。常见路径是 Shell（编排）→ Python（逻辑）→ Go（分发为二进制）。

## 本课小结

Shell 工程化 = **目录结构 + shellcheck/shfmt + bats 测试 + CI + 版本化发布**；脚本一旦进入生产，就要按代码对待。

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

## 常见错误与排查

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

## 复习与自测

- [ ] 脚本接入 ShellCheck、shfmt 与 bats。
- [ ] 复杂逻辑按库函数与编排脚本拆分。
- [ ] 破坏性操作支持 `--dry-run` 且默认安全。
- [ ] 退出码与日志格式有统一约定。
- [ ] 脚本进入版本管理，改动经过评审与 CI。

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

## 动手练习

> 本课练习重点：围绕「Shell、bats、shellcheck」完成复述、实验和交付，每个结果都要能被别人检查。

先加严格模式，再在临时目录验证成功与失败路径，最后补回滚。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Shell 脚本工程化解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「bats」是什么关系？

验收标准：说明 Shell 与 bats 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：把 TMP_DIR 当作原例，改动一次bats的取值，记录命令、输出与差异原因；五步里缺任意一步都算未完成。

### 练习 3：交付一个小结果（30 分钟）

用 TMP_DIR 构造最小可运行示例，并把输出与「目录与依赖」的结论对照。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Shell」和「bats」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 可运行练习

### 任务 1：先跑通，再解释

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

### 任务 2：只改一个条件

把「Shell 脚本工程化」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 bats 换成边界值，其他输入保持原样。
- 预测：先写下「Shell 脚本工程化」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响Shell。

### 任务 3：迁移到自己的数据

把 TMP_DIR 换成你自己的输入，先保持步骤不变，再比较输出差异。

## 故障现场

### 现场 1：不跑 ShellCheck

**症状**：在《Shell 脚本工程化》的复现场景中，未引用变量、拼写错误流入生产。

**根因**：触发点是把“不跑 ShellCheck”当成安全做法。它没有满足《Shell 脚本工程化》要求的前提，因此先表现为“未引用变量、拼写错误流入生产”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Shell 脚本工程化》的问题，CI 加 shellcheck -x。

**验证**：在《Shell 脚本工程化》中按“CI 加 shellcheck -x”调整后，从“不跑 ShellCheck”的触发条件重放同一条路径，确认“未引用变量、拼写错误流入生产”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：脚本无法重复执行

**症状**：在《Shell 脚本工程化》的复现场景中，第二次运行报错或重复插入。

**根因**：触发点是把“脚本无法重复执行”当成安全做法。它没有满足《Shell 脚本工程化》要求的前提，因此先表现为“第二次运行报错或重复插入”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Shell 脚本工程化》的问题，设计成幂等：先检查再操作。

**验证**：保留《Shell 脚本工程化》里触发“第二次运行报错或重复插入”的输入、版本和日志，按“设计成幂等：先检查再操作”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：退出码含义混乱

**症状**：在《Shell 脚本工程化》的复现场景中，调用方无法区分失败类型。

**根因**：“调用方无法区分失败类型”只是表层结果。向上追溯会落到“退出码含义混乱”这一步，因为它省略了《Shell 脚本工程化》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《Shell 脚本工程化》的问题，约定 0/1/2 并写进文档。

**验证**：先在《Shell 脚本工程化》中记录“退出码含义混乱”留下的失败证据，再执行“约定 0/1/2 并写进文档”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

## 版本与时效

- 版本提示：Shell 的行为在最近几个大版本里有过调整，升级「Shell 脚本工程化」前先用 TMP_DIR 复现当前输出，再对照官方发布说明逐条核对。
- 升级前确认 Shell 的兼容范围，把不可回退的改动单独拆成一次提交。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改 Shell 的版本变量，记录编译、测试与产物体积的变化。
- 先回归 Shell 与 bats 的默认行为和错误信息，再扩大测试范围。
- 升级后把 TMP_DIR 的实测版本写进「内容元数据」，再更新复核日期。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Shell 单元测试最成熟的框架是？」的判断依据。
- [ ] 不看解析，能说出「Shell 静态检查的必装工具是？」的判断依据。
- [ ] 不看解析，能说出「脚本何时应该改用其他语言？」的判断依据。
- [ ] 不看解析，能说出「set -x 与 set -v 的区别是？」的判断依据。
- [ ] 不看解析，能说出「脚本要支持标准风格的短选项（-a -b 值），推荐用？」的判断依据。
- [ ] 跑通「Shell 脚本工程化」的最小示例，并记录一次失败输入的处理方式。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把「Shell 脚本工程化」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `Shell` | Shell 工程化 = 目录结构 + shellcheck/shfmt + bats 测试 + CI + 版本化发布；脚本一旦进入生产，就要按代码对待。 |
| `CI` | 脚本头部写明用途、作者、版本与用法，重要变更记录 CHANGELOG；发布用 Git tag，配合 CI 打包成单文件（内嵌 lib）或用容器镜像分发，保证运行环境一致。 |
| `退出码规范` | 脚本要让自己和调用方都能判断成功与否：出错就 exit 1，别默默继续。 |
| `trap` | 捕获 EXIT、ERR 等信号做清理或上报，是脚本保证临时文件与锁被释放的标准做法。 |
| `退出码` | 进程结束时返回的整数，0 表示成功、非 0 表示失败，脚本与 CI 据此判断结果 |

## 考点精讲

### 考点 1：代码补全·Shell

- **题目**：阅读「Shell 脚本工程化」中的这段 Shell 代码，下面哪项判断最准确？
- **判断依据**：在「Shell 脚本工程化」里，这段 Shell 代码来自本课的本地示例，主要用来核对 Shell、bats、shellcheck、CI 之间的输入、处理和输出关系，目录结构、bats 测试、shellcheck 与 CI 发布。回到「Shell 脚本工程化」的正文示例，用“阅读Shell 脚本工程化中的这段”走一遍Shell、bats、shellcheck的完整流程，能复现的结论才可以保留。

### 考点 2：概念判断·Shell

- **题目**：Shell 静态检查的必装工具是？
- **判断依据**：在「Shell 脚本工程化」里，shellcheck 能拦掉引号、未定义变量等大量低级事故。其他选项：clippy 面向 Rust，pylint 面向 Python，eslint 面向 JavaScript。在「Shell 脚本工程化」里判断这道题，要把Shell、bats、shellcheck的条件、过程与失败路径逐项对齐，换成“Shell 静态检查的必装工具是”这个场景，只有满足前提的结论才成立。

### 考点 3：多选辨析·Shell

- **题目**：围绕“Shell 脚本工程化”中的 Shell、bats、shellcheck，下列哪两项是本课强调的实践判断？
- **判断依据**：在「Shell 脚本工程化」里，题干的正确项是学习 Shell 时要同时说明输入、输出和失败路径，不能只看正常流程。在Shell 脚本工程化里，判断 bats 时要固定版本与边界输入，所以“验证 bats 时要固定版本并覆盖边界输入，结论才可复现”才可复现。在「Shell 脚本工程化」里判断这道题，要把Shell、bats、shellcheck的条件、过程与失败路径逐项对齐，换成“围绕Shell 脚本工程化中的 Sh”这个场景，只有满足前提的结论才成立。

### 考点 4：概念判断·Shell

- **题目**：set -x 与 set -v 的区别是？
- **判断依据**：在「Shell 脚本工程化」里，结论应落在「-x 打印展开后实际执行的命令」。-x 是排查脚本逻辑最常用的手段，可用 set +x 精确关闭某段。在「Shell 脚本工程化」里，这道题要求区分概念与边界，「-x 打印展开后实际执行的命令」只有在题干给出的前提下才成立，而「-x 只能用于函数」、「-v 会关闭错误处理，但这会引入新的复杂度」缺少同一组条件。

### 考点 5：概念判断·Shell

- **题目**：脚本要支持标准风格的短选项（-a -b 值），推荐用？
- **判断依据**：在「Shell 脚本工程化」里，getopts。getopts 是 POSIX 内置，能自动处理选项与参数绑定的细节。回到「Shell 脚本工程化」的正文示例，用“脚本要支持标准风格的短选项（-a -”走一遍Shell、bats、shellcheck的完整流程，能复现的结论才可以保留。

### 考点 6：填空·Shell

- **题目**：补全代码：「Shell 脚本工程化」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `____ { log ERROR "$@"; }`
- **判断依据**：空格应填写「log_error」。这道题的关键在「Shell 脚本工程化」的Shell、bats、shellcheck：先确认题干“补全代码”问的是哪一步，再排除偷换前提的选项。把“logerror”代回「Shell 脚本工程化」里“Shell 脚本工程化示例中”的例子核对，条件一旦改变，结论就要用Shell、bats、shellcheck重新推导。

## English Overview

**Title:** Shell Engineering

**Summary:** Layout, bats, shellcheck and CI.

**Category:** Shell
**Level:** 基础
**Key terms:** Shell, bats, shellcheck, CI, 工程化

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：Bash 5 / POSIX Shell
；本课聚焦 Shell。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Shell、bats、shellcheck、CI、工程化
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [ShellCheck 文档](https://www.shellcheck.net/wiki/) | 脚本缺陷与安全写法 |
| [GNU Bash 手册](https://www.gnu.org/software/bash/manual/) | Bash 语法、展开与作业控制 |
| [GNU awk](https://www.gnu.org/software/gawk/manual/) | 字段处理与报表 |

> 「Shell 脚本工程化」的链接用于离线阅读后的延伸核对；App 不会自动联网。

