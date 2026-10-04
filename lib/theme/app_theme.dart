import 'package:flutter/material.dart';

/// 设计语言：知识库 / 索引卡（Ink & Paper）。
///
/// 纸白底 + 墨色文字 + 电光蓝强调，取消渐变与阴影堆叠；长文用衬线字体
/// 排版，标签与题干用无衬线，编号、数据与代码用等宽，用「分区带 + 竖标」
/// 建立目录式的阅读节奏。
class AppPalette {
  const AppPalette._();

  /// 主强调色：电光蓝。
  static const Color primary = Color(0xFF1B4DFF);
  static const Color primaryDark = Color(0xFF6E8CFF);

  /// 纸与墨。
  static const Color paper = Color(0xFFF7F7F4);
  static const Color paperRaised = Color(0xFFFFFEFA);
  static const Color ink = Color(0xFF14151A);
  static const Color inkMuted = Color(0xFF5C5F6B);
  static const Color rule = Color(0xFFDDDDD6);

  /// 深色模式的墨蓝底与纸白字。
  static const Color nightBase = Color(0xFF12141C);
  static const Color nightRaised = Color(0xFF1A1D28);
  static const Color nightRule = Color(0xFF2C3040);
  static const Color paperOnNight = Color(0xFFEDEDE8);
  static const Color paperMutedOnNight = Color(0xFF9A9DA8);

  /// 语义色。
  static const Color success = Color(0xFF1F7A4D);
  static const Color danger = Color(0xFFC2412D);
  static const Color warning = Color(0xFFB7791F);

  /// 兼容既有代码：沙箱终端与少许组件仍引用这组中性色。
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);
}

class AppTheme {
  const AppTheme._();

  static const Color seedColor = AppPalette.primary;

  /// 展示字体：长文与标题使用衬线，承载「教材」气质。
  static const String serifFamily = 'Georgia';
  static const String sansFamily = 'Roboto';
  static const String monoFamily = 'monospace';

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark ? _darkScheme() : _lightScheme();
    final textTheme = _textTheme(colorScheme);

    final hairline = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2),
      side: BorderSide(color: colorScheme.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLow,
        shape: hairline,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 20,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: hairline,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: hairline,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: const TextStyle(fontFamily: sansFamily, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: hairline,
          textStyle: const TextStyle(fontFamily: sansFamily, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: hairline,
        side: BorderSide(color: colorScheme.outlineVariant),
        backgroundColor: colorScheme.surfaceContainerLow,
        labelStyle: TextStyle(
          fontFamily: monoFamily,
          fontSize: 11,
          color: colorScheme.onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        hintStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: colorScheme.surfaceContainerHighest,
        linearMinHeight: 4,
        color: colorScheme.primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) => TextStyle(
            fontFamily: monoFamily,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        indicatorColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 22),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 22,
        ),
        selectedLabelTextStyle: TextStyle(
          fontFamily: monoFamily,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: monoFamily,
          fontSize: 11,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        shape: const RoundedRectangleBorder(),
        titleTextStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 15,
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 13,
          height: 1.4,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        textColor: colorScheme.onSurface,
        collapsedTextColor: colorScheme.onSurface,
        iconColor: colorScheme.onSurfaceVariant,
        collapsedIconColor: colorScheme.onSurfaceVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(2),
        ),
        textStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 12,
          color: colorScheme.onInverseSurface,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll<double>(6),
        radius: const Radius.circular(3),
      ),
    );
  }

  static ColorScheme _lightScheme() => const ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE3E9FF),
    onPrimaryContainer: Color(0xFF0A2A9E),
    secondary: AppPalette.ink,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFECECE6),
    onSecondaryContainer: AppPalette.ink,
    tertiary: AppPalette.inkMuted,
    onTertiary: Colors.white,
    error: AppPalette.danger,
    onError: Colors.white,
    errorContainer: Color(0xFFFBE4DF),
    onErrorContainer: Color(0xFF7A2415),
    surface: AppPalette.paper,
    onSurface: AppPalette.ink,
    onSurfaceVariant: AppPalette.inkMuted,
    surfaceContainerLowest: AppPalette.paperRaised,
    surfaceContainerLow: AppPalette.paperRaised,
    surfaceContainer: Color(0xFFF1F1EC),
    surfaceContainerHigh: Color(0xFFECECE6),
    surfaceContainerHighest: Color(0xFFE6E6E0),
    outline: Color(0xFF9A9C95),
    outlineVariant: AppPalette.rule,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppPalette.ink,
    onInverseSurface: AppPalette.paper,
    inversePrimary: AppPalette.primaryDark,
    surfaceTint: Colors.transparent,
  );

  static ColorScheme _darkScheme() => const ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.primaryDark,
    onPrimary: Color(0xFF0B1B5E),
    primaryContainer: Color(0xFF1E2B5E),
    onPrimaryContainer: Color(0xFFDCE3FF),
    secondary: AppPalette.paperOnNight,
    onSecondary: AppPalette.ink,
    secondaryContainer: AppPalette.nightRule,
    onSecondaryContainer: AppPalette.paperOnNight,
    tertiary: AppPalette.paperMutedOnNight,
    onTertiary: AppPalette.ink,
    error: Color(0xFFE98A79),
    onError: Color(0xFF4A1309),
    errorContainer: Color(0xFF5A1D12),
    onErrorContainer: Color(0xFFFFDAD3),
    surface: AppPalette.nightBase,
    onSurface: AppPalette.paperOnNight,
    onSurfaceVariant: AppPalette.paperMutedOnNight,
    surfaceContainerLowest: AppPalette.nightBase,
    surfaceContainerLow: AppPalette.nightRaised,
    surfaceContainer: Color(0xFF20232F),
    surfaceContainerHigh: Color(0xFF262A38),
    surfaceContainerHighest: AppPalette.nightRule,
    outline: Color(0xFF5A5E6B),
    outlineVariant: AppPalette.nightRule,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppPalette.paperOnNight,
    onInverseSurface: AppPalette.ink,
    inversePrimary: AppPalette.primary,
    surfaceTint: Colors.transparent,
  );

  /// 字体角色：衬线排长文、等宽排编号与数据、无衬线排界面文案。
  static TextTheme _textTheme(ColorScheme scheme) {
    final base = scheme.brightness == Brightness.dark
        ? Typography.material2021(platform: TargetPlatform.android).white
        : Typography.material2021(platform: TargetPlatform.android).black;

    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: serifFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: serifFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: serifFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: serifFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: sansFamily,
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontFamily: sansFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: serifFamily,
        fontSize: 17,
        height: 1.75,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: serifFamily,
        fontSize: 15.5,
        height: 1.75,
        letterSpacing: 0,
        color: scheme.onSurface,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: sansFamily,
        fontSize: 13,
        height: 1.5,
        letterSpacing: 0,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: sansFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: monoFamily,
        fontSize: 12,
        letterSpacing: 0,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontFamily: monoFamily,
        fontSize: 11,
        letterSpacing: 0,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
