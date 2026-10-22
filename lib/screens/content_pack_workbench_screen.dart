import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n_extension.dart';
import '../services/content_pack_workbench.dart';

/// 离线内容包工作台：粘贴 JSON → 本地校验 → 查看统计与问题清单。
///
/// 不联网、不写文件；导出的模板与报告通过剪贴板交给用户。
class ContentPackWorkbenchScreen extends StatefulWidget {
  const ContentPackWorkbenchScreen({super.key});

  @override
  State<ContentPackWorkbenchScreen> createState() =>
      _ContentPackWorkbenchScreenState();
}

class _ContentPackWorkbenchScreenState
    extends State<ContentPackWorkbenchScreen> {
  final TextEditingController _controller = TextEditingController();
  ContentPackAnalysis? _analysis;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analyze() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _analysis = null;
        // 事件回调里只能只读取词，不能建立 Provider 订阅。
        _error = context.trRead('packWorkbenchEmpty');
      });
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('root-not-object');
      }
      setState(() {
        _analysis = ContentPackWorkbench.analyze(
          decoded.cast<String, dynamic>(),
        );
        _error = null;
      });
    } catch (error) {
      setState(() {
        _analysis = null;
        _error = context.trReadArgs('packWorkbenchInvalid', {
          'error': '$error',
        });
      });
    }
  }

  Future<void> _copyTemplate() async {
    await Clipboard.setData(
      ClipboardData(text: ContentPackWorkbench.template()),
    );
    if (!mounted) return;
    _toast(context.trRead('packWorkbenchTemplateCopied'));
  }

  Future<void> _copyReport() async {
    final analysis = _analysis;
    if (analysis == null) return;
    final buffer = StringBuffer()
      ..writeln('内容包：${analysis.packId} v${analysis.version}')
      ..writeln(
        '课程 ${analysis.lessonCount} · 分类 ${analysis.categoryCount} · '
        '题目 ${analysis.questionCount} · 字符 ${analysis.totalCharacters}',
      )
      ..writeln('校验问题 ${analysis.issues.length} 条');
    for (final issue in analysis.issues) {
      buffer.writeln(issue.render());
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString().trimRight()));
    if (!mounted) return;
    _toast(context.trRead('packWorkbenchReportCopied'));
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysis = _analysis;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('packWorkbenchTitle')),
        actions: [
          IconButton(
            tooltip: context.tr('packWorkbenchTemplate'),
            icon: const Icon(Icons.description_outlined),
            onPressed: _copyTemplate,
          ),
          if (analysis != null)
            IconButton(
              tooltip: context.tr('packWorkbenchReport'),
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: _copyReport,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            context.tr('packWorkbenchHint'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            minLines: 6,
            maxLines: 12,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: '{"schema": "code-learn-content-pack", ...}',
              labelText: context.tr('packWorkbenchInput'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _analyze,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: Text(context.tr('packWorkbenchAnalyze')),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  _controller.clear();
                  setState(() {
                    _analysis = null;
                    _error = null;
                  });
                },
                child: Text(context.tr('packWorkbenchClear')),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          ],
          if (analysis != null) ...[
            const SizedBox(height: 16),
            _StatsCard(analysis: analysis),
            const SizedBox(height: 12),
            if (analysis.lessons.isNotEmpty) _LessonList(analysis: analysis),
            if (analysis.issues.isNotEmpty) ...[
              const SizedBox(height: 12),
              _IssueList(issues: analysis.issues),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.analysis});

  final ContentPackAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errors = analysis.issues
        .where((item) => item.severity == ContentPackIssueSeverity.error)
        .length;
    final warnings = analysis.issues
        .where((item) => item.severity == ContentPackIssueSeverity.warning)
        .length;
    final Color color = errors > 0
        ? theme.colorScheme.error
        : (warnings > 0
              ? theme.colorScheme.tertiary
              : theme.colorScheme.primary);
    final title = errors > 0
        ? context.trArgs('packWorkbenchResultError', {'n': errors})
        : warnings > 0
        ? context.trArgs('packWorkbenchResultWarning', {'n': warnings})
        : context.tr('packWorkbenchResultOk');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  errors > 0 ? Icons.error_outline : Icons.check_circle_outline,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(label: Text('课程 ${analysis.lessonCount}')),
                Chip(label: Text('分类 ${analysis.categoryCount}')),
                Chip(label: Text('题目 ${analysis.questionCount}')),
                Chip(label: Text('约 ${analysis.estimatedMinutes} 分钟')),
                Chip(label: Text('${analysis.totalCharacters} 字')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonList extends StatelessWidget {
  const _LessonList({required this.analysis});

  final ContentPackAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(context.tr('packWorkbenchLessons')),
        subtitle: Text(
          context.trArgs('packWorkbenchLessonCount', {
            'n': analysis.lessons.length,
          }),
          style: theme.textTheme.bodySmall,
        ),
        children: [
          for (final lesson in analysis.lessons)
            ListTile(
              dense: true,
              leading: const Icon(Icons.article_outlined, size: 18),
              title: Text(lesson.title),
              subtitle: Text(
                '${lesson.id} · ${lesson.questions} 题 · '
                '${lesson.characters} 字 · ${lesson.minutes} 分钟',
              ),
            ),
        ],
      ),
    );
  }
}

class _IssueList extends StatelessWidget {
  const _IssueList({required this.issues});

  final List<ContentPackIssue> issues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(context.tr('packWorkbenchIssues')),
        subtitle: Text('${issues.length} 条', style: theme.textTheme.bodySmall),
        children: [
          for (final issue in issues.take(60))
            ListTile(
              dense: true,
              leading: Icon(
                switch (issue.severity) {
                  ContentPackIssueSeverity.error => Icons.error_outline,
                  ContentPackIssueSeverity.warning => Icons.warning_amber,
                  ContentPackIssueSeverity.info => Icons.info_outline,
                },
                size: 18,
                color: switch (issue.severity) {
                  ContentPackIssueSeverity.error => theme.colorScheme.error,
                  ContentPackIssueSeverity.warning =>
                    theme.colorScheme.tertiary,
                  ContentPackIssueSeverity.info =>
                    theme.colorScheme.onSurfaceVariant,
                },
              ),
              title: Text(issue.message),
              subtitle: issue.lessonId == null ? null : Text(issue.lessonId!),
            ),
          if (issues.length > 60)
            ListTile(
              dense: true,
              title: Text(
                context.trArgs('packWorkbenchMoreIssues', {
                  'n': issues.length - 60,
                }),
              ),
            ),
        ],
      ),
    );
  }
}
