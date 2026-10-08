// Shell 入门五课的通俗精讲素材（手写，逐课定制）。
import 'language_intro_detail.dart';

const String _shFirstCode = r'''#!/usr/bin/env bash
set -euo pipefail

echo "你好，Shell"
echo "当前目录：$(pwd)"''';

const String _shVarCode = r'''#!/usr/bin/env bash
set -euo pipefail

name="小明"
age=18

# 用花括号界定变量名边界，避免歧义
echo "${name} 明年 $((age + 1)) 岁"

if [ $# -gt 0 ]; then
  echo "收到的第一个参数：$1"
else
  echo "没有收到参数"
fi''';

const String _shIfCode = r'''#!/usr/bin/env bash
set -euo pipefail

score="${1:-0}"

if [ "$score" -ge 90 ]; then
  echo "优秀"
elif [ "$score" -ge 60 ]; then
  echo "及格"
else
  echo "需要补考"
fi''';

const String _shLoopCode = r'''#!/usr/bin/env bash
set -euo pipefail

total=0

for i in $(seq 1 5); do
  total=$((total + i))
  echo "加入 $i 后累计 $total"
done

while [ "$total" -lt 20 ]; do
  total=$((total + 5))
done

echo "最终结果：$total"''';

const String _shPipeCode = r'''#!/usr/bin/env bash
set -euo pipefail

access_log="access.log"

printf '%s\n' \
  'GET /index.html 200' \
  'POST /login 401' \
  'GET /about 200' \
  'GET /missing 404' > "$access_log"

echo "总请求数：$(wc -l < "$access_log" | tr -d ' ')"
echo "状态码分布："
awk '{print $3}' "$access_log" | sort | uniq -c | sort -rn''';

const List<LanguageIntroDetail> shellIntroDetails = <LanguageIntroDetail>[
  ..._shFirstDetails,
  ..._shVarDetails,
  ..._shIfDetails,
  ..._shLoopDetails,
  ..._shPipeDetails,
];

const List<LanguageIntroDetail> _shFirstDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'shell_first_script',
    sectionTitle: '第一个 Shell 脚本',
    codeLanguage: 'bash',
    oneLiner:
        'Shell 脚本就是一份把终端命令按顺序写下来的文件；'
        '加上 shebang 和 set -euo pipefail 之后，它会按严格的规则逐条执行。',
    analogy:
        '脚本像一张写好的操作清单：你把平时手敲的命令抄下来，'
        '以后交给机器照着做，避免每次重新敲一遍还敲错。',
    code: _shFirstCode,
    lineWalk: r'''
- `#!/usr/bin/env bash` 是 shebang，告诉系统用哪个解释器执行这个文件。
- `set -euo pipefail` 一次性打开三条保护：命令出错就停、引用未定义变量报错、管道中间失败也报错。
- `echo "你好，Shell"` 把文字打印到标准输出并换行。
- `$(pwd)` 是命令替换，先执行括号里的命令，再把输出嵌进字符串。
- 脚本写完后要加执行权限才能直接运行：`chmod +x hello.sh`。
''',
    runThrough: '''
- 运行 `./hello.sh` 或 `bash hello.sh`。
- 解释器从上往下读取每一行。
- 第一行 echo 输出「你好，Shell」。
- 第二行的命令替换先执行 pwd，再输出当前目录。
''',
    pitfalls: '''
- 忘记 shebang：用 bash 显式调用仍能跑，但直接执行时系统不知道该用什么解释器。
- 不加 set -e：中间某条命令失败后脚本会继续往下跑，可能留下半成品状态。
- 变量引用不加引号：路径里有空格时会被拆成多个参数。
- Windows 换行符导致 bad interpreter：脚本要用 LF 换行，不能是 CRLF。
- 以为 sh 就是 bash：在 Ubuntu 上 sh 常指向 dash，特性支持不一样。
''',
    drill: '''
- 把输出文字改成自己的名字并运行。
- 删掉 set -e 那一行，在脚本里插入一条会失败的命令，观察行为差异。
- 用 `bash -x hello.sh` 运行，查看每条命令的执行轨迹。
''',
  ),
];

