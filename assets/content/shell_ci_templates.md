# CI 脚本模板库

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：35 分钟

![CI 流水线中的 Shell 脚本阶段](images/diagram_shell_ci.webp)

![CI 脚本模板库](images/remaining_shell_ci_templates.webp)

## 学习目标

- 能用自己的话解释CI 脚本模板库解决了什么问题，而不是只背术语。
- 能说清 「CI」、「流水线」、「缓存键」、「部署」 之间的关系，并分别举出一个例子。
- 能把 CI 放回「CI 脚本模板库」的知识体系，说明它和 流水线 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：流水线骨架、阶段复用、部署健康检查与自动回滚。

## 前置知识

- 先完成上一课《系统运维脚本实战》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「系统运维脚本实战」，或确认自己能独立跑通正文里的 BASH_SOURCE 示例。
- 开始前先复习：CI、流水线、缓存键。
- 看不懂就直接缩小例子：只保留 CI 相关的两行输入，跑通后再加回其余部分。

## 流水线阶段速查

| 阶段 | 目标 | 失败处理 |
| --- | --- | --- |
| 准备 | 校验环境与依赖 | 立即失败并打印缺失项 |
| 静态检查 | 快速反馈 | 阻断 |
| 测试 | 验证行为 | 阻断 |
| 构建 | 产出不可变制品 | 阻断 |
| 安全扫描 | 依赖与密钥 | 高危阻断 |
| 部署预发 | 环境验证 | 阻断并保留环境 |
| 灰度发布 | 观察真实流量 | 指标异常自动回滚 |
| 全量发布 | 正式上线 | 支持一键回滚 |

## 通用脚本骨架

```bash
#!/usr/bin/env bash
# ci.sh：可在本地与流水线复用，靠环境变量区分行为
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD_DIR="${BUILD_DIR:-${SCRIPT_DIR}/build}"

log() { printf '%s [%s] %s\n' "$(date '+%F %T')" "$1" "$2" >&2; }
die() { log ERROR "$1"; exit 1; }

require_tools() {
  local missing=()
  for tool in "$@"; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
  done
  ((${#missing[@]} == 0)) || die "缺少依赖：${missing[*]}"
}

stage() {
  local name="$1"; shift
  local start=$SECONDS
  log INFO "开始：$name"
  "$@" || { log ERROR "失败：$name"; return 1; }
  log INFO "完成：$name（$((SECONDS - start))s）"
}

run_lint()   { flutter analyze; }
run_test()   { flutter test; }
run_build()  {
  mkdir -p -- "$BUILD_DIR"
  flutter build apk --release
  cp -- build/app/outputs/flutter-apk/app-release.apk "$BUILD_DIR/"
  sha256sum "$BUILD_DIR/app-release.apk" > "$BUILD_DIR/app-release.apk.sha256"
}

main() {
  require_tools flutter git
  stage lint  run_lint
  stage test  run_test
  stage build run_build
  log INFO "流水线全部通过"
}

main "$@"
```

## 部署与回滚要点

| 要点 | 做法 |
| --- | --- |
| 制品不可变 | 用提交 SHA 或版本号命名，禁止覆盖 |
| 幂等部署 | 重复执行结果一致，不产生重复资源 |
| 健康检查 | 部署后轮询就绪端点，超时即失败 |
| 灰度放量 | 按比例逐步放量并观察指标 |
| 自动回滚 | 错误率或延迟超阈值立即切回上一版本 |
| 回滚演练 | 定期验证回滚路径可用 |
| 变更记录 | 记录版本、操作人、时间与结果 |

```bash
# 部署脚本片段：带健康检查与自动回滚
deploy() {
  local image="$1"
  local previous
  previous=$(current_version)

  log INFO "部署 $image（上一版本 $previous）"
  set_version "$image" || die "部署失败"

  if ! wait_healthy 60; then
    log ERROR "健康检查失败，回滚到 $previous"
    set_version "$previous" || die "回滚失败，需要人工介入"
    wait_healthy 60 || die "回滚后仍不健康"
    return 1
  fi
  log INFO "部署成功"
}

# 缓存键必须包含锁文件哈希，否则会用到过期依赖
cache_key() {
  local lockfile="$1"
  printf '%s-%s' "$(uname -s)" "$(sha256sum "$lockfile" | cut -c1-16)"
}
```

