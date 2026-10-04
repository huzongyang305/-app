import 'package:flutter/material.dart';

/// 视觉规范对齐 it小窝 的设计语言：
/// Slate 中性色阶 + 蓝靛强调色、135° 蓝色渐变、胶囊按钮、4~6px 小圆角卡片。
class AppPalette {
  const AppPalette._();

  // 主色与渐变（取自其 CSS：linear-gradient(135deg,#6c8ff8,#8ba5ff)）
  static const Color primary = Color(0xFF6C8FF8);
  static const Color primaryLight = Color(0xFF93B4FF);
  static const Color primaryDeep = Color(0xFF5078E8);
  static const Color sky = Color(0xFF38BDF8);

  // Slate 中性色阶
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

  // 语义色
  static const Color danger = Color(0xFFF56C6C);
  static const Color success = Color(0xFF5AC725);
  static const Color warning = Color(0xFFF9AE3D);
}

class AppTheme {
  const AppTheme._();

  static const Color seedColor = AppPalette.primary;

  /// 签名渐变：用于首页进度卡、强调按钮与勋章等。
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppPalette.primary, Color(0xFF8BA5FF)],
  );

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? AppPalette.primaryLight : AppPalette.primary,
          onPrimary: Colors.white,
          primaryContainer: isDark
              ? AppPalette.slate700
              : const Color(0xFFE8EEFF),
          secondary: AppPalette.sky,
          surface: isDark ? AppPalette.slate900 : AppPalette.slate50,
          onSurface: isDark ? AppPalette.slate200 : AppPalette.slate900,
          onSurfaceVariant: isDark ? AppPalette.slate400 : AppPalette.slate500,
          surfaceContainerLowest: isDark
              ? const Color(0xFF0B1220)
              : Colors.white,
          surfaceContainerLow: isDark ? AppPalette.slate800 : Colors.white,
          surfaceContainer: isDark ? AppPalette.slate800 : Colors.white,
          surfaceContainerHigh: isDark
              ? AppPalette.slate700
              : AppPalette.slate100,
          surfaceContainerHighest: isDark
              ? AppPalette.slate700
              : AppPalette.slate100,
          outlineVariant: isDark ? AppPalette.slate700 : AppPalette.slate200,
          error: AppPalette.danger,
        );

    final pill = StadiumBorder(
      side: BorderSide(color: scheme.outlineVariant, width: 1),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      // 卡片统一 6px 小圆角 + 极淡边框，贴近其设计规范
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 0.8,
        space: 24,
      ),
      // 按钮与标签统一胶囊形
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: pill,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: pill,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: pill,
          textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: isDark ? AppPalette.slate700 : AppPalette.slate100,
        labelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          color: scheme.onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppPalette.slate800 : AppPalette.slate100,
        hintStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: isDark
            ? AppPalette.slate700
            : AppPalette.primary.withValues(alpha: 0.14),
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 15,
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          color: scheme.onSurfaceVariant,
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
        iconColor: scheme.onSurfaceVariant,
        collapsedIconColor: scheme.onSurfaceVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
    );
  }
}