const List<LanguageIntroDetail> _shVarDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'shell_variables_args',
    sectionTitle: 'Shell 变量与参数',
    codeLanguage: 'bash',
    oneLiner:
        'Shell 变量赋值时不能有空格，引用时加美元符号；'
        r'脚本参数用 $1、$2 取，$# 表示参数个数，全部参数是 @ 符号。',
    analogy:
        '脚本参数像餐厅的取餐号：号码是固定的位置，'
        '1 号窗口永远取第一个参数，不管你给它起的名字是什么。',
    code: _shVarCode,
    lineWalk: r'''
- `name="小明"` 等号两边不能有空格，有空格会被当成命令名解析。
- `age=18` 赋的是字符串，但算术展开时会按整数处理。
- `"${name}"` 用花括号界定变量名边界，避免后面紧跟的字符被当成变量名的一部分。
- `$((age + 1))` 是算术展开，把表达式求值成数字。
- `$#` 是参数个数，`$1` 是第一个参数；参数不足时它的值为空字符串。
- 引用变量时加双引号能防止空格和通配符被再次解释。
''',
    runThrough: '''
- 执行 `./hello.sh` 时不带参数，参数个数是 0，走 else 分支输出「没有收到参数」。
- 执行 `./hello.sh 小明` 时参数个数是 1，走 if 分支输出「收到的第一个参数：小明」。
- 无论哪种情况，前面那行都会先输出「小明 明年 19 岁」。
- 如果引用变量时不加引号，名字里带空格时会被拆成两个词。
''',
    pitfalls: r'''
- 赋值时写 `name = "小明"`：Shell 会把 name 当成命令名，报 command not found。
- 变量不加引号：包含空格或星号时会被拆词或展开成文件名。
- 把 `$name_suffix` 当成两个变量：要用 `${name}_suffix` 明确边界。
- 用单引号包裹变量：单引号内不做变量展开，会原样输出美元符号。
- 忘记 `$@` 和 `$*` 的区别：前者按独立参数展开，后者会合成一个字符串。
''',
    drill: r'''
- 分别用 0 个、1 个、2 个参数运行脚本，观察参数个数和第一个参数的变化。
- 把某个变量引用去掉引号，用带空格的参数复现拆分问题。
- 打印 `$@` 和 `$*`，比较两者的输出差异。
''',
  ),
];

const List<LanguageIntroDetail> _shIfDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'shell_conditions',
    sectionTitle: 'Shell 条件判断',
    codeLanguage: 'bash',
    oneLiner:
        'Shell 用 if 加 test 命令判断条件，方括号就是 test 的另一种写法；'
        '比较字符串和比较数字用的运算符不一样。',
    analogy:
        '方括号像门口的门禁读卡器：你把条件塞进去，它只回你「过」或「不过」。'
        '方括号两边必须有空格，否则读卡器根本读不到你的卡。',
    code: _shIfCode,
    lineWalk: r'''
- `score="${1:-0}"` 取第一个参数，没有传参时用 0 作为默认值。
- `if [ "$score" -ge 90 ]; then` 中 `-ge` 表示大于等于，专门用于数字比较。
- 方括号和里面的内容之间必须有空格，方括号实际上是一个命令。
- `elif` 只在前面的条件不成立时才检查。
- `else` 兜住所有剩余情况，`fi` 表示 if 结构结束。
- 字符串比较要用等号和不等号，判断空值用 `-z`，判断文件用 `-f`、`-d`。
''',
    runThrough: '''
- 执行 `./score.sh 95`：95 大于等于 90，输出「优秀」。
- 执行 `./score.sh 72`：第一个条件不成立，第二个成立，输出「及格」。
- 执行 `./score.sh 40`：两个条件都不成立，输出「需要补考」。
- 不带参数时 score 取默认值 0，同样走 else 分支。
''',
    pitfalls: r'''
- 方括号内不加空格：如果方括号紧贴变量，整段会被当成一个命令名，报 command not found。
- 数字比较用字符串运算符：在方括号里用大于号是重定向，会导致意外建文件。
- 变量不加引号：为空时方括号收到的参数个数不对，报 unary operator expected。
- 在方括号里用逻辑与运算符：POSIX 的 test 不支持，应该写成两个方括号或改用双方括号。
- 忘记 fi：if 结构没有结束标记，解释器会一直读到文件末尾并报错。
''',
    drill: r'''
- 分别用 95、72、40 和不传参数运行脚本，核对四种结果。
- 把 `-ge` 换成 `-gt`，用 90 测试边界差异。
- 故意去掉方括号里的空格，记录报错信息。
''',
  ),
];

