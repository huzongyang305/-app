import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'backup_document_service.dart';
import 'backup_file_service.dart';
import 'storage_service.dart';

/// WebDAV 一次请求的返回。
class WebDavReply {
  const WebDavReply(this.status, this.body);

  /// HTTP 状态码；网络层失败（超时、断网、DNS）时为 0。
  final int status;
  final String body;
}

/// 传输层抽象，测试可注入假实现，正式运行使用系统 HttpClient。
abstract class WebDavTransport {
  const WebDavTransport();

  Future<WebDavReply> get(Uri uri, {String? username, String? password});

  Future<WebDavReply> put(
    Uri uri,
    String body, {
    String? username,
    String? password,
  });
}

/// 基于 dart:io HttpClient 的实现，不额外引入依赖。
class HttpWebDavTransport extends WebDavTransport {
  const HttpWebDavTransport({this.timeout = const Duration(seconds: 20)});

  final Duration timeout;

  @override
  Future<WebDavReply> get(Uri uri, {String? username, String? password}) =>
      _send('GET', uri, null, username, password);

  @override
  Future<WebDavReply> put(
    Uri uri,
    String body, {
    String? username,
    String? password,
  }) => _send('PUT', uri, body, username, password);

  Future<WebDavReply> _send(
    String method,
    Uri uri,
    String? body,
    String? username,
    String? password,
  ) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.openUrl(method, uri).timeout(timeout);
      if (username != null && username.isNotEmpty) {
        final token = base64Encode(utf8.encode('$username:$password'));
        request.headers.set(HttpHeaders.authorizationHeader, 'Basic $token');
      }
      if (body != null) {
        request.headers.contentType = ContentType(
          'application',
          'json',
          charset: 'utf-8',
        );
        request.write(body);
      }
      final response = await request.close().timeout(timeout);
      final text = await utf8.decoder.bind(response).join().timeout(timeout);
      return WebDavReply(response.statusCode, text);
    } on TimeoutException {
      return const WebDavReply(0, 'timeout');
    } on SocketException {
      return const WebDavReply(0, 'offline');
    } on OSError {
      return const WebDavReply(0, 'offline');
    } on FormatException {
      // 地址含非法字符或响应不是 UTF-8，按服务端异常上报。
      return const WebDavReply(-1, 'format');
    } finally {
      client.close(force: true);
    }
  }
}

/// WebDAV 连接配置，全部来自本机存储。
class WebDavConfig {
  const WebDavConfig({
    required this.endpoint,
    required this.username,
    required this.password,
    required this.enabled,
    required this.autoSync,
  });

  static const WebDavConfig empty = WebDavConfig(
    endpoint: '',
    username: '',
    password: '',
    enabled: false,
    autoSync: false,
  );

  /// 形如 `https://dav.example.com/dav/code_learn/backup.json` 的完整地址。
  final String endpoint;
  final String username;
  final String password;
  final bool enabled;

  /// 启动时自动同步：距上次成功同步超过 [WebDavSyncService.autoSyncGap] 才执行。
  final bool autoSync;

  bool get isConfigured => Uri.tryParse(endpoint)?.hasAbsolutePath ?? false;

  bool get isHttps => Uri.tryParse(endpoint)?.scheme == 'https';
}

/// 一次同步的结果，用于界面文案与「上次同步」记录。
class WebDavSyncOutcome {
  const WebDavSyncOutcome({
    required this.pulledFirstTime,
    required this.merged,
    required this.bytes,
    required this.finishedAt,
  });

  /// 远端原本没有备份文件，本次是首次上传。
  final bool pulledFirstTime;

  /// 本次把远端数据按合并模式并入了本机。
  final bool merged;
  final int bytes;
  final DateTime finishedAt;
}

class WebDavSyncException implements Exception {
  const WebDavSyncException(this.code, [this.status]);

  final String code;

  /// 原始 HTTP 状态码，网络层失败时为 null。
  final int? status;

  @override
  String toString() => code;
}

/// 把完整备份包同步到 WebDAV，实现多台设备共享同一份学习记录。
///
/// 同步是双向合并：先取回远端备份按 merge 模式并入本机，再把合并结果写回。
/// 因此两台离线设备各自学习后，先后同步即可互相补齐，不会互相覆盖。
class WebDavSyncService {
  WebDavSyncService(
    this._storage, {
    this._transport = const HttpWebDavTransport(),
  });

  static const String endpointKey = 'webdav_endpoint';
  static const String usernameKey = 'webdav_username';
  static const String passwordKey = 'webdav_password';
  static const String enabledKey = 'webdav_enabled';
  static const String autoSyncKey = 'webdav_auto_sync';
  static const String lastSyncKey = 'webdav_last_sync_at';
  static const String lastSizeKey = 'webdav_last_size_bytes';
  static const String lastStatusKey = 'webdav_last_status';

  /// 自动同步的最小间隔，避免每次冷启动都打网络。
  static const Duration autoSyncGap = Duration(days: 1);

  final StorageService _storage;
  final WebDavTransport _transport;

  WebDavConfig readConfig() => WebDavConfig(
    endpoint: _text(endpointKey),
    username: _text(usernameKey),
    password: _text(passwordKey),
    enabled: _storage.read(enabledKey, defaultValue: false) == true,
    autoSync: _storage.read(autoSyncKey, defaultValue: false) == true,
  );

  DateTime? get lastSyncAt => DateTime.tryParse(_text(lastSyncKey));

  String get lastStatus => _text(lastStatusKey);

  /// 上次成功同步写出的备份包大小（字节）；从未同步时为 null。
  int? get lastBytes {
    final value = _storage.read(lastSizeKey);
    return value is int ? value : null;
  }

