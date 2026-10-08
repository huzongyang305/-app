# 异常处理与文件操作

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：55 分钟

![异常处理与文件操作](images/diagram_py_errors.webp)

![异常处理与文件操作](images/remaining_python_errors_files.webp)

## 本节知识框架

**课程定位**：所属分类为「Python」，课程主题为「异常处理与文件操作」，学习阶段为「进阶」，建议用时 55 分钟。

**本课要解决的主问题**：try/except/else/finally、自定义异常、with 读写文件与 pathlib。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「异常处理与文件操作」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「异常处理与文件操作」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「异常」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《类与对象》

**学习位置**：本课位于《类与对象》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《模块、包与虚拟环境》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释异常处理与文件操作解决了什么问题，而不是只背术语。
- 能说清 「异常」、「try」、「except」、「with」 之间的关系，并分别举出一个例子。
- 能把 异常 放回「异常处理与文件操作」的知识体系，说明它和 try 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：try/except/else/finally、自定义异常、with 读写文件与 pathlib。

**教材衔接：前置知识**

- 先完成上一课《类与对象》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「类与对象」，或确认自己能独立跑通正文里的 BalanceError 示例。
- 开始前先复习：异常、try、except。
- 如果 捕获异常 这一步看不懂，先记录具体卡点，再用 BalanceError 复现一遍。

**教材衔接：本课小结**

异常用来处理「可预期的失败」，`with` 用来管理资源，`pathlib` 用来处理跨平台路径。

## 核心概念定义

> 阅读约定：本课先给「异常处理与文件操作」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| ValueError | 常见异常：ValueError 值不合法、TypeError 类型不匹配、KeyError 字典键不存在、IndexError 下标越界、FileNotFoundError 文件不存在。 | 仅在「异常处理与文件操作」明确给出的输入、版本与资源条件下成立。 |
| 异常 | 程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换。 | 仅在「异常处理与文件操作」明确给出的输入、版本与资源条件下成立。 |
| 上下文管理器 | with 语句在进入与退出时自动获取和释放资源，文件与锁都靠它保证释放。 | 仅在「异常处理与文件操作」明确给出的输入、版本与资源条件下成立。 |
| 异常链 | 用 raise ... from 保留原始异常，traceback 里才能看到真正的起因。 | 仅在「异常处理与文件操作」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「异常处理与文件操作」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「ValueError」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「异常」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「上下文管理器」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「异常处理与文件操作」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | ValueError | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | 异常 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 上下文管理器 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「异常处理与文件操作」自己的示例验证。「异常处理与文件操作」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：版本与时效**

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改 异常 的版本变量，记录编译、测试与产物体积的变化。
- 先回归 异常 与 try 的默认行为和错误信息，再扩大测试范围。
- 升级完成后记录 异常 的新旧版本差异，并据此调整下次复核时间。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 异常、try | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「异常处理与文件操作」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「异常处理与文件操作」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:python`，用于动手验证《异常处理与文件操作》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《异常处理与文件操作》原文中的最小示例。先预测《异常处理与文件操作》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```python
try:
    number = int("abc")
except ValueError as error:
    print("格式错误：", error)
except (TypeError, KeyError):
    print("类型或键错误")
else:
    print("没有异常时执行")
finally:
    print("无论如何都会执行，用于释放资源")
```

**教材衔接：捕获异常**

```python
try:
    number = int("abc")
except ValueError as error:
    print("格式错误：", error)
except (TypeError, KeyError):
    print("类型或键错误")
else:
    print("没有异常时执行")
finally:
    print("无论如何都会执行，用于释放资源")
```

常见异常：`ValueError` 值不合法、`TypeError` 类型不匹配、`KeyError` 字典键不存在、`IndexError` 下标越界、`FileNotFoundError` 文件不存在。

原则：**只捕获你真正能处理的异常**，不要写 `except Exception: pass` 把问题吞掉。

**教材衔接：抛出异常**

```python
def set_age(age):
    if age < 0:
        raise ValueError(f"年龄不能为负：{age}")
    return age

class BalanceError(Exception):
    """自定义异常：余额不足。"""

try:
    raise BalanceError("余额不足")