## 常见错误与排查

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| CI 用 `install` 而非锁定安装 | 依赖版本漂移 | 用 `--frozen-lockfile` / `npm ci` |
| 缓存键不含锁文件 | 用到过期依赖 | 键里加 lock 哈希 |
| 每个阶段重复构建 | 流水线很慢 | 构建一次，产物在阶段间传递 |
| 密钥打印到日志 | 泄漏 | 用环境变量并遮蔽输出 |
| 部署无健康检查 | 带病上线 | 部署后轮询就绪端点 |
| 无自动回滚 | 故障持续 | 指标超阈值立即回滚 |
| 跳过测试加速 | 缺陷进生产 | 只允许在明确授权时跳过 |
| 脚本不可本地复现 | 本地无法调试 | 同一脚本，靠环境变量区分 |

## 复习与自测

- [ ] CI 脚本可在本地执行，行为一致。
- [ ] 依赖锁定安装，缓存键包含锁文件哈希。
- [ ] 制品不可变并附带校验值。
- [ ] 部署有健康检查与自动回滚。
- [ ] 回滚路径定期演练。

## 零基础详解：CI 流水线模板

### 一句话说清它是什么

CI 流水线就是「每次提交后自动跑的那串检查」。
好的流水线有三个特征：**快、稳定、失败信息清楚**。

### 用生活比喻理解

| 阶段 | 比喻 | 说明 |
| --- | --- | --- |
| 检出与缓存 | 备料 | 装依赖，尽量复用缓存 |
| 静态检查 | 质检 | lint、类型检查、shellcheck |
| 测试 | 验收 | 单元与集成测试 |
| 构建 | 打包 | 产出制品，只构建一次 |
| 发布 | 发货 | 部署到环境，可回滚 |

### 模板一：通用多语言项目

```yaml
name: ci
on:
  push: { branches: [main] }
  pull_request:

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true          # 新提交自动取消旧流水线

jobs:
  check:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci
      - run: npx tsc --noEmit
      - run: npm run lint
      - run: npm test -- --run

  build:
    needs: check
    runs-on: ubuntu-latest
    steps:
        with: { node-version: 22, cache: npm }
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: dist-${{ github.sha }}     # 用 commit SHA 命名
          path: dist/
          retention-days: 7
```

### 模板二：Shell 脚本仓库

```yaml
name: shell-ci
on: [push, pull_request]

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: 安装工具
        run: |
          sudo apt-get update
          sudo apt-get install -y shellcheck bats
      - name: 静态检查
        run: shellcheck -S warning scripts/*.sh
      - name: 单元测试
        run: bats test/
      - name: 语法检查
        run: |
          for f in scripts/*.sh; do
            bash -n "$f"
          done
```

### 模板三：Docker 镜像构建与扫描

```yaml
name: image
on:
  push: { tags: ["v*"] }

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: docker/setup-buildx-action@v3
      - name: 登录镜像仓库
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: 构建并推送
        uses: docker/build-push-action@v6
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.ref_name }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
      - name: 漏洞扫描
        uses: aquasecurity/trivy-action@0.28.0
        with:
          image-ref: ghcr.io/${{ github.repository }}:${{ github.ref_name }}
          severity: HIGH,CRITICAL
          exit-code: "1"          # 有高危漏洞就失败
```

### 让流水线变快的五招

| 手段 | 效果 |
| --- | --- |
| 依赖缓存（`cache: npm`） | 省掉每次下载时间 |
| `concurrency` 取消旧任务 | 不浪费并行额度 |
| 拆分并行 job | 用时间换机器数 |
| 只跑受影响的包（monorepo） | 大幅缩短时间 |
| 容器镜像层缓存 | 加速镜像构建 |

