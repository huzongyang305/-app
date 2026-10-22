# Shell and Bash scripts

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Foundation = Estimated duration: 14 minutes

## Learning objectives

- It is possible to explain in its own words what the "shell and Bash scripts" have solved, rather than simply using them.
- The relationship between Shell, Bash, Script and Pipeline is clear.
- It's a way to put back the knowledge of "shell" and point out its boundaries with each other.
- It is possible to complete this course and check its results using acceptance standards.

> Synopsis of sentence: variable quotes, robust package and pipe combination.

## Pre-knowledge

- The basic file, command line or browser operation is performed; the key words of this course are checked first when there are unfamiliar terms.
- This course stage: Foundation. It is recommended to read and write simple codes or commands, with basic concepts such as variables, input output, etc.
- Read it first: Shell, Bash, script.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Why do you have to learn, Shell?

The construction, deployment, log processing and automation are almost all in the command line. Shell is** the most popular glue language: it combines small tools into streaming water lines with a default presence for all Linux environments.

## Basic

|Elements|Annotations|
| --- | --- |
|Variables|Zero, one or two.|
|Quote|Double quote allows the variable to be expanded, single quote output; always include spaces|
|Exit Code|0 for success, non-0 for failure, ⟦ to read the results of a previous command|
|Conditions|It's an enhanced version of Bash.|
|Loop| `for f in *.log; do ...; done`，`while read -r line; do ...; done` |
|Functions|⟦ 0, take 1 and 2 parameters.|

## A robust setup that must be mastered.

The three sets that are commonly used at the beginning of scripts: ⟦0 (in error or exit), 1 (in errors reported using undefined variables) and 2 (any command failed in a conduit is considered to be unsuccessful).Without these settings, the script will continue after an error, creating problems that are difficult to trace.

## Pipe and Text Processing

The essence of Shell is a combination: ⟦0 filter, 1 replacement, <2⟧ sorted by column, ̄3⟧4⟧ re-ordering, ‘5⟧ columns, =6 batch execution and 7⟧ location files.Use current conduits for processing large files to avoid reading all memory.

## Safety and portability

1. Both variables and paths are quoted in order to prevent spaces from being expanded with wildcards.
2. Prints the target before deleting: ⟦0 and performs non-empty verification of variables.
3. Checks whether the dependency is installed with ⟦0.
4. It's a lot more funky than that.
5. When it comes to complex logic (JSON parsing, convulsion, error retry), use Python first and not hard copy Bash.

## Common uses

Local development of scripts (first-key start, clean cache), CI step, log analysis (static error code Top10), batch renaming and backup, container entry script.

## It's the end of this class.
Shell's goal is** to quickly and reliably combine existing tools. Remember three sets + quotes that avoid 80% of script accidents; complex needs change language decisively.

<!-- appendix:v1 -->

## Bash, check.

|Scenes|Writing|Annotations|
| --- | --- | --- |
|Variable Values| `name="tom"` |We can't have room on either side.|
|Reference Variables| `"$name"` |Double quotes to keep spaces and avoid semiwords|
|Default|Zero.|No default set or empty|
|Checked|Zero.|Quit without setting a direct error|
|Length| `${#name}` |String Length|
|Intercept| `${name:0:3}` |Substring|
|Replace| `${path//a/b}` |Replace All|
|Command Result| `now=$(date +%F)` |It's better than an inverted sign.|
|Calculator.| `$((a + b))` |Integer Operations|
|Conditions| `if [[ -f "$file" ]]; then ... fi` |I don't think so.|
|File judgement|Zero files, one directory, two can be executed, three are not empty.|Common Tester|
|Loop| `for f in *.log; do ... done` |Note wildcards and spaces|
|Line-by-line| `while IFS= read -r line; do ... done < file` |Zero, keep the backslash.|
|Numeric| `arr=(a b c)`、`"${arr[@]}"` |We're gonna have to start with a quote.|
|Parameters| `"$@"` |Forwarding Parameters in Correct Form|
|Functions| `f() { local x="$1"; }` |Use ⟦0 to limit the range|
|Return value|⟦1 output data|State Code Separated from Data|
|Strict Mode| `set -euo pipefail` |Error Retrieval, Undefined Variable. Conduit failure visible|

## Quick check of common tools

|Purpose|Command|
| --- | --- |
|Filter Rows| `grep -n`、`grep -v`、`grep -c` |
|Remove Columns| `awk '{print $1, $3}'` |
|Replace| `sed 's/old/new/g'` |
|Sort to Heavy| `sort \| uniq -c` |
|Number of statistical lines| `wc -l` |
|View Disk| `df -h`、`du -sh *` |
|View Process| `ps aux \| grep app`、`pgrep -af app` |
|View Ports| `ss -tlnp` |
|Look at the end of the log| `tail -f app.log` |
|Time job| `crontab -e`、`systemctl list-timers` |
|Network request| `curl -fsSL`、`curl -o file url` |
|Pack up.| `tar -czf a.tgz dir/` |
|Verify| `sha256sum file` |

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
| `name = "tom"` | `command not found: name` |Values are not available: ⟦|
|Zero, no quotes.|Disassembly multiple arguments when file name is spaced|It's all written.|
|Use an inverted frame command|It's complicated, it can go wrong.|Use Zero.|
| `for f in $(ls)` |Space and line break.|Use wildcards, ⟦0 or 1|
|I don't remember.|The name of the variable is wrong, but it's empty.|Plus zero.|
|We'll continue when we fail.|Follow-up command running in error directory| `cd "$dir" \|\| exit 1` |
|It's empty.|Can not open message|Validation variables are not empty: \[-n "$dir"]|\| exit 1` |
|Use ⟦0 for output transfer.|Different shell behavior.|Use Zero.|
|Temporary file by fixed name|And execute each other.|Use ⟦0 and clean up with 1|
|Failed in Pipe|The first half goes on.|Plus zero.|
|The numbers are more like zero.|Error by string|Use 0 or 1|
|Zero in relative path.|Command not found|Use absolute path and visible settings|

