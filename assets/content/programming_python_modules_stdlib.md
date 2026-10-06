# 模块、包与虚拟环境

![模块、包、虚拟环境与依赖](images/diagram_py_modules.webp)

![模块、包与虚拟环境](images/remaining_python_modules_stdlib.webp)

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：40 分钟

## 学习目标

- 能用自己的话解释模块、包与虚拟环境解决了什么问题，而不是只背术语。
- 能说清 「import」、「模块」、「包」、「venv」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Python」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：导入机制、包组织、虚拟环境与常用标准库速查。

## 前置知识

- 先完成上一课《异常处理与文件操作》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：import、模块、包。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。

## 导入模块

```python
import math                     # 导入整个模块
from math import sqrt, pi       # 只导入需要的名字
from pathlib import Path as P   # 起别名

print(math.floor(3.7), sqrt(16), pi)
```

`if __name__ == "__main__":` 里的代码只在直接运行该文件时执行，被导入时不执行：

```python
def main():
    print("程序入口")

if __name__ == "__main__":
    main()
```

## 组织成包

```text
project/
├── main.py
└── utils/
    ├── __init__.py
    ├── text.py
    └── math_utils.py
```

```python
# main.py
from utils.text import slugify

print(slugify("Hello World"))
```

包内推荐使用绝对导入；相对导入（`from .text import slugify`）只在包内部使用。

## 虚拟环境与依赖

每个项目使用独立环境，避免依赖互相污染。

```bash
python -m venv .venv                  # 创建虚拟环境

# Windows
.venv\Scripts\activate
# macOS / Linux
source .venv/bin/activate

pip install requests                  # 安装依赖
pip freeze > requirements.txt         # 导出依赖清单
pip install -r requirements.txt       # 还原环境
deactivate                            # 退出环境
```

## 常用标准库

| 模块 | 用途 |
| --- | --- |
| `os` / `pathlib` | 文件与路径操作 |
| `json` / `csv` | 数据读写 |
| `datetime` | 日期时间 |
| `re` | 正则表达式 |
| `random` | 随机数 |
| `collections` | Counter、defaultdict、deque |
| `itertools` | 排列组合、分组 |
| `subprocess` | 调用外部命令 |
| `threading` / `asyncio` | 并发与异步 |

```python
from collections import defaultdict, deque
from datetime import datetime, timedelta

groups = defaultdict(list)
groups["a"].append(1)

queue = deque([1, 2, 3])
queue.appendleft(0)

print(datetime.now() + timedelta(days=7))
```

## 依赖管理与项目布局实践

| 工具 | 定位 | 特点 |
| --- | --- | --- |
| venv + pip | 标准库方案 | 无额外依赖，requirements.txt 记录版本 |
| pip-tools | 编译式依赖管理 | 从 requirements.in 生成锁定版本 |
| Poetry | 一体化工具 | 依赖解析 + 打包 + 发布 |
| uv | 极快的现代工具 | Rust 实现，兼容 pip 生态 |

**推荐项目布局**：`src/包名/`（源码）、`tests/`（测试）、`pyproject.toml`（配置与依赖）、`README.md`。把源码放 src 可避免"本地能导入、安装后不能"的问题（因为导入路径与安装路径不同）。

**常见坑**：① 忘记激活虚拟环境导致装到全局；② requirements.txt 不锁版本导致半年后无法复现；③ 用 `import *` 污染命名空间；④ 包内用相对导入却直接运行模块（应通过 `python -m 包.模块`）；⑤ 把敏感配置写进代码（应用环境变量或 .env 并在 .gitignore 排除）。

## 本课小结
能拆成模块就拆，能复用标准库就不自己写。虚拟环境 + `requirements.txt` 是 Python 工程化的起点。

## 常用标准库速查

| 模块 | 用途 | 高频 API |
| --- | --- | --- |
| `pathlib` | 路径与文件 | `Path("a") / "b"`、`read_text`、`write_text`、`exists` |
| `os` | 环境与目录 | `os.environ`、`os.getenv`、`os.makedirs` |
| `sys` | 解释器信息 | `sys.argv`、`sys.exit`、`sys.path` |
| `json` | JSON 读写 | `json.loads`、`json.dumps(ensure_ascii=False)` |
| `datetime` | 日期时间 | `datetime.now()`、`timedelta`、`strftime` |
| `collections` | 专用容器 | `Counter`、`defaultdict`、`deque`、`namedtuple` |
| `itertools` | 迭代工具 | `chain`、`groupby`、`combinations`、`islice` |
| `functools` | 函数工具 | `lru_cache`、`partial`、`reduce` |
| `re` | 正则表达式 | `re.findall`、`re.sub`、`re.compile` |
| `random` | 随机 | `random.choice`、`shuffle`、`randint` |
| `statistics` | 统计 | `mean`、`median`、`stdev` |
| `csv` | CSV 读写 | `csv.reader`、`DictReader`、`DictWriter` |
| `logging` | 日志 | `logging.basicConfig`、`logger.exception` |
| `subprocess` | 调用外部命令 | `subprocess.run([...], check=True)` |
| `timeit` | 计时 | `timeit.timeit`、`-m timeit` 命令行 |

