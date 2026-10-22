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
