import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../services/content_provider.dart';
import '../services/progress_provider.dart';
import '../services/recommendation_service.dart';
import '../widgets/category_card.dart';
import '../widgets/activity_chart.dart';
import '../widgets/check_in_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/index_card.dart';
import '../widgets/lesson_card.dart';
import 'category_screen.dart';
import 'lesson_screen.dart';
import 'learning_path_screen.dart';
import 'quiz_list_screen.dart';
import 'quiz_screen.dart';
import 'search_screen.dart';
import 'tools_screen.dart';

/// 首页：总体进度、继续学习与分类导航。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('appTitle')),
        actions: [
          IconButton(
            tooltip: context.tr('search'),
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: content.isLoading
          ? const Center(child: CircularProgressIndicator())
          : content.errorMessage != null
          ? EmptyState(
              icon: Icons.error_outline,
              message: context.trArgs('contentLoadFailed', {
                'error': content.errorMessage!,
              }),
              action: FilledButton(
                onPressed: content.load,
                child: Text(context.tr('retry')),
              ),
            )
          : _buildBody(context, content, progress, theme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ContentProvider content,
    ProgressProvider progress,
    ThemeData theme,
  ) {
    final totalLessons = content.totalLessons;
    final learnedCount = progress.learnedIds.length;
    final ratio = progress.learnedRatio(totalLessons);
    final nextLesson = _nextLesson(content, progress);
    final recommendations = buildRecommendations(
      lessons: content.allLessons,
      progress: progress,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // 学习档案：等宽百分比 + 细线进度尺 + 已学/总数
        IndexCard(
          accent: theme.colorScheme.primary,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          semanticLabel:
              '${context.tr('overallProgress')}, '
              '${(ratio * 100).round()}%, '
              '$learnedCount / $totalLessons ${context.tr('learnedLessons')}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('overallProgress'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$learnedCount / $totalLessons '
                          '${context.tr('learnedLessons')}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  MonoLabel(
                    '${(ratio * 100).round()}%',
                    size: 36,
                    weight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Semantics(
                label: context.trArgs('progressSemantic', {
                  'value': '${(ratio * 100).round()}%',
                }),
                child: SizedBox(
                  height: 6,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: ratio.clamp(0.0, 1.0),
                        child: ColoredBox(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const CheckInCard(),
        const SizedBox(height: 12),
        _RecentCard(content: content, progress: progress),

        // 今日推荐：到期复习 → 薄弱知识点 → 下一课
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          IndexCard(
            accent: theme.colorScheme.primary,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(context.tr('recommendTitle')),
                  subtitle: Text(
                    context.trArgs('homeRecentCount', {
                      'n': recommendations.length,
                    }),
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                for (final item in recommendations)
                  ListTile(
                    dense: true,
                    leading: Icon(
                      switch (item.reason) {
                        RecommendationReason.review => Icons.refresh,
                        RecommendationReason.weak => Icons.trending_up,
                        RecommendationReason.next => Icons.arrow_forward,
                      },
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      item.lesson.title.of(context.strings.localeCode),
                    ),
                    subtitle: Text(switch (item.reason) {
                      RecommendationReason.review => context.tr(
                        'recommendReview',
                      ),
                      RecommendationReason.weak => context.tr('recommendWeak'),
                      RecommendationReason.next => context.tr('recommendNext'),
                    }),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => _openLesson(context, item.lesson),
                  ),
              ],
            ),
          ),
        ],
        // 今日复习：按间隔重复到期队列
        if (progress.dueReviewCount > 0) ...[
          const SizedBox(height: 16),
          IndexCard(
            accent: theme.colorScheme.primary,
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.refresh, color: theme.colorScheme.primary),
              title: Text(
                '${context.tr('todayReview')} · ${progress.dueReviewCount}',
              ),
              subtitle: Text(context.tr('todayReviewHint')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final lesson = content.lessonById(
                  progress.dueReviewLessonIds.first,
                );
                if (lesson == null || lesson.quiz.isEmpty) return;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => QuizScreen(lesson: lesson),
                  ),
                );
              },
            ),
          ),
        ],
        if (nextLesson != null) ...[
          const SizedBox(height: 20),
          SectionBand(index: '01', title: context.tr('continueLearning')),
          const SizedBox(height: 12),
          LessonCard(
            lesson: nextLesson,
            isLearned: false,
            isFavorite: progress.isFavorite(nextLesson.id),
            quizResult: progress.resultOf(nextLesson.id),
            onFavoriteTap: () => progress.toggleFavorite(nextLesson.id),
            onTap: () => _openLesson(context, nextLesson),
          ),
        ],

        const SizedBox(height: 20),
        SectionBand(index: '02', title: context.tr('learningPaths')),
        const SizedBox(height: 12),
        IndexCard(
          accent: theme.colorScheme.primary,
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.route, color: theme.colorScheme.primary),
            title: Text(context.tr('learningPathsEntry')),
            subtitle: Text(context.tr('learningPathsHint')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LearningPathScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 快捷入口：测验与开发者工具
        SectionBand(index: '03', title: context.tr('homeQuizExamTitle')),
        const SizedBox(height: 12),
        IndexCard(
          accent: theme.colorScheme.primary,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.quiz_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(context.tr('homeQuizExamTitle')),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const QuizListScreen(),
                  ),
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              ListTile(
                leading: Icon(
                  Icons.build_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(context.tr('homeToolsTitle')),
                subtitle: Text(context.tr('homeToolsSub')),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ToolsScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionBand(index: '04', title: context.tr('categories')),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // 用固定高度而不是宽高比，避免窄屏上卡片内部内容溢出。
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 148,
          ),
          itemCount: content.categories.length,
          itemBuilder: (context, index) {
            final category = content.categories[index];
            return CategoryCard(
              category: category,
              learnedCount: category.lessons
                  .where((lesson) => progress.isLearned(lesson.id))
                  .length,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CategoryScreen(categoryId: category.id),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 找出第一个未学习的知识点，作为「继续学习」入口。
  Lesson? _nextLesson(ContentProvider content, ProgressProvider progress) {
    for (final lesson in content.allLessons) {
      if (!progress.isLearned(lesson.id)) return lesson;
    }
    return content.allLessons.isEmpty ? null : content.allLessons.first;
  }
}

void _openLesson(BuildContext context, Lesson lesson) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson)));
}

/// 最近学习进度 + 最近 7 天学习活动折线图。
class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.content, required this.progress});

  final ContentProvider content;
  final ProgressProvider progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lesson = progress.lastLessonId == null
        ? null
        : content.lessonById(progress.lastLessonId!);
    final recent =
        lesson ??
        (content.allLessons.isEmpty ? null : content.allLessons.first);
    final activity = progress.dailyActivity(7);
    final total = activity.fold<int>(0, (sum, value) => sum + value);
    final category = recent == null
        ? null
        : content.categoryById(recent.categoryId);
    final catLessons = category?.lessons ?? const [];
    final learned = catLessons
        .where((item) => progress.isLearned(item.id))
        .length;
    final ratio = catLessons.isEmpty ? 0.0 : learned / catLessons.length;

    return IndexCard(
      accent: theme.colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lesson == null
                        ? context.tr('homeStartFirst')
                        : context.tr('homeRecent'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.trArgs('homeRecentCount', {'n': total}),
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (recent != null) ...[
              const SizedBox(height: 4),
              Text(
                recent.title.of(context.strings.localeCode),
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: ratio, minHeight: 5),
              ),
              const SizedBox(height: 4),
              Text(
                '${category?.title.of(context.strings.localeCode) ?? ''} '
                '$learned/${catLessons.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            ActivityChart(values: activity),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 6; i >= 0; i--)
                  Expanded(
                    child: Text(
                      i == 0
                          ? context.tr('homeToday')
                          : context.trArgs('homeDaysAgo', {'n': i}),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 8,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