```python
from collections import Counter, defaultdict
from pathlib import Path
import json
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

words = ["a", "b", "a", "c", "a"]
print(Counter(words).most_common(2))          # [('a', 3), ('b', 1)]

groups = defaultdict(list)
for word in words:
    groups[len(word)].append(word)            # 不需要先判断 key 是否存在

Path("out").mkdir(exist_ok=True)
Path("out/data.json").write_text(
    json.dumps({"count": len(words)}, ensure_ascii=False), encoding="utf-8"
)
logging.info("写入完成")
```

## 虚拟环境与依赖速查

| 目的 | 命令 |
| --- | --- |
| 创建虚拟环境 | `python -m venv .venv` |
| 激活（Windows） | `.venv\Scripts\activate` |
| 激活（macOS / Linux） | `source .venv/bin/activate` |
| 退出 | `deactivate` |
| 导出依赖 | `pip freeze > requirements.txt` |
| 安装依赖 | `pip install -r requirements.txt` |
| 以脚本方式运行模块 | `python -m http.server 8000` |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `from os import *` | 名字冲突，来源不清 | 显式导入需要的名字 |
| `import json` 后写 `loads(...)` | `NameError` | 要写 `json.loads(...)`，或用 `from json import loads` |
| 模块名与标准库同名 | 导入到自己的文件 | 例如别把文件命名为 `json.py`、`random.py` |
| 在包内使用相对导入直接运行文件 | `ImportError: attempted relative import` | 用 `python -m 包名.模块` 运行 |
| `json.dumps` 中文变 `\uXXXX` | 输出难以阅读 | 加 `ensure_ascii=False` |
| 用 `datetime.now()` 存时间却不带时区 | 跨时区出现偏差 | 统一用 UTC 存储，展示时再转本地时区 |
| `open` 不指定编码 | 平台差异导致乱码 | 一律 `encoding="utf-8"` |
| `subprocess.run("ls -l")` | `FileNotFoundError` | 传参数列表：`subprocess.run(["ls", "-l"])` |
| 用 `re.match` 想匹配任意位置 | 匹配不到 | `match` 只从开头匹配，任意位置用 `re.search` |
| 在循环里用 `+=` 拼字符串 | 数据量大时变慢 | 收集到列表后用 `"".join()` |

## 自测清单

- [ ] 会用 `pathlib` 完成「建目录、写文件、读文件」。
- [ ] 会对 JSON 做读写并处理中文。
- [ ] 统计与分组时优先想到 `Counter` 与 `defaultdict`。
- [ ] 每个项目都建独立虚拟环境并导出 `requirements.txt`。
- [ ] 用 `logging` 替代散落的 `print` 做运行日志。

## 零基础详解：模块、包与标准库

### 一句话说清它是什么

模块就是一个 `.py` 文件，包就是「带 `__init__.py` 或命名空间的目录」。
Python 自带一整套标准库，能把文件、时间、正则、命令行这些常见需求直接解决，**不用装第三方包**。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 模块 | 一本工具手册 | 一个 `.py` 文件 |
| 包 | 一排书柜 | 目录下放多个模块 |
| `import` | 从书柜取书 | 用到才取 |
| 虚拟环境 | 独立工作间 | 各项目依赖互不干扰 |
| 标准库 | 出厂自带工具箱 | `pathlib`、`json`、`datetime` 等 |

### 四种导入写法

```python
import json                      # 导入整个模块
from pathlib import Path         # 只导入需要的名字
from collections import defaultdict as dd   # 改名，避免冲突
from .utils import helper        # 包内相对导入

data = json.loads('{"a": 1}')
p = Path("data") / "a.txt"
```

**建议**：优先「用到什么导什么」，但 `import json` 这种短名字也完全可以。

### 最值得先掌握的十个标准库

| 模块 | 解决什么问题 | 典型用法 |
| --- | --- | --- |
| `pathlib` | 路径拼接、读写文件 | `Path("a") / "b.txt"` |
| `json` | 读写 JSON | `json.loads` / `dumps` |
| `datetime` | 日期时间与时区 | `datetime.now(tz)` |
| `re` | 正则匹配与替换 | `re.findall` |
| `collections` | 专用容器 | `Counter`、`defaultdict`、`deque` |
| `itertools` | 组合迭代器 | `chain`、`groupby`、`islice` |
| `functools` | 高阶函数工具 | `lru_cache`、`partial` |
| `os` / `sys` | 环境、参数、退出 | `sys.argv`、`os.environ` |
| `subprocess` | 调用外部命令 | `subprocess.run` |
| `argparse` | 命令行参数解析 | `add_argument` |

