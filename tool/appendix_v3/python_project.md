## 零基础详解：从零做一个 Python 小项目

### 一句话说清它是什么

一个能交付的 Python 项目，除了能跑，还要有：**清晰目录、依赖声明、配置外置、日志、测试、一键运行**。
下面用一个「日志分析 CLI」把这几件事串起来。

### 用生活比喻理解

| 目录 | 比喻 | 说明 |
| --- | --- | --- |
| `src/` | 车间 | 真正的代码 |
| `tests/` | 验收区 | 自动化测试 |
| `pyproject.toml` | 产品说明书 | 依赖、脚本、构建配置 |
| `.env.example` | 样例表单 | 告诉别人要配哪些变量 |
| `README.md` | 使用手册 | 怎么装、怎么跑 |

### 推荐目录结构

```text
loganalyzer/
  pyproject.toml
  README.md
  .env.example
  src/loganalyzer/
    __init__.py
    cli.py           命令行入口
    config.py        配置读取与校验
    parser.py        纯函数：解析日志行
    report.py        生成报表
  tests/
    test_parser.py
    test_report.py
```

### 依赖与入口声明

```toml
[project]
name = "loganalyzer"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = ["httpx>=0.27"]

[project.optional-dependencies]
dev = ["pytest>=8", "pytest-cov>=6", "mypy>=1.11", "ruff>=0.6"]

[project.scripts]
loganalyzer = "loganalyzer.cli:main"

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.pytest.ini_options]
addopts = "-q --cov=loganalyzer --cov-report=term-missing"
```

装完就能用命令行的 `loganalyzer` 命令，不用记 `python -m ...`。

### 把纯逻辑和 IO 分开

```python
# parser.py —— 纯函数，最容易测
import re
from dataclasses import dataclass
from datetime import datetime

LINE = re.compile(
    r"(?P<ts>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+"
    r"(?P<level>INFO|WARN|ERROR)\s+(?P<msg>.*)"
)


@dataclass(frozen=True)
class Entry:
    ts: datetime
    level: str
    message: str


def parse_line(line: str) -> Entry | None:
    match = LINE.match(line.strip())
    if not match:
        return None
    return Entry(
        ts=datetime.strptime(match["ts"], "%Y-%m-%d %H:%M:%S"),
        level=match["level"],
        message=match["msg"],
    )
```

```python
# report.py —— 只做统计，不碰文件
from collections import Counter
from collections.abc import Iterable

from .parser import Entry


def summarize(entries: Iterable[Entry]) -> dict[str, object]:
    levels = Counter(e.level for e in entries)
    return {
        "total": sum(levels.values()),
        "levels": dict(levels),
    }
```

### 命令行入口

```python
# cli.py
import argparse
import logging
import sys
from pathlib import Path

from .parser import parse_line
from .report import summarize


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="loganalyzer", description="日志统计工具")
    parser.add_argument("path", type=Path, help="日志文件路径")
    parser.add_argument("-v", "--verbose", action="store_true", help="输出调试日志")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )

    if not args.path.is_file():
        logging.error("文件不存在：%s", args.path)
        return 2

    entries = []
    for lineno, line in enumerate(args.path.read_text(encoding="utf-8").splitlines(), 1):
        entry = parse_line(line)
        if entry is None:
            logging.debug("第 %d 行格式不符，已跳过", lineno)
            continue
        entries.append(entry)

    report = summarize(entries)
    print(f"总条数：{report['total']}")
    for level, count in sorted(report["levels"].items()):
        print(f"  {level}: {count}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

**返回退出码而不是 `sys.exit()` 到处写**，这样测试可以直接调用 `main([...])`。

### 测试：先测纯函数

```python
# tests/test_parser.py
from loganalyzer.parser import parse_line


def test_parse_valid_line() -> None:
    entry = parse_line("2026-01-01 10:00:00 ERROR 数据库连接失败")
    assert entry is not None
    assert entry.level == "ERROR"
    assert entry.message == "数据库连接失败"


def test_invalid_line_returns_none() -> None:
    assert parse_line("这不是日志") is None


def test_trailing_space_is_tolerated() -> None:
    assert parse_line("2026-01-01 10:00:00 INFO  启动完成  ") is not None
```

### 一键质量检查

```bash
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"

ruff check src tests
ruff format --check src tests
mypy src
pytest
```

把这四条写进 `Makefile` 或 CI，团队里每个人跑的命令就一致了。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 代码放在仓库根目录 | 导入混乱 | 用 `src/` 布局 |
| 逻辑与 IO 混在一起 | 无法单测 | 抽出纯函数 |
| 依赖写在 requirements 但没版本 | 环境不可复现 | 用 pyproject 或锁定版本 |
| 用 print 当日志 | 无法分级与开关 | 用 logging |
| 出错只抛异常不给退出码 | CI 判断不了 | 返回明确的退出码 |
| 路径用字符串拼接 | 跨平台出错 | 用 `pathlib` |
| 忘记 `encoding` | 中文乱码 | 一律 utf-8 |
| 只跑一次手工测试 | 改了就坏 | 加 pytest 用例 |

### 学完自测

- [ ] 能说出 `src/` 布局的好处。
- [ ] 知道为什么要把解析函数与文件读取分开。
- [ ] 能说出 `[project.scripts]` 的作用。
- [ ] 知道为什么 `main` 要返回退出码而不是直接退出。
- [ ] 能列出提交前要跑的至少三条检查命令。
