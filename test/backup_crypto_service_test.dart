import 'package:code_learn_app/services/backup_crypto_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test_backup_crypto');
  const service = BackupCryptoService(channel: channel);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('能够识别加密备份信封', () {
    expect(service.isEncrypted('CLB1:abc'), isTrue);
    expect(service.isEncrypted('  CLB1:abc'), isTrue);
    expect(service.isEncrypted('{"learned_ids": []}'), isFalse);
  });

  test('加密请求通过平台通道并返回信封', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return 'CLB1:encrypted';
        });

    final result = await service.encryptJson(<String, dynamic>{
      'learned_ids': <String>['a'],
    }, 'secret123');

    expect(result, 'CLB1:encrypted');
    expect(received?.method, 'encrypt');
    expect(received?.arguments['password'], 'secret123');
  });

  test('解密请求将平台通道返回的 JSON 还原为 Map', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'decrypt');
          return '{"favorite_ids":["a"]}';
        });

    final result = await service.decryptJson('CLB1:payload', 'secret123');

    expect(result['favorite_ids'], <String>['a']);
  });

  test('明文内容不会被误当成加密备份解密', () async {
    expect(
      () => service.decryptText('{"a":1}', 'secret123'),
      throwsA(isA<BackupCryptoException>()),
    );
  });
}
