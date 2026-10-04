import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../models/quiz_answer.dart';
import '../models/sandbox_language.dart';
import '../screens/code_sandbox_screen.dart';
import 'quiz_option_tile.dart';

/// 统一渲染一道题的作答控件。
///
/// 单选、代码输出和排错题沿用选项卡片；多选题使用复选框；填空题使用输入框；
/// 排序题使用可拖动列表。页面只负责保存 [QuizAnswer] 并判断是否提交。
class QuizAnswerPanel extends StatefulWidget {
  const QuizAnswerPanel({
    super.key,
    required this.question,
    required this.answer,
    required this.revealed,
    required this.onChanged,
    this.onSubmit,
    this.submitOnSelect = false,
  });

  final QuizQuestion question;
  final QuizAnswer answer;
  final bool revealed;
  final ValueChanged<QuizAnswer> onChanged;
  final VoidCallback? onSubmit;
  final bool submitOnSelect;

  @override
  State<QuizAnswerPanel> createState() => _QuizAnswerPanelState();
}

class _QuizAnswerPanelState extends State<QuizAnswerPanel> {
  late final TextEditingController _fillController;

  @override
  void initState() {
    super.initState();
    _fillController = TextEditingController(text: widget.answer.text);
  }

  @override
  void didUpdateWidget(covariant QuizAnswerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.question != widget.question.question ||
        widget.answer.text != _fillController.text) {
      _fillController.text = widget.answer.text;
    }
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.question.type) {
      'fill' => _buildFill(context),
      'order' => _buildOrder(context),
      _ => _buildOptions(context),
    };
  }

  Widget _buildFill(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('quizFillHint'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _fillController,
          enabled: !widget.revealed,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onChanged: (value) =>
              widget.onChanged(widget.answer.copyWith(text: value)),
          onSubmitted: (_) => widget.onSubmit?.call(),
          decoration: InputDecoration(
            hintText: context.tr('quizFillPlaceholder'),
            border: const OutlineInputBorder(),
            suffixIcon: widget.revealed
                ? const Icon(Icons.lock_outline)
                : const Icon(Icons.edit_outlined),
          ),
        ),
        if (widget.revealed && widget.question.acceptedAnswers.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            '${context.tr('quizAcceptedAnswers')}: '
            '${widget.question.acceptedAnswers.join(' / ')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrder(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.answer.orderedIndexes.isEmpty
        ? List<int>.generate(widget.question.options.length, (i) => i)
        : widget.answer.orderedIndexes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('quizOrderHint'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: order.length,
          onReorderItem: (oldIndex, newIndex) {
            if (widget.revealed) return;
            final next = <int>[...order];
            final item = next.removeAt(oldIndex);
            next.insert(newIndex, item);
            widget.onChanged(widget.answer.copyWith(orderedIndexes: next));
          },
          itemBuilder: (context, position) {
            final optionIndex = order[position];
            final correct =
                widget.revealed &&
                position < widget.question.correctOrder.length &&
                widget.question.correctOrder[position] == optionIndex;
            return Card(
              key: ValueKey<int>(optionIndex),
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              color: correct
                  ? const Color(0xFF16A34A).withValues(alpha: 0.10)
                  : theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: correct
                      ? const Color(0xFF16A34A)
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  child: Text('${position + 1}'),
                ),
                title: Text(widget.question.options[optionIndex]),
                trailing: widget.revealed
                    ? Icon(
                        correct ? Icons.check_circle : Icons.drag_indicator,
                        color: correct ? const Color(0xFF16A34A) : null,
                      )
                    : ReorderableDragStartListener(
                        index: position,
                        child: const Icon(Icons.drag_handle),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOptions(BuildContext context) {
    final question = widget.question;
    if (question.code?.trim().isNotEmpty ?? false) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CodePreview(question: question),
          const SizedBox(height: 14),
          for (var i = 0; i < question.options.length; i++)
            QuizOptionTile(
              label: question.options[i],
              index: i,
              selected: widget.answer.selectedIndexes.contains(i),
              correct: widget.revealed && question.correctIndexes.contains(i),
              answered: widget.revealed,
              multiSelect: question.type == 'multi',
              onTap: _onOptionTap,
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < question.options.length; i++)
          QuizOptionTile(
            label: question.options[i],
            index: i,
            selected: widget.answer.selectedIndexes.contains(i),
            correct: widget.revealed && question.correctIndexes.contains(i),
            answered: widget.revealed,
            multiSelect: question.type == 'multi',
            onTap: _onOptionTap,
          ),
      ],
    );
  }

  void _onOptionTap(int index) {
    if (widget.revealed) return;
    final next = widget.question.type == 'multi'
        ? widget.answer.toggleOption(index)
        : widget.answer.selectOnly(index);
    widget.onChanged(next);
    if (widget.submitOnSelect) widget.onSubmit?.call();
  }
}

class _CodePreview extends StatelessWidget {
  const _CodePreview({required this.question});

  final QuizQuestion question;

  Future<void> _run(BuildContext context) async {
    final language = SandboxLanguage.tryFromId(question.language);
    if (language == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('quizCodeRunUnsupported'))),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CodeSandboxScreen(
          initialCode: question.code,
          initialLanguageId: language.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = question.code ?? '';
    final language = SandboxLanguage.tryFromId(question.language);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Text(
                language?.id.toUpperCase() ?? 'CODE',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: context.tr('copy'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.trRead('codeCopied'))),
                  );
                },
                icon: const Icon(
                  Icons.copy,
                  color: Color(0xFFCBD5E1),
                  size: 18,
                ),
              ),
              if (language != null)
                TextButton.icon(
                  onPressed: () => _run(context),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(context.tr('quizRunInSandbox')),
                ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: SelectableText(
              code,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
