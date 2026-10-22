## 零基础详解：脚本安全加固

### 一句话说清它是什么

脚本安全要防三件事：**误删自己的数据**、**被别人的文件名/输入攻击**、**泄露密钥**。
三条防线分别是：输入校验、安全调用、密钥外置。

### 用生活比喻理解

| 风险 | 比喻 | 防线 |
| --- | --- | --- |
| 变量为空 | 地址写错，货送到别人家 | 非空校验 + 引号 |
| 文件名含空格 | 名字里有空格被拆成两个人 | 用 NUL 分隔 |
| 临时文件被抢 | 有人提前占了你的柜子 | `mktemp` |
| 密钥进日志 | 密码写在便签上贴上墙 | 环境变量 + 脱敏 |
| 命令注入 | 有人塞了伪造指令 | 避免 `eval`、用数组传参 |

### 三条铁律

```bash
# 铁律一：变量必须非空校验，且一律加引号
: "${TARGET:?拒绝执行：TARGET 未设置}"
rm -rf -- "$TARGET"

# 铁律二：临时文件用 mktemp，别自己拼名字
readonly TMP_FILE="$(mktemp)"
trap 'rm -f -- "$TMP_FILE"' EXIT

# 铁律三：密钥只从环境变量或密钥服务读取，永不写进脚本
: "${API_TOKEN:?缺少 API_TOKEN}"
curl -H "Authorization: Bearer $API_TOKEN" "$URL"
```

### 文件名攻击与安全遍历

```bash
# 危险：文件名含空格或换行会被拆坏
for f in $(find . -name '*.log'); do rm "$f"; done

# 安全一：find 自带执行（推荐）
find . -name '*.log' -exec rm -f -- {} +

# 安全二：NUL 分隔
find . -name '*.log' -print0 | while IFS= read -r -d '' f; do
  rm -f -- "$f"
done

# 安全三：Bash 数组 + globstar
shopt -s nullglob
files=(./logs/**/*.log)
((${#files[@]})) && rm -f -- "${files[@]}"
```

### 命令注入：为什么别用 eval

```bash
# 危险：用户输入直接参与命令构造
name="$1"
eval "echo $name"          # 传入 '; rm -rf /' 就完了

# 安全：用数组传参，避免 shell 再解析一次
args=(--user "$1" --output "$2")
curl "${args[@]}" https://example.com

# 需要执行外部命令时，明确分隔参数
cmd="$1"; shift
"$cmd" "$@"
```

### 权限与最小化

```bash
umask 077                       # 新建文件默认只有自己能读写
chmod 600 "$SECRET_FILE"        # 密钥文件权限收紧
chmod +x script.sh              # 只给需要的执行权限

# 不要用 sudo 跑整段脚本，只给真正需要的命令
sudo systemctl restart myapp
```

### 日志脱敏

```bash
mask() {
  local value="$1"
  if ((${#value} <= 8)); then
    printf '***'
  else
    printf '%s****%s' "${value:0:4}" "${value: -4}"
  fi
}

echo "使用令牌 $(mask "$API_TOKEN") 访问接口"
```

**永远不要打印完整令牌、密码、身份证号、银行卡号。**

### 常见攻击与防护对照

| 攻击 | 触发条件 | 防护 |
| --- | --- | --- |
| 路径穿越 | 拼接用户输入的路径 | 校验不含 `..`，用 `realpath` 比对前缀 |
| 命令注入 | `eval` 或字符串拼命令 | 用数组传参，别 eval |
| 符号链接攻击 | 可预测的临时文件名 | `mktemp` |
| 权限提升 | 脚本被 sudo 执行且使用相对路径 | 用绝对路径，重设 PATH |
| 敏感信息泄露 | 密钥写进脚本或日志 | 环境变量 + 脱敏 |
| 通配符误伤 | `rm -rf $DIR/*` 变量为空 | 引号 + 非空校验 + `--` |

```bash
# 路径穿越防护示例
safe_join() {
  local base="$1" rel="$2"
  local full
  full="$(realpath -m -- "$base/$rel")"
  case "$full" in
    "$base"/*) printf '%s' "$full" ;;
    *) echo "非法路径：$rel" >&2; return 1 ;;
  esac
}
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 变量不加引号 | 空格或空值导致意外 | 一律 `"$var"` |
| 用 `eval` 处理输入 | 命令注入 | 改数组传参 |
| 可预测的临时文件名 | 被抢占或符号链接攻击 | `mktemp` |
| 密钥写进脚本 | 泄露且难以轮换 | 环境变量或密钥服务 |
| 日志打印完整令牌 | 日志泄露 | 脱敏后输出 |
| 用 sudo 跑整脚本 | 权限过大 | 只给需要的那条命令 |
| 用相对路径做特权操作 | PATH 劫持 | 绝对路径 + 重设 PATH |
| 不校验用户路径 | 路径穿越 | `realpath` 加前缀比对 |

### 手把手练习：安全的文件清理脚本

```bash
#!/usr/bin/env bash
set -euo pipefail
umask 077

readonly BASE_DIR="${1:?用法：$0 <待清理目录> [保留天数]}"
readonly KEEP_DAYS="${2:-7}"

# 1. 绝对化并确认在允许范围内
readonly REAL_BASE="$(realpath -m -- "$BASE_DIR")"
if [[ "$REAL_BASE" == "/" || "$REAL_BASE" == "$HOME" ]]; then
  echo "拒绝在 $REAL_BASE 上执行清理" >&2
  exit 1
fi
[[ -d "$REAL_BASE" ]] || { echo "目录不存在：$REAL_BASE" >&2; exit 1; }

# 2. 先列出，再删除，全程使用 -print0
count=0
while IFS= read -r -d '' file; do
  ((count++))
  echo "删除：$file"
  rm -f -- "$file"
done < <(find "$REAL_BASE" -type f -mtime "+$KEEP_DAYS" -print0)

echo "共清理 $count 个文件"
```

### 学完自测

- [ ] 能说出脚本安全的三条铁律。
- [ ] 知道为什么不能用 `eval` 处理用户输入。
- [ ] 能说出安全遍历文件名的三种写法。
- [ ] 知道密钥应该从哪里读取。
- [ ] 能说出路径穿越的防护思路。
