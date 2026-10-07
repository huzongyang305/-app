import '../models/sandbox_language.dart';

/// 教学子集静态检查 + 输出追踪引擎。
///
/// Java / C# / Dart / Go / Rust / Kotlin / Swift 没有内置完整编译器，
/// 因此这里不做（也无法做）真正的编译执行，而是提供三层离线能力：
///
/// 1. 词法体检：跳过注释与字符串后检查括号、引号、块注释是否闭合；
/// 2. 结构检查：校验各语言必须的入口结构（package main / fn main / main 等）；
/// 3. 输出追踪：按行顺序跟踪字面量赋值，推导 println 一类语句的输出，
///    无法静态求值的表达式如实标注为「运行期求值」，不伪造结果。
///
/// 纯 Dart 实现，不依赖网络与原生层，可在任何平台上运行和测试。
class SandboxTraceEngine {
  const SandboxTraceEngine._();

  /// 分析 [code] 并返回可展示的追踪结果。
  static SandboxTraceResult analyze(SandboxLanguage language, String code) {
    final scanner = _CodeScanner(code);
    final diagnostics = <SandboxDiagnostic>[
      ...scanner.diagnostics,
      ..._checkLanguageRules(language, scanner),
    ];
    if (!scanner.hasLexicalError) {
      diagnostics.addAll(_checkBrackets(scanner));
      diagnostics.addAll(_checkSemicolons(language, scanner));
    }
    final outputs = scanner.hasLexicalError
        ? const <SandboxTraceOutput>[]
        : _traceOutputs(language, scanner);
    return SandboxTraceResult(
      diagnostics: diagnostics,
      outputs: outputs,
      profile: _profile(scanner.skeleton),
      lineCount: scanner.lineCount,
    );
  }

  /// 各语言必须的入口结构。缺失时给出错误级诊断。
  static const Map<SandboxLanguage, List<_StructureRule>> _structureRules = {
    SandboxLanguage.java: <_StructureRule>[
      _StructureRule(
        pattern: r'\b(class|interface|enum|record)\s+\w+',
        message: 'Java 程序至少需要一个 class / interface / enum / record 声明。',
        severity: SandboxDiagnosticSeverity.error,
      ),
      _StructureRule(
        pattern: r'static\s+void\s+main\s*\(',
        message: '没有找到 static void main(String[] args) 入口，程序无法独立运行。',
        severity: SandboxDiagnosticSeverity.warning,
      ),
    ],
    SandboxLanguage.csharp: <_StructureRule>[
      _StructureRule(
        pattern: r'\b(class|struct|interface|record|namespace)\s+\w+',
        message: 'C# 顶层语句之外的内容需要放在 class / struct / record / namespace 中。',
        severity: SandboxDiagnosticSeverity.warning,
      ),
      _StructureRule(
        pattern: r'\bstatic\s+(void|int|async\s+Task)\s+Main\s*\(',
        message: '没有找到 static Main 方法；使用顶级语句时可以忽略此提示。',
        severity: SandboxDiagnosticSeverity.info,
      ),
    ],
    SandboxLanguage.dart: <_StructureRule>[
      _StructureRule(
        pattern: r'\bmain\s*\(',
        message: 'Dart 可执行程序需要 main() 入口函数。',
        severity: SandboxDiagnosticSeverity.error,
      ),
    ],
    SandboxLanguage.golang: <_StructureRule>[
      _StructureRule(
        pattern: r'^\s*package\s+main\b',
        message: 'Go 可执行程序的第一行需要 package main。',
        severity: SandboxDiagnosticSeverity.error,
        multiLine: true,
      ),
      _StructureRule(
        pattern: r'\bfunc\s+main\s*\(',
        message: '没有找到 func main() 入口。',
        severity: SandboxDiagnosticSeverity.error,
      ),
    ],
    SandboxLanguage.rust: <_StructureRule>[
      _StructureRule(
        pattern: r'\bfn\s+main\s*\(',
        message: 'Rust 可执行程序需要 fn main() 入口。',
        severity: SandboxDiagnosticSeverity.error,
      ),
    ],
    SandboxLanguage.kotlin: <_StructureRule>[
      _StructureRule(
        pattern: r'\bfun\s+main\s*\(',
        message: 'Kotlin 可执行程序需要 fun main() 入口。',
        severity: SandboxDiagnosticSeverity.error,
      ),
    ],
    SandboxLanguage.swift: <_StructureRule>[
      _StructureRule(
        pattern: r'\b(print|func|struct|class|enum|let|var)\b',
        message: 'Swift 脚本没有可识别的顶层语句，请检查代码是否为空。',
        severity: SandboxDiagnosticSeverity.warning,
      ),
    ],
  };

