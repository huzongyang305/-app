import 'dart:convert';

import 'package:code_learn_app/models/backup_preview.dart';
import 'package:code_learn_app/services/backup_bundle_service.dart';
import 'package:code_learn_app/services/backup_document_service.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/services/webdav_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 假传输层：按脚本返回状态码与响应体，并记录每次 PUT 的内容。
class _FakeTransport extends WebDavTransport {
  _FakeTransport();

  int remoteStatus = 404;
  String remoteBody = '';
  int putStatus = 200;

  final List<String> uploads = <String>[];
  final List<String> requested = <String>[];
  String? lastAuth;

  @override
  Future<WebDavReply> get(Uri uri, {String? username, String? password}) async {
    requested.add('GET $uri');
    lastAuth = username == null
        ? null
        : base64Encode(utf8.encode('$username:$password'));
    return WebDavReply(remoteStatus, remoteBody);
  }

  @override
  Future<WebDavReply> put(
    Uri uri,
    String body, {
    String? username,
    String? password,
  }) async {
    requested.add('PUT $uri');
    uploads.add(body);
    return WebDavReply(putStatus, '');
  }
}

void main() {
  const endpoint = 'https://dav.example.com/code_learn/backup.json';

  late StorageService storage;
  late ProgressProvider progress;
  late SettingsProvider settings;
  late BackupBundleService bundle;
  late _FakeTransport transport;
  late WebDavSyncService service;

  setUp(() {
    storage = StorageService.inMemory();
    progress = ProgressProvider(storage);
    settings = SettingsProvider(storage);
    bundle = BackupBundleService(storage, progress, settings);
    transport = _FakeTransport();
    service = WebDavSyncService(storage, transport: transport);
  });

  Future<void> configure({
    String url = endpoint,
    String username = 'me',
    String password = 'secret',
    bool enabled = true,
    bool autoSync = false,
  }) => service.saveConfig(
    endpoint: url,
    username: username,
    password: password,
    enabled: enabled,
    autoSync: autoSync,
  );

  group('WebDAV 同步', () {
    test('远端没有文件时首次上传本机备份', () async {
      await configure();
      await progress.markLearned('lesson_a');

      final outcome = await service.sync(
        buildBundle: bundle.buildExportData,
        applyRemote: (remote) =>
            bundle.restore(remote, mode: BackupImportMode.merge),
      );

      expect(outcome.pulledFirstTime, isTrue);
      expect(outcome.merged, isFalse);
      expect(transport.uploads, hasLength(1));
      final uploaded = jsonDecode(transport.uploads.single) as Map;
      expect(uploaded['format'], BackupDocumentService.format);
      expect(uploaded['learned_ids'], contains('lesson_a'));
      expect(service.lastStatus, 'created');
      expect(service.lastSyncAt, isNotNull);
      expect(service.lastBytes, transport.uploads.single.length);
    });

    test('远端已有另一台设备的数据时双向合并', () async {
      final other = StorageService.inMemory();
      final otherProgress = ProgressProvider(other);
      await otherProgress.markLearned('lesson_b');
      final otherBundle = BackupBundleService(
        other,
        otherProgress,
        SettingsProvider(other),
      );

      await configure();
      await progress.markLearned('lesson_a');
      transport.remoteStatus = 200;
      transport.remoteBody = jsonEncode(otherBundle.buildExportData());

      final outcome = await service.sync(
        buildBundle: bundle.buildExportData,
        applyRemote: (remote) =>
            bundle.restore(remote, mode: BackupImportMode.merge),
      );

      expect(outcome.merged, isTrue);
      expect(outcome.pulledFirstTime, isFalse);
      expect(
        progress.learnedIds,
        containsAll(<String>['lesson_a', 'lesson_b']),
      );
      final uploaded = jsonDecode(transport.uploads.single) as Map;
      expect(
        (uploaded['learned_ids'] as List).cast<String>(),
        containsAll(<String>['lesson_a', 'lesson_b']),
      );
      expect(service.lastStatus, 'merged');
    });

    test('凭据被拒时不写远端也不改本机', () async {
      await configure();
      await progress.markLearned('lesson_a');
      transport.remoteStatus = 401;

      await expectLater(
        service.sync(
          buildBundle: bundle.buildExportData,
          applyRemote: (remote) =>
              bundle.restore(remote, mode: BackupImportMode.merge),
        ),
        throwsA(
          isA<WebDavSyncException>()
              .having((e) => e.code, 'code', 'webdav_unauthorized')
              .having((e) => e.status, 'status', 401),
        ),
      );
      expect(transport.uploads, isEmpty);
      expect(service.lastStatus, 'webdav_unauthorized');
    });

    test('远端不是备份格式时停止并保留本机数据', () async {
      await configure();
      await progress.markLearned('lesson_a');
      transport.remoteStatus = 200;
      transport.remoteBody = '<html>登录页</html>';

      await expectLater(
        service.sync(
          buildBundle: bundle.buildExportData,
          applyRemote: (remote) =>
              bundle.restore(remote, mode: BackupImportMode.merge),
        ),
        throwsA(
          isA<WebDavSyncException>().having(
            (e) => e.code,
            'code',
            'webdav_bad_backup',
          ),
        ),
      );
      expect(transport.uploads, isEmpty);
      expect(progress.learnedIds, contains('lesson_a'));
    });

    test('请求带上 Basic 认证', () async {
      await configure(username: 'me', password: 'secret');
      await service.sync(
        buildBundle: bundle.buildExportData,
        applyRemote: (remote) =>
            bundle.restore(remote, mode: BackupImportMode.merge),
      );
      expect(transport.lastAuth, base64Encode(utf8.encode('me:secret')));
    });

    test('明文 HTTP 配密码直接拒绝，不发请求', () async {
      await configure(url: 'http://192.168.1.5/dav/backup.json');

      await expectLater(
        service.sync(
          buildBundle: bundle.buildExportData,
          applyRemote: (remote) =>
              bundle.restore(remote, mode: BackupImportMode.merge),
        ),
        throwsA(
          isA<WebDavSyncException>().having(
            (e) => e.code,
            'code',
            'webdav_insecure_url',
          ),
        ),
      );
      expect(transport.requested, isEmpty);
    });

    test('匿名 http 目录允许同步', () async {
      await configure(
        url: 'http://192.168.1.5/dav/backup.json',
        username: '',
        password: '',
      );
      final outcome = await service.sync(
        buildBundle: bundle.buildExportData,
        applyRemote: (remote) =>
            bundle.restore(remote, mode: BackupImportMode.merge),
      );
      expect(transport.uploads, hasLength(1));
      expect(outcome.pulledFirstTime, isTrue);
    });

    test('密码留空表示沿用已保存的密码', () async {
      await configure(password: 'first');
      await service.saveConfig(
        endpoint: endpoint,
        username: 'me',
        password: '',
        enabled: true,
        autoSync: true,
      );
      expect(service.readConfig().password, 'first');
      expect(service.readConfig().autoSync, isTrue);
    });

    test('自动同步只在满一天后触发', () async {
      final now = DateTime(2026, 11, 10, 9);
      expect(service.isAutoSyncDue(now), isFalse);

      await configure(autoSync: true);
      expect(service.isAutoSyncDue(now), isTrue);

      await service.sync(
        buildBundle: bundle.buildExportData,
        applyRemote: (remote) =>
            bundle.restore(remote, mode: BackupImportMode.merge),
        at: now,
      );
      expect(
        service.isAutoSyncDue(now.add(const Duration(hours: 23))),
        isFalse,
      );
      expect(service.isAutoSyncDue(now.add(const Duration(hours: 25))), isTrue);

      await service.saveConfig(
        endpoint: endpoint,
        username: 'me',
        password: '',
        enabled: false,
        autoSync: true,
      );
      expect(service.isAutoSyncDue(now.add(const Duration(days: 3))), isFalse);
    });

    test('测试连接只读不写', () async {
      await configure();
      transport.remoteStatus = 200;
      transport.remoteBody = jsonEncode(bundle.buildExportData());
      await service.testConnection();
      expect(transport.requested, hasLength(1));
      expect(transport.uploads, isEmpty);
    });

    test('文件尚未生成时测试连接也算成功', () async {
      await configure();
      transport.remoteStatus = 404;
      await service.testConnection();
      expect(transport.uploads, isEmpty);
    });
  });
}
