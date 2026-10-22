import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 数据源：从 assets 读取课程索引与 Markdown 正文。
///
/// 这一层只负责「数据从哪来」，不关心业务状态；
/// `ContentProvider` 在它之上做解析、缓存与搜索。
class AssetContentSource {
  const AssetContentSource();

  static const String manifestPath = 'assets/content/manifest.json';

  Future<Map<String, dynamic>> loadManifest() async {
    final raw = await rootBundle.loadString(manifestPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<String> loadMarkdown(String assetFile) {
    return rootBundle.loadString(assetFile);
  }
}
