import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n_extension.dart';
import '../models/sandbox_language.dart';
import '../services/code_sandbox_service.dart';
import '../theme/app_theme.dart';

/// 离线多语言代码沙箱：选语言 → 写代码 → 运行 → 看输出。
///
/// 全部运行时都内置在 APK 里，运行期间不联网，也不需要安装任何解释器。
class CodeSandboxScreen extends StatefulWidget {
  const CodeSandboxScreen({
    super.key,
    this.initialCode,
    this.initialLanguageId,
  });

  /// 从题目跳转过来时可直接预填代码和语言。
  final String? initialCode;
  final String? initialLanguageId;

  @override
  State<CodeSandboxScreen> createState() => _CodeSandboxScreenState();
}

class _CodeSandboxScreenState extends State<CodeSandboxScreen> {
  late SandboxLanguage _language;
  late final TextEditingController _code;

  /// 各语言各自保留草稿，来回切换时不会丢掉已经写过的代码。
  final Map<SandboxLanguage, String> _drafts = <SandboxLanguage, String>{};

  String _output = '';
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _language =
        SandboxLanguage.tryFromId(widget.initialLanguageId) ??
        SandboxLanguage.javascript;
    _code = TextEditingController(
      text: widget.initialCode ?? _language.sampleCode,
    );
    if (widget.initialCode?.trim().isNotEmpty ?? false) {
      _drafts[_language] = widget.initialCode!;
    }
  }

  @override
  void dispose() {
    // 退出页面时销毁后台 WebView，避免残留页面继续占用内存。
    unawaited(CodeSandboxService.destroy());
    _code.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_running) return;
    if (_code.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('sandboxEmptyCode'))),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _running = true;
      _output = '';
    });
    final output = await CodeSandboxService.runCode(_language, _code.text);
    if (!mounted) return;
    setState(() {
      _running = false;
      _output = output;
    });
  }

  void _selectLanguage(SandboxLanguage language) {
    if (language == _language || _running) return;
    _drafts[_language] = _code.text;
    setState(() {
      _language = language;
      _code.text = _drafts[language] ?? language.sampleCode;
      _output = '';
    });
  }

  void _resetSample() {
    setState(() {
      _drafts.remove(_language);
      _code.text = _language.sampleCode;
    });
  }

  Future<void> _copy(String text, String messageKey) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.trRead(messageKey))));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('sandboxTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            context.tr(_language.hintKey),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: CodeSandboxService.languages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final language = CodeSandboxService.languages[index];
                final selected = language == _language;
                return ChoiceChip(
                  label: Text(context.tr(language.labelKey)),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primaryContainer,
                  onSelected: _running
                      ? null
                      : (_) => _selectLanguage(language),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            minLines: 10,
            maxLines: 20,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.5,
            ),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _running ? null : _run,
                  icon: _running
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    context.tr(_running ? 'sandboxRunning' : 'sandboxRun'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: context.tr('sandboxReset'),
                onPressed: _running ? null : _resetSample,
                icon: const Icon(Icons.restart_alt),
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                tooltip: context.tr('sandboxClear'),
                onPressed: _running
                    ? null
                    : () => setState(() => _code.clear()),
                icon: const Icon(Icons.backspace_outlined),
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                tooltip: context.tr('sandboxCopyCode'),
                onPressed: () => _copy(_code.text, 'codeCopied'),
                icon: const Icon(Icons.copy_all_outlined),
              ),
            ],
          ),
          if (_running) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                context.tr('sandboxOutput'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: context.tr('sandboxCopyOutput'),
                visualDensity: VisualDensity.compact,
                onPressed: _output.isEmpty
                    ? null
                    : () => _copy(_output, 'sandboxOutputCopied'),
                icon: const Icon(Icons.copy, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 140),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.slate900,
              borderRadius: BorderRadius.circular(6),
            ),
            child: SelectableText(
              _output.isEmpty ? context.tr('sandboxNoOutput') : _output,
              style: TextStyle(
                color: _output.isEmpty
                    ? AppPalette.slate500
                    : AppPalette.slate200,
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
