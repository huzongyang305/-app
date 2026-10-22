import 'dart:convert';

import 'package:code_learn_app/models/note.dart';
import 'package:code_learn_app/services/offline_content_pack_service.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/share_service.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/widgets/code_block_body.dart';
import 'package:code_learn_app/widgets/quiz_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// P1 功能回归：学习时长、笔记标签、代码显示设置、内容包增量更新与无障碍。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('学习时长', () {
    test('按天累计、忽略抖动、单次封顶并可恢复', () async {
      final storage = StorageService.inMemory();
      final progress = ProgressProvider(storage);

      await progress.addStudySeconds('a', 300);
      expect(progress.studySecondsToday, 300);
      expect(progress.totalStudyMinutes, 5);
      expect(progress.dailyStudyMinutes(3).last, 5);

      await progress.addStudySeconds('a', 3);
      expect(progress.studySecondsToday, 300, reason: '低于 5 秒的抖动应忽略');

      await progress.addStudySeconds('a', 999999);
      expect(progress.studySecondsToday, 300 + 7200, reason: '单次最多计入 2 小时');

      final restored = ProgressProvider(storage);
      expect(restored.studySecondsToday, 300 + 7200);
      expect(restored.studyMinutesInLastDays(7), greaterThan(0));
    });
  });

  group('笔记标签', () {
    test('标签去重、按标签筛选与 JSON 往返', () async {
      final progress = ProgressProvider(StorageService.inMemory());
      await progress.saveNote(
        'binary_search',
        '二分查找要注意左右边界的开闭区间。',
        tags: <String>['算法', '算法', '易错'],
      );

      final note = progress.notes.values.single;
      expect(note.tags, <String>['算法', '易错']);
      expect(progress.searchNotes('二分').single.lessonId, 'binary_search');
      expect(progress.searchNotes('', tag: '易错').length, 1);
      expect(progress.searchNotes('', tag: '不存在'), isEmpty);

      await progress.saveNote('sorting', '排序算法笔记', tags: <String>['算法']);
      expect(progress.allNoteTags.first, '算法', reason: '按使用频率排序');

      final roundTrip = Note.fromJson(note.toJson());
      expect(roundTrip.tags, <String>['算法', '易错']);
    });
  });

  group('代码显示设置', () {
    test('字号夹紧、换行开关与学习目标持久化', () async {
      final storage = StorageService.inMemory();
      final settings = SettingsProvider(storage);

      await settings.setCodeFontScale(5);
      expect(settings.codeFontScale, 1.6);
      await settings.setCodeFontScale(0.1);
      expect(settings.codeFontScale, 0.8);
      await settings.setCodeWrapLines(true);
      await settings.setSelectedPathId('python');

      final restored = SettingsProvider(storage);
      expect(restored.codeFontScale, closeTo(0.8, 0.001));
      expect(restored.codeWrapLines, isTrue);
      expect(restored.selectedPathId, 'python');
    });
  });

  group('内容包完整性', () {
    Map<String, dynamic> pack({
      String version = '1.0',
      List<Map<String, dynamic>>? lessons,
      Map<String, dynamic>? delta,
    }) {
      return <String, dynamic>{
        'schema': OfflineContentPackService.schema,
        'schema_version': OfflineContentPackService.schemaVersion,
        'pack_id': 'p1-pack',
        'name': 'P1 Pack',
        'version': version,
        'lessons':
            lessons ??
            <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'lesson_a',
                'category_id': 'python',
                'title': <String, String>{'zh': '课程 A', 'en': 'Lesson A'},
                'summary': <String, String>{'zh': '摘要', 'en': 'Summary'},
                'markdown': '# A',
              },
            ],
        'delta': ?delta,
      };
    }

    test('校验和与签名验证，篡改内容会被拒绝', () {
      final service = OfflineContentPackService();
      final content = pack();
      final signed = <String, dynamic>{
        ...content,
        'checksum': 'sha256:${OfflineContentPackService.checksumOf(content)}',
        'signature': OfflineContentPackService.signWithKey(content),
      };

      expect(OfflineContentPackService.verifyChecksum(signed), isTrue);
      expect(OfflineContentPackService.verifySignature(signed), isTrue);
      expect(service.decode(jsonEncode(signed))['pack_id'], 'p1-pack');

      final tampered = jsonDecode(jsonEncode(signed)) as Map<String, dynamic>;
      (tampered['lessons'] as List).first['markdown'] = '# hacked';
      expect(
        () => service.decode(jsonEncode(tampered)),
        throwsA(
          isA<ContentPackException>().having(
            (error) => error.message,
            'message',
            'checksum_failed',
          ),
        ),
      );
    });

    test('版本比较与 delta 增量合并', () {
      final service = OfflineContentPackService();
      expect(OfflineContentPackService.compareVersions('1.10.0', '1.9.9'), 1);
      expect(OfflineContentPackService.compareVersions('2.0', '2.0.0'), 0);
      expect(OfflineContentPackService.compareVersions('1.9', '2.0'), -1);

      final existing = pack(
        lessons: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'lesson_a',
            'category_id': 'python',
            'title': <String, String>{'zh': '旧 A', 'en': 'Old A'},
            'summary': <String, String>{'zh': '摘要', 'en': 'Summary'},
            'markdown': '# old',
          },
          <String, dynamic>{
            'id': 'lesson_b',
            'category_id': 'python',
            'title': <String, String>{'zh': '课程 B', 'en': 'Lesson B'},
            'summary': <String, String>{'zh': '摘要', 'en': 'Summary'},
            'markdown': '# B',
          },
        ],
      );
      final delta = pack(
        version: '1.1',
        delta: <String, dynamic>{
          'base_version': '1.0',
          'removed_lesson_ids': <String>['lesson_b'],
        },
        lessons: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'lesson_a',
            'category_id': 'python',
            'title': <String, String>{'zh': '新 A', 'en': 'New A'},
            'summary': <String, String>{'zh': '摘要', 'en': 'Summary'},
            'markdown': '# new',
          },
          <String, dynamic>{
            'id': 'lesson_c',
            'category_id': 'python',
            'title': <String, String>{'zh': '课程 C', 'en': 'Lesson C'},
            'summary': <String, String>{'zh': '摘要', 'en': 'Summary'},
            'markdown': '# C',
          },
        ],
      );

      final merged = service.mergeForImport(existing, delta);
      expect(merged.delta, isTrue);
      expect(merged.added, 1);
      expect(merged.updated, 1);
      expect(merged.removed, 1);
      final ids = (merged.pack['lessons'] as List)
          .map((item) => (item as Map)['id'])
          .toSet();
      expect(ids, <String>{'lesson_a', 'lesson_c'});
      expect(merged.pack['version'], '1.1');
      expect(
        () => service.mergeForImport(
          existing,
          pack(version: '1.2', delta: <String, dynamic>{'base_version': '9.9'}),
        ),
        throwsA(isA<ContentPackException>()),
      );
    });
  });

  group('分享服务', () {
    test('平台通道不可用时返回 false，交给调用方复制兜底', () async {
      final service = ShareService(
        channel: MethodChannel('code_learn_app/test_share'),
      );
      expect(await service.shareText('int main() {}'), isFalse);
      expect(await service.shareText('   '), isFalse);
    });
  });

  group('无障碍与代码显示', () {
    Future<void> pumpWithScale(
      WidgetTester tester,
      Widget child,
      double scale,
    ) {
      return tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(StorageService.inMemory()),
          child: MaterialApp(
            builder: (context, widget) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: widget!,
            ),
            home: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      );
    }

    testWidgets('2 倍字号下选项不溢出并显示文字徽标', (tester) async {
      await pumpWithScale(
        tester,
        QuizOptionTile(
          label: '在二分查找中，当目标值小于中间元素时应该执行哪一步操作？',
          index: 0,
          selected: false,
          correct: true,
          answered: true,
          onTap: (_) {},
        ),
        2.0,
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('正确'), findsOneWidget);
    });

    testWidgets('代码块换行模式隐藏横向滚动', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CodeBlockBody(
              source: 'const value = computeSomething(alpha, beta, gamma);',
              fontSize: 13,
              wrapLines: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final scrollViews = tester.widgetList<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(
        scrollViews.any((view) => view.scrollDirection == Axis.horizontal),
        isFalse,
      );
    });
  });
}
