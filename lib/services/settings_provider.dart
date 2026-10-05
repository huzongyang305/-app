import 'package:flutter/material.dart';

import 'storage_service.dart';

/// 设置项：深色模式与界面语言，持久化到本地。
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage) {
    final savedTheme = _storage.read('theme_mode', defaultValue: 'system');
    _themeMode = _themeModeFromName(savedTheme as String);

    final savedLocale = _storage.read('locale_code', defaultValue: 'zh');
    _localeCode = savedLocale == 'en' ? 'en' : 'zh';

    final scale = _storage.read('reading_font_scale', defaultValue: 1.0);
    _readingFontScale = (scale is num)
        ? scale.toDouble().clamp(0.85, 1.4)
        : 1.0;

    _reduceMotion = _storage.read('reduce_motion', defaultValue: false) == true;

    final codeScale = _storage.read('code_font_scale', defaultValue: 1.0);
    _codeFontScale = (codeScale is num)
        ? codeScale.toDouble().clamp(0.8, 1.6)
        : 1.0;
    _codeWrapLines =
        _storage.read('code_wrap_lines', defaultValue: false) == true;

    final selectedPath = _storage.read('selected_path_id', defaultValue: '');
    _selectedPathId = selectedPath is String ? selectedPath : '';

    final sandboxScale = _storage.read('sandbox_font_scale', defaultValue: 1.0);
    _sandboxFontScale = (sandboxScale is num)
        ? sandboxScale.toDouble().clamp(0.8, 1.8)
        : 1.0;

    _reviewReminderEnabled =
        _storage.read('review_reminder_enabled', defaultValue: false) == true;
    final goal = _storage.read('daily_goal_minutes', defaultValue: 20);
    _dailyGoalMinutes = (goal is int) ? goal.clamp(5, 240) : 20;
    final session = _storage.read('review_session_minutes', defaultValue: 30);
    _reviewSessionMinutes = (session is int) ? session.clamp(5, 120) : 30;
    final celebrated = _storage.read(
      'goal_celebrated_date',
      defaultValue: '',
    );
    _goalCelebratedDate = celebrated is String ? celebrated : '';
    _autoBackupEnabled =
        _storage.read('auto_backup_enabled', defaultValue: false) == true;
    final backupInterval = _storage.read(
      'auto_backup_interval_days',
      defaultValue: 1,
    );
    _autoBackupIntervalDays =
        (backupInterval is int && (backupInterval == 1 || backupInterval == 7))
        ? backupInterval
        : 1;
    final backupKeep = _storage.read(
      'auto_backup_keep_count',
      defaultValue: 5,
    );
    _autoBackupKeepCount = backupKeep is int
        ? backupKeep.clamp(2, 20)
        : 5;
    final lastBackup = _storage.read('auto_backup_last_at', defaultValue: '');
    _autoBackupLastAt = lastBackup is String
        ? DateTime.tryParse(lastBackup)
        : null;
    final hour = _storage.read('review_reminder_hour', defaultValue: 20);
    final minute = _storage.read('review_reminder_minute', defaultValue: 0);
    _reminderHour = (hour is int && hour >= 0 && hour <= 23) ? hour : 20;
    _reminderMinute = (minute is int && minute >= 0 && minute <= 59)
        ? minute
        : 0;

    final history = _storage.read('search_history', defaultValue: const []);
    if (history is List) {
      _searchHistory = history
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .take(12)
          .toList();
    }
  }

  final StorageService _storage;

  ThemeMode _themeMode = ThemeMode.system;
  String _localeCode = 'zh';
  double _readingFontScale = 1.0;
  bool _reduceMotion = false;
  double _codeFontScale = 1.0;
  bool _codeWrapLines = false;
  String _selectedPathId = '';
  double _sandboxFontScale = 1.0;
  bool _reviewReminderEnabled = false;
  int _dailyGoalMinutes = 20;
  int _reviewSessionMinutes = 30;
  String _goalCelebratedDate = '';
  bool _autoBackupEnabled = false;
  int _autoBackupIntervalDays = 1;
  int _autoBackupKeepCount = 5;
  DateTime? _autoBackupLastAt;
  int _reminderHour = 20;
  int _reminderMinute = 0;
  List<String> _searchHistory = <String>[];

  ThemeMode get themeMode => _themeMode;
  String get localeCode => _localeCode;
  Locale get locale => Locale(_localeCode);

  bool get isEnglish => _localeCode == 'en';

  /// 教程正文字号缩放（0.85 ~ 1.4），影响 Markdown 正文与代码字号。
  double get readingFontScale => _readingFontScale;

  /// 减少界面动画，配合系统无障碍设置使用。
  bool get reduceMotion => _reduceMotion;

  /// 代码块字号缩放（0.8 ~ 1.6），与正文缩放独立。
  double get codeFontScale => _codeFontScale;

  /// 代码块是否自动换行；关闭时保持横向滚动，避免长行被截断语义。
  bool get codeWrapLines => _codeWrapLines;

  /// 用户选定的学习目标路径 ID；为空表示尚未选择目标。
  String get selectedPathId => _selectedPathId;

  /// 代码沙箱编辑器的字号缩放（0.8 ~ 1.8）。
  double get sandboxFontScale => _sandboxFontScale;

  Future<void> setSandboxFontScale(double value) async {
    final clamped = value.clamp(0.8, 1.8);
    if ((_sandboxFontScale - clamped).abs() < 0.001) return;
    _sandboxFontScale = clamped;
    notifyListeners();
    await _storage.write('sandbox_font_scale', clamped);
  }

  Future<void> setCodeFontScale(double value) async {
    final clamped = value.clamp(0.8, 1.6);
    if ((_codeFontScale - clamped).abs() < 0.001) return;
    _codeFontScale = clamped;
    notifyListeners();
    await _storage.write('code_font_scale', clamped);
  }

  Future<void> setCodeWrapLines(bool value) async {
    if (_codeWrapLines == value) return;
    _codeWrapLines = value;
    notifyListeners();
    await _storage.write('code_wrap_lines', value);
  }

  Future<void> setSelectedPathId(String pathId) async {
    if (_selectedPathId == pathId) return;
    _selectedPathId = pathId;
    notifyListeners();
    await _storage.write('selected_path_id', pathId);
  }

  /// 是否开启每日复习提醒。
  bool get reviewReminderEnabled => _reviewReminderEnabled;

  /// 每日学习目标（分钟），默认 20 分钟，可在设置中调整。
  int get dailyGoalMinutes => _dailyGoalMinutes;

  /// 每次复习场次的时间预算（分钟），默认 30 分钟。
  int get reviewSessionMinutes => _reviewSessionMinutes;

  /// 已经庆祝过目标的日期（yyyy-MM-dd），用于每天只提醒一次。
  String get goalCelebratedDate => _goalCelebratedDate;

  Future<void> setDailyGoalMinutes(int value) async {
    final clamped = value.clamp(5, 240);
    if (_dailyGoalMinutes == clamped) return;
    _dailyGoalMinutes = clamped;
    notifyListeners();
    await _storage.write('daily_goal_minutes', clamped);
  }

  Future<void> setReviewSessionMinutes(int value) async {
    final clamped = value.clamp(5, 120);
    if (_reviewSessionMinutes == clamped) return;
    _reviewSessionMinutes = clamped;
    notifyListeners();
    await _storage.write('review_session_minutes', clamped);
  }

  /// 记录某天已经庆祝过目标达成，避免重复发通知。
  Future<void> markGoalCelebrated(String dayKey) async {
    if (_goalCelebratedDate == dayKey) return;
    _goalCelebratedDate = dayKey;
    await _storage.write('goal_celebrated_date', dayKey);
  }

  /// 是否开启自动备份（备份到用户选定的 SAF 目录）。
  bool get autoBackupEnabled => _autoBackupEnabled;

  /// 自动备份间隔：1 = 每天，7 = 每周。
  int get autoBackupIntervalDays => _autoBackupIntervalDays;

  /// 备份目录中保留的最近份数。
  int get autoBackupKeepCount => _autoBackupKeepCount;

  /// 上次自动备份时间；从未备份过时为 null。
  DateTime? get autoBackupLastAt => _autoBackupLastAt;

  Future<void> setAutoBackupEnabled(bool value) async {
    if (_autoBackupEnabled == value) return;
    _autoBackupEnabled = value;
    notifyListeners();
    await _storage.write('auto_backup_enabled', value);
  }

  Future<void> setAutoBackupIntervalDays(int value) async {
    final normalized = value == 7 ? 7 : 1;
    if (_autoBackupIntervalDays == normalized) return;
    _autoBackupIntervalDays = normalized;
    notifyListeners();
    await _storage.write('auto_backup_interval_days', normalized);
  }

  Future<void> setAutoBackupKeepCount(int value) async {
    final clamped = value.clamp(2, 20);
    if (_autoBackupKeepCount == clamped) return;
    _autoBackupKeepCount = clamped;
    notifyListeners();
    await _storage.write('auto_backup_keep_count', clamped);
  }

  /// 记录一次自动备份成功的时间。
  Future<void> markAutoBackupDone(DateTime value) async {
    _autoBackupLastAt = value;
    notifyListeners();
    await _storage.write('auto_backup_last_at', value.toIso8601String());
  }

  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;

  /// 最近搜索词，最新的在最前面，最多保留 12 条。
  List<String> get searchHistory => List<String>.unmodifiable(_searchHistory);

  /// 「20:00」形式的提醒时间文本。
  String get reminderTimeLabel =>
      '${_reminderHour.toString().padLeft(2, '0')}:'
      '${_reminderMinute.toString().padLeft(2, '0')}';

  Future<void> setReviewReminderEnabled(bool value) async {
    if (_reviewReminderEnabled == value) return;
    _reviewReminderEnabled = value;
    notifyListeners();
    await _storage.write('review_reminder_enabled', value);
  }

  Future<void> setReminderTime(int hour, int minute) async {
    _reminderHour = hour.clamp(0, 23);
    _reminderMinute = minute.clamp(0, 59);
    notifyListeners();
    await _storage.write('review_reminder_hour', _reminderHour);
    await _storage.write('review_reminder_minute', _reminderMinute);
  }

  Future<void> setReadingFontScale(double value) async {
    final clamped = value.clamp(0.85, 1.4);
    if ((_readingFontScale - clamped).abs() < 0.001) return;
    _readingFontScale = clamped;
    notifyListeners();
    await _storage.write('reading_font_scale', clamped);
  }

  Future<void> setReduceMotion(bool value) async {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    notifyListeners();
    await _storage.write('reduce_motion', value);
  }

  /// 记住一次搜索；重复词会移动到最前面。
  Future<void> rememberSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return;
    _searchHistory
      ..remove(query)
      ..insert(0, query);
    if (_searchHistory.length > 12) {
      _searchHistory = _searchHistory.take(12).toList();
    }
    notifyListeners();
    await _storage.write('search_history', _searchHistory);
  }

  Future<void> clearSearchHistory() async {
    if (_searchHistory.isEmpty) return;
    _searchHistory = <String>[];
    notifyListeners();
    await _storage.write('search_history', <String>[]);
  }

  /// 在浅色 / 深色 / 跟随系统之间循环切换。
  Future<void> cycleThemeMode() async {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
    await _storage.write('theme_mode', _themeMode.name);
  }

  /// 直接设置主题模式（供设置页的分段控件调用）。
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _storage.write('theme_mode', mode.name);
  }

  Future<void> toggleLocale() async {
    _localeCode = _localeCode == 'zh' ? 'en' : 'zh';
    notifyListeners();
    await _storage.write('locale_code', _localeCode);
  }

  ThemeMode _themeModeFromName(String name) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }
}
