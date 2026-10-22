import 'package:code_learn_app/services/algorithm_lab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('二分查找会记录命中位置并结束演示', () {
    final steps = AlgorithmLab.binarySearchSteps(<int>[8, 2, 5], 5);

    expect(steps.first.messageKey, 'labSearchStart');
    expect(steps.last.found, isTrue);
    expect(steps.last.done, isTrue);
    expect(steps.last.values, <int>[2, 5, 8]);
    expect(steps.last.mid, 1);
  });

  test('二分查找未命中时给出结束状态', () {
    final steps = AlgorithmLab.binarySearchSteps(<int>[1, 3, 5], 9);

    expect(steps.last.done, isTrue);
    expect(steps.last.found, isFalse);
    expect(steps.last.messageKey, 'labSearchNotFound');
  });

  test('冒泡排序步骤最终得到升序数组并包含交换记录', () {
    final steps = AlgorithmLab.bubbleSortSteps(<int>[3, 1, 2]);

    expect(steps.any((step) => step.swapped), isTrue);
    expect(steps.last.done, isTrue);
    expect(steps.last.values, <int>[1, 2, 3]);
  });

  test('插入排序步骤最终有序且包含移动与放置记录', () {
    final steps = AlgorithmLab.insertionSortSteps(<int>[5, 2, 4, 1]);

    expect(steps.first.messageKey, 'labInsertionStart');
    expect(steps.any((step) => step.messageKey == 'labInsertionShift'), isTrue);
    expect(steps.any((step) => step.swapped), isTrue);
    expect(steps.last.messageKey, 'labInsertionDone');
    expect(steps.last.done, isTrue);
    expect(steps.last.values, <int>[1, 2, 4, 5]);
  });

  test('插入排序对空数组与单元素数组直接结束', () {
    final empty = AlgorithmLab.insertionSortSteps(const <int>[]);
    final single = AlgorithmLab.insertionSortSteps(const <int>[7]);

    expect(empty.last.done, isTrue);
    expect(empty.last.values, isEmpty);
    expect(single.last.done, isTrue);
    expect(single.last.values, <int>[7]);
  });

  test('选择排序步骤最终有序并包含比较与交换记录', () {
    final steps = AlgorithmLab.selectionSortSteps(<int>[4, 1, 3, 2]);

    expect(steps.first.messageKey, 'labSelectionStart');
    expect(
      steps.any((step) => step.messageKey == 'labSelectionCompare'),
      isTrue,
    );
    expect(steps.any((step) => step.messageKey == 'labSelectionSwap'), isTrue);
    expect(steps.last.messageKey, 'labSelectionDone');
    expect(steps.last.values, <int>[1, 2, 3, 4]);
  });

  test('选择排序对已有序数组仍以完成步骤收尾', () {
    final steps = AlgorithmLab.selectionSortSteps(<int>[1, 2, 3]);

    expect(steps.last.done, isTrue);
    expect(steps.last.values, <int>[1, 2, 3]);
  });
}
