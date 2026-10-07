import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/tutor_reply.dart';
import '../services/content_provider.dart';
import '../services/offline_tutor_service.dart';
import '../services/progress_provider.dart';
import '../services/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_content.dart';
import 'lesson_screen.dart';

/// 离线学习助手：不调用任何云端模型，只用本机课程与学习进度回答。
///
/// 支持「今天学什么」「错题怎么办」「复习安排」等意图，以及按关键词检索
/// 本地课程；回答里的相关课程可以直接点开。
class TutorScreen extends StatefulWidget {
  const TutorScreen({super.key});

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Turn> _turns = <_Turn>[];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _ask(String rawQuery) {
    final query = rawQuery.trim();
    if (query.isEmpty) return;
    final content = context.read<ContentProvider>();
    final progress = context.read<ProgressProvider>();
    final settings = context.read<SettingsProvider>();
    final reply = OfflineTutorService.answer(
      query: query,
      lessons: content.allLessons,
      progress: progress,
      settings: settings,
    );
    setState(() {
      _turns.insert(0, _Turn(question: query, reply: reply));
      _controller.clear();
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    }
  }

  void _openLesson(String lessonId) {
    final content = context.read<ContentProvider>();
    for (final lesson in content.allLessons) {
      if (lesson.id != lessonId) continue;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson)),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('tutorTitle'))),
      body: ResponsiveContent(
        maxWidth: 820,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('tutorHint'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final key in const [
                  'tutorSuggestToday',
                  'tutorSuggestWrong',
                  'tutorSuggestReview',
                ])
                  ActionChip(
                    label: Text(context.tr(key)),
                    onPressed: () => _ask(context.tr(key)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: [
                  if (_turns.isEmpty)
                    _WelcomeCard(text: context.tr('tutorWelcome'))
                  else
                    for (final turn in _turns) ...[
                      _QuestionBubble(text: turn.question),
                      const SizedBox(height: AppSpacing.sm),
                      _ReplyCard(
                        reply: turn.reply,
                        onOpenLesson: _openLesson,
                        onFollowUp: _ask,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _ask,
                    decoration: InputDecoration(
                      hintText: context.tr('tutorPlaceholder'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: () => _ask(_controller.text),
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(context.tr('tutorAsk')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Turn {
  const _Turn({required this.question, required this.reply});

  final String question;
  final TutorReply reply;
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.support_agent, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionBubble extends StatelessWidget {
  const _QuestionBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: AppRadii.card,
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

/// 助手回复：标题 + 正文 + 相关课程 + 后续可点的问题。
class _ReplyCard extends StatelessWidget {
  const _ReplyCard({
    required this.reply,
    required this.onOpenLesson,
    required this.onFollowUp,
  });

  final TutorReply reply;
  final ValueChanged<String> onOpenLesson;
  final ValueChanged<String> onFollowUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = context.read<ContentProvider>();
    final titles = <String, String>{
      for (final lesson in content.allLessons)
        lesson.id: lesson.title.of(context.strings.localeCode),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reply.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              reply.body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
            ),
            if (reply.lessonIds.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                context.tr('tutorLessonHint'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final id in reply.lessonIds)
                    ActionChip(
                      avatar: const Icon(Icons.menu_book_outlined, size: 16),
                      label: Text(titles[id] ?? id),
                      onPressed: () => onOpenLesson(id),
                    ),
                ],
              ),
            ],
            if (reply.followUps.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final followUp in reply.followUps)
                    OutlinedButton(
                      onPressed: () => onFollowUp(followUp),
                      child: Text(followUp),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
