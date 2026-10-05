import 'dart:math';

import '../models/lesson.dart';

/// 代码练习工厂：为编程语言课程动态生成可判分的代码输出、排错与场景题。
///
/// 题目不写入 manifest，而是在读取课程时按课程 ID 稳定生成，因此：
/// · 不增加 APK 中的 JSON 体积；
/// · 同一门课每次生成完全相同的题目与答案顺序；
/// · 题库升级只需要更新本文件，老课程也能立即获得新练习。
class PracticeQuestionFactory {
  const PracticeQuestionFactory._();

  /// 支持代码练习的分类。HTML/CSS、数据库等分类使用原有题库。
  static const Set<String> supportedCategoryIds = <String>{
    'python',
    'c',
    'cpp',
    'java',
    'javascript',
    'typescript',
    'csharp',
    'go',
    'rust',
    'kotlin',
    'swift',
    'shell',
  };

  static final Map<String, List<QuizQuestion>> _cache =
      <String, List<QuizQuestion>>{};

  static bool supports(Lesson lesson) =>
      supportedCategoryIds.contains(lesson.categoryId);

  static bool supportsCategoryId(String categoryId) =>
      supportedCategoryIds.contains(categoryId);

  /// 返回课程的完整练习列表：内置题在前，动态代码练习在后。
  static List<QuizQuestion> questionsFor(Lesson lesson) {
    final cached = _cache[lesson.id];
    if (cached != null) return cached;
    final spec = _specs[lesson.categoryId];
    if (spec == null) return const <QuizQuestion>[];

    final seed = _stableHash(lesson.id);
    final x = 3 + (seed % 6);
    final n = 4 + ((seed ~/ 7) % 3);
    final sum = n * (n + 1) ~/ 2;
    final wrongSum = n * (n - 1) ~/ 2;
    final doubled = n * 2;
    final values = <String, String>{'x': '$x', 'n': '$n', 'n1': '${n + 1}'};

    String render(String template) => template.replaceAllMapped(
      RegExp(r'\{(\w+)\}'),
      (match) => values[match.group(1)] ?? match.group(0)!,
    );

    final title = lesson.title.zh;
    final keyword = lesson.keywords.isNotEmpty ? lesson.keywords.first : title;
    final questions = <QuizQuestion>[
      _codeOutput(
        lesson: lesson,
        spec: spec,
        code: render(spec.variable),
        correct: '$x',
        seed: seed,
        variant: 0,
      ),
      _codeOutput(
        lesson: lesson,
        spec: spec,
        code: render(spec.loop),
        correct: '$sum',
        seed: seed,
        variant: 1,
      ),
      _codeOutput(
        lesson: lesson,
        spec: spec,
        code: render(spec.function),
        correct: '$doubled',
        seed: seed,
        variant: 2,
      ),
      _debugSyntax(
        lesson: lesson,
        spec: spec,
        code: render(spec.syntaxError),
        fix: render(spec.syntaxFix),
        seed: seed,
      ),
      _debugOffByOne(
        lesson: lesson,
        spec: spec,
        code: render(spec.offByOne),
        fix: render(spec.offByOneFix),
        wrongSum: '$wrongSum',
        correctSum: '$sum',
        seed: seed,
      ),
      _scenario(
        lesson: lesson,
        spec: spec,
        title: title,
        keyword: keyword,
        seed: seed,
      ),
    ];
    _cache[lesson.id] = questions;
    return questions;
  }

  static QuizQuestion _codeOutput({
    required Lesson lesson,
    required _LangSpec spec,
    required String code,
    required String correct,
    required int seed,
    required int variant,
  }) {
    final title = lesson.title.zh;
    final label = _languageLabel(spec.language);
    final flavor = _flavor(seed + variant);
    final numeric = int.tryParse(correct);
    final wrongs = numeric == null
        ? <String>['0', '1', '2']
        : <String>['${numeric + 1}', '${numeric - 1}', '${numeric * 2}'];
    final options = _optionSet(correct, wrongs, seed + variant);
    final explanation = _joinExplanation(<String>[
      '在 $label 课程“$title”的$flavor代码实验里，程序先完成赋值、循环或函数调用，再把结果写到标准输出，因此正确结果是 $correct。',
      '判断 $label 课程“$title”的代码输出时，要把“源码写了什么”和“运行时实际打印什么”分开；变量值和循环边界都会直接改变最终结果。',
      '把 $correct 当作基线后，可以只改一个输入或一个边界，再观察 $label 课程“$title”的输出如何变化，这就是验证掌握程度的方法。',
    ]);
    return QuizQuestion(
      question: '在 $label 课程“$title”的$flavor实验里，这段代码运行后输出什么？',
      options: options,
      answerIndex: options.indexOf(correct),
      explanation: explanation,
      type: 'code',
      code: code,
      language: spec.language,
      expectedOutput: correct,
    );
  }

