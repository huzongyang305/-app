import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../services/progress_provider.dart';

/// 智能推荐卡片：基于学习数据分析的个性化推荐
class SmartRecommendations extends StatelessWidget {
  const SmartRecommendations({
    super.key,
    required this.lessons,
    required this.progress,
  });

  final List<Lesson> lessons;
  final ProgressProvider progress;

  @override
  Widget build(BuildContext context) {
    final recommendations = _generateRecommendations();
    
    if (recommendations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('暂无推荐内容'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recommendations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final rec = recommendations[index];
        return _RecommendationCard(recommendation: rec);
      },
    );
  }

  List<_Recommendation> _generateRecommendations() {
    final recommendations = <_Recommendation>[];
    
    // 1. 薄弱知识点推荐
    final weakLessons = _findWeakLessons();
    if (weakLessons.isNotEmpty) {
      recommendations.add(_Recommendation(
        type: RecommendationType.weakPoint,
        title: '薄弱知识点复习',
        description: '以下知识点掌握度较低，建议重点复习',
        lessons: weakLessons.take(3).toList(),
        priority: 1,
      ));
    }

    // 2. 错题重练推荐
    final wrongLessons = _findWrongLessons();
    if (wrongLessons.isNotEmpty) {
      recommendations.add(_Recommendation(
        type: RecommendationType.wrongReview,
        title: '错题重练',
        description: '这些题目答错过，重新练习巩固记忆',
        lessons: wrongLessons.take(3).toList(),
        priority: 2,
      ));
    }

    // 3. 进阶学习推荐
    final nextLessons = _findNextLessons();
    if (nextLessons.isNotEmpty) {
      recommendations.add(_Recommendation(
        type: RecommendationType.nextStep,
        title: '下一步学习',
        description: '基于当前进度，建议继续学习以下内容',
        lessons: nextLessons.take(3).toList(),
        priority: 3,
      ));
    }

    // 4. 复习到期提醒
    final dueLessons = _findDueLessons();
    if (dueLessons.isNotEmpty) {
      recommendations.add(_Recommendation(
        type: RecommendationType.review,
        title: '待复习内容',
        description: '以下知识点已到复习时间',
        lessons: dueLessons.take(3).toList(),
        priority: 0,
      ));
    }

    recommendations.sort((a, b) => a.priority.compareTo(b.priority));
    return recommendations;
  }

  List<Lesson> _findWeakLessons() {
    final weakLessons = <Lesson>[];
    for (final lesson in lessons) {
      final result = progress.resultOf(lesson.id);
      if (result != null && result.accuracy < 0.7) {
        weakLessons.add(lesson);
      }
    }
    weakLessons.sort((a, b) {
      final aResult = progress.resultOf(a.id)!;
      final bResult = progress.resultOf(b.id)!;
      return aResult.accuracy.compareTo(bResult.accuracy);
    });
    return weakLessons;
  }

  List<Lesson> _findWrongLessons() {
    final wrongLessons = <Lesson>[];
    for (final lesson in lessons) {
      final wrongCount = progress.wrongCountFor(lesson.id);
      if (wrongCount > 0) {
        wrongLessons.add(lesson);
      }
    }
    wrongLessons.sort((a, b) {
      final aWrong = progress.wrongCountFor(a.id);
      final bWrong = progress.wrongCountFor(b.id);
      return bWrong.compareTo(aWrong);
    });
    return wrongLessons;
  }

  List<Lesson> _findNextLessons() {
    final unlearned = lessons.where((l) => !progress.isLearned(l.id)).toList();
    return unlearned.take(5).toList();
  }

  List<Lesson> _findDueLessons() {
    final dueIds = progress.dueReviewLessonIds;
    return lessons.where((l) => dueIds.contains(l.id)).toList();
  }
}

enum RecommendationType {
  review,
  weakPoint,
  wrongReview,
  nextStep,
}

class _Recommendation {
  const _Recommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.lessons,
    required this.priority,
  });

  final RecommendationType type;
  final String title;
  final String description;
  final List<Lesson> lessons;
  final int priority;
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final _Recommendation recommendation;

  IconData _getIcon() {
    return switch (recommendation.type) {
      RecommendationType.review => Icons.schedule,
      RecommendationType.weakPoint => Icons.warning_amber,
      RecommendationType.wrongReview => Icons.refresh,
      RecommendationType.nextStep => Icons.arrow_forward,
    };
  }

  Color _getColor(BuildContext context) {
    return switch (recommendation.type) {
      RecommendationType.review => Theme.of(context).colorScheme.primary,
      RecommendationType.weakPoint => Colors.orange,
      RecommendationType.wrongReview => Colors.red,
      RecommendationType.nextStep => Colors.green,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIcon(), color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              recommendation.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...recommendation.lessons.map((lesson) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lesson.title.zh,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
