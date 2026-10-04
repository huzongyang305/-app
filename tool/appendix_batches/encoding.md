## 编码速查

| 编码 | 单位 | 特点 | 适用 |
| --- | --- | --- | --- |
| ASCII | 1 字节 | 0 到 127，只覆盖英文 | 历史遗留 |
| Latin-1 | 1 字节 | 0 到 255，西欧字符 | 老系统 |
| GBK | 1 到 2 字节 | 中文兼容 ASCII | 国内旧系统 |
| UTF-8 | 1 到 4 字节 | 兼容 ASCII，无字节序问题 | 网络与文件首选 |
| UTF-16 | 2 或 4 字节 | 有字节序问题，需 BOM | Windows API、Java 内部 |
| UTF-32 | 4 字节 | 定长，空间浪费 | 内部处理 |

| Unicode 范围 | UTF-8 字节数 | 示例 |
| --- | --- | --- |
| U+0000 到 U+007F | 1 | ASCII |
| U+0080 到 U+07FF | 2 | 拉丁扩展、希腊文 |
| U+0800 到 U+FFFF | 3 | 中文、日文汉字 |
| U+10000 到 U+10FFFF | 4 | Emoji、扩展汉字 |

```python
# 明确编码，避免平台差异
text = "你好，世界"
raw = text.encode("utf-8")
print(len(text), len(raw))          # 5 与 15：中文 3 字节，标点 3 字节
print(raw.decode("utf-8"))

# 处理非法字节：忽略、替换或用替代字符
bad = b"\xff\xfehello"
print(bad.decode("utf-8", errors="replace"))

# 读写文件统一 UTF-8
from pathlib import Path
path = Path("note.txt")
path.write_text(text, encoding="utf-8")
print(path.read_text(encoding="utf-8"))

# 需要 BOM 以兼容 Excel 时可写 utf-8-sig
Path("table.csv").write_text("名称,数量\n苹果,3\n", encoding="utf-8-sig")
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 读写文件不指定编码 | Windows 上按 GBK 解码导致乱码 | 一律显式 `encoding="utf-8"` |
| 认为 `len(str)` 等于字节数 | 长度与存储量不符 | 中文一个字通常 3 字节 |
| 把 Unicode 与 UTF-8 混为一谈 | 概念错误 | Unicode 是字符集，UTF-8 是编码方式 |
| 用 `errors="ignore"` 静默丢数据 | 数据悄悄缺失 | 用 `replace` 或记录错误并告警 |
| 在 UTF-8 文件里加 BOM | 解析器把 BOM 当内容 | JSON 与配置文件用无 BOM 的 UTF-8 |
| 按字节截断字符串 | 出现半个字符导致乱码 | 按字符或码位截断，或按字节但校验边界 |
| 认为 UTF-16 与字节序无关 | 跨平台读取乱码 | 明确 BOM 或统一用 UTF-8 |
| 用 `upper()` 比较国际化文本 | 某些语言结果不符 | 用 locale 感知的比较或大小写折叠 |
| Emoji 用 1 个 Java char 表示 | 取到半个代理对 | 用码位 API（`codePointAt`） |
| Base64 当作加密 | 数据可还原 | Base64 只是编码，不是加密 |

## 自测清单

- [ ] 能说出 Unicode 与 UTF-8 的区别。
- [ ] 知道常用汉字在 UTF-8 中占 3 字节。
- [ ] 读写文件一律显式指定编码。
- [ ] 知道 BOM 的作用与副作用。
- [ ] 处理非法字节时明确使用替换或告警策略。
