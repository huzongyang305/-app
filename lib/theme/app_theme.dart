import 'package:flutter/material.dart';
import 'dart:math' show pow;

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

  /// 内容分类色彩系统：为不同课程类型添加主题色，提升视觉区分度。
  static const Map<String, Color> categoryColors = {
    'programming_basics': Color(0xFF6366F1),   // 靛蓝 - 编程基础
    'discrete_math': Color(0xFF8B5CF6),        // 紫色 - 离散数学
    'data_structures': Color(0xFFEC4899),      // 粉红 - 数据结构与算法
    'javaweb': Color(0xFFF59E0B),              // 琥珀 - JavaWeb开发
    'operating_systems': Color(0xFF10B981),    // 翠绿 - 操作系统
    'computer_networks': Color(0xFF3B82F6),    // 蓝色 - 计算机网络
    'database': Color(0xFFEF4444),             // 红色 - 数据库
    'default': Color(0xFF64748B),              // 灰色 - 默认
  };

  /// 获取分类颜色，如果找不到则返回默认色
  static Color getCategoryColor(String categoryId) {
    return categoryColors[categoryId] ?? categoryColors['default']!;
  }

  /// 生成渐变背景色（从分类色的浅色到原色）
  static List<Color> getCategoryGradient(String categoryId) {
    final baseColor = getCategoryColor(categoryId);
    return [
      baseColor.withValues(alpha: 0.15),
      baseColor.withValues(alpha: 0.35),
    ];
  }

  /// 完整语义色系统：用于不同状态和反馈
  // 信息提示（蓝色系）
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  
  // 中性状态（灰色系）
  static const Color neutralState = Color(0xFF6B7280);
  static const Color neutralLight = Color(0xFFF3F4F6);
  
  // 学习进度（青色系）
  static const Color progress = Color(0xFF06B6D4);
  static const Color progressLight = Color(0xFFCFFAFE);
  
  // 掌握程度（紫色系）
  static const Color mastery = Color(0xFF8B5CF6);
  static const Color masteryLight = Color(0xFFEDE9FE);
  
  // 收藏标记（玫瑰色）
  static const Color favorite = Color(0xFFF43F5E);
  static const Color favoriteLight = Color(0xFFFCE7F3);
  
  // 复习提醒（橙色系）
  static const Color review = Color(0xFFF97316);
  static const Color reviewLight = Color(0xFFFED7AA);
  
  // 情感化色彩
  static const Color excitement = Color(0xFFFFD700);  // 兴奋/突破（金色）
  static const Color calm = Color(0xFFBFDBFE);        // 平静/专注（淡蓝）
  static const Color struggle = Color(0xFFFCA5A5);    // 挫折/需要帮助（柔和红）
  static const Color curiosity = Color(0xFF6EE7B7);   // 好奇/探索（薄荷绿）
}

/// 统一圆角：卡片 16、控件 12、小组件 10、弹层 24。
abstract final class AppRadii {
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double sheet = 24;

  /// L1 核心卡片：大圆角，用于重要内容和推荐项
  static BorderRadius get cardPrimary => BorderRadius.circular(xxl);
  
  /// L2 普通卡片：中圆角，用于常规内容
  static BorderRadius get card => BorderRadius.circular(lg);
  
  /// L3 辅助卡片：小圆角，用于次要信息
  static BorderRadius get cardSecondary => BorderRadius.circular(md);
  
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

  /// L1 核心卡片阴影：更强的视觉提升感
  static List<BoxShadow> primary(Brightness brightness) {
    final alpha = brightness == Brightness.dark ? 0.40 : 0.12;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: alpha),
        blurRadius: 32,
        offset: const Offset(0, 16),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: alpha * 0.5),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// L3 辅助卡片阴影：轻量级，不抢视觉焦点
  static List<BoxShadow> subtle(Brightness brightness) {
    final alpha = brightness == Brightness.dark ? 0.18 : 0.04;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: alpha),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ];
  }
}

