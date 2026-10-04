# Shell, secure the script.

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Advanced

## Learning objectives

- It's not like you can explain in your own words what the Shell script has to do with security, but it doesn't.
- The relationship between Script Security, Command Injection, Path Crossing and Mktemp is clear.
- It's a way to put back the knowledge of "shell" and point out its boundaries with each other.
- It is possible to complete this course and check its results using acceptance standards.

> Synopsis of sentence: Commands for protective, path verification, safe removal and operational strengthening.

## Pre-knowledge

- The first lesson is the CI Script Library; if available, this course can be used for self-measurement.
- This course stage: Advanced. It is recommended to have a complete basis in the same direction, reading longer code, configuration or system design instructions.
- Before we begin: Script security, command injections, route crossing.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Quick check of common risks

|Risk|Trigger Method|I'm trying to fix it.|
| --- | --- | --- |
|Injection|User input command|Parameters, White List Verification|
|Path Passes|Enter Zero.|Normalize Paths and Verify Prefix|
|Emblem|Variables are used directly for matching|Quote, zero. End option.|
|Error Data|The variable is empty and causes zero.|It's not empty and the path is legal.|
|Sensitive information leaks|Log or ⟦Pile Key|De-sensitization, temporary closure|
|Supply chain risk|Directly After Download|Verify Hashi's signature.|
|It's too much.|Run with root, chmod 777|Minimum Permissions, Special Account|
|Temporary File Competition|Predictable file name to be taken.|Use Zero.|

## Enter a quick check.

|Scenes|Writing|
| --- | --- |
|Required variables|Zero.|
|Allow numbers only| `[[ "$count" =~ ^[0-9]+$ ]] \|\|♪ "count must be the number" ♪|
|Only white lists.| `case "$env" in dev\|staging\|prod; *) die "unlawful environment";|
|File must exist| `[[ -f "$file" ]] \|\|♪ The file doesn't exist ♪|
|Path must be in the directory|Standardized prefix|
|Parameters|Zero, not a string.|

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

die() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

# 1. 下载后校验哈希，绝不直接执行
fetch_verified() {
  local url="$1" expected_sha="$2" dest="$3"
  curl --fail --location --silent --show-error --output "$dest" "$url" \
    || die "下载失败：$url"
  local actual
  actual=$(sha256sum "$dest" | awk '{print $1}')
  [[ "$actual" == "$expected_sha" ]] || { rm -f -- "$dest"; die "校验失败：$url"; }
}

# 2. 安全删除：断言路径在允许的根目录内
safe_remove() {
  local target="$1"
  local allowed_root="/var/tmp/app"
  [[ -n "$target" ]] || die "目标为空"
  local resolved
  resolved=$(realpath -m -- "$target")
  case "$resolved" in
    "$allowed_root"/*) ;;
    *) die "拒绝删除允许范围之外的路径：$resolved" ;;
  esac
  rm -rf -- "$resolved"
}

# 3. 避免把用户输入拼成命令
run_with_args() {
  local pattern="$1"
  # 用参数数组，shell 不会再做分词与元字符解析
  grep --fixed-strings -- "$pattern" /var/log/app.log
}

# 4. 敏感操作前临时关闭 xtrace，避免密钥进入日志
with_secret() {
  local secret="$1"
  local had_xtrace=0
  [[ "$-" == *x* ]] && had_xtrace=1
  set +x
  printf '%s' "$secret" > /dev/null      # 这里替换为真实的敏感调用
  (( had_xtrace )) && set -x
}

# 5. 临时文件用 mktemp 并自动清理
readonly WORK_DIR="$(mktemp -d)"
trap 'rm -rf -- "$WORK_DIR"' EXIT
```

## Operating environment reinforced speed check

|Item|Practice|
| --- | --- |
|Run Account|Dedicated Low Permission Account, avoid root|
|File Permissions|Script 750, configuration 640.|
| umask |Set 027 to avoid new files being readable for other users|
|Environmental variables|Do not trust ⟦0, use absolute path or visible settings|
|Log|De-sensitization, restricted access, centralized collection|
|Dependence|Fixed Version and Validation Source|
|Audit|Recording implementers, parameters and results|

## Common Error Table

