import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../models/note_anchor.dart';
import '../services/content_provider.dart';
import '../services/practice_question_factory.dart';
import '../services/progress_provider.dart';
import '../services/settings_provider.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/markdown_code_builder.dart';
import '../widgets/responsive_content.dart';
import 'code_sandbox_screen.dart';
import 'image_viewer_screen.dart';
import 'interactive_lab_screen.dart';
import 'quiz_screen.dart';
import 'system_lab_screen.dart';

/// 教程详情页：Markdown 正文 + 代码块 + 收藏 / 笔记 / 测验入口。
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson, this.initialAnchor});

  final Lesson lesson;

  /// 从笔记锚点进入时，直接跳到对应章节位置。
  final NoteAnchor? initialAnchor;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final Future<String> _markdownFuture;
  late final TtsService _ttsService;
  late final ProgressProvider _progress;

  /// 进入教程的时间戳，离开时换算成本次学习时长。
  late final DateTime _openedAt;
  final ScrollController _scrollController = ScrollController();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    _ttsService = const TtsService();
    // dispose() 里不能再查 Provider，提前保存引用。
    _progress = context.read<ProgressProvider>();
    final localeCode = context.read<SettingsProvider>().localeCode;
    _markdownFuture = context.read<ContentProvider>().markdownOf(
      widget.lesson,
      preferEnglish: localeCode == 'en',
    );

    // 打开教程即视为已学习，记录到本地进度。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final progress = _progress;
      progress.markLearned(widget.lesson.id);
      if (!_scrollController.hasClients) return;
      final anchor = widget.initialAnchor;
      if (anchor != null) {
        // 锚点存的是归一化位置，换设备或内容包更新后依然可用。
        _scrollController.jumpTo(
          (anchor.progress * _scrollController.position.maxScrollExtent).clamp(
            0,
            _scrollController.position.maxScrollExtent,
          ),
        );
        return;
      }
      final offset = progress.readingOffset(widget.lesson.id);
      if (offset > 0) {
        _scrollController.jumpTo(
          offset.clamp(0, _scrollController.position.maxScrollExtent),
        );
      }
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    final progress = _progress;
    // 记录本次真实阅读时长（单次上限 2 小时，由 Provider 兜底）。
    progress.addStudySeconds(
      widget.lesson.id,
      DateTime.now().difference(_openedAt).inSeconds,
    );
    if (_scrollController.hasClients) {
      progress.saveReadingOffset(widget.lesson.id, _scrollController.offset);
    }
    _scrollController.dispose();
    super.dispose();
  }

  /// 使用设备内置 TTS 朗读正文；没有完整英文正文时自动按中文朗读。
  Future<void> _toggleSpeech() async {
    if (_speaking) {
      await _ttsService.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final body = await _markdownFuture;
    if (!mounted) return;
    if (TtsService.prepareSpeechText(body).isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.trRead('ttsNoReadableText'))),
      );
      return;
    }

    final requestedLocale = context.read<SettingsProvider>().localeCode;
    final speechLocale = widget.lesson.hasEnglishBody && requestedLocale == 'en'
        ? 'en'
        : 'zh';
    final started = await _ttsService.speak(
      text: body,
      localeCode: speechLocale,
      onDone: () {
        if (mounted) setState(() => _speaking = false);
      },
    );
    if (!mounted) return;
    setState(() => _speaking = started);
    if (!started) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.trRead('ttsUnavailable'))),
      );
    }
  }

  /// 复制「标题 + 摘要 + 正文」到剪贴板。
  ///
  /// 本 App 完全离线，不加分享依赖，用剪贴板作为等价的分发手段：
  /// 粘贴到聊天工具、笔记或邮件里同样是「分享全文」。
  Future<void> _copyFullText() async {
    final messenger = ScaffoldMessenger.of(context);
    final localeCode = context.read<SettingsProvider>().localeCode;
    final copiedLabel = context.trRead('lessonCopied');
    final failedTemplate = context.trRead('copyFailed');
    try {
      final body = await _markdownFuture;
      final text =
          '${widget.lesson.title.of(localeCode)}\n\n'
          '${widget.lesson.summary.of(localeCode)}\n\n'
          '$body';
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showSnackBar(
        SnackBar(
          content: Text(copiedLabel),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(failedTemplate.replaceAll('{error}', '$error')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 教程正文里的链接：离线场景下不直接跳浏览器，改为可复制的面板。
  Future<void> _showLinkSheet(String href) async {
    final title = context.trRead('linkSheetTitle');
    final hint = context.trRead('linkHint');
    final copyLabel = context.trRead('copyLink');
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 10),
              SelectableText(
                href,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              const SizedBox(height: 10),
              Text(
                hint,
                style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(sheetContext);
                    await Clipboard.setData(ClipboardData(text: href));
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(copyLabel),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_all_outlined, size: 18),
                  label: Text(copyLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 从课程页直接进入绑定的离线实验；没有绑定入口时不显示按钮。
  Future<void> _openLab() async {
    final lab = widget.lesson.lab;
    if (lab == null) return;
    Widget? screen;
    if (lab == 'interactive') {
      screen = InteractiveLabScreen(initialMode: _interactiveMode());
    } else if (lab == 'system_network') {
      screen = const SystemLabScreen(initialMode: 0);
    } else if (lab == 'system_database') {
      screen = const SystemLabScreen(initialMode: 1);
    } else if (lab.startsWith('sandbox:')) {
      screen = CodeSandboxScreen(initialLanguageId: lab.substring(8));
    }
    if (screen == null || !mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen!));
  }

  int _interactiveMode() {
    final id = widget.lesson.id;
    if (id.contains('bubble')) return 1;
    if (id.contains('stack') || id.contains('queue')) return 2;
    if (id.contains('insertion')) return 3;
    if (id.contains('selection')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = context.watch<ProgressProvider>();
    final content = context.watch<ContentProvider>();
    final localeCode = context.strings.localeCode;
    final isFavorite = progress.isFavorite(widget.lesson.id);
    final isLearned = progress.isLearned(widget.lesson.id);
    final isBookmarked = progress.isBookmarked(widget.lesson.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title.of(localeCode)),
        actions: [
          if (widget.lesson.lab != null)
            IconButton(
              tooltip: context.tr('openLab'),
              icon: const Icon(Icons.science_outlined),
              onPressed: _openLab,
            ),
          IconButton(
            tooltip: context.tr(_speaking ? 'ttsStopReading' : 'ttsReadAloud'),
            icon: Icon(_speaking ? Icons.stop_circle : Icons.volume_up),
            onPressed: _toggleSpeech,
          ),
          IconButton(
            tooltip: context.tr('copyLesson'),
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _copyFullText,
          ),
          IconButton(
            tooltip: context.tr(
              isBookmarked ? 'bookmarkRemove' : 'bookmarkAdd',
            ),
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? theme.colorScheme.primary : null,
            ),
            onPressed: () => progress.toggleBookmark(widget.lesson.id),
          ),
          IconButton(
            tooltip: context.tr('favorites'),
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? AppPalette.warning : null,
            ),
            onPressed: () => progress.toggleFavorite(widget.lesson.id),
          ),
          IconButton(
            tooltip: context.tr('noteTitle'),
            icon: const Icon(Icons.edit_note),
            onPressed: _openNoteEditor,
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _markdownFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          final rawMarkdown = snapshot.data ?? '';
          final showEnglishFallback =
              localeCode == 'en' && !widget.lesson.hasEnglishBody;
          final renderedMarkdown = showEnglishFallback
              ? '> ${context.trArgs('lessonEnglishFallback', {'available': content.englishLessonCount, 'total': content.totalLessons})}\n\n$rawMarkdown'
              : rawMarkdown;
          final article = _buildMarkdown(context, renderedMarkdown, theme);
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < AppBreakpoints.wideReading) {
                return article;
              }
              return Row(
                key: const ValueKey('lesson-wide-layout'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 320,
                    child: _LessonOverviewPane(
                      lesson: widget.lesson,
                      isLearned: isLearned,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: article),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (widget.lesson.totalQuestionCount > 0) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => QuizScreen(lesson: widget.lesson),
                      ),
                    ),
                    icon: const Icon(Icons.quiz_outlined),
                    label: Text(context.tr('startQuiz')),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              OutlinedButton.icon(
                onPressed: () {
                  if (isLearned) {
                    progress.unmarkLearned(widget.lesson.id);
                  } else {
                    progress.markLearned(widget.lesson.id);
                  }
                },
                icon: Icon(
                  isLearned ? Icons.check_circle : Icons.check_circle_outline,
                  size: 18,
                ),
                label: Text(
                  isLearned ? context.tr('learned') : context.tr('markLearned'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkdown(BuildContext context, String data, ThemeData theme) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Markdown(
          data: data,
          controller: _scrollController,
          selectable: true,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 44),
          styleSheet: _styleSheet(theme),
          builders: {'pre': CodeBlockBuilder()},
          // 正文内的链接：离线场景下弹出可复制的面板，而不是跳浏览器。
          onTapLink: (text, href, title) {
            if (href == null || href.trim().isEmpty) return;
            _showLinkSheet(href.trim());
          },
          // 多模态配图：Markdown 里写 ![说明](images/xxx.webp) 即可渲染资产图片
          imageDirectory: 'assets/content/',
          sizedImageBuilder: (config) {
            final raw = config.uri.toString();
            final assetPath = raw.startsWith('assets/')
                ? raw
                : 'assets/content/$raw';
            void openViewer() => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ImageViewerScreen(
                  assetPath: assetPath,
                  caption: config.alt,
                ),
              ),
            );
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: AppRadii.card,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: openViewer,
                          child: Image.asset(
                            assetPath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: AppRadii.card,
                                  ),
                                  child: Text(
                                    config.alt ?? assetPath,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: context.tr('imageViewer'),
                              visualDensity: VisualDensity.compact,
                              onPressed: openViewer,
                              icon: const Icon(
                                Icons.zoom_out_map,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (config.alt != null && config.alt!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            config.alt!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.tr('imageViewer'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 针对正文调整 Markdown 排版，保证中文阅读行高舒适。
  MarkdownStyleSheet _styleSheet(ThemeData theme) {
    final scale = context.watch<SettingsProvider>().readingFontScale;
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      h1: theme.textTheme.headlineSmall?.copyWith(
        fontFamily: AppTheme.serifFamily,
        fontWeight: FontWeight.w700,
        fontSize: 24 * scale,
        height: 1.35,
      ),
      h2: theme.textTheme.titleLarge?.copyWith(
        fontFamily: AppTheme.serifFamily,
        fontWeight: FontWeight.w700,
        fontSize: 21 * scale,
        height: 1.4,
      ),
      h3: theme.textTheme.titleMedium?.copyWith(
        fontFamily: AppTheme.serifFamily,
        fontWeight: FontWeight.w700,
        fontSize: 17.5 * scale,
        height: 1.5,
      ),
      p: theme.textTheme.bodyMedium?.copyWith(
        fontFamily: AppTheme.serifFamily,
        height: 1.75,
        fontSize: 16 * scale,
      ),
      listBullet: theme.textTheme.bodyMedium?.copyWith(
        fontFamily: AppTheme.serifFamily,
        height: 1.75,
        fontSize: 16 * scale,
      ),
      code: TextStyle(
        fontFamily: AppTheme.monoFamily,
        fontSize: 13.5 * scale,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        color: theme.colorScheme.onSurface,
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: AppRadii.control,
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      tableBorder: TableBorder.all(color: theme.colorScheme.outlineVariant),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
    );
  }

  /// 当前阅读位置最接近的章节标题，用于生成笔记锚点。
  ///
  /// 教程里的标题来自 Markdown，按出现顺序等分正文高度做近似定位；
  /// 这样不用依赖具体字符偏移，内容更新后锚点依然可用。
  String _currentSectionTitle(String markdown) {
    final pattern = RegExp(r'^#{1,4}\s+');
    final headings = <String>[
      for (final line in markdown.split('\n'))
        if (pattern.hasMatch(line.trim()))
          line.trim().replaceFirst(pattern, '').trim(),
    ]..removeWhere((item) => item.isEmpty);
    if (headings.isEmpty) {
      return widget.lesson.title.of(context.strings.localeCode);
    }
    if (!_scrollController.hasClients) return headings.first;
    final max = _scrollController.position.maxScrollExtent;
    final ratio = max <= 0
        ? 0.0
        : (_scrollController.position.pixels / max).clamp(0.0, 1.0);
    final index = (ratio * headings.length).floor().clamp(
      0,
      headings.length - 1,
    );
    return headings[index];
  }

  /// 底部弹窗编辑笔记，保存到本地 Hive。
  Future<void> _openNoteEditor() async {
    final progress = context.read<ProgressProvider>();
    final savedMessage = context.tr('noteSaved');
    final existing = progress.noteOf(widget.lesson.id);
    final controller = TextEditingController(text: existing?.content ?? '');
    final tagController = TextEditingController(
      text: existing?.tags.join(', ') ?? '',
    );
    // 章节锚点与闪卡开关在弹窗内编辑，确认保存时才写回本地。
    final anchors = <NoteAnchor>[...?existing?.anchors];
    var flashcardEnabled = existing?.flashcardEnabled ?? true;
    final rawMarkdown = await _markdownFuture;
    if (!mounted) {
      controller.dispose();
      tagController.dispose();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('noteTitle'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  minLines: 4,
                  maxLines: 8,
                  autofocus: true,
                  decoration: InputDecoration(hintText: context.tr('noteHint')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagController,
                  decoration: InputDecoration(
                    labelText: context.tr('noteTagsLabel'),
                    hintText: context.tr('noteTagsHint'),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.style_outlined),
                  title: Text(context.tr('noteFlashcards')),
                  value: flashcardEnabled,
                  onChanged: (value) =>
                      setSheetState(() => flashcardEnabled = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('noteAnchors'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        final title = _currentSectionTitle(rawMarkdown);
                        final ratio =
                            _scrollController.hasClients &&
                                _scrollController.position.maxScrollExtent > 0
                            ? (_scrollController.position.pixels /
                                      _scrollController
                                          .position
                                          .maxScrollExtent)
                                  .clamp(0.0, 1.0)
                            : 0.0;
                        setSheetState(() {
                          anchors.add(
                            NoteAnchor(
                              title: title,
                              progress: ratio,
                              createdAt: DateTime.now(),
                            ),
                          );
                        });
                      },
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      label: Text(context.tr('noteAnchorAdd')),
                    ),
                  ],
                ),
                if (anchors.isEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.tr('noteAnchorEmpty'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final anchor in anchors)
                        InputChip(
                          label: Text(anchor.title),
                          onDeleted: () =>
                              setSheetState(() => anchors.remove(anchor)),
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(context.tr('cancel')),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final navigator = Navigator.of(sheetContext);
                        final messenger = ScaffoldMessenger.of(context);
                        await progress.saveNote(
                          widget.lesson.id,
                          controller.text,
                          tags: tagController.text
                              .split(RegExp(r'[,，、]'))
                              .toList(),
                          anchors: anchors,
                          flashcardEnabled: flashcardEnabled,
                        );
                        if (!sheetContext.mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(savedMessage),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Text(context.tr('save')),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    controller.dispose();
    tagController.dispose();
  }
}

/// 平板 / 横屏教程页左栏：稳定的课程概览，不挤占正文阅读宽度。
class _LessonOverviewPane extends StatelessWidget {
  const _LessonOverviewPane({required this.lesson, required this.isLearned});

  final Lesson lesson;
  final bool isLearned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.strings.localeCode;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Chip(
          avatar: Icon(
            isLearned ? Icons.check_circle : Icons.school_outlined,
            size: 18,
          ),
          label: Text(context.difficultyLabel(lesson.difficulty)),
        ),
        const SizedBox(height: 14),
        Text(
          lesson.title.of(locale),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          lesson.summary.of(locale),
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (lesson.prerequisites.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            context.tr('prerequisites'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _LessonLinkChips(ids: lesson.prerequisites),
        ],
        if (lesson.related.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            context.tr('relatedLessons'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _LessonLinkChips(ids: lesson.related),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.schedule, size: 17),
              label: Text('${lesson.minutes} ${context.tr('minutes')}'),
            ),
            Chip(
              avatar: const Icon(Icons.quiz_outlined, size: 17),
              label: Text(
                '${lesson.totalQuestionCount} ${context.tr('navQuiz')}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          context.tr('overallProgress'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: isLearned ? 1 : 0, minHeight: 6),
        const SizedBox(height: 20),
        Text(
          lesson.keywords.take(10).join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 先修与后续课程的跳转标签；找不到 ID 时静默跳过，避免脏数据崩溃。
class _LessonLinkChips extends StatelessWidget {
  const _LessonLinkChips({required this.ids});

  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final locale = context.strings.localeCode;
    final lessons = ids
        .map(content.lessonById)
        .whereType<Lesson>()
        .take(5)
        .toList();
    if (lessons.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final lesson in lessons)
          ActionChip(
            label: Text(
              lesson.title.of(locale),
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LessonScreen(lesson: lesson),
              ),
            ),
          ),
      ],
    );
  }
}
