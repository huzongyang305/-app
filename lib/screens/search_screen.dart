import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson_category.dart';
import '../models/search_hit.dart';
import '../services/content_provider.dart';
import '../services/progress_provider.dart';
import '../services/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'lesson_screen.dart';

enum _SearchFilter { all, unlearned, favorites, wrong }

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

  List<SearchHit> _hits = const [];
  bool _hasSearched = false;
  bool _isSearching = false;
  String? _categoryId;
  _SearchFilter _filter = _SearchFilter.all;

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
        _hits = const [];
        _hasSearched = false;
        _isSearching = false;
      }
    });
    if (query.isEmpty) return;

    _debounce = Timer(const Duration(milliseconds: 260), () => _search(query));
  }

  Future<void> _search(String query) async {
    final content = context.read<ContentProvider>();
    final progress = context.read<ProgressProvider>();
    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }
    final results = await content.search(
      query,
      categoryId: _categoryId,
      lessonIds: _lessonScope(progress, content),
    );
    if (!mounted || _controller.text.trim() != query) return;
    setState(() {
      _hits = results;
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
    if (_hits.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        message: context.tr('searchEmpty'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      itemCount: _hits.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final hit = _hits[index];
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
                          text: hit.lesson.title.of(context.strings.localeCode),
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
                        hit.category.title.of(context.strings.localeCode),
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
      },
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
