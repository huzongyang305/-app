## 零基础详解：用 jq 与 yq 处理结构化数据

### 一句话说清它是什么

Shell 处理 JSON 和 YAML 的正确方式是**用结构化工具**：`jq` 管 JSON，`yq` 管 YAML。
用 `sed`、`awk` 去改 JSON 是事故高发区——嵌套、转义、多行字符串都会出错。

### 用生活比喻理解

| 工具 | 比喻 | 说明 |
| --- | --- | --- |
| `jq` | JSON 查询语言 | 取值、过滤、重组、统计 |
| `yq` | YAML 版 jq | 读写 YAML，也能转格式 |
| 管道 | 流水线 | 把查询结果继续加工 |
| `-r` | 去掉引号 | 输出纯文本便于 shell 使用 |

### jq 的六种基本操作

```bash
# 0. 先格式化，看清结构
jq . config.json

# 1. 取字段
jq '.name' config.json              # 带引号
jq -r '.name' config.json           # 去引号，适合赋值给变量

# 2. 取嵌套与数组
jq -r '.database.host' config.json
jq -r '.servers[0].ip' config.json
jq -r '.servers[].ip' config.json   # 遍历数组

# 3. 过滤
jq '.items[] | select(.price > 100)' orders.json
jq '[.items[] | select(.stock == 0)] | length' inventory.json

# 4. 构造新对象
jq '{name: .user.name, total: (.items | length)}' order.json

# 5. 统计
jq '[.items[].price] | add' orders.json
jq '.items | group_by(.category) | map({key: .[0].category, count: length})' orders.json

# 6. 修改（写回用临时文件，别直接覆盖）
jq '.version = "2.0"' config.json > config.new && mv config.new config.json
```

### 实用组合：把 JSON 变成 shell 变量

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly CONFIG="config.json"

host=$(jq -r '.database.host' "$CONFIG")
port=$(jq -r '.database.port' "$CONFIG")
[[ "$host" != "null" ]] || { echo "缺少 database.host" >&2; exit 1; }

echo "连接 $host:$port"

# 逐行读取数组
while IFS= read -r ip; do
  echo "检查 $ip"
done < <(jq -r '.servers[].ip' "$CONFIG")
```

**要点**：取值用 `-r`；`null` 必须显式判断，否则会得到字符串 `"null"`。

### yq 常用操作

```bash
# 读取
yq '.services.web.image' docker-compose.yml
yq '.services | keys' docker-compose.yml

# 修改（-i 原地写入）
yq -i '.services.web.image = "myapp:v2"' docker-compose.yml

# 追加元素
yq -i '.services.web.ports += ["8080:80"]' docker-compose.yml

# 格式转换：JSON 与 YAML 互转
yq -p json -o yaml < config.json > config.yaml
yq -p yaml -o json < config.yaml > config.json
```

### 安全写回的三步法

```bash
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

jq '.version = "2.0"' config.json > "$tmp"
jq empty "$tmp"                 # 校验结果是合法 JSON
mv -- "$tmp" config.json        # 原子替换
```

直接 `jq ... config.json > config.json` 会把文件清空，因为重定向先发生。

### 两个容易忽略的细节

| 问题 | 说明 |
| --- | --- |
| 转义与多行 | JSON 字符串里的换行需要正确转义，`sed` 处理不了 |
| 大数字精度 | jq 默认用双精度浮点，超大整数要注意精度损失 |

```bash
# 处理超大整数时可考虑保留为字符串
jq -r '.bigId | tostring' data.json
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `sed` 改 JSON | 结构被破坏 | 用 `jq` |
| 忘了 `-r` | 变量里多出引号 | 取值加 `-r` |
| 不判断 `null` | 把 "null" 当有效值 | 显式判断 |
| 直接重定向覆盖源文件 | 文件被清空 | 写临时文件再 `mv` |
| `jq` 表达式引号用错 | shell 先展开变量 | 表达式用单引号 |
| 用 `awk` 解析 YAML | 缩进与多行处理不了 | 用 `yq` |
| 未校验写回结果 | 写坏了才发现 | `jq empty` 校验 |
| 忽略工具是否存在 | 报 command not found | 开头检查 `command -v jq` |

### 手把手练习：批量读取并汇总配置

```bash
#!/usr/bin/env bash
set -euo pipefail

for tool in jq yq; do
  command -v "$tool" >/dev/null || { echo "缺少 $tool" >&2; exit 1; }
done

readonly DIR="${1:?用法：$0 <配置目录>}"
readonly REPORT="report.json"

total=0
{
  echo "["
  first=1
  for file in "$DIR"/*.yaml; do
    [[ -f "$file" ]] || continue
    name=$(yq -r '.name // "未命名"' "$file")
    replicas=$(yq -r '.replicas // 1' "$file")
    total=$((total + replicas))

    ((first)) || echo ","
    first=0
    jq -n --arg n "$name" --arg f "$file" --argjson r "$replicas" \
      '{name: $n, file: $f, replicas: $r}'
  done
  echo "]"
} > "$REPORT"

jq empty "$REPORT"                       # 校验结果合法
echo "共 $(( $(jq 'length' "$REPORT") )) 个配置，副本总数 $total"
```

### 学完自测

- [ ] 能说出为什么不该用 sed 改 JSON。
- [ ] 知道取值时为什么要加 `-r`。
- [ ] 能写出「按条件过滤并统计数量」的 jq 表达式。
- [ ] 知道安全写回的三步是什么。
- [ ] 能用 yq 完成 JSON 与 YAML 互转。
