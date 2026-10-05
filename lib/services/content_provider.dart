import 'package:flutter/foundation.dart';

import '../data/asset_content_source.dart';
import '../models/lesson.dart';
import '../models/lesson_category.dart';
import '../models/search_hit.dart';
import 'offline_content_pack_service.dart';
import 'search_service.dart';
import 'storage_service.dart';

/// 课程内容仓库：启动时解析 manifest.json，按需读取 Markdown 正文。
///
/// 所有内容都打包在 assets 中，运行时不访问网络。
class ContentProvider extends ChangeNotifier {
  ContentProvider({
    AssetContentSource? source,
    StorageService? storage,
    OfflineContentPackService? contentPackService,
  }) : _source = source ?? const AssetContentSource(),
       _contentPackService =
           contentPackService ?? OfflineContentPackService(storage: storage);

  final AssetContentSource _source;
  final OfflineContentPackService _contentPackService;

  final List<LessonCategory> _categories = <LessonCategory>[];
  final Map<String, String> _markdownCache = <String, String>{};
  final Map<String, String> _plainTextCache = <String, String>{};
  LessonSearchIndex? _searchIndex;

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _offlinePack;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ContentPackInfo? get offlinePackInfo =>
      _contentPackService.infoOf(_offlinePack);

  /// 当前内容包校验和（SHA-256 十六进制）。
  String? get offlinePackChecksum {
    final pack = _offlinePack;
    return pack == null ? null : OfflineContentPackService.checksumOf(pack);
  }

  /// 内容包更新记录，最新的在最前面。
  List<ContentPackHistoryEntry> get offlinePackHistory =>
      _contentPackService.readHistory();
  List<LessonCategory> get categories => List.unmodifiable(_categories);

  List<Lesson> get allLessons =>
      _categories.expand((category) => category.lessons).toList();

  int get totalLessons => allLessons.length;

  /// 拥有完整英文正文的课程数。英文界面会用它显示真实覆盖率，
  /// 避免把中文正文回退误认为已翻译。
  int get englishLessonCount =>
      allLessons.where((lesson) => lesson.hasEnglishBody).length;

  double get englishCoverageRatio =>
      totalLessons == 0 ? 0 : englishLessonCount / totalLessons;

  /// 从 assets 加载内容索引。
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final json = await _source.loadManifest();
      _offlinePack = _contentPackService.readStoredPack();
      final resolved = _offlinePack == null
          ? json
          : _contentPackService.mergeManifest(json, _offlinePack!);
      final list = (resolved['categories'] as List<dynamic>? ?? const []);

      _markdownCache.clear();
      _plainTextCache.clear();
      _searchIndex = null;

      _categories
        ..clear()
        ..addAll(
          list.map(
            (item) =>
                LessonCategory.fromJson((item as Map).cast<String, dynamic>()),
          ),
        );
    } catch (error) {
      // 只保留原始错误，界面层负责按当前语言拼装提示文案。
      _errorMessage = '$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  LessonCategory? categoryById(String id) {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Lesson? lessonById(String id) {
    for (final lesson in allLessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  /// 读取教程 Markdown 正文，带内存缓存，避免重复 IO。
  Future<String> markdownOf(Lesson lesson, {bool preferEnglish = false}) async {
    final offlineMarkdown = _contentPackService.markdownFor(
      _offlinePack,
      lesson.id,
    );
    if (offlineMarkdown != null && offlineMarkdown.trim().isNotEmpty) {
      return offlineMarkdown;
    }
    final useEnglish =
        preferEnglish && (lesson.assetFileEn?.isNotEmpty ?? false);
    final cacheKey = '${lesson.id}:${useEnglish ? 'en' : 'zh'}';
    final cached = _markdownCache[cacheKey];
    if (cached != null) return cached;

    final text = await _source.loadMarkdown(
      useEnglish ? lesson.assetFileEn! : lesson.assetFile,
    );
    _markdownCache[cacheKey] = text;
    return text;
  }

  /// 从系统文件选择器导入 JSON 内容包，成功后立即重新加载课程。
  ///
  /// 支持整包覆盖与 delta 增量包：增量包需声明 base_version，
  /// 合并前会校验 SHA-256；带 signature 的包还会做签名验证。
  Future<ContentPackImportResult?> importOfflinePack() async {
    final raw = await _contentPackService.pickJsonFile();
    if (raw == null) return null;
    final incoming = _contentPackService.decode(raw);
    final existing = _contentPackService.readStoredPack();
    final merged = _contentPackService.mergeForImport(existing, incoming);
    final status = _contentPackService.statusFor(existing, merged.pack);
    final checksum = OfflineContentPackService.checksumOf(merged.pack);
    final signatureVerified = OfflineContentPackService.verifySignature(
      incoming,
    );

    await _contentPackService.persist(merged.pack);
    await _contentPackService.recordHistory(
      ContentPackHistoryEntry(
        version: merged.pack['version']?.toString() ?? '',
        importedAt: DateTime.now(),
        checksum: checksum,
        delta: merged.delta,
        added: merged.added,
        updated: merged.updated,
        removed: merged.removed,
      ),
    );
    _offlinePack = merged.pack;
    await load();
    final info = _contentPackService.infoOf(merged.pack);
    if (info == null) return null;
    return ContentPackImportResult(
      info: info,
      status: status,
      checksum: checksum,
      signatureVerified: signatureVerified,
      addedLessons: merged.added,
      updatedLessons: merged.updated,
      removedLessons: merged.removed,
      delta: merged.delta,
    );
  }

  Future<void> removeOfflinePack() async {
    await _contentPackService.removeStoredPack();
    _offlinePack = null;
    await load();
  }

  /// 去掉 Markdown 标记，得到用于搜索与摘要的纯文本。
  Future<String> plainTextOf(Lesson lesson) async {
    final cached = _plainTextCache[lesson.id];
    if (cached != null) return cached;

    final markdown = await markdownOf(lesson);
    final plain = markdown
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
        .replaceAll(RegExp(r'[#>*`|_\[\]()]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    _plainTextCache[lesson.id] = plain;
    return plain;
  }

  /// 按关键词搜索标题、关键词、摘要与正文，支持拼音、同义词和筛选。
  Future<List<SearchHit>> search(
    String query, {
    String? categoryId,
    Set<String>? lessonIds,
  }) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return const <SearchHit>[];
    final index = _searchIndex ??= LessonSearchIndex();
    if (!index.isBuilt) {
      await index.build(_categories, plainTextOf);
    }
    return index.search(keyword, categoryId: categoryId, lessonIds: lessonIds);
  }
}