const List<LanguageIntroDetail> _shLoopDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'shell_loops',
    sectionTitle: 'Shell 循环',
    codeLanguage: 'bash',
    oneLiner:
        'for 遍历一组值时逐个处理，while 在条件成立时重复；'
        'Shell 的算术要用双圆括号展开，变量引用建议加引号。',
    analogy:
        'for 像把一叠票据按顺序盖章：盖完一张换下一张，清单走完自动结束。'
        'while 像「只要还有票据就继续盖」，什么时候停由条件决定。',
    code: _shLoopCode,
    lineWalk: r'''
- `total=0` 初始化累加器。
- `for i in $(seq 1 5)` 中 seq 生成 1 到 5 的序列，循环逐个取值。
- 算术展开先把括号里的表达式求值，再赋值回 total。
- 循环体里的 echo 每轮执行一次，输出五行。
- `while [ "$total" -lt 20 ]` 每轮开始前判断，`-lt` 表示小于。
- 循环外的 echo 只执行一次。
''',
    runThrough: '''
- for 结束后 total 是 15。
- while 第一轮把 15 加到 20。
- 再次判断 20 不小于 20，循环结束。
- 输出「最终结果：20」。
''',
    pitfalls: r'''
- 算术赋值时等号两边加空格：Shell 会当成命令解析，报 command not found。
- 引用变量不加引号：数值为空时 test 会收到错误数量的参数。
- 用 seq 依赖外部命令：某些精简环境没有 seq，可用大括号展开替代。
- 在管道里用 while 并指望变量保留：管道会创建子 shell，循环里的变量在管道结束后丢失。
- 忘记修改循环变量：while 条件永远为真，脚本卡死。
''',
    drill: '''
- 把 seq 1 5 改成 seq 1 10，先算出总和再运行验证。
- 用大括号展开替换 seq，比较两种写法对环境的依赖。
- 在 for 里加 continue，跳过 i 等于 3 的那一轮。
''',
  ),
];

const List<LanguageIntroDetail> _shPipeDetails = <LanguageIntroDetail>[
  LanguageIntroDetail(
    id: 'shell_pipeline_intro',
    sectionTitle: 'Shell 管道与文本处理',
    codeLanguage: 'bash',
    oneLiner:
        '管道把前一条命令的标准输出直接接到后一条命令的标准输入，'
        '几件小工具串起来就能完成筛选、排序和统计。',
    analogy:
        '管道像流水线上的传送带：每道工序只做一件小事，'
        '上一道做完的零件直接交给下一道，不用先堆到地上再捡起来。',
    code: _shPipeCode,
    lineWalk: '''
- 用 printf 生成一份四行的访问日志，每行三个字段。
- 用输入重定向把文件内容交给 wc，避免把文件名也打进统计结果。
- tr 去掉数字周围的空格，让输出更干净。
- awk 取出每行的第三个字段，也就是状态码。
- sort 排序后再用 uniq -c 统计相邻重复出现的次数。
- 最后再按次数从多到少排列。
''',
    runThrough: '''
- printf 写出四行日志，文件里每行三个字段。
- wc 数出 4 行，tr 去掉空白，输出「总请求数：4」。
- awk 取出 200、401、200、404 四个状态码。
- sort 让相同的 200 相邻，uniq 统计出两个 200，最后按次数倒序输出。
''',
    pitfalls: '''
- 忘记打开 pipefail：管道中间的命令失败时整体仍可能返回 0，错误被吞掉。
- 用 uniq 之前不排序：uniq 只合并相邻的重复行，不排序会得到错误统计。
- 在管道右侧读取变量：管道会创建子 shell，赋值在管道结束后消失。
- 把文件名直接喂给 wc：输出里会附带文件名，脚本解析时多出一列。
- 不加引号的路径含空格：命令会把一个路径拆成两个参数。
''',
    drill: '''
- 把日志文件换成你自己写的一行，观察统计结果变化。
- 用 grep 过滤出错误请求，再用 wc 计数。
- 在管道前加一条会失败的命令，加上和去掉 pipefail 各跑一次，比较退出码。
''',
  ),
];
