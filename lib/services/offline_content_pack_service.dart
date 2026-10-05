import 'dart:convert';

import 'package:flutter/services.dart';

import 'content_pack_integrity.dart';
import 'storage_service.dart';

/// 离线内容包信息：展示在设置页，并写入 Hive 以便下次启动继续生效。
class ContentPackInfo {
  const ContentPackInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.lessonCount,
    required this.importedAt,
  });

  final String id;
  final String name;
  final String version;
  final int lessonCount;
  final DateTime importedAt;

  factory ContentPackInfo.fromJson(Map<String, dynamic> json) {
    return ContentPackInfo(
      id: json['pack_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['pack_id']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      lessonCount: (json['lessons'] as List?)?.length ?? 0,
      importedAt:
          DateTime.tryParse(json['imported_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// 内容包导入后的版本关系，用于界面提示「更新 / 已是最新 / 降级覆盖」。
enum ContentPackUpdateStatus { imported, updated, sameVersion, downgraded }

/// 一次导入的完整结果：版本关系、增量统计与校验状态。
class ContentPackImportResult {
  const ContentPackImportResult({
    required this.info,
    required this.status,
    required this.checksum,
    required this.signatureVerified,
    this.addedLessons = 0,
    this.updatedLessons = 0,
    this.removedLessons = 0,
    this.delta = false,
  });

  final ContentPackInfo info;
  final ContentPackUpdateStatus status;
  final String checksum;
  final bool signatureVerified;
  final int addedLessons;
  final int updatedLessons;
  final int removedLessons;
  final bool delta;
}

/// 内容包更新记录，保存在本地并展示在管理页。
class ContentPackHistoryEntry {
  const ContentPackHistoryEntry({
    required this.version,
    required this.importedAt,
    required this.checksum,
    required this.delta,
    required this.added,
    required this.updated,
    required this.removed,
  });

  final String version;
  final DateTime importedAt;
  final String checksum;
  final bool delta;
  final int added;
  final int updated;
  final int removed;

  factory ContentPackHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ContentPackHistoryEntry(
      version: json['version']?.toString() ?? '',
      importedAt:
          DateTime.tryParse(json['imported_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      checksum: json['checksum']?.toString() ?? '',
      delta: json['delta'] == true,
      added: (json['added'] as num?)?.toInt() ?? 0,
      updated: (json['updated'] as num?)?.toInt() ?? 0,
      removed: (json['removed'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': version,
    'imported_at': importedAt.toIso8601String(),
    'checksum': checksum,
    'delta': delta,
    'added': added,
    'updated': updated,
    'removed': removed,
  };
}

/// 负责读取设备上的 JSON 内容包，并把课程覆盖合并进内置 manifest。
///
/// 内容包是纯数据文件，不执行脚本、不访问网络；课程 Markdown 与题目都随包保存。
class OfflineContentPackService {
  OfflineContentPackService({this.storage, MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'code_learn_app/content_pack';
  static const String storageKey = 'offline_content_pack';
  static const String historyKey = 'offline_content_pack_history';
  static const String schema = 'code-learn-content-pack';
  static const int schemaVersion = 1;
  static const int maxPackBytes = 8 * 1024 * 1024;

  /// 内置签名密钥：内容包作者用同一密钥生成 signature 字段。
  /// 这不是保密用途，而是防止文件在传输过程中被意外篡改。
  static const String signingKey = ContentPackIntegrity.signingKey;

  final StorageService? storage;
  final MethodChannel _channel;

  Future<String?> pickJsonFile() async {
    try {
      return await _channel.invokeMethod<String>('pickJsonFile');
    } on MissingPluginException {
      throw const ContentPackException('content_pack_picker_unavailable');
    } on PlatformException catch (error) {
      throw ContentPackException(error.message ?? error.code);
    }
  }

  Map<String, dynamic>? readStoredPack() {
    final raw = storage?.read(storageKey);
    if (raw is! Map) return null;
    return raw.cast<String, dynamic>();
  }

  Map<String, dynamic> decode(String raw) {
    if (raw.trim().isEmpty) {
      throw const ContentPackException('empty_content_pack');
    }
    if (raw.length > maxPackBytes) {
      throw const ContentPackException('content_pack_too_large');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const ContentPackException('invalid_json');
    }
    if (decoded is! Map) {
      throw const ContentPackException('invalid_root');
    }
    final pack = decoded.cast<String, dynamic>();
    _validate(pack);
    _verifyIntegrity(pack);
    pack['imported_at'] = DateTime.now().toIso8601String();
    return pack;
  }

  Future<void> persist(Map<String, dynamic> pack) async {
    await storage?.write(storageKey, pack);
  }

  Future<void> removeStoredPack() async {
    await storage?.delete(storageKey);
  }

  /// 计算内容包校验和（不包含 checksum / signature / imported_at 字段）。
  static String checksumOf(Map<String, dynamic> pack) =>
      ContentPackIntegrity.checksumOf(pack);

  /// 使用内置密钥生成签名，供配套的打包工具调用。
  static String signWithKey(Map<String, dynamic> pack, {String? key}) =>
      ContentPackIntegrity.signWithKey(pack, key: key);

  /// 校验 checksum 字段；未声明 checksum 的旧包按兼容模式放行。
  static bool verifyChecksum(Map<String, dynamic> pack) =>
      ContentPackIntegrity.verifyChecksum(pack);

  /// 校验 signature 字段；未签名返回 false，签名错误抛异常。
  static bool verifySignature(Map<String, dynamic> pack) =>
      ContentPackIntegrity.verifySignature(pack);

  void _verifyIntegrity(Map<String, dynamic> pack) {
    if (!verifyChecksum(pack)) {
      throw const ContentPackException('checksum_failed');
    }
    final declared = pack['signature']?.toString().trim() ?? '';
    if (declared.isNotEmpty && !verifySignature(pack)) {
      throw const ContentPackException('signature_failed');
    }
  }

  /// 语义化版本比较：按数字段逐级比较，数字段缺失时补 0。
  static int compareVersions(String left, String right) {
    final a = _versionParts(left);
    final b = _versionParts(right);
    final length = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y ? 1 : -1;
    }
    return 0;
  }

  static List<int> _versionParts(String value) {
    return value
        .split(RegExp(r'[^0-9]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }

  /// 合并内容包：支持 delta 增量包，也支持整包覆盖。
  ///
  /// 增量包需要在 `delta.base_version` 声明所基于的版本；
  /// `delta.removed_lesson_ids` 列出要删除的课程 ID。
  ({Map<String, dynamic> pack, int added, int updated, int removed, bool delta})
  mergeForImport(
    Map<String, dynamic>? existing,
    Map<String, dynamic> incoming,
  ) {
    _validate(incoming);
    final deltaInfo = incoming['delta'];
    if (deltaInfo is! Map || existing == null) {
      return (pack: incoming, added: 0, updated: 0, removed: 0, delta: false);
    }
    if (existing['pack_id']?.toString() != incoming['pack_id']?.toString()) {
      throw const ContentPackException('delta_pack_mismatch');
    }
    final baseVersion = deltaInfo['base_version']?.toString() ?? '';
    if (baseVersion.isNotEmpty &&
        baseVersion != existing['version']?.toString()) {
      throw const ContentPackException('delta_base_mismatch');
    }

    final merged = _deepCopyMap(existing);
    final existingLessons = (merged['lessons'] as List).cast<Map>();
    final byId = <String, Map>{};
    for (final raw in existingLessons) {
      final lesson = raw.cast<String, dynamic>();
      byId[lesson['id'].toString()] = lesson;
    }
    var added = 0;
    var updated = 0;
    for (final raw in (incoming['lessons'] as List).cast<Map>()) {
      final lesson = raw.cast<String, dynamic>();
      final id = lesson['id'].toString();
      if (byId.containsKey(id)) {
        updated++;
      } else {
        added++;
      }
      byId[id] = _deepCopyMap(lesson);
    }
    var removed = 0;
    final removedIds = (deltaInfo['removed_lesson_ids'] as List?) ?? const [];
    for (final rawId in removedIds) {
      if (byId.remove(rawId.toString()) != null) removed++;
    }

    merged['lessons'] = byId.values.toList();
    for (final key in const [
      'name',
      'version',
      'categories',
      'author',
      'notes',
    ]) {
      if (incoming.containsKey(key)) merged[key] = _deepCopy(incoming[key]);
    }
    merged.remove('delta');
    merged.remove('signature');
    merged.remove('checksum');
    merged['imported_at'] = DateTime.now().toIso8601String();
    return (
      pack: merged,
      added: added,
      updated: updated,
      removed: removed,
      delta: true,
    );
  }

  /// 判断导入包相对已安装版本的更新关系。
  ContentPackUpdateStatus statusFor(
    Map<String, dynamic>? existing,
    Map<String, dynamic> incoming,
  ) {
    if (existing == null) return ContentPackUpdateStatus.imported;
    final comparison = compareVersions(
      incoming['version']?.toString() ?? '',
      existing['version']?.toString() ?? '',
    );
    if (comparison > 0) return ContentPackUpdateStatus.updated;
    if (comparison == 0) return ContentPackUpdateStatus.sameVersion;
    return ContentPackUpdateStatus.downgraded;
  }

  List<ContentPackHistoryEntry> readHistory() {
    final raw = storage?.read(historyKey);
    if (raw is! List) return const <ContentPackHistoryEntry>[];
    return raw
        .whereType<Map>()
        .map(
          (item) =>
              ContentPackHistoryEntry.fromJson(item.cast<String, dynamic>()),
        )
        .toList()
        .reversed
        .toList();
  }

  Future<void> recordHistory(ContentPackHistoryEntry entry) async {
    final raw = storage?.read(historyKey);
    final list = raw is List ? raw.toList() : <dynamic>[];
    list.add(entry.toJson());
    while (list.length > 20) {
      list.removeAt(0);
    }
    await storage?.write(historyKey, list);
  }

  ContentPackInfo? infoOf(Map<String, dynamic>? pack) {
    if (pack == null) return null;
    return ContentPackInfo.fromJson(pack);
  }

  /// 将内容包合并到 asset manifest：同 ID 覆盖元数据和正文，新 ID 追加。
  Map<String, dynamic> mergeManifest(
    Map<String, dynamic> manifest,
    Map<String, dynamic> pack,
  ) {
    _validate(pack);
    final result = _deepCopyMap(manifest);
    final categories = (result['categories'] as List).cast<Map>();
    final categoryById = <String, Map>{};
    for (final rawCategory in categories) {
      final category = rawCategory.cast<String, dynamic>();
      categoryById[category['id']?.toString() ?? ''] = category;
    }

    final packLessons = (pack['lessons'] as List).cast<Map>();
    for (final rawLesson in packLessons) {
      final lesson = rawLesson.cast<String, dynamic>();
      final categoryId = lesson['category_id'].toString();
      var category = categoryById[categoryId];
      if (category == null) {
        category = <String, dynamic>{
          'id': categoryId,
          'title': _packCategoryTitle(pack, categoryId),
          'icon': 'extension',
          'color': '2563EB',
          'lessons': <dynamic>[],
        };
        categories.add(category);
        categoryById[categoryId] = category;
      }
      final lessons = (category['lessons'] as List).cast<Map>();
      final lessonId = lesson['id'].toString();
      final existingIndex = lessons.indexWhere(
        (item) => item['id']?.toString() == lessonId,
      );
      final normalized = _normalizeLesson(lesson, categoryId);
      if (existingIndex >= 0) {
        final existing = lessons[existingIndex].cast<String, dynamic>();
        normalized['file'] ??= existing['file'];
        normalized['order'] ??= existing['order'];
        lessons[existingIndex] = <String, dynamic>{...existing, ...normalized};
      } else {
        normalized['order'] ??= lessons.length;
        lessons.add(normalized);
      }
    }
    return result;
  }

  String? markdownFor(Map<String, dynamic>? pack, String lessonId) {
    if (pack == null) return null;
    final lessons = (pack['lessons'] as List?) ?? const [];
    for (final rawLesson in lessons) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      if (lesson['id']?.toString() == lessonId) {
        return lesson['markdown']?.toString();
      }
    }
    return null;
  }

  Map<String, dynamic> _normalizeLesson(
    Map<String, dynamic> lesson,
    String categoryId,
  ) {
    final result = <String, dynamic>{...lesson}..remove('markdown');
    result['category_id'] = categoryId;
    result['file'] ??= 'offline://${lesson['id']}';
    result['file_en'] = null;
    result['difficulty'] ??= '基础';
    result['minutes'] ??= 10;
    result['keywords'] ??= const <String>[];
    return result;
  }

  Map<String, dynamic> _packCategoryTitle(
    Map<String, dynamic> pack,
    String categoryId,
  ) {
    final categories = (pack['categories'] as List?) ?? const [];
    for (final rawCategory in categories) {
      final category = (rawCategory as Map).cast<String, dynamic>();
      if (category['id']?.toString() != categoryId) continue;
      final title = category['title'];
      if (title is Map) return title.cast<String, dynamic>();
    }
    return <String, dynamic>{'zh': categoryId, 'en': categoryId};
  }

  void _validate(Map<String, dynamic> pack) {
    if (pack['schema']?.toString() != schema) {
      throw const ContentPackException('unsupported_schema');
    }
    if (pack['schema_version'] != schemaVersion) {
      throw const ContentPackException('unsupported_schema_version');
    }
    if ((pack['pack_id']?.toString() ?? '').trim().isEmpty ||
        (pack['version']?.toString() ?? '').trim().isEmpty) {
      throw const ContentPackException('missing_pack_identity');
    }
    final rawLessons = pack['lessons'];
    if (rawLessons is! List || rawLessons.isEmpty || rawLessons.length > 1000) {
      throw const ContentPackException('invalid_lessons');
    }
    final ids = <String>{};
    for (final rawLesson in rawLessons) {
      if (rawLesson is! Map) {
        throw const ContentPackException('invalid_lesson');
      }
      final lesson = rawLesson.cast<String, dynamic>();
      final id = lesson['id']?.toString().trim() ?? '';
      final category = lesson['category_id']?.toString().trim() ?? '';
      final title = lesson['title'];
      final summary = lesson['summary'];
      final markdown = lesson['markdown']?.toString() ?? '';
      if (id.isEmpty || category.isEmpty || !ids.add(id)) {
        throw const ContentPackException('invalid_lesson_identity');
      }
      if (title is! Map || summary is! Map || markdown.trim().isEmpty) {
        throw const ContentPackException('invalid_lesson_content');
      }
      if (markdown.length > 1024 * 1024) {
        throw const ContentPackException('lesson_too_large');
      }
    }
  }

  Map<String, dynamic> _deepCopyMap(Map<String, dynamic> value) =>
      value.map((key, item) => MapEntry(key.toString(), _deepCopy(item)));

  dynamic _deepCopy(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _deepCopy(item)),
      );
    }
    if (value is List) return value.map(_deepCopy).toList();
    return value;
  }
}

class ContentPackException implements Exception {
  const ContentPackException(this.message);

  final String message;

  @override
  String toString() => message;
}