  static List<SandboxDiagnostic> _checkLanguageRules(
    SandboxLanguage language,
    _CodeScanner scanner,
  ) {
    final rules = _structureRules[language];
    if (rules == null) return const <SandboxDiagnostic>[];
    final result = <SandboxDiagnostic>[];
    final text = scanner.skeleton;
    for (final rule in rules) {
      final regex = RegExp(rule.pattern, multiLine: rule.multiLine);
      if (regex.hasMatch(text)) continue;
      result.add(
        SandboxDiagnostic(
          line: 1,
          severity: rule.severity,
          message: rule.message,
        ),
      );
    }
    return result;
  }

  /// 括号配对检查：在去掉注释与字符串的骨架上做栈匹配。
  static List<SandboxDiagnostic> _checkBrackets(_CodeScanner scanner) {
    const openers = <String>{'(', '[', '{'};
    const pairs = <String, String>{')': '(', ']': '[', '}': '{'};
    final stack = <_OpenBracket>[];
    final result = <SandboxDiagnostic>[];
    var line = 1;
    for (final char in scanner.skeleton.split('')) {
      if (char == '\n') {
        line++;
        continue;
      }
      if (openers.contains(char)) {
        stack.add(_OpenBracket(char, line));
        continue;
      }
      final expected = pairs[char];
      if (expected == null) continue;
      if (stack.isEmpty) {
        result.add(
          SandboxDiagnostic(
            line: line,
            severity: SandboxDiagnosticSeverity.error,
            message: '多余的 $char：前面没有对应的开括号。',
          ),
        );
        continue;
      }
      final top = stack.removeLast();
      if (top.char != expected) {
        result.add(
          SandboxDiagnostic(
            line: line,
            severity: SandboxDiagnosticSeverity.error,
            message:
                '括号不匹配：$char 需要配对的 $expected，但最近的未闭合括号是 ${top.char}（L${top.line}）。',
          ),
        );
      }
    }
    for (final item in stack) {
      result.add(
        SandboxDiagnostic(
          line: item.line,
          severity: SandboxDiagnosticSeverity.error,
          message: '${item.char} 没有闭合。',
        ),
      );
    }
    return result;
  }

  /// 分号体检：只针对高置信度的输出语句，避免对合法语法产生误报。
  static List<SandboxDiagnostic> _checkSemicolons(
    SandboxLanguage language,
    _CodeScanner scanner,
  ) {
    if (language == SandboxLanguage.golang ||
        language == SandboxLanguage.swift) {
      // Go 由编译器自动插入分号；Swift 语句结尾分号可选。
      return const <SandboxDiagnostic>[];
    }
    final result = <SandboxDiagnostic>[];
    final pattern = RegExp(
      r'^\s*(System\.out\.print(?:ln)?|Console\.Write(?:Line)?|print(?:ln)?|fmt\.Print(?:ln|f)?|println!|print!)\b',
    );
    for (var index = 0; index < scanner.lines.length; index++) {
      final line = scanner.lines[index];
      if (!pattern.hasMatch(line)) continue;
      if (scanner.isInsideComment(index)) continue;
      final trimmed = line.trimRight();
      if (trimmed.endsWith(';') ||
          trimmed.endsWith('{') ||
          trimmed.endsWith(',')) {
        continue;
      }
      result.add(
        SandboxDiagnostic(
          line: index + 1,
          severity: SandboxDiagnosticSeverity.warning,
          message: '语句末尾可能缺少分号。',
        ),
      );
    }
    return result;
  }

