import 'package:code_learn_app/screens/webdav_sync_screen.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/services/webdav_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 假传输层：固定回复，并统计上传次数与内容。
class _StubTransport extends WebDavTransport {
  _StubTransport(this.reply);

  WebDavReply reply;
  int puts = 0;
  String? lastUpload;

  @override
  Future<WebDavReply> get(
    Uri uri, {
    String? username,
    String? password,
  }) async => reply;

  @override
  Future<WebDavReply> put(
    Uri uri,
    String body, {
    String? username,
    String? password,
  }) async {
    puts++;
    lastUpload = body;
    return const WebDavReply(201, '');
  }
}

void main() {
  const endpoint = 'https://dav.example.com/code_learn/backup.json';

  late _StubTransport transport;
  late WebDavSyncService service;

  Future<void> openScreen(
    WidgetTester tester, {
    String password = 'secret',
  }) async {
    final storage = StorageService.inMemory();
    transport = _StubTransport(const WebDavReply(404, ''));
    service = WebDavSyncService(storage, transport: transport);
    await service.saveConfig(
      endpoint: endpoint,
      username: 'me',
      password: password,
      enabled: false,
      autoSync: false,
    );
    await tester.binding.setSurfaceSize(const Size(420, 940));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
          ChangeNotifierProvider(create: (_) => ProgressProvider(storage)),
        ],
        child: MaterialApp(home: WebDavSyncScreen(service: service)),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool isEnabled(WidgetTester tester, String key) =>
      tester.widget<ButtonStyleButton>(find.byKey(ValueKey(key))).onPressed !=
      null;

  Future<void> enableSync(WidgetTester tester) async {
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
  }

  testWidgets('未启用同步时「立即同步」不可点', (tester) async {
    await openScreen(tester);
    expect(isEnabled(tester, 'webdav-sync'), isFalse);
    expect(isEnabled(tester, 'webdav-save'), isTrue);

    await enableSync(tester);
    expect(isEnabled(tester, 'webdav-sync'), isTrue);
  });

  testWidgets('保存配置后密码不回显，只提示已保存', (tester) async {
    await openScreen(tester);
    // 已存过密码：输入框留空，helper 说明留空即沿用。
    expect(find.text('已保存密码，留空表示不修改'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('webdav-save')));
    await tester.pumpAndSettle();

    expect(find.text('已保存 WebDAV 设置'), findsOneWidget);
    expect(find.text('已保存密码，留空表示不修改'), findsOneWidget);
    final passwordField = tester.widget<TextField>(
      find.byKey(const ValueKey('webdav-password-field')),
    );
    expect(passwordField.controller!.text, isEmpty);
    expect(passwordField.obscureText, isTrue);
  });

  testWidgets('明文 HTTP 地址当场警告，且拒绝带密码访问', (tester) async {
    await openScreen(tester);
    await tester.enterText(
      find.byKey(const ValueKey('webdav-endpoint-field')),
      'http://dav.example.com/backup.json',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('该地址是明文 HTTP'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('webdav-test')));
    await tester.pumpAndSettle();

    expect(find.textContaining('明文 HTTP 不允许携带密码'), findsOneWidget);
    expect(transport.puts, 0);
  });

  testWidgets('凭据被拒时不上传，失败原因留在同步状态里', (tester) async {
    await openScreen(tester);
    transport.reply = const WebDavReply(401, 'Unauthorized');
    await enableSync(tester);

    await tester.tap(find.byKey(const ValueKey('webdav-sync')));
    await tester.pumpAndSettle();

    expect(transport.puts, 0);
    // 弹出的提示和状态区的常驻提示都写着同一条原因。
    expect(find.textContaining('用户名或密码不对'), findsWidgets);
    expect(find.text('还没有成功同步过'), findsOneWidget);
  });

  testWidgets('远端为空时首次同步上传本机备份并记录时间与大小', (tester) async {
    await openScreen(tester);
    await enableSync(tester);
    await tester.tap(find.byKey(const ValueKey('webdav-sync')));
    await tester.pumpAndSettle();

    expect(find.text('同步完成'), findsOneWidget);
    expect(transport.puts, 1);
    expect(transport.lastUpload, contains('code-learn-backup'));
    expect(find.textContaining('上次成功：'), findsOneWidget);
    expect(find.text('还没有成功同步过'), findsNothing);
    expect(service.lastStatus, 'created');
  });

  testWidgets('未保存过密码时提示只存本机，明文地址可不填密码同步', (tester) async {
    await openScreen(tester, password: '');
    expect(find.text('只保存在本机，不会写入日志'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('webdav-endpoint-field')),
      'http://192.168.1.8/backup/code_learn.json',
    );
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('webdav-sync')));
    await tester.pumpAndSettle();

    // 匿名目录允许同步，密码框不会自动带上任何凭据。
    expect(find.text('同步完成'), findsOneWidget);
    expect(transport.puts, 1);
  });
}
