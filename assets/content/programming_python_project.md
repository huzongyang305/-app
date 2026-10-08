# 实战：爬虫与数据分析

![爬虫与数据分析流程](images/diagram_py_scraper.webp)

![实战：爬虫与数据分析](images/remaining_python_project.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：90 分钟

## 本节知识框架

**课程定位**：所属分类 `python`（Python），课程主题 `实战：爬虫与数据分析`，学习阶段 高级，建议用时 110 分钟。

本课主线：requests 抓取、pandas 清洗统计与 matplotlib 可视化。

**学完本课应当能够**
- 说清 `timeout` 与 `fillna` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `User-Agent` 的行为，记录输入、输出与失败条件。
- 遇到「代码放在仓库根目录」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `timeout`：先掌握 要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性，再用它解释 `fillna` 为什么会出现。
2. `fillna`：先掌握 常见清洗动作：去空白、统一大小写、类型转换、缺失值处理（`fillna` / `dropna`）、去重（`drop_duplicates`），再用它解释 `User-Agent` 为什么会出现。
3. `User-Agent`：先掌握 抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent`，再用它解释 `实战` 为什么会出现。
4. `实战`：先掌握 实战：爬虫与数据分析解决了什么问题，而不是只背术语，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「Python」分类的第 25 课。先修内容：《并发与异步》。《并发与异步》里的 `ProcessPoolExecutor`、`await` 是本课的前提。相关或后续课程：《实战：FastAPI 订单服务》。

### 完成判据

- **定义关**：不看正文也能说明 `timeout` 是 要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `实战：爬虫与数据分析`，而不是只背结论。
- **示例关**：能运行或推演 `实战：爬虫与数据分析` 的 `text` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `实战：爬虫与数据分析` 示例里的 出现字面量 `loganalyzer`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 代码放在仓库根目录，记录现象并按 用 `src/` 布局 修复。
- **迁移关**：能把 `实战`、`爬虫`、`pandas`、`requests` 放进一个与 `实战：爬虫与数据分析` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `实战：爬虫与数据分析` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| timeout | 要点：timeout 必填，raise_for_status() 检查状态码，选择器优先用稳定的 class 或 data 属性。 | 易错：请求可能永久挂起；正确做法是一律设置 `timeout=(连接, 读取)`。 |
| fillna | 常见清洗动作：去空白、统一大小写、类型转换、缺失值处理（fillna / dropna）、去重（drop_duplicates）。 | 静态检查只在编译期成立，运行期输入仍需校验。 |
| User-Agent | 抓取遵守 robots.txt 与服务条款，控制频率、加 User-Agent。 | 只在「抓取遵守 robots.txt 与服务条款，控制频率、加 User-Agent」这一前提下成立，换输入或换环境要重新验证。 |
| 实战 | 实战：爬虫与数据分析解决了什么问题，而不是只背术语。 | 只在「实战：爬虫与数据分析解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。 |

## 原理与运行机制

### 机制总览

**教材衔接：工程化建议**

1. 抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent`。
2. 把「抓取 / 清洗 / 分析 / 输出」拆成独立函数，便于测试与复用。
3. 长任务加日志与断点续跑（把已抓数据落盘）。
4. 用 Jupyter Notebook 探索，定型后沉淀为 `.py` 模块。

**教材衔接：pandas 速查**

| 目的 | 写法 |
| --- | --- |
| 读 CSV / Excel | `pd.read_csv("a.csv")` / `pd.read_excel("a.xlsx")` |
| 查看概览 | `df.head()`、`df.info()`、`df.describe()` |
| 选列 | `df[["name", "price"]]` |
| 条件过滤 | `df[df["price"] > 100]` |
| 多条件 | `df[(df.a > 1) & (df.b == "x")]` |
| 分组聚合 | `df.groupby("category")["price"].mean()` |
| 透视表 | `df.pivot_table(index="cat", columns="month", values="price", aggfunc="sum")` |
| 排序 | `df.sort_values("price", ascending=False)` |
| 去重 | `df.drop_duplicates(subset=["id"])` |
| 缺失值 | `df.isna().sum()`、`df.fillna(0)`、`df.dropna()` |
| 新增列 | `df["total"] = df.price * df.qty` |
| 合并 | `df.merge(other, on="id", how="left")` |
| 应用函数 | `df["c"] = df.a.apply(lambda v: v * 2)` |
| 时间处理 | `pd.to_datetime(df.created_at)` |
| 导出 | `df.to_csv("out.csv", index=False, encoding="utf-8-sig")` |

**教材衔接：版本与时效**

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 实战 相关的差异单独记成一条结论。
- 回归范围锁定 raise_for_status 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后记录 实战 的新旧版本差异，并据此调整下次复核时间。

**教材衔接：交付评审：评分表、决策记录与证据链**



### 三、「实战：爬虫与数据分析」的交付证据链

本课未给出可执行命令，用下面的最小证据集代替：


### 五、评审记录模板

| 记录项 | 填写要求 |
| --- | --- |
| 项目标识 | `python_project` |
| 本次范围 | 说明这一轮交付了「实战：爬虫与数据分析」的哪些部分 |
| 未完成项 | 列出与 实战 相关但本轮未做的内容 |
| 证据位置 | 指向 evidence/ 目录下的具体文件 |
| 风险与回滚 | 写清剩余风险、回滚步骤和验证方式 |
| 结论 | 通过 / 有条件通过 / 不通过，三者选一 |

### 机制拆解：每一步的输入、动作与输出

#### 1. `timeout`
- 输入：`实战`；本步把 要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性 当作判断规则。
- 动作：围绕 `timeout` 保留中间状态，并记录它与 `fillna` 的对应关系。
- 输出：`fillna`，它可以被下一段代码、测试或记录继续使用。
- `timeout` 的失败条件：当`requests.get` 不设超时时，会出现请求可能永久挂起。

#### 2. `fillna`
- 输入：`timeout`；本步把 常见清洗动作：去空白、统一大小写、类型转换、缺失值处理（`fillna` / `dropna`）、去重（`drop_duplicates`） 当作判断规则。
- 动作：围绕 `fillna` 保留中间状态，并记录它与 `User-Agent` 的对应关系。
- 输出：`User-Agent`，它可以被下一段代码、测试或记录继续使用。
- `fillna` 的失败条件：静态检查只在编译期成立，运行期输入仍需校验。

#### 3. `User-Agent`
- 输入：`fillna`；本步把 抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent` 当作判断规则。
- 动作：围绕 `User-Agent` 保留中间状态，并记录它与 `实战` 的对应关系。
- 输出：`实战`，它可以被下一段代码、测试或记录继续使用。
- `User-Agent` 的失败条件：只在「抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent`」这一前提下成立，换输入或换环境要重新验证。

#### 4. `实战`
- 输入：`User-Agent`；本步把 实战：爬虫与数据分析解决了什么问题，而不是只背术语 当作判断规则。
- 动作：围绕 `实战` 保留中间状态，并记录它与 `loganalyzer` 的对应关系。
- 输出：`loganalyzer`，它可以被下一段代码、测试或记录继续使用。
- `实战` 的失败条件：只在「实战：爬虫与数据分析解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。

### 示例中的可观察事实

1. 出现字面量 `loganalyzer`；它对应的课程主题是 `实战：爬虫与数据分析`。
2. 出现字面量 `0.1.0`；它对应的课程主题是 `实战：爬虫与数据分析`。
3. 出现字面量 `>=3.11`；它对应的课程主题是 `实战：爬虫与数据分析`。
4. 出现字面量 `httpx>=0.27`；它对应的课程主题是 `实战：爬虫与数据分析`。
5. 出现字面量 `pytest>=8`；它对应的课程主题是 `实战：爬虫与数据分析`。
6. 出现字面量 `pytest-cov>=6`；它对应的课程主题是 `实战：爬虫与数据分析`。
7. 出现字面量 `mypy>=1.11`；它对应的课程主题是 `实战：爬虫与数据分析`。
8. 出现字面量 `ruff>=0.6`；它对应的课程主题是 `实战：爬虫与数据分析`。

### 复现实验记录

- 环境：`实战：爬虫与数据分析` 使用 `text` 示例，固定 `实战`、`爬虫`、`pandas`、`requests` 作为第一组条件。
- 首轮输入：先确认 出现字面量 `loganalyzer`，预测 `timeout` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `实战`，观察 `实战` 是否仍满足定义。
- 失败注入：复现 代码放在仓库根目录，确认现象是 导入混乱。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `实战：爬虫与数据分析` 时才能区分概念错误与实现错误。

## 典型应用场景

**教材衔接：项目目标**

抓取公开数据 → 清洗成表格 → 统计与可视化。这是 Python 最常见的落地场景，涉及网络请求、数据处理与文件读写。

**教材衔接：零基础详解：从零做一个 Python 小项目**

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

**教材衔接：项目专属规格：实战：爬虫与数据分析**

### 核心场景

requests 抓取、pandas 清洗统计与 matplotlib 可视化。 项目目标是把「实战、爬虫、pandas、requests、可视化」落实为可运行、可测试、可回滚的交付物。



### 验收场景

1. 正常路径：最小输入得到预期输出，并留下日志与指标。
2. 边界路径：爬虫 在重复提交与超长输入下不产生额外副作用。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：实战 回滚后数据一致，且能说明恢复时间和影响范围。

**教材衔接：项目交付物**

### 建议仓库结构

```text
app/
  api/
  domain/
  infra/
tests/
README.md
```


### 验收数据

```json
{
  "project": "python_project",
  "scenario": "实战的正常路径",
  "input": {"case": "normal", "value": "raise_for_status"},
  "expected": {"ok": true, "checks": ["实战可复现", "爬虫有记录"]},
  "failure_case": {"case": "爬虫越界或缺失", "error": "validation_error"},
  "idempotency_key": "python_project-001"
}
```

### 复盘模板

- **代码放在仓库根目录**：典型现象是导入混乱；正确做法是用 `src/` 布局。
- **逻辑与 IO 混在一起**：典型现象是无法单测；正确做法是抽出纯函数。
- **依赖写在 requirements 但没版本**：典型现象是环境不可复现；正确做法是用 pyproject 或锁定版本。
- **用 print 当日志**：典型现象是无法分级与开关；正确做法是用 logging。

### 最小验证场景

- 准备：保留 `text` 示例的原始输入，先记录 `实战：爬虫与数据分析` 的基线输出和完整运行命令。
- 观察：先核对 出现字面量 `loganalyzer`，再改变一个与 `timeout` 相关的条件。
- 判定：新结果与 `实战：爬虫与数据分析` 的基线不同不等于错误；只有当差异破坏了 `timeout` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `timeout` 时，先满足它的定义：要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性；易错：请求可能永久挂起；正确做法是一律设置 `timeout=(连接, 读取)`。
- 使用 `fillna` 时，先满足它的定义：常见清洗动作：去空白、统一大小写、类型转换、缺失值处理（`fillna` / `dropna`）、去重（`drop_duplicates`）；静态检查只在编译期成立，运行期输入仍需校验。
- 使用 `User-Agent` 时，先满足它的定义：抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent`；只在「抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent`」这一前提下成立，换输入或换环境要重新验证。
- 使用 `实战` 时，先满足它的定义：实战：爬虫与数据分析解决了什么问题，而不是只背术语；只在「实战：爬虫与数据分析解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。

## 代码/协议/SQL 示例

### 最小可验证示例

```bash
python -m venv .venv
.venv\Scripts\activate
pip install requests beautifulsoup4 pandas matplotlib
pip freeze > requirements.txt
```

**教材衔接：环境准备**

**教材衔接：抓取与解析**

```python
import requests
from bs4 import BeautifulSoup

def fetch_quotes(page=1):
    url = f"https://quotes.toscrape.com/page/{page}/"
    response = requests.get(url, timeout=10)
    response.raise_for_status()               # 4xx/5xx 直接抛异常
    soup = BeautifulSoup(response.text, "html.parser")
    items = []
    for quote in soup.select(".quote"):
        items.append({
            "text": quote.select_one(".text").get_text(strip=True),
            "author": quote.select_one(".author").get_text(strip=True),
            "tags": [tag.get_text(strip=True) for tag in quote.select(".tag")],
        })
    return items
```

要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性。

**教材衔接：清洗与统计**

```python
import pandas as pd

rows = [item for page in range(1, 4) for item in fetch_quotes(page)]
df = pd.DataFrame(rows)
df["quote_length"] = df["text"].str.len()
df["author"] = df["author"].str.strip()

print(df.head())
print(df.groupby("author")["quote_length"].mean().sort_values(ascending=False).head())

tags = df.explode("tags")
print(tags["tags"].value_counts().head(10))

df.to_csv("quotes.csv", index=False, encoding="utf-8-sig")   # Excel 友好
```

常见清洗动作：去空白、统一大小写、类型转换、缺失值处理（`fillna` / `dropna`）、去重（`drop_duplicates`）。

**教材衔接：可视化**

```python
import matplotlib.pyplot as plt

plt.rcParams["font.sans-serif"] = ["SimHei"]
plt.rcParams["axes.unicode_minus"] = False

top = tags["tags"].value_counts().head(10)
top.plot(kind="barh")
plt.title("出现最多的标签")
plt.tight_layout()
plt.savefig("tags.png", dpi=120)
```

**教材衔接：requests 速查**

| 目的 | 写法 |
| --- | --- |
| GET 请求 | `requests.get(url, params={"q": "x"}, timeout=5)` |
| POST JSON | `requests.post(url, json=payload, timeout=5)` |
| 表单提交 | `requests.post(url, data={"k": "v"})` |
| 自定义头 | `headers={"User-Agent": "..."}` |
| 检查状态 | `resp.raise_for_status()` |
| 解析 JSON | `resp.json()` |
| 读取文本 | `resp.text`（配合 `resp.encoding`） |
| 重试 | `HTTPAdapter` + `Retry` |
| 会话复用 | `with requests.Session() as s:` |
| 超时设置 | 元组 `(连接超时, 读取超时)` |

```python
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

session = requests.Session()
session.mount("https://", HTTPAdapter(max_retries=Retry(
    total=3, backoff_factor=0.5,
    status_forcelist=[429, 500, 502, 503, 504],
)))

try:
    resp = session.get("https://example.com/api/items",
                       params={"page": 1}, timeout=(3, 10))
    resp.raise_for_status()
    items = resp.json()["data"]
except requests.RequestException as exc:
    print("请求失败：", exc)
```

**教材衔接：验证命令与预期输出**

先让 raise_for_status 的结果可复现，再谈扩展。下表给出最低验证集：

### 验收证据

- [ ] 保存依赖安装和启动命令的完整输出。
- [ ] 测试覆盖 爬虫 的核心规则，并包含一次可预期的失败。
- [ ] 用同一个幂等键重放 raise_for_status，确认结果与首次一致。
- [ ] 记录一次失败状态码、错误日志和恢复步骤。
- [ ] 记录 raise_for_status 的运行环境与复现命令，并补一段回滚说明。

### 回归与回滚

1. 先在副本上执行 爬虫，并记录前后差异。
2. 修改一处逻辑后重跑全部验证命令，确认没有回归。
3. 若失败，回滚到上一个可运行版本并保留失败日志。
4. 定位原因后补一条自动化测试，再重新执行发布流程。
5. 把教训写入项目复盘或本课笔记，形成下一次的检查项。

### 示例精读：先找证据，再改一个条件

1. 出现字面量 `loganalyzer`；它出现在 `实战：爬虫与数据分析` 的示例中，阅读时先确认它前后各发生了什么。
2. 出现字面量 `0.1.0`；它出现在 `实战：爬虫与数据分析` 的示例中，阅读时先确认它前后各发生了什么。
3. 出现字面量 `>=3.11`；它出现在 `实战：爬虫与数据分析` 的示例中，阅读时先确认它前后各发生了什么。
4. 出现字面量 `httpx>=0.27`；它出现在 `实战：爬虫与数据分析` 的示例中，阅读时先确认它前后各发生了什么。
5. 出现字面量 `pytest>=8`；它出现在 `实战：爬虫与数据分析` 的示例中，阅读时先确认它前后各发生了什么。
6. 出现字面量 `pytest-cov>=6`；它出现在 `实战：爬虫与数据分析` 的示例中，阅读时先确认它前后各发生了什么。
7. 出现字面量 `mypy>=1.11`；它出现在 `实战：爬虫与数据分析` 的示例中，阅读时先确认它前后各发生了什么。
8. 出现字面量 `ruff>=0.6`；它出现在 `实战：爬虫与数据分析` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `实战：爬虫与数据分析` 中与 `timeout` 对照：示例必须能支持 要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性，否则说明这一段还缺少实现或验证步骤。
- 在 `实战：爬虫与数据分析` 中与 `fillna` 对照：示例必须能支持 常见清洗动作：去空白、统一大小写、类型转换、缺失值处理（`fillna` / `dropna`）、去重（`drop_duplicates`），否则说明这一段还缺少实现或验证步骤。
- 在 `实战：爬虫与数据分析` 中与 `User-Agent` 对照：示例必须能支持 抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent`，否则说明这一段还缺少实现或验证步骤。
- 在 `实战：爬虫与数据分析` 中与 `实战` 对照：示例必须能支持 实战：爬虫与数据分析解决了什么问题，而不是只背术语，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**性能关注点（实战：爬虫与数据分析）**：解释执行与对象分配是主要成本：记录执行时间、内存峰值与 GC 次数，必要时对比其他实现。

**本课特有开销（实战：爬虫与数据分析 · 实战）**：并发度提高后要观察是否出现拐点：延迟上升而吞吐不增，说明瓶颈已转移。

**测量方法**：以 `实战：爬虫与数据分析` 的 `实战` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `实战：爬虫与数据分析` 的 `实战`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：爬虫与数据分析` 的 `爬虫`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：爬虫与数据分析` 的 `pandas`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：爬虫与数据分析` 的 `requests`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：爬虫与数据分析` 的 `可视化`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：爬虫与数据分析` 中 `timeout` 的边界：易错：请求可能永久挂起；正确做法是一律设置 `timeout=(连接, 读取)`。达到边界时不要外推，必须重新测量。
- `实战：爬虫与数据分析` 中 `fillna` 的边界：静态检查只在编译期成立，运行期输入仍需校验。达到边界时不要外推，必须重新测量。
- `实战：爬虫与数据分析` 中 `User-Agent` 的边界：只在「抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent`」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `实战：爬虫与数据分析` 中 `实战` 的边界：只在「实战：爬虫与数据分析解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `实战：爬虫与数据分析` 的代码证据：先验证 出现字面量 `loganalyzer`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 代码放在仓库根目录 | 导入混乱 | 用 `src/` 布局 |
| 逻辑与 IO 混在一起 | 无法单测 | 抽出纯函数 |
| 依赖写在 requirements 但没版本 | 环境不可复现 | 用 pyproject 或锁定版本 |
| 用 print 当日志 | 无法分级与开关 | 用 logging |
| 出错只抛异常不给退出码 | CI 判断不了 | 返回明确的退出码 |
| 路径用字符串拼接 | 跨平台出错 | 用 `pathlib` |
| 忘记 `encoding` | 中文乱码 | 一律 utf-8 |
| 只跑一次手工测试 | 改了就坏 | 加 pytest 用例 |
| `requests.get` 不设超时 | 请求可能永久挂起 | 一律设置 `timeout=(连接, 读取)` |
| 忽略 `raise_for_status()` | 4xx/5xx 当成正常数据处理 | 显式检查状态码 |
| 频繁创建新连接 | 慢且容易被限流 | 复用 `Session` 并配置重试 |
| 高频请求不控制速率 | 被封 IP | 加延时与并发上限，遵守 robots 与条款 |
| `df["a"] > 1 and df["b"] == 2` | `ValueError: truth value is ambiguous` | 用 `&` 并给每个条件加括号 |
| 链式赋值 `df[df.a > 1]["b"] = 0` | `SettingWithCopyWarning`，改动可能丢失 | 用 `.loc[df.a > 1, "b"] = 0` |
| 逐行 `for` 遍历 DataFrame | 慢几十倍 | 用向量化或 `apply`，必要时 `numpy` |
| 忘记 `index=False` 导出 | CSV 多出一列索引 | 导出时显式指定 |
| 日期字段当字符串比较 | 排序与筛选结果错误 | 先 `pd.to_datetime` |
| 中文 CSV 在 Excel 打开乱码 | 编码不匹配 | 导出用 `utf-8-sig` |
| requests.get 不设超时 | 请求可能永久挂起。 | 一律设置 timeout=(连接, 读取)。 |
| 忽略 raise_for_status() | 4xx/5xx 当成正常数据处理。 | 显式检查状态码。 |

### 现场 1：代码放在仓库根目录

**症状**：导入混乱。

**根因与修复**：用 `src/` 布局。

**自检**：在本课示例里复现「代码放在仓库根目录」，改成用 `src/` 布局后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：逻辑与 IO 混在一起

**症状**：无法单测。

**根因与修复**：抽出纯函数。

**自检**：在本课示例里复现「逻辑与 IO 混在一起」，改成抽出纯函数后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：依赖写在 requirements 但没版本

**症状**：环境不可复现。

**根因与修复**：用 pyproject 或锁定版本。

**自检**：在本课示例里复现「依赖写在 requirements 但没版本」，改成用 pyproject 或锁定版本后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：用 print 当日志

**症状**：无法分级与开关。

**根因与修复**：用 logging。

**自检**：在本课示例里复现「用 print 当日志」，改成用 logging后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：出错只抛异常不给退出码

**症状**：CI 判断不了。

**根因与修复**：返回明确的退出码。

**自检**：在本课示例里复现「出错只抛异常不给退出码」，改成返回明确的退出码后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：路径用字符串拼接

**症状**：跨平台出错。

**根因与修复**：用 `pathlib`。

**自检**：在本课示例里复现「路径用字符串拼接」，改成用 `pathlib`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：忘记 `encoding`

**症状**：中文乱码。

**根因与修复**：一律 utf-8。

**自检**：在本课示例里复现「忘记 `encoding`」，改成一律 utf-8后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：只跑一次手工测试

**症状**：改了就坏。

**根因与修复**：加 pytest 用例。

**自检**：在本课示例里复现「只跑一次手工测试」，改成加 pytest 用例后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：`requests.get` 不设超时

**症状**：请求可能永久挂起。

**根因与修复**：一律设置 `timeout=(连接, 读取)`。

**自检**：在本课示例里复现「`requests.get` 不设超时」，改成一律设置 `timeout=(连接, 读取)`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

- **先修**：`并发与异步`。本课默认这些内容已经掌握。
- **相关或后续**：`实战：FastAPI 订单服务`。本课术语会在这些课程里继续使用。
- **术语归属**：`timeout`、`fillna`、`User-Agent` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。
- 同一分类的《Python 数据处理：NumPy、pandas 与 Polars》也涉及 `pandas`；两课衔接时先确认这个术语的定义是否一致。

### 先修与后续术语接口

- `并发与异步`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。
- `实战：FastAPI 订单服务`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。

### 容易混淆的相邻概念

- `timeout` 与 `fillna`：前者强调 要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性；后者强调 常见清洗动作：去空白、统一大小写、类型转换、缺失值处理（`fillna` / `dropna`）、去重（`drop_duplicates`）。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `fillna` 与 `User-Agent`：前者强调 常见清洗动作：去空白、统一大小写、类型转换、缺失值处理（`fillna` / `dropna`）、去重（`drop_duplicates`）；后者强调 抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent`。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `User-Agent` 与 `实战`：前者强调 抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent`；后者强调 实战：爬虫与数据分析解决了什么问题，而不是只背术语。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `timeout` 的操作性定义，并说明它与 `fillna` 的区别。

**参考答案**：要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性。

`fillna` 的定位是：常见清洗动作：去空白、统一大小写、类型转换、缺失值处理（`fillna` / `dropna`）、去重（`drop_duplicates`）；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「代码放在仓库根目录」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是导入混乱；正确做法是用 `src/` 布局。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `text` 示例，改动其中一个输入后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `text` 示例应当复现正文给出的结果；改动输入后，如果结果改变或报错，先核对它是否满足 `实战：爬虫与数据分析` 中`timeout` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `text` 示例，说明它体现了`timeout` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`timeout` 的定义是 要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性，示例正是在实现这条定义。改动与 `timeout` 有关的一个输入后，如果结果不再符合 `实战：爬虫与数据分析` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `实战：爬虫与数据分析` 的方法迁移到自己的项目：围绕 `timeout` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「忽略 raise_for_status()」，它会导致4xx/5xx 当成正常数据处理；检验方式是按显式检查状态码改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `timeout` 与 `fillna`：各写一行适用场景、一行失败表现。

**参考答案**：`timeout` 的定义是要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性；`fillna` 的定义是常见清洗动作：去空白、统一大小写、类型转换、缺失值处理（`fillna` / `dropna`）、去重（`drop_duplicates`）。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「代码放在仓库根目录」引发的问题，请把“复现 导入混乱 → 保留证据 → 用 `src/` 布局 → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按导入混乱复现；第二步记录输入、版本与完整报错；第三步按用 `src/` 布局只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `实战`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：只在「实战：爬虫与数据分析解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。 同时要把 `实战` 的定义 实战：爬虫与数据分析解决了什么问题，而不是只背术语 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `timeout` → `fillna` → `User-Agent` → `实战` 的作用链。

**参考答案**：起点是 `timeout` 的定义 要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性；中间每一步都保留可观察状态；终点由 `实战` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `实战：爬虫与数据分析` 中，现象是 4xx/5xx 当成正常数据处理。请围绕 忽略 raise_for_status() 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 忽略 raise_for_status()，记录输入与完整错误；再按 显式检查状态码 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `实战：爬虫与数据分析`：先给主问题，再按顺序说出 `timeout`、`fillna`、`User-Agent`、`实战`，最后给一个失败案例。

**自评标准**：主问题必须对应 requests 抓取、pandas 清洗统计与 matplotlib 可视化；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `timeout` | 要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性。 |
| `fillna` | 常见清洗动作：去空白、统一大小写、类型转换、缺失值处理（`fillna` / `dropna`）、去重（`drop_duplicates`）。 |
| `User-Agent` | 抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent`。 |
| `实战` | 实战：爬虫与数据分析解决了什么问题，而不是只背术语。 |

**术语关系**：`timeout`（要点：`timeout` 必填） → `fillna`（常见清洗动作：去空白、统一大小写、类型转换、缺失值处理（`fillna` / `dropna`）、去重（`drop_duplicates`）） → `User-Agent`（抓取遵守 robots.txt 与服务条款） → `实战`（实战：爬虫与数据分析解决了什么问题）。

## 考点精讲

`实战：爬虫与数据分析` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：这段 `python` 代码对应 `实战：爬虫与数据分析` 的 `timeout`。课程要解决的是requests 抓取、pandas 清洗统计与 matplotlib 可视化。关于代码内容，哪一项说法准确？
- **正确项**：出现字面量 `loganalyzer.cli:main`
- **判断依据**：这道题落在术语 `timeout` 上：要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性。复习时把 `timeout` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 2：第 2 题

- **题目**：pandas 中按作者分组求均值应使用？
- **正确项**：df.groupby('author')['x'].mean
- **判断依据**：这道题检验本课主问题：requests 抓取、pandas 清洗统计与 matplotlib 可视化。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 3：第 3 题

- **题目**：围绕“实战：爬虫与数据分析”中的 实战、爬虫、pandas，下列哪两项是本课强调的实践判断？
- **正确项**：学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 爬虫 时要固定版本并覆盖边界输入，结论才可复现
- **判断依据**：这道题落在术语 `实战` 上：实战：爬虫与数据分析解决了什么问题，而不是只背术语。复习时把 `实战` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 4：第 4 题

- **题目**：给 requests 请求设置 timeout 的意义是？
- **正确项**：避免网络异常时请求无限期挂起
- **判断依据**：这道题落在术语 `timeout` 上：要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性。复习时把 `timeout` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 5：第 5 题

- **题目**：pandas 中把 DataFrame 保存成 CSV 的方法是？
- **正确项**：df.to_csv('out.csv')
- **判断依据**：这道题检验本课主问题：requests 抓取、pandas 清洗统计与 matplotlib 可视化。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `requests 抓取、pandas 清洗统计与 matplotlib 可视化。`，这段说明是：要点：``____`` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性。空缺处应填哪个术语？
- **正确项**：timeout
- **判断依据**：这道题落在术语 `timeout` 上：要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性。复习时把 `timeout` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`timeout`

- **要点**：要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性。
- **timeout 的边界**：易错：请求可能永久挂起；正确做法是一律设置 `timeout=(连接, 读取)`。

### 考点 8：`fillna`

- **要点**：常见清洗动作：去空白、统一大小写、类型转换、缺失值处理（`fillna` / `dropna`）、去重（`drop_duplicates`）。
- **fillna 的边界**：静态检查只在编译期成立，运行期输入仍需校验。

### 考点 9：`User-Agent`

- **要点**：抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent`。
- **User-Agent 的边界**：只在「抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent`」这一前提下成立，换输入或换环境要重新验证。

### 考点 10：`实战`

- **要点**：实战：爬虫与数据分析解决了什么问题，而不是只背术语。
- **实战 的边界**：只在「实战：爬虫与数据分析解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。

### 考点 11：排错——代码放在仓库根目录

- **现象**：导入混乱。
- **处理**：用 `src/` 布局。

### 考点 12：排错——逻辑与 IO 混在一起

- **现象**：无法单测。
- **处理**：抽出纯函数。

### 考点 13：综合辨析——`timeout` 与 `实战`

- **辨析点**：`timeout` 的定义是 要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性；`实战` 的定义是 实战：爬虫与数据分析解决了什么问题，而不是只背术语。
- **答题要求**：面对 `实战：爬虫与数据分析` 的题目，先判断描述的是 `timeout` 还是 `实战`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 14：排错评分点

- **现象分**：能写出 导入混乱，而不是只写“程序有错”。
- **证据分**：保留触发 代码放在仓库根目录 的输入、版本和错误原文。
- **修复分**：按 用 `src/` 布局 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：Python 3.12+
；本课聚焦 实战。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：实战、爬虫、pandas、requests、可视化
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2026-12-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：实战、爬虫、pandas、requests、可视化。

| 参考资料 | 本课用途 |
| --- | --- |
| [Python 标准库](https://docs.python.org/3/library/) | 标准库 API 与模块 |
| [sqlite3 文档](https://docs.python.org/3/library/sqlite3.html) | SQLite 持久化与事务 |
| [typing 文档](https://docs.python.org/3/library/typing.html) | 类型标注与泛型 |

| [本课术语索引：实战：爬虫与数据分析](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「实战：爬虫与数据分析」的链接用于离线阅读后的延伸核对；App 不会自动联网。

<!-- p1-project-review:start -->