## Self-Detected List

- [ ] Script starts with ⟦1.
- [ ] Double quotes for all variables.
- [ ] Managing temporary resources with zero and one.
- [ ] Delete pre-validation targets to avoid error or deletion.
- [ ] ⟦ mission uses absolute path and logs.

<!-- appendix:v2 -->

## Zero based details: Shell Scripts are "Current Command."

### What is it?

Shell Script is ** an order to knock you in the terminal and enter it in sequence.**
Its strengths are the organization of existing tools; its weaknesses are complex data structures and calculations.

### It's a life metaphor.

|Concept|A metaphor.|Annotations|
| --- | --- | --- |
| shebang |First line of instructions|Tell the system which interpreter.|
|Variables|Facilities|Save a value, then quote|
|Quote|Packaging Method|Whether to expand variables and wildcards|
|Exit Code|Hand over the orders.|0 for success, non-0 for failure|
|Pipes|Waterline|Give the last output to next.|

### Dismantling the first script by line

```bash
#!/usr/bin/env bash
set -euo pipefail                 # 健壮性三件套

readonly NAME="${1:-朋友}"         # 取第一个参数，没给就用默认值

echo "你好，${NAME}！"
echo "当前目录：$(pwd)"
```

|Okay.|Annotations|
| --- | --- |
| `#!/usr/bin/env bash` |Do it with a bah in PATH, more portable than an oscillator|
| `set -e` |We're not going anywhere without a mistake.|
| `set -u` |Error reporting when using undefined variables|
| `set -o pipefail` |If any of the rings fail, then the whole thing fails.|
|Zero.|Parameter default, simpler than ⟦|
| `$(pwd)` |Command Replace, embed command output into string|

### Quote: the difference between three ways

|Writing|Whether or not to expand the variable|Whether wildcards should be expanded|Use scene|
| --- | --- | --- | --- |
|Zero.|Yes|Yes|Output, Regular Expression|
|Zero.|Yes.|Yes|** Default selection**, package variable|
|No quotes.|Yes.|Yes.|Not really. It's easy to make mistakes.|

```bash
name="小明"
echo '$name'      # 输出 $name
echo "$name"      # 输出 小明
echo $name        # 能输出，但遇到空格会拆成多个参数
```

**Communications: always double quotes, unless you're quite certain that this is not required.**

### Variables and Parameters Scanning

|Writing|Meaning|
| --- | --- |
| `name=value` |It's worth it. We can't leave the equation on either side.|
| `"$name"` / `"${name}"` |Reference Variables|
|Zero.|Use default for empty hours|
| `"${#name}"` |String Length|
| `"$1"`、`"$2"` |Parameters 1, 2|
| `"$@"` |All parameters (maintain the boundary of each parameter)|
| `"$#"` |Number of parameters|
| `"$?"` |Last command exit code|
| `export NAME=value` |Export to Child Process|

### Command execution and judgement

```bash
if command -v git >/dev/null 2>&1; then
  echo "已安装 git"
else
  echo "请先安装 git" >&2
  exit 1
fi
```

Zero means losing both the standard output and the standard error, only "success or failure."

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|Add spaces to the grant| `name: command not found` |Zero, no spaces on either side.|
|Variables without quotation marks|Error encountering spaces or empty values|Zero.|
|Compare with 0|Only for string and space|Zero, note the square space.|
|Quantified|Consider it a reorientation.|Use 0, 1 and 2!|
|I don't remember.|You're still running.|We'll start with a zero.|
|Temporary files are not cleared|Residual garbage| `trap 'rm -f "$tmp"' EXIT` |
|Use 'ls' \| xargs rm` |There's a problem with the file name.| `find ... -print0 \| xargs -0` |
|Script is not executed.| `Permission denied` | `chmod +x script.sh` |

### Handheld exercise: Backup script with parameters and verification

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

### Learn how to measure yourself.

- [ Chuckles ] Can say each and every one of them.
- [ ] The distinction between single and double quotation marks can be explained.
- [ Laughs ] Know what that means.
- [ Laughs ] Can you tell me what the difference is?
- [ ] Can clean temporary files in scripts.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: repeat, experiment and deliver around "Shell, Bash, Script," each result is subject to scrutiny.

Add a strict pattern, then verify the path of success and failure in the temporary directory.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What did Shell and Bash Script solve?
2. Without it, what concrete consequences would there be?
3. What's it got to do with Bash?

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
- At least cover the key words "shell" and "Bash".
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Shell & Bash

**Summary:** Quoting, strict mode and pipelines.

**Category:** Shell  
**Level:** Foundation
**Key terms:**Shell, Bash, script, set-e

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: Foundation
- Applicable context: Bash 5 / POSIX Shell
- Source: Internal structured curriculum and engineering practices
- Related topics: Shell, Bash, scripts, pipes, set-e
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Shell & Bash** focuses on Quoting, strict mode and pipelines.

### Learning Outcomes

- Explain what **Shell & Bash** solves and when it should be used.
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

- Topic: **Shell & Bash**
- Relaid terms: Shell, Bash, Script
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Why do you have to learn, Shell?|Why do you have to learn, Shell?|
|Basic|Basic|
|A robust setup that must be mastered.|A robust setup that must be mastered.|
|Pipe and Text Processing|Pipe and Text Processing|
|Safety and portability|Security and portability|
|Common uses|Common uses|
|It's the end of this class.| Summary |
|Bash, check.|Bash, check.|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

