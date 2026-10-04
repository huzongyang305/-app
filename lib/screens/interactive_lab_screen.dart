import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../services/algorithm_lab.dart';

/// 交互式学习实验室：逐步演示算法和常用数据结构操作。
class InteractiveLabScreen extends StatefulWidget {
  const InteractiveLabScreen({super.key});

  @override
  State<InteractiveLabScreen> createState() => _InteractiveLabScreenState();
}

class _InteractiveLabScreenState extends State<InteractiveLabScreen> {
  static const int _binary = 0;
  static const int _bubble = 1;
  static const int _structures = 2;
  static const int _insertion = 3;
  static const int _selection = 4;

  final List<int> _binaryValues = const <int>[
    2,
    5,
    8,
    12,
    16,
    23,
    38,
    56,
    72,
    91,
  ];
  final List<int> _bubbleValues = const <int>[42, 17, 93, 8, 55, 24, 71];

  int _mode = _binary;
  int _stepIndex = 0;
  bool _playing = false;
  Timer? _timer;
  late List<LabStep> _steps = AlgorithmLab.binarySearchSteps(_binaryValues, 23);

  final List<String> _stack = <String>[];
  final List<String> _queue = <String>[];
  int _nextStackValue = 1;
  int _nextQueueValue = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  LabStep get _currentStep {
    if (_steps.isEmpty) {
      return const LabStep(values: <int>[], messageKey: 'labSearchStart');
    }
    final safeIndex = _stepIndex < 0
        ? 0
        : (_stepIndex >= _steps.length ? _steps.length - 1 : _stepIndex);
    return _steps[safeIndex];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('interactiveLab'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('interactiveLabHint'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _mode,
                    decoration: InputDecoration(
                      labelText: context.tr('labSelectAlgorithm'),
                      prefixIcon: const Icon(Icons.science_outlined),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: _binary,
                        child: Text(context.tr('labBinarySearch')),
                      ),
                      DropdownMenuItem(
                        value: _bubble,
                        child: Text(context.tr('labBubbleSort')),
                      ),
                      DropdownMenuItem(
                        value: _insertion,
                        child: Text(context.tr('labInsertionSort')),
                      ),
                      DropdownMenuItem(
                        value: _selection,
                        child: Text(context.tr('labSelectionSort')),
                      ),
                      DropdownMenuItem(
                        value: _structures,
                        child: Text(context.tr('labStackQueue')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) _switchMode(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_mode == _structures)
            _buildStructureLab(theme)
          else
            _buildAlgorithmLab(theme),
        ],
      ),
    );
  }

  void _switchMode(int mode) {
    _stop();
    setState(() {
      _mode = mode;
      _stepIndex = 0;
      if (mode == _binary) {
        _steps = AlgorithmLab.binarySearchSteps(_binaryValues, 23);
      } else if (mode == _bubble) {
        _steps = AlgorithmLab.bubbleSortSteps(_bubbleValues);
      } else if (mode == _insertion) {
        _steps = AlgorithmLab.insertionSortSteps(_bubbleValues);
      } else if (mode == _selection) {
        _steps = AlgorithmLab.selectionSortSteps(_bubbleValues);
      }
    });
  }