  /// 是否到了自动同步的时间窗口。
  bool isAutoSyncDue(DateTime now) {
    final config = readConfig();
    if (!config.enabled || !config.autoSync || !config.isConfigured) {
      return false;
    }
    final last = lastSyncAt;
    return last == null || !now.isBefore(last.add(autoSyncGap));
  }

  Future<void> saveConfig({
    required String endpoint,
    required String username,
    required String password,
    required bool enabled,
    required bool autoSync,
  }) async {
    final trimmed = endpoint.trim();
    await _storage.write(endpointKey, trimmed);
    await _storage.write(usernameKey, username.trim());
    // 留空表示沿用已保存的密码，避免每次进设置页都要重填。
    if (password.isNotEmpty) {
      await _storage.write(passwordKey, password);
    }
    await _storage.write(enabledKey, enabled);
    await _storage.write(autoSyncKey, autoSync);
  }

  Future<void> clearCredentials() async {
    await _storage.delete(passwordKey);
  }

  /// 只验证地址能不能连通，不读写学习数据。
  Future<void> testConnection() async {
    final config = readConfig();
    _validate(config);
    final reply = await _transport.get(
      Uri.parse(config.endpoint),
      username: config.username,
      password: config.password,
    );
    // 首次使用前文件还不存在，404 说明服务可达，属正常状态。
    if (reply.status == 404) return;
    _checkReply(reply, expectBody: false);
  }

  /// 执行一次双向合并同步。
  ///
  /// [buildBundle] 提供本机完整备份包，[applyRemote] 负责把远端数据并入本机；
  /// 由调用方注入，避免本服务反向依赖 Provider。
  Future<WebDavSyncOutcome> sync({
    required Map<String, dynamic> Function() buildBundle,
    required Future<void> Function(Map<String, dynamic> remote) applyRemote,
    DateTime? at,
  }) async {
    try {
      return await _merge(
        buildBundle: buildBundle,
        applyRemote: applyRemote,
        at: at,
      );
    } on WebDavSyncException catch (error) {
      await _recordFailure(error.code);
      rethrow;
    }
  }

  Future<WebDavSyncOutcome> _merge({
    required Map<String, dynamic> Function() buildBundle,
    required Future<void> Function(Map<String, dynamic> remote) applyRemote,
    DateTime? at,
  }) async {
    final config = readConfig();
    _validate(config);
    final uri = Uri.parse(config.endpoint);
    final reply = await _transport.get(
      uri,
      username: config.username,
      password: config.password,
    );
    var pulledFirstTime = false;
    var merged = false;
    if (reply.status == 404) {
      // 远端还没有文件，首次同步直接把本机数据推上去。
      pulledFirstTime = true;
    } else {
      _checkReply(reply, expectBody: true);
      final remote = _decodeBundle(reply.body);
      await applyRemote(remote);
      merged = true;
    }
    final payload = jsonEncode(buildBundle());
    if (payload.length > BackupFileService.maxBackupBytes) {
      throw const WebDavSyncException('webdav_too_large');
    }
    final put = await _transport.put(
      uri,
      payload,
      username: config.username,
      password: config.password,
    );
    _checkReply(put, expectBody: false);
    final finishedAt = at ?? DateTime.now();
    await _storage.write(lastSyncKey, finishedAt.toIso8601String());
    await _storage.write(lastSizeKey, payload.length);
    await _storage.write(lastStatusKey, pulledFirstTime ? 'created' : 'merged');
    return WebDavSyncOutcome(
      pulledFirstTime: pulledFirstTime,
      merged: merged,
      bytes: payload.length,
      finishedAt: finishedAt,
    );
  }

  void _validate(WebDavConfig config) {
    if (config.endpoint.isEmpty) {
      throw const WebDavSyncException('webdav_url_missing');
    }
    final uri = Uri.tryParse(config.endpoint);
    if (uri == null || !uri.hasAbsolutePath) {
      throw const WebDavSyncException('webdav_url_invalid');
    }
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      throw const WebDavSyncException('webdav_url_invalid');
    }
    if (!uri.hasAuthority) {
      throw const WebDavSyncException('webdav_url_invalid');
    }
    if (uri.scheme != 'https' && config.password.isNotEmpty) {
      // 明文 HTTP 传密码风险很高，直接拒绝而不是提示。
      throw const WebDavSyncException('webdav_insecure_url');
    }
  }

  void _checkReply(WebDavReply reply, {required bool expectBody}) {
    if (reply.status == 0 || reply.status == -1) {
      throw const WebDavSyncException('webdav_unreachable');
    }
    if (reply.status == 401 || reply.status == 403) {
      throw WebDavSyncException('webdav_unauthorized', reply.status);
    }
    if (reply.status == 409) {
      throw const WebDavSyncException('webdav_parent_missing');
    }
    if (reply.status >= 400) {
      throw WebDavSyncException('webdav_server_error', reply.status);
    }
    if (expectBody && reply.status != 200 && reply.status != 201) {
      // 207 Multi-Status 等响应体不是备份 JSON，无法合并。
      throw WebDavSyncException('webdav_unsupported_reply', reply.status);
    }
  }

  Map<String, dynamic> _decodeBundle(String body) {
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw const WebDavSyncException('webdav_bad_backup');
    }
    if (decoded is! Map) {
      throw const WebDavSyncException('webdav_bad_backup');
    }
    try {
      return BackupDocumentService.normalizeForImport(
        decoded.cast<String, dynamic>(),
      );
    } catch (_) {
      throw const WebDavSyncException('webdav_bad_backup');
    }
  }

  Future<void> _recordFailure(String code) =>
      _storage.write(lastStatusKey, code);

  String _text(String key) {
    final value = _storage.read(key, defaultValue: '');
    return value is String ? value : '';
  }
}
