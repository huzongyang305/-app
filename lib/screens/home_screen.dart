import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../services/content_provider.dart';
import '../services/daily_question_service.dart';
import '../services/progress_provider.dart';
import '../services/recommendation_service.dart';
import '../services/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/activity_chart.dart';
import '../widgets/check_in_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/index_card.dart';
import '../widgets/lesson_card.dart';
import 'category_screen.dart';
import 'daily_question_screen.dart';
import 'lesson_screen.dart';
import 'learning_path_screen.dart';
import 'flashcard_screen.dart';
import 'quiz_list_screen.dart';
import 'review_plan_screen.dart';
import 'search_screen.dart';
import 'study_center_screen.dart';
import 'tools_screen.dart';
import 'tutor_screen.dart';

/// 首页：总体进度、继续学习与分类导航。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final settings = context.watch<SettingsProvider>();
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
          : _buildBody(context, content, progress, settings, theme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ContentProvider content,
    ProgressProvider progress,
    SettingsProvider settings,
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
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

        const SizedBox(height: AppSpacing.lg),
        const _DailyGoalCard(),
        const SizedBox(height: AppSpacing.md),
        const CheckInCard(),
        const SizedBox(height: AppSpacing.md),
        _DailyQuestionCard(progress: progress),
        const SizedBox(height: AppSpacing.md),
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
        // 快捷入口：顺序与勾选状态来自「我的 → 首页快捷入口」
        const SizedBox(height: AppSpacing.lg),
        ..._shortcutCards(context, progress, settings, theme),
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
        const SizedBox(height: AppSpacing.xl),
        SectionBand(index: '04', title: context.tr('categories')),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // 用固定高度而不是宽高比，避免窄屏上卡片内部内容溢出。
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 164,
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
  /// 首页快捷入口：按设置里的顺序渲染，未勾选的入口不会出现。
  ///
  /// 默认包含今日学习中心、复习计划、闪卡与工具箱；学习助手可在设置里开启。
  List<Widget> _shortcutCards(
    BuildContext context,
    ProgressProvider progress,
    SettingsProvider settings,
    ThemeData theme,
  ) {
    final cards = <Widget>[];
    for (final id in settings.homeShortcuts) {
      final card = switch (id) {
        'study_center' => _shortcutCard(
          context,
          theme: theme,
          icon: Icons.today_outlined,
          titleKey: 'studyCenterTitle',
          subtitleKey: 'studyCenterSubtitle',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const StudyCenterScreen()),
          ),
        ),
        'review' => _shortcutCard(
          context,
          theme: theme,
          icon: Icons.refresh,
          titleKey: progress.dueReviewCount > 0
              ? 'studyTaskReview'
              : 'reviewPlanTitle',
          subtitleKey: progress.dueReviewCount > 0
              ? 'todayReviewHint'
              : 'reviewQueueEmptyHint',
          badge: progress.dueReviewCount > 0
              ? '${progress.dueReviewCount}'
              : null,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ReviewPlanScreen()),
          ),
        ),
        'flashcards' => _shortcutCard(
          context,
          theme: theme,
          icon: Icons.style_outlined,
          titleKey: 'flashcardTitle',
          subtitleKey: 'flashcardEntryHint',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FlashcardScreen()),
          ),
        ),
        'tools' => _shortcutCard(
          context,
          theme: theme,
          icon: Icons.build_outlined,
          titleKey: 'homeToolsTitle',
          subtitleKey: 'homeToolsSub',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const ToolsScreen())),
        ),
        'tutor' => _shortcutCard(
          context,
          theme: theme,
          icon: Icons.support_agent_outlined,
          titleKey: 'tutorTitle',
          subtitleKey: 'tutorHint',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const TutorScreen())),
        ),
        _ => null,
      };
      if (card == null) continue;
      cards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: card,
        ),
      );
    }
    return cards;
  }

  Widget _shortcutCard(
    BuildContext context, {
    required ThemeData theme,
    required IconData icon,
    required String titleKey,
    required String subtitleKey,
    required VoidCallback onTap,
    String? badge,
  }) {
    return IndexCard(
      accent: theme.colorScheme.primary,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(context.tr(titleKey)),
        subtitle: Text(context.tr(subtitleKey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(badge),
                ),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Lesson? _nextLesson(ContentProvider content, ProgressProvider progress) {
    for (final lesson in content.allLessons) {
      if (!progress.isLearned(lesson.id)) return lesson;
    }
    return content.allLessons.isEmpty ? null : content.allLessons.first;
  }
}

/// 每日学习目标：今日已学分钟数与目标进度。
class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard();

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final goal = settings.dailyGoalMinutes;
    final done = (progress.studySecondsToday / 60).ceil();
    final ratio = goal <= 0 ? 0.0 : (done / goal).clamp(0.0, 1.0);
    final reached = done >= goal;
    final accent = reached ? AppPalette.success : theme.colorScheme.primary;

    return IndexCard(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      semanticLabel: context.trArgs('dailyGoalProgress', {
        'done': done,
        'goal': goal,
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                reached ? Icons.flag : Icons.flag_outlined,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reached
                      ? context.tr('dailyGoalReached')
                      : context.tr('dailyGoal'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$done/$goal ${context.tr('minutes')}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

void _openLesson(BuildContext context, Lesson lesson) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson)));
}

/// 每日一题入口：展示今天的题目侧重与作答状态。
class _DailyQuestionCard extends StatelessWidget {
  const _DailyQuestionCard({required this.progress});

  final ProgressProvider progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = context.watch<ContentProvider>();
    final daily = DailyQuestionService.pick(content.allLessons, progress.now);
    final answered = progress.dailyQuestionAnsweredToday;
    final correct = answered && progress.dailyQuestionCorrect;
    final accent = answered
        ? (correct ? AppPalette.success : AppPalette.danger)
        : theme.colorScheme.primary;

    return IndexCard(
      accent: accent,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          answered
              ? (correct ? Icons.check_circle : Icons.cancel)
              : Icons.today_outlined,
          color: accent,
        ),
        title: Text(context.tr('dailyQuestionTitle')),
        subtitle: Text(
          daily == null
              ? context.tr('dailyQuestionEmpty')
              : answered
              ? (correct
                    ? context.tr('correct')
                    : context.tr('dailyQuestionAnswered'))
              : daily.lesson.title.of(context.strings.localeCode),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DailyQuestionScreen()),
        ),
      ),
    );
  }
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