  static SandboxCodeProfile _profile(String skeleton) {
    int count(RegExp regex) => regex.allMatches(skeleton).length;
    return SandboxCodeProfile(
      classes: count(
        RegExp(r'\b(class|struct|interface|enum|record|trait|impl)\b'),
      ),
      functions: count(
        RegExp(
          r'\b(fn|func|fun|void|int|double|String|bool|boolean|var|let)\s+\w+\s*\(',
        ),
      ),
      loops: count(RegExp(r'\b(for|while|do|loop)\b')),
      branches: count(RegExp(r'\b(if|else|switch|when|match|case)\b')),
      assignments: count(RegExp(r'(^|[^=!<>+\-*/])=(?!=)')),
    );
  }

  static List<SandboxTraceOutput> _traceOutputs(
    SandboxLanguage language,
    _CodeScanner scanner,
  ) {
    final callPattern = _outputCallPattern(language);
    final variables = <String, _StaticValue>{};
    final outputs = <SandboxTraceOutput>[];
    for (var index = 0; index < scanner.lines.length; index++) {
      final line = scanner.lines[index];
      if (scanner.isInsideComment(index)) continue;
      _updateVariables(line, variables);
      for (final match in callPattern.allMatches(line)) {
        final argumentStart = match.end;
        final rawArguments = _readArguments(line, argumentStart);
        if (rawArguments == null) continue;
        final values = _evaluateArguments(
          language,
          rawArguments,
          variables,
          scanner,
        );
        if (values.isEmpty) continue;
        outputs.add(
          SandboxTraceOutput(
            line: index + 1,
            text: values.join(language == SandboxLanguage.golang ? ' ' : ''),
          ),
        );
      }
    }
    return outputs;
  }

  static RegExp _outputCallPattern(SandboxLanguage language) {
    switch (language) {
      case SandboxLanguage.java:
        return RegExp(r'System\.out\.print(?:ln)?\s*\(');
      case SandboxLanguage.csharp:
        return RegExp(r'Console\.Write(?:Line)?\s*\(');
      case SandboxLanguage.golang:
        return RegExp(r'fmt\.Print(?:ln|f)?\s*\(');
      case SandboxLanguage.rust:
        return RegExp(r'print(?:ln)?!\s*\(');
      case SandboxLanguage.kotlin:
        return RegExp(r'\bprint(?:ln)?\s*\(');
      case SandboxLanguage.swift:
      case SandboxLanguage.dart:
        return RegExp(r'\bprint\s*\(');
      default:
        return RegExp(r'\bprint(?:ln)?\s*\(');
    }
  }

  /// 从 [start]（左括号之后）读取到配对的右括号，返回内部参数文本。
  static String? _readArguments(String line, int start) {
    final buffer = StringBuffer();
    var depth = 0;
    String? quote;
    for (var index = start; index < line.length; index++) {
      final char = line[index];
      final previous = index > 0 ? line[index - 1] : '';
      if (quote != null) {
        buffer.write(char);
        if (char == quote && previous != r'\') quote = null;
        continue;
      }
      if (char == '"' || char == "'" || char == '`') {
        quote = char;
        buffer.write(char);
        continue;
      }
      if (char == '(' || char == '[' || char == '{') {
        depth++;
        buffer.write(char);
        continue;
      }
      if (char == ')' && depth == 0) return buffer.toString();
      if (char == ')' || char == ']' || char == '}') {
        depth--;
        buffer.write(char);
        continue;
      }
      buffer.write(char);
    }
    return null;
  }

  static List<String> _evaluateArguments(
    SandboxLanguage language,
    String raw,
    Map<String, _StaticValue> variables,
    _CodeScanner scanner,
  ) {
    final parts = _splitTopLevel(raw);
    final values = <String>[];
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      // 命名参数（Swift terminator / Kotlin separator）不产生输出。
      if (RegExp(r'^\w+\s*:').hasMatch(trimmed) && trimmed.contains(': ')) {
        final key = trimmed.split(':').first.trim();
        if (key == 'terminator' || key == 'separator' || key == 'end') continue;
      }
      values.add(_evaluateExpression(trimmed, variables));
    }
    return values;
  }

