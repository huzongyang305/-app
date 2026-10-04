## 零基础详解：高级文本处理工具箱

### 一句话说清它是什么

除了管道三剑客，Linux 还有一批「专治某类文本问题」的小工具。
认清每个工具的强项，就能用一条管道解决过去要写脚本的活。

### 工具定位表

| 工具 | 专治 | 典型用法 |
| --- | --- | --- |
| `cut` | 按固定分隔符取列 | `cut -d: -f1` |
| `paste` | 把多个文件按行并排 | `paste a.txt b.txt` |
| `tr` | 字符替换与删除 | `tr 'a-z' 'A-Z'` |
| `sort` | 排序与去重 | `sort -u -k2,2n` |
| `uniq` | 相邻去重与计数 | `uniq -c` |
| `comm` | 比较两个已排序文件 | `comm -12 a b` |
| `diff` | 比较内容差异 | `diff -u a b` |
| `wc` | 统计行/词/字符 | `wc -l` |
| `split` | 大文件切分 | `split -l 1000 big.txt part_` |
| `sed` | 流式替换与提取 | `sed -n '10,20p'` |
| `awk` | 按列计算与格式化 | `awk -F, '{sum+=$3} END{print sum}'` |

### 一行一例

```bash
# 取第 1 与第 3 列（以逗号分隔）
cut -d, -f1,3 data.csv

# 大小写转换与删除空行
tr 'a-z' 'A-Z' < input.txt
tr -d '\r' < windows.txt > unix.txt        # 去掉 Windows 换行符

# 按第 2 列数字排序，去重后取前 10
sort -k2,2n data.txt | uniq | head -n 10

# 只保留两个文件共有的行
comm -12 <(sort a.txt) <(sort b.txt)

# 生成带行号的差异补丁
diff -u old.txt new.txt > change.patch

# 统计目录下各扩展名的数量
find . -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn

# 按列求和并格式化输出
awk -F, 'NR>1 {sum += $3; count++} END {printf "共 %d 条，合计 %.2f\n", count, sum}' sales.csv
```

### 正则的三档强度

| 写法 | 支持 | 说明 |
| --- | --- | --- |
| `grep` | 基本正则 | `+`、`?` 要转义 |
| `grep -E` | 扩展正则 | 常用写法，推荐 |
| `grep -P` | Perl 正则 | 支持 `\d`、`\w`、环视 |
| `sed -E` | 扩展正则 | 替换时更易读 |

```bash
grep -E '^(ERROR|WARN)' app.log
grep -P '(?<=user_id=)\d+' app.log        # 环视提取，GNU grep 支持
sed -E 's/([0-9]{4})-([0-9]{2})-([0-9]{2})/\3\/\2\/\1/' dates.txt
```

### awk 的三个必会块

```awk
BEGIN   { FS=","; print "开始统计" }      # 处理前执行一次
        { sum += $3; count++ }             # 每一行执行
END     { printf "平均 %.2f\n", sum / count }   # 处理后执行一次
```

```bash
# 按第一列分组求和
awk -F, '{sum[$1] += $3} END {for (k in sum) print k, sum[k]}' sales.csv

# 只处理匹配的行
awk -F, '$1 == "2026-10" {print $2, $3}' sales.csv

# 过滤掉表头与空行
awk -F, 'NR > 1 && NF > 0' data.csv
```

### 处理大文件的原则

| 原则 | 原因 |
| --- | --- |
| 用流式工具（sed、awk） | 不用把整个文件读进内存 |
| 避免多次遍历 | 一次 awk 能做完就别串五个命令 |
| 善用 `LC_ALL=C` | 按字节比较比按语言环境快很多 |
| 排序大文件加 `-S` | 提高排序使用的内存 |
| 先 `head` 验证管道 | 避免跑完才发现格式错 |

```bash
LC_ALL=C sort -S 2G -T /data/tmp big.txt > sorted.txt
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `cut` 处理多空格分隔 | 取不到正确列 | 改用 `awk '{print $3}'` |
| `uniq` 前不排序 | 结果偏小 | 先 `sort` |
| 在 `sed` 里用 `\d` | 不生效 | 用 `[0-9]` 或 `sed -E` |
| 处理 Windows 换行 | 出现 `\r` 导致匹配失败 | `tr -d '\r'` 或 `dos2unix` |
| 忘记引号包正则 | shell 先把 `*` 展开 | 正则一律加单引号 |
| 大文件用 `sort` 未指定临时目录 | 临时空间不足 | 加 `-T` 指定目录 |
| 直接改源文件 | 出错无法回滚 | 先输出到临时文件再 `mv` |
| 忽略语言环境影响排序 | 结果与预期不同 | 需要字节序时设 `LC_ALL=C` |

### 手把手练习：分析访问日志

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly LOG="${1:-access.log}"

echo "=== 总览 ==="
awk 'END {print "总请求数:", NR}' "$LOG"

echo "=== 状态码分布 ==="
awk '{codes[$9]++} END {for (c in codes) printf "%s %d\n", c, codes[c]}' "$LOG" \
  | sort -k2,2nr

echo "=== 最多访问的 5 个路径 ==="
awk '{paths[$7]++} END {for (p in paths) print paths[p], p}' "$LOG" \
  | sort -rn | head -n 5

echo "=== 传输量前 3 的 IP（按字节）==="
awk '{bytes[$1] += $10} END {for (ip in bytes) print bytes[ip], ip}' "$LOG" \
  | sort -rn | head -n 3

echo "=== 5xx 错误的时间分布（按小时）==="
awk '$9 ~ /^5/ {gsub(/\[/, "", $4); split($4, t, ":"); hours[t[2]]++}
     END {for (h in hours) printf "%s 时: %d\n", h, hours[h]}' "$LOG" | sort
```

### 学完自测

- [ ] 能说出 cut 与 awk 在取列上的取舍。
- [ ] 知道 `grep`、`grep -E`、`grep -P` 的区别。
- [ ] 能说出 awk 的 BEGIN、主体、END 三块执行时机。
- [ ] 知道处理 Windows 换行要先做什么。
- [ ] 能说出大文件处理的两条性能原则。
