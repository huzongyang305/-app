import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';

/// 网络与数据库机制的离线交互式时序演示。
///
/// 每个步骤包含标题和解释，用户用上一步/下一步观察共享状态如何变化。
/// 页面不依赖动画才能理解内容，因此“减少动画”设置只会缩短过渡时间。
class SystemLabScreen extends StatefulWidget {
  const SystemLabScreen({super.key, this.initialMode = 0});

  /// 0 = HTTP / 网络时序，1 = 数据库事务。
  final int initialMode;

  @override
  State<SystemLabScreen> createState() => _SystemLabScreenState();
}

class _SystemLabScreenState extends State<SystemLabScreen> {
  static const int _http = 0;
  static const int _transaction = 1;

  late int _mode;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode.clamp(_http, _transaction);
  }

  static const List<_FlowStage> _httpStages = <_FlowStage>[
    _FlowStage('systemHttpDnsTitle', 'systemHttpDnsDetail', Icons.dns_outlined),
    _FlowStage(
      'systemHttpTcpTitle',
      'systemHttpTcpDetail',
      Icons.cable_outlined,
    ),
    _FlowStage('systemHttpTlsTitle', 'systemHttpTlsDetail', Icons.lock_outline),
    _FlowStage(
      'systemHttpRequestTitle',
      'systemHttpRequestDetail',
      Icons.upload_outlined,
    ),
    _FlowStage(
      'systemHttpServerTitle',
      'systemHttpServerDetail',
      Icons.dns_outlined,
    ),
    _FlowStage(
      'systemHttpResponseTitle',
      'systemHttpResponseDetail',
      Icons.download_outlined,
    ),
  ];

  static const List<_FlowStage> _transactionStages = <_FlowStage>[
    _FlowStage(
      'systemTxBeginTitle',
      'systemTxBeginDetail',
      Icons.play_circle_outline,
    ),
    _FlowStage(
      'systemTxUpdateTitle',
      'systemTxUpdateDetail',
      Icons.edit_outlined,
    ),
    _FlowStage(
      'systemTxOtherBeginTitle',
      'systemTxOtherBeginDetail',
      Icons.person_add_alt_outlined,
    ),
    _FlowStage(
      'systemTxReadOldTitle',
      'systemTxReadOldDetail',
      Icons.visibility_outlined,
    ),
    _FlowStage(
      'systemTxCommitTitle',
      'systemTxCommitDetail',
      Icons.check_circle_outline,
    ),
    _FlowStage(
      'systemTxReadNewTitle',
      'systemTxReadNewDetail',
      Icons.update_outlined,
    ),
    _FlowStage(
      'systemTxRollbackTitle',
      'systemTxRollbackDetail',
      Icons.undo_outlined,
    ),
  ];

  List<_FlowStage> get _stages =>
      _mode == _http ? _httpStages : _transactionStages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stages = _stages;
    final current = stages[_step.clamp(0, stages.length - 1)];
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('systemLab'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _buildIntro(theme),
          const SizedBox(height: 12),
          _buildCurrent(context, theme, current, stages.length),
          const SizedBox(height: 12),
          _buildControls(context, stages.length),
          const SizedBox(height: 16),
          Text(
            context.tr('systemLabTimeline'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildTimeline(context, stages),
        ],
      ),
    );
  }

  Widget _buildIntro(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('systemLabHint'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: _http,
                  icon: const Icon(Icons.language, size: 17),
                  label: Text(context.tr('systemLabHttp')),
                ),
                ButtonSegment(
                  value: _transaction,
                  icon: const Icon(Icons.storage_outlined, size: 17),
                  label: Text(context.tr('systemLabTransaction')),
                ),
              ],
              selected: <int>{_mode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() {
                  _mode = selection.first;
                  _step = 0;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrent(
    BuildContext context,
    ThemeData theme,
    _FlowStage current,
    int total,
  ) {
    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return Card(
      key: ValueKey<String>('system-lab-current-$_mode-$_step'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('systemLabCurrent'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    current.icon,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(current.titleKey),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: animationDuration,
              child: Text(
                context.tr(current.detailKey),
                key: ValueKey<String>(
                  '${current.titleKey}-${current.detailKey}',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / total,
                      minHeight: 7,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.trArgs('labStepProgress', {
                    'current': _step + 1,
                    'total': total,
                  }),
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton.outlined(
              tooltip: context.tr('systemLabPrevious'),
              onPressed: _step == 0 ? null : _previous,
              icon: const Icon(Icons.skip_previous),
            ),
            IconButton.filled(
              tooltip: context.tr('systemLabNext'),
              onPressed: _step == total - 1 ? null : _next,
              icon: const Icon(Icons.skip_next),
            ),
            IconButton(
              tooltip: context.tr('systemLabReset'),
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<_FlowStage> stages) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (var index = 0; index < stages.length; index++)
                  _TimelineTile(
                    key: ValueKey<String>('system-lab-$_mode-$index'),
                    stage: stages[index],
                    index: index,
                    selected: index == _step,
                    completed: index < _step,
                    onTap: () => setState(() => _step = index),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            _step == stages.length - 1
                ? context.tr('systemLabComplete')
                : context.tr('systemLabHint'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _step == stages.length - 1
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  void _next() => setState(() => _step++);

  void _previous() => setState(() => _step--);

  void _reset() => setState(() => _step = 0);
}

class _FlowStage {
  const _FlowStage(this.titleKey, this.detailKey, this.icon);

  final String titleKey;
  final String detailKey;
  final IconData icon;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    super.key,
    required this.stage,
    required this.index,
    required this.selected,
    required this.completed,
    required this.onTap,
  });

  final _FlowStage stage;
  final int index;
  final bool selected;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : completed
        ? AppPalette.success
        : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.14),
              child: completed
                  ? Icon(Icons.check, size: 16, color: color)
                  : Text(
                      '${index + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr(stage.titleKey),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (selected) Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
