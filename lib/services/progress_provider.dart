import 'package:flutter/foundation.dart';

import '../models/lesson.dart';
import '../models/note.dart';
import '../models/quiz_result.dart';
import '../models/review_grade.dart';
import 'backup_document_service.dart';
import 'practice_question_factory.dart';
import 'review_planner.dart';
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
    _restoreStudySeconds();
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
  final Map<String, double> _reviewEase = <String, double>{};
  final Map<String, int> _reviewInterval = <String, int>{};
  final Map<String, int> _reviewRepetitions = <String, int>{};
  final Set<String> _studyDays = <String>{};
  final Map<String, int> _dailyActivity = <String, int>{};
  final Map<String, int> _dailyStudySeconds = <String, int>{};
  String? _lastLessonId;

  /// SM-2 风格的复习参数：难度系数越高，间隔拉长越快。
  static const double _initialEase = 2.5;
  static const double _minEase = 1.3;
  static const double _maxEase = 3.0;
  static const int _maxIntervalDays = 180;

  /// 旧版固定档位，仅用于把老数据迁移成新的间隔天数。
  static const List<int> _legacyIntervals = <int>[1, 3, 7, 30];

  Set<String> get learnedIds => _learnedIds;
  Set<String> get favoriteIds => _favoriteIds;
  Map<String, Note> get notes => Map.unmodifiable(_notes);
  Map<String, QuizResult> get quizResults => Map.unmodifiable(_quizResults);

  bool isLearned(String lessonId) => _learnedIds.contains(lessonId);
  bool isFavorite(String lessonId) => _favoriteIds.contains(lessonId);

  Note? noteOf(String lessonId) => _notes[lessonId];
  QuizResult? resultOf(String lessonId) => _quizResults[lessonId];

  /// 全部笔记标签（去重、按使用频率降序）。
  List<String> get allNoteTags {
    final counts = <String, int>{};
    for (final note in _notes.values) {
      for (final tag in note.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final tags = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return List<String>.unmodifiable(tags);
  }

  /// 跨课程笔记检索：按正文、标签和知识点 ID 匹配，按更新时间倒序。
  List<Note> searchNotes(String query, {String? tag}) {
    final keyword = query.trim().toLowerCase();
    final results = _notes.values.where((note) {
      if (tag != null && !note.tags.contains(tag)) return false;
      if (keyword.isEmpty) return true;
      if (note.content.toLowerCase().contains(keyword)) return true;
      if (note.lessonId.toLowerCase().contains(keyword)) return true;
      return note.tags.any((item) => item.toLowerCase().contains(keyword));
    }).toList();
    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<Note>.unmodifiable(results);
  }

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

  /// 今日已记录的真实学习时长（秒），由教程页在离开时回传。
  int get studySecondsToday => _dailyStudySeconds[_dayKey(DateTime.now())] ?? 0;

  /// 累计学习时长（分钟）。
  int get totalStudyMinutes =>
      _dailyStudySeconds.values.fold<int>(0, (sum, value) => sum + value) ~/ 60;

  /// 最近 [days] 天每天的学习时长（分钟，向上取整），最后一项是今天。
  List<int> dailyStudyMinutes(int days) {
    final now = DateTime.now();
    return List<int>.generate(days, (index) {
      final seconds =
          _dailyStudySeconds[_dayKey(
            now.subtract(Duration(days: days - 1 - index)),
          )] ??
          0;
      return (seconds / 60).ceil();
    }, growable: false);
  }

  /// 最近 [days] 天的学习时长合计（分钟）。
  int studyMinutesInLastDays(int days) =>
      dailyStudyMinutes(days).fold<int>(0, (sum, value) => sum + value);

  /// 记录一次真实学习时长；单次上限 2 小时，低于 5 秒的抖动直接忽略。
  Future<void> addStudySeconds(String lessonId, int seconds) async {
    final value = seconds.clamp(0, 7200);
    if (value < 5) return;
    final key = _dayKey(DateTime.now());
    _dailyStudySeconds[key] = (_dailyStudySeconds[key] ?? 0) + value;
    _lastLessonId = lessonId;
    await _markStudyToday();
    await _storage.write(
      'daily_study_seconds',
      Map<String, int>.from(_dailyStudySeconds),
    );
    await _storage.write('last_lesson_id', lessonId);
    notifyListeners();
  }

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
  Future<void> scheduleReview(
    String lessonId, {
    required bool perfect,
    double? accuracy,
    int wrongCount = 0,
    String difficulty = '基础',
  }) async {
    // 兼容旧调用：全对视为「记得」，否则视为「忘记了」。
    await scheduleReviewWithGrade(
      lessonId,
      perfect ? ReviewGrade.remembered : ReviewGrade.forgot,
      accuracy: accuracy,
      wrongCount: wrongCount,
      difficulty: difficulty,
    );
  }

  /// 三档自评 + SM-2 风格调度。
  ///
  /// · 记得：重复次数 +1，按「1 天 → 3 天 → 上次间隔 × 难度系数」拉长；
  /// · 模糊：重复次数不变，间隔小幅增长，难度系数下调；
  /// · 忘记：重复次数归零，间隔回到 1 天，难度系数下调。
  ///
  /// 另外，正确率低于 60%、错题本里仍有记录、课程本身越难，都会缩短间隔。
  Future<void> scheduleReviewWithGrade(
    String lessonId,
    ReviewGrade grade, {
    double? accuracy,
    int wrongCount = 0,
    String difficulty = '基础',
  }) async {
    final ease = (_reviewEase[lessonId] ?? _initialEase)
        .clamp(_minEase, _maxEase)
        .toDouble();
    final repetitions = _reviewRepetitions[lessonId] ?? 0;
    final previous = _reviewInterval[lessonId] ?? 0;

    var nextEase = ease;
    var nextRepetitions = repetitions;
    var interval = previous;
    switch (grade) {
      case ReviewGrade.forgot:
        nextRepetitions = 0;
        nextEase = ease - 0.25;
        interval = 1;
      case ReviewGrade.fuzzy:
        nextEase = ease - 0.12;
        interval = repetitions == 0 ? 1 : (previous * 1.2).round();
      case ReviewGrade.remembered:
        nextRepetitions = repetitions + 1;
        nextEase = ease + 0.08;
        if (nextRepetitions <= 1) {
          interval = 1;
        } else if (nextRepetitions == 2) {
          interval = 3;
        } else {
          interval = (previous * nextEase).round();
        }
    }

    if (accuracy != null && accuracy < 0.6) {
      nextEase -= 0.15;
      interval = (interval * 0.7).round();
    }
    if (wrongCount > 0) {
      interval = (interval * 0.85).round();
    }
    interval = (interval * _difficultyFactor(difficulty)).round().clamp(
      1,
      _maxIntervalDays,
    );
    nextEase = nextEase.clamp(_minEase, _maxEase).toDouble();

    _reviewEase[lessonId] = double.parse(nextEase.toStringAsFixed(3));
    _reviewRepetitions[lessonId] = nextRepetitions;
    _reviewInterval[lessonId] = interval;
    _reviewStage[lessonId] = nextRepetitions + 1;
    _reviewGrade[lessonId] = grade.storageKey;
    _reviewDue[lessonId] = DateTime.now()
        .add(Duration(days: interval))
        .toIso8601String();
    notifyListeners();
    await _persistReview();
  }

  /// 课程难度对复习间隔的影响：入门内容可以放慢复习节奏，高级内容更密。
  static double _difficultyFactor(String difficulty) => switch (difficulty) {
    '入门' => 1.15,
    '进阶' => 0.9,
    '高级' => 0.8,
    _ => 1.0,
  };

  /// 某个知识点上次自评的档位（未评过则为 null）。
  ReviewGrade? reviewGradeOf(String lessonId) =>
      ReviewGrade.fromStorage(_reviewGrade[lessonId]);

  /// 某个知识点当前档位对应的复习间隔天数。
  int nextReviewDays(String lessonId) =>
      (_reviewInterval[lessonId] ?? 1).clamp(1, _maxIntervalDays);

  /// 当前记忆难度系数（越大表示越容易记住），供学习分析使用。
  double easeFactorOf(String lessonId) => _reviewEase[lessonId] ?? _initialEase;

  /// 今日复习计划：按逾期程度与用时排序，并给出总用时与顺延数量。
  ReviewPlan reviewPlanFor(List<Lesson> lessons, {int budgetMinutes = 30}) {
    final byId = <String, Lesson>{
      for (final lesson in lessons)
        if (lesson.totalQuestionCount > 0) lesson.id: lesson,
    };
    final candidates = <ReviewCandidate>[];
    for (final lessonId in dueReviewLessonIds) {
      final lesson = byId[lessonId];
      if (lesson == null) continue;
      candidates.add(
        ReviewCandidate(lesson: lesson, dueAt: reviewDueAt(lessonId)),
      );
    }
    return buildReviewPlan(candidates, budgetMinutes: budgetMinutes);
  }

  Future<void> _persistReview() async {
    await _storage.write('review_due', Map<String, String>.from(_reviewDue));
    await _storage.write('review_stage', Map<String, int>.from(_reviewStage));
    await _storage.write(
      'review_grade',
      Map<String, String>.from(_reviewGrade),
    );
    await _storage.write('review_ease', Map<String, double>.from(_reviewEase));
    await _storage.write(
      'review_interval',
      Map<String, int>.from(_reviewInterval),
    );
    await _storage.write(
      'review_repetitions',
      Map<String, int>.from(_reviewRepetitions),
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
        _reviewEase.putIfAbsent(lessonId, () => _initialEase);
        // 首次阅读本身算第 1 次成功重复：1 天后复习，再成功后进入 3 天。
        _reviewRepetitions.putIfAbsent(lessonId, () => 1);
        _reviewInterval[lessonId] = 1;
        _reviewStage[lessonId] = 1;
        _reviewDue[lessonId] = DateTime.now()
            .add(const Duration(days: 1))
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

  Future<void> saveNote(
    String lessonId,
    String content, {
    List<String> tags = const <String>[],
  }) async {
    final trimmed = content.trim();
    final normalizedTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);
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
        tags: normalizedTags,
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
    final ease = _storage.read('review_ease');
    if (ease is Map) {
      ease.forEach((key, value) {
        if (value is num) _reviewEase[key.toString()] = value.toDouble();
      });
    }
    final interval = _storage.read('review_interval');
    if (interval is Map) {
      interval.forEach((key, value) {
        if (value is int && value > 0) {
          _reviewInterval[key.toString()] = value;
        }
      });
    }
    final repetitions = _storage.read('review_repetitions');
    if (repetitions is Map) {
      repetitions.forEach((key, value) {
        if (value is int && value >= 0) {
          _reviewRepetitions[key.toString()] = value;
        }
      });
    }
    // 老版本只存了档位：换算成等效的间隔天数与重复次数，保证升级后不丢进度。
    for (final entry in _reviewStage.entries) {
      if (_reviewInterval.containsKey(entry.key)) continue;
      final level = entry.value.clamp(1, _legacyIntervals.length);
      _reviewInterval[entry.key] = _legacyIntervals[level - 1];
      _reviewRepetitions.putIfAbsent(entry.key, () => level - 1);
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

  void _restoreStudySeconds() {
    final data = _storage.read('daily_study_seconds');
    if (data is Map) {
      data.forEach((key, value) {
        if (value is int && value > 0) {
          _dailyStudySeconds[key.toString()] = value;
        }
      });
    }
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
        'review_ease': Map<String, double>.from(_reviewEase),
        'review_interval': Map<String, int>.from(_reviewInterval),
        'review_repetitions': Map<String, int>.from(_reviewRepetitions),
        'study_days': _studyDays.toList(),
        'daily_activity': Map<String, int>.from(_dailyActivity),
        'daily_study_seconds': Map<String, int>.from(_dailyStudySeconds),
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
      'daily_study_seconds',
      (data['daily_study_seconds'] as Map?) ?? const {},
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
    await _storage.write(
      'review_ease',
      (data['review_ease'] as Map?) ?? const {},
    );
    await _storage.write(
      'review_interval',
      (data['review_interval'] as Map?) ?? const {},
    );
    await _storage.write(
      'review_repetitions',
      (data['review_repetitions'] as Map?) ?? const {},
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
    _reviewGrade.clear();
    _reviewEase.clear();
    _reviewInterval.clear();
    _reviewRepetitions.clear();
    _restoreReview();
    _studyDays.clear();
    _restoreStudyDays();
    _dailyActivity.clear();
    _restoreActivity();
    _dailyStudySeconds.clear();
    _restoreStudySeconds();
    _notes.clear();
    _noteIds = noteIds.toSet();
    _restoreNotes();
    notifyListeners();
  }
}
