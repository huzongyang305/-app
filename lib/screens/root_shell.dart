import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/notification_service.dart';
import '../services/progress_provider.dart';
import '../services/settings_provider.dart';
import '../widgets/responsive_content.dart';
import 'home_screen.dart';
import 'learn_screen.dart';
import 'profile_screen.dart';
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

  /// 上次已下发的提醒方案签名，避免每次重建都重复调度。
  String? _reminderSignature;

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
  }

  @override
  void dispose() {
    _settings?.removeListener(_syncReminder);
    _progress?.removeListener(_syncReminder);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    final signature =
        '${settings.reviewReminderEnabled}|'
        '${settings.reminderTimeLabel}|'
        '${progress.dueReviewCount}|'
        '${settings.localeCode}';
    if (signature == _reminderSignature) return;
    _reminderSignature = signature;

    if (!settings.reviewReminderEnabled) {
      await service.cancelDailyReview();
      return;
    }
    await service.scheduleDailyReview(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
      dueCount: progress.dueReviewCount,
      isEnglish: settings.isEnglish,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomeScreen(),
      LearnScreen(),
      ToolsScreen(),
      ProfileScreen(),
    ];

    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= AppBreakpoints.tablet;
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: context.tr('navHome'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.menu_book_outlined),
        selectedIcon: const Icon(Icons.menu_book),
        label: context.tr('navLearn'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.build_outlined),
        selectedIcon: const Icon(Icons.build),
        label: context.tr('navTools'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: context.tr('navProfile'),
      ),
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
                selectedIndex: _index,
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
              child: IndexedStack(index: _index, children: pages),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      // IndexedStack 保留各页面状态，切换标签不会丢失滚动位置。
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Semantics(
        container: true,
        label: context.tr('mainNavigation'),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: destinations,
        ),
      ),
    );
  }
}
