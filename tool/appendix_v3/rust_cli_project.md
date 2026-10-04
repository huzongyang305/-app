## 零基础详解：写一个 Rust 命令行工具

### 一句话说清它是什么

Rust 非常适合写 CLI：编译成单个二进制、启动快、无运行时依赖。
一个完整的 CLI 需要四件套：**参数解析、错误处理、配置读取、日志输出**。

### 用生活比喻理解

| 库 | 比喻 | 作用 |
| --- | --- | --- |
| `clap` | 前台登记 | 解析参数与子命令 |
| `anyhow` | 通用报错卡 | 应用层错误，带上下文 |
| `thiserror` | 分类报错卡 | 库层错误，区分类型 |
| `serde` | 通用翻译 | 读写 JSON 或 TOML |
| `tracing` | 记录仪 | 分级日志 |

### 项目结构

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

### 参数定义：derive 风格

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

`clap` 会自动生成 `--help` 与 `--version`，还会校验必填参数。

### 入口：一行解析，一处处理

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

`main` 返回 `Result` 时，出错会自动打印错误并以非 0 退出。

### 错误处理：加 context 而不丢原因

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

**要点**：`bail!` 提前返回错误，`with_context` 保留原因链，日志用结构化字段。

### 配置读取与校验

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

### 集成测试：直接跑二进制

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

### 发布

```bash
cargo fmt
cargo clippy -- -D warnings
cargo test
cargo build --release

# 交叉编译到其他平台（静态二进制）
cargo install cross
cross build --release --target x86_64-unknown-linux-musl
```

产物在 `target/release/mycli`，可直接分发。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `unwrap()` 处理输入 | 用户看到 panic | 用 `?` 加 context |
| 手写参数解析 | 帮助信息不全 | 用 clap derive |
| 错误信息没上下文 | 不知道哪个文件出错 | 用 `with_context` |
| 配置不校验 | 运行到一半才崩 | 加载后立即校验 |
| 日志用 println | 无法分级与关闭 | 用 tracing |
| 输出直接覆盖源文件 | 出错丢数据 | 写临时文件再重命名 |
| 忘记处理管道关闭 | 报 Broken pipe | 处理 `ErrorKind::BrokenPipe` |
| 只测函数不测 CLI | 参数解析出错没人发现 | 加 assert_cmd 集成测试 |

### 学完自测

- [ ] 能说出 clap、anyhow、thiserror 各自的分工。
- [ ] 知道 `main` 返回 `Result` 会带来什么行为。
- [ ] 能说出 `bail!` 与 `with_context` 的用途。
- [ ] 知道配置加载后应该立刻做什么。
- [ ] 能用 assert_cmd 写一个 CLI 集成测试。
