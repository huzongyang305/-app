## 补充：UTF-8 编码规则、乱码排查与代码实践

### 码点、编码与字形：三个概念分清

```text
码点（Code Point）  字符在 Unicode 表中的编号，如「中」= U+4E2D
编码（Encoding）    码点如何变成字节，如 UTF-8 用 3 字节表示 U+4E2D
字形（Glyph）       字体把码点画出来的样子

同一个码点在不同字体下字形可以不同；同一个字节序列用不同编码解释会得到不同字符
```

### UTF-8 的编码规则

| 码点范围 | 字节数 | 首字节格式 | 后续字节 |
| --- | --- | --- | --- |
| U+0000 ~ U+007F | 1 | `0xxxxxxx` | —— |
| U+0080 ~ U+07FF | 2 | `110xxxxx` | `10xxxxxx` |
| U+0800 ~ U+FFFF | 3 | `1110xxxx` | `10xxxxxx` × 2 |
| U+10000 ~ U+10FFFF | 4 | `11110xxx` | `10xxxxxx` × 3 |

```text
例：「中」= U+4E2D
  二进制：0100 1110 0010 1101
  填入三字节模板：1110[0100] 10[111000] 10[101101]
  得到：E4 B8 AD   ← 这正是 UTF-8 下的三个字节

自校验特性
  · 首字节的高位决定了「这个词有多长」
  · 后续字节都以 10 开头，因此从任意位置也能重新同步
```

### 常见乱码与成因对照

| 现象 | 典型成因 | 修法 |
| --- | --- | --- |
| `ä¸æ–‡` | UTF-8 字节被按 Latin-1 解读 | 统一声明 UTF-8 |
| `���` | 解码时遇到非法字节，被替换为 U+FFFD | 检查源文件与声明的编码是否一致 |
| `涓枃` | UTF-8 被按 GBK 解读 | 读写两端统一 UTF-8 |
| 首部多出 `ï»¿` | 把 UTF-8 BOM 当成正文字符 | 读文件时忽略 BOM |
| Windows 下正常、Linux 乱码 | 依赖系统默认编码 | 显式指定 `encoding="utf-8"` |

```bash
# 排查：先看字节，再猜编码
file -i data.txt                  # 查看文件声明的编码
xxd data.txt | head -2            # 看真实字节
iconv -f gbk -t utf-8 bad.txt > fixed.txt   # 尝试转码
```

### 各语言里的三个易错点

| 语言 | 易错点 | 正确做法 |
| --- | --- | --- |
| Python | 不指定 encoding 会用平台默认 | 显式 `encoding="utf-8"`，读二进制用 `"rb"` |
| JavaScript | 字符串按 UTF-16 存储，`length` 是码元数 | emoji 长度可能为 2，用 `[...str].length` 取真实字符数 |
| Java | `String.length()` 同样是 UTF-16 码元数 | 用 `codePointCount` 统计真实字符 |

```javascript
const emoji = "👨‍👩‍👧";
console.log(emoji.length);          // 8（码元数，含零宽连接符）
console.log([...emoji].length);     // 5（码点数）
// 真实「人类感知的字符」还需要按字素簇切分：
console.log(Array.from(new Intl.Segmenter().segment(emoji)).length);  // 1
```

### BOM 该不该有

```text
UTF-8 BOM = EF BB BF（3 字节）

· Windows 记事本有时会写入 BOM
· 多数解析器能处理，但会污染首行内容（如 JSON 解析失败、CSV 首列名带怪字符）
· 规范建议：UTF-8 不使用 BOM

处理方式
  · 读文件时用 utf-8-sig（Python）或手动跳过 BOM
  · 服务端响应头声明 charset=utf-8，不要依赖 BOM
```

### 自查清单

- [ ] 能说出码点、编码、字形的区别
- [ ] 记得 UTF-8 的四种字节长度与首字节前缀
- [ ] 遇到乱码会先看字节再判断编码
- [ ] 知道 emoji 的 `length` 为什么不是 1
- [ ] 知道 BOM 的作用与为什么要避免它

