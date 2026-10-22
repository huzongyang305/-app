import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/root_shell.dart';
import 'l10n/app_strings.dart';
import 'services/content_provider.dart';
import 'services/notification_service.dart';
import 'services/progress_provider.dart';
import 'services/settings_provider.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

/// 根据主题预设创建定制化的 ThemeData。
ThemeData _buildThemeWithPreset(
  bool isDark,
  bool highContrast,
  String presetId,
) {
  final baseTheme = isDark
      ? AppTheme.dark(highContrast: highContrast)
      : AppTheme.light(highContrast: highContrast);

  // 如果不是默认主题，应用自定义主题色
  if (presetId != 'default') {
    final preset = AppThemes.findById(presetId);
    
    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: preset.primary,
        secondary: preset.secondary,
        primaryContainer: preset.secondary.withValues(alpha: 0.3),
        onPrimaryContainer: preset.primary,
      ),
      appBarTheme: baseTheme.appBarTheme.copyWith(
        foregroundColor: preset.primary,
      ),
      navigationBarTheme: baseTheme.navigationBarTheme.copyWith(
        indicatorColor: preset.primary.withValues(alpha: 0.10),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) => TextStyle(
            fontFamily: AppTheme.sansFamily,
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? preset.primary
                : baseTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? preset.primary
                : baseTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  return baseTheme;
}

/// 应用根组件：通过 Provider 注入设置、进度与内容仓库。
class CodeLearnApp extends StatelessWidget {
  const CodeLearnApp({
    super.key,
    required this.storage,
    this.notifications,
    this.contentProvider,
    this.clock,
  });

  final StorageService storage;

  /// 本地提醒服务；测试或不需要通知时可不传，内部会自动降级。
  final NotificationService? notifications;

  /// 测试可注入预加载内容仓库；正式运行留空，由 App 自己加载 assets。
  final ContentProvider? contentProvider;

  /// 测试用固定时钟；正式运行留空，使用系统时间。
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
        ChangeNotifierProvider(
          create: (_) => ProgressProvider(storage, now: clock),
        ),
        if (contentProvider != null)
          ChangeNotifierProvider<ContentProvider>.value(value: contentProvider!)
        else
          ChangeNotifierProvider(
            create: (_) => ContentProvider(storage: storage)..load(),
          ),
        Provider<NotificationService>.value(
          value: notifications ?? NotificationService(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppStrings(settings.localeCode).get('appTitle'),
            debugShowCheckedModeBanner: false,
            theme: _buildThemeWithPreset(
              false,
              settings.highContrast,
              settings.themePresetId,
            ),
            darkTheme: _buildThemeWithPreset(
              true,
              settings.highContrast,
              settings.themePresetId,
            ),
            themeMode: settings.themeMode,
            locale: settings.locale,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  disableAnimations:
                      settings.reduceMotion || media.disableAnimations,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const RootShell(),
          );
        },
      ),
    );
  }
}
