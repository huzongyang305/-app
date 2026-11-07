import 'package:code_learn_app/models/backup_preview.dart';
import 'package:code_learn_app/models/code_snippet.dart';
import 'package:code_learn_app/services/backup_bundle_service.dart';
import 'package:code_learn_app/services/backup_document_service.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/sandbox_draft_service.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/snippet_service.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('完整备份包', () {
    test('导出包含设置、片段、草稿与阅读位置', () async {
      final device = _Device(StorageService.inMemory());
      await device.progress.markLearned('lesson_a');
      await device.progress.saveReadingOffset('lesson_a', 128);
      await device.settings.setThemeMode(ThemeMode.dark);
      await device.settings.setDailyGoalMinutes(45);
      await device.snippets.upsert(
        languageId: 'python',
        title: '源片段',
        code: 'print(1)',
        now: DateTime(2026, 1, 1),
      );
      await device.drafts.save('python', code: 'print(2)');

      final data = device.bundle.buildExportData();

      expect(data['format'], BackupDocumentService.format);
      expect((data['settings'] as Map)['daily_goal_minutes'], 45);
      expect(data['snippets'] as List, hasLength(1));
      expect((data['sandbox_drafts'] as Map)['python']['code'], 'print(2)');
      final reading = data['reading'] as Map;
      expect(reading['last_lesson_id'], 'lesson_a');
      expect((reading['offsets'] as Map)['lesson_a'], 128);

      final preview = BackupPreview.fromData(data);
      expect(preview.settings, greaterThan(0));
      expect(preview.snippets, 1);
      expect(preview.sandboxDrafts, 1);
    });

    test('替换恢复会还原设置、片段、草稿与阅读位置', () async {
      final source = _Device(StorageService.inMemory());
      await source.progress.markLearned('lesson_a');
      await source.progress.saveReadingOffset('lesson_a', 128);
      await source.settings.setThemeMode(ThemeMode.dark);
      await source.settings.setDailyGoalMinutes(45);
      await source.snippets.upsert(
        languageId: 'python',
        title: '源片段',
        code: 'print(1)',
        now: DateTime(2026, 1, 1),
      );
      await source.drafts.save('python', code: 'print(2)');
      final dump = source.bundle.buildExportData();

      final target = _Device(StorageService.inMemory());
      await target.bundle.restore(dump);

      expect(target.progress.isLearned('lesson_a'), isTrue);
      expect(target.progress.readingOffset('lesson_a'), 128);
      expect(target.progress.lastLessonId, 'lesson_a');
      expect(target.settings.themeMode, ThemeMode.dark);
      expect(target.settings.dailyGoalMinutes, 45);
      expect(target.snippets.snippets.single.title, '源片段');
      expect(target.drafts.forLanguage('python')!.code, 'print(2)');
    });

    test('合并恢复保留本机偏好与草稿，片段按 id 取较新版本', () async {
      final source = _Device(StorageService.inMemory());
      await source.progress.markLearned('lesson_a');
      await source.progress.saveReadingOffset('lesson_a', 128);
      await source.settings.setThemeMode(ThemeMode.dark);
      await source.drafts.save('python', code: 'source');
      await _seedSnippets(source.storage, <CodeSnippet>[
        _snippet('s1', '远端旧版', DateTime(2026, 1, 1)),
        _snippet('s3', '远端新增', DateTime(2026, 1, 2)),
      ]);
      final dump = source.bundle.buildExportData();

      final target = _Device(StorageService.inMemory());
      await target.progress.markLearned('lesson_b');
      await target.progress.saveReadingOffset('local_lesson', 10);
      await target.settings.setThemeMode(ThemeMode.light);
      await target.drafts.save('python', code: 'local');
      await _seedSnippets(target.storage, <CodeSnippet>[
        _snippet('s1', '本机新版', DateTime(2026, 2, 1)),
        _snippet('s2', '本机独有', DateTime(2026, 2, 2)),
      ]);

      await target.bundle.restore(dump, mode: BackupImportMode.merge);

      expect(target.progress.isLearned('lesson_a'), isTrue);
      expect(target.progress.isLearned('lesson_b'), isTrue);
      expect(target.settings.themeMode, ThemeMode.light);
      expect(target.drafts.forLanguage('python')!.code, 'local');
      expect(target.progress.lastLessonId, 'lesson_b');
      expect(target.progress.readingOffset('local_lesson'), 10);
      expect(target.progress.readingOffset('lesson_a'), 128);
      final titles = target.snippets.snippets
          .map((item) => '${item.id}:${item.title}')
          .toSet();
      expect(titles, containsAll(<String>{'s1:本机新版', 's2:本机独有', 's3:远端新增'}));
    });

    test('旧版进度备份不会清空设置、片段与草稿', () async {
      final source = _Device(StorageService.inMemory());
      await source.progress.markLearned('lesson_from_backup');
      final legacy = Map<String, dynamic>.from(source.bundle.buildExportData())
        ..remove('settings')
        ..remove('snippets')
        ..remove('sandbox_drafts')
        ..remove('reading');

      final target = _Device(StorageService.inMemory());
      await target.settings.setThemeMode(ThemeMode.dark);
      await target.snippets.upsert(
        languageId: 'python',
        title: '本机片段',
        code: 'print(1)',
        now: DateTime(2026, 1, 1),
      );
      await target.drafts.save('python', code: 'local');

      await target.bundle.restore(legacy);

      expect(target.progress.isLearned('lesson_from_backup'), isTrue);
      expect(target.settings.themeMode, ThemeMode.dark);
      expect(target.snippets.snippets.single.title, '本机片段');
      expect(target.drafts.forLanguage('python')!.code, 'local');
    });

    test('回滚恢复导入前的完整状态', () async {
      final device = _Device(StorageService.inMemory());
      await device.progress.markLearned('lesson_before');
      await device.settings.setThemeMode(ThemeMode.dark);
      await device.snippets.upsert(
        languageId: 'python',
        title: '导入前片段',
        code: 'print(1)',
        now: DateTime(2026, 1, 1),
      );
      await device.drafts.save('python', code: 'before');

      final source = _Device(StorageService.inMemory());
      await source.progress.markLearned('lesson_from_backup');
      await source.settings.setThemeMode(ThemeMode.light);
      await source.snippets.upsert(
        languageId: 'python',
        title: '备份片段',
        code: 'print(2)',
        now: DateTime(2026, 1, 2),
      );
      await source.drafts.save('python', code: 'backup');

      await device.bundle.restore(source.bundle.buildExportData());
      expect(device.progress.isLearned('lesson_before'), isFalse);
      expect(device.progress.isLearned('lesson_from_backup'), isTrue);
      expect(device.settings.themeMode, ThemeMode.light);
      expect(device.snippets.snippets.single.title, '备份片段');

      expect(await device.bundle.rollbackLastImport(), isTrue);

      expect(device.progress.isLearned('lesson_before'), isTrue);
      expect(device.progress.isLearned('lesson_from_backup'), isFalse);
      expect(device.settings.themeMode, ThemeMode.dark);
      expect(device.snippets.snippets.single.title, '导入前片段');
      expect(device.drafts.forLanguage('python')!.code, 'before');
      expect(device.bundle.hasRollbackSnapshot, isFalse);
    });

    test('拒绝未知格式的备份文件', () async {
      final device = _Device(StorageService.inMemory());
      await expectLater(
        device.bundle.restore(<String, dynamic>{
          'format': 'other-app',
          'schema_version': 2,
        }),
        throwsA(isA<BackupDocumentException>()),
      );
    });
  });
}

class _Device {
  _Device(this.storage)
    : settings = SettingsProvider(storage),
      progress = ProgressProvider(storage);

  final StorageService storage;
  final SettingsProvider settings;
  final ProgressProvider progress;

  late final BackupBundleService bundle = BackupBundleService(
    storage,
    progress,
    settings,
  );

  SnippetService get snippets => SnippetService(storage);

  SandboxDraftService get drafts => SandboxDraftService(storage);
}

CodeSnippet _snippet(String id, String title, DateTime updatedAt) =>
    CodeSnippet(
      id: id,
      languageId: 'python',
      title: title,
      code: 'print("$id")',
      createdAt: updatedAt,
      updatedAt: updatedAt,
    );

Future<void> _seedSnippets(StorageService storage, List<CodeSnippet> items) =>
    storage.write(
      'sandbox_snippets',
      items.map((item) => item.toJson()).toList(),
    );