|Easy to step on.|Actual|Reasons and correct practices|
| --- | --- | --- |
|Run a spell string with ⟦0|Injection|Arguments, avoid eval|
| `curl ... \| bash` |Supply chain attack|Check Hashi for execution.|
|Variables without quotation marks|Spell & Quote|It's all right.|
|Do not verify path before deleting|Missed System Directory|Unempted and prefixed.|
|Predictable temporary file names|Contest and Symbolic Link Attack|Use Zero.|
|Zero, print key.|Log leak|Sensitivity is temporarily closed|
|Script 777 Permissions|It's been tampered with by any user.|750 and a special account.|

## Self-Detected List

- [ ] All external inputs are verified by a white list or format.
- [ ] Disruptive operation assertion that the path is not empty and within permissible limits.
- [ ] Downloads must be validated before they are used.
- [ ] The temporary file is ⟦ and cleaned in the track.
- [ ] Scripts run with minimal permission and no sensitive information in the log.

<!-- appendix:v3 -->

## Zero-basic details: script secure.

### What is it?

The script is secure against three things:** the incorrect deletion of its own data,** an attack by someone else's file name/entry** and** a leaked key.**
The three lines are: input validation, secure call and external key.

### It's a life metaphor.

|Risk|A metaphor.|Lines|
| --- | --- | --- |
|Variables are empty|Wrong address. Delivery to someone else.|Non-empty verification + quotation marks|
|Synchronising folder|The name's been taken apart.|Split with NUL|
|The temporary file was robbed.|Someone took your locker in advance.| `mktemp` |
|Key entry log|It's written on the wall.|Environmental variable + dissensitisation|
|Injection|There's a fake order in there.|Avoid ⟦0, use arrays.|

### Three rules.

```bash
# 铁律一：变量必须非空校验，且一律加引号
: "${TARGET:?拒绝执行：TARGET 未设置}"
rm -rf -- "$TARGET"

# 铁律二：临时文件用 mktemp，别自己拼名字
readonly TMP_FILE="$(mktemp)"
trap 'rm -f -- "$TMP_FILE"' EXIT

# 铁律三：密钥只从环境变量或密钥服务读取，永不写进脚本
: "${API_TOKEN:?缺少 API_TOKEN}"
curl -H "Authorization: Bearer $API_TOKEN" "$URL"
```

### Filename attacks and security.

```bash
# 危险：文件名含空格或换行会被拆坏
for f in $(find . -name '*.log'); do rm "$f"; done

# 安全一：find 自带执行（推荐）
find . -name '*.log' -exec rm -f -- {} +

# 安全二：NUL 分隔
find . -name '*.log' -print0 | while IFS= read -r -d '' f; do
  rm -f -- "$f"
done

# 安全三：Bash 数组 + globstar
shopt -s nullglob
files=(./logs/**/*.log)
((${#files[@]})) && rm -f -- "${files[@]}"
```

### Injection: Why not eval

```bash
# 危险：用户输入直接参与命令构造
name="$1"
eval "echo $name"          # 传入 '; rm -rf /' 就完了

# 安全：用数组传参，避免 shell 再解析一次
args=(--user "$1" --output "$2")
curl "${args[@]}" https://example.com

# 需要执行外部命令时，明确分隔参数
cmd="$1"; shift
"$cmd" "$@"
```

### Permissions & Minimize

```bash
umask 077                       # 新建文件默认只有自己能读写
chmod 600 "$SECRET_FILE"        # 密钥文件权限收紧
chmod +x script.sh              # 只给需要的执行权限

# 不要用 sudo 跑整段脚本，只给真正需要的命令
sudo systemctl restart myapp
```

### I don't know.

```bash
mask() {
  local value="$1"
  if ((${#value} <= 8)); then
    printf '***'
  else
    printf '%s****%s' "${value:0:4}" "${value: -4}"
  fi
}

echo "使用令牌 $(mask "$API_TOKEN") 访问接口"
```

** Never print the full token, password, ID number, bank card number.

### Common assault and defense.

|Attack!|Trigger|Protection|
| --- | --- | --- |
|Path Passes|Collapse User Input Paths|Validation does not contain ⟦1 prefix|
|Injection|⟦0 or string command|Use arrays, don't eval|
|Symbolic Link Attack|Predictable temporary file names| `mktemp` |
|Increase Permissions|Script executed with relative path|Use absolute path to reset PATH|
|Sensitive information leaks|Key to Script or Log|Environmental variable + dissensitisation|
|Embezzlement|⟦0 is empty|Quote + Non-Air Validation|

