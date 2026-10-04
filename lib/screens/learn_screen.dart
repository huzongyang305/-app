import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson_category.dart';
import '../services/content_provider.dart';
import '../services/progress_provider.dart';
import '../widgets/icon_mapper.dart';
import '../widgets/lesson_card.dart';
import '../widgets/lesson_group_header.dart';
import 'lesson_screen.dart';
import 'quiz_list_screen.dart';

/// 学习页：整体进度 + 按分类展开的全部知识点。
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);

    if (content.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('navLearn'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final total = content.totalLessons;
    final learned = progress.learnedIds.length;
    final ratio = progress.learnedRatio(total);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('allLessons'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            '${context.tr('overallProgress')}  '
            '$learned/$total · ${(ratio * 100).round()}%',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: ratio, minHeight: 7),
          ),
          const SizedBox(height: 16),
          // 测验与模拟考试入口集中在学习页（底部导航不再单列测验）
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                Icons.quiz_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(context.tr('homeQuizExamTitle')),
              subtitle: Text(context.tr('learnQuizExamSub')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const QuizListScreen()),
              ),
            ),
          ),
          for (final category in content.categories)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Icon(
                  iconFromName(category.iconName),
                  color: Color(0xFF000000 | category.colorValue),
                ),
                title: Text(
                  category.title.of(context.strings.localeCode),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${category.lessons.where((l) => progress.isLearned(l.id)).length}'
                  '/${category.lessons.length} ${context.tr('lessons')}',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: _groupedLessons(context, category, progress),
              ),
            ),
        ],
      ),
    );
  }

  /// 按 group 字段生成带分组标题的知识点列表。
  List<Widget> _groupedLessons(
    BuildContext context,
    LessonCategory category,
    ProgressProvider progress,
  ) {
    final widgets = <Widget>[];
    String? currentGroup;

    for (final lesson in category.lessons) {
      final group = lesson.group;
      if (group != null && group.isNotEmpty && group != currentGroup) {
        widgets.add(LessonGroupHeader(title: group));
        currentGroup = group;
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: LessonCard(
            lesson: lesson,
            isLearned: progress.isLearned(lesson.id),
            isFavorite: progress.isFavorite(lesson.id),
            quizResult: progress.resultOf(lesson.id),
            onFavoriteTap: () => progress.toggleFavorite(lesson.id),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LessonScreen(lesson: lesson),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}
