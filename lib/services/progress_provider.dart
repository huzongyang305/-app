import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../models/quiz_result.dart';
import '../models/review_grade.dart';
import 'backup_document_service.dart';
import 'storage_service.dart';

/// 学习进度：已学知识点、收藏、笔记与测验成绩。
class ProgressProvider extends ChangeNotifier {
  ProgressProvider(this._storage) {
    _learnedIds = _storage.readStringSet('learned_ids');
    _favoriteIds = _storage.readStringSet('favorite_ids');
    _restoreNotes();
    _restoreQuizResults();
    _restoreWrongCounts();
    _restoreReview();
    _restoreStudyDays();
    _restoreActivity();
  }

  final StorageService _storage;

  Set<String> _learnedIds = <String>{};
  Set<String> _favoriteIds = <String>{};
  Set<String> _noteIds = <String>{};
  Set<String> _quizIds = <String>{};
  final Map<String, Note> _notes = <String, Note>{};
  final Map<String, QuizResult> _quizResults = <String, QuizResult>{};
  final Map<String, int> _wrongCounts = <String, int>{};
  final Map<String, String> _reviewDue = <String, String>{};
  final Map<String, int> _reviewStage = <String, int>{};
  final Map<String, String> _reviewGrade = <String, String>{};
  final Set<String> _studyDays = <String>{};
  final Map<String, int> _dailyActivity = <String, int>{};
  String? _lastLessonId;

  /// 复习间隔（天）：全对则逐级拉长，答错回到第 1 级。
  static const List<int> _reviewIntervals = <int>[1, 3, 7, 30];

  Set<String> get learnedIds => _learnedIds;
  Set<String> get favoriteIds => _favoriteIds;
  Map<String, Note> get notes => Map.unmodifiable(_notes);
  Map<String, QuizResult> get quizResults => Map.unmodifiable(_quizResults);

  bool isLearned(String lessonId) => _learnedIds.contains(lessonId);
  bool isFavorite(String lessonId) => _favoriteIds.contains(lessonId);

  Note? noteOf(String lessonId) => _notes[lessonId];
  QuizResult? resultOf(String lessonId) => _quizResults[lessonId];

  /// 错题本：键为「知识点ID#题号」，值为答错次数。
  int wrongCountFor(String lessonId) => _wrongCounts.entries
      .where((entry) => entry.key.startsWith('$lessonId#'))
      .fold(0, (sum, entry) => sum + entry.value);

  int get totalWrongQuestions => _wrongCounts.length;

  /// 错题本原始键集合（`知识点ID#题号`），供「错题重练」组卷使用。
  List<String> get wrongQuestionKeys =>
      List<String>.unmodifiable(_wrongCounts.keys);

  /// 某一道题的历史答错次数（0 表示不在错题本中）。
  int wrongCountOf(String lessonId, int questionIndex) =>
      _wrongCounts['$lessonId#$questionIndex'] ?? 0;

  /// 今日待复习的知识点（已到期或逾期），按到期时间升序。
  List<String> get dueReviewLessonIds {
    final now = DateTime.now();
    final entries = _reviewDue.entries.where((entry) {
      final due = DateTime.tryParse(entry.value);
      return due != null && !due.isAfter(now);
    }).toList()..sort((a, b) => a.value.compareTo(b.value));
    return entries.map((entry) => entry.key).toList();
  }

  int get dueReviewCount => dueReviewLessonIds.length;

  /// 供测试与调试查看某知识点的下次复习时间。
  DateTime? reviewDueAt(String lessonId) =>
      DateTime.tryParse(_reviewDue[lessonId] ?? '');

