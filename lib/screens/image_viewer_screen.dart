import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';

/// 全屏图片查看器：双指缩放、拖动查看细节、双击缩放或复位。
///
/// 教程里的配图在正文中是缩略显示，遇到流程图、架构图或时序图时
/// 文字会偏小；这里提供不依赖任何插件的全屏查看能力，并保留图注，
/// 离线状态下也能正常使用。
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({super.key, required this.assetPath, this.caption});

  /// 资源路径，例如 `assets/content/images/xxx.webp`。
  final String assetPath;

  /// 图注：来自 Markdown 图片的替代文本（alt）。
  final String? caption;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  static const double _minScale = 1;
  static const double _maxScale = 5;
  static const double _doubleTapScale = 2.4;

  final TransformationController _controller = TransformationController();
  double _scale = 1;
  Offset _doubleTapPoint = Offset.zero;

  bool get _hasCaption => (widget.caption ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTransformChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    final next = _controller.value.getMaxScaleOnAxis();
    if ((next - _scale).abs() > 0.01) {
      setState(() => _scale = next);
    }
  }

  /// 以屏幕中心为焦点缩放到 [target]，保证放大后图片仍在视野中央。
  void _zoomTo(double target) {
    final size = context.size;
    final focal = size == null
        ? const Offset(180, 320)
        : Offset(size.width / 2, size.height / 2);
    _zoomAround(focal, target);
  }

  void _zoomAround(Offset focal, double target) {
    final scenePoint = _controller.toScene(focal);
    final next = target.clamp(_minScale, _maxScale);
    _controller.value = Matrix4.identity()
      ..translateByDouble(focal.dx, focal.dy, 0, 1)
      ..scaleByDouble(next, next, 1, 1)
      ..translateByDouble(-scenePoint.dx, -scenePoint.dy, 0, 1);
  }

  void _reset() {
    _controller.value = Matrix4.identity();
  }

  void _handleDoubleTap() {
    if (_scale > 1.05) {
      _reset();
    } else {
      _zoomAround(_doubleTapPoint, _doubleTapScale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          context.tr('imageViewer'),
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        actions: [
          Center(
            child: Text(
              '${(_scale * 100).round()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          IconButton(
            tooltip: context.tr('zoomOut'),
            onPressed: () => _zoomTo(_scale / 1.4),
            icon: const Icon(Icons.zoom_out),
          ),
          IconButton(
            tooltip: context.tr('zoomIn'),
            onPressed: () => _zoomTo(_scale * 1.4),
            icon: const Icon(Icons.zoom_in),
          ),
          IconButton(
            tooltip: context.tr('resetZoom'),
            onPressed: _reset,
            icon: const Icon(Icons.center_focus_strong_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Semantics(
              label: '${context.tr('imageViewer')}：${widget.caption ?? ''}',
              image: true,
              child: GestureDetector(
                onDoubleTapDown: (details) =>
                    _doubleTapPoint = details.localPosition,
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _controller,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: Image.asset(
                      widget.assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white54,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.caption ?? widget.assetPath,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_hasCaption) _CaptionPanel(caption: widget.caption!),
        ],
      ),
    );
  }
}

/// 图注面板：说明图片在讲什么，并提示缩放与拖动手势。
class _CaptionPanel extends StatelessWidget {
  const _CaptionPanel({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        color: const Color(0xFF121212),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('imageCaption'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white54,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              caption.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.pinch_outlined,
                  size: 15,
                  color: Colors.white54,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.tr('imageZoomHint'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
