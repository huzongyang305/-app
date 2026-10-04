# Operational: reptiles and data analysis

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Advanced

## Learning objectives

- It is possible to explain, in its own words, what problems were solved by the battle: reptiles and data analysis, rather than simply using terminology.
- The relationship between "real warfare", "panders," and "requests" is clear, with one example.
- It's a way to put this subject back into the "Python" system of knowledge, and it shows how much it has to do with each other.
- It is possible to complete this course and check its results using acceptance standards.

> Synopsis of a sentence: capture, pandas cleansing statistics and visualization.

## Pre-knowledge

- One lesson, " Co-opting and Stepping", is completed; if available, this course can be used for self-measurement.
- This course stage: Advanced. It is recommended to have a complete basis in the same direction, reading longer code, configuration or system design instructions.
- Before we begin: combat, reptiles, pandas.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Project objectives

Fetching open data Cleans up tables Statistics and visualization. This is the most common Python landing scene, involving web requests, data processing and document reading and writing.

## Environmental readiness

```bash
python -m venv .venv
.venv\Scripts\activate
pip install requests beautifulsoup4 pandas matplotlib
pip freeze > requirements.txt
```

## Capture and Parsing

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

Element: ⟦0 shall be filled, 1 check the state code and selector will give priority to stable class or data properties.

## Purge and Statistics

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

Common cleaning actions: go to blanks, unified casework, type conversion, missing value processing (00/`dropna`), weighting (2⟧).

## Visualize

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

## Engineering proposal

1. Capture robots.txt and service terms, control frequency, plus zero.
2. Disassembly "capture" / analyse / output into a stand-alone function to facilitate testing and reuse.
3. Long missions with logs and break points (discovered data).
4. Use the Cupyter Notebook explorer, and then settle to zero.

## It's the end of this class.
The value of this project is to link ** request, analysis, DataFrame and visualization** into a complete chain. It runs through the Python data processing capability.

<!-- appendix:v1 -->

## Check it out.

|Purpose|Writing|
| --- | --- |
|GET Request| `requests.get(url, params={"q": "x"}, timeout=5)` |
| POST JSON | `requests.post(url, json=payload, timeout=5)` |
|Forms submitted| `requests.post(url, data={"k": "v"})` |
|Custom Header| `headers={"User-Agent": "..."}` |
|Check Status| `resp.raise_for_status()` |
|Parsing JSON| `resp.json()` |
|Read Text|Zero.|
|Try again| `HTTPAdapter` + `Retry` |
|Can not open message| `with requests.Session() as s:` |
|Timeout Settings|It's a group.|

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

## Pandas, quick check.

|Purpose|Writing|
| --- | --- |
|Read CSV / Excel| `pd.read_csv("a.csv")` / `pd.read_excel("a.xlsx")` |
|View Overview| `df.head()`、`df.info()`、`df.describe()` |
|Selection| `df[["name", "price"]]` |
|Conditional Filter| `df[df["price"] > 100]` |
|Multiple| `df[(df.a > 1) & (df.b == "x")]` |
|Group Aggregation| `df.groupby("category")["price"].mean()` |
|Perceived| `df.pivot_table(index="cat", columns="month", values="price", aggfunc="sum")` |
|Sort| `df.sort_values("price", ascending=False)` |
|It's heavy.| `df.drop_duplicates(subset=["id"])` |
|Missing value| `df.isna().sum()`、`df.fillna(0)`、`df.dropna()` |
|New| `df["total"] = df.price * df.qty` |
|Merge| `df.merge(other, on="id", how="left")` |
|Apply Functions| `df["c"] = df.a.apply(lambda v: v * 2)` |
|Time processing| `pd.to_datetime(df.created_at)` |
|Export| `df.to_csv("out.csv", index=False, encoding="utf-8-sig")` |

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
|No time-out.|Request may be suspended permanently|Set Zero.|
|Ignore ⟦0|4x5/xx as normal data processing|Visible Check Status Code|
|Frequent creation of new connections|It's easy to stop the flow.|Reuse ⟦0 and configure the retry|
|High frequency request rate|Blocked IP|Increase the delay and issue a cap, comply with robots|
| `df["a"] > 1 and df["b"] == 2` | `ValueError: truth value is ambiguous` |Use ⟦0 and brackets for each condition|
|Chain value, zero.|The change could be lost.|Use Zero.|
|Line by line, zero. Walk through DataFrame|It's a couple of times slower.|Quantified or zero, if required|
|Forget, Zero.|CSV, add an index.|Visible designation for export|
|Date field as string comparison|Error sorting and filtering results|Let's go.|
|Chinese CSV in Excel|Encoding does not match|Export ⟦0|

## Self-Detected List

- [ ] All network requests are timed out, retried and inspected.
- [ ] Identify the robots of the target site and use terms before capturing them.
- [ ] Data cleansing should be quantified as a matter of priority, avoiding line-by-line cycles.
- [ ] Grouping statistics with a ⟦-+ aggregation function.
- [ ] Export CSV-designated code with ⟦0.

<!-- appendix:v3 -->

## Zero basic details: a Python small project from zero

### What is it?

In addition to being able to run, a Python project will include:** clear directories, relying statements, configuration of external logs, testing and one-key running.**
Here's an analysis of the CLI.

### It's a life metaphor.

|Contents|A metaphor.|Annotations|
| --- | --- | --- |
| `src/` |Workshop|Real code.|
| `tests/` |Receiving and inspection area|Automation testing|
| `pyproject.toml` |Product description|Dependency, scripts, build configuration|
| `.env.example` |Sample forms|Tell people what they want.|
| `README.md` |Use of manuals|How? How?|

