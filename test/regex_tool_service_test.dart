import 'package:code_learn_app/services/regex_tool_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegexToolService', () {
    test('返回匹配文本、位置与分组', () async {
      final result = await RegexToolService.match(
        pattern: r'(\w+)=(\d+)',
        text: 'a=1, bb=22',
      );

      expect(result.matches, hasLength(2));
      expect(result.matches[0].text, 'a=1');
      expect(result.matches[0].start, 0);
      expect(result.matches[0].end, 3);
      expect(result.matches[0].groups, ['a', '1']);
      expect(result.matches[1].text, 'bb=22');
      expect(result.truncated, isFalse);
    });

    test('支持忽略大小写与点号匹配换行', () async {
      final result = await RegexToolService.match(
        pattern: 'hello.world',
        text: 'HELLO\nWORLD',
        caseSensitive: false,
        dotAll: true,
      );

      expect(result.matches.single.text, 'HELLO\nWORLD');
    });

    test('达到上限后标记截断并停止展开', () async {
      final result = await RegexToolService.match(
        pattern: 'a',
        text: 'aaaaa',
        matchLimit: 2,
      );

      expect(result.matches, hasLength(2));
      expect(result.truncated, isTrue);
    });

    test('非法表达式抛出 invalidPattern', () async {
      await expectLater(
        RegexToolService.match(pattern: '(', text: 'abc'),
        throwsA(
          isA<RegexToolException>().having(
            (error) => error.kind,
            'kind',
            RegexToolError.invalidPattern,
          ),
        ),
      );
    });

    test('超长表达式与文本在进入 isolate 前被拒绝', () async {
      await expectLater(
        RegexToolService.match(
          pattern: 'a' * (RegexToolService.maxPatternLength + 1),
          text: 'abc',
        ),
        throwsA(
          isA<RegexToolException>().having(
            (error) => error.kind,
            'kind',
            RegexToolError.patternTooLong,
          ),
        ),
      );

      await expectLater(
        RegexToolService.match(
          pattern: 'a',
          text: 'a' * (RegexToolService.maxTextLength + 1),
        ),
        throwsA(
          isA<RegexToolException>().having(
            (error) => error.kind,
            'kind',
            RegexToolError.textTooLong,
          ),
        ),
      );
    });

    test('灾难性回溯会超时并被终止', () async {
      await expectLater(
        RegexToolService.match(
          pattern: r'(a+)+$',
          text: '${'a' * 32}!',
          timeout: const Duration(milliseconds: 150),
        ),
        throwsA(
          isA<RegexToolException>().having(
            (error) => error.kind,
            'kind',
            RegexToolError.timeout,
          ),
        ),
      );
    });
  });
}
