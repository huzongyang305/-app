import 'package:flutter/foundation.dart';

import '../models/backup_preview.dart';
import '../models/lesson.dart';
import '../models/note.dart';
import '../models/note_anchor.dart';
import '../models/quiz_answer.dart';
import '../models/quiz_result.dart';
import '../models/review_grade.dart';
import '../models/study_center.dart';
import 'backup_document_service.dart';
import 'practice_question_factory.dart';
import 'review_planner.dart';
import 'storage_service.dart';

/// 学习进度：已学知识点、收藏、笔记与测验成绩。
class ProgressProvider extends ChangeNotifier {
  ProgressProvider(this._storage, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _learnedIds = _storage.readStringSet('learned_ids');
    _favoriteIds = _storage.readStringSet('favorite_ids');
    _restoreNotes();
    _restoreQuizResults();
    _restoreWrongCounts();
    _restoreReview();
    _restoreStudyDays();
    _restoreActivity();
    _restoreStudySeconds();
    _restoreInsights();
    _restoreReviewPreferences();
    _restoreBookmarks();
    final dailyDate = _storage.read('daily_question_date', defaultValue: '');
    _dailyQuestionDate = dailyDate is String ? dailyDate : '';
    _dailyQuestionCorrect =
        _storage.read('daily_question_correct', defaultValue: false) == true;
  }

  final StorageService _storage;

  /// 可注入时钟：测试与金图使用固定时间，正式运行取系统时间。
  final DateTime Function() _now;

  /// 当前时间；按天统计与复习排期统一以它为准。
  DateTime get now => _now();

  Set<String> _learnedIds = <String>{};
  Set<String> _favoriteIds = <String>{};
  Set<String> _noteIds = <String>{};
  Set<String> _quizIds = <String>{};
  final Map<String, Note> _notes = <String, Note>{};
  final Map<String, QuizResult> _quizResults = <String, QuizResult>{};
  final Map<String, int> _wrongCounts = <String, int>{};
  final Set<String> _wrongEverKeys = <String>{};
  final Map<String, String> _reviewDue = <String, String>{};
  final Map<String, int> _reviewStage = <String, int>{};
  final Map<String, String> _reviewGrade = <String, String>{};
  final Map<String, double> _reviewEase = <String, double>{};
  final Map<String, int> _reviewInterval = <String, int>{};
  final Map<String, int> _reviewRepetitions = <String, int>{};
  final Set<String> _studyDays = <String>{};
  final Map<String, int> _dailyActivity = <String, int>{};
  final Map<String, int> _dailyStudySeconds = <String, int>{};

  /// 单题作答统计：题号 -> attempts / correct / partialScore / confidence。
  final Map<String, Map<String, dynamic>> _questionStats =
      <String, Map<String, dynamic>>{};

  /// 错因累计：概念不清、粗心、语法 / API 等。
  final Map<String, int> _errorCauseCounts = <String, int>{};

  /// 阅读书签与段落收藏。
  final Set<String> _bookmarkedIds = <String>{};

  /// 已完成挑战 ID。
  final Set<String> _challengeDoneIds = <String>{};

  /// 项目里程碑：`课程:里程碑` -> 是否完成。
  final Map<String, bool> _projectMilestones = <String, bool>{};

  /// 暂停复习的截止日期（当天及以前继续暂停）。
  String _reviewPausedUntil = '';

  /// 允许安排复习的星期（1=周一，7=周日）。
  Set<int> _reviewWeekdays = <int>{1, 2, 3, 4, 5, 6, 7};

  /// 最近复习记录，用于场次总结。
  final List<Map<String, dynamic>> _reviewHistory = <Map<String, dynamic>>[];

  /// 每日一题的作答记录：当天日期键与是否答对。
  String _dailyQuestionDate = '';
  bool _dailyQuestionCorrect = false;
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
  Set<String> get bookmarkedIds => Set<String>.unmodifiable(_bookmarkedIds);
  Map<String, int> get errorCauseCounts =>
      Map<String, int>.unmodifiable(_errorCauseCounts);

  bool isBookmarked(String lessonId) => _bookmarkedIds.contains(lessonId);
  bool isChallengeDone(String id) => _challengeDoneIds.contains(id) || false;
  bool get hasRollbackSnapshot =>
      _storage.read('backup_rollback_snapshot') is Map;

