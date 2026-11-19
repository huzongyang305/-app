import 'package:code_learn_app/services/home_widget_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 桌面小组件快照服务：编码格式、写入去重与点击跳转。
///
/// 原生侧的契约是「shared_preferences 里的一个字符串」，
/// 编码一旦改动，Android 的 `ReviewWidgetProvider.parse` 就会退化成占位文案，
/// 因此这里的字段顺序与数量都要钉死。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/home_widget');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // 静态跳转队列跨用例共享，先清空再测。
    HomeWidgetService.consumePendingRoute();
    messenger.setMockMethodCallHandler(channel, null);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('快照编码', () {
    test('载荷顺序与 Android 侧解析一致：v1|题|卡|天|分钟|目标|时间戳', () {
      const snapshot = HomeWidgetSnapshot(
        dueQuestions: 7,
        dueFlashcards: 3,
        streakDays: 12,
        minutesToday: 25,
        goalMinutes: 40,
      );
      expect(snapshot.encode(1700000000000), 'v1|7|3|12|25|40|1700000000000');
      expect(snapshot.encode(0).split('|'), hasLength(7));
    });

    test('负数按 0 处理，目标至少 1 分钟', () {
      final snapshot = HomeWidgetSnapshot.normalized(
        dueQuestions: -5,
        dueFlashcards: -1,
        streakDays: -3,
        minutesToday: -2,
        goalMinutes: 0,
      );
      expect(snapshot.signature, '0|0|0|0|1');
    });

    test('签名只含数字，不含时间戳', () {
      const snapshot = HomeWidgetSnapshot(
        dueQuestions: 1,
        dueFlashcards: 2,
        streakDays: 3,
        minutesToday: 4,
        goalMinutes: 5,
      );
      expect(
        snapshot.signature,
        snapshot
            .encode(DateTime.now().millisecondsSinceEpoch)
            .split('|')
            .sublist(1, 6)
            .join('|'),
      );
    });
  });

  group('快照写入', () {
    test('首次写入落盘并请求原生刷新，数字未变时第二次直接跳过', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });
      final service = HomeWidgetService(
        channel: channel,
        clock: () async => DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      const snapshot = HomeWidgetSnapshot(
        dueQuestions: 2,
        dueFlashcards: 4,
        streakDays: 9,
        minutesToday: 15,
        goalMinutes: 30,
      );
      expect(await service.sync(snapshot), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(HomeWidgetService.snapshotKey),
        'v1|2|4|9|15|30|1700000000000',
      );
      expect(calls.map((call) => call.method), ['refresh']);

      // 同一组数字再同步一次：不写盘、也不再打扰原生。
      expect(await service.sync(snapshot), isFalse);
      expect(calls, hasLength(1));

      // 数字变了才重写。
      expect(
        await service.sync(
          HomeWidgetSnapshot.normalized(
            dueQuestions: 3,
            dueFlashcards: 4,
            streakDays: 9,
            minutesToday: 15,
            goalMinutes: 30,
          ),
        ),
        isTrue,
      );
      expect(calls, hasLength(2));
    });

    test('原生不可用时静默降级，不抛异常', () async {
      final service = HomeWidgetService(
        channel: const MethodChannel('test/home_widget_missing'),
      );
      expect(
        await service.sync(
          HomeWidgetSnapshot.normalized(
            dueQuestions: 1,
            dueFlashcards: 1,
            streakDays: 1,
            minutesToday: 1,
            goalMinutes: 1,
          ),
        ),
        isFalse,
      );
      expect(service.isAvailable, isFalse);
    });
  });

  group('点击跳转', () {
    test('冷启动时从原生取回启动路由', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'takeLaunchRoute') return 'review';
        return null;
      });
      final service = HomeWidgetService(channel: channel);
      await service.init();
      expect(service.isAvailable, isTrue);
      expect(HomeWidgetService.consumePendingRoute(), 'review');
      expect(HomeWidgetService.consumePendingRoute(), isNull);
    });

    test('前台运行时原生推送 onRoute 会被排队', () async {
      final service = HomeWidgetService(channel: channel);
      await service.init();
      await messenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onRoute', 'daily_question'),
        ),
        null,
      );
      expect(HomeWidgetService.pendingRoute.value, 'daily_question');
      expect(HomeWidgetService.consumePendingRoute(), 'daily_question');
    });

    test('空路由与无关方法都不产生跳转', () async {
      final service = HomeWidgetService(channel: channel);
      await service.init();
      for (final arguments in <Object?>['', null]) {
        await messenger.handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onRoute', arguments),
          ),
          null,
        );
        expect(HomeWidgetService.consumePendingRoute(), isNull);
      }
      await messenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('other', 'review'),
        ),
        null,
      );
      expect(HomeWidgetService.consumePendingRoute(), isNull);
    });
  });
}
