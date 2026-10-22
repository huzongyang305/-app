## 常见异常速查

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

## 文件操作速查

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

## 常见错误对照表

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

## 自测清单

- [ ] 能列出五个以上常见异常并知道触发条件。
- [ ] 处理文件一定写 `encoding="utf-8"` 并用 `with`。
- [ ] 知道 `finally` 一定执行，`else` 只在无异常时执行。
- [ ] 重新抛出异常时保留原始堆栈（`raise` 或 `from`）。
- [ ] 会用 `pathlib` 读写文本文件。
