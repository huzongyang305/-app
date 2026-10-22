# CI Script Template Library

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: progress

## Learning objectives

- I can explain in my own words what the CI Script Library solves, not just a term.
- The relationship between the "CI" and "waterlines", "Cache keys," and "deployment" is clear, with one example.
- It's a way to put back the knowledge of "shell" and point out its boundaries with each other.
- It is possible to complete this course and check its results using acceptance standards.

> Summary of sentence: flow line skeleton, phase reuse, deployment health check and automatic roll-back.

## Pre-knowledge

- First, the first course on " The operationalization of systems " ; if available, self-censorship can be used for this subject.
- This course stage: Progress. It is recommended to have a basic curriculum for the same classification and to be able to run the smallest examples in the text independently.
- Read it first: CI, Waterlines, Cache keys.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Waterline, quick.

|Phase|Objective|Failed to process|
| --- | --- | --- |
|Ready.|Validation of environment and dependence|Failed immediately and printing missing entries|
|Static check|Quick feedback|Block|
|Test|Authentication|Block|
|Build|Outputs are non-variable|Block|
|Clear.|Dependency and Keys|It's high-risk.|
|Deployment in advance|Environmental validation|Interrupt and preserve the environment|
|Greyscale Release|Watch the flow.|Indicator Autorolling|
|Full Release|Officially online.|Supporting one key rollback|

## General script skeleton

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

## Deployment and Rollback Points

|Points|Practice|
| --- | --- |
|It's not gonna change.|Naming as submitting SHA or version number, disables overwrite|
|I'll be right back.|Duplication of results without duplication of resources|
|Health checkup|Query end after deployment, fail.|
|Greyscale|Proportional step-down and observation of indicators|
|Auto Roll Back|Error rate or delay exceeding threshold immediately to the previous version|
|Rollback|Regularly verify rollback paths available|
|Change of record|Record version, operator, time and result|

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

## Common Error Table

|Easy to step on.|Actual|Reasons and correct practices|
| --- | --- | --- |
|CI Installation with ⟦0 instead of locking|_Other Organiser|Use ⟦0/ 1|
|Cache key without lock file|To Expire Dependence|Literally lock, Hash.|
|Duplicate each stage|The water line is slow.|We'll build it once, and the product will pass through.|
|Print Key to Log|Leak.|Use the environment variable and hide the output|
|No health check-ups deployed|Get on the line.|Query Endpoint After Deployment|
|No Auto Rolling|It's not working.|Over-threshold indicator immediately.|
|Skip the test.|Defective production|Only skips with a clear mandate|
|Scripts cannot be reproduced locally|Could not initialise Bonobo|Same script, with environment variables|

## Self-Detected List

- [ ] C.I. Scripts can be executed locally, act in the same way.
- [ ] Reliance lock installation, Cache keys containing locked files.
- [ ] The product is not subject to change and its verification value.
- [ ] Deployment with health check-ups and automatic rollback.
- [ ] Rolling back to regular exercises.

<!-- appendix:v3 -->

## Zero base details: CI flow line template

### What is it?

C.I. Waterlines are "a series of checks that run automatically after each submission."
There are three characteristics of a good water line:** fast, stable and clear information on failures.**

### It's a life metaphor.

|Phase|A metaphor.|Annotations|
| --- | --- | --- |
|Checkout and Cache|- Oh, my God.|Load dependency, reset cache as much as you can.|
|Static check|Check|lint, type check, shellcheck|
|Test|Receiving and Inspection|Modules and Integration Test|
|Build|Pack up.|Output products, constructed only once|
|Release|Delivery|It's in the environment and it can roll back.|

### Template I: Universal Multilingual Projects

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

### Template 2: Shell Script Repository

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

### Template III: Docker mirroring and scanning

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

### Five moves to speed up the water line.

|Means|Effects|
| --- | --- |
|Cache dependent (⟦0)|Saves every download time|
|Zero, cancel the old job.|Don't waste the parallel amount.|
|Split|Time for machine count.|
|Run the affected bag only (monorepo)|It's a lot shorter.|
|Container Mirror Cache|Accelerating mirror construction|

### Four rules that make the line credible.

```text
1. 只构建一次：制品用 commit SHA 命名，各环境复用同一份
2. 密钥进 Secrets：绝不写在 YAML 里
3. 失败要能定位：日志分级、保留测试报告与制品
4. 关键检查不许跳过：类型检查、测试、漏洞扫描都是门禁
```

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|Rebuild Every Environment|It's not a test.|Build it once, reuse it.|
|Use Zero.|Version may be inconsistent with Lockfile|C.I. With zero.|
|Key to YAML|Discovery.|Use Secrets|
|No, it's not.|Stuffed task occupancy.|Timeout for each job|
|Cache does not contain|To Expire Dependence|Lockfile, Hash.|
|All Check Threads in|It's slow and hard to locate.|Split|
|Just run the test and build it.|I didn't see it coming.|Build into the waterline|
|I don't have a deadline.|Storage Unlimited Growth|Setup ⟦0|

### Learn how to measure yourself.

- [ Laughs ] Can you tell me about the five typical stages of C.I.
- [ Chuckles ] Know why the C.I. needs to use zero, not one.
- [ Chuckles ] At least three moves to speed up the water line.
- [ Laughs ] Know why "only once" is important.
- [ ] Can write a waterline for Shell warehouse, shellcheck and bats.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeats, experiments and deliveries around "CI, flow lines, cache keys", each result being checked by someone else.

Add a strict pattern, then verify the path of success and failure in the temporary directory.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with "CI Script Library"?
2. Without it, what concrete consequences would there be?
3. What's it got to do with the waterline?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Write a script with ⟦0 and verify success and failure in a temporary directory.

Mission requests:

- The result must be checked, not just "I understand."
- It's not like it's going to be a "c" or "waterline."
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

## It's the end of this class.

- The core issue is that "CI Script Template Library" is not an isolated term, but addresses a specific type of problem in Shell.
- The key relationship is to separate the duties of "CI" from "waterlines", and then understand the applicable boundaries of the Cache Key.
- The test: to explain normal scenes, border conditions and failures is truly mastery.
- Next step: Write down three points in your own words and do the test.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** CI Script Templates

**Summary:** Pipeline skeleton, staging, health checks and auto rollback.

**Category:** Shell  
**Level:** Progress
**Key terms:**CI, Cache key, deployment, health checkup, automatic rollback

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: progress
- Applicable context: Bash 5 / POSIX Shell
- Source: Internal structured curriculum and engineering practices
- Related topics: CI, flow lines, cache keys, deployments, health checks, automatic rollback
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

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
- Relaid terms: CI, Cache key, deployment
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning Objectives |
|Pre-knowledge| Pre-knowledge |
|Waterline, quick.| Quick Look at the Pipeline Stage |
|General script skeleton| Generic Script Skeleton |
|Deployment and Rollback Points| Deployment and rollback points |
|Common Error Table| Common Errors Comparison Table |
|Self-Detected List| Self Test Checklist |
|Zero base details: CI flow line template| Zero Basics Explained in Detail: CI Pipeline Template |
|Let's practice.| Hands on exercise: |
|It's the end of this class.| Lesson Summary |

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

