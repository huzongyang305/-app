# 结构化数据处理：jq 与 yq

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：50 分钟

![jq 与 yq 处理结构化数据](images/diagram_jq_yq.webp)

![结构化数据处理：jq 与 yq](images/remaining_shell_json_yaml.webp)

## 本节知识框架

**课程定位**：所属分类为「Shell」，课程主题为「结构化数据处理：jq 与 yq」，学习阶段为「进阶」，建议用时 50 分钟。

**本课要解决的主问题**：用 jq 提取过滤聚合、用 yq 读写 YAML 与格式互转。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「结构化数据处理：jq 与 yq」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「结构化数据处理：jq 与 yq」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「jq」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：没有硬性先修课；仍建议先具备本分类的基础阅读与操作能力。

**学习位置**：本课位于《CI 脚本模板库》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《Shell 脚本安全加固》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释结构化数据处理：jq 与 yq解决了什么问题，而不是只背术语。
- 能说清 「jq」、「yq」、「JSON」、「YAML」 之间的关系，并分别举出一个例子。
- 能把 jq 放回「结构化数据处理：jq 与 yq」的知识体系，说明它和 yq 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：用 jq 提取过滤聚合、用 yq 读写 YAML 与格式互转。

**教材衔接：前置知识**

- 先完成上一课《Shell 脚本安全加固》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文里的 validate_payload 示例。
- 开始前先复习：jq、yq、JSON。
- 卡在 jq 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

**教材衔接：本课小结**

- 核心问题：结构化数据处理：jq 与 yq不是孤立术语，而是在「Shell」中解决一类具体问题。
- 关键关系：先分清「jq」与「yq」的职责，再理解「JSON」的适用边界。
- 判断标准：能解释 jq 的正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：把 validate_payload 的实验结论记成三句话，然后进入测验。

## 核心概念定义

> 阅读约定：本课先给「结构化数据处理：jq 与 yq」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| sed | JSON 里可以有转义、嵌套与多行字符串，sed、awk 一旦遇到嵌套结构就会误伤。**解析结构化数据必须用结构化工具**：jq 处理 JSON，yq 处理 YAML（yq 也能读写 JSON）。 | 仅在「结构化数据处理：jq 与 yq」明确给出的输入、版本与资源条件下成立。 |
| JSON | 用对象、数组、字符串和数字等表示结构化数据的文本格式。 | 仅在「结构化数据处理：jq 与 yq」明确给出的输入、版本与资源条件下成立。 |
| jq | 在命令行里过滤、提取和重组 JSON 的工具，配合管道处理接口响应最方便。 | 仅在「结构化数据处理：jq 与 yq」明确给出的输入、版本与资源条件下成立。 |
| YAML 缩进 | YAML 用缩进表达层级，空格数量不一致或混用制表符是最常见的解析失败原因。 | 仅在「结构化数据处理：jq 与 yq」明确给出的输入、版本与资源条件下成立。 |
| Shell | 接收命令并调用操作系统程序的命令行解释器与脚本环境 | 仅在「结构化数据处理：jq 与 yq」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「结构化数据处理：jq 与 yq」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「sed」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「JSON」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「jq」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「结构化数据处理：jq 与 yq」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | sed | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | JSON | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | jq | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「结构化数据处理：jq 与 yq」自己的示例验证。「结构化数据处理：jq 与 yq」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：为什么不要用文本工具处理 JSON**

JSON 里可以有转义、嵌套与多行字符串，`sed`、`awk` 一旦遇到嵌套结构就会误伤。**解析结构化数据必须用结构化工具**：jq 处理 JSON，yq 处理 YAML（yq 也能读写 JSON）。

| 需求 | 工具 |
| --- | --- |
| 提取字段、过滤、改造 | jq |
| 聚合与统计 | jq 的 group_by 与 map |
| YAML 读写 | yq |
| JSON 与 YAML 互转 | `yq -p=json -o=yaml` / `-p=yaml -o=json` |
| 简单键值读取 | `jq -r '.key'` |

**教材衔接：零基础详解：用 jq 与 yq 处理结构化数据**

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

**教材衔接：版本与时效**

