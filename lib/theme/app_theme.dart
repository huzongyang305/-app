import 'package:flutter/material.dart';

/// 设计语言：现代极简（Modern Minimal）。
///
/// 全局只使用三种核心颜色：主色蓝、画布浅灰、表面白。文字与分割线均为
/// 中性灰阶，不额外引入色相；圆角、间距、阴影与动效统一由设计令牌提供。
class AppPalette {
  const AppPalette._();

  static const Color primary = Color(0xFF2F6BFF);
  static const Color primaryDark = Color(0xFF6E96FF);
  static const Color canvas = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF101828);
  static const Color inkMuted = Color(0xFF667085);
  static const Color rule = Color(0xFFE7EAF0);
  static const Color neutralFill = Color(0xFFF2F4F7);

  static const Color nightBase = Color(0xFF0F1115);
  static const Color nightRaised = Color(0xFF181B22);
  static const Color nightRule = Color(0xFF2A2F3A);
  static const Color paperOnNight = Color(0xFFF2F4F7);
  static const Color paperMutedOnNight = Color(0xFF98A2B3);

  /// 语义色只用于答题对错、删除等必要反馈。
  static const Color success = Color(0xFF12B76A);
  static const Color danger = Color(0xFFF04438);
  static const Color warning = Color(0xFFF79009);

  static const Color paper = canvas;
  static const Color paperRaised = surface;

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

/// 统一圆角：卡片 16、控件 12、小组件 10、弹层 24。
abstract final class AppRadii {
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double sheet = 24;

  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get control => BorderRadius.circular(md);
  static BorderRadius get chip => BorderRadius.circular(sm);
  static BorderRadius get sheetTop =>
      const BorderRadius.vertical(top: Radius.circular(sheet));
}

/// 统一间距：4 的倍数，页面水平边距固定 20。
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double page = 20;
}

/// 柔和阴影：只在卡片与弹层使用一次，避免阴影堆叠。
abstract final class AppShadows {
  static List<BoxShadow> soft(Brightness brightness) {
    final alpha = brightness == Brightness.dark ? 0.28 : 0.06;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: alpha),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static List<BoxShadow> raised(Brightness brightness) {
    final alpha = brightness == Brightness.dark ? 0.36 : 0.10;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: alpha),
        blurRadius: 28,
        offset: const Offset(0, 12),
      ),
    ];
  }
}

/// 克制动效：统一时长与曲线，交互反馈不超过 280ms。
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 280);
  static const Curve curve = Curves.easeOutCubic;
}

class AppTheme {
  const AppTheme._();

  static const Color seedColor = AppPalette.primary;
  static const String sansFamily = 'Roboto';
  static const String serifFamily = sansFamily;
  static const String monoFamily = 'monospace';

  static ThemeData light({bool highContrast = false}) =>
      _build(Brightness.light, highContrast: highContrast);
  static ThemeData dark({bool highContrast = false}) =>
      _build(Brightness.dark, highContrast: highContrast);