  DateTime? get reviewPausedUntil => DateTime.tryParse(_reviewPausedUntil);

  bool get reviewsPaused {
    final paused = reviewPausedUntil;
    if (paused == null) return false;
    final today = DateTime(_now().year, _now().month, _now().day);
    final until = DateTime(paused.year, paused.month, paused.day);
    return !today.isAfter(until);
  }

  Set<int> get reviewWeekdays => Set<int>.unmodifiable(_reviewWeekdays);
  List<Map<String, dynamic>> get reviewHistory =>
      List<Map<String, dynamic>>.unmodifiable(_reviewHistory);

  Map<String, dynamic>? questionStat(String key) {
    final value = _questionStats[key];
    return value == null ? null : Map<String, dynamic>.unmodifiable(value);
  }

  List<MapEntry<String, Map<String, dynamic>>> get questionStats =>
      List.unmodifiable(
        _questionStats.entries.map(
          (entry) => MapEntry(
            entry.key,
            Map<String, dynamic>.unmodifiable(entry.value),
          ),
        ),
      );

  List<String> get answeredQuestionKeysToday {
    final today = _dayKey(_now());
    return _questionStats.entries
        .where(
          (entry) =>
              entry.value['lastAt']?.toString().startsWith(today) == true,
        )
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  List<ProjectMilestone> milestonesForLesson(String lessonId) {
    const templates = <String, String>{
      'requirements': '明确需求与验收标准',
      'mvp': '完成最小可运行版本',
      'quality': '补齐错误处理与测试',
      'review': '复盘并整理项目文档',
    };
    return templates.entries
        .map(
          (entry) => ProjectMilestone(
            id: '$lessonId:${entry.key}',
            lessonId: lessonId,
            title: entry.value,
            done:
                _projectMilestones[entry.value] == true ||
                _projectMilestones['$lessonId:${entry.key}'] == true,
          ),
        )
        .toList(growable: false);
  }

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

  /// 曾经答错过的题目总数（含已经消灭的）。
  int get everWrongQuestions => _wrongEverKeys.length;

  /// 已消灭错题数：曾经答错、且现在已经不在错题本里。
  int get resolvedWrongQuestions =>
      _wrongEverKeys.where((key) => !_wrongCounts.containsKey(key)).length;

  /// 错题消灭率（0~1）；没有错题历史时为 0。
  double get wrongResolvedRatio =>
      everWrongQuestions == 0 ? 0 : resolvedWrongQuestions / everWrongQuestions;

  /// 错题本原始键集合（`知识点ID#题号`），供「错题重练」组卷使用。
  List<String> get wrongQuestionKeys =>
      List<String>.unmodifiable(_wrongCounts.keys);

  /// 某一道题的历史答错次数（0 表示不在错题本中）。
  int wrongCountOf(String lessonId, int questionIndex) =>
      _wrongCounts['$lessonId#$questionIndex'] ?? 0;

  /// 今日待复习的知识点（已到期或逾期），按到期时间升序。
  List<String> get dueReviewLessonIds {
    if (reviewsPaused || !_reviewWeekdays.contains(_now().weekday)) {
      return const <String>[];
    }
    return rawDueReviewLessonIds;
  }

  /// 不考虑暂停和星期限制的到期课程，用于设置页展示真实积压数量。
  List<String> get rawDueReviewLessonIds {
    final now = _now();
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
    var day = _now();
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
    if (_studyDays.add(_dayKey(_now()))) {
      await _storage.write('study_days', _studyDays.toList());
    }
  }

  /// 最近 [days] 天是否学习过（最后一项是今天），用于首页签到格子。
  List<bool> recentStudyDays(int days) {
    final now = _now();
    return List<bool>.generate(
      days,
      (index) => _studyDays.contains(
        _dayKey(now.subtract(Duration(days: days - 1 - index))),
      ),
      growable: false,
    );
  }

  bool get signedToday => _studyDays.contains(_dayKey(_now()));

  /// 今日已记录的真实学习时长（秒），由教程页在离开时回传。
  int get studySecondsToday => _dailyStudySeconds[_dayKey(_now())] ?? 0;

  /// 累计学习时长（分钟）。
  int get totalStudyMinutes =>
      _dailyStudySeconds.values.fold<int>(0, (sum, value) => sum + value) ~/ 60;

  /// 最近 [days] 天每天的学习时长（分钟，向上取整），最后一项是今天。
  List<int> dailyStudyMinutes(int days) {
    final now = _now();
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

  /// 某一天的学习时长（分钟，向上取整），用于日历热力图。
  int studyMinutesOn(DateTime day) =>
      ((_dailyStudySeconds[_dayKey(day)] ?? 0) / 60).ceil();

  /// 记录一次真实学习时长；单次上限 2 小时，低于 5 秒的抖动直接忽略。
  Future<void> addStudySeconds(String lessonId, int seconds) async {
    final value = seconds.clamp(0, 7200);
    if (value < 5) return;
    final key = _dayKey(_now());
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
    final now = _now();
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
    final key = _dayKey(_now());
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

  /// 今天是否已经作答每日一题。
  bool get dailyQuestionAnsweredToday => _dailyQuestionDate == _dayKey(_now());

  /// 今天每日一题的作答结果（未作答时为 false）。
  bool get dailyQuestionCorrect => _dailyQuestionCorrect;

  /// 记录每日一题的作答结果。
  Future<void> markDailyQuestionAnswered({required bool correct}) async {
    _dailyQuestionDate = _dayKey(_now());
    _dailyQuestionCorrect = correct;
    notifyListeners();
    await _storage.write('daily_question_date', _dailyQuestionDate);
    await _storage.write('daily_question_correct', correct);
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
    _reviewDue[lessonId] = _now()
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
  ReviewPlan reviewPlanFor(
    List<Lesson> lessons, {
    int budgetMinutes = 30,
    String? categoryId,
  }) {
    final byId = <String, Lesson>{
      for (final lesson in lessons)
        if (lesson.totalQuestionCount > 0 &&
            (categoryId == null || lesson.categoryId == categoryId))
          lesson.id: lesson,
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

  /// 未来 [days] 天内到期、但今天还不用复习的内容，按到期时间升序。
  ///
  /// 用于「提前复习」与未来复习日历；今天已到期的内容不在这里重复出现。
  List<ReviewCandidate> upcomingReviewCandidates(
    List<Lesson> lessons, {
    int days = 7,
    String? categoryId,
  }) {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final end = today.add(Duration(days: days));
    final byId = <String, Lesson>{
      for (final lesson in lessons)
        if (lesson.totalQuestionCount > 0 &&
            (categoryId == null || lesson.categoryId == categoryId))
          lesson.id: lesson,
    };
    final result = <ReviewCandidate>[];
    for (final entry in _reviewDue.entries) {
      final due = DateTime.tryParse(entry.value);
      if (due == null || !due.isAfter(now) || due.isAfter(end)) continue;
      final lesson = byId[entry.key];
      if (lesson == null) continue;
      result.add(ReviewCandidate(lesson: lesson, dueAt: due));
    }
    result.sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    return List<ReviewCandidate>.unmodifiable(result);
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
    _wrongEverKeys.add(key);
    // 错题自动排入复习队列：把该课的复习时间提前到最迟 1 天后，
    // 保证答错的知识点会尽快回到复习计划里。
    final target = _now().add(const Duration(days: 1));
    final current = DateTime.tryParse(_reviewDue[lessonId] ?? '');
    if (current == null || current.isAfter(target)) {
      _reviewEase.putIfAbsent(lessonId, () => _initialEase);
      _reviewRepetitions.putIfAbsent(lessonId, () => 0);
      _reviewInterval[lessonId] = 1;
      _reviewStage[lessonId] = (_reviewRepetitions[lessonId] ?? 0) + 1;
      _reviewDue[lessonId] = target.toIso8601String();
      await _persistReview();
    }
    notifyListeners();
    await _storage.write('wrong_counts', Map<String, int>.from(_wrongCounts));
    await _storage.write('wrong_ever_keys', _wrongEverKeys.toList());
  }

  /// 作答后的细分标注：修正最近一次作答的信心与错因，不重复计次。
  ///
  /// 测验页在判分后让用户自评「猜的 / 不确定 / 很确定」，并可选错因；
  /// 这里只更新最近一次记录，避免同一道题被统计成两次作答。
  Future<void> annotateAnswerOutcome(
    String lessonId,
    int questionIndex, {
    AnswerConfidence? confidence,
    String? errorCause,
  }) async {
    final key = '$lessonId#$questionIndex';
    final stat = _questionStats[key];
    if (stat == null) return;
    var changed = false;
    if (confidence != null) {
      stat['lastConfidence'] = confidence.storageKey;
      changed = true;
    }
    final cause = errorCause?.trim() ?? '';
    if (cause.isNotEmpty && stat['lastCause']?.toString() != cause) {
      final previous = stat['lastCause']?.toString() ?? '';
      if (previous.isNotEmpty) {
        final left = (_errorCauseCounts[previous] ?? 0) - 1;
        if (left > 0) {
          _errorCauseCounts[previous] = left;
        } else {
          _errorCauseCounts.remove(previous);
        }
      }
      stat['lastCause'] = cause;
      _errorCauseCounts[cause] = (_errorCauseCounts[cause] ?? 0) + 1;
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
    await _storage.write('question_stats', _questionStats);
    await _storage.write('error_cause_counts', _errorCauseCounts);
  }

  Future<void> clearWrong(String lessonId, int questionIndex) async {
    final key = '$lessonId#$questionIndex';
    if (_wrongCounts.remove(key) != null) {
      notifyListeners();
      await _storage.write('wrong_counts', Map<String, int>.from(_wrongCounts));
    }
  }

  /// 记录一次完整作答：分数、信心和错因。
  ///
  /// `score` 支持多选 / 排序的部分得分；答对时会自动从错题本移除。
  Future<void> recordAnswerOutcome(
    String lessonId,
    int questionIndex, {
    required double score,
    required AnswerConfidence confidence,
    String? errorCause,
  }) async {
    final key = '$lessonId#$questionIndex';
    final stat = _questionStats.putIfAbsent(key, () => <String, dynamic>{});
    stat['attempts'] = ((stat['attempts'] as int?) ?? 0) + 1;
    if (score >= 0.999) {
      stat['correct'] = ((stat['correct'] as int?) ?? 0) + 1;
    }
    stat['partialScore'] =
        ((stat['partialScore'] as num?)?.toDouble() ?? 0) + score;
    stat['lastConfidence'] = confidence.storageKey;
    stat['lastScore'] = score;
    stat['lastAt'] = _now().toIso8601String();
    if (errorCause != null && errorCause.trim().isNotEmpty) {
      stat['lastCause'] = errorCause.trim();
      _errorCauseCounts[errorCause.trim()] =
          (_errorCauseCounts[errorCause.trim()] ?? 0) + 1;
    }
    if (score >= 0.999) {
      _wrongCounts.remove(key);
    } else {
      _wrongCounts[key] = (_wrongCounts[key] ?? 0) + 1;
      _wrongEverKeys.add(key);
    }
    notifyListeners();
    await _storage.write('question_stats', _questionStats);
    await _storage.write('error_cause_counts', _errorCauseCounts);
    await _storage.write('wrong_counts', Map<String, int>.from(_wrongCounts));
    await _storage.write('wrong_ever_keys', _wrongEverKeys.toList());
  }

  /// 阅读书签：与收藏知识点分开，用于标记“正在读 / 稍后继续”。
  Future<void> toggleBookmark(String lessonId) async {
    if (!_bookmarkedIds.remove(lessonId)) _bookmarkedIds.add(lessonId);
    notifyListeners();
    await _storage.write('bookmarked_ids', _bookmarkedIds.toList());
  }

  /// 完成每日 / 每周挑战。
  Future<void> markChallengeDone(String id) async {
    if (!_challengeDoneIds.add(id)) return;
    notifyListeners();
    await _storage.write('challenge_done_ids', _challengeDoneIds.toList());
  }

  /// 项目里程碑勾选。
  Future<void> toggleProjectMilestone(String milestoneId, bool done) async {
    _projectMilestones[milestoneId] = done;
    notifyListeners();
    await _storage.write('project_milestones', _projectMilestones);
  }

  /// 把某门课推迟 [days] 天复习。
  Future<void> snoozeReview(String lessonId, int days) async {
    final value = days.clamp(1, 30);
    _reviewDue[lessonId] = _now().add(Duration(days: value)).toIso8601String();
    notifyListeners();
    await _persistReview();
  }

  /// 暂停全部复习到指定日期（含当天）。
  Future<void> pauseReviewsUntil(DateTime date) async {
    _reviewPausedUntil = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String();
    notifyListeners();
    await _storage.write('review_paused_until', _reviewPausedUntil);
  }

  Future<void> resumeReviews() async {
    _reviewPausedUntil = '';
    notifyListeners();
    await _storage.write('review_paused_until', '');
  }

  /// 设置允许复习的星期，至少保留一天。
  Future<void> setReviewWeekdays(Set<int> values) async {
    final normalized = values.where((item) => item >= 1 && item <= 7).toSet();
    if (normalized.isEmpty) return;
    _reviewWeekdays = normalized;
    notifyListeners();
    await _storage.write('review_weekdays', normalized.toList()..sort());
  }

  /// 记录一次复习场次，供完成总结展示。
  Future<void> recordReviewSession({
    required int lessonCount,
    required int correct,
    required int total,
    required int minutes,
  }) async {
    _reviewHistory.insert(0, <String, dynamic>{
      'at': _now().toIso8601String(),
      'lessonCount': lessonCount,
      'correct': correct,
      'total': total,
      'minutes': minutes,
    });
    if (_reviewHistory.length > 50) {
      _reviewHistory.removeRange(50, _reviewHistory.length);
    }
    notifyListeners();
    await _storage.write('review_history', _reviewHistory);
  }

  BackupPreview previewImport(Map<String, dynamic> data) {
    final normalized = BackupDocumentService.normalizeForImport(data);
    return BackupPreview.fromData(normalized);
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
        _reviewDue[lessonId] = _now()
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
    List<NoteAnchor> anchors = const <NoteAnchor>[],
    bool flashcardEnabled = true,
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
        updatedAt: _now(),
        tags: normalizedTags,
        anchors: anchors,
        flashcardEnabled: flashcardEnabled,
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
      updatedAt: _now(),
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
    final ever = _storage.read(
      'wrong_ever_keys',
      defaultValue: const <String>[],
    );
    _wrongEverKeys
      ..clear()
      ..addAll((ever as List).map((item) => item.toString()));
    // 旧版本没有历史集合：把当前错题视为曾经答错，保证升级后数据可用。
    _wrongEverKeys.addAll(_wrongCounts.keys);
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

  void _restoreInsights() {
    final stats = _storage.read('question_stats');
    if (stats is Map) {
      stats.forEach((key, value) {
        if (value is Map) {
          _questionStats[key.toString()] = value.cast<String, dynamic>();
        }
      });
    }
    final causes = _storage.read('error_cause_counts');
    if (causes is Map) {
      causes.forEach((key, value) {
        if (value is int && value > 0) {
          _errorCauseCounts[key.toString()] = value;
        }
      });
    }
    final challenges = _storage.read(
      'challenge_done_ids',
      defaultValue: const <String>[],
    );
    _challengeDoneIds
      ..clear()
      ..addAll((challenges as List).map((item) => item.toString()));
    final milestones = _storage.read('project_milestones');
    if (milestones is Map) {
      milestones.forEach((key, value) {
        if (value is bool) _projectMilestones[key.toString()] = value;
      });
    }
    final history = _storage.read(
      'review_history',
      defaultValue: const <dynamic>[],
    );
    for (final item in history as List) {
      if (item is Map) _reviewHistory.add(item.cast<String, dynamic>());
    }
  }

  void _restoreReviewPreferences() {
    _reviewPausedUntil =
        _storage.read('review_paused_until', defaultValue: '')?.toString() ??
        '';
    final weekdays = _storage.read(
      'review_weekdays',
      defaultValue: const <int>[],
    );
    if (weekdays is List && weekdays.isNotEmpty) {
      _reviewWeekdays = weekdays
          .map((item) => item is int ? item : int.tryParse(item.toString()))
          .whereType<int>()
          .where((item) => item >= 1 && item <= 7)
          .toSet();
      if (_reviewWeekdays.isEmpty) _reviewWeekdays = <int>{1, 2, 3, 4, 5, 6, 7};
    }
  }

  void _restoreBookmarks() {
    _bookmarkedIds
      ..clear()
      ..addAll(_storage.readStringSet('bookmarked_ids'));
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

  /// 模拟考试草稿：保存题目、作答与剩余时间，支持断点续考。
  Map<String, dynamic>? get examDraft {
    final raw = _storage.read('exam_draft');
    return raw is Map ? raw.cast<String, dynamic>() : null;
  }

  Future<void> saveExamDraft(Map<String, dynamic> draft) =>
      _storage.write('exam_draft', draft);

  Future<void> clearExamDraft() => _storage.delete('exam_draft');

  /// 导出全部本地数据为可读 JSON（用于换机备份）。
  Map<String, dynamic> exportData() =>
      BackupDocumentService.prepareForExport(<String, dynamic>{
        'learned_ids': _learnedIds.toList(),
        'favorite_ids': _favoriteIds.toList(),
        'quiz_results': _quizResults.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'wrong_counts': Map<String, int>.from(_wrongCounts),
        'wrong_ever_keys': _wrongEverKeys.toList(),
        'review_due': Map<String, String>.from(_reviewDue),
        'review_stage': Map<String, int>.from(_reviewStage),
        'review_grade': Map<String, String>.from(_reviewGrade),
        'review_ease': Map<String, double>.from(_reviewEase),
        'review_interval': Map<String, int>.from(_reviewInterval),
        'review_repetitions': Map<String, int>.from(_reviewRepetitions),
        'study_days': _studyDays.toList(),
        'daily_activity': Map<String, int>.from(_dailyActivity),
        'daily_study_seconds': Map<String, int>.from(_dailyStudySeconds),
        'daily_question_date': _dailyQuestionDate,
        'daily_question_correct': _dailyQuestionCorrect,
        'notes': _notes.map((key, value) => MapEntry(key, value.toJson())),
        'bookmarked_ids': _bookmarkedIds.toList(),
        'question_stats': _questionStats,
        'error_cause_counts': Map<String, int>.from(_errorCauseCounts),
        'challenge_done_ids': _challengeDoneIds.toList(),
        'project_milestones': Map<String, bool>.from(_projectMilestones),
        'review_paused_until': _reviewPausedUntil,
        'review_weekdays': _reviewWeekdays.toList()..sort(),
        'review_history': _reviewHistory,
      });

  /// 从导出的 JSON 恢复数据，默认覆盖当前数据。
  ///
  /// 恢复前会把当前数据保存为回滚快照；[mode] 为 merge 时按课程、日期和
  /// 题号合并，适合把两台离线设备的学习记录合在一起。
  Future<void> importData(
    Map<String, dynamic> data, {
    BackupImportMode mode = BackupImportMode.replace,
  }) async {
    data = BackupDocumentService.normalizeForImport(data);
    await _storage.write('backup_rollback_snapshot', exportData());
    final effective = mode == BackupImportMode.merge
        ? _mergeImportData(data)
        : data;
    await _applyImportData(effective);
  }

  /// 撤销上一次恢复，回到导入前的本地快照。
  Future<bool> rollbackLastImport() async {
    final raw = _storage.read('backup_rollback_snapshot');
    if (raw is! Map) return false;
    await _applyImportData(raw.cast<String, dynamic>());
    await _storage.delete('backup_rollback_snapshot');
    return true;
  }

  Map<String, dynamic> _mergeImportData(Map<String, dynamic> incoming) {
    final current = exportData();
    final result = <String, dynamic>{...current};
    result['learned_ids'] = <String>{
      ...((current['learned_ids'] as List?) ?? const []).map((e) => '$e'),
      ...((incoming['learned_ids'] as List?) ?? const []).map((e) => '$e'),
    }.toList();
    result['favorite_ids'] = <String>{
      ...((current['favorite_ids'] as List?) ?? const []).map((e) => '$e'),
      ...((incoming['favorite_ids'] as List?) ?? const []).map((e) => '$e'),
    }.toList();
    result['bookmarked_ids'] = <String>{
      ...((current['bookmarked_ids'] as List?) ?? const []).map((e) => '$e'),
      ...((incoming['bookmarked_ids'] as List?) ?? const []).map((e) => '$e'),
    }.toList();
    result['wrong_ever_keys'] = <String>{
      ...((current['wrong_ever_keys'] as List?) ?? const []).map((e) => '$e'),
      ...((incoming['wrong_ever_keys'] as List?) ?? const []).map((e) => '$e'),
    }.toList();
    result['challenge_done_ids'] = <String>{
      ...((current['challenge_done_ids'] as List?) ?? const []).map(
        (e) => '$e',
      ),
      ...((incoming['challenge_done_ids'] as List?) ?? const []).map(
        (e) => '$e',
      ),
    }.toList();
    result['quiz_results'] = _mergeQuizResults(current, incoming);
    result['notes'] = _mergeNotes(current, incoming);
    result['wrong_counts'] = _mergeIntMaps(
      current['wrong_counts'],
      incoming['wrong_counts'],
    );
    result['error_cause_counts'] = _mergeIntMaps(
      current['error_cause_counts'],
      incoming['error_cause_counts'],
    );
    result['daily_activity'] = _mergeIntMaps(
      current['daily_activity'],
      incoming['daily_activity'],
    );
    result['daily_study_seconds'] = _mergeMaxMaps(
      current['daily_study_seconds'],
      incoming['daily_study_seconds'],
    );
    result['study_days'] = <String>{
      ...((current['study_days'] as List?) ?? const []).map((e) => '$e'),
      ...((incoming['study_days'] as List?) ?? const []).map((e) => '$e'),
    }.toList();
    result['question_stats'] = _mergeQuestionStats(current, incoming);
    result['project_milestones'] = <String, bool>{
      ..._boolMap(current['project_milestones']),
      ..._boolMap(incoming['project_milestones']),
    };
    result['review_due'] = _mergeReviewDue(current, incoming);
    result['review_history'] = <dynamic>[
      ...((current['review_history'] as List?) ?? const []),
      ...((incoming['review_history'] as List?) ?? const []),
    ];
    return result;
  }

  Map<String, dynamic> _mergeQuizResults(
    Map<String, dynamic> current,
    Map<String, dynamic> incoming,
  ) {
    final result = <String, dynamic>{};
    final currentMap = _mapOf(current['quiz_results']);
    final incomingMap = _mapOf(incoming['quiz_results']);
    for (final id in <String>{...currentMap.keys, ...incomingMap.keys}) {
      final left = _mapOf(currentMap[id]);
      final right = _mapOf(incomingMap[id]);
      if (left.isEmpty) {
        result[id] = right;
        continue;
      }
      if (right.isEmpty) {
        result[id] = left;
        continue;
      }
      final leftCorrect = left['correct'] as int? ?? 0;
      final rightCorrect = right['correct'] as int? ?? 0;
      final selected = rightCorrect > leftCorrect ? right : left;
      result[id] = <String, dynamic>{
        ...selected,
        'attempts':
            (left['attempts'] as int? ?? 0) + (right['attempts'] as int? ?? 0),
      };
    }
    return result;
  }

  Map<String, dynamic> _mergeNotes(
    Map<String, dynamic> current,
    Map<String, dynamic> incoming,
  ) {
    final result = <String, dynamic>{..._mapOf(current['notes'])};
    final incomingMap = _mapOf(incoming['notes']);
    for (final entry in incomingMap.entries) {
      final existing = _mapOf(result[entry.key]);
      final candidate = _mapOf(entry.value);
      final existingTime = DateTime.tryParse(
        existing['updatedAt']?.toString() ?? '',
      );
      final candidateTime = DateTime.tryParse(
        candidate['updatedAt']?.toString() ?? '',
      );
      if (existing.isEmpty ||
          candidateTime == null ||
          (existingTime != null && candidateTime.isAfter(existingTime))) {
        result[entry.key] = candidate;
      }
    }
    return result;
  }

  Map<String, dynamic> _mergeQuestionStats(
    Map<String, dynamic> current,
    Map<String, dynamic> incoming,
  ) {
    final result = <String, dynamic>{};
    final left = _mapOf(current['question_stats']);
    final right = _mapOf(incoming['question_stats']);
    for (final key in <String>{...left.keys, ...right.keys}) {
      final a = _mapOf(left[key]);
      final b = _mapOf(right[key]);
      if (a.isEmpty) {
        result[key] = b;
        continue;
      }
      if (b.isEmpty) {
        result[key] = a;
        continue;
      }
      final aAt = a['lastAt']?.toString() ?? '';
      final bAt = b['lastAt']?.toString() ?? '';
      result[key] = <String, dynamic>{
        ...a,
        if (bAt.compareTo(aAt) > 0) ...b,
        'attempts': (a['attempts'] as int? ?? 0) + (b['attempts'] as int? ?? 0),
        'correct': (a['correct'] as int? ?? 0) + (b['correct'] as int? ?? 0),
        'partialScore':
            ((a['partialScore'] as num?)?.toDouble() ?? 0) +
            ((b['partialScore'] as num?)?.toDouble() ?? 0),
      };
    }
    return result;
  }

  Map<String, dynamic> _mergeReviewDue(
    Map<String, dynamic> current,
    Map<String, dynamic> incoming,
  ) {
    final result = <String, dynamic>{..._mapOf(current['review_due'])};
    final right = _mapOf(incoming['review_due']);
    for (final entry in right.entries) {
      final leftValue = result[entry.key]?.toString();
      final rightValue = entry.value.toString();
      if (leftValue == null || rightValue.compareTo(leftValue) < 0) {
        result[entry.key] = rightValue;
      }
    }
    return result;
  }

  static Map<String, dynamic> _mapOf(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  static Map<String, int> _mergeIntMaps(dynamic left, dynamic right) {
    final result = <String, int>{};
    for (final map in <Map<String, dynamic>>[_mapOf(left), _mapOf(right)]) {
      for (final entry in map.entries) {
        final value = entry.value is int
            ? entry.value as int
            : int.tryParse(entry.value.toString()) ?? 0;
        result[entry.key] = (result[entry.key] ?? 0) + value;
      }
    }
    return result;
  }

  static Map<String, int> _mergeMaxMaps(dynamic left, dynamic right) {
    final result = <String, int>{};
    for (final map in <Map<String, dynamic>>[_mapOf(left), _mapOf(right)]) {
      for (final entry in map.entries) {
        final value = entry.value is int
            ? entry.value as int
            : int.tryParse(entry.value.toString()) ?? 0;
        result[entry.key] = result[entry.key] == null
            ? value
            : (result[entry.key]! > value ? result[entry.key]! : value);
      }
    }
    return result;
  }

  static Map<String, bool> _boolMap(dynamic value) {
    final result = <String, bool>{};
    final map = _mapOf(value);
    for (final entry in map.entries) {
      if (entry.value is bool) result[entry.key] = entry.value as bool;
    }
    return result;
  }

  Future<void> _applyImportData(Map<String, dynamic> data) async {
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
    await _storage.write(
      'wrong_ever_keys',
      (data['wrong_ever_keys'] as List?) ?? const [],
    );

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
      'daily_question_date',
      data['daily_question_date'] as String? ?? '',
    );
    await _storage.write(
      'daily_question_correct',
      data['daily_question_correct'] == true,
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
    await _storage.write(
      'bookmarked_ids',
      (data['bookmarked_ids'] as List?) ?? const [],
    );
    await _storage.write(
      'question_stats',
      (data['question_stats'] as Map?) ?? const {},
    );
    await _storage.write(
      'error_cause_counts',
      (data['error_cause_counts'] as Map?) ?? const {},
    );
    await _storage.write(
      'challenge_done_ids',
      (data['challenge_done_ids'] as List?) ?? const [],
    );
    await _storage.write(
      'project_milestones',
      (data['project_milestones'] as Map?) ?? const {},
    );
    await _storage.write(
      'review_paused_until',
      data['review_paused_until']?.toString() ?? '',
    );
    await _storage.write(
      'review_weekdays',
      (data['review_weekdays'] as List?) ?? const <int>[1, 2, 3, 4, 5, 6, 7],
    );
    await _storage.write(
      'review_history',
      (data['review_history'] as List?) ?? const [],
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
    _wrongEverKeys.clear();
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
    final dailyDate = _storage.read('daily_question_date', defaultValue: '');
    _dailyQuestionDate = dailyDate is String ? dailyDate : '';
    _dailyQuestionCorrect =
        _storage.read('daily_question_correct', defaultValue: false) == true;
    _notes.clear();
    _noteIds = noteIds.toSet();
    _restoreNotes();
    _bookmarkedIds.clear();
    _restoreBookmarks();
    _questionStats.clear();
    _errorCauseCounts.clear();
    _challengeDoneIds.clear();
    _projectMilestones.clear();
    _reviewHistory.clear();
    _restoreInsights();
    _restoreReviewPreferences();
    notifyListeners();
  }
}
