import 'localized_text.dart';

/// 沙箱示例库中的一个示例。
class SandboxExample {
  const SandboxExample({
    required this.title,
    required this.code,
    this.stdin = '',
  });

  /// 示例名称（中英双语，界面按当前语言取值）。
  final LocalizedText title;

  final String code;

  /// 可选的标准输入（按行拆分为 stdin）。
  final String stdin;
}

/// 代码沙箱支持的语言与数据格式。
///
/// 每种语言的运行时都作为 JS 资源内置在 APK 中（见 assets/sandbox），
/// 由原生层在 WebView 里离线执行，不联网、不需要后端。
/// 其中 Markdown / 正则 / XML / CSV 是离线可确定执行的格式与 DSL，
/// 用于练习语法与数据转换；Scheme 使用内置的 BiwaScheme 解释器。
enum SandboxLanguage {
  javascript(
    id: 'javascript',
    labelKey: 'sandboxLangJavascript',
    hintKey: 'sandboxHintJavascript',
    timeout: Duration(seconds: 15),
    supportsStdin: true,
    sampleCode: '''
// 计算 1~10 的平方和
const squares = Array.from({ length: 10 }, (_, i) => (i + 1) ** 2);
console.log("平方和 =", squares.reduce((sum, n) => sum + n, 0));
''',
    examples: [
      SandboxExample(
        title: LocalizedText(zh: '平方和', en: 'Sum of squares'),
        code: '''
const squares = Array.from({ length: 10 }, (_, i) => (i + 1) ** 2);
console.log("平方和 =", squares.reduce((sum, n) => sum + n, 0));
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '读取标准输入', en: 'Read stdin'),
        stdin: '小明\n92\n小红\n88',
        code: '''
// stdin 里每行一个值：readLine() 依次读取
const name = readLine();
const score = Number(readLine());
console.log(name + " 的成绩是 " + score);
console.log("下一行：" + readLine());
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '数组去重与排序', en: 'Unique and sort'),
        code: '''
const raw = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3];
const unique = [...new Set(raw)].sort((a, b) => a - b);
console.log("去重排序：", unique.join(", "));
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '对象统计', en: 'Object counting'),
        code: '''
const words = "the quick brown fox jumps over the lazy dog".split(" ");
const counts = {};
for (const word of words) {
  counts[word] = (counts[word] || 0) + 1;
}
console.log(counts);
''',
      ),
    ],
  ),
  typescript(
    id: 'typescript',
    labelKey: 'sandboxLangTypescript',
    hintKey: 'sandboxHintTypescript',
    timeout: Duration(seconds: 20),
    supportsStdin: true,
    sampleCode: '''
interface Student {
  name: string;
  score: number;
}

const students: Student[] = [
  { name: "小明", score: 92 },
  { name: "小红", score: 88 },
];

const total = students.reduce((sum, s) => sum + s.score, 0);
console.log("平均分 =", (total / students.length).toFixed(1));
''',
    examples: [
      SandboxExample(
        title: LocalizedText(zh: '接口与平均分', en: 'Interface and average'),
        code: '''
interface Student {
  name: string;
  score: number;
}
const students: Student[] = [
  { name: "小明", score: 92 },
  { name: "小红", score: 88 },
];
const total = students.reduce((sum, s) => sum + s.score, 0);
console.log("平均分 =", (total / students.length).toFixed(1));
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '枚举与联合类型', en: 'Enum and union'),
        code: '''
type Level = "info" | "warn" | "error";
function log(level: Level, message: string): void {
  console.log("[" + level.toUpperCase() + "] " + message);
}
log("info", "构建完成");
log("error", "构建失败");
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '泛型函数', en: 'Generic function'),
        code: '''
function first<T>(items: T[]): T | undefined {
  return items.length ? items[0] : undefined;
}
console.log(first<number>([3, 1, 4]));
console.log(first<string>(["a", "b"]));
''',
      ),
    ],
  ),
  python(
    id: 'python',
    labelKey: 'sandboxLangPython',
    hintKey: 'sandboxHintPython',
    timeout: Duration(seconds: 30),
    supportsStdin: true,
    sampleCode: '''
# 统计每个单词出现的次数
text = "the quick brown fox jumps over the lazy dog the fox"
counts = {}
for word in text.split():
    counts[word] = counts.get(word, 0) + 1

for word, times in sorted(counts.items(), key=lambda kv: -kv[1])[:3]:
    print(word, times)
''',
    examples: [
      SandboxExample(
        title: LocalizedText(zh: '词频统计', en: 'Word frequency'),
        code: '''
text = "the quick brown fox jumps over the lazy dog the fox"
counts = {}
for word in text.split():
    counts[word] = counts.get(word, 0) + 1
for word, times in sorted(counts.items(), key=lambda kv: -kv[1])[:3]:
    print(word, times)
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '读取标准输入', en: 'Read stdin'),
        stdin: '小明 92\n小红 88\n小刚 75',
        code: '''
# stdin 每行一条记录，使用 input() 读取
total = 0
count = 0
while True:
    try:
        line = input()
    except EOFError:
        break
    if not line.strip():
        continue
    name, score = line.split()
    total += int(score)
    count += 1
print("平均分 =", round(total / count, 1))
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '列表推导与字典', en: 'Comprehension'),
        code: '''
numbers = list(range(1, 11))
squares = [n * n for n in numbers if n % 2 == 0]
pairs = {n: n * n for n in numbers[:5]}
print("偶数平方：", squares)
print("字典：", pairs)
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '类与继承', en: 'Class and inheritance'),
        code: '''
class Animal:
    def __init__(self, name):
        self.name = name

    def speak(self):
        return "..."

class Dog(Animal):
    def speak(self):
        return "汪汪"

for animal in [Animal("动物"), Dog("旺财")]:
    print(animal.name, animal.speak())
''',
      ),
    ],
  ),
  lua(
    id: 'lua',
    labelKey: 'sandboxLangLua',
    hintKey: 'sandboxHintLua',
    timeout: Duration(seconds: 20),
    supportsStdin: true,
    sampleCode: '''
-- 斐波那契数列前 10 项
local a, b = 0, 1
local list = {}
for i = 1, 10 do
  a, b = b, a + b
  table.insert(list, a)
end
print("前 10 项：", table.concat(list, ", "))
''',
    examples: [
      SandboxExample(
        title: LocalizedText(zh: '斐波那契数列', en: 'Fibonacci'),
        code: '''
local a, b = 0, 1
local list = {}
for i = 1, 10 do
  a, b = b, a + b
  table.insert(list, a)
end
print("前 10 项：", table.concat(list, ", "))
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '读取标准输入', en: 'Read stdin'),
        stdin: '小明 92\n小红 88',
        code: '''
-- readLine() 每次读取一行，读完返回 nil
while true do
  local line = readLine()
  if not line then break end
  local name, score = string.match(line, "(%S+)%s+(%d+)")
  if name then
    print(name .. " 的成绩是 " .. score)
  end
end
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '表与函数', en: 'Tables and functions'),
        code: '''
local function map(t, fn)
  local result = {}
  for i, v in ipairs(t) do result[i] = fn(v) end
  return result
end

local doubled = map({1, 2, 3, 4}, function(v) return v * 2 end)
print(table.concat(doubled, ", "))
''',
      ),
    ],
  ),
  sql(
    id: 'sql',
    labelKey: 'sandboxLangSql',
    hintKey: 'sandboxHintSql',
    timeout: Duration(seconds: 30),
    sampleCode: '''
CREATE TABLE score (name TEXT, subject TEXT, score INTEGER);
INSERT INTO score VALUES ('小明', '数学', 92), ('小明', '英语', 85), ('小红', '数学', 78);
SELECT name, SUM(score) AS total FROM score GROUP BY name ORDER BY total DESC;
''',
    examples: [
      SandboxExample(
        title: LocalizedText(zh: '分组统计', en: 'Group by'),
        code: '''
CREATE TABLE score (name TEXT, subject TEXT, score INTEGER);
INSERT INTO score VALUES ('小明', '数学', 92), ('小明', '英语', 85), ('小红', '数学', 78);
SELECT name, SUM(score) AS total FROM score GROUP BY name ORDER BY total DESC;
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '多表连接', en: 'Join'),
        code: '''
CREATE TABLE student (id INTEGER, name TEXT);
CREATE TABLE grade (student_id INTEGER, score INTEGER);
INSERT INTO student VALUES (1, '小明'), (2, '小红'), (3, '小刚');
INSERT INTO grade VALUES (1, 92), (1, 85), (2, 78);
SELECT s.name, AVG(g.score) AS avg_score
FROM student s JOIN grade g ON g.student_id = s.id
GROUP BY s.name ORDER BY avg_score DESC;
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '子查询与条件', en: 'Subquery'),
        code: '''
CREATE TABLE score (name TEXT, score INTEGER);
INSERT INTO score VALUES ('小明', 92), ('小红', 78), ('小刚', 65);
SELECT name, score FROM score WHERE score > (SELECT AVG(score) FROM score);
''',
      ),
    ],
  ),
  json(
    id: 'json',
    labelKey: 'sandboxLangJson',
    hintKey: 'sandboxHintJson',
    timeout: Duration(seconds: 15),
    sampleCode: '''
{
  "course": "Python 基础",
  "lessons": ["变量与类型", "函数", "列表与字典"],
  "done": 2
}
''',
    examples: [
      SandboxExample(
        title: LocalizedText(zh: '课程对象', en: 'Course object'),
        code: '''
{
  "course": "Python 基础",
  "lessons": ["变量与类型", "函数", "列表与字典"],
  "done": 2
}
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '嵌套数组', en: 'Nested arrays'),
        code: '''
{
  "students": [
    { "name": "小明", "scores": [92, 85] },
    { "name": "小红", "scores": [78, 90] }
  ],
  "total": 2
}
''',
      ),
    ],
  ),
  scheme(
    id: 'scheme',
    labelKey: 'sandboxLangScheme',
    hintKey: 'sandboxHintScheme',
    timeout: Duration(seconds: 20),
    supportsStdin: true,
    sampleCode: '''
; 递归计算阶乘
(define (fact n)
  (if (<= n 1)
      1
      (* n (fact (- n 1)))))

(display "5! = ")
(display (fact 5))
(newline)
''',
    examples: [
      SandboxExample(
        title: LocalizedText(zh: '递归阶乘', en: 'Recursive factorial'),
        code: '''
(define (fact n)
  (if (<= n 1)
      1
      (* n (fact (- n 1)))))
(display "5! = ")
(display (fact 5))
(newline)
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: 'map 与 filter', en: 'Map and filter'),
        code: '''
(define numbers (list 1 2 3 4 5 6 7 8 9 10))
(define squares (map (lambda (n) (* n n)) numbers))
(define evens (filter (lambda (n) (= 0 (remainder n 2))) squares))
(display "平方：")
(display squares)
(newline)
(display "其中偶数：")
(display evens)
(newline)
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '读取标准输入', en: 'Read stdin'),
        stdin: '小明 92\n小红 88',
        code: '''
; read-line 每次读取一行，读完返回 #f
(let loop ((line (read-line)))
  (if line
      (begin
        (display "读到：")
        (display line)
        (newline)
        (loop (read-line)))))
''',
      ),
    ],
  ),
  markdown(
    id: 'markdown',
    labelKey: 'sandboxLangMarkdown',
    hintKey: 'sandboxHintMarkdown',
    timeout: Duration(seconds: 15),
    sampleCode: '''
# Markdown 语法练习

用 **粗体**、*斜体* 和 `行内代码` 描述知识点。

## 有序步骤

1. 先理解语法
2. 再写示例
3. 最后做练习

> 小提示：渲染结果会以 HTML 文本返回。

```dart
void main() => print("Hello");
```
''',
    examples: [
      SandboxExample(
        title: LocalizedText(zh: '基础语法', en: 'Basic syntax'),
        code: '''
# Markdown 语法练习

用 **粗体**、*斜体* 和 `行内代码` 描述知识点。

## 有序步骤

1. 先理解语法
2. 再写示例
3. 最后做练习

> 小提示：渲染结果会以 HTML 文本返回。
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '代码块与链接', en: 'Code and links'),
        code: '''
## 代码块

```dart
void main() => print("Hello");
```

## 链接

见 [Dart 官网](https://dart.dev)。
''',
      ),
    ],
  ),
  regex(
    id: 'regex',
    labelKey: 'sandboxLangRegex',
    hintKey: 'sandboxHintRegex',
    timeout: Duration(seconds: 15),
    sampleCode: '''
\\d{4}-\\d{2}-\\d{2}
g
订单 A: 2026-01-05 下单，订单 B: 2026-03-18 发货
''',
    examples: [
      SandboxExample(
        title: LocalizedText(zh: '匹配日期', en: 'Match dates'),
        code: '''
\\d{4}-\\d{2}-\\d{2}
g
订单 A: 2026-01-05 下单，订单 B: 2026-03-18 发货
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '分组提取', en: 'Capture groups'),
        code: '''
(\\w+)@(\\w+)\\.com
g
联系邮箱：xiaoming@example.com，备用：hong@test.com
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '校验手机号', en: 'Validate phone'),
        code: '''
^1[3-9]\\d{9}\$
13812345678
''',
      ),
    ],
  ),
  xml(
    id: 'xml',
    labelKey: 'sandboxLangXml',
    hintKey: 'sandboxHintXml',
    timeout: Duration(seconds: 15),
    sampleCode: '''
<course id="python" level="基础">
  <title>Python 基础语法</title>
  <lesson order="1">变量与类型</lesson>
  <lesson order="2">函数</lesson>
</course>
''',
    examples: [
      SandboxExample(
        title: LocalizedText(zh: '校验并格式化', en: 'Validate and format'),
        code: '''
<course id="python" level="基础">
  <title>Python 基础语法</title>
  <lesson order="1">变量与类型</lesson>
  <lesson order="2">函数</lesson>
</course>
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '属性与注释', en: 'Attributes and comments'),
        code: '''
<!-- 学生名单 -->
<students count="2">
  <student id="1" score="92">小明</student>
  <student id="2" score="88">小红</student>
</students>
''',
      ),
    ],
  ),
  csv(
    id: 'csv',
    labelKey: 'sandboxLangCsv',
    hintKey: 'sandboxHintCsv',
    timeout: Duration(seconds: 15),
    sampleCode: '''
name,subject,score
小明,数学,92
小红,数学,78
小刚,英语,85
''',
    examples: [
      SandboxExample(
        title: LocalizedText(zh: '成绩表', en: 'Score table'),
        code: '''
name,subject,score
小明,数学,92
小红,数学,78
小刚,英语,85
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '引号与逗号', en: 'Quotes and commas'),
        code: '''
title,author,year
"计算机基础, 上册",张三,2024
"编程, 从入门到实践",李四,2025
''',
      ),
    ],
  ),
  cpp(
    id: 'cpp',
    labelKey: 'sandboxLangCpp',
    hintKey: 'sandboxHintCpp',
    timeout: Duration(seconds: 20),
    supportsStdin: true,
    sampleCode: '''
// C / C++ 教学子集：支持变量、数组、函数、递归、指针与 printf / cout
#include <stdio.h>

int main() {
    int n = 5;
    int sum = 0;
    for (int i = 1; i <= n; i++) {
        sum += i;
    }
    printf("1 到 %d 的和 = %d\\n", n, sum);
    return 0;
}
''',
    examples: [
      SandboxExample(
        title: LocalizedText(zh: '求和（读取输入）', en: 'Sum with input'),
        stdin: '3 4',
        code: '''
#include <stdio.h>

int main() {
    int a, b;
    scanf("%d %d", &a, &b);
    printf("%d + %d = %d\\n", a, b, a + b);
    return 0;
}
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '冒泡排序', en: 'Bubble sort'),
        code: '''
#include <iostream>
using namespace std;

int main() {
    int a[6] = {5, 2, 4, 1, 3, 6};
    int n = 6;
    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < n - 1 - i; j++) {
            if (a[j] > a[j + 1]) {
                int t = a[j];
                a[j] = a[j + 1];
                a[j + 1] = t;
            }
        }
    }
    for (int i = 0; i < n; i++) cout << a[i] << " ";
    cout << endl;
    return 0;
}
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '递归与指针', en: 'Recursion and pointers'),
        code: '''
#include <stdio.h>

int fib(int n) {
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
}

void swap(int *a, int *b) {
    int t = *a;
    *a = *b;
    *b = t;
}

int main() {
    printf("fib(10) = %d\\n", fib(10));
    int x = 1, y = 2;
    swap(&x, &y);
    printf("交换后 x=%d y=%d\\n", x, y);
    return 0;
}
''',
      ),
    ],
  ),
  bash(
    id: 'bash',
    labelKey: 'sandboxLangBash',
    hintKey: 'sandboxHintBash',
    timeout: Duration(seconds: 20),
    sampleCode: '''
#!/bin/bash
# 变量、循环与算术运算
total=0
for i in 1 2 3 4 5; do
  total=\$((total + i))
done
echo "1 到 5 的和 = \$total"
''',
    examples: [
      SandboxExample(
        title: LocalizedText(zh: '管道与文本处理', en: 'Pipes and text'),
        code: '''
#!/bin/bash
# 管道把上一条命令的输出交给下一条
echo "banana apple cherry" | tr ' ' '\\n' | sort
printf 'a\\nb\\nc\\n' | wc -l
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '函数与参数', en: 'Functions and arguments'),
        code: '''
#!/bin/bash
greet() {
  echo "你好，\$1！"
}

square() {
  echo \$((\$1 * \$1))
}

greet 学习者
echo "9 的平方是 \$(square 9)"
''',
      ),
      SandboxExample(
        title: LocalizedText(zh: '条件与退出码', en: 'Conditions and exit codes'),
        code: '''
#!/bin/bash
score=86
if [ "\$score" -ge 60 ]; then
  echo "及格：\$score"
else
  echo "不及格：\$score"
fi

cat /tmp/不存在.txt
echo "上一条命令的退出码：\$?"
''',
      ),
    ],
  );

  const SandboxLanguage({
    required this.id,
    required this.labelKey,
    required this.hintKey,
    required this.timeout,
    required this.sampleCode,
    this.supportsStdin = false,
    this.examples = const <SandboxExample>[],
  });

  /// 与原生层约定的语言标识。
  final String id;

  /// 界面上显示的语言名（l10n 键）。
  final String labelKey;

  /// 该语言的用法提示（l10n 键）。
  final String hintKey;

  /// 本地执行超时时间，超时后由原生层销毁 WebView。
  final Duration timeout;

  /// 打开该语言时默认填充的示例代码。
  final String sampleCode;

  /// 是否支持标准输入（stdin）。
  final bool supportsStdin;

  /// 内置示例库（至少包含默认示例）。
  final List<SandboxExample> examples;

  static SandboxLanguage? tryFromId(String? id) {
    if (id == null) return null;
    for (final language in SandboxLanguage.values) {
      if (language.id == id) return language;
    }
    return null;
  }

  /// Markdown 围栏语言别名 -> 沙箱语言。
  ///
  /// 教程里的代码块使用 ```python、```js、```c 这类围栏名，这里统一映射到
  /// 实际可执行的沙箱运行时；没有映射的语言（Java、C#、Go 等）表示当前
  /// 沙箱不支持离线执行，界面需要给出明确提示而不是静默失败。
  static const Map<String, SandboxLanguage> _fenceAliases = {
    'js': SandboxLanguage.javascript,
    'javascript': SandboxLanguage.javascript,
    'mjs': SandboxLanguage.javascript,
    'node': SandboxLanguage.javascript,
    'ts': SandboxLanguage.typescript,
    'typescript': SandboxLanguage.typescript,
    'py': SandboxLanguage.python,
    'python': SandboxLanguage.python,
    'python3': SandboxLanguage.python,
    'lua': SandboxLanguage.lua,
    'sql': SandboxLanguage.sql,
    'sqlite': SandboxLanguage.sql,
    'mysql': SandboxLanguage.sql,
    'json': SandboxLanguage.json,
    'jsonc': SandboxLanguage.json,
    'scheme': SandboxLanguage.scheme,
    'scm': SandboxLanguage.scheme,
    'rkt': SandboxLanguage.scheme,
    'md': SandboxLanguage.markdown,
    'markdown': SandboxLanguage.markdown,
    'regex': SandboxLanguage.regex,
    'regexp': SandboxLanguage.regex,
    'xml': SandboxLanguage.xml,
    'csv': SandboxLanguage.csv,
    'c': SandboxLanguage.cpp,
    'cpp': SandboxLanguage.cpp,
    'c++': SandboxLanguage.cpp,
    'cc': SandboxLanguage.cpp,
    'cxx': SandboxLanguage.cpp,
    'h': SandboxLanguage.cpp,
    'hpp': SandboxLanguage.cpp,
    'sh': SandboxLanguage.bash,
    'bash': SandboxLanguage.bash,
    'shell': SandboxLanguage.bash,
    'zsh': SandboxLanguage.bash,
  };

  /// 按教程代码块的围栏语言名查找可用的沙箱语言。
  ///
  /// 形如 `python title=...` 的围栏信息字符串只取第一个单词。
  static SandboxLanguage? tryFromFence(String? fence) {
    final raw = (fence ?? '').trim().toLowerCase();
    if (raw.isEmpty) return null;
    final token = raw.split(RegExp(r'[\s,{]+')).first;
    return _fenceAliases[token];
  }

  /// 当前沙箱支持的语言名列表，用于「不支持」时的提示文案。
  static String get supportedFenceNames =>
      'Python / JavaScript / TypeScript / C / C++ / Bash / SQL / JSON / Lua / '
      'Scheme / Markdown / 正则 / XML / CSV';

  static SandboxLanguage fromId(String id) =>
      tryFromId(id) ?? SandboxLanguage.javascript;
}
