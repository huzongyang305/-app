## 零基础详解：管道与文本处理三剑客

### 一句话说清它是什么

Linux 的哲学是「**每个工具只做一件小事，用管道把它们串起来**」。
文本处理最常用的三件是：`grep` 找行、`sed` 改行、`awk` 按列统计。

### 用生活比喻理解

| 工具 | 比喻 | 一句话 |
| --- | --- | --- |
| `grep` | 筛子 | 按条件挑出需要的行 |
| `sed` | 修改器 | 对匹配到的内容做替换删除 |
| `awk` | 计算器 | 按列取值、求和、分组 |
| `sort` | 排序台 | 排序，是 `uniq` 的前置步骤 |
| `uniq` | 合并器 | 只合并**相邻**重复行 |
| `xargs` | 传送带 | 把输入变成命令行参数 |
| `tee` | 三通阀 | 一路写文件，一路继续往下传 |

### 一条日志分析流水线

```bash
# 找出错误最多的 5 个接口
grep '"level":"error"' app.log \
  | awk -F'"path":"' '{split($2, a, "\""); print a[1]}' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -n 5
```

拆开看每一步：

| 步骤 | 作用 |
| --- | --- |
| `grep` | 只保留含错误的行 |
| `awk -F` | 按分隔符切列，取出接口路径 |
| `sort` | 排序，让相同项相邻 |
| `uniq -c` | 统计每项出现次数 |
| `sort -rn` | 按数字倒序 |
| `head -n 5` | 取前 5 条 |

### 三个工具的常用写法

```bash
# grep：找内容
grep -rn "TODO" src/              # 递归搜索并显示行号
grep -i -w "error" app.log        # 忽略大小写、整词匹配
grep -v "^#" config.conf          # 排除注释行
grep -c "ERROR" app.log           # 只输出匹配行数

# sed：改内容
sed 's/old/new/' file             # 每行替换第一处
sed 's/old/new/g' file            # 每行替换全部
sed -i.bak 's/old/new/g' file     # 原地修改并留备份
sed -n '10,20p' file              # 只打印第 10~20 行

# awk：算内容
awk '{print $1, $3}' file         # 打印第 1、3 列
awk -F: '{print $1}' /etc/passwd  # 指定分隔符
awk '{sum += $2} END {print sum}' nums.txt
awk '$3 > 100 {print $1}' data.txt   # 条件筛选
```

### 安全处理文件名

```bash
# 错误：文件名含空格会被拆坏
find . -name "*.log" | xargs rm

# 正确：用 NUL 分隔
find . -name "*.log" -print0 | xargs -0 rm

# 更直接：find 自带执行（推荐）
find . -name "*.log" -exec rm {} +
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| `uniq` 前不排序 | 统计结果偏小 | 先 `sort` |
| 数字排序不加 `-n` | 10 排在 2 前面 | `sort -n` 或 `sort -rn` |
| 用 `xargs` 处理文件名 | 空格和换行导致误删 | 配 `-print0` 与 `-0` |
| `sed -i` 不带备份 | 改坏了没法还原 | `-i.bak` 或先输出验证 |
| 管道中间失败被忽略 | 错误静默通过 | 加 `set -o pipefail` |
| 以为 `grep` 支持正则全语法 | `\d`、`+` 不生效 | 用 `grep -E` 或 Perl 正则 `-P` |
| 在管道里拼接大文件 | 内存或速度问题 | 用 `awk` 一次遍历 |
| 输出直接覆盖源文件 | 文件被清空 | 写入临时文件后再 `mv` |

### 手把手练习：统计访问量前五的 IP

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly LOG="${1:-access.log}"

if [[ ! -f "$LOG" ]]; then
  echo "日志文件不存在：$LOG" >&2
  exit 1
fi

echo "总请求数：$(wc -l < "$LOG")"
echo "状态码分布："
awk '{print $9}' "$LOG" | sort | uniq -c | sort -rn | head -n 5
echo "访问量前五的 IP："
awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -n 5
```

### 学完自测

- [ ] 能说出 `grep`、`sed`、`awk` 各自最擅长的场景。
- [ ] 知道为什么 `uniq -c` 前必须先 `sort`。
- [ ] 能说出安全处理文件名的两种写法。
- [ ] 知道 `set -o pipefail` 解决什么问题。
- [ ] 能写出「统计出现次数并取前 N」的完整管道。
