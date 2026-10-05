import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/note.dart';
import '../services/content_provider.dart';
import '../services/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'lesson_screen.dart';

/// 我的笔记：跨课程检索、标签筛选、Markdown 预览与一键导出。
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _tag;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final content = context.watch<ContentProvider>();
    final notes = progress.searchNotes(_query, tag: _tag);
    final tags = progress.allNoteTags;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notesTitle')),
        actions: [
          IconButton(
            tooltip: context.tr('notesExport'),
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: notes.isEmpty ? null : () => _export(notes, content),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: context.tr('notesSearchHint'),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: context.tr('searchClear'),
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          if (tags.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(context.tr('notesAllTags')),
                      selected: _tag == null,
                      onSelected: (_) => setState(() => _tag = null),
                    ),
                  ),
                  for (final tag in tags)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(tag),
                        selected: _tag == tag,
                        onSelected: (_) => setState(() => _tag = tag),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: notes.isEmpty
                ? EmptyState(
                    icon: Icons.sticky_note_2_outlined,
                    message: context.tr('notesEmpty'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: notes.length,
                    itemBuilder: (context, index) => _NoteCard(
                      note: notes[index],
                      lessonTitle: _lessonTitle(content, notes[index]),
                      onEdit: () => _edit(notes[index]),
                      onDelete: () => _delete(notes[index]),
                      onOpenLesson: () => _openLesson(content, notes[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _lessonTitle(ContentProvider content, Note note) {
    final lesson = content.lessonById(note.lessonId);
    return lesson?.title.of(context.strings.localeCode) ?? note.lessonId;
  }

  void _openLesson(ContentProvider content, Note note) {
    final lesson = content.lessonById(note.lessonId);
    if (lesson == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson)),
    );
  }

  Future<void> _delete(Note note) async {
    final progress = context.read<ProgressProvider>();
    await progress.saveNote(note.lessonId, '');
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.trRead('notesDeleted'))));
  }

  Future<void> _edit(Note note) async {
    final progress = context.read<ProgressProvider>();
    final contentController = TextEditingController(text: note.content);
    final tagController = TextEditingController(text: note.tags.join(', '));
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
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
              context.tr('notesEdit'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              minLines: 4,
              maxLines: 12,
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
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await progress.saveNote(
                  note.lessonId,
                  contentController.text,
                  tags: tagController.text.split(RegExp(r'[,，、]')).toList(),
                );
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop(true);
              },
              child: Text(context.tr('noteSave')),
            ),
          ],
        ),
      ),
    );
    contentController.dispose();
    tagController.dispose();
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.trRead('noteSaved'))));
    }
  }

  /// 导出为 Markdown 文本并复制到剪贴板，用户可自行粘贴到任意笔记应用。
  Future<void> _export(List<Note> notes, ContentProvider content) async {
    final buffer = StringBuffer()..writeln('# 我的学习笔记\n');
    for (final note in notes) {
      buffer.writeln('## ${_lessonTitle(content, note)}');
      if (note.tags.isNotEmpty) {
        buffer.writeln('标签：${note.tags.map((tag) => '#$tag').join(' ')}');
      }
      buffer.writeln('更新时间：${formatNoteTime(note.updatedAt)}\n');
      buffer.writeln('${note.content}\n');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.trArgs('notesExportDone', {'n': notes.length})),
      ),
    );
  }
}

/// 稳定的本地时间格式（不引入 intl 依赖）。
String formatNoteTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)} '
      '${two(time.hour)}:${two(time.minute)}';
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.lessonTitle,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenLesson,
  });

  final Note note;
  final String lessonTitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpenLesson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              lessonTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(formatNoteTime(note.updatedAt)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: context.tr('notesEdit'),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: context.tr('notesDelete'),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
            onTap: onOpenLesson,
          ),
          if (note.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in note.tags)
                    Chip(
                      label: Text(tag, style: theme.textTheme.labelSmall),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: MarkdownBody(
              data: note.content,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(theme)
                  .copyWith(p: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