### 一段代码展示高频用法

```python
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from functools import lru_cache
from pathlib import Path

# 1. pathlib：路径操作不再是字符串拼接
base = Path("data")
base.mkdir(exist_ok=True)
(base / "note.txt").write_text("你好", encoding="utf-8")

# 2. json：序列化与反序列化
payload = {"id": 1, "tags": ["py", "db"]}
(base / "config.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
)

# 3. Counter：一行做词频
words = "a b a c a".split()
print(Counter(words).most_common(2))          # [('a', 3), ('b', 1)]

# 4. defaultdict：免去判空
groups = defaultdict(list)
for name in ["小明", "小红", "小刚"]:
    groups[name[0]].append(name)

# 5. re：提取与校验
print(re.findall(r"\d+", "订单 12 号，金额 88 元"))

# 6. datetime：带时区的时间
print(datetime.now(timezone.utc).isoformat())

# 7. lru_cache：把重复计算缓存起来
@lru_cache(maxsize=None)
def fib(n: int) -> int:
    return n if n < 2 else fib(n - 1) + fib(n - 2)
```

### 虚拟环境与依赖管理

```bash
python -m venv .venv              # 创建虚拟环境
source .venv/bin/activate         # Linux / macOS 激活
.venv\Scripts\activate            # Windows 激活

pip install requests              # 安装
pip freeze > requirements.txt     # 导出依赖
pip install -r requirements.txt   # 按清单安装
```

**每个项目一个虚拟环境**，否则不同项目的依赖版本会互相打架。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 文件名与标准库重名 | `random.py` 导致导入错乱 | 别用 `json.py`、`re.py` 这类名字 |
| 循环导入 | `ImportError` 或半初始化模块 | 拆出公共模块或用函数内导入 |
| 忘了 `encoding="utf-8"` | 中文乱码 | 读写文本一律指定 |
| 用 `os.path` 拼字符串 | 跨平台出错 | 用 `pathlib` |
| 不用虚拟环境 | 依赖冲突 | 每项目独立 `.venv` |
| 用 `eval` 解析 JSON | 安全漏洞 | 用 `json.loads` |
| 用 `datetime.now()` 存时间 | 时区混乱 | 存 UTC，展示再转本地 |
| 把密码写进代码 | 泄露 | 用环境变量或配置外置 |

### 手把手练习：统计日志目录

```python
import json
import re
from collections import Counter
from pathlib import Path

def summarize(log_dir: str) -> dict:
    levels = Counter()
    total_lines = 0
    for file in Path(log_dir).glob("*.log"):
        for line in file.read_text(encoding="utf-8").splitlines():
            total_lines += 1
            match = re.search(r"\b(INFO|WARN|ERROR)\b", line)
            if match:
                levels[match.group(1)] += 1
    return {"files": len(list(Path(log_dir).glob("*.log"))),
            "lines": total_lines,
            "levels": dict(levels)}

if __name__ == "__main__":
    print(json.dumps(summarize("logs"), ensure_ascii=False, indent=2))
```

### 学完自测

- [ ] 能说出模块与包的区别。
- [ ] 能列出至少六个标准库及其用途。
- [ ] 知道为什么要为每个项目建虚拟环境。
- [ ] 会用 `pathlib` 与 `json` 完成一次读写。
- [ ] 知道为什么不能用 `eval` 解析外部数据。

## 动手练习

> 本课练习重点：围绕「import、模块、包」完成复述、实验和交付，每个结果都要能被别人检查。

先写可运行脚本，再用类型注解与测试保护核心函数，最后处理真实输入。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 模块、包与虚拟环境解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「模块」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

写一个 20 行以内的小脚本，把本课概念用于处理一份真实文本或列表数据。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「import」和「模块」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 可运行练习

### 任务 1：先跑通，再解释

```python
import math                     # 导入整个模块
from math import sqrt, pi       # 只导入需要的名字
from pathlib import Path as P   # 起别名

print(math.floor(3.7), sqrt(16), pi)
```

### 任务 2：只改一个条件

把「模块、包与虚拟环境」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只把import的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「模块、包与虚拟环境」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响import。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：本课的 import 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 import 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 import 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“import 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 import 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 模块 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 模块 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 模块 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“模块 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 模块 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：本课的验证只在开发机通过