### Recommended Directory Structure

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

### Dependency and Entry Declaration

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

When you're done with the command line, do not forget.

### Separate pure logic from IO

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

### Command Line Entry

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

**Returns the exit code instead of writing it all over, so that you can call directly one.

### Test: Pure function first

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

### One-key quality check

```bash
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"

ruff check src tests
ruff format --check src tests
mypy src
pytest
```

Put these four in the Zero or C.I., and everyone on this team will be ordered to run.

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|The code is on the base of the warehouse.|Organisation|Use ⟦0 layout|
|Logic mixed with IO|Unable to measure|Draw Pure Functions|
|Requirements, but no version|It's not gonna happen again.|Use pyproject or lock version|
|Use print as log|Could not initialise Bonobo|Use logging|
|It's just an anomaly.|C.I. can't judge.|Return specified exit code|
|Path to string|Error across Platform|Use Zero.|
|Forget it.|Chinese Spell|utf-8|
|Just one manual test.|It's not working.|Plus Pytest|

### Learn how to measure yourself.

- [ Laughs ] Can you tell me the advantages of a layout?
- [ ] Knows why the parse function is separated from the file.
- [ Chuckles ] Can you tell me what the role is?
- [ Laughs ] Know why the ⟦0 is going back to exit code and not directly.
- [ ] Can list at least three inspection orders before submission.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeats, experiments and deliveries around "Performance, reptiles, pandas" each result to be checked.

Write runable scripts, then use type notes and test to protect core functions, and finally process real inputs.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with "Performance: reptile and data analysis"?
2. Without it, what concrete consequences would there be?
3. What does it have to do with reptiles?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Writes a small script within 20 lines to use this lesson concept for processing real text or list data.

Mission requests:

- The result must be checked, not just “I understand”.
- It's not like we have to go out of our way, but it doesn't make sense.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- project-verification:v1 -->

## Validation command and expected output

The project code does not read only " Compilable " , but repeats the results by a fixed command.

|Phase|Command|Expected output|
| --- | --- | --- |
|Installation Dependence| `python -m pip install -r requirements.txt` |Reliance on installation, no conflict of version|
|Syntax:| `python -m compileall .` |All modules compiled|
|Run Test| `python -m pytest -q` |All tests passed, and zero failed.|
|Example:| `python main.py` |Service start and output listening address|

### Evidence of acceptance

- [ ] Save the complete output relying on installation and start-up orders.
- [ ] Run at least 3 tests containing an illegal input or failure path.
- [ ] Repeat the same operation twice and confirm that there are no duplicates or side effects.
- [ ] Record a failure code, wrong log and recovery steps.
- [ ] Provide an environmental version, start-up and rollback in README.

### Return and Roll

1. Start with an abandoned directory or temporary database to avoid contamination of real data.
2. Rerun all authentication orders after a logical change to confirm that they are not returned.
3. If you fail, roll back to the previous runable version and keep the failed log.
4. The reason for the location is supplemented by an automated test and re-execution process.
5. The lessons are included in the project ' s repertoire or in a note, which will form the next inspection.

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Project: Scraping & Data

**Summary:** Scrape, clean, analyze and visualize data.

**Category:** Python  
**Level:** Advanced
**Key terms:** field, pandas, reptiles, visualize

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: advanced
- Applicable environment: Python 3.12+
- Source: Internal structured curriculum and engineering practices
- Related themes: combat, reptiles, pandas, requests, visualization
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

## Project specifications: field operations: reptiles and data analysis

### Core scene

Requests grab, pandas clean statistics and matplotlib visualize.The goal of the project is to make operational, testable and roll-back deliverables.

### Structures and data flows

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### Minimum Data Model

|Object|Key Fields|Constraints|
| --- | --- | --- |
|Enter entity|Actual, time and source|Keys to verify, limit the length, etc.|
|Task entity|Status, priority, creation|It's legal, it can't be repeated|
|Result entity|Output, Error Code, Time|Sequencable. Errors.|
|Audit records|Operator, action, result, time|It's unmovable, searchable and dissensitive.|

### Receiving scenes

1. Normal path: The minimum input receives the expected output, leaving a log and an indicator.
2. Boundary path: Empty, maximum, duplicated data and super-long content are explicitly addressed.
3. Failed path: fast failure, retest or downgrade if you rely on excess time.
4. Paths, etc.: The execution of the same request will not have repeated side effects.
5. Rollback path: Backroll data are consistent and indicate recovery time and impact.

<!-- project-delivery:v1 -->

## Project delivery

### Suggested warehouse structure

```text
app/
  api/
  domain/
  infra/
tests/
README.md
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
  "project": "python_project",
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

> Project acceptance revolves around "activated, reptile, pandas": at least one normal route, one border entry, one failed recovery and one check.

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Project: Scraping & Data** focuses on Scrape, clean, analyze and visualize data.

### Learning Outcomes

- Explain what **Project: Scraping & Data** solves and when it should be used.
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

- Topic: **Project: Scraping & Data**
- Relaid terms: combat, pandas, reptiles
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Project objectives|Project objectives|
|Environmental readiness|Environmental readiness|
|Capture and Parsing|Capture and Parsing|
|Purge and Statistics|Purge and Statistics|
|Visualize|Visualize|
|Engineering proposal|Engineering proposal|
|It's the end of this class.| Summary |
|Check it out.|Check it out.|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