/// 无障碍工具类：确保颜色对比度符合WCAG AA标准
abstract final class AccessibilityUtils {
  /// 计算两个颜色之间的对比度比率
  static double calculateContrastRatio(Color foreground, Color background) {
    final lum1 = _relativeLuminance(foreground);
    final lum2 = _relativeLuminance(background);
    
    final lighter = lum1 > lum2 ? lum1 : lum2;
    final darker = lum1 > lum2 ? lum2 : lum1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// 计算相对亮度（WCAG 2.0公式）
  static double _relativeLuminance(Color color) {
    final r = _linearize(color.red / 255.0);
    final g = _linearize(color.green / 255.0);
    final b = _linearize(color.blue / 255.0);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
  
  /// 线性化sRGB值
  static double _linearize(double value) {
    return value <= 0.03928
        ? value / 12.92
        : pow((value + 0.055) / 1.055, 2.4).toDouble();
  }
  
  /// 检查是否符合WCAG AA标准（4.5:1用于普通文本，3:1用于大文本）
  static bool meetsWCAGAA(Color foreground, Color background, {bool isLargeText = false}) {
    final ratio = calculateContrastRatio(foreground, background);
    return isLargeText ? ratio >= 3.0 : ratio >= 4.5;
  }
  
  /// 自动选择最佳文字颜色（黑或白）
  static Color getOptimalTextColor(Color backgroundColor) {
    final lightContrast = calculateContrastRatio(Colors.white, backgroundColor);
    final darkContrast = calculateContrastRatio(Colors.black, backgroundColor);
    
    return lightContrast > darkContrast ? Colors.white : Colors.black;
  }
  
  /// 生成符合无障碍标准的颜色变体
  static Color ensureAccessible(Color color, Color background, {double minRatio = 4.5}) {
    var adjusted = color;
    for (int i = 0; i < 20; i++) {
      if (calculateContrastRatio(adjusted, background) >= minRatio) {
        return adjusted;
      }
      // 逐步调整亮度直到满足标准
      final hsl = HSLColor.fromColor(adjusted);
      final newLightness = hsl.lightness + (i % 2 == 0 ? 0.05 : -0.05);
      adjusted = hsl.withLightness(newLightness.clamp(0.0, 1.0)).toColor();
    }
    // 如果无法调整到满足要求，返回黑白
    return getOptimalTextColor(background);
  }
}

/// 微交互色彩效果：为细微操作提供视觉反馈
abstract final class MicroInteractionColors {
  /// 悬停提亮（+15%亮度）
  static Color hoverBrighten(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
  }
  
  /// 按下加深（-20%亮度）
  static Color pressDarken(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0)).toColor();
  }
  
  /// 选中发光效果
  static BoxShadow selectedGlow(Color base, {double intensity = 0.4}) {
    return BoxShadow(
      color: base.withValues(alpha: intensity),
      blurRadius: 12,
      spreadRadius: 2,
    );
  }
  
  /// 脉冲光晕（用于通知）
  static List<BoxShadow> pulseGlow(Color base) {
    return [
      BoxShadow(
        color: base.withValues(alpha: 0.3),
        blurRadius: 16,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: base.withValues(alpha: 0.15),
        blurRadius: 32,
        spreadRadius: 4,
      ),
    ];
  }
}

/// 多主题预设系统：支持用户切换不同视觉风格
class ThemePreset {
  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final IconData icon;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.icon,
  });
}

/// 预定义主题集合
abstract final class AppThemes {
  // 默认主题 - 科技蓝（适合大多数用户）
  static const ThemePreset defaultTheme = ThemePreset(
    id: 'default',
    name: '科技蓝',
    primary: Color(0xFF2F6BFF),
    secondary: Color(0xFF6E96FF),
    accent: Color(0xFFA5B4FC),
    icon: Icons.palette_outlined,
  );
  
  // 活力主题 - 珊瑚橙（适合初学者，更温暖友好）
  static const ThemePreset vibrantTheme = ThemePreset(
    id: 'vibrant',
    name: '活力橙',
    primary: Color(0xFFFF6B6B),
    secondary: Color(0xFFFF8E8E),
    accent: Color(0xFFFFB4B4),
    icon: Icons.flash_on,
  );
  
  // 沉稳主题 - 森林绿（适合进阶者，专业感）
  static const ThemePreset matureTheme = ThemePreset(
    id: 'mature',
    name: '森林绿',
    primary: Color(0xFF10B981),
    secondary: Color(0xFF34D399),
    accent: Color(0xFF6EE7B7),
    icon: Icons.eco_outlined,
  );
  
  // 夜间专注主题 - 深紫（减少蓝光，护眼）
  static const ThemePreset focusTheme = ThemePreset(
    id: 'focus',
    name: '专注紫',
    primary: Color(0xFF8B5CF6),
    secondary: Color(0xFFA78BFA),
    accent: Color(0xFFC4B5FD),
    icon: Icons.nightlight_round,
  );
  
  // 获取所有可用主题
  static List<ThemePreset> get allPresets => [
    defaultTheme,
    vibrantTheme,
    matureTheme,
    focusTheme,
  ];
  
  // 根据ID查找主题
  static ThemePreset findById(String id) {
    return allPresets.firstWhere(
      (p) => p.id == id,
      orElse: () => defaultTheme,
    );
  }
}

/// 动态色彩响应系统：根据用户行为和时间调整颜色
abstract final class DynamicColorSystem {
  /// 根据学习活跃度调整颜色饱和度
  /// 
  /// activityScore: 0.0 (不活跃) - 1.0 (非常活跃)
  /// 活跃用户看到更鲜艳的颜色，提升成就感
  static Color adjustSaturation(Color baseColor, double activityScore) {
    final saturationMultiplier = 0.7 + (activityScore * 0.3);
    final hsl = HSLColor.fromColor(baseColor);
    
    return hsl.withSaturation(
      (hsl.saturation * saturationMultiplier).clamp(0.0, 1.0),
    ).toColor();
  }
  