except BalanceError as error:
    print(error)
```

**教材衔接：读写文件**

用 `with` 打开文件，离开代码块会自动关闭，即使发生异常也安全。

```python
# 写文件（覆盖）
with open("notes.txt", "w", encoding="utf-8") as file:
    file.write("第一行\n")

# 追加
with open("notes.txt", "a", encoding="utf-8") as file:
    file.write("第二行\n")

# 读文件
with open("notes.txt", "r", encoding="utf-8") as file:
    for line in file:
        print(line.rstrip())
```

常用模式：`r` 读、`w` 覆盖写、`a` 追加、`rb` 二进制读。**处理文本时始终显式指定 `encoding="utf-8"`**。

**教材衔接：路径与 JSON**

```python
from pathlib import Path
import json

path = Path("data") / "config.json"
path.parent.mkdir(parents=True, exist_ok=True)

path.write_text(json.dumps({"debug": True}, ensure_ascii=False), encoding="utf-8")
config = json.loads(path.read_text(encoding="utf-8"))
print(config["debug"])
```

**教材衔接：常见异常速查**

| 异常 | 典型触发 | 处理建议 |
| --- | --- | --- |
| `ValueError` | `int("abc")` | 校验输入或用 `try/except` 提示用户 |
| `TypeError` | `"a" + 1` | 修类型，而不是靠捕获掩盖 |
| `KeyError` | 访问不存在的字典键 | 用 `get()` / `setdefault()` |
| `IndexError` | 列表下标越界 | 先判断长度或捕获 |
| `AttributeError` | 对象没有该属性 | 检查拼写与空值 |
| `FileNotFoundError` | 打开不存在的文件 | 判断存在或用 `try/except` |
| `PermissionError` | 没有读写权限 | 检查路径与运行用户 |
| `ZeroDivisionError` | 除以 0 | 先判断分母 |
| `UnicodeDecodeError` | 以错误编码读文件 | 明确 `encoding="utf-8"` |
| `ModuleNotFoundError` | 模块未安装或路径不对 | 检查虚拟环境与依赖 |
| `RecursionError` | 递归过深 | 加终止条件，或改写成迭代 |

异常处理写法对照：

| 目的 | 推荐写法 |
| --- | --- |
| 兜住指定异常 | `except ValueError as exc:` |
| 多个异常同一处理 | `except (ValueError, TypeError):` |
| 无论是否异常都要清理 | `finally:` 或 `with` |
| 无异常时执行 | `try` 的 `else:` 分支 |
| 重新抛出并保留堆栈 | `raise`（不带参数）或 `raise NewError(...) from exc` |
| 记录完整堆栈 | `logging.exception("上下文")` |

```python
import logging

try:
    value = int(raw)
except ValueError as exc:
    logging.exception("解析失败：%s", raw)   # 保留堆栈，便于排查
    raise
else:
    print("解析成功", value)
finally:
    print("无论成功失败都会执行")
```

**教材衔接：文件操作速查**

| 模式 | 含义 | 文件不存在时 | 是否清空 |
| --- | --- | --- | --- |
| `r` | 只读 | 报错 | 否 |
| `w` | 只写 | 新建 | **是** |
| `a` | 追加 | 新建 | 否 |
| `x` | 独占创建 | 报错 | 新建 |
| `r+` | 读写 | 报错 | 否 |
| `rb` / `wb` | 二进制读写 | 同上 | 同上 |

```python
from pathlib import Path

path = Path("data") / "notes.txt"
path.parent.mkdir(parents=True, exist_ok=True)   # 确保目录存在
path.write_text("你好\n", encoding="utf-8")      # 一步写完
print(path.read_text(encoding="utf-8"))          # 一步读完

with path.open("a", encoding="utf-8") as file:   # 追加并自动关闭
    file.write("第二行\n")

for line in path.read_text(encoding="utf-8").splitlines():
    print(line.strip())
