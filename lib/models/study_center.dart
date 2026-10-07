import 'localized_text.dart';

/// 今日学习任务类型。
enum StudyTaskKind {
  review('review'),
  newLesson('new_lesson'),
  wrongPractice('wrong_practice'),
  dailyQuestion('daily_question'),
  challenge('challenge'),
  project('project');

  const StudyTaskKind(this.storageKey);

  final String storageKey;
}

/// 今日学习中心里的一条可执行任务。
class StudyTask {
  const StudyTask({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.minutes,
    this.lessonId,
  });

  final String id;
  final StudyTaskKind kind;
  final String title;
  final String subtitle;
  final int minutes;
  final String? lessonId;
}

/// 某一天的学习计划。
class StudyDayPlan {
  const StudyDayPlan({
    required this.date,
    required this.tasks,
    required this.totalMinutes,
  });

  final DateTime date;
  final List<StudyTask> tasks;
  final int totalMinutes;

  bool get isEmpty => tasks.isEmpty;
}

/// 本地挑战：每日或每周完成指定题量 / 课程量。
enum StudyChallengeKind { daily, weekly }

class StudyChallenge {
  const StudyChallenge({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.target,
    required this.progress,
    required this.completed,
  });

  final String id;
  final StudyChallengeKind kind;
  final String title;
  final String description;
  final int target;
  final int progress;
  final bool completed;

  double get ratio => target == 0 ? 0 : (progress / target).clamp(0.0, 1.0);
}

/// 概念级掌握度：按课程关键词聚合测验与错题数据。
class ConceptMastery {
  const ConceptMastery({
    required this.concept,
    required this.score,
    required this.attempts,
    required this.correct,
    required this.lessonIds,
  });

  final String concept;
  final double score;
  final int attempts;
  final int correct;
  final List<String> lessonIds;

  int get percent => (score * 100).round();
  double get accuracy => attempts == 0 ? 0 : correct / attempts;
}

/// 单题统计，用于难度校准与题目质量检查。
class QuestionStat {
  const QuestionStat({
    required this.key,
    required this.lessonId,
    required this.questionIndex,
    required this.question,
    required this.attempts,
    required this.correct,
    required this.partialScore,
    required this.lastConfidence,
    required this.lastCause,
  });

  final String key;
  final String lessonId;
  final int questionIndex;
  final String question;
  final int attempts;
  final int correct;
  final double partialScore;
  final String lastConfidence;
  final String lastCause;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;
  double get averageScore => attempts == 0 ? 0 : partialScore / attempts;

  String get difficultyLabel {
    if (attempts < 3) return '样本不足';
    if (accuracy >= 0.9) return '偏简单';
    if (accuracy <= 0.35) return '偏难';
    if (accuracy <= 0.6) return '有挑战';
    return '适中';
  }
}

/// 错因统计。
class ErrorCauseStat {
  const ErrorCauseStat({required this.cause, required this.count});

  final String cause;
  final int count;
}

/// 项目实战里程碑。
class ProjectMilestone {
  const ProjectMilestone({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.done,
  });

  final String id;
  final String lessonId;
  final String title;
  final bool done;
}

/// 项目实战课程摘要。
class ProjectLessonSummary {
  const ProjectLessonSummary({
    required this.lessonId,
    required this.title,
    required this.milestones,
  });

  final String lessonId;
  final LocalizedText title;
  final List<ProjectMilestone> milestones;

  int get completed => milestones.where((item) => item.done).length;
  double get ratio => milestones.isEmpty ? 0 : completed / milestones.length;
}
