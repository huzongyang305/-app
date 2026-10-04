# Rust Operation: Command Line Tool

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Advanced

## Learning objectives

- It is possible to explain in its own words what "Rust Realism: The Commanding Tool" solves, not just the terminology.
- The relationship between "Rust", "CLI," "clap" and "anyhow" is clear, with one example.
- It's a way to put this subject back into Rust's knowledge system, and it shows the boundaries of an adjacent theme.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentence: clap parsing, bug processing, asert_cmd testing and publishing.

## Pre-knowledge

- The first lesson is "Rust unsafe, FFI and Ecology"; if you have it, you can use this course to test yourself.
- This course stage: Advanced. It is recommended to have a complete basis in the same direction, reading longer code, configuration or system design instructions.
- Before we begin: Rust, CLI, clap.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Objectives and structure

A CLI capable of reading, filtering, counting and exporting JSON/Forms. Structure: ⟦0 (decomposition parameters and schedule), 1 (testable business logic) and 2 (integrated testing).

## Parameter Parsing:

Define parameters with a divet declaration: The structural body adds ⟦, the field uses 1  and the sub commands use 2 . Clap automatically produces 3 ; completion and parameter validation is much more reliable than hand-written resolution.

## Error processing and output

The application layer uses `?` to spread along the path, and prints errors and exit codes with 3⟧; thiserror defines an error that can be determined by the reservoir.Output follows Unix habits: Normal results to stdout, logs and errors to sstderr, easy to combine.

## Read & Write and Sequence

Server + server_json handles configuration and output; large files are processed by BuffReader to avoid one-time reading of memory.Pay attention to CRLF, BOM and invalid UTF-8 (bytes as necessary or using lossy conversion).

## Test

The unit test overwrites the resolution and statistical function; integration tests call for a binary with an asserted stdout, stderr and exit code. Add ⟦1 and ⟦2 to CI.

## Release

A multi-platform product with a single output file; cross-compilation of matrices available for cros or GitHub Actions;You need to complete the README, license and version syntax (SemVer).

## It's the end of this class.
Rust CLI standard formula: **clap parsing anyhow/thiserror error + sequencation + asert_cmd test + multiplatform release**;The type system makes these tools almost "pull or stabilize."

<!-- appendix:v1 -->

## Common Curt

|Purpose| crate |Annotations|
| --- | --- | --- |
|Parameter Parsing| `clap`（derive） |Generate Help & Completion|
|Colour Output| `owo-colors`、`colored` |Terminal Coloring|
|Progress Bar| `indicatif` |Download and Batch Progress|
|Interactive hints| `dialoguer` |Select, confirm, enter|
|Configure Read| `figment`、`config` |Multisource|
|Sequence| `serde` + `serde_json` / `toml` |Structured data|
|Log| `tracing` + `tracing-subscriber` |Structured Log|
|Error| `anyhow` / `thiserror` |Apply and Library|
|Test CLI| `assert_cmd` + `predicates` |Claim stdout and exit code|
|Temporary documents| `tempfile` |Testing and intermediates|

```rust
use clap::Parser;
use std::path::PathBuf;

/// 统计文件行数
#[derive(Parser, Debug)]
#[command(name = "linecount", version, about)]
struct Args {
    /// 要统计的文件路径
    #[arg(value_name = "FILE")]
    path: PathBuf,

    /// 只统计非空行
    #[arg(short, long)]
    non_empty: bool,

    /// 显示每行长度
    #[arg(short = 'l', long, default_value_t = false)]
    lengths: bool,
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    let content = std::fs::read_to_string(&args.path)
        .map_err(|e| anyhow::anyhow!("读取 {} 失败: {e}", args.path.display()))?;

    let count = content
        .lines()
        .filter(|line| !args.non_empty || !line.trim().is_empty())
        .count();

    println!("{count}");
    Ok(())
}
```

## CLI, get used to it.

|Custom.|Annotations|
| --- | --- |
|Normal Output|Facilitate consumption of pipelines and other processes|
|Error and progress|Don't pollute|
|Exit code 0 means success|Failed to return non-zero|
|Supporting 0 / 1|clap automatically generated|
|Supported by 0|Read from Cargo.toml|
|Do not overwrite existing files|Default rejection or request|
|Respect for environmental variables|Proxy, Configuration Directory (01)|
|Could be interrupted by the pipe.|Handle ⟦0(Rust default, need to be visible)|