### 让流水线可信的四条纪律

```text
1. 只构建一次：制品用 commit SHA 命名，各环境复用同一份
2. 密钥进 Secrets：绝不写在 YAML 里
3. 失败要能定位：日志分级、保留测试报告与制品
4. 关键检查不许跳过：类型检查、测试、漏洞扫描都是门禁
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 每个环境都重新构建 | 测试过的不是发布的 | 构建一次，复用制品 |
| 用 `npm install` | 版本可能与 lockfile 不一致 | CI 用 `npm ci` |
| 密钥写进 YAML | 泄露 | 用 Secrets |
| 没设 `timeout-minutes` | 卡住的任务占用额度 | 每个 job 设超时 |
| 缓存键不含 lockfile | 用到过期依赖 | 用 lockfile 哈希做键 |
| 所有检查串在一个 job | 出错慢、定位难 | 拆分并行 job |
| 只跑测试不跑构建 | 上线才发现打不出包 | 构建纳入流水线 |
| 制品没保留期限 | 存储无限增长 | 设置 `retention-days` |

### 学完自测

- [ ] 能说出 CI 的五个典型阶段。
- [ ] 知道为什么 CI 要用 `npm ci` 而不是 `npm install`。
- [ ] 能说出让流水线变快的至少三招。
- [ ] 知道「只构建一次」为什么重要。
- [ ] 能为 Shell 仓库写出 shellcheck 加 bats 的流水线。

## 动手练习

> 本课练习重点：围绕「CI、流水线、缓存键」完成复述、实验和交付，每个结果都要能被别人检查。

先加严格模式，再在临时目录验证成功与失败路径，最后补回滚。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. CI 脚本模板库解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「流水线」是什么关系？

验收标准：回答里必须出现 CI，并写出一个让结论失效的边界条件。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：围绕「流水线阶段速查」小节做一次五步记录，原例取自 BASH_SOURCE，改动只允许动一处CI，原因要能指回正文的判断依据。

### 练习 3：交付一个小结果（30 分钟）

写一个只做一件事的小程序：输入 CI，输出 流水线，其余全部省略。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「CI」和「流水线」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 本课小结

- 核心问题：CI 脚本模板库不是孤立术语，而是在「Shell」中解决一类具体问题。
- 关键关系：先分清「CI」与「流水线」的职责，再理解「缓存键」的适用边界。
- 判断标准：能解释 CI 的正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：把 BASH_SOURCE 的实验结论记成三句话，然后进入测验。

## 可运行练习

### 任务 1：先跑通，再解释

```bash
# 部署脚本片段：带健康检查与自动回滚
deploy() {
  local image="$1"
  local previous
  previous=$(current_version)

  log INFO "部署 $image（上一版本 $previous）"
  set_version "$image" || die "部署失败"

  if ! wait_healthy 60; then
    log ERROR "健康检查失败，回滚到 $previous"
    set_version "$previous" || die "回滚失败，需要人工介入"
    wait_healthy 60 || die "回滚后仍不健康"
    return 1
  fi
  log INFO "部署成功"
}

