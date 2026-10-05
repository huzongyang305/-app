# CI 脚本模板库

![CI 脚本模板库](images/remaining_shell_ci_templates.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「CI 脚本模板库」解决了什么问题，而不是只背术语。
- 能说清 「CI」、「流水线」、「缓存键」、「部署」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Shell」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：流水线骨架、阶段复用、部署健康检查与自动回滚。

## 前置知识

- 先完成上一课《系统运维脚本实战》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：CI、流水线、缓存键。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


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

## 常见错误对照表

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

## 自测清单

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
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
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
      - uses: actions/checkout@v4
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
      - uses: actions/checkout@v4
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

1. 「CI 脚本模板库」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「流水线」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

写一个带 `set -euo pipefail` 的脚本，并用临时目录验证成功与失败路径。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「CI」和「流水线」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 本课小结

- 核心问题：「CI 脚本模板库」不是孤立术语，而是在「Shell」中解决一类具体问题。
- 关键关系：先分清「CI」与「流水线」的职责，再理解「缓存键」的适用边界。
- 判断标准：能解释正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：完成练习后，用自己的话写下 3 条要点，再去做本课测验。



## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：CI 中依赖缓存的 key 应该包含什么？

- **正确判断**：锁文件的哈希
- **判断依据**：正确答案是「锁文件的哈希」，本课在「零基础详解：CI 流水线模板」中说明：CI 流水线就是「每次提交后自动跑的那串检查」。锁文件哈希变化说明依赖变了，缓存要失效。本课还在「零基础详解：CI 流水线模板」中说明：好的流水线有三个特征：快、稳定、失败信息清楚。本课还在「零基础详解：CI 流水线模板」中说明：能为 Shell 仓库写出 shellcheck 加 bats 的流水线。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 2：部署后必须做健康检查的原因是？

- **正确判断**：确认新版本真正可用
- **判断依据**：正确答案是「确认新版本真正可用」，本课在「零基础详解：CI 流水线模板」中说明：CI 流水线就是「每次提交后自动跑的那串检查」。部署成功不等于服务可用，健康检查才能发现启动失败或依赖异常并触发回滚。本课还在「零基础详解：CI 流水线模板」中说明：好的流水线有三个特征：快、稳定、失败信息清楚。本课还在「零基础详解：CI 流水线模板」中说明：能为 Shell 仓库写出 shellcheck 加 bats 的流水线。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：为了让 CI 脚本能本地复现问题，应该？

- **正确判断**：同一个脚本在本地与流水线执行，靠环境变量区分行为
- **判断依据**：正确答案是「同一个脚本在本地与流水线执行，靠环境变量区分行为」，本课在「零基础详解：CI 流水线模板」中说明：知道为什么 CI 要用 npm ci 而不是 npm install。同一脚本可本地运行才能快速定位问题，环境差异通过变量注入解决。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 4：制品（构建产物）应该如何命名与使用？

- **正确判断**：用提交 SHA 或版本号命名且不覆盖
- **判断依据**：正确答案是「用提交 SHA 或版本号命名且不覆盖」，这道题在问制品（构建产物）应该如何命名与使用，判断时要把题干限定的输入、边界与目标逐项对齐。不可变且可追溯的制品才能保证各环境部署同一份代码，出问题也能定位到具体提交。课程摘要指出流水线骨架，阶段复用，部署健康检查与自动回滚，本课要判断的正是制品（构建产物）应该如何命名与使用。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：自动回滚触发条件通常是什么？

- **正确判断**：错误率或延迟等关键指标超过阈值
- **判断依据**：正确答案是「错误率或延迟等关键指标超过阈值」，这道题在问自动回滚触发条件通常是什么，判断时要把题干限定的输入、边界与目标逐项对齐。以可观测指标为触发条件，才能在故障扩散前自动切换回上一版本。课程摘要指出流水线骨架，阶段复用，部署健康检查与自动回滚，本课要判断的正是自动回滚触发条件通常是什么。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 6：补全代码：「CI 脚本模板库」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `sudo apt-get install -y ____ bats`

- **正确判断**：shellcheck
- **判断依据**：正确答案是「shellcheck」，本课在「零基础详解：CI 流水线模板」中说明：知道为什么 CI 要用 npm ci 而不是 npm install。本课示例中还能看到 `sudo apt-get install -y shellcheck bats` 这样的用法，说明该关键字在本课代码中承担实际功能。
- **迁移检查**：如果填成相近的另一个函数或关键字，程序会在哪一步出错？

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「CI 中依赖缓存的 key 应该包含什么？」的判断依据。
- [ ] 不看解析，能说出「部署后必须做健康检查的原因是？」的判断依据。
- [ ] 不看解析，能说出「为了让 CI 脚本能本地复现问题，应该？」的判断依据。
- [ ] 不看解析，能说出「制品（构建产物）应该如何命名与使用？」的判断依据。
- [ ] 不看解析，能说出「自动回滚触发条件通常是什么？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「CI 脚本模板库」示例中，下面这行代码缺少哪个关键字或函数名？请填入…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把本课反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `install` | \| CI 用 `install` 而非锁定安装 \| 依赖版本漂移 \| 用 `--frozen-lockfile` / `npm ci` \| |
| `--frozen-lockfile` | \| CI 用 `install` 而非锁定安装 \| 依赖版本漂移 \| 用 `--frozen-lockfile` / `npm ci` \| |
| `npm ci` | \| CI 用 `install` 而非锁定安装 \| 依赖版本漂移 \| 用 `--frozen-lockfile` / `npm ci` \| |
| `cache: npm` | \| 依赖缓存（`cache: npm`） \| 省掉每次下载时间 \| |
| `concurrency` | \| `concurrency` 取消旧任务 \| 不浪费并行额度 \| |
| `npm install` | \| 用 `npm install` \| 版本可能与 lockfile 不一致 \| CI 用 `npm ci` \| |
| `timeout-minutes` | \| 没设 `timeout-minutes` \| 卡住的任务占用额度 \| 每个 job 设超时 \| |
| `retention-days` | \| 制品没保留期限 \| 存储无限增长 \| 设置 `retention-days` \| |
| `set -euo pipefail` | 写一个带 `set -euo pipefail` 的脚本，并用临时目录验证成功与失败路径。 |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：CI 中依赖缓存的 key 应该包含什么？

**参考回答**：正确答案是「锁文件的哈希」，本课在「零基础详解·CI 流水线模板」中说明：CI 流水线就是「每次提交后自动跑的那串检查」。锁文件哈希变化说明依赖变了，缓存要失效。本课还在「零基础详解·CI 流水线模板」中说明：好的流水线有三个特征：快、稳定、失败信息清楚。本课还在「零基础详解·CI 流水线模板」中说明：能为 Shell 仓库写出 shellcheck 加 bats 的流水线。

### 追问 2：部署后必须做健康检查的原因是？

**参考回答**：正确答案是「确认新版本真正可用」，本课在「零基础详解·CI 流水线模板」中说明：CI 流水线就是「每次提交后自动跑的那串检查」。部署成功不等于服务可用，健康检查才能发现启动失败或依赖异常并触发回滚。本课还在「零基础详解·CI 流水线模板」中说明：好的流水线有三个特征：快、稳定、失败信息清楚。本课还在「零基础详解·CI 流水线模板」中说明：能为 Shell 仓库写出 shellcheck 加 bats 的流水线。

### 追问 3：为了让 CI 脚本能本地复现问题，应该？

**参考回答**：正确答案是「同一个脚本在本地与流水线执行，靠环境变量区分行为」，本课在「零基础详解·CI 流水线模板」中说明：知道为什么 CI 要用 npm ci 而不是 npm install。同一脚本可本地运行才能快速定位问题，环境差异通过变量注入解决。

### 追问 4：制品（构建产物）应该如何命名与使用？

**参考回答**：正确答案是「用提交 SHA 或版本号命名且不覆盖」，这道题在问制品（构建产物）应该如何命名与使用，判断时要把题干限定的输入、边界与目标逐项对齐。不可变且可追溯的制品才能保证各环境部署同一份代码，出问题也能定位到具体提交。课程摘要指出流水线骨架，阶段复用，部署健康检查与自动回滚，本课要判断的正是制品（构建产物）应该如何命名与使用。

### 追问 5：自动回滚触发条件通常是什么？

**参考回答**：正确答案是「错误率或延迟等关键指标超过阈值」，这道题在问自动回滚触发条件通常是什么，判断时要把题干限定的输入、边界与目标逐项对齐。以可观测指标为触发条件，才能在故障扩散前自动切换回上一版本。课程摘要指出流水线骨架，阶段复用，部署健康检查与自动回滚，本课要判断的正是自动回滚触发条件通常是什么。

## English Overview

**Title:** CI Script Templates

**Summary:** Pipeline skeleton, staging, health checks and auto rollback.

**Category:** Shell  
**Level:** 进阶  
**Key terms:** CI, 流水线, 缓存键, 部署, 健康检查, 自动回滚

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：Bash 5 / POSIX Shell
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：CI、流水线、缓存键、部署、健康检查、自动回滚
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## Full English Study Guide

### Overview

**CI Script Templates** focuses on Pipeline skeleton, staging, health checks and auto rollback.

### Learning Outcomes

- Explain what **CI Script Templates** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **CI Script Templates**
- Related terms: CI, 流水线, 缓存键, 部署
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.


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

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [GNU Bash Manual](https://www.gnu.org/software/bash/manual/) | Bash 语法与行为 |
| [POSIX Shell](https://pubs.opengroup.org/onlinepubs/9799919799/) | 可移植 Shell 标准 |

> 本课主题：流水线骨架、阶段复用、部署健康检查与自动回滚。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