  static QuizQuestion _debugSyntax({
    required Lesson lesson,
    required _LangSpec spec,
    required String code,
    required String fix,
    required int seed,
  }) {
    final title = lesson.title.zh;
    final label = _languageLabel(spec.language);
    final wrongs = <String>[
      '把变量名改成另一个单词即可',
      '重新安装运行时并清空所有缓存',
      '把输出语句整段删除，代码就会自动修复',
    ];
    final options = _optionSet(fix, wrongs, seed + 11);
    final explanation = _joinExplanation(<String>[
      '$label 课程“$title”里的这段代码无法通过编译或解析，关键原因是缺少了必要语法结构，正确修复是$fix。',
      '在 $label 课程“$title”中，错误信息通常会指出出错行和期望符号；先读第一条错误，再检查这一行的括号、冒号、分号或花括号。',
      '修复后还要重新运行 $label 课程“$title”的最小示例，确认输出恢复，并记录这次问题属于语法错误而不是逻辑错误。',
    ]);
    return QuizQuestion(
      question: '$label 课程“$title”的下面这段代码无法运行，最可能的修复是什么？',
      options: options,
      answerIndex: options.indexOf(fix),
      explanation: explanation,
      type: 'debug',
      code: code,
      language: spec.language,
    );
  }

  static QuizQuestion _debugOffByOne({
    required Lesson lesson,
    required _LangSpec spec,
    required String code,
    required String fix,
    required String wrongSum,
    required String correctSum,
    required int seed,
  }) {
    final title = lesson.title.zh;
    final label = _languageLabel(spec.language);
    final wrongs = <String>[
      '把循环变量从 1 改成 0，其余保持不变',
      '把输出语句移到循环体内部',
      '把累加操作改成减法操作',
    ];
    final options = _optionSet(fix, wrongs, seed + 17);
    final explanation = _joinExplanation(<String>[
      '$label 课程“$title”里的循环边界少算了最后一项，当前输出是 $wrongSum，而完整求和应为 $correctSum。',
      '正确修复是$fix；这类错误属于边界问题，代码能运行但结果偏离，所以比语法错误更隐蔽。',
      '验证 $label 课程“$title”时至少选择首项、中间值和末尾值三个输入，比较手算结果与程序输出，才能发现类似偏差。',
    ]);
    return QuizQuestion(
      question: '$label 课程“$title”的这段代码结果偏小，应该怎样修改？',
      options: options,
      answerIndex: options.indexOf(fix),
      explanation: explanation,
      type: 'debug',
      code: code,
      language: spec.language,
      expectedOutput: correctSum,
    );
  }

  static QuizQuestion _scenario({
    required Lesson lesson,
    required _LangSpec spec,
    required String title,
    required String keyword,
    required int seed,
  }) {
    final label = _languageLabel(spec.language);
    final correct = '先围绕$keyword写最小可运行示例，再用边界输入验证“$title”的结果';
    final wrongs = <String>[
      '只背下$title的结论，遇到新输入时凭感觉修改代码',
      '一次改完所有变量和依赖，再统一观察是否报错',
      '跳过错误信息，直接复制另一段代码直到能运行',
    ];
    final options = _optionSet(correct, wrongs, seed + 23);
    final explanation = _joinExplanation(<String>[
      '在 $label 课程“$title”里，$keyword不是孤立的名词，而是一组可以用输入、过程、输出和边界验证的行为。',
      '对 $label 课程“$title”来说，先写最小可运行示例，再逐步增加边界输入，能把“感觉会了”转化成可以重复的证据。',
      '如果只背结论或一次改很多变量，出错时就无法判断是哪一步破坏了 $label 课程“$title”的预期；先把变化隔离出来才容易定位。',
    ]);
    return QuizQuestion(
      question: '在 $label 课程“$title”的学习或项目场景中，哪种做法最有助于得到可验证、可迁移的结果？',
      options: options,
      answerIndex: options.indexOf(correct),
      explanation: explanation,
      type: 'single',
    );
  }

