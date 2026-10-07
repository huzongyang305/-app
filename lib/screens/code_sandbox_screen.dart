import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/code_snippet.dart';
import '../models/sandbox_challenge.dart';
import '../models/sandbox_language.dart';
import '../services/code_sandbox_service.dart';
import '../services/sandbox_challenge_service.dart';
import '../services/share_service.dart';
import '../services/snippet_service.dart';
import '../services/settings_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/code_editor_field.dart';
import '../widgets/sandbox_output_panel.dart';
import 'sandbox_editor_screen.dart';

/// 离线多语言代码沙箱：选语言 → 写代码 / 填标准输入 → 运行 → 看输出。
///
/// 全部运行时都内置在 APK 里，运行期间不联网，也不需要安装任何解释器。
/// 片段库、示例库与字号设置都保存在本地。
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
  late final TextEditingController _stdin;

  /// 各语言各自保留草稿，来回切换时不会丢掉已经写过的代码。
  final Map<SandboxLanguage, String> _drafts = <SandboxLanguage, String>{};
  final Map<SandboxLanguage, String> _stdinDrafts = <SandboxLanguage, String>{};

  SnippetService? _snippets;
  String _output = '';
  bool _running = false;

  /// 当前选中的挑战；为空表示普通编辑模式。
  SandboxChallenge? _challenge;

  /// 最近一次挑战运行是否通过；为空表示还没运行过。
  bool? _challengePassed;

  /// 最近一次挑战运行的真实输出，用于失败时对照。
  String _challengeActual = '';

  bool _challengeHintVisible = false;

  /// 每次运行的令牌：用户中途停止或连续运行多次时，只接受最新一次的结果。
  int _runToken = 0;

  @override
  void initState() {
    super.initState();
    _language =
        SandboxLanguage.tryFromId(widget.initialLanguageId) ??
        SandboxLanguage.javascript;
    _code = TextEditingController(
      text: widget.initialCode ?? _language.sampleCode,
    );
    _stdin = TextEditingController();
    if (widget.initialCode?.trim().isNotEmpty ?? false) {
      _drafts[_language] = widget.initialCode!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _snippets ??= _resolveSnippets(context);
  }

  /// 片段库依赖本地存储；测试等没有注入存储的场景自动降级为不可用。
  SnippetService? _resolveSnippets(BuildContext context) {
    try {
      return SnippetService(context.read<StorageService>());
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  void dispose() {
    // 退出页面时销毁后台 WebView，避免残留页面继续占用内存。
    unawaited(CodeSandboxService.destroy());
    _code.dispose();
    _stdin.dispose();
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
    final token = ++_runToken;
    setState(() {
      _running = true;
      _output = '';
    });
    final output = await CodeSandboxService.runCode(
      _language,
      _code.text,
      stdin: _language.supportsStdin ? _stdin.text : '',
    );
    if (!mounted || token != _runToken) return;
    setState(() {
      _running = false;
      _output = output;
    });
  }

  /// 打开挑战选择面板；没有挑战的语言给出明确提示。
  Future<void> _pickChallenge() async {
    final challenges = _language.challenges;
    if (challenges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('sandboxChallengeNone'))),
      );
      return;
    }
    final theme = Theme.of(context);
    final settings = context.read<SettingsProvider>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('sandboxChallengePick'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    context.trReadArgs('sandboxChallengeProgress', {
                      'passed': _passedChallengeCount(settings).toString(),
                      'total': challenges.length.toString(),
                    }),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final challenge in challenges)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    settings.isSandboxChallengePassed(challenge.id)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: settings.isSandboxChallengePassed(challenge.id)
                        ? AppPalette.success
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(challenge.title.of(context.strings.localeCode)),
                  subtitle: Text(
                    challenge.prompt.of(context.strings.localeCode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: challenge.id == _challenge?.id
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _startChallenge(challenge);
                  },
                ),
              const Divider(height: 24),
              TextButton.icon(
                onPressed: settings.passedSandboxChallenges.isEmpty
                    ? null
                    : () async {
                        await settings.resetSandboxChallengeProgress();
                        if (!mounted || !sheetContext.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.trRead('sandboxChallengeResetDone'),
                            ),
                          ),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                icon: const Icon(Icons.restart_alt, size: 18),
                label: Text(context.tr('sandboxChallengeReset')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 当前语言下已通过的挑战数量。
  int _passedChallengeCount(SettingsProvider settings) {
    return _language.challenges
        .where((challenge) => settings.isSandboxChallengePassed(challenge.id))
        .length;
  }

  /// 选中挑战：填入起始代码、输入数据并重置挑战状态。
  void _startChallenge(SandboxChallenge challenge) {
    setState(() {
      _challenge = challenge;
      _challengePassed = null;
      _challengeActual = '';
      _challengeHintVisible = false;
      _code.text = challenge.starterCode;
      _stdin.text = challenge.stdin;
      _drafts[_language] = challenge.starterCode;
      _stdinDrafts[_language] = challenge.stdin;
      _output = '';
    });
  }

  void _exitChallenge() {
    setState(() {
      _challenge = null;
      _challengePassed = null;
      _challengeActual = '';
      _challengeHintVisible = false;
    });
  }

  void _loadStarterCode() {
    final challenge = _challenge;
    if (challenge == null) return;
    setState(() {
      _code.text = challenge.starterCode;
      _stdin.text = challenge.stdin;
      _drafts[_language] = challenge.starterCode;
      _stdinDrafts[_language] = challenge.stdin;
      _challengePassed = null;
      _challengeActual = '';
      _output = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.trRead('sandboxChallengeStarterLoaded'))),
    );
  }

  /// 运行挑战：执行代码 → 规范化输出 → 与期望输出比对 → 记录通关。
  Future<void> _runChallenge() async {
    final challenge = _challenge;
    if (challenge == null || _running) return;
    if (_code.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('sandboxEmptyCode'))),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final token = ++_runToken;
    setState(() {
      _running = true;
      _output = '';
      _challengePassed = null;
      _challengeActual = '';
    });
    final output = await CodeSandboxService.runCode(
      _language,
      _code.text,
      stdin: _language.supportsStdin ? _stdin.text : '',
    );
    if (!mounted || token != _runToken) return;
    final passed = SandboxChallengeService.matches(
      actual: output,
      expected: challenge.expectedOutput,
    );
    setState(() {
      _running = false;
      _output = output;
      _challengePassed = passed;
      _challengeActual = output;
    });
    if (passed) {
      final settings = context.read<SettingsProvider>();
      await settings.markSandboxChallengePassed(challenge.id);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.trRead(
            passed
                ? 'sandboxChallengePassedToast'
                : 'sandboxChallengeFailedToast',
          ),
        ),
      ),
    );
  }

  /// 停止运行：销毁 WebView，并让正在等待的旧结果失效。
  Future<void> _stop() async {
    if (!_running) return;
    final stopped = context.trRead('sandboxStopped');
    _runToken++;
    await CodeSandboxService.destroy();
    if (!mounted) return;
    setState(() {
      _running = false;
      _output = stopped;
    });
  }

  void _selectLanguage(SandboxLanguage language) {
    if (language == _language || _running) return;
    _drafts[_language] = _code.text;
    _stdinDrafts[_language] = _stdin.text;
    setState(() {
      _language = language;
      _code.text = _drafts[language] ?? language.sampleCode;
      _stdin.text = _stdinDrafts[language] ?? '';
      _output = '';
      _challenge = null;
      _challengePassed = null;
      _challengeActual = '';
      _challengeHintVisible = false;
    });
  }

  void _applyExample(SandboxExample example) {
    setState(() {
      _code.text = example.code;
      _stdin.text = example.stdin;
      _drafts[_language] = example.code;
      _stdinDrafts[_language] = example.stdin;
      _output = '';
      _challenge = null;
      _challengePassed = null;
      _challengeActual = '';
      _challengeHintVisible = false;
    });
  }

  void _resetSample() {
    setState(() {
      _drafts.remove(_language);
      _stdinDrafts.remove(_language);
      _code.text = _language.sampleCode;
      _stdin.text = '';
      _output = '';
      _challenge = null;
      _challengePassed = null;
      _challengeActual = '';
      _challengeHintVisible = false;
    });
  }

  Future<void> _copy(String text, String messageKey) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.trRead(messageKey))));
  }

  Future<void> _share() async {
    final shared = await const ShareService().shareText(
      _code.text,
      subject: context.trRead(_language.labelKey),
    );
    if (!mounted) return;
    if (!shared) {
      await _copy(_code.text, 'codeCopied');
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.trRead('sandboxShared'))));
  }

  Future<void> _openFullscreen(SettingsProvider settings) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => SandboxEditorScreen(
          title: context.trRead(_language.labelKey),
          initialCode: _code.text,
          fontScale: settings.sandboxFontScale,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _code.text = result;
      _drafts[_language] = result;
    });
  }

  Future<void> _showExamples() async {
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              context.tr('sandboxExamples'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final example in _language.examples)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                ),
                title: Text(example.title.of(context.strings.localeCode)),
                subtitle: example.stdin.isEmpty
                    ? null
                    : Text(context.tr('sandboxExampleWithStdin')),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _applyExample(example);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSnippets() async {
    final service = _snippets;
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('sandboxSnippetsUnavailable'))),
      );
      return;
    }
    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final items = service.snippets;
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr('sandboxSnippets'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            Navigator.of(sheetContext).pop();
                            await _saveSnippet();
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(context.tr('sandboxSaveSnippet')),
                        ),
                      ],
                    ),
                  ),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('sandboxSnippetEmpty'),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('sandboxSnippetEmptyHint'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final snippet = items[index];
                          final language = SandboxLanguage.fromId(
                            snippet.languageId,
                          );
                          return ListTile(
                            leading: Icon(
                              snippet.favorite ? Icons.star : Icons.code,
                              color: snippet.favorite
                                  ? AppPalette.warning
                                  : theme.colorScheme.primary,
                            ),
                            title: Text(
                              snippet.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              context.tr(language.labelKey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: context.tr('sandboxFavorite'),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () async {
                                    await service.toggleFavorite(snippet.id);
                                    setSheetState(() {});
                                  },
                                  icon: Icon(
                                    snippet.favorite
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  tooltip: context.tr('delete'),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () async {
                                    await service.remove(snippet.id);
                                    setSheetState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              _loadSnippet(snippet);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _loadSnippet(CodeSnippet snippet) {
    final language = SandboxLanguage.fromId(snippet.languageId);
    setState(() {
      _language = language;
      _code.text = snippet.code;
      _stdin.text = snippet.stdin;
      _drafts[language] = snippet.code;
      _stdinDrafts[language] = snippet.stdin;
      _output = '';
      _challenge = null;
      _challengePassed = null;
      _challengeActual = '';
      _challengeHintVisible = false;
    });
  }

  /// 挑战面板：任务要求、输入 / 期望输出、运行结果与操作按钮。
  Widget _buildChallengeCard(ThemeData theme) {
    final challenge = _challenge!;
    final localeCode = context.strings.localeCode;
    final passed = _challengePassed;
    final actual = _challengeActual.isEmpty
        ? ''
        : SandboxChallengeService.normalize(_challengeActual);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadii.card,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  challenge.title.of(localeCode),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (passed != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (passed ? AppPalette.success : AppPalette.danger)
                        .withValues(alpha: 0.12),
                    borderRadius: AppRadii.chip,
                  ),
                  child: Text(
                    context.tr(
                      passed
                          ? 'sandboxChallengePassedTag'
                          : 'sandboxChallengeFailedTag',
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: passed ? AppPalette.success : AppPalette.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            challenge.prompt.of(localeCode),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildChallengeField(
            theme,
            context.tr('sandboxChallengeStdin'),
            challenge.stdin.isEmpty
                ? context.tr('sandboxChallengeNoStdin')
                : challenge.stdin,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildChallengeField(
            theme,
            context.tr('sandboxChallengeExpected'),
            challenge.expectedOutput,
          ),
          if (passed == false && actual.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildChallengeField(
              theme,
              context.tr('sandboxChallengeActual'),
              actual,
              accent: AppPalette.danger,
            ),
          ],
          if (challenge.hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: () => setState(
                () => _challengeHintVisible = !_challengeHintVisible,
              ),
              icon: Icon(
                _challengeHintVisible
                    ? Icons.lightbulb
                    : Icons.lightbulb_outline,
                size: 18,
              ),
              label: Text(context.tr('sandboxChallengeHint')),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
            if (_challengeHintVisible)
              Text(
                challenge.hint!.of(localeCode),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: _running ? null : _runChallenge,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: Text(context.tr('sandboxChallengeRun')),
              ),
              OutlinedButton.icon(
                onPressed: _running ? null : _loadStarterCode,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: Text(context.tr('sandboxChallengeLoadStarter')),
              ),
              TextButton.icon(
                onPressed: _running ? null : _exitChallenge,
                icon: const Icon(Icons.close, size: 18),
                label: Text(context.tr('sandboxChallengeExit')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 挑战面板里的只读文本块（输入数据 / 期望输出 / 实际输出）。
  Widget _buildChallengeField(
    ThemeData theme,
    String label,
    String value, {
    Color? accent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadii.control,
            border: Border.all(
              color: accent ?? theme.colorScheme.outlineVariant,
            ),
          ),
          child: SelectableText(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSnippet() async {
    final service = _snippets;
    if (service == null) return;
    final now = DateTime.now();
    final controller = TextEditingController(
      text: '${context.trRead(_language.labelKey)} ${now.month}-${now.day}',
    );
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('sandboxSaveSnippet')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.tr('sandboxSnippetTitle'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty || !mounted) return;
    await service.upsert(
      languageId: _language.id,
      title: title,
      code: _code.text,
      stdin: _stdin.text,
      now: DateTime.now(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.trRead('sandboxSnippetSaved'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final scale = settings.sandboxFontScale;

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
          if (_language.isTraceOnly) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  label: Text(context.tr('sandboxTraceBadge')),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('sandboxTraceBanner'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
          if (_challenge != null) ...[
            const SizedBox(height: 12),
            _buildChallengeCard(theme),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                context.tr('sandboxCodeLabel'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: context.tr('sandboxFontSmaller'),
                visualDensity: VisualDensity.compact,
                onPressed: () => settings.setSandboxFontScale(scale - 0.1),
                icon: const Icon(Icons.text_decrease, size: 20),
              ),
              IconButton(
                tooltip: context.tr('sandboxFontLarger'),
                visualDensity: VisualDensity.compact,
                onPressed: () => settings.setSandboxFontScale(scale + 0.1),
                icon: const Icon(Icons.text_increase, size: 20),
              ),
              IconButton(
                tooltip: context.tr('sandboxFullscreen'),
                visualDensity: VisualDensity.compact,
                onPressed: _running ? null : () => _openFullscreen(settings),
                icon: const Icon(Icons.open_in_full, size: 20),
              ),
              PopupMenuButton<String>(
                tooltip: context.tr('sandboxMore'),
                onSelected: (value) {
                  switch (value) {
                    case 'save':
                      _saveSnippet();
                    case 'share':
                      _share();
                    case 'copy':
                      _copy(_code.text, 'codeCopied');
                    case 'clear':
                      setState(() => _code.clear());
                    case 'reset':
                      _resetSample();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'save',
                    child: Text(context.trRead('sandboxSaveSnippet')),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Text(context.trRead('sandboxShare')),
                  ),
                  PopupMenuItem(
                    value: 'copy',
                    child: Text(context.trRead('sandboxCopyCode')),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    child: Text(context.tr('sandboxClear')),
                  ),
                  PopupMenuItem(
                    value: 'reset',
                    child: Text(context.tr('sandboxReset')),
                  ),
                ],
              ),
            ],
          ),
          CodeEditorField(
            controller: _code,
            minLines: 10,
            maxLines: 22,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13 * scale,
              height: 1.5,
            ),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.lightbulb_outline, size: 18),
                label: Text(context.tr('sandboxExamples')),
                onPressed: _running ? null : _showExamples,
              ),
              ActionChip(
                avatar: Icon(
                  _challenge == null
                      ? Icons.emoji_events_outlined
                      : Icons.emoji_events,
                  size: 18,
                ),
                label: Text(
                  _language.challenges.isEmpty
                      ? context.tr('sandboxChallenge')
                      : '${context.tr('sandboxChallenge')} '
                            '(${_passedChallengeCount(settings)}/'
                            '${_language.challenges.length})',
                ),
                backgroundColor: _challenge == null
                    ? null
                    : theme.colorScheme.primaryContainer,
                onPressed: _running ? null : _pickChallenge,
              ),
              ActionChip(
                avatar: const Icon(Icons.bookmark_border, size: 18),
                label: Text(
                  _snippets == null
                      ? context.tr('sandboxSnippets')
                      : '${context.tr('sandboxSnippets')} '
                            '(${_snippets!.length})',
                ),
                onPressed: _running ? null : _showSnippets,
              ),
            ],
          ),
          if (_language.supportsStdin) ...[
            const SizedBox(height: 12),
            Text(
              context.tr('sandboxStdin'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('sandboxStdinHint'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _stdin,
              minLines: 2,
              maxLines: 5,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.multiline,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13 * scale,
                height: 1.4,
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: context.tr('sandboxStdinPlaceholder'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _running
                    ? FilledButton.icon(
                        onPressed: _stop,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        icon: const Icon(Icons.stop_rounded),
                        label: Text(context.tr('sandboxStop')),
                      )
                    : FilledButton.icon(
                        // 挑战模式下由挑战卡里的「运行测试用例」负责比对，
                        // 主按钮始终是普通运行，避免同屏出现两个同名按钮。
                        onPressed: _run,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(context.tr('sandboxRun')),
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
                tooltip: context.tr('sandboxShare'),
                onPressed: _running ? null : _share,
                icon: const Icon(Icons.ios_share),
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
                    : () => _copy(
                        SandboxOutputPanel.plainText(_output),
                        'sandboxOutputCopied',
                      ),
                icon: const Icon(Icons.copy, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SandboxOutputPanel(
            language: _language,
            output: _output,
            source: _code.text,
            fontSize: 13 * scale,
          ),
        ],
      ),
    );
  }
}
