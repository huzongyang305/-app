import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/content_provider.dart';
import '../services/exam_builder.dart';
import '../services/progress_provider.dart';
import '../widgets/icon_mapper.dart';
import 'exam_screen.dart';

/// 模拟考试设置页：先选范围与题量，再进入考试。
///
/// 范围支持「全部课程」或某一个分类；题量按范围内可用知识点数量给出候选，
/// 避免出现「题量大于题库」的无效组合。
class ExamSetupScreen extends StatefulWidget {
  const ExamSetupScreen({super.key});

  @override
  State<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends State<ExamSetupScreen> {
  static const List<int> _sizeOptions = <int>[10, 20, 30, 50];

  /// 错题重练在范围选择里的哨兵值（与分类 id 区分开）。
  static const String _wrongScope = '__wrong__';

  /// null 表示全部课程，[_wrongScope] 表示错题重练，其余为分类 id。
  String? _scope;
  int _size = 10;

  /// 按题量换算考试时长：每 10 题约 15 分钟。
  int _minutesFor(int size) => (size * 1.5).round().clamp(5, 120);

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);

    final wrongOnly = _scope == _wrongScope;
    final categoryId = (_scope == null || wrongOnly) ? null : _scope;
    final wrongPool = wrongQuestionPoolSize(
      content.allLessons,
      progress.wrongQuestionKeys,
    );
    final pool = wrongOnly
        ? wrongPool
        : examPoolSize(content.allLessons, categoryId: categoryId);
    var sizes = _sizeOptions.where((size) => size <= pool).toList();
    if (sizes.isEmpty && pool > 0) sizes = <int>[pool];
    final selectedSize = sizes.contains(_size)
        ? _size
        : (sizes.isEmpty ? 0 : sizes.first);

    final scopeName = wrongOnly
        ? context.tr('wrongDrill')
        : categoryId == null
        ? context.tr('examAllCourses')
        : content.categories
              .firstWhere((category) => category.id == categoryId)
              .title
              .of(context.strings.localeCode);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('mockExam'))),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: pool == 0 || selectedSize == 0
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ExamScreen(
                        size: selectedSize,
                        minutes: _minutesFor(selectedSize),
                        categoryId: categoryId,
                        scopeTitle: scopeName,
                        wrongOnly: wrongOnly,
                      ),
                    ),
                  ),
            icon: const Icon(Icons.play_arrow),
            label: Text(context.tr('examStart')),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 范围
          _SectionTitle(title: context.tr('examScope')),
          Card(
            child: RadioGroup<String?>(
              groupValue: _scope,
              onChanged: (value) => setState(() => _scope = value),
              child: Column(
                children: [
                  RadioListTile<String?>(
                    value: null,
                    title: Text(context.tr('examAllCourses')),
                    subtitle: Text(
                      '${examPoolSize(content.allLessons)} ${context.tr('lessons')}',
                    ),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String?>(
                    value: _wrongScope,
                    secondary: Icon(
                      Icons.replay_circle_filled_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(context.tr('wrongDrill')),
                    subtitle: Text(
                      wrongPool == 0
                          ? context.tr('wrongDrillEmpty')
                          : '$wrongPool ${context.tr('questions')}',
                    ),
                    enabled: wrongPool > 0,
                  ),
                  for (final category in content.categories) ...[
                    const Divider(height: 1),
                    RadioListTile<String?>(
                      value: category.id,
                      secondary: Icon(
                        iconFromName(category.iconName),
                        color: Color(0xFF000000 | category.colorValue),
                      ),
                      title: Text(
                        category.title.of(context.strings.localeCode),
                      ),
                      subtitle: Text(
                        '${category.lessons.length} ${context.tr('lessons')}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 题量
          _SectionTitle(title: context.tr('examQuestionsCount')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sizes.isEmpty)
                    Text(
                      context.tr('examNoQuestion'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final size in sizes)
                          ChoiceChip(
                            label: Text('$size ${context.tr('questions')}'),
                            selected: size == selectedSize,
                            onSelected: (_) => setState(() => _size = size),
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Text(
                    '${context.tr('examPoolHint')}：'
                    '$pool ${context.tr('lessons')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (selectedSize > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${context.tr('examTimeHint')}：'
                      '${_minutesFor(selectedSize)} ${context.tr('minutes')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Text(
            context.tr('examRuleHint'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