```

**教材衔接：零基础详解：异常处理与文件读写**

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

## 时间/空间复杂度或性能分析

**复杂度证据**：「异常处理与文件操作」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「异常处理与文件操作」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「异常处理与文件操作」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《异常处理与文件操作》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「异常处理与文件操作」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `open(...)` 不写 `encoding` | 在 Windows 上按 GBK 解码，出现乱码或 `UnicodeDecodeError` | 显式写 `encoding="utf-8"` |
| 用 `open` 后忘记 `close` | 文件被占用、内容未落盘 | 用 `with` 语句自动关闭 |
| `except Exception: pass` | 真实 bug 被吞掉 | 至少记录日志；只捕获预期异常 |
| 把 `try` 包住一大段代码 | 定位困难，还可能误捕无关错误 | 只包住可能失败的最小片段 |
| `json.loads("")` | `JSONDecodeError` | 先判断空字符串，或用 `try/except` |
| 用 `+` 拼路径 | 跨平台分隔符出错 | 用 `pathlib.Path` 的 `/` 运算 |
| `readlines()` 读超大文件 | 内存爆掉 | 逐行迭代文件对象或分块读取 |
| 写入时忘了 `flush` / 关闭 | 进程被杀导致内容丢失 | 用 `with`，必要时 `file.flush()` + `os.fsync()` |
| 捕获异常后返回 `None` | 调用方继续用空值出错 | 明确抛出或返回统一的结果对象 |

**教材衔接：故障现场**

### 现场 1：open(...) 不写 encoding

**症状**：在《异常处理与文件操作》的复现场景中，在 Windows 上按 GBK 解码，出现乱码或 UnicodeDecodeError。

**根因**：“在 Windows 上按 GBK 解码，出现乱码或 UnicodeDecodeError”只是表层结果。向上追溯会落到“open(...) 不写 encoding”这一步，因为它省略了《异常处理与文件操作》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《异常处理与文件操作》的问题，显式写 encoding="utf-8"。

**验证**：先在《异常处理与文件操作》中记录“open(...) 不写 encoding”留下的失败证据，再执行“显式写 encoding="utf-8"”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 2：用 open 后忘记 close

**症状**：在《异常处理与文件操作》的复现场景中，文件被占用、内容未落盘。

**根因**：当出现“用 open 后忘记 close”时，执行路径已经绕过了《异常处理与文件操作》的关键约束，最终以“文件被占用、内容未落盘”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《异常处理与文件操作》的问题，用 with 语句自动关闭。

**验证**：先在《异常处理与文件操作》中记录“用 open 后忘记 close”留下的失败证据，再执行“用 with 语句自动关闭”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 3：except Exception: pass

**症状**：在《异常处理与文件操作》的复现场景中，真实 bug 被吞掉。

**根因**：触发点是把“except Exception: pass”当成安全做法。它没有满足《异常处理与文件操作》要求的前提，因此先表现为“真实 bug 被吞掉”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《异常处理与文件操作》的问题，至少记录日志；只捕获预期异常。

**验证**：在《异常处理与文件操作》中按“至少记录日志；只捕获预期异常”调整后，从“except Exception: pass”的触发条件重放同一条路径，确认“真实 bug 被吞掉”不再出现，并补一个相邻边界用例检查没有引入新问题。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《类与对象》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《模块、包与虚拟环境》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 关联 | 《异常处理与文件 IO》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 关联 | 《错误处理与调试》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《类与对象》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《模块、包与虚拟环境》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「异常处理与文件操作」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《异常处理与文件操作》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

围绕“异常处理与文件操作”中的 异常、try、except，下列哪两项是本课强调的实践判断？

A. 学习 异常 时要同时说明输入、输出和失败路径，不能只看正常流程
B. 只要 异常 的常规示例通过，就可以跳过边界与异常路径
C. 验证 try 时要固定版本并覆盖边界输入，结论才可复现
D. 把 try 的单次运行结果当成所有版本和规模都成立

**参考答案**：学习 异常 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 try 时要固定版本并覆盖边界输入，结论才可复现

**解析**：本课把异常处理与文件操作拆成概念、示例与故障现场三部分，因此判断 异常 时必须同时交代输入、输出和失败路径，这使“学习 异常 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在异常处理与文件操作里，判断 try 时要固定版本与边界输入，所以“验证 try 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 2

这段 Python 代码是「异常处理与文件操作」的示例片段，下面哪一项描述与它一致？

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

A. 这段代码包含条件分支，不同输入会走不同的执行路径。
B. 这段代码只做静态声明，没有循环、分支或可观察输出。
C. 这段代码包含循环结构，同一段逻辑会被重复执行。
D. 这段代码会读取外部输入，结果依赖传入的数据。

**参考答案**：这段代码包含条件分支，不同输入会走不同的执行路径。

**解析**：题干的正确项是这段代码包含条件分支，不同输入会走不同的执行路径，在「异常处理与文件操作」里分支条件由异常决定，替换条件后结论可能变化。这段代码出自「异常处理与文件操作」的正文示例，围绕异常、try、except展开；把输入或边界换成空值、极值或失败情况后，结论要以「异常处理与文件操作」的实际运行结果为准。“Python”与「异常处理与文件操作」的术语表相呼应，只有符合异常、try、except约束的“这段代码包含条件分支”才是正文支持的结论。

### 自测 3

下面哪种异常处理方式最不推荐？

A. 捕获具体的 ValueError，但这会引入新的复杂度，需要额外的验证与维护
B. 记录日志后重新抛出
C. except Exception: pass 静默吞掉所有异常
D. 使用 finally 释放资源

**参考答案**：except Exception: pass 静默吞掉所有异常

**解析**：在「异常处理与文件操作」里，except Exception: pass 静默吞掉所有异常。静默吞异常会掩盖真实缺陷，应当只捕获能处理的异常并保留上下文。“下面哪种异常处理方式最不推荐”与「异常处理与文件操作」的术语表相呼应，只有符合异常、try、except约束的“except Exception”才是正文支持的结论。

**教材衔接：复习与自测**

- [ ] 能列出五个以上常见异常并知道触发条件。
- [ ] 处理文件一定写 `encoding="utf-8"` 并用 `with`。
- [ ] 知道 `finally` 一定执行，`else` 只在无异常时执行。
- [ ] 重新抛出异常时保留原始堆栈（`raise` 或 `from`）。
- [ ] 会用 `pathlib` 读写文本文件。

**教材衔接：动手练习**

> 本课练习重点：围绕「异常、try、except」完成复述、实验和交付，每个结果都要能被别人检查。

把 BalanceError 抽成函数并补类型标注，最后换成真实输入验证。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 异常处理与文件操作解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「try」是什么关系？

验收标准：用自己的话解释 异常，并给出一个它不成立的反例。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：先在「捕获异常」里找一个可运行的最小输入，再按五步法记录异常的影响；预测与结果不一致时补写被忽略的前提。

### 练习 3：交付一个小结果（30 分钟）

用 BalanceError 解析一份自己的数据，输出统计结果并核对一条记录。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「异常」和「try」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```python
try:
    number = int("abc")