  static List<String> _optionSet(
    String correct,
    List<String> wrongs,
    int seed,
  ) {
    final options = <String>{correct, ...wrongs}.toList();
    options.shuffle(Random(seed));
    return options;
  }

  static String _joinExplanation(List<String> sentences) =>
      sentences.where((sentence) => sentence.trim().isNotEmpty).join('\n');

  static String _flavor(int seed) {
    const values = <String>['变量', '循环', '函数', '集合', '条件', '错误处理', '输入输出', '边界'];
    return values[seed.abs() % values.length];
  }

  static String _languageLabel(String language) {
    const labels = <String, String>{
      'python': 'Python',
      'c': 'C',
      'cpp': 'C++',
      'java': 'Java',
      'javascript': 'JavaScript',
      'typescript': 'TypeScript',
      'csharp': 'C#',
      'go': 'Go',
      'rust': 'Rust',
      'kotlin': 'Kotlin',
      'swift': 'Swift',
      'shell': 'Shell',
    };
    return labels[language] ?? language;
  }

  static int _stableHash(String value) {
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = 37 * hash + codeUnit;
      hash &= 0x7fffffff;
    }
    return hash;
  }
}

/// 在 UI 与组卷服务中统一使用完整题集，避免动态题只出现在某一个页面。
extension LessonPracticeQuestions on Lesson {
  List<QuizQuestion> get allQuiz => <QuizQuestion>[
    ...quiz,
    ...PracticeQuestionFactory.questionsFor(this),
  ];

  int get totalQuestionCount => allQuiz.length;
}

/// 单一语言的最小语法模板。模板用 {x}/{n}/{n1} 等占位符表示运行时变量。
class _LangSpec {
  const _LangSpec({
    required this.language,
    required this.variable,
    required this.loop,
    required this.function,
    required this.syntaxError,
    required this.syntaxFix,
    required this.offByOne,
    required this.offByOneFix,
  });

  final String language;
  final String variable;
  final String loop;
  final String function;
  final String syntaxError;
  final String syntaxFix;
  final String offByOne;
  final String offByOneFix;
}

