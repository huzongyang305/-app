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

  /// 难度筛选：空集合表示不限。
  final Set<String> _difficulties = <String>{};

  /// 题型筛选：空集合表示不限。
  final Set<String> _types = <String>{};

  /// 练习模式：不限时；默认限时考试。
  bool _practiceMode = false;

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
        : examPoolSize(
            content.allLessons,
            categoryId: categoryId,
            difficulties: _difficulties,
            questionTypes: _types,
          );
    final maxSize = pool == 0 ? 0 : pool.clamp(1, 100);
    final sizes = _sizeOptions.where((size) => size <= maxSize).toList();
    final selectedSize = maxSize == 0 ? 0 : _size.clamp(1, maxSize);

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
                        difficulties: _difficulties,
                        questionTypes: _types,
                        practiceMode: _practiceMode,
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
          if (progress.examDraft != null) ...[
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Icon(
                  Icons.restore,
                  color: theme.colorScheme.primary,
                ),
                title: Text(context.tr('examResume')),
                subtitle: Text(context.tr('examResumeHint')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ExamScreen(resumeDraft: true),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
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
                        color: Theme.of(context).colorScheme.primary,
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

          if (!wrongOnly) ...[
            // 难度筛选
            _SectionTitle(title: context.tr('examDifficultyFilter')),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final entry
                        in const <String, String>{
                          '入门': 'difficultyBeginner',
                          '基础': 'difficultyBasic',
                          '进阶': 'difficultyIntermediate',
                          '高级': 'difficultyAdvanced',
                        }.entries)
                      FilterChip(
                        label: Text(context.tr(entry.value)),
                        selected: _difficulties.contains(entry.key),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _difficulties.add(entry.key);
                          } else {
                            _difficulties.remove(entry.key);
                          }
                        }),
                      ),
                  ],
                ),
              ),
            ),

            // 题型筛选
            _SectionTitle(title: context.tr('examTypeFilter')),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final type in const <String>[
                      'single',
                      'multi',
                      'fill',
                      'order',
                      'code',
                      'debug',
                    ])
                      FilterChip(
                        label: Text(_typeLabel(context, type)),
                        selected: _types.contains(type),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _types.add(type);
                          } else {
                            _types.remove(type);
                          }
                        }),
                      ),
                  ],
                ),
              ),
            ),

            // 限时考试 / 练习模式
            _SectionTitle(title: context.tr('examMode')),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(context.tr('examTimedMode')),
                      icon: const Icon(Icons.timer_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(context.tr('examPracticeMode')),
                      icon: const Icon(Icons.school_outlined, size: 16),
                    ),
                  ],
                  selected: {_practiceMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) =>
                      setState(() => _practiceMode = value.first),
                ),
              ),
            ),
          ],

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
                  if (maxSize > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(context.tr('examCustomCount')),
                        ),
                        Text(
                          '$selectedSize ${context.tr('questions')}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: selectedSize.toDouble(),
                      min: 1,
                      max: maxSize.toDouble(),
                      divisions: maxSize > 1 ? maxSize - 1 : null,
                      label: '$selectedSize',
                      onChanged: (value) =>
                          setState(() => _size = value.round()),
                    ),
                  ],
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
                      '${_practiceMode ? context.tr('examNoTimeLimit') : '${_minutesFor(selectedSize)} ${context.tr('minutes')}'}',
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

/// 题型筛选标签：把数据层题型映射到界面文案。
String _typeLabel(BuildContext context, String type) => context.tr(
  switch (type) {
    'multi' => 'questionTypeMulti',
    'fill' => 'questionTypeFill',
    'order' => 'questionTypeOrder',
    'code' => 'questionTypeCode',
    'debug' => 'questionTypeDebug',
    _ => 'questionTypeSingle',
  },
);
