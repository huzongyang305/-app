import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/storage_diagnostic.dart';
import '../services/content_provider.dart';
import '../services/storage_diagnostics_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// 本地存储诊断：查看各类数据占用，并安全清理可重建缓存与孤立记录。
///
/// 清理只涉及缓存和已经失去课程引用的记录，用户笔记、进度与成绩不会被删除。
class StorageDiagnosticsScreen extends StatefulWidget {
  const StorageDiagnosticsScreen({super.key});

  @override
  State<StorageDiagnosticsScreen> createState() =>
      _StorageDiagnosticsScreenState();
}

class _StorageDiagnosticsScreenState extends State<StorageDiagnosticsScreen> {
  StorageDiagnostic? _diagnostic;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _diagnostic ??= _analyze();
  }

  StorageDiagnostic _analyze() {
    final storage = context.read<StorageService>();
    final content = context.read<ContentProvider>();
    return StorageDiagnosticsService(
      storage,
    ).analyze(lessonIds: content.allLessons.map((lesson) => lesson.id).toSet());
  }

  Future<void> _cleanup({required bool removeOrphans}) async {
    final storage = context.read<StorageService>();
    final content = context.read<ContentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final emptyMessage = context.tr('storageNothingToClean');
    final removed = await StorageDiagnosticsService(storage).cleanup(
      lessonIds: content.allLessons.map((lesson) => lesson.id).toSet(),
      removeOrphans: removeOrphans,
    );
    if (!mounted) return;
    setState(() => _diagnostic = _analyze());
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          removed == 0
              ? emptyMessage
              : context.trArgs('storageCleaned', {'n': removed}),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diagnostic = _diagnostic;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('storageTitle'))),
      body: diagnostic == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              children: [
                Text(
                  context.tr('storageHint'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Column(
                    children: [
                      _StatTile(
                        icon: Icons.key_outlined,
                        label: context.tr('storageKeys'),
                        value: '${diagnostic.keyCount}',
                      ),
                      const Divider(height: 1),
                      _StatTile(
                        icon: Icons.sd_storage_outlined,
                        label: context.tr('storageEstimatedSize'),
                        value:
                            '${diagnostic.estimatedMiB.toStringAsFixed(3)} MiB',
                      ),
                      const Divider(height: 1),
                      _StatTile(
                        icon: Icons.report_gmailerrorred_outlined,
                        label: context.tr('storageOrphans'),
                        value: '${diagnostic.orphanKeys.length}',
                      ),
                      const Divider(height: 1),
                      _StatTile(
                        icon: Icons.cleaning_services_outlined,
                        label: context.tr('storageCaches'),
                        value: '${diagnostic.cacheKeys.length}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.tr('categories'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  child: Column(
                    children: [
                      for (final entry in diagnostic.categories.entries)
                        ListTile(
                          dense: true,
                          title: Text(entry.key),
                          trailing: Text('${entry.value}'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: diagnostic.cacheKeys.isEmpty
                            ? null
                            : () => _cleanup(removeOrphans: false),
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: Text(context.tr('storageCleanCaches')),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: diagnostic.orphanKeys.isEmpty
                            ? null
                            : () => _cleanup(removeOrphans: true),
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: Text(context.tr('storageCleanOrphans')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      trailing: Text(
        value,
        style: theme.textTheme.titleSmall?.copyWith(
          fontFamily: AppTheme.monoFamily,
        ),
      ),
    );
  }
}
