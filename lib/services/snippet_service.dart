import '../models/code_snippet.dart';
import 'storage_service.dart';

/// 代码片段的本地存储：保存、收藏、删除与按语言检索。
///
/// 片段只写在设备本地（Hive），不联网、不同步；导出交给系统分享面板。
class SnippetService {
  SnippetService(this._storage) {
    _restore();
  }

  static const String _storageKey = 'sandbox_snippets';
  static const int maxSnippets = 200;

  final StorageService _storage;
  final List<CodeSnippet> _snippets = <CodeSnippet>[];

  /// 全部片段：收藏优先，其次按更新时间倒序。
  List<CodeSnippet> get snippets {
    final list = List<CodeSnippet>.from(_snippets)
      ..sort((a, b) {
        if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return List<CodeSnippet>.unmodifiable(list);
  }

  List<CodeSnippet> forLanguage(String languageId) =>
      List<CodeSnippet>.unmodifiable(
        snippets.where((item) => item.languageId == languageId),
      );

  int get length => _snippets.length;

  /// 新建或更新片段（id 相同则覆盖），返回保存后的片段。
  Future<CodeSnippet> upsert({
    String? id,
    required String languageId,
    required String title,
    required String code,
    String stdin = '',
    required DateTime now,
  }) async {
    final existingIndex = id == null
        ? -1
        : _snippets.indexWhere((item) => item.id == id);
    final CodeSnippet saved;
    if (existingIndex >= 0) {
      saved = _snippets[existingIndex].copyWith(
        languageId: languageId,
        title: title,
        code: code,
        stdin: stdin,
        updatedAt: now,
      );
      _snippets[existingIndex] = saved;
    } else {
      saved = CodeSnippet(
        id: 'snippet_${now.microsecondsSinceEpoch}',
        languageId: languageId,
        title: title,
        code: code,
        stdin: stdin,
        createdAt: now,
        updatedAt: now,
      );
      _snippets.add(saved);
    }
    if (_snippets.length > maxSnippets) {
      // 超出上限时优先丢弃最旧的未收藏片段。
      final sorted = List<CodeSnippet>.from(_snippets)
        ..sort((a, b) {
          if (a.favorite != b.favorite) return a.favorite ? 1 : -1;
          return a.updatedAt.compareTo(b.updatedAt);
        });
      final removable = sorted.firstWhere(
        (item) => !item.favorite,
        orElse: () => sorted.first,
      );
      _snippets.removeWhere((item) => item.id == removable.id);
    }
    await _persist();
    return saved;
  }

  Future<void> remove(String id) async {
    final before = _snippets.length;
    _snippets.removeWhere((item) => item.id == id);
    if (_snippets.length != before) await _persist();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _snippets.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _snippets[index] = _snippets[index].copyWith(
      favorite: !_snippets[index].favorite,
    );
    await _persist();
  }

  /// 备份用：全部片段的 JSON 表示。
  List<Map<String, dynamic>> exportJson() =>
      _snippets.map((item) => item.toJson()).toList();

  /// 从备份恢复片段；[merge] 为 true 时同 id 仅保留更新时间较新的版本。
  ///
  /// 传入非列表（旧版备份没有该分区）时保持现有片段不变。
  Future<void> importJson(dynamic raw, {bool merge = false}) async {
    if (raw is! List) return;
    final incoming = <CodeSnippet>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final snippet = CodeSnippet.fromJson(item.cast<String, dynamic>());
      if (snippet.id.isEmpty || snippet.code.isEmpty) continue;
      incoming.add(snippet);
    }
    if (!merge) _snippets.clear();
    for (final snippet in incoming) {
      final index = _snippets.indexWhere((item) => item.id == snippet.id);
      if (index < 0) {
        _snippets.add(snippet);
      } else if (snippet.updatedAt.isAfter(_snippets[index].updatedAt)) {
        _snippets[index] = snippet;
      }
    }
    _trimToLimit();
    await _persist();
  }

  void _trimToLimit() {
    while (_snippets.length > maxSnippets) {
      final sorted = List<CodeSnippet>.from(_snippets)
        ..sort((a, b) {
          if (a.favorite != b.favorite) return a.favorite ? 1 : -1;
          return a.updatedAt.compareTo(b.updatedAt);
        });
      final removable = sorted.firstWhere(
        (item) => !item.favorite,
        orElse: () => sorted.first,
      );
      _snippets.removeWhere((item) => item.id == removable.id);
    }
  }

  Future<void> _persist() async {
    await _storage.write(
      _storageKey,
      _snippets.map((item) => item.toJson()).toList(),
    );
  }

  void _restore() {
    final raw = _storage.read(_storageKey, defaultValue: const []);
    if (raw is! List) return;
    for (final item in raw) {
      if (item is Map) {
        final snippet = CodeSnippet.fromJson(item.cast<String, dynamic>());
        if (snippet.id.isEmpty || snippet.code.isEmpty) continue;
        _snippets.add(snippet);
      }
    }
  }
}
