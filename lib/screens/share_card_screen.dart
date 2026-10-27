import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/achievement.dart';
import '../services/content_provider.dart';
import '../services/progress_provider.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widget_snapshot.dart';

/// 学习成果卡片：把本机学习统计渲染成一张图片，经系统分享面板发送。
class ShareCardScreen extends StatefulWidget {
  const ShareCardScreen({super.key});

  @override
  State<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends State<ShareCardScreen> {
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
        fileName: 'code_learn_card.png',
        text: context.trRead('shareCardTagline'),
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

  String _durationLabel(int minutes) {
    if (minutes < 60) {
      return context.trArgs('shareCardMinutesValue', {'n': minutes});
    }
    final hours = minutes / 60;
    final value = hours >= 10
        ? hours.round().toString()
        : hours.toStringAsFixed(1);
    return context.trArgs('shareCardHoursValue', {'n': value});
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);
    final learned = progress.learnedIds.length;
    final total = content.totalLessons;
    final earned = earnedAchievementCount(evaluateAchievements(progress));

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('shareCardTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Text(
            context.tr('shareCardHint'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RepaintBoundary(
                key: _cardKey,
                child: _LearningCard(
                  learned: learned,
                  total: total,
                  streak: progress.streakDays,
                  studyTime: _durationLabel(progress.totalStudyMinutes),
                  accuracy: (progress.averageQuizAccuracy * 100).round(),
                  favorites: progress.favoriteIds.length,
                  notes: progress.notes.length,
                  achievements: earned,
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
              context.tr(_sharing ? 'shareImageRendering' : 'shareImageAction'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({
    required this.learned,
    required this.total,
    required this.streak,
    required this.studyTime,
    required this.accuracy,
    required this.favorites,
    required this.notes,
    required this.achievements,
    required this.date,
  });

  final int learned;
  final int total;
  final int streak;
  final String studyTime;
  final int accuracy;
  final int favorites;
  final int notes;
  final int achievements;
  final String date;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    const whiteMuted = Color(0xCCFFFFFF);
    final ratio = total == 0 ? 0.0 : learned / total;

    Widget stat(String value, String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: whiteMuted, fontSize: 10)),
        ],
      ),
    );

    // 分享图宽度固定以保持版式，较长文案允许卡片变高而不被裁切。
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Container(
        width: 340,
        constraints: const BoxConstraints(minHeight: 440),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF17308F), Color(0xFF2F6BFF), Color(0xFF6EA8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -60,
              bottom: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: white,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Code Learn',
                          style: TextStyle(
                            color: white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        date,
                        style: const TextStyle(color: whiteMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('shareCardHeader'),
                        style: const TextStyle(
                          color: white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('shareCardTagline'),
                        style: const TextStyle(color: whiteMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '$learned',
                                      style: const TextStyle(
                                        color: white,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '/ $total',
                                      style: const TextStyle(
                                        color: whiteMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr('shareCardLearned'),
                                  style: const TextStyle(
                                    color: whiteMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$streak',
                                    style: const TextStyle(
                                      color: white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    context.tr('shareCardDays'),
                                    style: const TextStyle(
                                      color: whiteMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr('shareCardStreak'),
                                style: const TextStyle(
                                  color: whiteMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          stat(studyTime, context.tr('shareCardStudyTime')),
                          stat('$accuracy%', context.tr('shareCardAccuracy')),
                          stat(
                            '$achievements',
                            context.tr('shareCardAchievements'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: whiteMuted,
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.trArgs('shareCardFootprint', {
                          'favorites': favorites,
                          'notes': notes,
                        }),
                        style: const TextStyle(color: whiteMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
