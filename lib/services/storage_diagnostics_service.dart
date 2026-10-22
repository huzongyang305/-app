import 'dart:convert';

import '../models/storage_diagnostic.dart';
import 'storage_service.dart';

/// 本地存储诊断与安全清理。
///
/// 只统计本地数据，不读取网络；清理默认只处理可重建缓存和已经失去课程引用的
/// 孤立记录，避免误删用户笔记与进度。
class StorageDiagnosticsService {
  const StorageDiagnosticsService(this._storage);

  final StorageService _storage;

  static const Set<String> cacheKeys = <String>{
    'search_index_cache_v1',
    'apk_size_report_cache',
  };

  StorageDiagnostic analyze({required Set<String> lessonIds}) {
    final categories = <String, int>{};
    final orphan = <String>[];
    final cache = <String>[];
    final notes = <String>[];
    var bytes = 0;
    for (final key in _storage.keys) {
      final value = _storage.read(key);
      final encoded = _encodedLength(value);
      bytes += key.length + encoded;
      categories[_categoryOf(key)] = (categories[_categoryOf(key)] ?? 0) + 1;
      if (cacheKeys.contains(key)) cache.add(key);
      if (key.startsWith('note_')) {
        final id = key.substring('note_'.length);
        if (lessonIds.isNotEmpty && !lessonIds.contains(id)) orphan.add(key);
        notes.add(id);
      } else if (key.startsWith('quiz_result_')) {
        final id = key.substring('quiz_result_'.length);
        if (lessonIds.isNotEmpty && !lessonIds.contains(id)) orphan.add(key);
      }
    }
    return StorageDiagnostic(
      keyCount: _storage.keys.length,
      estimatedBytes: bytes,
      categories: Map<String, int>.unmodifiable(categories),
      orphanKeys: List<String>.unmodifiable(orphan),
      cacheKeys: List<String>.unmodifiable(cache),
      notes: List<String>.unmodifiable(notes),
    );
  }

  Future<int> cleanup({
    required Set<String> lessonIds,
    bool removeOrphans = false,
  }) async {
    final diagnostic = analyze(lessonIds: lessonIds);
    final keys = <String>{...diagnostic.cacheKeys};
    if (removeOrphans) keys.addAll(diagnostic.orphanKeys);
    for (final key in keys) {
      await _storage.delete(key);
    }
    return keys.length;
  }

  static String _categoryOf(String key) {
    if (key.startsWith('note_')) return '笔记';
    if (key.startsWith('quiz_result_')) return '测验成绩';
    if (key.startsWith('review_')) return '复习计划';
    if (key.startsWith('daily_study') || key.startsWith('study_')) {
      return '学习统计';
    }
    if (key.contains('cache')) return '可重建缓存';
    if (key.startsWith('offline_pack')) return '离线内容包';
    return '其他设置';
  }

  static int _encodedLength(dynamic value) {
    try {
      return jsonEncode(value).length;
    } catch (_) {
      return value.toString().length;
    }
  }
}
