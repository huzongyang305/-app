import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 本地复习提醒。
///
/// 使用系统本地通知（flutter_local_notifications）在每天固定时间提醒
/// 今日到期的复习内容。整个流程不依赖任何服务器与推送服务，
/// 断网环境下照常工作。
///
/// 插件在单元测试 / 桌面环境下不可用时会自动降级为「静默失活」，
/// 不会影响 App 其余功能。
class NotificationService {
  NotificationService();

  /// 每日提醒使用固定 ID，重复调度会覆盖上一条，不会堆积通知。
  static const int _dailyReviewId = 1001;
  static const String _channelId = 'review_reminder';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _available = false;

  /// 通知能力是否可用（初始化成功且拿到了 Android 插件实例）。
  bool get isAvailable => _available;

  /// 初始化插件、时区与通知渠道，并申请通知权限。
  ///
  /// 失败时只记录日志，不抛出异常，保证 App 能正常启动。
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _configureTimeZone();

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _plugin.initialize(initSettings);

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          // 通知渠道名由系统持久保存，切换语言不会刷新，因此用双语写法。
          '复习提醒 / Review reminder',
          description: '每日复习提醒 / Daily review reminder',
          importance: Importance.defaultImportance,
        ),
      );
      _available = android != null;
    } catch (error) {
      _available = false;
      debugPrint('本地通知不可用，已自动跳过：$error');
    }
  }

  /// 设置本地时区，保证「20:00 提醒」按手机本地时间触发。
  void _configureTimeZone() {
    try {
      tz_data.initializeTimeZones();
    } catch (error) {
      debugPrint('时区数据库初始化失败：$error');
      return;
    }
    // 时区名需要异步获取，先在本地按偏移量兜底，再异步修正。
    _applySystemTimeZone();
  }

  Future<void> _applySystemTimeZone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (error) {
      // 获取失败时沿用 timezone 包的默认（UTC），只影响触发时刻的精度。
      debugPrint('获取本地时区失败，使用默认时区：$error');
    }
  }

  /// 申请通知权限（Android 13+ 需要用户授权）。
  Future<bool> requestPermission() async {
    await init();
    if (!_available) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    } catch (error) {
      debugPrint('申请通知权限失败：$error');
      return false;
    }
  }

  /// 安排「每天 [hour]:[minute] 提醒复习」。
  ///
  /// [dueCount] 为当前到期数量，用于生成更有信息量的提醒文案；
  /// 每次调度都会覆盖旧计划，因此可以随时用最新数量刷新。
  Future<void> scheduleDailyReview({
    required int hour,
    required int minute,
    required int dueCount,
    required bool isEnglish,
  }) async {
    await init();
    if (!_available) return;
    // 等时区修正完成，避免首次调度落在错误时区上。
    await _applySystemTimeZone();
    try {
      final now = tz.TZDateTime.now(tz.local);
      var next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (!next.isAfter(now)) {
        next = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + 1,
          hour,
          minute,
        );
      }

      final title = isEnglish ? 'Time to review' : '该复习啦';
      final body = isEnglish
          ? (dueCount > 0
                ? '$dueCount lesson(s) waiting in your review queue'
                : 'Learn one new lesson to keep your streak going')
          : (dueCount > 0
                ? '复习队列里有 $dueCount 个知识点，花几分钟巩固一下'
                : '今天没有待复习内容，学一篇新知识点保持连续学习');

      await _plugin.zonedSchedule(
        _dailyReviewId,
        title,
        body,
        next,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            '复习提醒',
            channelDescription: '每天提醒今日到期的复习知识点',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // 按「每天同一时刻」重复，无需 App 常驻后台。
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'review',
      );
    } catch (error) {
      debugPrint('安排复习提醒失败：$error');
    }
  }

  /// 撤销每日提醒（用户关闭开关时调用）。
  Future<void> cancelDailyReview() async {
    await init();
    if (!_available) return;
    try {
      await _plugin.cancel(_dailyReviewId);
    } catch (error) {
      debugPrint('取消复习提醒失败：$error');
    }
  }
}