- 版本提示：jq 的行为在最近几个大版本里有过调整，升级「结构化数据处理：jq 与 yq」前先用 validate_payload 复现当前输出，再对照官方发布说明逐条核对。
- 升级「结构化数据处理：jq 与 yq」涉及的依赖前，先用 validate_payload 复现当前行为，再逐项核对版本说明与破坏性变更。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改 jq 的版本变量，记录编译、测试与产物体积的变化。
- 回归范围锁定 validate_payload 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级后把 validate_payload 的实测版本写进「内容元数据」，再更新复核日期。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 jq、yq | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「结构化数据处理：jq 与 yq」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「结构化数据处理：jq 与 yq」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:bash`，用于动手验证《结构化数据处理：jq 与 yq》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《结构化数据处理：jq 与 yq》原文中的最小示例。先预测《结构化数据处理：jq 与 yq》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```bash
# 从接口响应里取前 5 个高价值条目，并转成 TSV 便于后续处理
curl -fsSL https://api.example.com/items \
  | jq -r '.items | sort_by(-.price) | .[:5] | .[] | [.id, .name, .price] | @tsv'

# 按类目统计金额与数量
jq -r '
  [.items[]]
  | group_by(.category)
  | map({category: .[0].category, count: length, total: (map(.price) | add)})
  | sort_by(-.total)
  | .[]
  | "\(.category)\t\(.count)\t\(.total)"
' orders.json

# 批量改名与写回：先写临时文件，成功后再替换，避免中途失败损坏原文件
update_config() {
  local file="$1" version="$2" tmp
  tmp=$(mktemp)
  jq --arg v "$version" '.version = $v | .updatedAt = (now | todate)' "$file" > "$tmp" \
    && mv -- "$tmp" "$file"
}

# 用 jq 做参数校验：字段缺失即失败
validate_payload() {
  local file="$1"
  jq -e 'has("userId") and (.items | length > 0)' "$file" >/dev/null \
    || { printf 'payload 不合法\n' >&2; return 1; }
}
```

**教材衔接：jq 速查**

| 需求 | 写法 |
| --- | --- |
| 取字段（去引号） | `jq -r '.name'` |
| 取数组元素 | `jq '.items[0]'`、`jq '.items[-1]'` |
| 遍历数组 | `jq '.items[]'` |
| 过滤 | `jq '.items[] \| select(.price > 100)'` |
| 映射 | `jq '[.items[].name]'` |
| 排序 | `jq '.items \| sort_by(.price)'` |
| 分组统计 | `jq '[.items[]] \| group_by(.category) \| map({key: .[0].category, count: length})'` |
| 求和 | `jq '[.items[].price] \| add'` |
| 合并对象 | `jq '.a * .b'` |
| 构造新对象 | `jq '{id: .id, total: (.price * .qty)}'` |
| 默认值 | `jq '.name // "未知"'` |
| 原始输出与换行 | `jq -r -c`（紧凑输出，便于逐行处理） |

```bash
# 从接口响应里取前 5 个高价值条目，并转成 TSV 便于后续处理
curl -fsSL https://api.example.com/items \
  | jq -r '.items | sort_by(-.price) | .[:5] | .[] | [.id, .name, .price] | @tsv'

# 按类目统计金额与数量
jq -r '
  [.items[]]
  | group_by(.category)
  | map({category: .[0].category, count: length, total: (map(.price) | add)})
  | sort_by(-.total)
  | .[]
  | "\(.category)\t\(.count)\t\(.total)"
' orders.json

# 批量改名与写回：先写临时文件，成功后再替换，避免中途失败损坏原文件
update_config() {
  local file="$1" version="$2" tmp
  tmp=$(mktemp)
  jq --arg v "$version" '.version = $v | .updatedAt = (now | todate)' "$file" > "$tmp" \
    && mv -- "$tmp" "$file"
}