**症状**：在本课的练习或生产场景里出现“本课的验证只在开发机通过”。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，import 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 版本与时效

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改一个版本变量，记录编译、测试、性能与产物体积的变化。
- 重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。
- 升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「if __name__ == '__main__': 的作用是？」的判断依据。
- [ ] 不看解析，能说出「为每个项目创建虚拟环境的主要目的是？」的判断依据。
- [ ] 不看解析，能说出「统计词频最方便的标准库是？」的判断依据。
- [ ] 不看解析，能说出「为什么不推荐 from module import *？」的判断依据。
- [ ] 不看解析，能说出「pathlib.Path 相比手写字符串拼接路径的优势是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

| 术语 | 本课语境 |
| --- | --- |
| `if __name__ == "__main__":` | `if __name__ == "__main__":` 里的代码只在直接运行该文件时执行，被导入时不执行： |
| `from .text import slugify` | 包内推荐使用绝对导入；相对导入（`from .text import slugify`）只在包内部使用。 |
| `os` | \| `os` / `pathlib` \| 文件与路径操作 \| |
| `pathlib` | \| `os` / `pathlib` \| 文件与路径操作 \| |
| `json` | \| `json` / `csv` \| 数据读写 \| |
| `csv` | \| `json` / `csv` \| 数据读写 \| |

## 考点精讲

### 考点 1：多选辨析·import

- **题目**：围绕“模块、包与虚拟环境”中的 import、模块、包，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把模块、包与虚拟环境拆成概念、示例与故障现场三部分，因此判断 import 时必须同时交代输入、输出和失败路径，这使“学习 import 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在模块、包与虚拟环境里，判断 模块 时要固定版本与边界输入，所以“验证 模块 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：概念判断·import

- **题目**：为每个项目创建虚拟环境的主要目的是？
- **判断依据**：虚拟环境让不同项目使用各自的依赖版本，互不影响。在「模块、包与虚拟环境」里，作答时，先用import建立输入与输出的基线，再把隔离项目依赖，避免版本冲突代入边界条件核对，结论才能复现。在「模块、包与虚拟环境」里判断这道题，要把import、模块、包的条件、过程与失败路径逐项对齐，换成“为每个项目创建虚拟环境的主要目的是”这个场景，只有满足前提的结论才成立。

### 考点 3：概念判断·import

- **题目**：统计词频最方便的标准库是？
- **判断依据**：在「模块、包与虚拟环境」里，collections.Counter 专门用于计数，mostcommon(n) 可直接取出前 n 名。在「模块、包与虚拟环境」里，其他选项：pathlib 管路径、subprocess（仅部分场景成立） 调进程、math 做数学运算，只有 Counter 专门用于计数。

### 考点 4：代码补全·import

- **题目**：下面这段 Python 代码摘自「模块、包与虚拟环境」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？
- **判断依据**：在「模块、包与虚拟环境」里，题干的正确项是这段代码只做静态声明，没有循环、分支或可观察输出，在「模块、包与虚拟环境」里它只能证明import相关约束存在，不能替代真实运行证据。把输入或边界换成空值、极值或失败情况后，结论要以「模块、包与虚拟环境」的实际运行结果为准。「模块、包与虚拟环境」要求先交代import、模块、包的前提再下结论，所以“这段代码只做静态声明，没有循环”只在题干“下面这段 Python 代码摘自模块、包与虚拟环境的正文示例”给定的条件下成立。

### 考点 5：概念判断·import

- **题目**：pathlib.Path 相比手写字符串拼接路径的优势是？
- **判断依据**：在「模块、包与虚拟环境」里，跨平台分隔符自动处理。用 / 运算符拼路径更直观，也不用担心 Windows 的反斜杠转义。在「模块、包与虚拟环境」里判断这道题，要把import、模块、包的条件、过程与失败路径逐项对齐，换成“pathlib.Path 相比手写字”这个场景，只有满足前提的结论才成立。

### 考点 6：填空·import

- **题目**：补全代码：「模块、包与虚拟环境」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `logging.____(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")`
- **判断依据**：在「模块、包与虚拟环境」里，basicConfig。在「模块、包与虚拟环境」里判断这道题，要把import、模块、包的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。“包与虚拟环境示例中”与「模块、包与虚拟环境」的术语表相呼应，只有符合import、模块、包约束的“basicConfig”才是正文支持的结论。

## English Overview

**Title:** Modules & Virtualenv

**Summary:** Imports, packages, virtualenv and the standard library.

**Category:** Python
**Level:** 进阶
**Key terms:** import, 模块, 包, venv, pip, 标准库

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Python 3.12+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：import、模块、包、venv、pip、标准库
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Python 打包指南](https://packaging.python.org/) | 依赖、构建与发布 |
| [Python 标准库](https://docs.python.org/3/library/) | 标准库 API 与模块 |
| [PEP 索引](https://peps.python.org/) | 语言提案与版本演进 |

> 「模块、包与虚拟环境」的链接用于离线阅读后的延伸核对；App 不会自动联网。
