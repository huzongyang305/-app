import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/auto_backup_service.dart';
import '../services/notification_service.dart';
import '../services/progress_provider.dart';
import '../services/settings_provider.dart';
import '../widgets/responsive_content.dart';
import 'daily_question_screen.dart';
import 'home_screen.dart';
import 'learn_screen.dart';
import 'profile_screen.dart';
import 'review_plan_screen.dart';
import 'tools_screen.dart';

/// 底部导航容器：首页 / 学习 / 测验 / 我的。
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _index = 0;

  SettingsProvider? _settings;
  ProgressProvider? _progress;
  NotificationService? _notifications;

  /// 上次已下发的提醒方案签名，避免每次重建都重复调度。
  String? _reminderSignature;

  /// 自动备份执行中标志，避免设置刷新时重入。
  bool _autoBackupRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncReminder());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.read<SettingsProvider>();
    if (!identical(_settings, settings)) {
      _settings?.removeListener(_syncReminder);
      _settings = settings..addListener(_syncReminder);
    }
    final progress = context.read<ProgressProvider>();
    if (!identical(_progress, progress)) {
      _progress?.removeListener(_syncReminder);
      _progress = progress..addListener(_syncReminder);
    }
    final notifications = context.read<NotificationService>();
    if (!identical(_notifications, notifications)) {
      NotificationService.pendingPayload.removeListener(_onNotificationPayload);
      _notifications = notifications;
      NotificationService.pendingPayload.addListener(_onNotificationPayload);
      // 冷启动时可能已经带着通知跳转目标，补一次处理。
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onNotificationPayload(),
      );
    }
  }

  @override
  void dispose() {
    _settings?.removeListener(_syncReminder);
    _progress?.removeListener(_syncReminder);
    NotificationService.pendingPayload.removeListener(_onNotificationPayload);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 通知点击跳转：复习计划 / 每日一题。
  void _onNotificationPayload() {
    if (!mounted) return;
    final payload = NotificationService.consumePendingPayload();
    if (payload == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (payload) {
        case 'review':
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ReviewPlanScreen()),
          );
        case 'daily_question':
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const DailyQuestionScreen(),
            ),
          );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 退到后台或回到前台时刷新一次，保证提醒内容与到期数量一致。
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.paused) {
      _syncReminder();
    }
  }

  /// 同步「每日复习提醒」的定时计划。
  ///
  /// 关闭开关时撤销通知；开启时按设置的时间与当前复习队列刷新文案。
  Future<void> _syncReminder() async {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    final progress = context.read<ProgressProvider>();
    final service = context.read<NotificationService>();

    // 自动备份：到期的每日/每周备份在这里顺带完成。
    await _maybeAutoBackup();

    // 目标达成祝贺：仅在用户开启提醒时发送，且每天最多一次。
    final goalMinutes = settings.dailyGoalMinutes;
    final studiedMinutes = (progress.studySecondsToday / 60).ceil();
    final todayKey = _dayKey(progress.now);
    if (settings.reviewReminderEnabled &&
        studiedMinutes >= goalMinutes &&
        settings.goalCelebratedDate != todayKey) {
      await settings.markGoalCelebrated(todayKey);
      await service.showGoalReached(
        minutes: studiedMinutes,
        isEnglish: settings.isEnglish,
      );
    }

    final signature =
        '${settings.reviewReminderEnabled}|'
        '${settings.reminderTimeLabel}|'
        '${progress.dueReviewCount}|'
        '${settings.localeCode}|dq';
    if (signature == _reminderSignature) return;
    _reminderSignature = signature;

    if (!settings.reviewReminderEnabled) {
      await service.cancelDailyReview();
      await service.cancelDailyQuestion();
      return;
    }
    await service.scheduleDailyReview(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
      dueCount: progress.dueReviewCount,
      isEnglish: settings.isEnglish,
    );
    // 每日一题固定中午 12:30 提醒，与复习提醒错开时段。
    await service.scheduleDailyQuestion(
      hour: 12,
      minute: 30,
      isEnglish: settings.isEnglish,
    );
  }

  String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// 检查自动备份是否到期；到期则导出数据写入用户选定的 SAF 目录。
  Future<void> _maybeAutoBackup() async {
    if (_autoBackupRunning || !mounted) return;
    final settings = context.read<SettingsProvider>();
    if (!settings.autoBackupEnabled) return;
    final progress = context.read<ProgressProvider>();
    final now = progress.now;
    final last = settings.autoBackupLastAt;
    if (last != null &&
        now.difference(last) <
            Duration(days: settings.autoBackupIntervalDays)) {
      return;
    }

    _autoBackupRunning = true;
    try {
      final payload = jsonEncode(progress.exportData());
      final name = await const AutoBackupCoordinator().maybeRun(
        enabled: true,
        intervalDays: settings.autoBackupIntervalDays,
        keepCount: settings.autoBackupKeepCount,
        lastBackupAt: last,
        now: now,
        payload: payload,
      );
      if (name != null) {
        await settings.markAutoBackupDone(now);
      }
    } catch (error) {
      debugPrint('自动备份失败：$error');
    } finally {
      _autoBackupRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 导航入口与顺序由设置决定，默认首页 / 学习 / 工具 / 我的。
    final settings = context.watch<SettingsProvider>();
    final tabs = settings.navTabs;
    final index = _index.clamp(0, tabs.length - 1);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= AppBreakpoints.tablet;
    final pages = <Widget>[for (final tab in tabs) _pageFor(tab)];
    final destinations = <NavigationDestination>[
      for (final tab in tabs) _destinationFor(context, tab),
    ];

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            Semantics(
              container: true,
              label: context.tr('mainNavigation'),
              child: NavigationRail(
                extended: width >= 1180,
                selectedIndex: index,
                groupAlignment: -0.85,
                onDestinationSelected: (value) =>
                    setState(() => _index = value),
                destinations: [
                  for (final destination in destinations)
                    NavigationRailDestination(
                      icon: destination.icon,
                      selectedIcon: destination.selectedIcon,
                      label: Text(destination.label),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(index: index, children: pages),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      // IndexedStack 保留各页面状态，切换标签不会丢失滚动位置。
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Semantics(
        container: true,
        label: context.tr('mainNavigation'),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: destinations,
        ),
      ),
    );
  }

  /// 导航入口 ID 到页面。
  Widget _pageFor(String id) => switch (id) {
    'learn' => const LearnScreen(),
    'tools' => const ToolsScreen(),
    'profile' => const ProfileScreen(),
    _ => const HomeScreen(),
  };

  /// 导航入口 ID 到图标与文案。
  NavigationDestination _destinationFor(BuildContext context, String id) {
    return switch (id) {
      'learn' => NavigationDestination(
        icon: const Icon(Icons.menu_book_outlined),
        selectedIcon: const Icon(Icons.menu_book),
        label: context.tr('navLearn'),
      ),
      'tools' => NavigationDestination(
        icon: const Icon(Icons.build_outlined),
        selectedIcon: const Icon(Icons.build),
        label: context.tr('navTools'),
      ),
      'profile' => NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: context.tr('navProfile'),
      ),
      _ => NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: context.tr('navHome'),
      ),
    };
  }
}