```bash
# 路径穿越防护示例
safe_join() {
  local base="$1" rel="$2"
  local full
  full="$(realpath -m -- "$base/$rel")"
  case "$full" in
    "$base"/*) printf '%s' "$full" ;;
    *) echo "非法路径：$rel" >&2; return 1 ;;
  esac
}
```

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|Variables without quotation marks|Unexpected space or empty value|It's all right.|
|Use ⟦0 to process input|Injection|Alter array transfer.|
|Predictable temporary file names|Carjacked or marked link attacked| `mktemp` |
|Script|It's leaky and hard to rotate.|Environmental variable or key service|
|Log print full token|Log Leak|Output after dissension|
|Run the script with sudo|It's too much.|Just the orders you need.|
|Use relative paths for privileged operations|PATH hijacking|Absolute Path + Reset PATH|
|Do not verify user path|Path Passes|Zero plus prefix.|

### Handheld practice: Cleaning the script

```bash
#!/usr/bin/env bash
set -euo pipefail
umask 077

readonly BASE_DIR="${1:?用法：$0 <待清理目录> [保留天数]}"
readonly KEEP_DAYS="${2:-7}"

# 1. 绝对化并确认在允许范围内
readonly REAL_BASE="$(realpath -m -- "$BASE_DIR")"
if [[ "$REAL_BASE" == "/" || "$REAL_BASE" == "$HOME" ]]; then
  echo "拒绝在 $REAL_BASE 上执行清理" >&2
  exit 1
fi
[[ -d "$REAL_BASE" ]] || { echo "目录不存在：$REAL_BASE" >&2; exit 1; }

# 2. 先列出，再删除，全程使用 -print0
count=0
while IFS= read -r -d '' file; do
  ((count++))
  echo "删除：$file"
  rm -f -- "$file"
done < <(find "$REAL_BASE" -type f -mtime "+$KEEP_DAYS" -print0)

echo "共清理 $count 个文件"
```

### Learn how to measure yourself.

- [ Chuckles ] Can you say three iron rules that make the script safe?
- [ ] Know why you can't process user input.
- [ ] Three ways to name a secure file.
- [ ] Know where the key should be read.
- [ Laughs ] It's the idea of protection.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of practice: Repeat, experiment and deliver around "Script security, command injections, path crossing", each result being checked by someone else.

Add a strict pattern, then verify the path of success and failure in the temporary directory.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with Shell?
2. Without it, what concrete consequences would there be?
3. What does it have to do with "injection"?

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

- The result must be checked, not just “I understand”.
- At least cover the key words "script safety" and "command injection".
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

## It's the end of this class.

- “Shell script secure” is not an isolated term, but a specific type of problem in the ‘shell’.
- The key relationship: first, to distinguish between "script safety" and the duty of "order injection", then to understand what's going on with "pathway crossing."
- The test: to explain normal scenes, border conditions and failures is truly mastery.
- Next step: Write down three points in your own words and do the test.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Shell Script Security

**Summary:** Injection defense, path validation, safe deletion and hardening.

**Category:** Shell  
**Level:** Advanced
**Key terms:** Script security, command injection, path crossing, mktemp, minimum access, supply chain

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: advanced
- Applicable context: Bash 5 / POSIX Shell
- Source: Internal structured curriculum and engineering practices
- Related topics: Script security, command injections, path crossing, mktemp, minimum access, supply chain
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Shell Script Security** focuses on Injection defense, path validation, safe deletion and hardening.

### Learning Outcomes

- Explain what **Shell Script Security** solves and when it should be used.
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

- Topic: **Shell Script Security**
- Relaid terms: Script secure, command injection, path crossing, mktemp
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning Objectives |
|Pre-knowledge| Pre-knowledge |
|Quick check of common risks| Common Quick Risk Checks |
|Enter a quick check.| Enter checksum |
|Operating environment reinforced speed check| Operational environment reinforcement quick check |
|Common Error Table| Common Errors Comparison Table |
|Self-Detected List| Self Test Checklist |
|Zero-basic details: script secure.| Zero Basics Explained in Detail: Script Security Reinforcement |
|Let's practice.| Hands on exercise: |
|It's the end of this class.| Lesson Summary |

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

