import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../l10n/l10n_extension.dart';
import '../models/achievement.dart';
import '../services/backup_crypto_service.dart';
import '../services/backup_document_service.dart';
import '../services/backup_file_service.dart';
import '../services/content_provider.dart';
import '../services/notification_service.dart';
import '../services/offline_content_pack_service.dart';
import '../services/progress_provider.dart';
import '../services/settings_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/lesson_card.dart';
import 'analytics_screen.dart';
import 'lesson_screen.dart';
import 'quiz_screen.dart';
import 'achievements_screen.dart';
import 'notes_screen.dart';

/// 我的：学习统计、收藏、笔记与设置。
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// 导出学习数据到用户通过系统“另存为”选择的位置。
  ///
  /// 密码留空时保持旧版明文 JSON 格式；输入密码后使用 Android 原生
  /// AES-256-GCM 加密，旧版本导出的文件仍可继续导入。
  Future<void> _exportData(
    BuildContext context,
    ProgressProvider progress,
  ) async {
    final password = await _askBackupPassword(
      context,
      titleKey: 'profileExportEncrypted',
      confirmKey: 'save',
      allowEmpty: true,
    );
    if (password == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final strings = AppStrings(context.read<SettingsProvider>().localeCode);
    try {
      final payload = await _buildBackupPayload(progress, password);
      final saved = await const BackupFileService().saveBackup(
        payload: payload,
        suggestedName: _backupFileName(),
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.trRead(
              saved ? 'profileBackupSaved' : 'profileBackupCancelled',
            ),
          ),
        ),
      );
    } on BackupFileException catch (error) {
      if (error.code == 'backup_file_picker_unavailable') {
        await _exportLegacyFile(
          context,
          progress,
          password,
          messenger,
          strings,
        );
        return;
      }
      _showBackupError(context, messenger, strings, error);
    } catch (error) {
      if (!context.mounted) return;
      _showBackupError(context, messenger, strings, error);
    }
  }

  /// 通过系统分享面板发送备份文件。
  Future<void> _shareData(
    BuildContext context,
    ProgressProvider progress,
  ) async {
    final password = await _askBackupPassword(
      context,
      titleKey: 'profileExportEncrypted',
      confirmKey: 'profileShare',
      allowEmpty: true,
    );
    if (password == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppStrings(context.read<SettingsProvider>().localeCode);
    try {
      final payload = await _buildBackupPayload(progress, password);
      final shared = await const BackupFileService().shareBackup(
        payload: payload,
        suggestedName: _backupFileName(),
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.trRead(
              shared ? 'profileShareStarted' : 'profileShareCancelled',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showBackupError(context, messenger, strings, error);
    }
  }

  /// 从备份文件恢复学习数据。
  ///
  /// [preferLegacy] 为 true 时跳过系统文件选择器，直接读取旧版本写入
  /// 应用文档目录的 `code_learn_backup.json`，供升级用户找回历史备份。
  Future<void> _importData(
    BuildContext context,
    ProgressProvider progress, {
    bool preferLegacy = false,
  }) async {
    final restored = context.trRead('profileRestored');
    final failedTemplate = context.trRead('profileRestoreFailed');
    final strings = AppStrings(context.read<SettingsProvider>().localeCode);
    final messenger = ScaffoldMessenger.of(context);
    try {
      String? raw;
      if (preferLegacy) {
        raw = await _readLegacyBackup();
        if (raw == null) {
          if (context.mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text(context.trRead('profileLegacyMissing'))),
            );
          }
          return;
        }
      } else {
        try {
          raw = await const BackupFileService().openBackup();
        } on BackupFileException catch (error) {
          if (error.code != 'backup_file_picker_unavailable') rethrow;
          raw = await _readLegacyBackup();
        }
      }
      if (raw == null) {
        if (context.mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(context.trRead('profileOpenCancelled'))),
          );
        }
        return;
      }
      if (!context.mounted) return;
      final crypto = const BackupCryptoService();
      Map<String, dynamic> data;
      if (crypto.isEncrypted(raw)) {
        final password = await _askBackupPassword(
          context,
          titleKey: 'profileImportEncrypted',
          confirmKey: 'importData',
          allowEmpty: false,
        );
        if (password == null || !context.mounted) return;
        data = await crypto.decryptJson(raw, password);
      } else {
        final decoded = jsonDecode(raw);
        data = (decoded as Map).cast<String, dynamic>();
      }
      await progress.importData(data);
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(restored)));
      }
    } catch (error) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              failedTemplate.replaceAll(
                '{error}',
                _backupErrorText(error, strings),
              ),
            ),
          ),
        );
      }
    }
  }

  Future<String> _buildBackupPayload(
    ProgressProvider progress,
    String password,
  ) async {
    final data = progress.exportData();
    return password.isEmpty
        ? jsonEncode(data)
        : await const BackupCryptoService().encryptJson(data, password);
  }

  String _backupFileName() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'code_learn_backup_${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}.json';
  }

  /// 非 Android 平台保留旧版“写入应用文档目录”的降级路径。
  Future<void> _exportLegacyFile(
    BuildContext context,
    ProgressProvider progress,
    String password,
    ScaffoldMessengerState messenger,
    AppStrings strings,
  ) async {
    try {
      final payload = await _buildBackupPayload(progress, password);
      final file = await const LegacyBackupStore().write(payload);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.trRead('profileExported').replaceAll('{path}', file.path),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showBackupError(context, messenger, strings, error);
    }
  }

  Future<String?> _readLegacyBackup() async {
    return const LegacyBackupStore().readIfExists();
  }

  void _showBackupError(
    BuildContext context,
    ScaffoldMessengerState messenger,
    AppStrings strings,
    Object error,
  ) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          context
              .trRead('profileExportFailed')
              .replaceAll('{error}', _backupErrorText(error, strings)),
        ),
      ),
    );
  }

  /// 导入可选 JSON 内容包；内容全部落在本机，不经过网络。
  Future<void> _importOfflinePack(
    BuildContext context,
    ContentProvider content,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await content.importOfflinePack();
      if (!context.mounted) return;
      if (result == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.trRead('offlinePackCancelled'))),
        );
        return;
      }
      var message = switch (result.status) {
        ContentPackUpdateStatus.imported => context.trRead(
          'offlinePackImported',
        ),
        ContentPackUpdateStatus.updated => context.trArgs('offlinePackNewer', {
          'version': result.info.version,
        }),
        ContentPackUpdateStatus.sameVersion => context.trArgs(
          'offlinePackSameVersion',
          {'version': result.info.version},
        ),
        ContentPackUpdateStatus.downgraded => context.trArgs(
          'offlinePackOlder',
          {'version': result.info.version},
        ),
      };
      if (result.delta) {
        message =
            '$message\n'
            '${context.trArgs('offlinePackDeltaApplied', {'added': result.addedLessons, 'updated': result.updatedLessons, 'removed': result.removedLessons})}';
      }
      if (result.signatureVerified) {
        message = '$message · ${context.trRead('offlinePackVerified')}';
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      final message = switch (error) {
        ContentPackException(message: 'checksum_failed') => context.trRead(
          'offlinePackChecksumFailed',
        ),
        ContentPackException(message: 'signature_failed') => context.trRead(
          'offlinePackSignatureFailed',
        ),
        _ =>
          context.trRead('offlinePackInvalid').replaceAll('{error}', '$error'),
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _removeOfflinePack(
    BuildContext context,
    ContentProvider content,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('offlinePackRemove')),
        content: Text(dialogContext.tr('offlinePackRemoveConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.tr('confirmAction')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await content.removeOfflinePack();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.trRead('offlinePackRemoved'))),
    );
  }

  /// 内容包管理面板：版本、校验和、更新记录与操作入口。
  Future<void> _showOfflinePackManager(
    BuildContext context,
    ContentProvider content,
  ) async {
    final history = content.offlinePackHistory;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              sheetContext.tr('offlinePackManage'),
              style: Theme.of(sheetContext).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(sheetContext.tr('offlinePackHint')),
            const SizedBox(height: 16),
            if (content.offlinePackInfo == null)
              Text(
                sheetContext.tr('offlinePackNone'),
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              )
            else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(content.offlinePackInfo!.name),
                subtitle: Text(
                  '${sheetContext.trArgs('offlinePackVersion', {'version': content.offlinePackInfo!.version})} · '
                  '${sheetContext.trArgs('offlinePackLessons', {'count': content.offlinePackInfo!.lessonCount})}',
                ),
              ),
              if (content.offlinePackChecksum != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(sheetContext.tr('offlinePackVerified')),
                  subtitle: Text(
                    sheetContext.trArgs('offlinePackChecksum', {
                      'value': content.offlinePackChecksum!.substring(0, 12),
                    }),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Text(
              sheetContext.tr('offlinePackHistory'),
              style: Theme.of(sheetContext).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(sheetContext.tr('offlinePackNoHistory')),
              )
            else
              for (final entry in history)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    entry.delta
                        ? Icons.call_merge_outlined
                        : Icons.download_done_outlined,
                    size: 20,
                  ),
                  title: Text(entry.version),
                  subtitle: Text(
                    '${_formatPackTime(entry.importedAt)} · '
                    '+${entry.added} / ~${entry.updated} / -${entry.removed}',
                  ),
                ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _importOfflinePack(context, content);
              },
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(sheetContext.tr('offlinePackImport')),
            ),
            if (content.offlinePackInfo != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _removeOfflinePack(context, content);
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(sheetContext.tr('offlinePackRemove')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatPackTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  Future<String?> _askBackupPassword(
    BuildContext context, {
    required String titleKey,
    required String confirmKey,
    required bool allowEmpty,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _BackupPasswordDialog(
        titleKey: titleKey,
        confirmKey: confirmKey,
        allowEmpty: allowEmpty,
      ),
    );
  }

  String _backupErrorText(Object error, AppStrings strings) {
    if (error is BackupFileException) {
      switch (error.code) {
        case 'backup_file_picker_unavailable':
        case 'backup_share_unavailable':
          return strings.get('backupFileUnavailable');
        case 'backup_too_large':
          return strings.get('backupTooLarge');
        default:
          return strings.get('backupFileFailed');
      }
    }
    if (error is BackupDocumentException) {
      if (error.code.startsWith('backup_version_unsupported')) {
        return strings.get('backupVersionUnsupported');
      }
      return strings.get('backupInvalidFormat');
    }
    if (error is BackupCryptoException) {
      switch (error.message) {
        case 'backup_crypto_unavailable':
          return strings.get('backupCryptoUnavailable');
        case 'backup_password_required':
          return strings.get('profilePasswordRequired');
        case 'backup_encrypt_failed':
          return strings.get('backupEncryptFailed');
        case 'backup_invalid_format':
          return strings.get('backupInvalidFormat');
        case 'backup_decrypt_failed':
          return strings.get('backupDecryptFailed');
        default:
          return strings.get('backupDecryptFailed');
      }
    }
    if (error is FormatException) {
      return strings.get('backupInvalidFormat');
    }
    return '$error';
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final compactControls = MediaQuery.sizeOf(context).width < 420;

    final total = content.totalLessons;
    final learned = progress.learnedIds.length;
    final ratio = progress.learnedRatio(total);

    final favoriteLessons = content.allLessons
        .where((lesson) => progress.isFavorite(lesson.id))
        .toList();
    final notedLessons = content.allLessons
        .where((lesson) => progress.noteOf(lesson.id) != null)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('navProfile'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 学习统计
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('overallProgress'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatItem(
                        value: '$learned/$total',
                        label: context.tr('learnedLessons'),
                        color: theme.colorScheme.primary,
                      ),
                      _StatItem(
                        value:
                            '${(progress.averageQuizAccuracy * 100).round()}%',
                        label: context.tr('quizAverage'),
                        color: theme.colorScheme.onSurface,
                      ),
                      _StatItem(
                        value: '${progress.favoriteIds.length}',
                        label: context.tr('favorites'),
                        color: theme.colorScheme.onSurface,
                      ),
                      _StatItem(
                        value: '${progress.notes.length}',
                        label: context.tr('notes'),
                        color: theme.colorScheme.onSurface,
                      ),
                      _StatItem(
                        value: '${progress.totalWrongQuestions}',
                        label: context.tr('wrongBook'),
                        color: theme.colorScheme.onSurface,
                      ),
                      _StatItem(
                        value: '${progress.streakDays}',
                        label: context.tr('streak'),
                        color: theme.colorScheme.onSurface,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: ratio, minHeight: 7),
                  ),
                ],
              ),
            ),
          ),

          // 成就与里程碑入口
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                Icons.emoji_events_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(context.tr('achievements')),
              subtitle: Text(
                context.trArgs('achievementEarnedCount', {
                  'n': earnedAchievementCount(evaluateAchievements(progress)),
                  'm': kAchievements.length,
                }),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AchievementsScreen(),
                ),
              ),
            ),
          ),

          // 学习分析：周期活动、分类掌握度与薄弱点
          const SizedBox(height: 10),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                Icons.insights_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(context.tr('learningAnalytics')),
              subtitle: Text(context.tr('learningAnalyticsHint')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AnalyticsScreen(),
                ),
              ),
            ),
          ),

          // 我的笔记：跨课程检索、标签筛选与导出
          const SizedBox(height: 10),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                Icons.sticky_note_2_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(context.tr('notesTitle')),
              subtitle: Text(
                context.trArgs('notesCountHint', {'n': progress.notes.length}),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const NotesScreen()),
              ),
            ),
          ),

          // 设置
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
            child: Text(
              context.tr('settings'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: Text(context.tr('darkMode')),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(context.tr('themeSystem')),
                          icon: compactControls
                              ? null
                              : const Icon(Icons.brightness_auto, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(context.tr('themeLight')),
                          icon: compactControls
                              ? null
                              : const Icon(Icons.light_mode, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(context.tr('themeDark')),
                          icon: compactControls
                              ? null
                              : const Icon(Icons.dark_mode, size: 16),
                        ),
                      ],
                      selected: {settings.themeMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (value) =>
                          settings.setThemeMode(value.first),
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.translate),
                  title: Text(context.tr('language')),
                  subtitle: Text(
                    '${settings.isEnglish ? 'English' : '简体中文'} · '
                    '${context.trArgs('englishCoverage', {'available': content.englishLessonCount, 'total': content.totalLessons})}',
                  ),
                  value: settings.isEnglish,
                  onChanged: (_) => settings.toggleLocale(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.format_size),
                  title: Text(context.tr('readingFont')),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SegmentedButton<double>(
                      segments: [
                        ButtonSegment(
                          value: 0.9,
                          label: Text(context.tr('fontSmall')),
                        ),
                        ButtonSegment(
                          value: 1.0,
                          label: Text(context.tr('fontNormal')),
                        ),
                        ButtonSegment(
                          value: 1.2,
                          label: Text(context.tr('fontLarge')),
                        ),
                      ],
                      selected: {settings.readingFontScale},
                      showSelectedIcon: false,
                      onSelectionChanged: (value) =>
                          settings.setReadingFontScale(value.first),
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.motion_photos_off_outlined),
                  title: Text(context.tr('reduceMotion')),
                  subtitle: Text(context.tr('reduceMotionHint')),
                  value: settings.reduceMotion,
                  onChanged: settings.setReduceMotion,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Text(context.tr('reviewReminder')),
                  subtitle: Text(
                    settings.reviewReminderEnabled
                        ? '${context.tr('reviewReminderOn')} '
                              '${settings.reminderTimeLabel}'
                        : context.tr('reviewReminderOff'),
                  ),
                  value: settings.reviewReminderEnabled,
                  onChanged: (value) =>
                      _toggleReminder(context, settings, value),
                ),
                if (settings.reviewReminderEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(context.tr('reminderTime')),
                    trailing: Text(
                      settings.reminderTimeLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => _pickReminderTime(context, settings),
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(context.tr('exportData')),
                  subtitle: Text(context.tr('profileExportEncryptedHint')),
                  onTap: () => _exportData(context, progress),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: Text(context.tr('profileShare')),
                  subtitle: Text(context.tr('profileShareHint')),
                  onTap: () => _shareData(context, progress),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: Text(context.tr('importData')),
                  subtitle: Text(context.tr('profileImportHint')),
                  onTap: () => _importData(context, progress),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: Text(context.tr('profileLegacyImport')),
                  subtitle: Text(context.tr('profileLegacyImportHint')),
                  onTap: () =>
                      _importData(context, progress, preferLegacy: true),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(context.tr('offlinePack')),
                  subtitle: Text(
                    content.offlinePackInfo == null
                        ? context.tr('offlinePackNone')
                        : context.trArgs('offlinePackCurrent', {
                            'name': content.offlinePackInfo!.name,
                            'version': content.offlinePackInfo!.version,
                            'count': content.offlinePackInfo!.lessonCount,
                          }),
                  ),
                  trailing: content.offlinePackInfo == null
                      ? const Icon(Icons.download_outlined)
                      : const Icon(Icons.chevron_right),
                  onTap: () => _showOfflinePackManager(context, content),
                ),
              ],
            ),
          ),

          // 错题本：答错的知识点可一键重做
          _SectionHeader(
            title: context.tr('wrongBook'),
            count: progress.totalWrongQuestions,
          ),
          if (progress.totalWrongQuestions == 0)
            EmptyState(
              icon: Icons.task_alt,
              message: context.tr('noWrongQuestions'),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final lesson in content.allLessons.where(
                    (lesson) => progress.wrongCountFor(lesson.id) > 0,
                  ))
                    ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text(lesson.title.of(context.strings.localeCode)),
                      subtitle: Text(
                        '${context.tr('wrongCount')} '
                        '${progress.wrongCountFor(lesson.id)}',
                      ),
                      trailing: const Icon(Icons.refresh),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => QuizScreen(lesson: lesson),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // 收藏
          _SectionHeader(
            title: context.tr('favorites'),
            count: favoriteLessons.length,
          ),
          if (favoriteLessons.isEmpty)
            EmptyState(
              icon: Icons.star_border,
              message: context.tr('noFavorites'),
            )
          else
            for (final lesson in favoriteLessons)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LessonCard(
                  lesson: lesson,
                  isLearned: progress.isLearned(lesson.id),
                  isFavorite: true,
                  quizResult: progress.resultOf(lesson.id),
                  onFavoriteTap: () => progress.toggleFavorite(lesson.id),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LessonScreen(lesson: lesson),
                    ),
                  ),
                ),
              ),

          // 笔记
          _SectionHeader(
            title: context.tr('notes'),
            count: notedLessons.length,
          ),
          if (notedLessons.isEmpty)
            EmptyState(icon: Icons.edit_note, message: context.tr('noNotes'))
          else
            Card(
              child: Column(
                children: [
                  for (final lesson in notedLessons)
                    ListTile(
                      leading: const Icon(Icons.sticky_note_2_outlined),
                      title: Text(lesson.title.of(context.strings.localeCode)),
                      subtitle: Text(
                        progress.noteOf(lesson.id)!.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LessonScreen(lesson: lesson),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link),
            title: Text(context.tr('references')),
            onTap: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(context.tr('references')),
                content: SingleChildScrollView(
                  child: Text(context.tr('referencesBody')),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(context.tr('close')),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Text(
              context.tr('about'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 开关注复提醒：开启时先申请系统通知权限，再交给外壳同步定时计划。
  Future<void> _toggleReminder(
    BuildContext context,
    SettingsProvider settings,
    bool value,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (value) {
      final deniedText = context.tr('notificationDenied');
      final granted = await context
          .read<NotificationService>()
          .requestPermission();
      if (!granted) {
        messenger.showSnackBar(SnackBar(content: Text(deniedText)));
      }
    }
    await settings.setReviewReminderEnabled(value);
  }

  /// 选择每天的提醒时刻。
  Future<void> _pickReminderTime(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      ),
      helpText: context.tr('reminderTime'),
    );
    if (picked == null) return;
    await settings.setReminderTime(picked.hour, picked.minute);
  }
}

class _BackupPasswordDialog extends StatefulWidget {
  const _BackupPasswordDialog({
    required this.titleKey,
    required this.confirmKey,
    required this.allowEmpty,
  });

  final String titleKey;
  final String confirmKey;
  final bool allowEmpty;

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text;
    if (!widget.allowEmpty && value.isEmpty) {
      setState(() => _error = context.tr('profilePasswordRequired'));
      return;
    }
    if (value.isNotEmpty && value.length < 6) {
      setState(() => _error = context.tr('profilePasswordWeak'));
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(context.tr(widget.titleKey)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: context.tr('profilePassword'),
              hintText: widget.allowEmpty
                  ? context.tr('profileExportEncryptedHint')
                  : context.tr('profilePasswordHint'),
              errorText: _error,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.allowEmpty
                ? context.tr('profilePasswordOptional')
                : context.tr('profilePasswordHint'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.tr(widget.confirmKey)),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
