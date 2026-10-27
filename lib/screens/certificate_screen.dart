import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson_category.dart';
import '../services/content_provider.dart';
import '../services/progress_provider.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/icon_mapper.dart';
import '../widgets/widget_snapshot.dart';

/// 学习证书列表：完成某个分类的全部课程后可领取该分类的结业证书。
class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);
    final localeCode = context.strings.localeCode;

    final entries =
        content.categories
            .map(
              (category) => _CategoryProgress(
                category: category,
                learned: category.lessons
                    .where((lesson) => progress.isLearned(lesson.id))
                    .length,
                total: category.lessons.length,
              ),
            )
            .toList()
          ..sort((a, b) {
            if (a.isComplete != b.isComplete) return a.isComplete ? -1 : 1;
            final ratioDiff = b.ratio.compareTo(a.ratio);
            if (ratioDiff != 0) return ratioDiff;
            return a.category.title
                .of(localeCode)
                .compareTo(b.category.title.of(localeCode));
          });
    final earned = entries.where((entry) => entry.isComplete).length;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('certificateTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB8860B), Color(0xFFE0B84C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadii.card,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.trArgs('certificateOverall', {
                          'n': earned,
                          'm': entries.length,
                        }),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('certificateHint'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final entry in entries) ...[
            _CategoryCertificateCard(entry: entry),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _CategoryProgress {
  const _CategoryProgress({
    required this.category,
    required this.learned,
    required this.total,
  });

  final LessonCategory category;
  final int learned;
  final int total;

  bool get isComplete => total > 0 && learned >= total;
  double get ratio => total == 0 ? 0 : (learned / total).clamp(0.0, 1.0);
}

class _CategoryCertificateCard extends StatelessWidget {
  const _CategoryCertificateCard({required this.entry});

  final _CategoryProgress entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(entry.category.colorValue);
    final title = entry.category.title.of(context.strings.localeCode);
    final complete = entry.isComplete;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: complete
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      CertificateViewScreen(categoryId: entry.category.id),
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  iconFromName(entry.category.iconName),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: entry.ratio,
                        minHeight: 5,
                        color: complete ? AppPalette.success : color,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.trArgs('certificateProgress', {
                        'done': entry.learned,
                        'total': entry.total,
                      }),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (complete)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: AppPalette.success,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('certificateUnlocked'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppPalette.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  context.tr('certificateLocked'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 单张结业证书：展示分类完成情况，并支持分享为图片。
class CertificateViewScreen extends StatefulWidget {
  const CertificateViewScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<CertificateViewScreen> createState() => _CertificateViewScreenState();
}

class _CertificateViewScreenState extends State<CertificateViewScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await WidgetSnapshot.capturePng(_cardKey);
      if (!mounted) return;
      if (bytes == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.trRead('shareImageFailed'))),
        );
        return;
      }
      final shared = await const ShareService().shareImage(
        bytes,
        fileName: 'code_learn_certificate.png',
        text: context.trRead('certificateTitle'),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.trRead(
              shared ? 'shareImageStarted' : 'shareImageUnavailable',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(context.trRead('shareImageFailed'))),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _dateLabel() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${now.year}.${two(now.month)}.${two(now.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);
    final localeCode = context.strings.localeCode;
    final categoryMatches = content.categories
        .where((item) => item.id == widget.categoryId)
        .toList();
    final category = categoryMatches.isEmpty ? null : categoryMatches.first;

    if (category == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('certificateTitle'))),
        body: Center(child: Text(context.tr('certificateMissing'))),
      );
    }

    final total = category.lessons.length;
    final learned = category.lessons
        .where((lesson) => progress.isLearned(lesson.id))
        .length;
    final complete = total > 0 && learned >= total;

    return Scaffold(
      appBar: AppBar(title: Text(category.title.of(localeCode))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (!complete)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                context.tr('certificateHint'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RepaintBoundary(
                key: _cardKey,
                child: _CertificateCard(
                  categoryTitle: category.title.of(localeCode),
                  lessons: total,
                  minutes: progress.totalStudyMinutes,
                  accuracy: (progress.averageQuizAccuracy * 100).round(),
                  date: _dateLabel(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
            label: Text(
              context.tr(_sharing ? 'shareImageRendering' : 'certificateShare'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({
    required this.categoryTitle,
    required this.lessons,
    required this.minutes,
    required this.accuracy,
    required this.date,
  });

  final String categoryTitle;
  final int lessons;
  final int minutes;
  final int accuracy;
  final String date;

  static const Color _gold = Color(0xFFB8860B);
  static const Color _goldDark = Color(0xFF7A5C00);
  static const Color _paper = Color(0xFFFFFCF3);
  static const Color _ink = Color(0xFF2B2416);
  static const Color _muted = Color(0xFF7C725C);

  @override
  Widget build(BuildContext context) {
    // 证书以固定宽度出图，限制系统字号；较长文案允许卡片向下延伸。
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Container(
        width: 340,
        constraints: const BoxConstraints(minHeight: 480),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _gold, width: 2),
        ),
        padding: const EdgeInsets.all(10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gold.withValues(alpha: 0.45)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: _gold,
                    size: 38,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('certificateCardTitle'),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'CERTIFICATE OF COMPLETION',
                    style: TextStyle(
                      color: _goldDark,
                      fontSize: 8,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(width: 60, height: 1.5, color: _gold),
                  const SizedBox(height: 18),
                  Text(
                    context.tr('certificateCertifies'),
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('certificateLearner'),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.trArgs('certificateCompleted', {
                      'category': categoryTitle,
                      'n': lessons,
                    }),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 12.5,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _CertificateStat(
                          label: context.tr('shareCardStudyTime'),
                          value: context.trArgs('shareCardMinutesValue', {
                            'n': minutes,
                          }),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 26,
                        color: _gold.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _CertificateStat(
                          label: context.tr('shareCardAccuracy'),
                          value: '$accuracy%',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _gold, width: 2),
                        color: _gold.withValues(alpha: 0.08),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: _goldDark,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('certificateIssuer'),
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${context.tr('certificateIssuedAt')} · $date',
                            style: const TextStyle(color: _muted, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificateStat extends StatelessWidget {
  const _CertificateStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _CertificateCard._ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: _CertificateCard._muted, fontSize: 9),
        ),
      ],
    );
  }
}
