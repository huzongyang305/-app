import 'dart:math' as math;

import '../models/lesson.dart';

/// 自适应测验档位。
enum QuizLevel {
  warmup('热身'),
  standard('标准'),
  challenge('挑战');

  const QuizLevel(this.label);

  final String label;
}

/// 一次自适应测验的出题计划。
class AdaptiveQuizPlan {
  const AdaptiveQuizPlan({
    required this.level,
    required this.questions,
    required this.timeLimit,
    required this.shuffledOptions,
    required this.reason,
  });

  final QuizLevel level;
  final List<QuizQuestion> questions;
  final Duration timeLimit;
  final bool shuffledOptions;

  /// 为什么推荐这个档位（用于界面说明，不显示内部算法细节）。
  final String reason;

  bool get isEmpty => questions.isEmpty;
}

/// 一次测验结束后的自适应反馈。
class AdaptiveFeedback {
  const AdaptiveFeedback({
    required this.nextLevel,
    required this.message,
    required this.accuracy,
  });

  final QuizLevel nextLevel;
  final String message;
  final double accuracy;
}

/// 自适应测验：根据近期表现推荐难度、确定性洗牌题目与选项，并给出下一轮建议。
///
/// 全部离线计算；同一 (lessonId, seed, level) 组合结果稳定，便于测试与复现。
class AdaptiveQuizService {
  const AdaptiveQuizService._();

  /// 依据近期正确率与连对次数推荐档位。
  static QuizLevel recommendLevel({
    required double recentAccuracy,
    required int recentAttempts,
    required int correctStreak,
  }) {
    if (recentAttempts == 0) return QuizLevel.warmup;
    if (recentAccuracy >= 0.85 && correctStreak >= 3) {
      return QuizLevel.challenge;
    }
    if (recentAccuracy >= 0.6) return QuizLevel.standard;
    return QuizLevel.warmup;
  }

  /// 构建出题计划。
  ///
  /// 热身优先单选，挑战优先多选 / 填空 / 排序 / 代码等交互题型；
  /// 题目不足时按顺序回退，保证题目数量尽可能满足 [questionCount]。
  static AdaptiveQuizPlan buildPlan({
    required Lesson lesson,
    required QuizLevel level,
    int questionCount = 5,
    int seed = 0,
    double? masteryScore,
  }) {
    final pool = lesson.quiz;
    if (pool.isEmpty) {
      return AdaptiveQuizPlan(
        level: level,
        questions: const <QuizQuestion>[],
        timeLimit: Duration.zero,
        shuffledOptions: false,
        reason: '',
      );
    }
    final ordered = <QuizQuestion>[
      ...pool.where((item) => _matches(level, item)),
      ...pool.where((item) => !_matches(level, item)),
    ];
    final deduped = <QuizQuestion>[];
    for (final question in ordered) {
      if (!deduped.contains(question)) deduped.add(question);
    }
    final selected = deduped.take(questionCount.clamp(1, pool.length)).toList();
    final random = math.Random(seed);
    _shuffle(selected, random);
    final questions = selected
        .map((item) => _shuffleOptions(item, random, level))
        .toList(growable: false);
    final secondsPerQuestion = switch (level) {
      QuizLevel.warmup => 45,
      QuizLevel.standard => 55,
      QuizLevel.challenge => 70,
    };
    return AdaptiveQuizPlan(
      level: level,
      questions: questions,
      timeLimit: Duration(seconds: secondsPerQuestion * questions.length),
      shuffledOptions: true,
      reason: _reasonFor(level, masteryScore),
    );
  }

  /// 测验结束后的档位建议。
  static AdaptiveFeedback feedback({
    required QuizLevel currentLevel,
    required int correct,
    required int total,
  }) {
    final accuracy = total == 0 ? 0.0 : correct / total;
    final QuizLevel next;
    final String message;
    if (accuracy >= 0.9 && currentLevel != QuizLevel.challenge) {
      next = QuizLevel.values[
        math.min(QuizLevel.values.length - 1, currentLevel.index + 1)
      ];
      message = '本轮表现很好，下一轮将提高到「${next.label}」档，继续保持。';
    } else if (accuracy < 0.5 && currentLevel != QuizLevel.warmup) {
      next = QuizLevel.values[math.max(0, currentLevel.index - 1)];
      message = '本轮正确率偏低，下一轮回到「${next.label}」档，先把基础打牢。';
    } else {
      next = currentLevel;
      message = '当前档位合适，下一轮继续保持「${currentLevel.label}」难度。';
    }
    return AdaptiveFeedback(nextLevel: next, message: message, accuracy: accuracy);
  }

  /// 选项乱序后用新的下标重建题目对象，保证判分仍然正确。
  static QuizQuestion shuffleQuestionOptions(QuizQuestion question, int seed) {
    return _shuffleOptions(question, math.Random(seed), QuizLevel.standard);
  }

  static QuizQuestion _shuffleOptions(
    QuizQuestion question,
    math.Random random,
    QuizLevel level,
  ) {
    // 填空、排序题不重排选项：它们的选项本身就是需要排序的素材。
    if (question.type == 'fill' || question.type == 'order') return question;
    final options = question.options;
    if (options.length < 3) return question;
    final indices = List<int>.generate(options.length, (index) => index);
    _shuffle(indices, random);
    final shuffled = indices
        .map((index) => options[index])
        .toList(growable: false);
    int remap(int oldIndex) => indices.indexOf(oldIndex);
    return QuizQuestion(
      question: question.question,
      options: shuffled,
      answerIndex: remap(question.answerIndex),
      explanation: question.explanation,
      type: question.type,
      code: question.code,
      answerIndexes: question.answerIndexes.map(remap).toList(growable: false),
      acceptedAnswers: question.acceptedAnswers,
      correctOrder: question.correctOrder,
      language: question.language,
      expectedOutput: question.expectedOutput,
    );
  }

  static bool _matches(QuizLevel level, QuizQuestion question) {
    switch (level) {
      case QuizLevel.warmup:
        return question.isSingleChoice;
      case QuizLevel.standard:
        return true;
      case QuizLevel.challenge:
        return question.isInteractive || question.type == 'code';
    }
  }

  static String _reasonFor(QuizLevel level, double? mastery) {
    if (mastery == null) {
      return '还没有测验记录，从「${level.label}」档开始。';
    }
    final percent = (mastery * 100).round();
    return '当前掌握度约 $percent%，推荐「${level.label}」档。';
  }

  static void _shuffle<T>(List<T> values, math.Random random) {
    for (var index = values.length - 1; index > 0; index--) {
      final swap = random.nextInt(index + 1);
      final temp = values[index];
      values[index] = values[swap];
      values[swap] = temp;
    }
  }
}