  /// 连续学习天数：今天或昨天学过即算连续，中断一天则归零。
  int get streakDays {
    if (_studyDays.isEmpty) return 0;
    var day = DateTime.now();
    if (!_studyDays.contains(_dayKey(day))) {
      day = day.subtract(const Duration(days: 1));
      if (!_studyDays.contains(_dayKey(day))) return 0;
    }
    var streak = 0;
    while (_studyDays.contains(_dayKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  Future<void> _markStudyToday() async {
    if (_studyDays.add(_dayKey(DateTime.now()))) {
      await _storage.write('study_days', _studyDays.toList());
    }
  }

  /// 最近 [days] 天是否学习过（最后一项是今天），用于首页签到格子。
  List<bool> recentStudyDays(int days) {
    final now = DateTime.now();
    return List<bool>.generate(
      days,
      (index) => _studyDays.contains(
        _dayKey(now.subtract(Duration(days: days - 1 - index))),
      ),
      growable: false,
    );
  }

  bool get signedToday => _studyDays.contains(_dayKey(DateTime.now()));

  /// 最近 [days] 天每天的学习活动量（学完知识点或完成测验计 1 次）。
  List<int> dailyActivity(int days) {
    final now = DateTime.now();
    return List<int>.generate(
      days,
      (index) =>
          _dailyActivity[_dayKey(
            now.subtract(Duration(days: days - 1 - index)),
          )] ??
          0,
      growable: false,
    );
  }

  /// 最近一次学习或测验的知识点 ID。
  String? get lastLessonId => _lastLessonId;

  Future<void> _recordActivity(String lessonId) async {
    final key = _dayKey(DateTime.now());
    _dailyActivity[key] = (_dailyActivity[key] ?? 0) + 1;
    _lastLessonId = lessonId;
    await _storage.write(
      'daily_activity',
      Map<String, int>.from(_dailyActivity),
    );
    await _storage.write('last_lesson_id', lessonId);
  }

  /// 首页手动签到（打开教程或做测验同样会自动记为当天已学）。
  Future<void> checkInToday() async {
    await _markStudyToday();
    notifyListeners();
  }

  /// 复习调度：perfect 为真表示本次全对。
  Future<void> scheduleReview(String lessonId, {required bool perfect}) async {
    // 兼容旧调用：全对视为「记得」，否则视为「忘记了」。
    await scheduleReviewWithGrade(
      lessonId,
      perfect ? ReviewGrade.remembered : ReviewGrade.forgot,
    );
  }

  /// 三档自评复习调度：忘记回到第 1 档，模糊保持当前档，记得进入下一档。
  Future<void> scheduleReviewWithGrade(
    String lessonId,
    ReviewGrade grade,
  ) async {
    final maxStage = _reviewIntervals.length;
    // 未建立复习计划时视为第 0 档：首次「记得」落到第 1 档（1 天），
    // 与旧的 scheduleReview(perfect: true) 行为保持一致。
    final current = _reviewStage[lessonId] ?? 0;
    final int stage;
    switch (grade) {
      case ReviewGrade.forgot:
        stage = 1;
      case ReviewGrade.fuzzy:
        stage = current.clamp(1, maxStage);
      case ReviewGrade.remembered:
        stage = (current + 1).clamp(1, maxStage);
    }

    _reviewStage[lessonId] = stage;
    _reviewGrade[lessonId] = grade.storageKey;
    _reviewDue[lessonId] = DateTime.now()
        .add(Duration(days: _reviewIntervals[stage - 1]))
        .toIso8601String();
    notifyListeners();
    await _persistReview();
  }

  /// 某个知识点上次自评的档位（未评过则为 null）。
  ReviewGrade? reviewGradeOf(String lessonId) =>
      ReviewGrade.fromStorage(_reviewGrade[lessonId]);

  /// 某个知识点当前档位对应的复习间隔天数。
  int nextReviewDays(String lessonId) {
    final stage = (_reviewStage[lessonId] ?? 1).clamp(
      1,
      _reviewIntervals.length,
    );
    return _reviewIntervals[stage - 1];
  }

  Future<void> _persistReview() async {
    await _storage.write('review_due', Map<String, String>.from(_reviewDue));
    await _storage.write('review_stage', Map<String, int>.from(_reviewStage));
    await _storage.write(
      'review_grade',
      Map<String, String>.from(_reviewGrade),
    );
  }

  Future<void> recordWrong(String lessonId, int questionIndex) async {
    final key = '$lessonId#$questionIndex';
    _wrongCounts[key] = (_wrongCounts[key] ?? 0) + 1;
    notifyListeners();
    await _storage.write('wrong_counts', Map<String, int>.from(_wrongCounts));
  }

  Future<void> clearWrong(String lessonId, int questionIndex) async {
    final key = '$lessonId#$questionIndex';
    if (_wrongCounts.remove(key) != null) {
      notifyListeners();
      await _storage.write('wrong_counts', Map<String, int>.from(_wrongCounts));
    }
  }

  /// 学习进度 = 已学知识点 / 全部知识点。
  double learnedRatio(int totalLessons) {
    if (totalLessons == 0) return 0;
    return _learnedIds.length / totalLessons;
  }

  /// 测验平均正确率，只统计做过测验的知识点。
  double get averageQuizAccuracy {
    if (_quizResults.isEmpty) return 0;
    final total = _quizResults.values
        .map((result) => result.accuracy)
        .fold<double>(0, (sum, value) => sum + value);
    return total / _quizResults.length;
  }

  /// 打开教程时自动标记为已学。
  Future<void> markLearned(String lessonId) async {
    if (_learnedIds.add(lessonId)) {
      await _recordActivity(lessonId);
      await _markStudyToday();
      if (!_reviewDue.containsKey(lessonId)) {
        _reviewStage[lessonId] = 1;
        _reviewDue[lessonId] = DateTime.now()
            .add(Duration(days: _reviewIntervals.first))
            .toIso8601String();
        await _persistReview();
      }
      notifyListeners();
      await _storage.write('learned_ids', _learnedIds.toList());
    }
  }

  Future<void> unmarkLearned(String lessonId) async {
    if (_learnedIds.remove(lessonId)) {
      notifyListeners();
      await _storage.write('learned_ids', _learnedIds.toList());
    }
  }

  Future<void> toggleFavorite(String lessonId) async {
    if (!_favoriteIds.remove(lessonId)) {
      _favoriteIds.add(lessonId);
    }
    notifyListeners();
    await _storage.write('favorite_ids', _favoriteIds.toList());
  }

  Future<void> saveNote(String lessonId, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      _notes.remove(lessonId);
      _noteIds.remove(lessonId);
      await _storage.delete('note_$lessonId');
      await _storage.write('all_note_ids', _noteIds.toList());
    } else {
      final note = Note(
        lessonId: lessonId,
        content: trimmed,
        updatedAt: DateTime.now(),
      );
      _notes[lessonId] = note;
      _noteIds.add(lessonId);
      await _storage.write('note_$lessonId', note.toJson());
      await _storage.write('all_note_ids', _noteIds.toList());
    }
    notifyListeners();
  }

  /// 保存测验成绩：保留历史最好成绩，同时累加作答次数。
  Future<void> saveQuizResult(String lessonId, int correct, int total) async {
    await _markStudyToday();
    await _recordActivity(lessonId);
    final previous = _quizResults[lessonId];
    final attempts = (previous?.attempts ?? 0) + 1;
    final isBetter = previous == null || correct > previous.correct;

    final result = QuizResult(
      lessonId: lessonId,
      correct: isBetter ? correct : previous.correct,
      total: total,
      attempts: attempts,
      updatedAt: DateTime.now(),
    );
    _quizResults[lessonId] = result;
    _quizIds.add(lessonId);
    notifyListeners();
    await _storage.write('quiz_result_$lessonId', result.toJson());
    await _storage.write('all_quiz_ids', _quizIds.toList());
  }

  void _restoreNotes() {
    final raw = _storage.read('all_note_ids', defaultValue: const <String>[]);
    _noteIds = (raw as List).map((item) => item.toString()).toSet();
    for (final id in _noteIds) {
      final data = _storage.read('note_$id');
      if (data is Map) {
        final note = Note.fromJson(data.cast<String, dynamic>());
        _notes[note.lessonId] = note;
      }
    }
  }

  void _restoreQuizResults() {
    final raw = _storage.read('all_quiz_ids', defaultValue: const <String>[]);
    _quizIds = (raw as List).map((item) => item.toString()).toSet();
    for (final id in _quizIds) {
      final data = _storage.read('quiz_result_$id');
      if (data is Map) {
        final result = QuizResult.fromJson(data.cast<String, dynamic>());
        _quizResults[result.lessonId] = result;
      }
    }
  }

  void _restoreWrongCounts() {
    final data = _storage.read('wrong_counts');
    if (data is Map) {
      data.forEach((key, value) {
        if (value is int && value > 0) {
          _wrongCounts[key.toString()] = value;
        }
      });
    }
  }

  void _restoreReview() {
    final due = _storage.read('review_due');
    if (due is Map) {
      due.forEach(
        (key, value) => _reviewDue[key.toString()] = value.toString(),
      );
    }
    final stage = _storage.read('review_stage');
    if (stage is Map) {
      stage.forEach((key, value) {
        if (value is int) _reviewStage[key.toString()] = value;
      });
    }
    final grade = _storage.read('review_grade');
    if (grade is Map) {
      grade.forEach((key, value) {
        _reviewGrade[key.toString()] = value.toString();
      });
    }
  }

  void _restoreStudyDays() {
    final raw = _storage.read('study_days', defaultValue: const <String>[]);
    _studyDays
      ..clear()
      ..addAll((raw as List).map((item) => item.toString()));
  }

  void _restoreActivity() {
    final activity = _storage.read('daily_activity');
    if (activity is Map) {
      activity.forEach((key, value) {
        if (value is int) _dailyActivity[key.toString()] = value;
      });
    }
    _lastLessonId = _storage.read('last_lesson_id') as String?;
  }

  /// 教程滚动位置：按知识点记录，用于「继续上次位置阅读」。
  double readingOffset(String lessonId) {
    final value = _storage.read('reading_offset_$lessonId', defaultValue: 0.0);
    return value is num ? value.toDouble() : 0.0;
  }

  Future<void> saveReadingOffset(String lessonId, double offset) async {
    if (offset < 1) return;
    await _storage.write('reading_offset_$lessonId', offset);
  }

  /// 导出全部本地数据为可读 JSON（用于换机备份）。
  Map<String, dynamic> exportData() =>
      BackupDocumentService.prepareForExport(<String, dynamic>{
        'learned_ids': _learnedIds.toList(),
        'favorite_ids': _favoriteIds.toList(),
        'quiz_results': _quizResults.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'wrong_counts': Map<String, int>.from(_wrongCounts),
        'review_due': Map<String, String>.from(_reviewDue),
        'review_stage': Map<String, int>.from(_reviewStage),
        'review_grade': Map<String, String>.from(_reviewGrade),
        'study_days': _studyDays.toList(),
        'daily_activity': Map<String, int>.from(_dailyActivity),
        'notes': _notes.map((key, value) => MapEntry(key, value.toJson())),
      });

  /// 从导出的 JSON 恢复数据（覆盖当前内存与本地存储）。
  Future<void> importData(Map<String, dynamic> data) async {
    data = BackupDocumentService.normalizeForImport(data);
    await _storage.write(
      'learned_ids',
      List<String>.from((data['learned_ids'] as List?) ?? const []),
    );
    await _storage.write(
      'favorite_ids',
      List<String>.from((data['favorite_ids'] as List?) ?? const []),
    );

    final quizzes = (data['quiz_results'] as Map?) ?? const {};
    final quizIds = <String>[];
    for (final entry in quizzes.entries) {
      final id = entry.key.toString();
      final json = (entry.value as Map).cast<String, dynamic>();
      await _storage.write('quiz_result_$id', json);
      quizIds.add(id);
    }
    await _storage.write('all_quiz_ids', quizIds);

    final wrong = (data['wrong_counts'] as Map?) ?? const {};
    await _storage.write('wrong_counts', wrong);

    final notes = (data['notes'] as Map?) ?? const {};
    final noteIds = <String>[];
    for (final entry in notes.entries) {
      final id = entry.key.toString();
      final json = (entry.value as Map).cast<String, dynamic>();
      await _storage.write('note_$id', json);
      noteIds.add(id);
    }
    await _storage.write('all_note_ids', noteIds);

    await _storage.write(
      'study_days',
      (data['study_days'] as List?) ?? const [],
    );
    await _storage.write(
      'daily_activity',
      (data['daily_activity'] as Map?) ?? const {},
    );
    await _storage.write(
      'review_due',
      (data['review_due'] as Map?) ?? const {},
    );
    await _storage.write(
      'review_stage',
      (data['review_stage'] as Map?) ?? const {},
    );
    await _storage.write(
      'review_grade',
      (data['review_grade'] as Map?) ?? const {},
    );
    // 上次学习位置不在备份范围内，恢复时一并清掉，避免指向上一个设备的内容。
    await _storage.delete('last_lesson_id');

    // 覆盖内存状态前先清空，否则恢复出来的数据会与旧数据混合。
    _learnedIds = _storage.readStringSet('learned_ids');
    _favoriteIds = _storage.readStringSet('favorite_ids');
    _quizResults.clear();
    _quizIds = quizIds.toSet();
    _restoreQuizResults();
    _wrongCounts.clear();
    _restoreWrongCounts();
    _reviewDue.clear();
    _reviewStage.clear();
    _restoreReview();
    _studyDays.clear();
    _restoreStudyDays();
    _dailyActivity.clear();
    _restoreActivity();
    _notes.clear();
    _noteIds = noteIds.toSet();
    _restoreNotes();
    notifyListeners();
  }
}
