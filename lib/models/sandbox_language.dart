/// 代码沙箱支持的语言。
///
/// 每种语言的运行时都作为 JS 资源内置在 APK 中（见 assets/sandbox），
/// 由原生层在 WebView 里离线执行，不联网、不需要后端。
enum SandboxLanguage {
  javascript(
    id: 'javascript',
    labelKey: 'sandboxLangJavascript',
    hintKey: 'sandboxHintJavascript',
    timeout: Duration(seconds: 15),
    sampleCode: '''
// 计算 1~10 的平方和
const squares = Array.from({ length: 10 }, (_, i) => (i + 1) ** 2);
console.log("平方和 =", squares.reduce((sum, n) => sum + n, 0));
''',
  ),
  typescript(
    id: 'typescript',
    labelKey: 'sandboxLangTypescript',
    hintKey: 'sandboxHintTypescript',
    timeout: Duration(seconds: 20),
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
  ),
  python(
    id: 'python',
    labelKey: 'sandboxLangPython',
    hintKey: 'sandboxHintPython',
    timeout: Duration(seconds: 30),
    sampleCode: '''
# 统计每个单词出现的次数
text = "the quick brown fox jumps over the lazy dog the fox"
counts = {}
for word in text.split():
    counts[word] = counts.get(word, 0) + 1

for word, times in sorted(counts.items(), key=lambda kv: -kv[1])[:3]:
    print(word, times)
''',
  ),
  lua(
    id: 'lua',
    labelKey: 'sandboxLangLua',
    hintKey: 'sandboxHintLua',
    timeout: Duration(seconds: 20),
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
  );

  const SandboxLanguage({
    required this.id,
    required this.labelKey,
    required this.hintKey,
    required this.timeout,
    required this.sampleCode,
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

  static SandboxLanguage? tryFromId(String? id) {
    if (id == null) return null;
    for (final language in SandboxLanguage.values) {
      if (language.id == id) return language;
    }
    return null;
  }

  static SandboxLanguage fromId(String id) =>
      tryFromId(id) ?? SandboxLanguage.javascript;
}
