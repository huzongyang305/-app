## 常用 crate 速查

| 目的 | crate | 说明 |
| --- | --- | --- |
| 参数解析 | `clap`（derive） | 生成帮助与补全 |
| 彩色输出 | `owo-colors`、`colored` | 终端着色 |
| 进度条 | `indicatif` | 下载与批处理进度 |
| 交互提示 | `dialoguer` | 选择、确认、输入 |
| 配置读取 | `figment`、`config` | 多来源合并 |
| 序列化 | `serde` + `serde_json` / `toml` | 结构化数据 |
| 日志 | `tracing` + `tracing-subscriber` | 结构化日志 |
| 错误 | `anyhow` / `thiserror` | 应用与库分别使用 |
| 测试 CLI | `assert_cmd` + `predicates` | 断言 stdout 与退出码 |
| 临时文件 | `tempfile` | 测试与中间产物 |

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

## CLI 习惯速查

| 习惯 | 说明 |
| --- | --- |
| 正常输出走 stdout | 便于管道与其他程序消费 |
| 错误与进度走 stderr | 不污染 stdout |
| 退出码 0 表示成功 | 失败返回非零（`std::process::ExitCode`） |
| 支持 `-h` / `--help` | clap 自动生成 |
| 支持 `--version` | 从 Cargo.toml 读取 |
| 不覆盖已有文件 | 默认拒绝或要求 `--force` |
| 尊重环境变量 | 代理、配置目录（`XDG_*` / `%APPDATA%`） |
| 可被管道中断 | 处理 `SIGPIPE`（Rust 默认忽略，需显式处理） |

## 测试速查

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

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `unwrap()` 处理用户输入 | 报错时直接 panic，堆栈难看 | 返回 `anyhow::Result` 并输出可读错误 |
| 把日志打到 stdout | 管道结果被污染 | 日志与进度打 stderr |
| 手动解析 `args()` | 帮助信息缺失、边界遗漏 | 用 clap derive |
| 失败仍返回退出码 0 | 脚本无法判断失败 | 返回 `Err` 或非零 `ExitCode` |
| 不处理大文件 | 一次性读入内存导致 OOM | 用 `BufReader` 流式处理 |
| 覆盖用户文件 | 数据丢失 | 默认拒绝，提供 `--force` |
| 硬编码路径分隔符 | 跨平台失败 | 用 `PathBuf` 与 `join` |
| 忽略非 UTF-8 输入 | `read_to_string` 报错 | 用 `read` + `String::from_utf8_lossy` |
| 不写集成测试 | 参数解析改动无人发现 | 用 `assert_cmd` 测 stdout / 退出码 |
| 发布未加 `--release` | 运行速度慢 | 发布用 `cargo build --release` |

## 自测清单

- [ ] 用 clap derive 定义参数并自动生成帮助。
- [ ] 数据输出到 stdout，日志与进度到 stderr。
- [ ] 错误可读，退出码语义正确。
- [ ] 大文件使用流式读取。
- [ ] 用 `assert_cmd` 写集成测试。
