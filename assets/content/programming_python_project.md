# 实战：爬虫与数据分析

![爬虫与数据分析流程](images/diagram_py_scraper.webp)

![实战：爬虫与数据分析](images/remaining_python_project.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：100 分钟

## 学习目标

- 能用自己的话解释实战：爬虫与数据分析解决了什么问题，而不是只背术语。
- 能说清 「实战」、「爬虫」、「pandas」、「requests」 之间的关系，并分别举出一个例子。
- 能把 实战 放回「实战：爬虫与数据分析」的知识体系，说明它和 爬虫 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：requests 抓取、pandas 清洗统计与 matplotlib 可视化。

## 前置知识

- 先完成上一课《并发与异步》；如果已经掌握，可以直接用本课练习自测。
- 开始前先复习：实战、爬虫、pandas。
- 看不懂就直接缩小例子：只保留 实战 相关的两行输入，跑通后再加回其余部分。

## 项目目标

抓取公开数据 → 清洗成表格 → 统计与可视化。这是 Python 最常见的落地场景，涉及网络请求、数据处理与文件读写。

## 环境准备

```bash
python -m venv .venv
.venv\Scripts\activate
pip install requests beautifulsoup4 pandas matplotlib
pip freeze > requirements.txt
```

## 抓取与解析

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

## 清洗与统计

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

## 可视化

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

## 工程化建议

1. 抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent`。
2. 把「抓取 / 清洗 / 分析 / 输出」拆成独立函数，便于测试与复用。
3. 长任务加日志与断点续跑（把已抓数据落盘）。
4. 用 Jupyter Notebook 探索，定型后沉淀为 `.py` 模块。

## 本课小结

这个项目的价值在于把**请求、解析、DataFrame、可视化**串成完整链路。把它跑通，Python 的数据处理能力就入门了。

## requests 速查

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

## pandas 速查

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

## 常见错误与排查

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
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

## 复习与自测

- [ ] 所有网络请求都设超时、重试与状态检查。
- [ ] 抓取前确认目标站点的 robots 与使用条款。
- [ ] 数据清洗优先向量化，避免逐行循环。
- [ ] 分组统计用 `groupby` + 聚合函数。
- [ ] 导出 CSV 指定编码与 `index=False`。

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

## 动手练习

> 本课练习重点：围绕「实战、爬虫、pandas」完成复述、实验和交付，每个结果都要能被别人检查。

先写可运行的脚本演示 实战，再用类型注解与测试保护核心函数。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 实战：爬虫与数据分析解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「爬虫」是什么关系？

验收标准：说明 实战 与 爬虫 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：先在「项目目标」里找一个可运行的最小输入，再按五步法记录实战的影响；预测与结果不一致时补写被忽略的前提。

### 练习 3：交付一个小结果（30 分钟）

用 raise_for_status 解析一份自己的数据，输出统计结果并核对一条记录。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「实战」和「爬虫」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 验证命令与预期输出

先让 raise_for_status 的结果可复现，再谈扩展。下表给出最低验证集：

| 阶段 | 命令 | 预期输出 |
| --- | --- | --- |
| 安装依赖 | `python -m pip install -r requirements.txt` | 依赖安装完成，没有版本冲突 |
| 语法检查 | `python -m compileall .` | 所有模块编译通过 |
| 运行测试 | `python -m pytest -q` | 测试全部通过，失败用例数为 0 |
| 启动示例 | `python main.py` | 服务启动并输出监听地址 |

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

## 可运行练习

### 任务 1：先跑通，再解释

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

### 任务 2：只改一个条件

把「实战：爬虫与数据分析」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只调整 raise_for_status 的一个参数，其余条件一律不动。
- 预测：先写下「实战：爬虫与数据分析」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响实战。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的 实战 数据，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：requests.get 不设超时

**症状**：在《实战：爬虫与数据分析》的复现场景中，请求可能永久挂起。

**根因**：触发点是把“requests.get 不设超时”当成安全做法。它没有满足《实战：爬虫与数据分析》要求的前提，因此先表现为“请求可能永久挂起”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《实战：爬虫与数据分析》的问题，一律设置 timeout=(连接, 读取)。

**验证**：保留《实战：爬虫与数据分析》里触发“请求可能永久挂起”的输入、版本和日志，按“一律设置 timeout=(连接, 读取)”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 2：忽略 raise_for_status()

**症状**：在《实战：爬虫与数据分析》的复现场景中，4xx/5xx 当成正常数据处理。

**根因**：当出现“忽略 raise_for_status()”时，执行路径已经绕过了《实战：爬虫与数据分析》的关键约束，最终以“4xx/5xx 当成正常数据处理”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《实战：爬虫与数据分析》的问题，显式检查状态码。

**验证**：先在《实战：爬虫与数据分析》中记录“忽略 raise_for_status()”留下的失败证据，再执行“显式检查状态码”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 3：频繁创建新连接

**症状**：在《实战：爬虫与数据分析》的复现场景中，慢且容易被限流。

**根因**：当出现“频繁创建新连接”时，执行路径已经绕过了《实战：爬虫与数据分析》的关键约束，最终以“慢且容易被限流”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《实战：爬虫与数据分析》的问题，复用 Session 并配置重试。

**验证**：先在《实战：爬虫与数据分析》中记录“频繁创建新连接”留下的失败证据，再执行“复用 Session 并配置重试”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

## 版本与时效

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 实战 相关的差异单独记成一条结论。
- 回归范围锁定 raise_for_status 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后记录 实战 的新旧版本差异，并据此调整下次复核时间。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「用 requests 发起请求时，下面哪项是必须的？」的判断依据。
- [ ] 不看解析，能说出「pandas 中按作者分组求均值应使用？」的判断依据。
- [ ] 不看解析，能说出「编写爬虫时最应该遵守的是？」的判断依据。
- [ ] 不看解析，能说出「给 requests 请求设置 timeout 的意义是？」的判断依据。
- [ ] 不看解析，能说出「pandas 中把 DataFrame 保存成 CSV 的方法是？」的判断依据。
- [ ] 至少运行一次 raise_for_status 的示例，记录输入、输出和 实战 的边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `timeout` | 要点：`timeout` 必填，`raise_for_status()` 检查状态码，选择器优先用稳定的 class 或 data 属性。 |
| `fillna` | 常见清洗动作：去空白、统一大小写、类型转换、缺失值处理（`fillna` / `dropna`）、去重（`drop_duplicates`）。 |
| `User-Agent` | 抓取遵守 robots.txt 与服务条款，控制频率、加 `User-Agent`。 |
| `实战` | 实战：爬虫与数据分析解决了什么问题，而不是只背术语。 |

## 考点精讲

### 考点 1：代码补全·实战

- **题目**：下面这段 Python 代码摘自「实战：爬虫与数据分析」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？
- **判断依据**：题干的正确项是这段代码包含循环结构，同一段逻辑会被重复执行，在「实战：爬虫与数据分析」里循环次数与实战的输入规模直接相关。这段代码出自「实战：爬虫与数据分析」的正文示例，围绕实战、爬虫、pandas展开；把输入或边界换成空值、极值或失败情况后，结论要以「实战：爬虫与数据分析」的实际运行结果为准。把“这段代码包含循环结构”代回「实战：爬虫与数据分析」里“下面这段 Python 代码摘自实战”的例子核对，条件一旦改变，结论就要用实战、爬虫、pandas重新推导。

### 考点 2：概念判断·实战

- **题目**：pandas 中按作者分组求均值应使用？
- **判断依据**：在「实战：爬虫与数据分析」里，df.groupby('author')['x'].mean。groupby 用于分组聚合，是数据分析最常用的操作。这道题的关键在「实战：爬虫与数据分析」的实战、爬虫、pandas：先确认题干“pandas 中按作者分组求均值应使”问的是哪一步，再排除偷换前提的选项。

### 考点 3：多选辨析·实战

- **题目**：围绕“实战：爬虫与数据分析”中的 实战、爬虫、pandas，下列哪两项是本课强调的实践判断？
- **判断依据**：在「实战：爬虫与数据分析」里，学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程。在实战：爬虫与数据分析里，判断 爬虫 时要固定版本与边界输入，所以“验证 爬虫 时要固定版本并覆盖边界输入，结论才可复现”才可复现。“围绕实战”与「实战：爬虫与数据分析」的术语表相呼应，只有符合实战、爬虫、pandas约束的“学习 实战 时要同时说明输入”才是正文支持的结论。

### 考点 4：概念判断·实战

- **题目**：给 requests 请求设置 timeout 的意义是？
- **判断依据**：在「实战：爬虫与数据分析」里，结论应落在「避免网络异常时请求无限期挂起」。生产脚本必须设置超时与重试，否则一个慢请求就可能卡住整个任务。在「实战：爬虫与数据分析」里，这道题要求区分概念与边界，「避免网络异常时请求无限期挂起」只有在题干给出的前提下才成立，而「自动重试失败请求」、「绕过反爬限制」缺少同一组条件。

### 考点 5：概念判断·实战

- **题目**：pandas 中把 DataFrame 保存成 CSV 的方法是？
- **判断依据**：在「实战：爬虫与数据分析」里，df.to_csv('out.csv', index=False)。tocsv 是写出方法，index=False 可避免多出一列行号。“pandas”与「实战：爬虫与数据分析」的术语表相呼应，只有符合实战、爬虫、pandas约束的“df.tocsv('out.csv'”才是正文支持的结论。

### 考点 6：填空·实战

- **题目**：补全代码：「实战：爬虫与数据分析」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `response.____ # 4xx/5xx 直接抛异常`
- **判断依据**：空格应填写「raise_for_status」。在「实战：爬虫与数据分析」里判断这道题，要把实战、爬虫、pandas的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。“爬虫与数据分析示例中”与「实战：爬虫与数据分析」的术语表相呼应，只有符合实战、爬虫、pandas约束的“raiseforstatus”才是正文支持的结论。

## English Overview

**Title:** Project: Scraping & Data

**Summary:** Scrape, clean, analyze and visualize data.

**Category:** Python
**Level:** 高级
**Key terms:** 实战, 爬虫, pandas, requests, 可视化

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：Python 3.12+
；本课聚焦 实战。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：实战、爬虫、pandas、requests、可视化
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 项目专属规格：实战：爬虫与数据分析

### 核心场景

requests 抓取、pandas 清洗统计与 matplotlib 可视化。 项目目标是把「实战、爬虫、pandas、requests、可视化」落实为可运行、可测试、可回滚的交付物。

### 架构与数据流

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### 最小数据模型

| 对象 | 关键字段 | 约束 |
| --- | --- | --- |
| 输入实体 | 实战、时间、来源 | 必填校验、长度限制、幂等键 |
| 任务实体 | 状态、优先级、创建时间 | 状态迁移合法、不可重复执行 |
| 结果实体 | 输出、错误码、耗时 | 可序列化、错误可解释 |
| 审计记录 | 操作者、动作、结果、时间 | 不可篡改、可查询、脱敏 |

### 验收场景

1. 正常路径：最小输入得到预期输出，并留下日志与指标。
2. 边界路径：爬虫 在重复提交与超长输入下不产生额外副作用。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：实战 回滚后数据一致，且能说明恢复时间和影响范围。

## 项目交付物

### 建议仓库结构

```text
app/
  api/
  domain/
  infra/
tests/
README.md
```

### 测试矩阵

| 层级 | 覆盖内容 | 最低数量 | 通过标准 |
| --- | --- | ---: | --- |
| 单元测试 | 领域规则、边界和错误分类 | 8 | 正常、边界、失败路径全部通过 |
| 集成测试 | 数据库、网络、文件或平台边界 | 3 | 使用真实边界且可重复运行 |
| 端到端测试 | 核心用户路径 | 1 | 从输入到输出完整跑通 |
| 手动验收 | 文档中列出的 5 个场景 | 5 | 有命令、输出和结论记录 |

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

| 问题 | 记录 |
| --- | --- |
| 原目标是什么？ | 用一句话描述可验收目标 |
| 实际发生了什么？ | 时间线、指标和关键日志 |
| 哪个假设被推翻？ | 根因与促成因素 |
| 如何回滚？ | 步骤、耗时和数据校验 |
| 下一步做什么？ | 负责人、期限和验证方式 |

> 项目验收围绕「实战、爬虫、pandas」：至少完成一次正常路径、一次边界输入、一次失败恢复和一次幂等检查。

## Full English Study Guide

### Overview

**Project: Scraping & Data** focuses on Scrape, clean, analyze and visualize data.

### Learning Outcomes

- Explain what **Project: Scraping & Data** solves and when it should be used.

### Glossary

- Topic: **Project: Scraping & Data**
- Related terms: 实战, 爬虫, pandas, requests

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 项目目标 | 项目目标 |
| 环境准备 | 环境准备 |
| 抓取与解析 | 抓取与解析 |
| 清洗与统计 | 清洗与统计 |
| 可视化 | 可视化 |
| 工程化建议 | 工程化建议 |
| 本课小结 | Summary |
| requests 速查 | requests 速查 |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Python 标准库](https://docs.python.org/3/library/) | 标准库 API 与模块 |
| [sqlite3 文档](https://docs.python.org/3/library/sqlite3.html) | SQLite 持久化与事务 |
| [typing 文档](https://docs.python.org/3/library/typing.html) | 类型标注与泛型 |

> 「实战：爬虫与数据分析」的链接用于离线阅读后的延伸核对；App 不会自动联网。

<!-- p1-project-review:start -->
## 交付评审：评分表、决策记录与证据链

「实战：爬虫与数据分析」的验收不能只看功能能不能跑通。下面把正文里的交付物、验证命令和关键设计点整理成一张评审表，按表逐项留下证据即可。

### 一、「实战：爬虫与数据分析」的交付物评分表

| 交付物 | 权重 | 合格线 | 需要的证据 |
| --- | ---: | --- | --- |
| 核心链路 | 34% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |
| 测试与验收记录 | 33% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |
| 运行与回滚说明 | 33% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |

「实战：爬虫与数据分析」的评分先看证据再打分：任意一项只要拿不出可复现的命令或测试，该项按 0 分计，不允许用「基本完成」代替。

### 二、需要写下来的决策（ADR）

| 决策点 | 本课给出的做法 | 备选方案 | 代价与回滚 |
| --- | --- | --- | --- |
| 架构与数据流 | 用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控 | 不做「架构与数据流」，沿用最朴素的实现（需要额外补一次对照实验） | 若「架构与数据流」出问题，回到上一版本并按本课验收场景重跑 |

ADR 不需要长：每个决策三行就够——选了什么、放弃了什么、出问题怎么退。评审时只检查这三行是否和「实战：爬虫与数据分析」的实际代码一致。

### 三、「实战：爬虫与数据分析」的交付证据链

本课未给出可执行命令，用下面的最小证据集代替：

1. 一条从零开始的环境准备命令。
2. 一条跑通核心链路的命令及其完整输出。
3. 一条触发失败的命令，以及恢复后的验证结果。

把「实战：爬虫与数据分析」的上表整理成一个 evidence/ 目录：每条命令一个文件，文件名带日期，内容包含版本、命令与输出。评审时直接按目录核对，不再口头确认。

### 四、「实战：爬虫与数据分析」的验收指标

| 指标 | 目标值 | 测量方式 | 不达标时的动作 |
| --- | --- | --- | --- |
| 实战 的核心路径耗时与失败率 | 用本课正文给出的阈值，没有就写实测基线 | 固定环境重复三次取中位数 | 回到对应小节定位，先修原因再重测 |
| 资源占用峰值与回收情况 | 用本课正文给出的阈值，没有就写实测基线 | 固定环境重复三次取中位数 | 回到对应小节定位，先修原因再重测 |
| 验收场景的通过率 | 用本课正文给出的阈值，没有就写实测基线 | 固定环境重复三次取中位数 | 回到对应小节定位，先修原因再重测 |

指标必须能用一条命令或一次操作测出来；写不出测量方式的指标，在「实战：爬虫与数据分析」的评审里一律视为未定义。

### 五、评审记录模板

| 记录项 | 填写要求 |
| --- | --- |
| 项目标识 | `python_project` |
| 本次范围 | 说明这一轮交付了「实战：爬虫与数据分析」的哪些部分 |
| 未完成项 | 列出与 实战 相关但本轮未做的内容 |
| 证据位置 | 指向 evidence/ 目录下的具体文件 |
| 风险与回滚 | 写清剩余风险、回滚步骤和验证方式 |
| 结论 | 通过 / 有条件通过 / 不通过，三者选一 |

「实战：爬虫与数据分析」评审结束后把这张表填完并归档；下一轮迭代直接读上一次的「未完成项」与「风险与回滚」，避免重复讨论同一个问题。
<!-- p1-project-review:end -->
