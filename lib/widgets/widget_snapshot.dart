import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 把 [RepaintBoundary] 渲染成 PNG 字节，用于分享学习卡片与证书。
class WidgetSnapshot {
  const WidgetSnapshot._();

  static Future<Uint8List?> capturePng(
    GlobalKey boundaryKey, {
    double pixelRatio = 3,
  }) async {
    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}