# 缓存键必须包含锁文件哈希，否则会用到过期依赖
cache_key() {
  local lockfile="$1"
  printf '%s-%s' "$(uname -s)" "$(sha256sum "$lockfile" | cut -c1-16)"
}
```

### 任务 2：只改一个条件

把「CI 脚本模板库」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 流水线 换成边界值，其他输入保持原样。
- 预测：先写下「CI 脚本模板库」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响CI。

### 任务 3：迁移到自己的数据

换一个 流水线 场景重做一次，确认结论不是只对示例数据成立。

## 故障现场

### 现场 1：CI 用 install 而非锁定安装

**症状**：在《CI 脚本模板库》的复现场景中，依赖版本漂移。

**根因**：触发点是把“CI 用 install 而非锁定安装”当成安全做法。它没有满足《CI 脚本模板库》要求的前提，因此先表现为“依赖版本漂移”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《CI 脚本模板库》的问题，用 --frozen-lockfile / npm ci。

**验证**：保留《CI 脚本模板库》里触发“依赖版本漂移”的输入、版本和日志，按“用 --frozen-lockfile / npm ci”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 2：缓存键不含锁文件

**症状**：在《CI 脚本模板库》的复现场景中，用到过期依赖。

**根因**：当出现“缓存键不含锁文件”时，执行路径已经绕过了《CI 脚本模板库》的关键约束，最终以“用到过期依赖”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《CI 脚本模板库》的问题，键里加 lock 哈希。

**验证**：保留《CI 脚本模板库》里触发“用到过期依赖”的输入、版本和日志，按“键里加 lock 哈希”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：脚本不可本地复现

**症状**：在《CI 脚本模板库》的复现场景中，本地无法调试。

**根因**：触发点是把“脚本不可本地复现”当成安全做法。它没有满足《CI 脚本模板库》要求的前提，因此先表现为“本地无法调试”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《CI 脚本模板库》的问题，同一脚本，靠环境变量区分。

**验证**：保留《CI 脚本模板库》里触发“本地无法调试”的输入、版本和日志，按“同一脚本，靠环境变量区分”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 版本与时效

- 版本提示：CI 的行为在最近几个大版本里有过调整，升级「CI 脚本模板库」前先用 BASH_SOURCE 复现当前输出，再对照官方发布说明逐条核对。
- 升级「CI 脚本模板库」涉及的依赖前，先用 BASH_SOURCE 复现当前行为，再逐项核对版本说明与破坏性变更。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 CI 相关的差异单独记成一条结论。
- 升级后重点回归 CI 的默认值、警告信息与错误格式。
- 升级后把 BASH_SOURCE 的实测版本写进「内容元数据」，再更新复核日期。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「CI 中依赖缓存的 key 应该包含什么？」的判断依据。
- [ ] 不看解析，能说出「部署后必须做健康检查的原因是？」的判断依据。
- [ ] 不看解析，能说出「为了让 CI 脚本能本地复现问题，应该？」的判断依据。
- [ ] 不看解析，能说出「制品（构建产物）应该如何命名与使用？」的判断依据。
- [ ] 不看解析，能说出「自动回滚触发条件通常是什么？」的判断依据。
- [ ] 用 CI 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `部署` | 把构建产物、配置和依赖发布到目标环境并使其可对外服务。 |
| `健康检查` | 周期性探测进程或依赖是否可服务，并据此摘除或重启实例。 |
| `幂等发布` | 同一个版本重复执行不产生额外副作用，这是流水线可以安全重跑的前提。 |
| `失败回滚` | 发布失败时把副本与配置切回上一个可用版本，并且要有明确的判定条件。 |
| `缓存键` | 决定缓存能否命中的字符串，通常包含依赖锁文件的哈希，写错就会复用到过期的依赖 |
| `Shell` | 接收命令并调用操作系统程序的命令行解释器与脚本环境 |

## 考点精讲

### 考点 1：概念判断·CI

- **题目**：CI 中依赖缓存的 key 应该包含什么？
- **判断依据**：锁文件哈希变化说明依赖变了，缓存要失效。作答时，先用CI建立输入与输出的基线，再把锁文件的哈希代入边界条件核对，结论才能复现。这道题的关键在「CI 脚本模板库」的CI、流水线、缓存键：先确认题干“CI 中依赖缓存的 key 应该包含”问的是哪一步，再排除偷换前提的选项。

### 考点 2：概念判断·CI

- **题目**：部署后必须做健康检查的原因是？
- **判断依据**：在「CI 脚本模板库」里，确认新版本真正可用。部署成功不等于服务可用，健康检查才能发现启动失败或依赖异常并触发回滚。「CI 脚本模板库」要求先交代CI、流水线、缓存键的前提再下结论，所以“确认新版本真正可用”只在题干“部署后必须做健康检查的原因是”给定的条件下成立。把“确认新版本真正可用”代回「CI 脚本模板库」里“部署后必须做健康检查的原因是”的例子核对，条件一旦改变，结论就要用CI、流水线、缓存键重新推导。

### 考点 3：多选辨析·CI

- **题目**：围绕“CI 脚本模板库”中的 CI、流水线、缓存键，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把CI 脚本模板库拆成概念、示例与故障现场三部分，因此判断 CI 时必须同时交代输入、输出和失败路径，这使“学习 CI 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在CI 脚本模板库里，判断 流水线 时要固定版本与边界输入，所以“验证 流水线 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 4：代码补全·CI

- **题目**：阅读「CI 脚本模板库」中的这段 Shell 代码，下面哪项判断最准确？
- **判断依据**：在「CI 脚本模板库」里，结论应落在流水线骨架、阶段复用、部署健康检查与自动回滚。在「CI 脚本模板库」里，这段 Shell 代码来自本课的本地示例，主要用来核对 CI、流水线、缓存键、部署 之间的输入、处理和输出关系，流水线骨架、阶段复用、部署健康检查与自动回滚。在「CI 脚本模板库」里，这道题要求区分概念与边界，流水线骨架、阶段复用、部署健康检查与自动回滚。

### 考点 5：概念判断·CI

- **题目**：自动回滚触发条件通常是什么？
- **判断依据**：在「CI 脚本模板库」里，错误率或延迟等关键指标超过阈值。以可观测指标为触发条件，才能在故障扩散前自动切换回上一版本。这道题的关键在「CI 脚本模板库」的CI、流水线、缓存键：先确认题干“自动回滚触发条件通常是什么”问的是哪一步，再排除偷换前提的选项。

### 考点 6：填空·CI

- **题目**：补全代码：「CI 脚本模板库」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `sudo apt-get install -y ____ bats`
- **判断依据**：把“shellcheck”代回「CI 脚本模板库」里“CI 脚本模板库示例中”的例子核对，条件一旦改变，结论就要用CI、流水线、缓存键重新推导。「CI 脚本模板库」要求先交代CI、流水线、缓存键的前提再下结论，所以“shellcheck”只在题干“脚本模板库示例中”给定的条件下成立。

## English Overview

**Title:** CI Script Templates

**Summary:** Pipeline skeleton, staging, health checks and auto rollback.

**Category:** Shell
**Level:** 进阶
**Key terms:** CI, 流水线, 缓存键, 部署, 健康检查, 自动回滚

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Bash 5 / POSIX Shell
；本课聚焦 CI。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：CI、流水线、缓存键、部署、健康检查、自动回滚
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## Full English Study Guide

### Overview

**CI Script Templates** focuses on Pipeline skeleton, staging, health checks and auto rollback.

### Learning Outcomes

- Explain what **CI Script Templates** solves and when it should be used.

### Glossary

- Topic: **CI Script Templates**
- Related terms: CI, 流水线, 缓存键, 部署

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning Objectives |
| 前置知识 | Pre-knowledge |
| 流水线阶段速查 | Quick Look at the Pipeline Stage |
| 通用脚本骨架 | Generic Script Skeleton |
| 部署与回滚要点 | Deployment and rollback points |
| 常见错误对照表 | Common Errors Comparison Table |
| 自测清单 | Self Test Checklist |
| 零基础详解：CI 流水线模板 | Zero Basics Explained in Detail: CI Pipeline Template |
| 动手练习 | Hands on exercise: |
| 本课小结 | Lesson Summary |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [GNU Bash 手册](https://www.gnu.org/software/bash/manual/) | Bash 语法、展开与作业控制 |
| [GNU Coreutils](https://www.gnu.org/software/coreutils/manual/) | 文件、文本与进程工具 |
| [GNU grep](https://www.gnu.org/software/grep/manual/) | 模式匹配与过滤 |

> 「CI 脚本模板库」的链接用于离线阅读后的延伸核对；App 不会自动联网。

