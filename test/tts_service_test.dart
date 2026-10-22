import 'package:code_learn_app/services/tts_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// TTS 服务测试：覆盖 Markdown 清洗与无原生插件时的离线降级。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(TtsService.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('prepareSpeechText 移除代码块与 Markdown 标记', () {
    const markdown = '''
# 标题

![示意图](images/demo.webp)

[参考文档](https://example.com) 与 `行内代码`

```python
print("hello")
```

正文内容
''';
    final text = TtsService.prepareSpeechText(markdown);

    expect(text, contains('标题'));
    expect(text, contains('示意图'));
    expect(text, contains('参考文档'));
    expect(text, contains('代码示例。'));
    expect(text, contains('正文内容'));
    expect(text, isNot(contains('print')));
    expect(text, isNot(contains('```')));
  });

  test('英文朗读使用英文代码占位符', () async {
    String? captured;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'speak') {
        captured = (call.arguments as Map)['text'] as String;
      }
      return true;
    });

    const service = TtsService();
    final ok = await service.speak(
      text: '```js\nlet answer = 1;\n```',
      localeCode: 'en',
    );

    expect(ok, isTrue);
    expect(captured, contains('Code example.'));
    expect(captured, isNot(contains('let answer')));
  });

  test('MissingPluginException 时静默降级', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw MissingPluginException('no tts engine in test environment');
    });

    const service = TtsService();
    expect(await service.isAvailable(), isFalse);
    expect(await service.speak(text: '正文', localeCode: 'zh'), isFalse);
    await service.stop();
  });

  test('只有注释或空白时 speak 直接返回 false', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      return true;
    });

    const service = TtsService();
    expect(
      await service.speak(text: '<!-- 仅注释 -->', localeCode: 'zh'),
      isFalse,
    );
    expect(calls, 0);
  });

  test('原生层可用时 isAvailable 返回 true', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => true);

    const service = TtsService();
    expect(await service.isAvailable(), isTrue);
  });
}
