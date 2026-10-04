import 'dart:convert';

import 'package:flutter/services.dart';

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

/// 负责读取设备上的 JSON 内容包，并把课程覆盖合并进内置 manifest。
///
/// 内容包是纯数据文件，不执行脚本、不访问网络；课程 Markdown 与题目都随包保存。
class OfflineContentPackService {
  OfflineContentPackService({this.storage, MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'code_learn_app/content_pack';
  static const String storageKey = 'offline_content_pack';
  static const String schema = 'code-learn-content-pack';
  static const int schemaVersion = 1;
  static const int maxPackBytes = 8 * 1024 * 1024;

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
    pack['imported_at'] = DateTime.now().toIso8601String();
    return pack;
  }

  Future<void> persist(Map<String, dynamic> pack) async {
    await storage?.write(storageKey, pack);
  }

  Future<void> removeStoredPack() async {
    await storage?.delete(storageKey);
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