  static ThemeData _build(Brightness brightness, {bool highContrast = false}) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? _darkScheme() : _lightScheme();
    // 高对比模式只调整次级文字与描边，保留原有品牌色与版面结构。
    final scheme = highContrast
        ? _highContrastScheme(base, isDark: isDark)
        : base;
    final textTheme = _textTheme(scheme);
    final cardShape = RoundedRectangleBorder(
      borderRadius: AppRadii.card,
      side: BorderSide(color: scheme.outlineVariant),
    );
    final controlShape = RoundedRectangleBorder(borderRadius: AppRadii.control);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      canvasColor: scheme.surfaceContainerLowest,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shadowColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: AppSpacing.xxl,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: controlShape,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: controlShape,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          side: BorderSide(color: scheme.outlineVariant),
          foregroundColor: scheme.onSurface,
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: controlShape,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          highlightColor: scheme.primary.withValues(alpha: 0.08),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.chip),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primary.withValues(alpha: 0.12),
        labelStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        hintStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 14,
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 6,
        color: scheme.primary,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.10),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) => TextStyle(
            fontFamily: sansFamily,
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primary.withValues(alpha: 0.10),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        selectedIconTheme: IconThemeData(color: scheme.primary, size: 23),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: 23,
        ),
        selectedLabelTextStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: scheme.primary,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.control),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        titleTextStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 13,
          height: 1.45,
          color: scheme.onSurfaceVariant,
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
        iconColor: scheme.primary,
        collapsedIconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
        collapsedShape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 13.5,
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.control),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
        textStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 12,
          color: scheme.onInverseSurface,
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
    primaryContainer: Color(0xFFE8EEFF),
    onPrimaryContainer: Color(0xFF1B3FA8),
    secondary: AppPalette.ink,
    onSecondary: Colors.white,
    secondaryContainer: AppPalette.neutralFill,
    onSecondaryContainer: AppPalette.ink,
    tertiary: AppPalette.inkMuted,
    onTertiary: Colors.white,
    error: AppPalette.danger,
    onError: Colors.white,
    errorContainer: Color(0xFFFFE9E7),
    onErrorContainer: Color(0xFFB42318),
    surface: AppPalette.surface,
    onSurface: AppPalette.ink,
    onSurfaceVariant: AppPalette.inkMuted,
    surfaceContainerLowest: AppPalette.canvas,
    surfaceContainerLow: AppPalette.surface,
    surfaceContainer: Color(0xFFF7F8FA),
    surfaceContainerHigh: AppPalette.neutralFill,
    surfaceContainerHighest: Color(0xFFEDEFF3),
    outline: Color(0xFF98A2B3),
    outlineVariant: AppPalette.rule,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppPalette.ink,
    onInverseSurface: AppPalette.surface,
    inversePrimary: AppPalette.primaryDark,
    surfaceTint: Colors.transparent,
  );

  static ColorScheme _darkScheme() => const ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.primaryDark,
    onPrimary: Color(0xFF0B1220),
    primaryContainer: Color(0xFF23345F),
    onPrimaryContainer: Color(0xFFDCE6FF),
    secondary: AppPalette.paperOnNight,
    onSecondary: AppPalette.nightBase,
    secondaryContainer: AppPalette.nightRule,
    onSecondaryContainer: AppPalette.paperOnNight,
    tertiary: AppPalette.paperMutedOnNight,
    onTertiary: AppPalette.nightBase,
    error: Color(0xFFFF8A80),
    onError: Color(0xFF3F0D09),
    errorContainer: Color(0xFF4E1A16),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppPalette.nightBase,
    onSurface: AppPalette.paperOnNight,
    onSurfaceVariant: AppPalette.paperMutedOnNight,
    surfaceContainerLowest: AppPalette.nightBase,
    surfaceContainerLow: AppPalette.nightRaised,
    surfaceContainer: Color(0xFF1E222B),
    surfaceContainerHigh: Color(0xFF232833),
    surfaceContainerHighest: AppPalette.nightRule,
    outline: Color(0xFF5A6270),
    outlineVariant: AppPalette.nightRule,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppPalette.paperOnNight,
    onInverseSurface: AppPalette.nightBase,
    inversePrimary: AppPalette.primary,
    surfaceTint: Colors.transparent,
  );

  /// 高对比配色：把次级文字与描边推向更高对比度，其余色彩保持不变。
  static ColorScheme _highContrastScheme(
    ColorScheme base, {
    required bool isDark,
  }) {
    return base.copyWith(
      onSurfaceVariant: isDark
          ? const Color(0xFFE8ECF4)
          : const Color(0xFF2A3140),
      outline: isDark ? const Color(0xFF9AA4B8) : const Color(0xFF5D6675),
      outlineVariant: isDark
          ? const Color(0xFF6B7488)
          : const Color(0xFF9AA3B2),
    );
  }

  /// 清晰的无衬线层级：标题紧凑、正文宽松、标签克制。
  static TextTheme _textTheme(ColorScheme scheme) {
    final base = scheme.brightness == Brightness.dark
        ? Typography.material2021(platform: TargetPlatform.android).white
        : Typography.material2021(platform: TargetPlatform.android).black;

    TextStyle? style(
      TextStyle? source, {
      required double size,
      required FontWeight weight,
      double height = 1.4,
    }) => source?.copyWith(
      fontFamily: sansFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: 0,
      color: scheme.onSurface,
    );

    return base.copyWith(
      displaySmall: style(
        base.displaySmall,
        size: 28,
        weight: FontWeight.w700,
        height: 1.2,
      ),
      headlineMedium: style(
        base.headlineMedium,
        size: 24,
        weight: FontWeight.w700,
        height: 1.25,
      ),
      headlineSmall: style(
        base.headlineSmall,
        size: 20,
        weight: FontWeight.w700,
        height: 1.3,
      ),
      titleLarge: style(
        base.titleLarge,
        size: 18,
        weight: FontWeight.w700,
        height: 1.35,
      ),
      titleMedium: style(
        base.titleMedium,
        size: 15.5,
        weight: FontWeight.w600,
        height: 1.4,
      ),
      titleSmall: style(
        base.titleSmall,
        size: 14,
        weight: FontWeight.w600,
        height: 1.4,
      ),
      bodyLarge: style(
        base.bodyLarge,
        size: 16,
        weight: FontWeight.w400,
        height: 1.7,
      ),
      bodyMedium: style(
        base.bodyMedium,
        size: 15,
        weight: FontWeight.w400,
        height: 1.6,
      ),
      bodySmall: style(
        base.bodySmall,
        size: 13,
        weight: FontWeight.w400,
        height: 1.5,
      )?.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: style(
        base.labelLarge,
        size: 14,
        weight: FontWeight.w600,
        height: 1.3,
      ),
      labelMedium: style(
        base.labelMedium,
        size: 12,
        weight: FontWeight.w600,
        height: 1.3,
      )?.copyWith(color: scheme.onSurfaceVariant),
      labelSmall: style(
        base.labelSmall,
        size: 11,
        weight: FontWeight.w500,
        height: 1.3,
      )?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}