# 用 jq 做参数校验：字段缺失即失败
validate_payload() {
  local file="$1"
  jq -e 'has("userId") and (.items | length > 0)' "$file" >/dev/null \
    || { printf 'payload 不合法\n' >&2; return 1; }
}
```

**教材衔接：yq 速查**

| 需求 | 写法 |
| --- | --- |
| 读取字段 | `yq '.spec.replicas' deploy.yaml` |
| 修改字段 | `yq -i '.spec.replicas = 5' deploy.yaml` |
| 追加数组元素 | `yq -i '.spec.containers += [{"name":"sidecar","image":"busybox"}]'` |
| 删除字段 | `yq -i 'del(.metadata.annotations)'` |
| 多文档处理 | `yq 'select(.kind == "Deployment")'` 或按 `---` 分隔处理 |
| JSON 转 YAML | `yq -p=json -o=yaml '.' config.json` |
| YAML 转 JSON | `yq -p=yaml -o=json '.' deploy.yaml` |

```bash
# 批量给所有 Deployment 加上资源限制（先 dry-run 看 diff）
for file in k8s/*.yaml; do
  yq '.spec.template.spec.containers[] |= (.resources.limits.memory = "512Mi")' "$file" \
    | diff -u "$file" - || true
done

# 确认无误后再原地写入
for file in k8s/*.yaml; do
  yq -i '.spec.template.spec.containers[] |= (.resources.limits.memory = "512Mi")' "$file"
done
```

## 时间/空间复杂度或性能分析

**复杂度证据**：「结构化数据处理：jq 与 yq」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「结构化数据处理：jq 与 yq」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「结构化数据处理：jq 与 yq」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《结构化数据处理：jq 与 yq》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「结构化数据处理：jq 与 yq」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 grep/sed 提取 JSON 字段 | 嵌套或转义时出错 | 用 jq |
| 忘记 `-r` | 输出带引号，后续处理出错 | 需要纯文本时加 `-r` |
| 直接重定向覆盖原文件 | 写失败后原文件损坏 | 写临时文件再 `mv` |
| `jq` 表达式里拼 Shell 变量 | 注入或语法错误 | 用 `--arg` / `--argjson` 传参 |
| 用 `yq -i` 不先看 diff | 误改生产配置 | 先 dry-run 输出 diff |
| 用 `.*` 通配传文件 | 顺序与数量不可控 | 显式列出或用循环 |
| 认为 yq 就是 jq 的别名 | 语法差异导致失败 | 注意 yq 版本（v4 与旧版语法不同） |
| 忽略大文件内存占用 | 处理超大数据卡死 | 用流式模式（如 jq 的 `--stream`） |

**教材衔接：故障现场**

### 现场 1：直接重定向覆盖原文件

**症状**：在《结构化数据处理：jq 与 yq》的复现场景中，写失败后原文件损坏。

**根因**：触发点是把“直接重定向覆盖原文件”当成安全做法。它没有满足《结构化数据处理：jq 与 yq》要求的前提，因此先表现为“写失败后原文件损坏”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《结构化数据处理：jq 与 yq》的问题，写临时文件再 mv。

**验证**：保留《结构化数据处理：jq 与 yq》里触发“写失败后原文件损坏”的输入、版本和日志，按“写临时文件再 mv”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 2：jq 表达式里拼 Shell 变量

**症状**：在《结构化数据处理：jq 与 yq》的复现场景中，注入或语法错误。

**根因**：当出现“jq 表达式里拼 Shell 变量”时，执行路径已经绕过了《结构化数据处理：jq 与 yq》的关键约束，最终以“注入或语法错误”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《结构化数据处理：jq 与 yq》的问题，用 --arg / --argjson 传参。

**验证**：保留《结构化数据处理：jq 与 yq》里触发“注入或语法错误”的输入、版本和日志，按“用 --arg / --argjson 传参”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：用 yq -i 不先看 diff

**症状**：在《结构化数据处理：jq 与 yq》的复现场景中，误改生产配置。

**根因**：触发点是把“用 yq -i 不先看 diff”当成安全做法。它没有满足《结构化数据处理：jq 与 yq》要求的前提，因此先表现为“误改生产配置”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《结构化数据处理：jq 与 yq》的问题，先 dry-run 输出 diff。

**验证**：保留《结构化数据处理：jq 与 yq》里触发“误改生产配置”的输入、版本和日志，按“先 dry-run 输出 diff”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 关联 | 《实战：Shell 零停机部署脚本》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 关联 | 《序列化格式：JSON、YAML、Protobuf 横向对照》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《CI 脚本模板库》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《Shell 脚本安全加固》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「结构化数据处理：jq 与 yq」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《结构化数据处理：jq 与 yq》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

处理 JSON 时为什么不要用 grep 或 sed？

A. 因为它们速度慢
B. 它们不理解嵌套结构与转义，容易误匹配
C. 因为它们不支持中文
D. 因为 JSON 必须用 Python 解析

**参考答案**：它们不理解嵌套结构与转义，容易误匹配

**解析**：在「结构化数据处理：jq 与 yq」里，它们不理解嵌套结构与转义，容易误匹配。JSON 是树形结构且有转义规则，只有结构化解析器才能正确处理。把“它们不理解嵌套结构与转义，容易误匹配”代回「结构化数据处理：jq 与 yq」里“处理 JSON 时为什么不要用 grep 或 sed”的例子核对，条件一旦改变，结论就要用jq、yq、JSON重新推导。

### 自测 2

围绕“结构化数据处理：jq 与 yq”中的 jq、yq、JSON，下列哪两项是本课强调的实践判断？

A. 只要 jq 的常规示例通过，就可以跳过边界与异常路径
B. 验证 yq 时要固定版本并覆盖边界输入，结论才可复现
C. 把 yq 的单次运行结果当成所有版本和规模都成立
D. 学习 jq 时要同时说明输入、输出和失败路径，不能只看正常流程

**参考答案**：验证 yq 时要固定版本并覆盖边界输入，结论才可复现；学习 jq 时要同时说明输入、输出和失败路径，不能只看正常流程

**解析**：本课把结构化数据处理：jq 与 yq拆成概念、示例与故障现场三部分，因此判断 jq 时必须同时交代输入、输出和失败路径，这使“学习 jq 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在结构化数据处理：jq 与 yq里，判断 yq 时要固定版本与边界输入，所以“验证 yq 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 3

阅读「结构化数据处理：jq 与 yq」中的这段 Shell 代码，下面哪项判断最准确？

```shell
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

A. 用 jq 提取过滤聚合、用 yq 读写 YAML 与格式互转。
B. jq、yq、JSON 的结论只取决于关键字数量，与代码的控制流和边界条件无关。
C. 这段 Shell 代码可以跳过错误处理，因为运行成功后就不会再出现异常。
D. 它说明 jq、yq、JSON 只需要记忆结论，不需要记录版本、输入与运行结果。

**参考答案**：用 jq 提取过滤聚合、用 yq 读写 YAML 与格式互转。

**解析**：在「结构化数据处理：jq 与 yq」里，这段 Shell 代码来自本课的本地示例，主要用来核对 jq、yq、JSON、YAML 之间的输入、处理和输出关系，用 jq 提取过滤聚合、用 yq 读写 YAML 与格式互转。在「结构化数据处理：jq 与 yq」里判断这道题，要把jq、yq、JSON的条件、过程与失败路径逐项对齐，换成“阅读结构化数据处理”这个场景，只有满足前提的结论才成立。

**教材衔接：复习与自测**

- [ ] 提取与过滤 JSON 一律使用 jq，不用文本工具。
- [ ] 会用 `--arg` 传参，避免拼接表达式。
- [ ] 修改配置文件先 dry-run 看 diff，再原地写入。
- [ ] 知道 jq 与 yq 的基本语法的差异与版本影响。
- [ ] 需要纯文本输出时使用 `-r`。

**教材衔接：动手练习**

> 本课练习重点：围绕「jq、yq、JSON」完成复述、实验和交付，每个结果都要能被别人检查。

先加严格模式，再在临时目录验证成功与失败路径，最后补回滚。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 结构化数据处理：jq 与 yq解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「yq」是什么关系？

验收标准：说明 jq 与 yq 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：围绕「为什么不要用文本工具处理 JSON」小节做一次五步记录，原例取自 validate_payload，改动只允许动一处jq，原因要能指回正文的判断依据。

### 练习 3：交付一个小结果（30 分钟）

写一个只做一件事的小程序：输入 jq，输出 yq，其余全部省略。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「jq」和「yq」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

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

### 任务 2：只改一个条件

把「结构化数据处理：jq 与 yq」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 yq 换成边界值，其他输入保持原样。
- 预测：先写下「结构化数据处理：jq 与 yq」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响jq。

### 任务 3：迁移到自己的数据

换一个 yq 场景重做一次，确认结论不是只对示例数据成立。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「处理 JSON 时为什么不要用 grep 或 sed？」的判断依据。
- [ ] 不看解析，能说出「jq 输出带引号的字符串，想去掉引号应该加？」的判断依据。
- [ ] 不看解析，能说出「在 jq 表达式里使用 Shell 变量，推荐做法是？」的判断依据。
- [ ] 不看解析，能说出「用 yq/jq 原地修改配置文件前，推荐先做什么？」的判断依据。
- [ ] 不看解析，能说出「要把 JSON 转成 YAML，正确的思路是？」的判断依据。
- [ ] 用 jq 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
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
| `sed` | JSON 里可以有转义、嵌套与多行字符串，`sed`、`awk` 一旦遇到嵌套结构就会误伤。**解析结构化数据必须用结构化工具**：jq 处理 JSON，yq 处理 YAML（yq 也能读写 JSON）。 |
| `JSON` | 用对象、数组、字符串和数字等表示结构化数据的文本格式。 |
| `jq` | 在命令行里过滤、提取和重组 JSON 的工具，配合管道处理接口响应最方便。 |
| `YAML 缩进` | YAML 用缩进表达层级，空格数量不一致或混用制表符是最常见的解析失败原因。 |
| `Shell` | 接收命令并调用操作系统程序的命令行解释器与脚本环境 |

## 考点精讲

### 考点 1：概念判断·jq

- **题目**：处理 JSON 时为什么不要用 grep 或 sed？
- **判断依据**：在「结构化数据处理：jq 与 yq」里，它们不理解嵌套结构与转义，容易误匹配。JSON 是树形结构且有转义规则，只有结构化解析器才能正确处理。把“它们不理解嵌套结构与转义，容易误匹配”代回「结构化数据处理：jq 与 yq」里“处理 JSON 时为什么不要用 grep 或 sed”的例子核对，条件一旦改变，结论就要用jq、yq、JSON重新推导。

### 考点 2：多选辨析·jq

- **题目**：围绕“结构化数据处理：jq 与 yq”中的 jq、yq、JSON，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把结构化数据处理：jq 与 yq拆成概念、示例与故障现场三部分，因此判断 jq 时必须同时交代输入、输出和失败路径，这使“学习 jq 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在结构化数据处理：jq 与 yq里，判断 yq 时要固定版本与边界输入，所以“验证 yq 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 3：代码补全·jq

- **题目**：阅读「结构化数据处理：jq 与 yq」中的这段 Shell 代码，下面哪项判断最准确？
- **判断依据**：在「结构化数据处理：jq 与 yq」里，这段 Shell 代码来自本课的本地示例，主要用来核对 jq、yq、JSON、YAML 之间的输入、处理和输出关系，用 jq 提取过滤聚合、用 yq 读写 YAML 与格式互转。在「结构化数据处理：jq 与 yq」里判断这道题，要把jq、yq、JSON的条件、过程与失败路径逐项对齐，换成“阅读结构化数据处理”这个场景，只有满足前提的结论才成立。

### 考点 4：概念判断·jq

- **题目**：用 yq/jq 原地修改配置文件前，推荐先做什么？
- **判断依据**：在「结构化数据处理：jq 与 yq」里，结论应落在「先输出到临时文件比对 diff」。先看 diff 能避免误改生产配置，写临时文件再替换可防止中途失败损坏原文件。在「结构化数据处理：jq 与 yq」里，这道题要求区分概念与边界，「先输出到临时文件比对 diff」只有在题干给出的前提下才成立，而「备份到内存里」、「关闭文件权限」缺少同一组条件。

### 考点 5：概念判断·jq

- **题目**：要把 JSON 转成 YAML，正确的思路是？
- **判断依据**：在「结构化数据处理：jq 与 yq」里，用 yq 指定输入输出格式（-p=json -o=yaml）。格式转换必须由结构化工具完成，才能正确处理嵌套、多行字符串与转义。把“用 yq 指定输入输出格式（-p=jso”代回「结构化数据处理：jq 与 yq」里“要把 JSON 转成 YAML”的例子核对，条件一旦改变，结论就要用jq、yq、JSON重新推导。

### 考点 6：填空·jq

- **题目**：补全代码：「结构化数据处理：jq 与 yq」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `yq '.spec.template.spec.____[] |= (.resources.limits.memory = "512Mi")' "$file" \`
- **判断依据**：在「结构化数据处理：jq 与 yq」里，containers。「结构化数据处理：jq 与 yq」要求先交代jq、yq、JSON的前提再下结论，所以“containers”只在题干“结构化数据处理”给定的条件下成立。把“containers”代回「结构化数据处理：jq 与 yq」里“结构化数据处理”的例子核对，条件一旦改变，结论就要用jq、yq、JSON重新推导。

## English Overview

**Title:** jq & yq

**Summary:** Extract, filter and aggregate with jq; read and write YAML with yq.

**Category:** Shell
**Level:** 进阶
**Key terms:** jq, yq, JSON, YAML, 结构化数据, 配置修改

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Bash 5 / POSIX Shell
；本课聚焦 jq。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：jq、yq、JSON、YAML、结构化数据、配置修改
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [jq 手册](https://jqlang.org/manual/) | JSON 查询与转换 |
| [GNU Bash 手册](https://www.gnu.org/software/bash/manual/) | Bash 语法、展开与作业控制 |
| [GNU Coreutils](https://www.gnu.org/software/coreutils/manual/) | 文件、文本与进程工具 |

> 「结构化数据处理：jq 与 yq」的链接用于离线阅读后的延伸核对；App 不会自动联网。
