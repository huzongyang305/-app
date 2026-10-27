import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/global_search.dart';
import '../models/lesson_category.dart';
import '../models/sandbox_language.dart';
import '../models/search_hit.dart';
import '../services/content_provider.dart';
import '../services/global_search_service.dart';
import '../services/progress_provider.dart';
import '../services/settings_provider.dart';
import '../services/snippet_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'code_sandbox_screen.dart';
import 'flashcard_screen.dart';
import 'lesson_screen.dart';
import 'quiz_screen.dart';

enum _SearchFilter { all, unlearned, favorites, wrong }

class _Suggestion {
  const _Suggestion({required this.title, required this.subtitle, required this.lessonId});
  final String title;
  final String subtitle;
  final String lessonId;
}

/// 搜索页：倒排索引检索 + 拼音/首字母 + 学习状态与分类筛选。
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.categoryId,
    required this.categories,
    required this.onFilterChanged,
    required this.onCategoryChanged,
  });

  final _SearchFilter filter;
  final String? categoryId;
  final List<LessonCategory> categories;
  final ValueChanged<_SearchFilter> onFilterChanged;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    var selectedCategory = context.tr('searchAllCategories');
    if (categoryId != null) {
      for (final category in categories) {
        if (category.id == categoryId) {
          selectedCategory = category.title.of(context.strings.localeCode);
          break;
        }
      }
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        children: [
          for (final item in _SearchFilter.values) ...[
            ChoiceChip(
              selected: filter == item,
              label: Text(_label(context, item)),
              onSelected: (_) => onFilterChanged(item),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          PopupMenuButton<String>(
            tooltip: context.tr('searchCategoryFilter'),
            initialValue: categoryId ?? '',
            onSelected: (value) =>
                onCategoryChanged(value.isEmpty ? null : value),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: '',
                child: Text(context.tr('searchAllCategories')),
              ),
              for (final category in categories)
                PopupMenuItem<String>(
                  value: category.id,
                  child: Text(category.title.of(context.strings.localeCode)),
                ),
            ],
            child: Chip(
              avatar: const Icon(Icons.tune, size: 16),
              label: Text(selectedCategory),
            ),
          ),
        ],
      ),
    );
  }

  String _label(BuildContext context, _SearchFilter filter) {
    switch (filter) {
      case _SearchFilter.all:
        return context.tr('searchFilterAll');
      case _SearchFilter.unlearned:
        return context.tr('searchFilterUnlearned');
      case _SearchFilter.favorites:
        return context.tr('searchFilterFavorites');
      case _SearchFilter.wrong:
        return context.tr('searchFilterWrong');
    }
  }
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  GlobalSearchResults _results = GlobalSearchResults.empty;
  List<_Suggestion> _suggestions = const [];
  bool _hasSearched = false;
  bool _isSearching = false;
  String? _categoryId;
  _SearchFilter _filter = _SearchFilter.all;
  StorageService? _storage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storage ??= _storageOrFallback(context);
  }

  /// 统一搜索要读片段库；个别测试未注入存储时退化为空的内存库。
  StorageService _storageOrFallback(BuildContext context) {
    try {
      return context.read<StorageService>();
    } on ProviderNotFoundException {
      return StorageService.inMemory();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// 输入停顿 260ms 再查询，避免每次按键都触发全文搜索。
  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    setState(() {
      if (query.isEmpty) {
        _results = GlobalSearchResults.empty;
        _suggestions = const [];
        _hasSearched = false;
        _isSearching = false;
      } else {
        _updateSuggestions(query);
      }
    });
    if (query.isEmpty) return;

    _debounce = Timer(const Duration(milliseconds: 260), () => _search(query));
  }

  /// 生成实时建议：匹配课程标题，最多显示5条
  void _updateSuggestions(String query) {
    if (query.length < 2) {
      _suggestions = const [];
      return;
    }
    final content = context.read<ContentProvider>();
    final localeCode = context.localeCodeRead;
    final lowerQuery = query.toLowerCase();
    final suggestions = <_Suggestion>[];
    
    for (final lesson in content.allLessons) {
      final title = lesson.title.of(localeCode);
      if (title.toLowerCase().contains(lowerQuery)) {
        final category = content.categories.firstWhere(
          (c) => c.lessons.any((l) => l.id == lesson.id),
          orElse: () => content.categories.first,
        );
        suggestions.add(_Suggestion(
          title: title,
          subtitle: category.title.of(localeCode),
          lessonId: lesson.id,
        ));
        if (suggestions.length >= 5) break;
      }
    }
    _suggestions = suggestions;
  }

  Future<void> _search(String query) async {
    final content = context.read<ContentProvider>();
    final progress = context.read<ProgressProvider>();
    // 片段库每次查询重建，保证从沙箱保存的新片段能被立刻搜到。
    final service = GlobalSearchService(
      content: content,
      progress: progress,
      snippets: SnippetService(_storage ?? StorageService.inMemory()),
    );
    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }
    final results = await service.search(
      query,
      categoryId: _categoryId,
      lessonIds: _lessonScope(progress, content),
    );
    if (!mounted || _controller.text.trim() != query) return;
    setState(() {
      _results = results;
      _hasSearched = true;
      _isSearching = false;
    });
  }

  Set<String>? _lessonScope(
    ProgressProvider progress,
    ContentProvider content,
  ) {
    switch (_filter) {
      case _SearchFilter.all:
        return null;
      case _SearchFilter.favorites:
        return progress.favoriteIds;
      case _SearchFilter.unlearned:
        return content.allLessons
            .map((lesson) => lesson.id)
            .where((id) => !progress.isLearned(id))
            .toSet();
      case _SearchFilter.wrong:
        return progress.wrongQuestionKeys
            .map((key) => key.split('#').first)
            .toSet();
    }
  }

  void _setFilter(_SearchFilter value) {
    if (_filter == value) return;
    setState(() => _filter = value);
    final query = _controller.text.trim();
    if (query.isNotEmpty) _search(query);
  }

  void _setCategory(String? value) {
    if (_categoryId == value) return;
    setState(() => _categoryId = value);
    final query = _controller.text.trim();
    if (query.isNotEmpty) _search(query);
  }

  void _useHistory(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    _search(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = context.watch<ProgressProvider>();
    final settings = context.watch<SettingsProvider>();
    final content = context.watch<ContentProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('search'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (value) {
                final query = value.trim();
                if (query.isEmpty) return;
                context.read<SettingsProvider>().rememberSearch(query);
                _search(query);
              },
              decoration: InputDecoration(
                hintText: context.tr('searchHint'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: context.tr('clear'),
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      ),
              ),
            ),
          ),
          if (_suggestions.isNotEmpty && !_hasSearched)
            _SuggestionsList(
              suggestions: _suggestions,
              onSelected: (lessonId) {
                final content = context.read<ContentProvider>();
                final lesson = content.allLessons.firstWhere((l) => l.id == lessonId);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson)),
                );
              },
            ),
          _FilterBar(
            filter: _filter,
            categoryId: _categoryId,
            categories: content.categories,
            onFilterChanged: _setFilter,
            onCategoryChanged: _setCategory,
          ),
          Expanded(
            child: _buildResults(
              context: context,
              theme: theme,
              progress: progress,
              history: settings.searchHistory,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults({
    required BuildContext context,
    required ThemeData theme,
    required ProgressProvider progress,
    required List<String> history,
  }) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            Text(context.tr('searchIndexing')),
          ],
        ),
      );
    }
    if (!_hasSearched) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        children: [
          if (history.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('searchHistory'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: context
                      .read<SettingsProvider>()
                      .clearSearchHistory,
                  child: Text(context.tr('clearHistory')),
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final query in history)
                  ActionChip(
                    avatar: const Icon(Icons.history, size: 16),
                    label: Text(query),
                    onPressed: () => _useHistory(query),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          EmptyState(
            icon: Icons.manage_search,
            message: context.tr('searchTip'),
            action: Text(
              context.tr('searchPinyinHint'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      );
    }
    if (_results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        message: context.tr('searchEmpty'),
      );
    }
    final localeCode = context.strings.localeCode;
    final sections = <Widget>[];
    void addSection(String titleKey, int count, List<Widget> cards) {
      if (cards.isEmpty) return;
      sections.add(
        _ResultSectionHeader(title: context.tr(titleKey), count: count),
      );
      for (final card in cards) {
        sections.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: card,
          ),
        );
      }
    }

    addSection('searchGroupLessons', _results.lessons.length, [
      for (final hit in _results.lessons)
        _buildLessonCard(context, theme, progress, hit),
    ]);
    addSection('searchGroupNotes', _results.notes.length, [
      for (final hit in _results.notes)
        _buildSimpleCard(
          context,
          theme,
          icon: Icons.edit_note,
          title: _HighlightedText(
            text: hit.lesson.title.of(localeCode),
            terms: hit.matchedTerms,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          meta:
              '${hit.category.title.of(localeCode)} · '
              '${context.tr('searchGroupNotes')}',
          snippet: hit.snippet,
          terms: hit.matchedTerms,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LessonScreen(
                lesson: hit.lesson,
                initialAnchor: hit.note.anchors.isEmpty
                    ? null
                    : hit.note.anchors.first,
              ),
            ),
          ),
        ),
    ]);
    addSection('searchGroupWrong', _results.wrongQuestions.length, [
      for (final hit in _results.wrongQuestions)
        _buildSimpleCard(
          context,
          theme,
          icon: Icons.rule,
          title: _HighlightedText(
            text: 'Q${hit.questionIndex + 1} · ${hit.lesson.title.of(localeCode)}',
            terms: hit.matchedTerms,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          meta:
              '${hit.category.title.of(localeCode)} · '
              '${context.trArgs('analyticsWrongTimes', {'n': hit.wrongCount})}',
          snippet: hit.snippet,
          terms: hit.matchedTerms,
          onTap: () => _showWrongQuestion(hit),
        ),
    ]);
    addSection('searchGroupTerms', _results.terms.length, [
      for (final hit in _results.terms)
        _buildSimpleCard(
          context,
          theme,
          icon: Icons.menu_book_outlined,
          title: _HighlightedText(
            text: hit.term,
            terms: hit.matchedTerms,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          meta:
              '${hit.category.title.of(localeCode)} · '
              '${hit.lesson.title.of(localeCode)}',
          snippet: hit.explanation,
          terms: hit.matchedTerms,
          onTap: () => _showTerm(hit),
        ),
    ]);
    addSection('searchGroupSnippets', _results.snippets.length, [
      for (final hit in _results.snippets)
        _buildSimpleCard(
          context,
          theme,
          icon: Icons.code,
          title: _HighlightedText(
            text: hit.snippet.title,
            terms: hit.matchedTerms,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          meta:
              '${_languageLabel(context, hit.snippet.languageId)} · '
              '${context.tr('searchGroupSnippets')}',
          snippet: hit.excerpt,
          terms: hit.matchedTerms,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CodeSandboxScreen(
                initialCode: hit.snippet.code,
                initialLanguageId: hit.snippet.languageId,
                initialStdin: hit.snippet.stdin,
              ),
            ),
          ),
        ),
    ]);
    addSection('searchGroupChallenges', _results.challenges.length, [
      for (final hit in _results.challenges)
        _buildSimpleCard(
          context,
          theme,
          icon: Icons.flag_outlined,
          title: _HighlightedText(
            text: hit.challenge.title.of(localeCode),
            terms: hit.matchedTerms,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          meta:
              '${_languageLabel(context, hit.language.id)} · '
              '${context.tr('searchGroupChallenges')}',
          snippet: hit.challenge.prompt.of(localeCode),
          terms: hit.matchedTerms,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CodeSandboxScreen(
                initialLanguageId: hit.language.id,
                initialChallengeId: hit.challenge.id,
              ),
            ),
          ),
        ),
    ]);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      children: sections,
    );
  }

  Widget _buildLessonCard(
    BuildContext context,
    ThemeData theme,
    ProgressProvider progress,
    SearchHit hit,
  ) {
    final localeCode = context.strings.localeCode;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LessonScreen(lesson: hit.lesson),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _HighlightedText(
                      text: hit.lesson.title.of(localeCode),
                      terms: hit.matchedTerms,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (progress.isLearned(hit.lesson.id))
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  Text(
                    hit.category.title.of(localeCode),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    context.difficultyLabel(hit.lesson.difficulty),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _HighlightedText(
                text: hit.snippet,
                terms: hit.matchedTerms,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required Widget title,
    required String meta,
    required String snippet,
    required List<String> terms,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      icon,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: title),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                meta,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              if (snippet.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _HighlightedText(
                  text: snippet,
                  terms: terms,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  maxLines: 3,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _languageLabel(BuildContext context, String languageId) {
    for (final language in SandboxLanguage.values) {
      if (language.id == languageId) return context.tr(language.labelKey);
    }
    return languageId;
  }

  Future<void> _showWrongQuestion(WrongQuestionHit hit) async {
    final localeCode = context.localeCodeRead;
    final correctIndexes = hit.question.answerIndexes.isNotEmpty
        ? hit.question.answerIndexes.toSet()
        : (hit.question.answerIndex >= 0
              ? <int>{hit.question.answerIndex}
              : <int>{});
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${hit.questionIndex + 1} · '
                    '${hit.lesson.title.of(localeCode)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${hit.category.title.of(localeCode)} · '
                    '${sheetContext.trArgs('analyticsWrongTimes', {'n': hit.wrongCount})}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    hit.question.question,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  if (hit.question.code != null &&
                      hit.question.code!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        hit.question.code!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  if (hit.question.options.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    for (
                      var index = 0;
                      index < hit.question.options.length;
                      index++
                    )
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              correctIndexes.contains(index)
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color: correctIndexes.contains(index)
                                  ? AppPalette.success
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                hit.question.options[index],
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.4,
                                  color: correctIndexes.contains(index)
                                      ? AppPalette.success
                                      : null,
                                  fontWeight: correctIndexes.contains(index)
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else if (hit.question.acceptedAnswers.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${sheetContext.tr('searchWrongCorrect')}: '
                      '${hit.question.acceptedAnswers.join(' / ')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (hit.question.explanation.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      sheetContext.tr('explanation'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hit.question.explanation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(sheetContext.tr('close')),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => QuizScreen(lesson: hit.lesson),
                            ),
                          );
                        },
                        child: Text(sheetContext.tr('searchRetryLesson')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTerm(TermHit hit) async {
    final localeCode = context.localeCodeRead;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hit.term,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${hit.category.title.of(localeCode)} · '
                    '${hit.lesson.title.of(localeCode)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    hit.explanation,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                FlashcardScreen(lessonId: hit.lesson.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.style_outlined, size: 18),
                      label: Text(sheetContext.tr('searchFlashcardAction')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResultSectionHeader extends StatelessWidget {
  const _ResultSectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.terms,
    this.style,
    this.maxLines,
  });

  final String text;
  final List<String> terms;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final validTerms = terms.where((term) => term.length >= 2).toList();
    if (validTerms.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
      );
    }
    final pattern = validTerms.map(RegExp.escape).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final expression = RegExp(pattern.join('|'), caseSensitive: false);
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in expression.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
            backgroundColor: Theme.of(context).colorScheme.primary
                .withValues(alpha: 0.08),
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({required this.suggestions, required this.onSelected});

  final List<_Suggestion> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Material(
        color: theme.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: suggestions.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return ListTile(
                dense: true,
                leading: Icon(
                  Icons.article_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  suggestion.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  suggestion.subtitle,
                  style: theme.textTheme.bodySmall,
                ),
                trailing: Icon(
                  Icons.north_east,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () => onSelected(suggestion.lessonId),
              );
            },
          ),
        ),
      ),
    );
  }
}