  /// 根据时间调整色温
  /// 
  /// 早晨：冷色调，提神
  /// 白天：标准色温
  /// 夜晚：暖色调，护眼
  static Color adjustColorTemperature(Color baseColor, int hour) {
    if (hour >= 6 && hour < 12) {
      // 早晨：增加蓝色成分，提神
      final r = baseColor.red;
      final g = baseColor.green;
      final b = (baseColor.blue * 1.1).clamp(0, 255).toInt();
      return Color.fromARGB(baseColor.alpha, r, g, b);
    } else if (hour >= 18 || hour < 6) {
      // 夜晚：增加红色成分，减少蓝光
      final r = (baseColor.red * 1.15).clamp(0, 255).toInt();
      final g = baseColor.green;
      final b = (baseColor.blue * 0.85).clamp(0, 255).toInt();
      return Color.fromARGB(baseColor.alpha, r, g, b);
    }
    
    // 白天：返回原色
    return baseColor;
  }
  
  /// 根据当前时间自动调整主题色
  static Color getTimeAdjustedPrimary(Color baseColor) {
    final now = DateTime.now();
    return adjustColorTemperature(baseColor, now.hour);
  }
  
  /// 情感化色彩映射：根据学习状态调整界面氛围
  static Color getEmotionalColor(String emotionalState) {
    switch (emotionalState) {
      case 'excitement':  // 兴奋/突破
        return AppPalette.excitement;
      case 'calm':        // 平静/专注
        return AppPalette.calm;
      case 'struggle':    // 挫折/需要帮助
        return AppPalette.struggle;
      case 'curiosity':   // 好奇/探索
        return AppPalette.curiosity;
      default:
        return AppPalette.primary;
    }
  }
}

/// 克制动效：统一时长与曲线，交互反馈不超过 280ms。
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 280);
  static const Curve curve = Curves.easeOutCubic;
}

/// 预定义渐变集合：用于按钮、进度条、徽章等
abstract final class AppGradients {
  // 主色渐变（按钮、主要操作）
  static LinearGradient get primary => const LinearGradient(
    colors: [Color(0xFF2F6BFF), Color(0xFF6E96FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 成功渐变（完成徽章、成就）
  static LinearGradient get success => const LinearGradient(
    colors: [Color(0xFF12B76A), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 警告渐变（待办事项、每日挑战）
  static LinearGradient get warning => const LinearGradient(
    colors: [Color(0xFFF79009), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 梦幻渐变（首页Banner、庆祝动画）
  static LinearGradient get dreamy => const LinearGradient(
    colors: [
      Color(0xFF667eea),
      Color(0xFF764ba2),
      Color(0xFFf093fb),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 金属质感渐变（高级徽章、VIP标识）
  static LinearGradient get metallic => const LinearGradient(
    colors: [
      Color(0xFFE0E0E0),
      Color(0xFFFFD700),
      Color(0xFFE0E0E0),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 信息渐变（提示卡片）
  static LinearGradient get info => const LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 学习进度渐变（进度条）
  static LinearGradient get progress => const LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 掌握程度渐变（技能树节点）
  static LinearGradient get mastery => const LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 彩虹成就渐变（终极成就动画）
  static List<Color> get achievement => const [
    Color(0xFFFF6B6B), // 红
    Color(0xFFF79009), // 橙
    Color(0xFFFFD700), // 黄
    Color(0xFF12B76A), // 绿
    Color(0xFF3B82F6), // 蓝
    Color(0xFF8B5CF6), // 紫
  ];
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

/// 主题配置扩展：用于在运行时动态切换主题预设。
class AppThemeConfig extends ThemeExtension<AppThemeConfig> {
  const AppThemeConfig({
    required this.presetId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });

  final String presetId;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  @override
  AppThemeConfig copyWith({
    String? presetId,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
  }) {
    return AppThemeConfig(
      presetId: presetId ?? this.presetId,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
    );
  }

  @override
  AppThemeConfig lerp(AppThemeConfig? other, double t) {
    if (other == null) return this;
    return AppThemeConfig(
      presetId: t < 0.5 ? presetId : other.presetId,
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t)!,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
    );
  }

  /// 根据主题预设ID创建配置
  static AppThemeConfig fromPreset(String presetId) {
    final preset = AppThemes.findById(presetId);
    return AppThemeConfig(
      presetId: preset.id,
      primaryColor: preset.primary,
      secondaryColor: preset.secondary,
      accentColor: preset.accent,
    );
  }
}
