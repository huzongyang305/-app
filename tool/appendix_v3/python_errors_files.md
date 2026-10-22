## 零基础详解：异常处理与文件读写

### 一句话说清它是什么

异常处理让程序**出错时不崩溃**，而是走另一条路；文件读写解决「数据要存下来」的问题。
两者经常一起用：读文件最容易出错，所以要用 `try` 包住。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| `try` | 试着做一件事 | 可能出错的代码 |
| `except` | 出问题时的备用方案 | 按异常类型分别处理 |
| `else` | 顺利做完才做的事 | 没有异常时执行 |
| `finally` | 无论怎样都要做的收尾 | 关闭资源、清理临时文件 |
| `with` | 自动收尾的托管 | 离开代码块自动关闭文件 |

### 异常处理的完整结构

```python
try:
    raw = input("请输入除数：")
    divisor = int(raw)
    result = 100 / divisor
except ValueError:
    print("这不是一个整数")
except ZeroDivisionError:
    print("除数不能为 0")
else:
    print("结果是", result)      # 没出错才执行
finally:
    print("计算结束")            # 无论如何都执行
```

### 常见异常类型速查

| 异常 | 什么时候出现 | 典型修法 |
| --- | --- | --- |
| `ValueError` | 类型对但值不对，如 `int("abc")` | 先校验输入 |
| `TypeError` | 类型不对，如 `"1" + 1` | 显式转换 |
| `KeyError` | 字典键不存在 | 用 `.get()` 或先判断 |
| `IndexError` | 下标越界 | 检查长度 |
| `FileNotFoundError` | 文件不存在 | 检查路径或先创建 |
| `PermissionError` | 没有权限 | 换路径或以合适身份运行 |
| `ZeroDivisionError` | 除以 0 | 先判断分母 |
| `AttributeError` | 对象没有这个属性 | 检查拼写与类型 |

### 文件读写的三种写法

```python
# 1. 一次读全部（小文件）
with open("data.txt", encoding="utf-8") as f:
    content = f.read()

# 2. 按行读（大文件，内存友好）
with open("data.txt", encoding="utf-8") as f:
    for line in f:
        print(line.rstrip())

# 3. 写入与追加
with open("out.txt", "w", encoding="utf-8") as f:
    f.write("第一行\n")

with open("out.txt", "a", encoding="utf-8") as f:
    f.write("追加一行\n")
```

| 模式 | 含义 | 注意 |
| --- | --- | --- |
| `"r"` | 只读（默认） | 文件不存在会报错 |
| `"w"` | 覆盖写 | **会清空原内容** |
| `"a"` | 追加 | 不会清空 |
| `"x"` | 只在文件不存在时创建 | 已存在则报错 |
| `"rb"` / `"wb"` | 二进制读写 | 图片、压缩包用 |

**`encoding="utf-8"` 一定要写**，否则在中文 Windows 上容易乱码。

### 读 JSON / CSV 的规范写法

```python
import csv
import json

with open("config.json", encoding="utf-8") as f:
    config = json.load(f)          # 读：文件 -> 字典

with open("out.json", "w", encoding="utf-8") as f:
    json.dump(config, f, ensure_ascii=False, indent=2)

with open("users.csv", encoding="utf-8", newline="") as f:
    for row in csv.DictReader(f):
        print(row["name"])
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用裸 `except:` | 连 Ctrl+C 都吞掉，问题被掩盖 | 指明具体异常类型 |
| 用异常代替判断 | 逻辑绕、性能差 | 能用 `if` 判断就判断 |
| 忘写 `encoding` | 中文乱码 | 一律写 `utf-8` |
| 用 `"w"` 追加 | 原文件被清空 | 追加用 `"a"` |
| 不用 `with` | 异常时文件句柄不释放 | 始终用 `with` |
| 路径写死绝对路径 | 换机器就跑不了 | 用 `pathlib.Path` 拼接 |
| 读大文件用 `read()` | 内存爆掉 | 逐行迭代 |
| 在 `finally` 里返回 | 覆盖掉真正的返回值 | 别在 `finally` 中返回 |

### 用 `pathlib` 写更现代的路径处理

```python
from pathlib import Path

base = Path("data")
base.mkdir(exist_ok=True)              # 目录存在也不报错
target = base / "notes.txt"            # 用 / 拼路径，跨平台

target.write_text("你好", encoding="utf-8")
print(target.read_text(encoding="utf-8"))
print(target.exists(), target.stat().st_size)
```

### 手把手练习：安全读取配置

```python
import json
from pathlib import Path


def load_config(path: str) -> dict:
    file = Path(path)
    if not file.exists():
        raise FileNotFoundError(f"配置文件不存在：{file}")

    try:
        data = json.loads(file.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"配置不是合法 JSON：{exc}") from exc

    if not isinstance(data, dict):
        raise ValueError("配置顶层必须是对象")
    return data


try:
    print(load_config("config.json"))
except (FileNotFoundError, ValueError) as err:
    print("加载失败：", err)
```

### 学完自测

- [ ] 能说出 `try / except / else / finally` 各自的执行时机。
- [ ] 知道为什么不该写裸 `except:`。
- [ ] 能说出 `"w"`、`"a"`、`"x"` 三种模式的区别。
- [ ] 会用 `with open(..., encoding="utf-8")` 读写文本。
- [ ] 能用 `pathlib` 拼接路径并判断文件是否存在。
