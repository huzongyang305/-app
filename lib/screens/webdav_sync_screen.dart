import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/backup_preview.dart';
import '../services/backup_bundle_service.dart';
import '../services/progress_provider.dart';
import '../services/settings_provider.dart';
import '../services/storage_service.dart';
import '../services/webdav_sync_service.dart';

/// WebDAV 多设备同步设置页。
///
/// 同步的是完整备份包（进度 + 设置 + 片段 + 草稿 + 阅读位置），采用双向合并：
/// 取回远端数据并入本机后再写回，两台设备先后同步即可互相补齐。
class WebDavSyncScreen extends StatefulWidget {
  const WebDavSyncScreen({super.key, this.service});

  /// 测试可注入假传输层；为 null 时使用系统 HttpClient。
  final WebDavSyncService? service;

  @override
  State<WebDavSyncScreen> createState() => _WebDavSyncScreenState();
}

class _WebDavSyncScreenState extends State<WebDavSyncScreen> {
  final TextEditingController _endpoint = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  late final WebDavSyncService _service;
  bool _enabled = false;
  bool _autoSync = false;
  bool _hasSavedPassword = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service =
        widget.service ?? WebDavSyncService(context.read<StorageService>());
    final config = _service.readConfig();
    _endpoint.text = config.endpoint;
    _username.text = config.username;
    _enabled = config.enabled;
    _autoSync = config.autoSync;
    _hasSavedPassword = config.password.isNotEmpty;
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _service.saveConfig(
      endpoint: _endpoint.text,
      username: _username.text,
      password: _password.text,
      enabled: _enabled,
      autoSync: _autoSync,
    );
    if (!mounted) return;
    setState(() => _hasSavedPassword = _service.readConfig().password != '');
    _toast(context.trRead('webdavSaved'));
  }

  Future<void> _testConnection() =>
      _run(action: _service.testConnection, success: 'webdavTestOk');

  Future<void> _syncNow() async {
    final bundle = BackupBundleService(
      context.read<StorageService>(),
      context.read<ProgressProvider>(),
      context.read<SettingsProvider>(),
    );
    await _run(
      action: () async {
        final outcome = await _service.sync(
          buildBundle: bundle.buildExportData,
          applyRemote: (remote) =>
              bundle.restore(remote, mode: BackupImportMode.merge),
          at: context.read<ProgressProvider>().now,
        );
        return outcome;
      },
      success: 'webdavSyncDone',
    );
  }

  Future<void> _run({
    required Future<Object?> Function() action,
    required String success,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // 先落盘配置，否则「立即同步」用的还是旧地址。
      await _service.saveConfig(
        endpoint: _endpoint.text,
        username: _username.text,
        password: _password.text,
        enabled: _enabled,
        autoSync: _autoSync,
      );
      await action();
      if (!mounted) return;
      setState(() => _hasSavedPassword = _service.readConfig().password != '');
      _toast(context.trRead(success));
    } on WebDavSyncException catch (error) {
      if (mounted) _toast(_errorText(error));
    } catch (error) {
      if (mounted) _toast(context.trRead('webdavFailedUnknown'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errorText(WebDavSyncException error) {
    final detail = error.status == null ? '' : ' (${error.status})';
    final key = switch (error.code) {
      'webdav_url_missing' => 'webdavErrUrlMissing',
      'webdav_url_invalid' => 'webdavErrUrlInvalid',
      'webdav_insecure_url' => 'webdavErrInsecure',
      'webdav_unauthorized' => 'webdavErrUnauthorized',
      'webdav_parent_missing' => 'webdavErrParentMissing',
      'webdav_unreachable' => 'webdavErrUnreachable',
      'webdav_server_error' => 'webdavErrServer',
      'webdav_unsupported_reply' => 'webdavErrUnsupported',
      'webdav_bad_backup' => 'webdavErrBadBackup',
      'webdav_too_large' => 'webdavErrTooLarge',
      _ => 'webdavFailedUnknown',
    };
    return '${context.trRead(key)}$detail';
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _service.lastSyncAt;
    final lastStatus = _service.lastStatus;
    final endpoint = _endpoint.text.trim();
    final isInsecure = endpoint.startsWith('http://');

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('webdavTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            context.tr('webdavIntro'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('webdav-endpoint-field'),
            controller: _endpoint,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: context.tr('webdavEndpoint'),
              helperText: context.tr('webdavEndpointHint'),
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _username,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: context.tr('webdavUsername'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('webdav-password-field'),
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: context.tr('webdavPassword'),
              helperText: _hasSavedPassword
                  ? context.tr('webdavPasswordKept')
                  : context.tr('webdavPasswordEmpty'),
              border: const OutlineInputBorder(),
            ),
          ),
          if (isInsecure) ...[
            const SizedBox(height: 12),
            _Notice(
              icon: Icons.warning_amber_rounded,
              text: context.tr('webdavInsecureWarning'),
            ),
          ],
          const Divider(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.sync),
            title: Text(context.tr('webdavEnabled')),
            subtitle: Text(context.tr('webdavEnabledHint')),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.schedule),
            title: Text(context.tr('webdavAutoSync')),
            subtitle: Text(context.tr('webdavAutoSyncHint')),
            value: _autoSync,
            onChanged: _enabled
                ? (value) => setState(() => _autoSync = value)
                : null,
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('webdav-save'),
                onPressed: _busy ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(context.tr('webdavSave')),
              ),
              OutlinedButton.icon(
                key: const ValueKey('webdav-test'),
                onPressed: _busy ? null : _testConnection,
                icon: const Icon(Icons.network_check),
                label: Text(context.tr('webdavTest')),
              ),
              FilledButton.icon(
                key: const ValueKey('webdav-sync'),
                onPressed: _busy || !_enabled ? null : _syncNow,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(context.tr('webdavSyncNow')),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            context.tr('webdavStatusTitle'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            last == null
                ? context.tr('webdavNeverSynced')
                : context.trArgs('webdavLastSync', {
                    'time': _formatTime(last),
                    'size': _formatSize(_service.lastBytes),
                  }),
            style: theme.textTheme.bodySmall,
          ),
          if (lastStatus.isNotEmpty &&
              lastStatus != 'created' &&
              lastStatus != 'merged')
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _Notice(
                icon: Icons.error_outline,
                text: _errorText(WebDavSyncException(lastStatus)),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            context.tr('webdavSecurityNote'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  static String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '-';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
