import 'dart:io';

import 'package:code_learn_app/services/backup_document_service.dart';
import 'package:code_learn_app/services/backup_file_service.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/storage_migration_service.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P5A 备份文件通道', () {
    const channel = MethodChannel('test_backup_files');
    const service = BackupFileService(channel: channel);

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('另存为会传递内容和建议文件名', () async {
      MethodCall? received;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            received = call;
            return true;
          });

      final saved = await service.saveBackup(
        payload: '{"format":"code-learn-backup"}',
        suggestedName: 'backup.json',
      );

      expect(saved, isTrue);
      expect(received?.method, 'saveBackup');
      expect(received?.arguments['suggestedName'], 'backup.json');
    });

    test('文件选择器可返回备份，取消返回 null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'openBackup');
            return '{"learned_ids":["a"]}';
          });
      expect(await service.openBackup(), contains('learned_ids'));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => null);
      expect(await service.openBackup(), isNull);
    });

    test('分享会打开系统分享通道', () async {
      MethodCall? received;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            received = call;
            return true;
          });

      expect(
        await service.shareBackup(
          payload: '{"a":1}',
          suggestedName: 'backup.json',
        ),
        isTrue,
      );
      expect(received?.method, 'shareBackup');
    });

    test('空备份和超限备份在 Dart 侧直接拒绝', () {
      expect(
        () => service.saveBackup(payload: '', suggestedName: 'backup.json'),
        throwsA(isA<BackupFileException>()),
      );
      expect(
        () => service.shareBackup(
          payload: List<String>.filled(
            BackupFileService.maxBackupBytes + 1,
            'x',
          ).join(),
          suggestedName: 'backup.json',
        ),
        throwsA(isA<BackupFileException>()),
      );
    });
  });

  group('P5A 备份版本', () {
    test('导出写入格式和版本，旧裸 JSON 仍可导入', () async {
      final storage = StorageService.inMemory();
      final progress = ProgressProvider(storage);
      await progress.markLearned('python_first_script');

      final exported = progress.exportData();
      expect(exported['format'], BackupDocumentService.format);
      expect(exported['schema_version'], BackupDocumentService.currentVersion);
      expect(exported['exported_at'], isA<String>());

      final restored = ProgressProvider(StorageService.inMemory());
      await restored.importData(<String, dynamic>{
        'learned_ids': <String>['legacy_lesson'],
      });
      expect(restored.learnedIds, contains('legacy_lesson'));
    });

    test('未来版本备份会被拒绝，避免旧客户端覆盖数据', () {
      expect(
        () => BackupDocumentService.normalizeForImport(<String, dynamic>{
          'format': BackupDocumentService.format,
          'schema_version': BackupDocumentService.currentVersion + 1,
        }),
        throwsA(isA<BackupDocumentException>()),
      );
    });
  });

  group('P5A 存储迁移', () {
    test('旧数据库补写索引并记录 schema 版本', () async {
      final storage = StorageService.inMemory();
      await storage.write('quiz_result_a', <String, dynamic>{'score': 1});
      await storage.write('note_b', <String, dynamic>{'content': 'note'});

      final result = await StorageMigrationService.run(storage);

      expect(result.fromVersion, 0);
      expect(result.toVersion, StorageMigrationService.currentVersion);
      expect(result.migrated, isTrue);
      expect(storage.read('all_quiz_ids'), <String>['a']);
      expect(storage.read('all_note_ids'), <String>['b']);
      expect(
        storage.read(StorageMigrationService.versionKey),
        StorageMigrationService.currentVersion,
      );
    });

    test('迁移幂等且拒绝高于当前客户端的 schema', () async {
      final storage = StorageService.inMemory();
      await StorageMigrationService.run(storage);
      final second = await StorageMigrationService.run(storage);
      expect(second.migrated, isFalse);

      await storage.write(
        StorageMigrationService.versionKey,
        StorageMigrationService.currentVersion + 1,
      );
      expect(
        () => StorageMigrationService.run(storage),
        throwsA(isA<StorageMigrationException>()),
      );
    });
  });

  group('P5A 旧版备份兼容', () {
    test('可从应用文档目录读取旧版备份文件', () async {
      final directory = await Directory.systemTemp.createTemp(
        'code_learn_legacy',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = LegacyBackupStore(
        documentsDirectory: () async => directory,
      );

      expect(await store.readIfExists(), isNull);

      final file = await store.write('{"learned_ids":["a"]}');
      expect(file.path, endsWith(LegacyBackupStore.fileName));
      expect(await store.readIfExists(), contains('learned_ids'));
    });
  });
}