  Widget _buildAlgorithmLab(ThemeData theme) {
    final step = _currentStep;
    final progress = _steps.isEmpty ? 0.0 : (_stepIndex + 1) / _steps.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _titleForMode(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      context.trArgs('labStepProgress', {
                        'current': _stepIndex + 1,
                        'total': _steps.length,
                      }),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildArray(step, theme),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    context.trArgs(step.messageKey, step.messageArgs),
                    key: ValueKey(
                      step.messageKey + step.messageArgs.toString(),
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: progress, minHeight: 5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.outlined(
                  tooltip: context.tr('labPrevious'),
                  onPressed: _stepIndex == 0 ? null : _previousStep,
                  icon: const Icon(Icons.skip_previous),
                ),
                IconButton.filled(
                  tooltip: _playing
                      ? context.tr('labPause')
                      : context.tr('labPlay'),
                  onPressed: _playPause,
                  icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                ),
                IconButton.outlined(
                  tooltip: context.tr('labNext'),
                  onPressed: _stepIndex >= _steps.length - 1 ? null : _nextStep,
                  icon: const Icon(Icons.skip_next),
                ),
                IconButton(
                  tooltip: context.tr('labReset'),
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _titleForMode() {
    switch (_mode) {
      case _binary:
        return context.tr('labBinarySearch');
      case _bubble:
        return context.tr('labBubbleSort');
      case _insertion:
        return context.tr('labInsertionSort');
      case _selection:
        return context.tr('labSelectionSort');
      default:
        return context.tr('interactiveLab');
    }
  }

  Widget _buildArray(LabStep step, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var index = 0; index < step.values.length; index++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Column(
                children: [
                  SizedBox(
                    height: 13,
                    child: Text(
                      _markerFor(step, index),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _cellColor(step, index, theme),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _cellBorderColor(step, index, theme),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      '${step.values[index]}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _cellTextColor(step, index, theme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$index',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _markerFor(LabStep step, int index) {
    if (_mode == _binary) {
      final markers = <String>[];
      if (step.low == index) markers.add('L');
      if (step.mid == index) markers.add('M');
      if (step.high == index) markers.add('R');
      return markers.join('/');
    }
    if (step.activeIndex == index) return 'j';
    if (step.compareIndex == index) return 'j+1';
    return '';
  }

  Color _cellColor(LabStep step, int index, ThemeData theme) {
    if (step.found && step.mid == index) {
      return const Color(0xFF16A34A);
    }
    if (step.mid == index ||
        step.activeIndex == index ||
        step.compareIndex == index) {
      return theme.colorScheme.primaryContainer;
    }
    return theme.colorScheme.surfaceContainerHighest;
  }

  Color _cellBorderColor(LabStep step, int index, ThemeData theme) {
    if (step.found && step.mid == index) return const Color(0xFF16A34A);
    if (step.mid == index ||
        step.activeIndex == index ||
        step.compareIndex == index) {
      return theme.colorScheme.primary;
    }
    return theme.colorScheme.outlineVariant;
  }

  Color _cellTextColor(LabStep step, int index, ThemeData theme) {
    if (step.found && step.mid == index) return Colors.white;
    if (step.mid == index ||
        step.activeIndex == index ||
        step.compareIndex == index) {
      return theme.colorScheme.onPrimaryContainer;
    }
    return theme.colorScheme.onSurface;
  }

  void _playPause() {
    if (_playing) {
      _stop();
      return;
    }
    if (_steps.isEmpty) return;
    if (_stepIndex >= _steps.length - 1) {
      _stepIndex = 0;
    }
    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(milliseconds: 850), (_) {
      if (!mounted) return;
      if (_stepIndex >= _steps.length - 1) {
        _stop();
        return;
      }
      setState(() => _stepIndex++);
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (mounted && _playing) {
      setState(() => _playing = false);
    } else {
      _playing = false;
    }
  }

  void _previousStep() {
    _stop();
    final next = _stepIndex - 1;
    setState(() => _stepIndex = next < 0 ? 0 : next);
  }

  void _nextStep() {
    _stop();
    final next = _stepIndex + 1;
    setState(
      () => _stepIndex = next >= _steps.length ? _steps.length - 1 : next,
    );
  }

  void _reset() {
    _stop();
    setState(() => _stepIndex = 0);
  }

  Widget _buildStructureLab(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('labStructureHint'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _structureBox(
                  context.tr('labStack'),
                  _stack.reversed.toList(),
                  theme,
                  icon: Icons.vertical_align_top,
                ),
                const SizedBox(height: 16),
                _structureBox(
                  context.tr('labQueue'),
                  _queue,
                  theme,
                  icon: Icons.arrow_forward,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('labOperations'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pushStack,
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('labPush')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _popStack,
                      icon: const Icon(Icons.remove),
                      label: Text(context.tr('labPop')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _enqueue,
                      icon: const Icon(Icons.login),
                      label: Text(context.tr('labEnqueue')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _dequeue,
                      icon: const Icon(Icons.logout),
                      label: Text(context.tr('labDequeue')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _structureBox(
    String title,
    List<String> values,
    ThemeData theme, {
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: theme.colorScheme.primary),
            const SizedBox(width: 7),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        if (values.isEmpty)
          Text(
            context.tr('labEmptyStructure'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final value in values)
                  Chip(
                    label: Text(value),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _pushStack() {
    setState(() => _stack.add('${_nextStackValue++}'));
  }

  void _popStack() {
    if (_stack.isEmpty) {
      _showStructureEmpty();
      return;
    }
    setState(() => _stack.removeLast());
  }

  void _enqueue() {
    const labels = <String>['A', 'B', 'C', 'D', 'E', 'F'];
    final label = labels[_nextQueueValue % labels.length];
    final count = _nextQueueValue ~/ labels.length;
    _nextQueueValue++;
    setState(() => _queue.add(count == 0 ? label : '$label$count'));
  }

  void _dequeue() {
    if (_queue.isEmpty) {
      _showStructureEmpty();
      return;
    }
    setState(() => _queue.removeAt(0));
  }

  void _showStructureEmpty() {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr('labEmptyStructure'))));
  }
}