final Map<String, _LangSpec> _specs = <String, _LangSpec>{
  'python': const _LangSpec(
    language: 'python',
    variable: 'x = {x}\nprint(x)',
    loop: 'total = 0\nfor i in range(1, {n1}):\n    total += i\nprint(total)',
    function: 'def double(value):\n    return value * 2\n\nprint(double({n}))',
    syntaxError: 'score = {x}\nif score > 0\n    print("positive")',
    syntaxFix: '在 if 条件行末尾补上冒号',
    offByOne:
        'total = 0\nfor i in range(1, {n}):\n    total += i\nprint(total)',
    offByOneFix: '把 range(1, {n}) 改成 range(1, {n1})',
  ),
  'c': const _LangSpec(
    language: 'c',
    variable: '#include <stdio.h>\n\nint main(void) {\n    int x = {x};\n    printf("%d\\n", x);\n    return 0;\n}',
    loop: '#include <stdio.h>\n\nint main(void) {\n    int total = 0;\n    for (int i = 1; i <= {n}; i++) {\n        total += i;\n    }\n    printf("%d\\n", total);\n    return 0;\n}',
    function: '#include <stdio.h>\n\nint double_value(int value) {\n    return value * 2;\n}\n\nint main(void) {\n    printf("%d\\n", double_value({n}));\n    return 0;\n}',
    syntaxError: '#include <stdio.h>\n\nint main(void) {\n    int x = {x}\n    printf("%d\\n", x);\n    return 0;\n}',
    syntaxFix: '在 int x = {x} 这一行末尾补上分号',
    offByOne: '#include <stdio.h>\n\nint main(void) {\n    int total = 0;\n    for (int i = 1; i < {n}; i++) {\n        total += i;\n    }\n    printf("%d\\n", total);\n    return 0;\n}',
    offByOneFix: '把循环条件 i < {n} 改成 i <= {n}',
  ),
  'cpp': const _LangSpec(
    language: 'cpp',
    variable: '#include <iostream>\n\nint main() {\n    int x = {x};\n    std::cout << x << "\\n";\n    return 0;\n}',
    loop: '#include <iostream>\n\nint main() {\n    int total = 0;\n    for (int i = 1; i <= {n}; i++) {\n        total += i;\n    }\n    std::cout << total << "\\n";\n    return 0;\n}',
    function: '#include <iostream>\n\nint double_value(int value) {\n    return value * 2;\n}\n\nint main() {\n    std::cout << double_value({n}) << "\\n";\n    return 0;\n}',
    syntaxError: '#include <iostream>\n\nint main() {\n    int x = {x}\n    std::cout << x << "\\n";\n    return 0;\n}',
    syntaxFix: '在 int x = {x} 这一行末尾补上分号',
    offByOne: '#include <iostream>\n\nint main() {\n    int total = 0;\n    for (int i = 1; i < {n}; i++) {\n        total += i;\n    }\n    std::cout << total << "\\n";\n    return 0;\n}',
    offByOneFix: '把循环条件 i < {n} 改成 i <= {n}',
  ),
  'java': const _LangSpec(
    language: 'java',
    variable: 'public class Main {\n    public static void main(String[] args) {\n        int x = {x};\n        System.out.println(x);\n    }\n}',
    loop: 'public class Main {\n    public static void main(String[] args) {\n        int total = 0;\n        for (int i = 1; i <= {n}; i++) {\n            total += i;\n        }\n        System.out.println(total);\n    }\n}',
    function: 'public class Main {\n    static int doubleValue(int value) {\n        return value * 2;\n    }\n\n    public static void main(String[] args) {\n        System.out.println(doubleValue({n}));\n    }\n}',
    syntaxError: 'public class Main {\n    public static void main(String[] args) {\n        int x = {x}\n        System.out.println(x);\n    }\n}',
    syntaxFix: '在 int x = {x} 这一行末尾补上分号',
    offByOne: 'public class Main {\n    public static void main(String[] args) {\n        int total = 0;\n        for (int i = 1; i < {n}; i++) {\n            total += i;\n        }\n        System.out.println(total);\n    }\n}',
    offByOneFix: '把循环条件 i < {n} 改成 i <= {n}',
  ),
  'javascript': const _LangSpec(
    language: 'javascript',
    variable: 'const x = {x};\nconsole.log(x);',
    loop: 'let total = 0;\nfor (let i = 1; i <= {n}; i++) {\n  total += i;\n}\nconsole.log(total);',
    function: 'function double(value) {\n  return value * 2;\n}\n\nconsole.log(double({n}));',
    syntaxError:
        'const score = {x};\nif (score > 0 {\n  console.log("positive");\n}',
    syntaxFix: '在 if 条件后面补上右括号',
    offByOne: 'let total = 0;\nfor (let i = 1; i < {n}; i++) {\n  total += i;\n}\nconsole.log(total);',
    offByOneFix: '把循环条件 i < {n} 改成 i <= {n}',
  ),
  'typescript': const _LangSpec(
    language: 'typescript',
    variable: 'const x: number = {x};\nconsole.log(x);',
    loop: 'let total: number = 0;\nfor (let i: number = 1; i <= {n}; i++) {\n  total += i;\n}\nconsole.log(total);',
    function: 'function double(value: number): number {\n  return value * 2;\n}\n\nconsole.log(double({n}));',
    syntaxError: 'const score: number = {x};\nif (score > 0 {\n  console.log("positive");\n}',
    syntaxFix: '在 if 条件后面补上右括号',
    offByOne: 'let total: number = 0;\nfor (let i: number = 1; i < {n}; i++) {\n  total += i;\n}\nconsole.log(total);',
    offByOneFix: '把循环条件 i < {n} 改成 i <= {n}',
  ),
  'csharp': const _LangSpec(
    language: 'csharp',
    variable: 'using System;\n\nclass Program {\n    static void Main() {\n        int x = {x};\n        Console.WriteLine(x);\n    }\n}',
    loop: 'using System;\n\nclass Program {\n    static void Main() {\n        int total = 0;\n        for (int i = 1; i <= {n}; i++) {\n            total += i;\n        }\n        Console.WriteLine(total);\n    }\n}',
    function: 'using System;\n\nclass Program {\n    static int DoubleValue(int value) => value * 2;\n\n    static void Main() {\n        Console.WriteLine(DoubleValue({n}));\n    }\n}',
    syntaxError: 'using System;\n\nclass Program {\n    static void Main() {\n        int x = {x}\n        Console.WriteLine(x);\n    }\n}',
    syntaxFix: '在 int x = {x} 这一行末尾补上分号',
    offByOne: 'using System;\n\nclass Program {\n    static void Main() {\n        int total = 0;\n        for (int i = 1; i < {n}; i++) {\n            total += i;\n        }\n        Console.WriteLine(total);\n    }\n}',
    offByOneFix: '把循环条件 i < {n} 改成 i <= {n}',
  ),
  'go': const _LangSpec(
    language: 'go',
    variable: 'package main\n\nimport "fmt"\n\nfunc main() {\n    x := {x}\n    fmt.Println(x)\n}',
    loop: 'package main\n\nimport "fmt"\n\nfunc main() {\n    total := 0\n    for i := 1; i <= {n}; i++ {\n        total += i\n    }\n    fmt.Println(total)\n}',
    function: 'package main\n\nimport "fmt"\n\nfunc double(value int) int {\n    return value * 2\n}\n\nfunc main() {\n    fmt.Println(double({n}))\n}',
    syntaxError: 'package main\n\nimport "fmt"\n\nfunc main() {\n    total := 0\n    for i := 1; i <= {n}; i++\n        total += i\n    }\n    fmt.Println(total)\n}',
    syntaxFix: '在 for 语句末尾补上左花括号',
    offByOne: 'package main\n\nimport "fmt"\n\nfunc main() {\n    total := 0\n    for i := 1; i < {n}; i++ {\n        total += i\n    }\n    fmt.Println(total)\n}',
    offByOneFix: '把循环条件 i < {n} 改成 i <= {n}',
  ),
  'rust': const _LangSpec(
    language: 'rust',
    variable: 'fn main() {\n    let x = {x};\n    println!("{}", x);\n}',
    loop: 'fn main() {\n    let mut total = 0;\n    for i in 1..={n} {\n        total += i;\n    }\n    println!("{}", total);\n}',
    function: 'fn double(value: i32) -> i32 {\n    value * 2\n}\n\nfn main() {\n    println!("{}", double({n}));\n}',
    syntaxError: 'fn main() {\n    let x = {x}\n    println!("{}", x);\n}',
    syntaxFix: '在 let x = {x} 这一行末尾补上分号',
    offByOne: 'fn main() {\n    let mut total = 0;\n    for i in 1..{n} {\n        total += i;\n    }\n    println!("{}", total);\n}',
    offByOneFix: '把 1..{n} 改成 1..={n}',
  ),
  'kotlin': const _LangSpec(
    language: 'kotlin',
    variable: 'fun main() {\n    val x = {x}\n    println(x)\n}',
    loop: 'fun main() {\n    var total = 0\n    for (i in 1..{n}) {\n        total += i\n    }\n    println(total)\n}',
    function: 'fun double(value: Int): Int = value * 2\n\nfun main() {\n    println(double({n}))\n}',
    syntaxError: 'fun main() {\n    val x = {x}\n    println(x)\n',
    syntaxFix: '在 main 函数末尾补上右花括号',
    offByOne: 'fun main() {\n    var total = 0\n    for (i in 1 until {n}) {\n        total += i\n    }\n    println(total)\n}',
    offByOneFix: '把 1 until {n} 改成 1..{n}',
  ),
  'swift': const _LangSpec(
    language: 'swift',
    variable: 'let x = {x}\nprint(x)',
    loop: 'var total = 0\nfor i in 1...{n} {\n    total += i\n}\nprint(total)',
    function: 'func double(_ value: Int) -> Int {\n    return value * 2\n}\n\nprint(double({n}))',
    syntaxError: 'let score = {x}\nif score > 0\n    print("positive")\n',
    syntaxFix: '给 if 分支补上花括号',
    offByOne:
        'var total = 0\nfor i in 1..<{n} {\n    total += i\n}\nprint(total)',
    offByOneFix: '把 1..<{n} 改成 1...{n}',
  ),
  'shell': const _LangSpec(
    language: 'shell',
    variable: 'x={x}\necho "\$x"',
    loop: 'total=0\nfor i in \$(seq 1 {n}); do\n  total=\$((total + i))\ndone\necho "\$total"',
    function: 'double() {\n  echo \$((\$1 * 2))\n}\n\ndouble {n}',
    syntaxError: 'if [ {x} -gt 0 ]; then\n  echo "positive"\n',
    syntaxFix: '在 if 块末尾补上 fi',
    offByOne: 'total=0\nfor i in \$(seq 1 \$(({n} - 1))); do\n  total=\$((total + i))\ndone\necho "\$total"',
    offByOneFix: '把 seq 的上界改成 1..{n}',
  ),
};
