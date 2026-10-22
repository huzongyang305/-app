import 'package:code_learn_app/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

/// 界面文案自检：保证每个词条中英文齐全，且占位符一致。
void main() {
  test('每个词条都同时提供中文与英文', () {
    final missing = <String>[];
    for (final key in AppStrings.allKeys) {
      final entry = AppStrings.raw(key)!;
      final zh = (entry['zh'] ?? '').trim();
      final en = (entry['en'] ?? '').trim();
      if (zh.isEmpty || en.isEmpty) {
        missing.add(key);
      }
    }
    expect(missing, isEmpty, reason: '缺少中英文的词条：${missing.join('、')}');
  });

  test('中英文的占位符保持一致', () {
    final placeholder = RegExp(r'\{(\w+)\}');
    final problems = <String>[];
    for (final key in AppStrings.allKeys) {
      final entry = AppStrings.raw(key)!;
      final zh = placeholder
          .allMatches(entry['zh'] ?? '')
          .map((m) => m.group(1))
          .toSet();
      final en = placeholder
          .allMatches(entry['en'] ?? '')
          .map((m) => m.group(1))
          .toSet();
      if (!zh.containsAll(en) || !en.containsAll(zh)) {
        problems.add('$key（zh: ${zh.join(',')} / en: ${en.join(',')}）');
      }
    }
    expect(problems, isEmpty, reason: '占位符不一致：${problems.join('、')}');
  });

  test('难度映射覆盖四个档位且英文各不相同', () {
    const keys = <String>[
      'difficultyBeginner',
      'difficultyBasic',
      'difficultyIntermediate',
      'difficultyAdvanced',
    ];
    final english = <String>{};
    for (final key in keys) {
      final entry = AppStrings.raw(key);
      expect(entry, isNotNull, reason: '缺少词条 $key');
      expect(entry!['zh'], isNotEmpty, reason: '$key 缺少中文');
      english.add(entry['en']!);
    }
    expect(english.length, keys.length, reason: '英文难度标签出现重复');
  });
}
