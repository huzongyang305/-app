import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../l10n/l10n_extension.dart';
import '../models/sandbox_language.dart';
import '../models/sandbox_output.dart';
import '../theme/app_theme.dart';

/// 沙箱输出面板：按语言把原始文本升级成更易读的结构化视图。
///
///   * SQL / CSV：解析运行时附带的表格标记，渲染成真正的数据表格；
///   * Markdown：在「预览」和「HTML 源码」之间切换；
///   * 正则：把匹配到的片段在原文里高亮出来；
///   * 其余语言：保持等宽文本输出。
class SandboxOutputPanel extends StatefulWidget {
  const SandboxOutputPanel({
    super.key,
    required this.language,
    required this.output,
    required this.source,
    this.fontSize = 13,
  });

  final SandboxLanguage language;

  /// 运行时返回的原始输出（可能包含结构化标记）。
  final String output;

  /// 编辑器里的源代码，Markdown 预览与正则高亮会用到。
  final String source;

  final double fontSize;

  /// 去掉结构化标记后的纯文本，供复制、朗读等场景复用。
  static String plainText(String raw) =>
      SandboxStructuredOutput.parse(raw).text;

  @override
  State<SandboxOutputPanel> createState() => _SandboxOutputPanelState();
}

class _SandboxOutputPanelState extends State<SandboxOutputPanel> {
  /// 0 = 首选视图（表格 / 预览 / 高亮），1 = 源码或纯文本。
  int _mode = 0;

  @override
  void didUpdateWidget(SandboxOutputPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language ||
        oldWidget.output != widget.output) {
      _mode = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = SandboxStructuredOutput.parse(widget.output);
    if (widget.output.trim().isEmpty) {
      return _textSurface(
        context,
        Text(
          context.tr('sandboxNoOutput'),
          style: _textStyle(AppPalette.slate500),
        ),
      );
    }

    switch (widget.language) {
      case SandboxLanguage.sql:
      case SandboxLanguage.csv:
        final table = parsed.table;
        if (table == null) {
          return _textSurface(context, _plainText(parsed.text));
        }
        return _tableSurface(context, table);
      case SandboxLanguage.markdown:
        return _modeSurface(
          context,
          options: [
            (context.tr('sandboxMarkdownPreview'), Icons.article_outlined),
            (context.tr('sandboxMarkdownHtml'), Icons.code),
          ],
          child: _mode == 0
              ? _MarkdownPreview(source: widget.source)
              : _plainText(parsed.text),
        );
      case SandboxLanguage.regex:
        return _modeSurface(
          context,
          options: [
            (context.tr('sandboxRegexHighlight'), Icons.highlight),
            (context.tr('sandboxRegexPlain'), Icons.notes),
          ],
          child: _mode == 0
              ? _RegexHighlight(
                  source: widget.source,
                  fontSize: widget.fontSize,
                )
              : _plainText(parsed.text),
        );
      default:
        return _textSurface(context, _plainText(parsed.text));
    }
  }

  TextStyle _textStyle(Color color) => TextStyle(
    color: color,
    fontFamily: 'monospace',
    fontSize: widget.fontSize,
    height: 1.5,
  );

  Widget _modeSurface(
    BuildContext context, {
    required List<(String, IconData)> options,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<int>(
            segments: [
              for (var index = 0; index < options.length; index++)
                ButtonSegment<int>(
                  value: index,
                  label: Text(options[index].$1),
                  icon: Icon(options[index].$2, size: 16),
                ),
            ],
            selected: <int>{_mode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _mode = selection.first),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _plainText(String text) =>
      SelectableText(text, style: _textStyle(AppPalette.slate200));

  Widget _textSurface(BuildContext context, Widget child) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.slate900,
        borderRadius: AppRadii.control,
      ),
      child: child,
    );
  }

  Widget _tableSurface(BuildContext context, SandboxTable table) {
    return _textSurface(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 16,
                color: AppPalette.slate400,
              ),
              const SizedBox(width: 6),
              Text(
                context.trArgs('sandboxTableRows', {'n': table.rows.length}),
                style: TextStyle(
                  color: AppPalette.slate400,
                  fontSize: widget.fontSize - 1,
                ),
              ),
              if (table.truncated) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.trArgs('sandboxTableTruncated', {'n': 200}),
                    style: TextStyle(
                      color: AppPalette.warning,
                      fontSize: widget.fontSize - 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectionArea(
                  child: Table(
                    defaultColumnWidth: const IntrinsicColumnWidth(),
                    border: TableBorder.all(color: AppPalette.nightRule),
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: AppPalette.nightRaised,
                        ),
                        children: [
                          for (final column in table.columns)
                            _cell(column, header: true),
                        ],
                      ),
                      for (final row in table.rows)
                        TableRow(
                          children: [
                            for (
                              var index = 0;
                              index < table.columns.length;
                              index++
                            )
                              _cell(index < row.length ? row[index] : ''),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String value, {bool header = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Text(
        value,
        style: TextStyle(
          color: header ? AppPalette.paperOnNight : AppPalette.slate200,
          fontFamily: 'monospace',
          fontWeight: header ? FontWeight.w700 : FontWeight.w400,
          fontSize: widget.fontSize - 1,
        ),
      ),
    );
  }
}

/// Markdown 预览：复用 App 的 Markdown 渲染器，放在浅色表面上保证对比度。
class _MarkdownPreview extends StatelessWidget {
  const _MarkdownPreview({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: AppRadii.control,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: MarkdownBody(
        data: source,
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
          p: theme.textTheme.bodyMedium,
          code: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12.5,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }
}

/// 正则匹配高亮：在原文里用底色标出所有匹配片段。
class _RegexHighlight extends StatelessWidget {
  const _RegexHighlight({required this.source, required this.fontSize});

  final String source;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final spec = SandboxRegexSpec.tryParse(source);
    final regex = spec?.compile();
    if (spec == null || regex == null) {
      return SelectableText(
        context.tr('sandboxRegexNoMatch'),
        style: TextStyle(
          color: AppPalette.slate400,
          fontFamily: 'monospace',
          fontSize: fontSize,
        ),
      );
    }

    final matches = regex.allMatches(spec.text).take(500).toList();
    if (matches.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('sandboxRegexNoMatch'),
            style: TextStyle(color: AppPalette.slate400, fontSize: fontSize),
          ),
          const SizedBox(height: 8),
          Text(
            spec.text,
            style: TextStyle(
              color: AppPalette.slate200,
              fontFamily: 'monospace',
              fontSize: fontSize,
              height: 1.5,
            ),
          ),
        ],
      );
    }

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: spec.text.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: const TextStyle(
            backgroundColor: AppPalette.warning,
            color: Color(0xFF1A1205),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < spec.text.length) {
      spans.add(TextSpan(text: spec.text.substring(cursor)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${matches.length} · /${spec.pattern}/${spec.flags}',
          style: TextStyle(color: AppPalette.slate400, fontSize: fontSize - 1),
        ),
        const SizedBox(height: 8),
        SelectableText.rich(
          TextSpan(
            style: TextStyle(
              color: AppPalette.slate200,
              fontFamily: 'monospace',
              fontSize: fontSize,
              height: 1.5,
            ),
            children: spans,
          ),
        ),
      ],
    );
  }
}
