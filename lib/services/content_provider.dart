import 'package:flutter/foundation.dart';

import '../data/asset_content_source.dart';
import '../models/lesson.dart';
import '../models/lesson_category.dart';
import '../models/search_hit.dart';
import 'offline_content_pack_service.dart';
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

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _offlinePack;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ContentPackInfo? get offlinePackInfo =>
      _contentPackService.infoOf(_offlinePack);
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
  Future<ContentPackInfo?> importOfflinePack() async {
    final raw = await _contentPackService.pickJsonFile();
    if (raw == null) return null;
    final pack = _contentPackService.decode(raw);
    await _contentPackService.persist(pack);
    _offlinePack = pack;
    await load();
    return _contentPackService.infoOf(pack);
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

  /// 按关键词搜索标题、关键词、摘要与正文，标题命中优先。
  Future<List<SearchHit>> search(String query) async {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return const [];

    final hits = <_ScoredHit>[];
    for (final category in _categories) {
      for (final lesson in category.lessons) {
        var score = 0;
        final title = '${lesson.title.zh} ${lesson.title.en}'.toLowerCase();
        final summary = '${lesson.summary.zh} ${lesson.summary.en}'
            .toLowerCase();
        final keywords = lesson.keywords.join(' ').toLowerCase();
        final body = (await plainTextOf(lesson)).toLowerCase();

        if (title.contains(keyword)) score += 5;
        if (keywords.contains(keyword)) score += 3;
        if (summary.contains(keyword)) score += 2;
        if (body.contains(keyword)) score += 1;

        if (score > 0) {
          hits.add(
            _ScoredHit(
              hit: SearchHit(
                lesson: lesson,
                category: category,
                snippet: _buildSnippet(body, keyword, lesson.summary.zh),
              ),
              score: score,
            ),
          );
        }
      }
    }

    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits.take(30).map((item) => item.hit).toList();
  }

  String _buildSnippet(String body, String keyword, String fallback) {
    final index = body.indexOf(keyword);
    if (index < 0) return fallback;

    final start = (index - 30).clamp(0, body.length);
    final end = (index + keyword.length + 50).clamp(0, body.length);
    final prefix = start > 0 ? '…' : '';
    final suffix = end < body.length ? '…' : '';
    return '$prefix${body.substring(start, end).trim()}$suffix';
  }
}

class _ScoredHit {
  const _ScoredHit({required this.hit, required this.score});

  final SearchHit hit;
  final int score;
}
