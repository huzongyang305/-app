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

enum _DifficultyFilter { all, beginner, intermediate, advanced }

/// 学习页：整体进度 + 按分类展开的全部知识点。
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  _DifficultyFilter _difficultyFilter = _DifficultyFilter.all;

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
          // 难度筛选
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final filter in _DifficultyFilter.values) ...[
                  FilterChip(
                    selected: _difficultyFilter == filter,
                    label: Text(_difficultyLabel(context, filter)),
                    onSelected: (_) => setState(() => _difficultyFilter = filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
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
          for (final category in _filteredCategories(content.categories))
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Icon(
                  iconFromName(category.iconName),
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  category.title.of(context.strings.localeCode),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${category.lessons.where((l) => progress.isLearned(l.id)).length}'
                      '/${category.lessons.length} ${context.tr('lessons')}',
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: category.lessons.isEmpty
                            ? 0
                            : category.lessons.where((l) => progress.isLearned(l.id)).length /
                                category.lessons.length,
                        minHeight: 4,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: _groupedLessons(context, category, progress),
              ),
            ),
        ],
      ),
    );
  }

  String _difficultyLabel(BuildContext context, _DifficultyFilter filter) {
    switch (filter) {
      case _DifficultyFilter.all:
        return '全部难度';
      case _DifficultyFilter.beginner:
        return context.difficultyLabel('入门');
      case _DifficultyFilter.intermediate:
        return context.difficultyLabel('进阶');
      case _DifficultyFilter.advanced:
        return context.difficultyLabel('高级');
    }
  }

  List<LessonCategory> _filteredCategories(List<LessonCategory> categories) {
    if (_difficultyFilter == _DifficultyFilter.all) {
      return categories;
    }

    final difficulty = switch (_difficultyFilter) {
      _DifficultyFilter.beginner => '入门',
      _DifficultyFilter.intermediate => '进阶',
      _DifficultyFilter.advanced => '高级',
      _DifficultyFilter.all => '',
    };

    return categories.map((category) {
      final filteredLessons = category.lessons
          .where((lesson) => lesson.difficulty == difficulty)
          .toList();
      if (filteredLessons.isEmpty) return null;
      return LessonCategory(
        id: category.id,
        title: category.title,
        iconName: category.iconName,
        colorValue: category.colorValue,
        lessons: filteredLessons,
      );
    }).whereType<LessonCategory>().toList();
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