## Test quick.

```rust
#[test]
fn counts_lines() {
    use assert_cmd::Command;
    use predicates::prelude::*;

    let mut cmd = Command::cargo_bin("linecount").unwrap();
    cmd.write_stdin("a\n\nb\n")
        .arg("--non-empty")
        .arg("-")
        .assert()
        .success()
        .stdout(predicate::str::contains("2"));
}
```

## Common Error Table

|Easy to step on.|Actual|Reasons and correct practices|
| --- | --- | --- |
|Use ⟦0 for user input|Directly panic, ugly pile.|Return ⟦0 and output readable error|
|Hit the log to stdout|The pipes are contaminated.|Log and progress|
|Manually phrasing.|Missing help, missing borders|Clap Deve|
|Failed to return exit code 0|Script cannot judge failure.|returns ⟦0 or non-zero1⟧|
|Do not process large files|One-time reading memory resulting in OOM|Zero fluent treatment|
|Overwrite User File|Data lost|Default Refuse, Provide ⟦0|
|Hard Encoding Path Separator|Cross-platform Failed|Use 0 and 1|
|Ignore non-UTF-8 input|I'm sorry.|Use 0+1|
|Do not write integration test|Parameter Parsing Undetected|Use stdout/ exit code|
|Released without ⟦|Run slow|Published by 0|

## Self-Detected List

- [ ] Define parameters and automatically generate help.
- [ ] Data output to stdout, log and progress to sstderr.
- [ ] Error readable, exit code correct.
- [ ] Large documents are read in stream.
- [ ] Writing integration tests with ⟦0.

<!-- appendix:v3 -->

## Zero based details: Write a Rust command line tool

### What is it?

Rust is well placed to write CLI: compiled into a single binary, start fast and do not depend on it.
A full CLI requires four sets:** parameter resolution, error processing, configuration reading, log output.

### It's a life metaphor.

|Library|A metaphor.|Role|
| --- | --- | --- |
| `clap` |Front desk registration|Parsing Parameters and Subcommands|
| `anyhow` |General Error Reporting Card|Application Layer Error, Below|
| `thiserror` |Catalogue Error Card|Library Error, Distinguishing Type|
| `serde` |Generic translation|Read & Write JSON or TOML|
| `tracing` |Recorder|Level Log|

### Project structure

```text
mycli/
  Cargo.toml
  src/
    main.rs        入口：解析参数、调用、退出
    cli.rs         参数定义
    config.rs      配置读取与校验
    commands/      各子命令实现
  tests/
    cli.rs         集成测试
```

```toml
[package]
name = "mycli"
version = "0.1.0"
edition = "2021"

[dependencies]
clap = { version = "4", features = ["derive"] }
anyhow = "1"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
toml = "0.8"
tracing = "0.1"
tracing-subscriber = "0.3"

[dev-dependencies]
assert_cmd = "2"
predicates = "3"
```

### Parameter definition: Deviated style

```rust
use clap::{Parser, Subcommand};
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "mycli", version, about = "示例命令行工具")]
struct Cli {
    /// 输出详细日志
    #[arg(short, long, global = true)]
    verbose: bool,

    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// 处理指定文件
    Process {
        /// 输入文件路径
        input: PathBuf,
        /// 输出路径，省略则打印到屏幕
        #[arg(short, long)]
        output: Option<PathBuf>,
    },
    /// 显示统计信息
    Stats {
        #[arg(default_value = "data.json")]
        file: PathBuf,
    },
}
```

⟦0 will automatically generate 1⟧ and 2, and verify the required parameters.

### Entry: 1 line decomposition, 1 processing

```rust
fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();

    let level = if cli.verbose {
        tracing::Level::DEBUG
    } else {
        tracing::Level::INFO
    };
    tracing_subscriber::fmt().with_max_level(level).init();

    match cli.command {
        Command::Process { input, output } => process(&input, output.as_deref())?,
        Command::Stats { file } => stats(&file)?,
    }
    Ok(())
}
```

