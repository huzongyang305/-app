import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 设置项的持久化与边界处理：主题、语言、字号、复习提醒。
void main() {
  late StorageService storage;
  late SettingsProvider settings;

  setUp(() {
    storage = StorageService.inMemory();
    settings = SettingsProvider(storage);
  });

  test('默认值：跟随系统主题、中文、标准字号、提醒关闭', () {
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.localeCode, 'zh');
    expect(settings.isEnglish, isFalse);
    expect(settings.readingFontScale, 1.0);
    expect(settings.reviewReminderEnabled, isFalse);
    expect(settings.reminderTimeLabel, '20:00');
  });

  test('主题模式与语言切换会写入本地并可恢复', () async {
    await settings.setThemeMode(ThemeMode.dark);
    await settings.toggleLocale();

    final restored = SettingsProvider(storage);
    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.localeCode, 'en');
    expect(restored.locale, const Locale('en'));
  });

  test('循环切换主题：系统 → 浅色 → 深色 → 系统', () async {
    await settings.cycleThemeMode();
    expect(settings.themeMode, ThemeMode.light);
    await settings.cycleThemeMode();
    expect(settings.themeMode, ThemeMode.dark);
    await settings.cycleThemeMode();
    expect(settings.themeMode, ThemeMode.system);
  });

  test('设置同一主题不会重复通知', () async {
    var notified = 0;
    settings.addListener(() => notified++);
    await settings.setThemeMode(ThemeMode.system); // 与当前值相同
    expect(notified, 0);
    await settings.setThemeMode(ThemeMode.light);
    expect(notified, 1);
  });

  group('正文字号', () {
    test('超出范围会被裁剪到 0.85 ~ 1.4', () async {
      await settings.setReadingFontScale(3.0);
      expect(settings.readingFontScale, 1.4);
      await settings.setReadingFontScale(0.1);
      expect(settings.readingFontScale, 0.85);
      expect(SettingsProvider(storage).readingFontScale, 0.85);
    });

    test('非法存储值回落到默认字号', () async {
      final broken = StorageService.inMemory();
      await broken.write('reading_font_scale', 'big');
      expect(SettingsProvider(broken).readingFontScale, 1.0);
    });
  });

  group('复习提醒', () {
    test('开关与时间会持久化', () async {
      await settings.setReminderTime(7, 30);
      await settings.setReviewReminderEnabled(true);

      final restored = SettingsProvider(storage);
      expect(restored.reviewReminderEnabled, isTrue);
      expect(restored.reminderHour, 7);
      expect(restored.reminderMinute, 30);
      expect(restored.reminderTimeLabel, '07:30');
    });

    test('越界时间会被裁剪到合法区间', () async {
      await settings.setReminderTime(99, -5);
      expect(settings.reminderHour, 23);
      expect(settings.reminderMinute, 0);
      expect(settings.reminderTimeLabel, '23:00');
    });

    test('本地存了非法时间时回落到 20:00', () async {
      final broken = StorageService.inMemory();
      await broken.write('review_reminder_hour', 42);
      await broken.write('review_reminder_minute', 'x');
      final restored = SettingsProvider(broken);
      expect(restored.reminderHour, 20);
      expect(restored.reminderMinute, 0);
    });
  });
}
