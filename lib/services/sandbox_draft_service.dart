import 'dart:convert';

import 'storage_service.dart';

/// 某个语言最近一次编辑的代码与标准输入。
class SandboxDraft {
  const SandboxDraft({required this.code, required this.stdin});

  final String code;
  final String stdin;
}

/// 沙箱草稿：按语言保存代码与标准输入，重新打开 App 后仍可继续编辑。
///
/// 数据只落在本机 Hive，不经过网络；空草稿会被自动删除，
/// 恢复示例代码时不会留下无意义的默认内容。
class SandboxDraftService {
  SandboxDraftService(this._storage);

  static const String storageKey = 'sandbox_drafts_v1';

  final StorageService _storage;

  Map<String, SandboxDraft> _readAll() {
    final raw = _storage.read(storageKey);
    if (raw is! String || raw.isEmpty) return <String, SandboxDraft>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, SandboxDraft>{};
      final drafts = <String, SandboxDraft>{};
      decoded.forEach((key, value) {
        if (key is! String || value is! Map) return;
        final code = value['code'];
        final stdin = value['stdin'];
        if (code is! String && stdin is! String) return;
        final codeText = code is String ? code : '';
        final stdinText = stdin is String ? stdin : '';
        // 只填了标准输入也算有效草稿，与 save 的空内容规则保持一致。
        if (codeText.isEmpty && stdinText.isEmpty) return;
        drafts[key] = SandboxDraft(code: codeText, stdin: stdinText);
      });
      return drafts;
    } catch (_) {
      // 本地数据损坏时按无草稿处理，不能让沙箱无法打开。
      return <String, SandboxDraft>{};
    }
  }

  SandboxDraft? forLanguage(String languageId) => _readAll()[languageId];

  int get length => _readAll().length;

  bool get isEmpty => _readAll().isEmpty;

  Future<void> save(
    String languageId, {
    required String code,
    String stdin = '',
  }) async {
    if (code.trim().isEmpty && stdin.trim().isEmpty) {
      await remove(languageId);
      return;
    }
    final drafts = _readAll();
    drafts[languageId] = SandboxDraft(code: code, stdin: stdin);
    await _writeAll(drafts);
  }

  Future<void> remove(String languageId) async {
    final drafts = _readAll();
    if (drafts.remove(languageId) == null) return;
    await _writeAll(drafts);
  }

  Future<void> clear() async {
    if (_storage.read(storageKey) == null) return;
    await _storage.delete(storageKey);
  }

  Future<void> _writeAll(Map<String, SandboxDraft> drafts) {
    final payload = <String, dynamic>{
      for (final entry in drafts.entries)
        entry.key: <String, dynamic>{
          'code': entry.value.code,
          'stdin': entry.value.stdin,
        },
    };
    return _storage.write(storageKey, jsonEncode(payload));
  }
}