When `Result` returns, an error will automatically print and exit with a non-0.

### Error processing: Add context without losing cause

```rust
use anyhow::{bail, Context, Result};
use std::path::Path;

fn process(input: &Path, output: Option<&Path>) -> Result<()> {
    if !input.exists() {
        bail!("输入文件不存在：{}", input.display());
    }

    let text = std::fs::read_to_string(input)
        .with_context(|| format!("读取 {} 失败", input.display()))?;

    let result = transform(&text).context("处理内容失败")?;

    match output {
        Some(path) => {
            std::fs::write(path, &result)
                .with_context(|| format!("写入 {} 失败", path.display()))?;
            tracing::info!(path = %path.display(), "已写出结果");
        }
        None => println!("{result}"),
    }
    Ok(())
}
```

** Point: ⟦ early return error,  retention of cause chain, logs structured field.

### Configure Reading and Validation

```rust
use anyhow::{bail, Context, Result};
use serde::Deserialize;
use std::path::Path;

#[derive(Debug, Deserialize)]
struct Config {
    #[serde(default = "default_threads")]
    threads: usize,
    #[serde(default)]
    dry_run: bool,
}

fn default_threads() -> usize {
    4
}

impl Config {
    fn load(path: &Path) -> Result<Self> {
        let text = std::fs::read_to_string(path)
            .with_context(|| format!("读取配置 {} 失败", path.display()))?;
        let cfg: Config = toml::from_str(&text).context("配置格式不正确")?;

        if cfg.threads == 0 || cfg.threads > 256 {
            bail!("threads 必须在 1 到 256 之间，实际为 {}", cfg.threads);
        }
        Ok(cfg)
    }
}
```

### Integrated test: Run directly to binary

```rust
// tests/cli.rs
use assert_cmd::Command;
use predicates::prelude::*;

#[test]
fn prints_help() {
    Command::cargo_bin("mycli")
        .unwrap()
        .arg("--help")
        .assert()
        .success()
        .stdout(predicate::str::contains("Usage"));
}

#[test]
fn fails_on_missing_file() {
    Command::cargo_bin("mycli")
        .unwrap()
        .args(["process", "/definitely/missing.txt"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("不存在"));
}
```

### Release

```bash
cargo fmt
cargo clippy -- -D warnings
cargo test
cargo build --release

# 交叉编译到其他平台（静态二进制）
cargo install cross
cross build --release --target x86_64-unknown-linux-musl
```

The product's in the middle of nowhere, and it can be distributed directly.

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|Use ⟦0 to process input|User sees panic|Use ⟦0+context|
|Manual Parameter Parsing|Help incomplete.|Clap Deve|
|There's no context.|I don't know which file went wrong.|Use Zero.|
|Configure Unvalidated|We're not going to die until we get there.|Verify immediately after loading|
|Log with println|Could not initialise Bonobo|Use Tracing|
|Output directly overwrite source files|Error Dropping Data|Write temporary files and rename them|
|Forget the pipe.|Broken pope.|Handle ⟦0|
|It's only a function check. CLI|Parameter Parsing Undetected|Add asert_cmd integration test|

### Learn how to measure yourself.

- [ Laughing ] Can you tell me about the division of labour?
- [ Laughs ] Know what it's like to be back in the middle of nowhere.
- [ Laughs ] Can you tell me what it's for?
- [ ] Know what to do as soon as the configuration is loaded.
- [ ] Could write a CLI integration test with ansert_cmd.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of practice: Repeating, experimenting and delivering around Rust, CLI, each result being checked.

Let's get the cargo check through, then fill up ownership, wrong and parallel borders, and finally run clippy.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with Rust?
2. Without it, what concrete consequences would there be?
3. What's it got to do with CLI?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Writes a smallest example of Cargo, first with ⟦0 and then a border test.

Mission requests:

- The result must be checked, not just "I understand."
- "Rust" and "CLI," at least.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- project-verification:v1 -->

## Validation command and expected output

The project code does not read only " Compilable " , but repeats the results by a fixed command.

|Phase|Command|Expected output|
| --- | --- | --- |
|Format Check| `cargo fmt --check` |No format difference|
|Static check| `cargo clippy -- -D warnings` |No clippy warning|
|Run Test| `cargo test` |All tests passed.|