  static List<String> _splitTopLevel(String text) {
    final result = <String>[];
    final buffer = StringBuffer();
    var depth = 0;
    String? quote;
    for (var index = 0; index < text.length; index++) {
      final char = text[index];
      final previous = index > 0 ? text[index - 1] : '';
      if (quote != null) {
        buffer.write(char);
        if (char == quote && previous != r'\') quote = null;
        continue;
      }
      if (char == '"' || char == "'" || char == '`') {
        quote = char;
        buffer.write(char);
        continue;
      }
      if (char == '(' || char == '[' || char == '{') {
        depth++;
      } else if (char == ')' || char == ']' || char == '}') {
        depth--;
      } else if (char == ',' && depth == 0) {
        result.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }
    result.add(buffer.toString());
    return result;
  }

  static String _evaluateExpression(
    String expression,
    Map<String, _StaticValue> variables,
  ) {
    final trimmed = expression.trim();
    if (trimmed.isEmpty) return '';

    final literal = _parseStringLiteral(trimmed);
    if (literal != null) return literal;

    final number = double.tryParse(trimmed);
    if (number != null) return _formatNumber(number);

    final variable = variables[trimmed];
    if (variable != null) return variable.display;

    final concatenated = _evaluateConcatenation(trimmed, variables);
    if (concatenated != null) return concatenated;

    final arithmetic = _evaluateArithmetic(trimmed);
    if (arithmetic != null) return arithmetic;

    final call = _evaluateKnownCall(trimmed, variables);
    if (call != null) return call;

    // 无法静态求值的表达式如实标注，绝不伪造运行结果。
    return '（运行期求值：${_clip(trimmed, 40)}）';
  }

  static String? _evaluateConcatenation(
    String expression,
    Map<String, _StaticValue> variables,
  ) {
    final parts = _splitTopLevelOperator(expression, '+');
    if (parts.length < 2) return null;
    final buffer = StringBuffer();
    for (final part in parts) {
      final value = _evaluateExpression(part.trim(), variables);
      if (value.startsWith('（运行期求值：')) return null;
      buffer.write(value);
    }
    return buffer.toString();
  }

  static List<String> _splitTopLevelOperator(String text, String operator) {
    final result = <String>[];
    final buffer = StringBuffer();
    var depth = 0;
    String? quote;
    for (var index = 0; index < text.length; index++) {
      final char = text[index];
      final previous = index > 0 ? text[index - 1] : '';
      if (quote != null) {
        buffer.write(char);
        if (char == quote && previous != r'\') quote = null;
        continue;
      }
      if (char == '"' || char == "'" || char == '`') {
        quote = char;
        buffer.write(char);
        continue;
      }
      if (char == '(' || char == '[' || char == '{') {
        depth++;
      } else if (char == ')' || char == ']' || char == '}') {
        depth--;
      } else if (char == operator &&
          depth == 0 &&
          _isBinaryOperator(text, index)) {
        result.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }
    result.add(buffer.toString());
    return result;
  }

  static bool _isBinaryOperator(String text, int index) {
    final previous = index > 0 ? text[index - 1] : '';
    final next = index + 1 < text.length ? text[index + 1] : '';
    if (previous == '+' || next == '+') return false;
    return true;
  }

  static String? _evaluateArithmetic(String expression) {
    final match = RegExp(
      r'^(-?\d+(?:\.\d+)?)\s*([+\-*/%])\s*(-?\d+(?:\.\d+)?)$',
    ).firstMatch(expression);
    if (match == null) return null;
    final left = double.parse(match.group(1)!);
    final right = double.parse(match.group(3)!);
    final op = match.group(2)!;
    final value = switch (op) {
      '+' => left + right,
      '-' => left - right,
      '*' => left * right,
      '/' => right == 0 ? null : left / right,
      '%' => right == 0 ? null : left % right,
      _ => null,
    };
    return value == null ? null : _formatNumber(value);
  }

  static String? _evaluateKnownCall(
    String expression,
    Map<String, _StaticValue> variables,
  ) {
    final lengthMatch = RegExp(r'^(\w+)\.(length|Length|len\(\)|count)$')
        .firstMatch(expression);
    if (lengthMatch != null) {
      final target = variables[lengthMatch.group(1)!];
      if (target?.length != null) return target!.length.toString();
    }
    final sumMatch = RegExp(r'^(\w+)\.reduce\(0,\s*\+\)$')
        .firstMatch(expression);
    if (sumMatch != null) {
      final target = variables[sumMatch.group(1)!];
      if (target?.sum != null) return _formatNumber(target!.sum!);
    }
    return null;
  }

  static String? _parseStringLiteral(String expression) {
    for (final quote in const ['"""', "'''", '"', "'", '`']) {
      if (!expression.startsWith(quote) || !expression.endsWith(quote)) {
        continue;
      }
      if (expression.length < quote.length * 2) continue;
      var inner = expression.substring(
        quote.length,
        expression.length - quote.length,
      );
      inner = inner.replaceAll(r'\n', '\n').replaceAll(r'\t', '\t');
      inner = inner.replaceAll(r'\"', '"').replaceAll(r"\'", "'");
      return inner;
    }
    return null;
  }

  static void _updateVariables(
    String line,
    Map<String, _StaticValue> variables,
  ) {
    final declaration = RegExp(
      r'(?:^|[;{]\s*|\b)(?:final|const|let|val|var|int|long|double|float|String|bool|boolean|auto|dyn)?\s*(\w+)\s*(?::\s*\w+(?:<[^>]+>)?\s*)?(?::=|=)\s*([^;]+)',
    );
    for (final match in declaration.allMatches(line)) {
      final name = match.group(1)!;
      final value = match.group(2)!.trim();
      _StaticValue? parsed = _parseStaticValue(value);
      if (parsed == null) {
        variables.remove(name);
        continue;
      }
      variables[name] = parsed;
    }
    // 变量被重新赋值或自增后，静态追踪不再可靠，直接移除。
    final reassign = RegExp(r'(\w+)\s*(?:\+\+|--|\+=|-=|\*=|/=|=(?!=))');
    for (final match in reassign.allMatches(line)) {
      final name = match.group(1)!;
      if (RegExp(
        r'(?:final|const|let|val|var|int|long|double|float|String|bool|boolean|auto)\s+$',
      ).hasMatch(line.substring(0, match.start))) {
        continue;
      }
      variables.remove(name);
    }
  }

  static _StaticValue? _parseStaticValue(String value) {
    final text = value.trim();
    final literal = _parseStringLiteral(text);
    if (literal != null) return _StaticValue(text: literal);
    final number = double.tryParse(text);
    if (number != null) return _StaticValue(text: _formatNumber(number));
    final list = _parseListLiteral(text);
    if (list != null) {
      return _StaticValue(
        text: '（集合：${list.length} 项）',
        length: list.length,
        sum: list.fold<double>(0, (sum, item) => sum + item),
      );
    }
    return null;
  }

  static List<double>? _parseListLiteral(String text) {
    final listMatch = RegExp(r'^\[(.*)\]$').firstMatch(text.trim());
    final braceMatch = RegExp(r'^\{([^:]*)\}$').firstMatch(text.trim());
    final inner = listMatch?.group(1) ?? braceMatch?.group(1);
    if (inner == null) return null;
    final items = _splitTopLevel(inner)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (items.isEmpty) return <double>[];
    final numbers = <double>[];
    for (final item in items) {
      final number = double.tryParse(item);
      if (number == null) return null;
      numbers.add(number);
    }
    return numbers;
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String _clip(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max)}…';
}

/// 一次静态追踪的完整结果。
class SandboxTraceResult {
  const SandboxTraceResult({
    required this.diagnostics,
    required this.outputs,
    required this.profile,
    required this.lineCount,
  });

  final List<SandboxDiagnostic> diagnostics;
  final List<SandboxTraceOutput> outputs;
  final SandboxCodeProfile profile;
  final int lineCount;

  bool get hasErrors => diagnostics.any(
    (item) => item.severity == SandboxDiagnosticSeverity.error,
  );

  int get errorCount => diagnostics
      .where((item) => item.severity == SandboxDiagnosticSeverity.error)
      .length;

  int get warningCount => diagnostics
      .where((item) => item.severity == SandboxDiagnosticSeverity.warning)
      .length;

  String get profileSummary => profile.describe();

  /// 渲染为可直接展示在沙箱输出区的文本。
  String render(SandboxLanguage language) {
    final buffer = StringBuffer();
    buffer.writeln('【静态检查】教学模式（未做完整编译）');
    if (diagnostics.isEmpty) {
      buffer.writeln('  通过：没有发现结构问题。');
    } else {
      if (errorCount > 0) {
        buffer.writeln('  发现 $errorCount 个错误、$warningCount 个警告。');
      } else if (warningCount > 0) {
        buffer.writeln('  发现 $warningCount 个警告。');
      } else {
        buffer.writeln('  提示 ${diagnostics.length} 条。');
      }
      for (final item in diagnostics.take(12)) {
        buffer.writeln('  ${item.render()}');
      }
      if (diagnostics.length > 12) {
        buffer.writeln('  ……还有 ${diagnostics.length - 12} 条，请先修正前面的问题。');
      }
    }

    buffer.writeln();
    if (outputs.isEmpty) {
      buffer.writeln('【输出追踪】没有找到可静态推导的输出语句。');
    } else {
      buffer.writeln('【输出追踪】共 ${outputs.length} 条（按字面量与变量推导）');
      for (final item in outputs) {
        buffer.writeln('  L${item.line}  ${item.text}');
      }
    }

    if (profile.hasContent) {
      buffer.writeln();
      buffer.writeln('【代码画像】${profile.describe()}');
    }
    if (hasErrors) {
      buffer.writeln();
      buffer.writeln('提示：静态检查只覆盖结构问题，不替代编译器的类型检查与标准库校验。');
    }
    return buffer.toString().trimRight();
  }
}

class SandboxTraceOutput {
  const SandboxTraceOutput({required this.line, required this.text});

  final int line;
  final String text;
}

class SandboxDiagnostic {
  const SandboxDiagnostic({
    required this.line,
    required this.severity,
    required this.message,
  });

  final int line;
  final SandboxDiagnosticSeverity severity;
  final String message;

  String render() {
    final label = switch (severity) {
      SandboxDiagnosticSeverity.error => '错误',
      SandboxDiagnosticSeverity.warning => '警告',
      SandboxDiagnosticSeverity.info => '提示',
    };
    return '[$label] L$line $message';
  }
}

enum SandboxDiagnosticSeverity { error, warning, info }

class _StructureRule {
  const _StructureRule({
    required this.pattern,
    required this.message,
    required this.severity,
    this.multiLine = false,
  });

  final String pattern;
  final String message;
  final SandboxDiagnosticSeverity severity;
  final bool multiLine;
}

class SandboxCodeProfile {
  const SandboxCodeProfile({
    required this.classes,
    required this.functions,
    required this.loops,
    required this.branches,
    required this.assignments,
  });

  final int classes;
  final int functions;
  final int loops;
  final int branches;
  final int assignments;

  bool get hasContent =>
      classes + functions + loops + branches + assignments > 0;

  String describe() {
    final parts = <String>[];
    if (classes > 0) parts.add('类型声明 $classes');
    if (functions > 0) parts.add('函数/方法 $functions');
    if (loops > 0) parts.add('循环 $loops');
    if (branches > 0) parts.add('分支/匹配 $branches');
    if (assignments > 0) parts.add('赋值 $assignments');
    return parts.isEmpty ? '未识别到结构' : parts.join(' · ');
  }
}

class _StaticValue {
  const _StaticValue({required this.text, this.length, this.sum});

  final String text;
  final int? length;
  final double? sum;

  String get display => text;
}

class _OpenBracket {
  const _OpenBracket(this.char, this.line);

  final String char;
  final int line;
}

/// 逐字符扫描源码：跳过注释与字符串字面量，产出用于结构检查的骨架。
class _CodeScanner {
  _CodeScanner(this.source) {
    _lines = source.split('\n');
    _scan();
  }

  final String source;
  late final List<String> _lines;
  final StringBuffer _skeleton = StringBuffer();
  final List<SandboxDiagnostic> diagnostics = <SandboxDiagnostic>[];
  final List<bool> _commentLines = <bool>[];
  bool hasLexicalError = false;

  String get skeleton => _skeleton.toString();
  List<String> get lines => _lines;
  int get lineCount => _lines.length;

  /// 最后一行的列号，预留用于后续定位诊断。
  int get lastColumn => _lastColumn;
  int _lastColumn = 0;

  bool isInsideComment(int index) =>
      index >= 0 && index < _commentLines.length && _commentLines[index];

  void _scan() {
    var line = 0;
    var column = 0;
    var index = 0;
    var inLineComment = false;
    var inBlockComment = false;
    String? quote;
    var currentLineHasComment = false;
    var quoteStartLine = 0;

    void addDiagnostic(String message) {
      diagnostics.add(
        SandboxDiagnostic(
          line: line + 1,
          severity: SandboxDiagnosticSeverity.error,
          message: message,
        ),
      );
      hasLexicalError = true;
    }

    void flushCommentFlag() {
      _commentLines.add(currentLineHasComment);
      currentLineHasComment = false;
    }

    while (index < source.length) {
      final char = source[index];
      final next = index + 1 < source.length ? source[index + 1] : '';

      if (char == '\n') {
        if (inLineComment) inLineComment = false;
        if (quote != null) {
          addDiagnostic('字符串从 L${quoteStartLine + 1} 开始，到文件结束都没有闭合。');
          quote = null;
          break;
        }
        flushCommentFlag();
        _skeleton.write('\n');
        line++;
        column = 0;
        index++;
        continue;
      }

      if (inBlockComment) {
        currentLineHasComment = true;
        if (char == '*' && next == '/') {
          inBlockComment = false;
          index += 2;
          column += 2;
          continue;
        }
        index++;
        column++;
        continue;
      }

      if (inLineComment) {
        currentLineHasComment = true;
        index++;
        column++;
        continue;
      }

      if (quote != null) {
        if (char == r'\' && index + 1 < source.length) {
          index += 2;
          column += 2;
          continue;
        }
        if (char == quote) {
          // Kotlin / Swift 的三引号字符串。
          if (index + 2 < source.length &&
              source[index + 1] == quote &&
              source[index + 2] == quote) {
            index += 3;
            column += 3;
          } else {
            index++;
            column++;
          }
          quote = null;
          _skeleton.write(' ');
          continue;
        }
        index++;
        column++;
        continue;
      }

      if (char == '/' && next == '/') {
        inLineComment = true;
        index += 2;
        column += 2;
        continue;
      }
      if (char == '/' && next == '*') {
        inBlockComment = true;
        currentLineHasComment = true;
        index += 2;
        column += 2;
        continue;
      }
      if (char == '"' || char == "'" || char == '`') {
        // Rust 的 'static / 'a 是生命周期标注而不是字符字面量，直接跳过。
        if (char == "'" &&
            index + 2 < source.length &&
            RegExp(r'[A-Za-z_]').hasMatch(source[index + 1]) &&
            source[index + 2] != "'") {
          _skeleton.write(char);
          index++;
          column++;
          continue;
        }
        quote = char;
        quoteStartLine = line;
        _skeleton.write(char);
        index++;
        column++;
        continue;
      }
      _skeleton.write(char);
      index++;
      column++;
    }

    while (_commentLines.length < _lines.length) {
      _commentLines.add(false);
    }
    _lastColumn = column;
    if (inBlockComment) {
      diagnostics.add(
        SandboxDiagnostic(
          line: _lines.length,
          severity: SandboxDiagnosticSeverity.error,
          message: '块注释 /* 没有闭合。',
        ),
      );
      hasLexicalError = true;
    }
  }
}
