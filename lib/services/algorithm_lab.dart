/// 一步算法演示的状态快照。
///
/// 算法逻辑与 Flutter 界面解耦，方便单元测试，也方便后续增加更多算法。
class LabStep {
  const LabStep({
    required this.values,
    required this.messageKey,
    this.messageArgs = const <String, String>{},
    this.low,
    this.high,
    this.mid,
    this.activeIndex,
    this.compareIndex,
    this.found = false,
    this.done = false,
    this.swapped = false,
  });

  final List<int> values;
  final String messageKey;
  final Map<String, String> messageArgs;

  /// 二分查找的三个边界；不适用时为空。
  final int? low;
  final int? high;
  final int? mid;

  /// 当前比较或交换的两个位置。
  final int? activeIndex;
  final int? compareIndex;

  final bool found;
  final bool done;
  final bool swapped;
}

/// 纯 Dart 算法演示步骤生成器。
class AlgorithmLab {
  const AlgorithmLab._();

  /// 生成二分查找的每一步。
  ///
  /// 输入会先排序；每一步都保留当前搜索区间，便于界面显示 low / mid / high。
  static List<LabStep> binarySearchSteps(List<int> source, int target) {
    final values = [...source]..sort();
    if (values.isEmpty) {
      return const [LabStep(values: <int>[], messageKey: 'labSearchNotFound')];
    }

    var low = 0;
    var high = values.length - 1;
    final steps = <LabStep>[
      LabStep(
        values: [...values],
        messageKey: 'labSearchStart',
        messageArgs: {'target': '$target'},
        low: low,
        high: high,
      ),
    ];

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final current = values[mid];
      steps.add(
        LabStep(
          values: [...values],
          messageKey: 'labSearchCompare',
          messageArgs: {
            'value': '$current',
            'target': '$target',
            'mid': '$mid',
          },
          low: low,
          high: high,
          mid: mid,
          activeIndex: mid,
          compareIndex: mid,
        ),
      );

      if (current == target) {
        steps.add(
          LabStep(
            values: [...values],
            messageKey: 'labSearchFound',
            messageArgs: {'value': '$current', 'mid': '$mid'},
            low: low,
            high: high,
            mid: mid,
            activeIndex: mid,
            compareIndex: mid,
            found: true,
            done: true,
          ),
        );
        return steps;
      }

      if (current < target) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    steps.add(
      LabStep(
        values: [...values],
        messageKey: 'labSearchNotFound',
        messageArgs: {'target': '$target'},
        done: true,
      ),
    );
    return steps;
  }

  /// 生成冒泡排序的每一步，展示比较和交换位置。
  static List<LabStep> bubbleSortSteps(List<int> source) {
    final values = [...source];
    final steps = <LabStep>[
      LabStep(values: [...values], messageKey: 'labBubbleStart'),
    ];
    if (values.length < 2) {
      steps.add(
        LabStep(values: [...values], messageKey: 'labBubbleDone', done: true),
      );
      return steps;
    }

    for (var end = values.length - 1; end > 0; end--) {
      var swappedInPass = false;
      for (var index = 0; index < end; index++) {
        final left = values[index];
        final right = values[index + 1];
        if (left > right) {
          values[index] = right;
          values[index + 1] = left;
          swappedInPass = true;
          steps.add(
            LabStep(
              values: [...values],
              messageKey: 'labBubbleSwap',
              messageArgs: {
                'left': '$left',
                'right': '$right',
                'index': '${index + 1}',
              },
              activeIndex: index,
              compareIndex: index + 1,
              swapped: true,
            ),
          );
        } else {
          steps.add(
            LabStep(
              values: [...values],
              messageKey: 'labBubbleCompare',
              messageArgs: {
                'left': '$left',
                'right': '$right',
                'index': '${index + 1}',
              },
              activeIndex: index,
              compareIndex: index + 1,
            ),
          );
        }
      }
      if (!swappedInPass) break;
    }

    steps.add(
      LabStep(values: [...values], messageKey: 'labBubbleDone', done: true),
    );
    return steps;
  }

  /// 生成插入排序的每一步：左侧是已排序区，右侧是待处理区。
  static List<LabStep> insertionSortSteps(List<int> source) {
    final values = [...source];
    final steps = <LabStep>[
      LabStep(values: [...values], messageKey: 'labInsertionStart'),
    ];
    if (values.length < 2) {
      steps.add(
        LabStep(
          values: [...values],
          messageKey: 'labInsertionDone',
          done: true,
        ),
      );
      return steps;
    }

    for (var index = 1; index < values.length; index++) {
      final current = values[index];
      var position = index - 1;
      while (position >= 0 && values[position] > current) {
        final compared = values[position];
        values[position + 1] = compared;
        steps.add(
          LabStep(
            values: [...values],
            messageKey: 'labInsertionShift',
            messageArgs: {'value': '$current', 'compare': '$compared'},
            activeIndex: position,
            compareIndex: position + 1,
            swapped: true,
          ),
        );
        position--;
      }
      values[position + 1] = current;
      steps.add(
        LabStep(
          values: [...values],
          messageKey: 'labInsertionPlace',
          messageArgs: {'value': '$current', 'index': '${position + 1}'},
          activeIndex: position + 1,
          compareIndex: position + 1,
        ),
      );
    }

    steps.add(
      LabStep(values: [...values], messageKey: 'labInsertionDone', done: true),
    );
    return steps;
  }

  /// 生成选择排序的每一步：每轮从未排序区选择最小值并交换到区首。
  static List<LabStep> selectionSortSteps(List<int> source) {
    final values = [...source];
    final steps = <LabStep>[
      LabStep(values: [...values], messageKey: 'labSelectionStart'),
    ];
    if (values.length < 2) {
      steps.add(
        LabStep(
          values: [...values],
          messageKey: 'labSelectionDone',
          done: true,
        ),
      );
      return steps;
    }

    for (var start = 0; start < values.length - 1; start++) {
      var minimumIndex = start;
      for (var index = start + 1; index < values.length; index++) {
        steps.add(
          LabStep(
            values: [...values],
            messageKey: 'labSelectionCompare',
            messageArgs: {
              'minimum': '${values[minimumIndex]}',
              'candidate': '${values[index]}',
            },
            activeIndex: minimumIndex,
            compareIndex: index,
          ),
        );
        if (values[index] < values[minimumIndex]) {
          minimumIndex = index;
        }
      }

      if (minimumIndex != start) {
        final minimum = values[minimumIndex];
        values[minimumIndex] = values[start];
        values[start] = minimum;
        steps.add(
          LabStep(
            values: [...values],
            messageKey: 'labSelectionSwap',
            messageArgs: {'minimum': '$minimum', 'index': '$start'},
            activeIndex: start,
            compareIndex: minimumIndex,
            swapped: true,
          ),
        );
      }
    }

    steps.add(
      LabStep(values: [...values], messageKey: 'labSelectionDone', done: true),
    );
    return steps;
  }
}
