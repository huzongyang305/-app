import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/progress_provider.dart';
import '../services/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/index_card.dart';

/// 专注计时：把课文之外的学习时间也计入今日目标。
///
/// 只统计本页面打开且处于前台的时间；切到后台会自动暂停，
/// 每分钟落盘一次，避免进程被系统回收时丢失整段时长。
class FocusSessionScreen extends StatefulWidget {
  const FocusSessionScreen({super.key});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen>
    with WidgetsBindingObserver {
  static const List<int> _presets = <int>[15, 25, 45, 60];
  static const int _recordChunkSeconds = 60;

  int _targetMinutes = 25;
  bool _running = false;
  bool _finished = false;
  Duration _elapsed = Duration.zero;
  int _recordedSeconds = 0;
  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  ProgressProvider? _progress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _progress = context.read<ProgressProvider>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _stopwatch.stop();
    _syncElapsed();
    _recordRemainder();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _running) {
      _pause();
    }
  }

  void _start() {
    if (_finished || _running) return;
    setState(() => _running = true);
    _stopwatch.start();
    _ticker ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
  }

  void _pause() {
    if (!_running) return;
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    _syncElapsed();
    _recordRemainder();
    setState(() => _running = false);
  }

  void _tick() {
    _syncElapsed();
    _recordChunk();
    if (_elapsed.inSeconds >= _targetMinutes * 60) {
      _finish();
      return;
    }
    if (mounted) setState(() {});
  }

  void _syncElapsed() {
    final seconds = _stopwatch.elapsed.inSeconds;
    if (seconds == _elapsed.inSeconds) return;
    _elapsed = Duration(seconds: seconds);
  }

  /// 整分钟落盘：即使应用被系统回收，已完成的分钟不会丢。
  void _recordChunk() {
    final delta = _elapsed.inSeconds - _recordedSeconds;
    if (delta < _recordChunkSeconds) return;
    final chunk = delta - (delta % _recordChunkSeconds);
    _recordedSeconds += chunk;
    unawaited(_progress?.addFocusStudySeconds(chunk));
  }

  void _recordRemainder() {
    final delta = _elapsed.inSeconds - _recordedSeconds;
    if (delta < 5) return;
    _recordedSeconds = _elapsed.inSeconds;
    unawaited(_progress?.addFocusStudySeconds(delta));
  }

  void _finish() {
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    _syncElapsed();
    _recordRemainder();
    setState(() {
      _running = false;
      _finished = true;
    });
  }

  void _changeTarget(int minutes) {
    if (_running || _elapsed > Duration.zero) return;
    setState(() => _targetMinutes = minutes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = context.watch<ProgressProvider>();
    final settings = context.watch<SettingsProvider>();
    final goal = settings.dailyGoalMinutes;
    final done = (progress.studySecondsToday / 60).ceil();
    final goalRatio = goal <= 0 ? 0.0 : (done / goal).clamp(0.0, 1.0);
    final targetSeconds = _targetMinutes * 60;
    final ratio = (_elapsed.inSeconds / targetSeconds).clamp(0.0, 1.0);
    final accent = _finished
        ? AppPalette.success
        : theme.colorScheme.primary;
    final elapsedMinutes = (_elapsed.inSeconds / 60).ceil();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('focusTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        children: [
          Center(
            child: SizedBox(
              width: 236,
              height: 236,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: ratio,
                      strokeWidth: 10,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: accent,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _format(_elapsed),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.trArgs('focusTarget', {'n': _targetMinutes}),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final minutes in _presets)
                ChoiceChip(
                  selected: _targetMinutes == minutes,
                  label: Text(context.trArgs('studyMinutesShort', {
                    'n': minutes,
                  })),
                  onSelected: _running || _elapsed > Duration.zero
                      ? null
                      : (_) => _changeTarget(minutes),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (!_finished)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _running ? _pause : _start,
                    icon: Icon(
                      _running ? Icons.pause : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      context.tr(
                        _running
                            ? 'focusPause'
                            : _elapsed > Duration.zero
                            ? 'focusResume'
                            : 'focusStart',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _elapsed.inSeconds >= 5 ? _finish : null,
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(context.tr('focusStop')),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppPalette.success.withValues(alpha: 0.1),
                    borderRadius: AppRadii.card,
                  ),
                  child: Text(
                    elapsedMinutes < 1
                        ? context.tr('focusTooShort')
                        : context.trArgs('focusFinished', {'n': elapsedMinutes}),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppPalette.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.tr('focusDone')),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.xl),
          IndexCard(
            accent: done >= goal ? AppPalette.success : theme.colorScheme.primary,
            semanticLabel: context.trArgs('dailyGoalProgress', {
              'done': done,
              'goal': goal,
            }),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done >= goal
                      ? context.tr('dailyGoalReached')
                      : context.tr('dailyGoal'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.trArgs('dailyGoalProgress', {
                    'done': done,
                    'goal': goal,
                  }),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: goalRatio,
                    minHeight: 6,
                    color: done >= goal
                        ? AppPalette.success
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('focusHint'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