### Evidence of acceptance

- [ ] Save the complete output relying on installation and start-up orders.
- [ ] Run at least 3 tests containing an illegal input or failure path.
- [ ] Repeat the same operation twice and confirm that there are no duplicates or side effects.
- [ ] Record a failure code, wrong log and recovery steps.
- [ ] Provide an environmental version, start-up and rollback in README.

### Return and Roll

1. Start with an abandoned directory or temporary database to avoid contamination of real data.
2. Rerun all authentication commands after a logical change to confirm that they have not returned.
3. If you fail, roll back to the previous runable version and keep the failed log.
4. The reason for the location is supplemented by an automated test and re-execution process.
5. The lessons are included in the project ' s repertoire or in a note, which will form the next inspection.

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Rust CLI Project

**Summary:** clap, error handling, assert_cmd and release.

**Category:** Rust  
**Level:** Advanced
**Key terms:**Rust, CLI,

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: advanced
- Applicable environment: Rust 1.85+ / Cargo
- Source: Internal structured curriculum and engineering practices
- Related themes: Rust, CLI, klap, Anyhow
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

## Project Specification: Rust Actual: Command Line Tool

### Core scene

clap parsing, bug processing, asert_cmd testing and publishing.The goal of the project is to translate "Rust, CLI, cap, release" into a lively, testable and rolling delivery.

### Structures and data flows

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### Minimum Data Model

|Object|Key Fields|Constraints|
| --- | --- | --- |
|Enter entity|Rust, time and source.|Keys to verify, limit the length, etc.|
|Task entity|Status, priority, creation|It's legal, it can't be repeated|
|Result entity|Output, Error Code, Time|Sequencable. Errors.|
|Audit records|Operator, action, result, time|It's unmovable, searchable and dissensitive.|

### Receiving scenes

1. Normal path: The minimum input receives the expected output, leaving a log and an indicator.
2. Boundary path: Empty, maximum, duplicated data and super-long content are explicitly addressed.
3. Failed path: fast failure, retest or downgrade if you rely on excess time.
4. Paths, etc.: The execution of the same request will not have repeated side effects.
5. Roll back: The data are consistent and indicate the recovery time and impact.

<!-- project-delivery:v1 -->

## Project delivery

### Suggested warehouse structure

```text
src/main.rs
src/domain/
src/infra/
tests/
Cargo.toml
```

### Test Matrix

|Level|Overwrite|Minimum|Adoption of standards|
| --- | --- | ---: | --- |
|Unit Test|Field rules, boundaries and misclassification| 8 |It's normal. The border, the path to failure.|
|Integrated testing|Database, network, document or platform boundary| 3 |Use real boundaries and run again|
|End-to-end testing|Core User Path| 1 |Full run from input to output|
|Manually.|5 scenes listed in the document| 5 |Orders, output and conclusion records|

### Receiving and Inspection Data

```json
{
  "project": "rust_cli_project",
  "input": {"case": "normal", "value": 5},
  "expected": {"ok": true, "result": 5},
  "failure_case": {"value": -1, "error": "validation_error"},
  "idempotency_key": "demo-001"
}
```

### Duplicate Template

|Problem|Records|
| --- | --- |
|What was the original target?|I'll give you a description of the acceptable target.|
|What's going on?|Timeline, indicators and key logs|
|Which assumption was overturned?|Root causes and contributing factors|
|How do you roll back?|Steps, time-consuming and data validation|
|What's next?|Responsible persons, duration and certification|

> Project acceptance revolved around "Rust, CLI, clap": at least one normal path, one border entry, one failed recovery and one check.

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Rust CLI Project** focuses on clap, error handling, assert_cmd and release.

### Learning Outcomes

- Explain what **Rust CLI Project** solves and when it should be used.
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

- Topic: **Rust CLI Project**
- Related terms: Rust, CLI, clap, anyhow
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Objectives and structure|Objectives and structure|
|Parameter Parsing:|Parameter Parsing:|
|Error processing and output|Error Handling and Output|
|Read & Write and Sequence|Read & Write and Sequence|
|Test| Testing |
|Release| Release |
|It's the end of this class.| Summary |
|Common Curt|Common Curt|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

