import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 桌面小组件「每日复习」需要展示的五个数字。
@immutable
class HomeWidgetSnapshot {
  const HomeWidgetSnapshot({
    required this.dueQuestions,
    required this.dueFlashcards,
    required this.streakDays,
    required this.minutesToday,
    required this.goalMinutes,
  });

  final int dueQuestions;
  final int dueFlashcards;
  final int streakDays;
  final int minutesToday;
  final int goalMinutes;

  /// 负数按 0 处理、目标至少 1 分钟：小组件没有「负到期」这种状态可显示。
  factory HomeWidgetSnapshot.normalized({
    required int dueQuestions,
    required int dueFlashcards,
    required int streakDays,
    required int minutesToday,
    required int goalMinutes,
  }) {
    return HomeWidgetSnapshot(
      dueQuestions: dueQuestions < 0 ? 0 : dueQuestions,
      dueFlashcards: dueFlashcards < 0 ? 0 : dueFlashcards,
      streakDays: streakDays < 0 ? 0 : streakDays,
      minutesToday: minutesToday < 0 ? 0 : minutesToday,
      goalMinutes: goalMinutes < 1 ? 1 : goalMinutes,
    );
  }

  /// 数字部分，用于判断「值有没有变」；时间戳不参与比较。
  String get signature =>
      '$dueQuestions|$dueFlashcards|$streakDays|$minutesToday|$goalMinutes';

  /// 与 Android 侧 `ReviewWidgetProvider.parse` 一一对应的载荷串。
  ///
  /// 刻意用单个字符串而不是多个 int 键：shared_preferences 的数字类型
  /// 在原生侧的落盘形式不保证，读的时候 `getInt` 容易踩到类型不符。
  String encode(int updatedAtMs) => 'v1|$signature|$updatedAtMs';
}

/// 把 App 内状态同步到桌面小组件，并接收小组件点击带来的跳转。
///
/// 非 Android 环境与单元测试里没有原生实现，所有调用都静默降级，
/// 与 [NotificationService] 的处理方式一致。
class HomeWidgetService {
  HomeWidgetService({
    MethodChannel? channel,
    Future<DateTime> Function()? clock,
  }) : _channel = channel ?? const MethodChannel(channelName),
       _clock = clock ?? (() async => DateTime.now());

  static const String channelName = 'code_learn_app/home_widget';

  /// shared_preferences 在 Android 侧会自动加 `flutter.` 前缀，
  /// 原生读取时使用 `flutter.widget_review_snapshot`。
  static const String snapshotKey = 'widget_review_snapshot';

  /// 小组件点击后的跳转目标（review / daily_question）。
  ///
  /// 与通知点击共用一套取值，冷启动时靠静态字段留住结果。
  static final ValueNotifier<String?> pendingRoute = ValueNotifier<String?>(
    null,
  );
  static String? _pendingRoute;

  static void _queueRoute(String? route) {
    if (route == null || route.isEmpty) return;
    _pendingRoute = route;
    pendingRoute.value = route;
  }

  /// 取出并清空待处理的跳转目标，没有时返回 null。
  static String? consumePendingRoute() {
    final value = _pendingRoute;
    _pendingRoute = null;
    if (pendingRoute.value != null) {
      pendingRoute.value = null;
    }
    return value;
  }

  final MethodChannel _channel;
  final Future<DateTime> Function() _clock;

  String? _lastSignature;
  bool _syncing = false;
  bool _isAvailable = false;

  /// 最近一次同步是否成功写入了原生侧（决定小组件是否可能显示旧数据）。
  bool get isAvailable => _isAvailable;

  /// 注册原生回调，并取回冷启动时小组件带来的跳转目标。
  Future<void> init() async {
    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onRoute') {
          _queueRoute(
            call.arguments is String ? call.arguments as String : null,
          );
        }
        return null;
      });
      final launchRoute = await _channel.invokeMethod<String>(
        'takeLaunchRoute',
      );
      _queueRoute(launchRoute);
      _isAvailable = true;
    } on MissingPluginException {
      _isAvailable = false;
    } on PlatformException {
      _isAvailable = false;
    }
  }

  /// 写入快照并请求原生立即重绘；数字没变时直接跳过。
  ///
  /// 返回值表示这次是否真的写了盘，便于调用方（和测试）判断有没有做无用功。
  Future<bool> sync(HomeWidgetSnapshot snapshot) async {
    final signature = snapshot.signature;
    if (_syncing || signature == _lastSignature) return false;
    _syncing = true;
    try {
      final now = await _clock();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        snapshotKey,
        snapshot.encode(now.millisecondsSinceEpoch),
      );
      await _channel.invokeMethod<bool>('refresh');
      _lastSignature = signature;
      _isAvailable = true;
      return true;
    } on MissingPluginException {
      // 桌面端与测试环境：只记签名，避免每帧都重试一次注定失败的写入。
      _lastSignature = signature;
      _isAvailable = false;
      return false;
    } on PlatformException catch (error) {
      debugPrint('桌面小组件快照写入失败：$error');
      _isAvailable = false;
      return false;
    } finally {
      _syncing = false;
    }
  }
}
