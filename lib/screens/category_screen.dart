import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../services/content_provider.dart';
import '../services/progress_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/icon_mapper.dart';
import '../widgets/index_card.dart';
import '../widgets/lesson_card.dart';
import '../widgets/lesson_group_header.dart';
import 'lesson_screen.dart';

/// 分类详情页：列出该分类下的全部知识点。
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final category = content.categoryById(categoryId);

    if (category == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.search_off,
          message: context.tr('loadFailed'),
        ),
      );
    }

    final color = Color(0xFF000000 | category.colorValue);
    // 课程内按 order 排序，保证「推荐学习顺序」可用
    final ordered = <Lesson>[...category.lessons]
      ..sort((a, b) => a.order.compareTo(b.order));
    Lesson? nextLesson;
    for (final lesson in ordered) {
      if (!progress.isLearned(lesson.id)) {
        nextLesson = lesson;
        break;
      }
    }
    final learned = ordered.where((l) => progress.isLearned(l.id)).length;
    final ratio = ordered.isEmpty ? 0.0 : learned / ordered.length;
    final children = <Widget>[
      // 分类概览
      IndexCard(
        accent: color,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            Icon(iconFromName(category.iconName), color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${category.lessons.length} ${context.tr('lessons')}',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  MonoLabel(
                    '$learned/${ordered.length} '
                    '${context.tr('learnedLessons')}',
                  ),
                ],
              ),
            ),
            MonoLabel(
              '${(ratio * 100).round()}%',
              color: color,
              size: 15,
              weight: FontWeight.w700,
            ),
          ],
        ),
      ),
      const SizedBox(height: 4),
    ];

    // 推荐学习顺序：直接给出本课程下一篇未学内容
    if (nextLesson != null) {
      final target = nextLesson;
      final targetIndex = ordered.indexOf(target) + 1;
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: IndexCard(
            accent: color,
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.play_arrow, color: color),
              title: Text(context.tr('continueCourse')),
              subtitle: Text(
                context.trArgs('lessonIndex', {
                  'n': targetIndex,
                  'title': target.title.of(context.strings.localeCode),
                }),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LessonScreen(lesson: target),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 同一分类内按 group 二次分组（例如 Python / C++ / Java / JavaScript）。
    String? currentGroup;
    var orderInCourse = 0;
    for (final lesson in ordered) {
      orderInCourse++;
      final group = lesson.group;
      if (group != null && group.isNotEmpty && group != currentGroup) {
        children.add(LessonGroupHeader(title: group, color: color));
        currentGroup = group;
      }
      children.add(
        LessonCard(
          lesson: lesson,
          courseIndex: orderInCourse,
          isLearned: progress.isLearned(lesson.id),
          isFavorite: progress.isFavorite(lesson.id),
          quizResult: progress.resultOf(lesson.id),
          flat: true,
          accentColor: color,
          onFavoriteTap: () => progress.toggleFavorite(lesson.id),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LessonScreen(lesson: lesson),
            ),
          ),
        ),
      );
      children.add(
        Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(category.title.of(context.strings.localeCode)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: children,
      ),
    );
  }
}