except ValueError as error:
    print("格式错误：", error)
except (TypeError, KeyError):
    print("类型或键错误")
else:
    print("没有异常时执行")
finally:
    print("无论如何都会执行，用于释放资源")
```

**预期输出**：无论如何都会执行，用于释放资源

### 任务 2：只改一个条件

把「异常处理与文件操作」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只调整 BalanceError 的一个参数，其余条件一律不动。
- 预测：先写下「异常处理与文件操作」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响异常。

### 任务 3：迁移到自己的数据

换一个 try 场景重做一次，确认结论不是只对示例数据成立。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「try/except/finally 中的 finally 什么时候执行？」的判断依据。
- [ ] 不看解析，能说出「读写文件推荐的写法是？」的判断依据。
- [ ] 不看解析，能说出「下面哪种异常处理方式最不推荐？」的判断依据。
- [ ] 不看解析，能说出「读取一个不存在的文件，会抛出哪个异常？」的判断依据。
- [ ] 不看解析，能说出「自定义异常类通常继承自？」的判断依据。
- [ ] 用 异常 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `ValueError` | 常见异常：`ValueError` 值不合法、`TypeError` 类型不匹配、`KeyError` 字典键不存在、`IndexError` 下标越界、`FileNotFoundError` 文件不存在。 |
| `异常` | 程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换。 |
| `上下文管理器` | with 语句在进入与退出时自动获取和释放资源，文件与锁都靠它保证释放。 |
| `异常链` | 用 raise ... from 保留原始异常，traceback 里才能看到真正的起因。 |

## 考点精讲

### 考点 1：多选辨析·异常

- **题目**：围绕“异常处理与文件操作”中的 异常、try、except，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把异常处理与文件操作拆成概念、示例与故障现场三部分，因此判断 异常 时必须同时交代输入、输出和失败路径，这使“学习 异常 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在异常处理与文件操作里，判断 try 时要固定版本与边界输入，所以“验证 try 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：代码补全·异常

- **题目**：这段 Python 代码是「异常处理与文件操作」的示例片段，下面哪一项描述与它一致？
- **判断依据**：题干的正确项是这段代码包含条件分支，不同输入会走不同的执行路径，在「异常处理与文件操作」里分支条件由异常决定，替换条件后结论可能变化。这段代码出自「异常处理与文件操作」的正文示例，围绕异常、try、except展开；把输入或边界换成空值、极值或失败情况后，结论要以「异常处理与文件操作」的实际运行结果为准。“Python”与「异常处理与文件操作」的术语表相呼应，只有符合异常、try、except约束的“这段代码包含条件分支”才是正文支持的结论。

### 考点 3：概念判断·异常

- **题目**：下面哪种异常处理方式最不推荐？
- **判断依据**：在「异常处理与文件操作」里，except Exception: pass 静默吞掉所有异常。静默吞异常会掩盖真实缺陷，应当只捕获能处理的异常并保留上下文。“下面哪种异常处理方式最不推荐”与「异常处理与文件操作」的术语表相呼应，只有符合异常、try、except约束的“except Exception”才是正文支持的结论。

### 考点 4：概念判断·异常

- **题目**：读取一个不存在的文件，会抛出哪个异常？
- **判断依据**：在「异常处理与文件操作」里，FileNotFoundError 是 OSError 的子类，捕获时也可以按 OSError 处理。在「异常处理与文件操作」里，其他选项：抛出 IndexError 对应下标越界，KeyError 是字典缺键，TypeError 是类型不匹配。在「异常处理与文件操作」里，这道题要求区分概念与边界，「FileNotFoundError」只有在题干给出的前提下才成立，而「抛出 IndexError」、「TypeError」缺少同一组条件。

### 考点 5：概念判断·异常

- **题目**：自定义异常类通常继承自？
- **判断依据**：在「异常处理与文件操作」里，继承 Exception 可被常规 except 捕获，也便于按业务分层定义异常体系。在「异常处理与文件操作」里，其他选项：BaseException 是包含 KeyboardInterrupt 在内的顶层基类。这道题的关键在「异常处理与文件操作」的异常、try、except：先确认题干“自定义异常类通常继承自”问的是哪一步，再排除偷换前提的选项。

### 考点 6：填空·异常

- **题目**：补全代码：「异常处理与文件操作」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `raise ____(f"配置文件不存在：{file}")`
- **判断依据**：空格应填写「FileNotFoundError」、「filenotfounderror」。把“FileNotFoundError”代回「异常处理与文件操作」里“异常处理与文件操作示例中”的例子核对，条件一旦改变，结论就要用异常、try、except重新推导。「异常处理与文件操作」要求先交代异常、try、except的前提再下结论，所以“FileNotFoundError”只在题干“FileNotFoundError”给定的条件下成立。

## English Overview

**Title:** Exceptions & Files

**Summary:** Exception handling, custom errors, file IO and pathlib.

**Category:** Python
**Level:** 进阶
**Key terms:** 异常, try, except, with, 文件, pathlib

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Python 3.12+
；本课聚焦 异常。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：异常、try、except、with、文件、pathlib
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2026-11-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Python 标准库](https://docs.python.org/3/library/) | 标准库 API 与模块 |
| [Python 性能分析](https://docs.python.org/3/library/profile.html) | cProfile 与性能分析 |
| [unittest 文档](https://docs.python.org/3/library/unittest.html) | 测试组织与断言 |

> 「异常处理与文件操作」的链接用于离线阅读后的延伸核对；App 不会自动联网。
