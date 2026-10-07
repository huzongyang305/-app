import 'package:flutter_test/flutter_test.dart';

import 'package:code_learn_app/models/sandbox_language.dart';
import 'package:code_learn_app/services/code_sandbox_service.dart';
import 'package:code_learn_app/services/sandbox_trace_engine.dart';

void main() {
  group('SandboxTraceEngine 静态检查', () {
    test('Java 缺少类声明时给出错误', () {
      final result = SandboxTraceEngine.analyze(
        SandboxLanguage.java,
        'public static void main(String[] args) {\n'
        '  System.out.println("hi");\n'
        '}',
      );
      expect(result.hasErrors, isTrue);
      expect(
        result.diagnostics.any((item) => item.message.contains('class')),
        isTrue,
      );
    });

    test('Java 教材示例可以通过结构检查', () {
      final result = SandboxTraceEngine.analyze(SandboxLanguage.java, '''
public class Main {
    public static void main(String[] args) {
        System.out.println("你好，Java");
    }
}
''');
      expect(result.hasErrors, isFalse, reason: result.diagnostics.join('\n'));
    });

    test('Go 必须声明 package main', () {
      final result = SandboxTraceEngine.analyze(
        SandboxLanguage.golang,
        'func main() {\n  fmt.Println("hi")\n}',
      );
      expect(result.hasErrors, isTrue);
      expect(
        result.diagnostics.any((item) => item.message.contains('package main')),
        isTrue,
      );
    });

    test('Rust 必须声明 fn main', () {
      final result = SandboxTraceEngine.analyze(
        SandboxLanguage.rust,
        'fn add(a: i32, b: i32) -> i32 { a + b }',
      );
      expect(result.hasErrors, isTrue);
    });

    test('Kotlin 必须声明 fun main', () {
      final result = SandboxTraceEngine.analyze(
        SandboxLanguage.kotlin,
        'val x = 1',
      );
      expect(result.hasErrors, isTrue);
    });

    test('Dart 必须声明 main', () {
      final result = SandboxTraceEngine.analyze(
        SandboxLanguage.dart,
        'final x = 1;',
      );
      expect(result.hasErrors, isTrue);
    });

    test('括号不匹配会报错并给出行号', () {
      final result = SandboxTraceEngine.analyze(
        SandboxLanguage.java,
        'public class Main {\n  static void main(String[] a) {\n    int x = 1;\n}\n',
      );
      expect(result.hasErrors, isTrue);
      expect(
        result.diagnostics.any((item) => item.message.contains('没有闭合')),
        isTrue,
      );
    });

    test('字符串未闭合会报错', () {
      final result = SandboxTraceEngine.analyze(
        SandboxLanguage.java,
        'public class Main {\n  static void main(String[] a) {\n'
        '    System.out.println("没有结束);\n  }\n}\n',
      );
      expect(result.hasErrors, isTrue);
    });

    test('块注释未闭合会报错', () {
      final result = SandboxTraceEngine.analyze(
        SandboxLanguage.java,
        'public class Main {\n/* 注释没有结束\n}\n',
      );
      expect(result.hasErrors, isTrue);
    });

    test('合法的 Rust 生命周期标注不会被当成未闭合字符串', () {
      final result = SandboxTraceEngine.analyze(
        SandboxLanguage.rust,
        "fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {\n"
        '    if a.len() > b.len() { a } else { b }\n'
        '}\n\nfn main() {\n    println!("ok");\n}\n',
      );
      expect(result.hasErrors, isFalse, reason: result.diagnostics.join('\n'));
    });
  });

  group('SandboxTraceEngine 输出追踪', () {
    test('追踪字符串字面量与数字', () {
      final result = SandboxTraceEngine.analyze(SandboxLanguage.java, '''
public class Main {
    public static void main(String[] args) {
        System.out.println("总分");
        System.out.println(42);
    }
}
''');
      expect(result.outputs.length, 2);
      expect(result.outputs[0].text, '总分');
      expect(result.outputs[1].text, '42');
    });

    test('追踪字符串拼接中的常量折叠', () {
      final result = SandboxTraceEngine.analyze(SandboxLanguage.csharp, '''
class Program {
    static void Main() {
        Console.WriteLine("结果 = " + 3);
    }
}
''');
      expect(result.outputs.single.text, '结果 = 3');
    });

    test('无法静态求值的表达式标注为运行期求值', () {
      final result = SandboxTraceEngine.analyze(SandboxLanguage.golang, '''
package main

import "fmt"

func main() {
	total := 10
	fmt.Println(total / 3)
}
''');
      expect(result.outputs.single.text, contains('运行期求值'));
      expect(result.outputs.single.text, contains('total / 3'));
    });

    test('变量重新赋值后不再使用旧值', () {
      final result = SandboxTraceEngine.analyze(SandboxLanguage.kotlin, '''
fun main() {
    var name = "旧值"
    name = "新值"
    println(name)
}
''');
      expect(result.outputs.single.text, contains('运行期求值'));
    });

    test('渲染结果包含静态检查与输出追踪两段', () {
      final result = SandboxTraceEngine.analyze(
        SandboxLanguage.swift,
        'print("hello")\n',
      );
      final rendered = result.render(SandboxLanguage.swift);
      expect(rendered, contains('【静态检查】'));
      expect(rendered, contains('【输出追踪】'));
      expect(rendered, contains('hello'));
    });
  });

  group('内置样例自检', () {
    test('Java / C# / Dart / Go / Rust / Kotlin / Swift 默认样例无结构错误', () {
      for (final language in SandboxLanguage.values.where(
        (item) => item.isTraceOnly,
      )) {
        final result = SandboxTraceEngine.analyze(
          language,
          language.sampleCode,
        );
        expect(
          result.hasErrors,
          isFalse,
          reason: '${language.id}: ${result.diagnostics.join(', ')}',
        );
      }
    });

    test('内置样例库中的每个示例都能通过结构检查', () {
      for (final language in SandboxLanguage.values.where(
        (item) => item.isTraceOnly,
      )) {
        for (final example in language.examples) {
          final result = SandboxTraceEngine.analyze(language, example.code);
          expect(
            result.hasErrors,
            isFalse,
            reason:
                '${language.id} / ${example.title.zh}: '
                '${result.diagnostics.join(', ')}',
          );
        }
      }
    });
  });

  group('CodeSandboxService 分派', () {
    test('教学模式语言走纯 Dart 引擎，不依赖原生通道', () async {
      final output = await CodeSandboxService.runCode(
        SandboxLanguage.dart,
        'void main() {\n  print("本地执行");\n}\n',
      );
      expect(output, contains('静态检查'));
      expect(output, contains('本地执行'));
    });

    test('教学模式会提示 stdin 被忽略', () async {
      final output = await CodeSandboxService.runCode(
        SandboxLanguage.java,
        'public class Main {\n  static void main(String[] a) {}\n}\n',
        stdin: '42',
      );
      expect(output, contains('stdin'));
    });
  });
}
