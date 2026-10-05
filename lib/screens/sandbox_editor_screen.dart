import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';

/// 全屏代码编辑器：横屏或长代码时使用，支持字号缩放。
///
/// 关闭时通过 [Navigator.pop] 返回编辑后的代码；用户取消则返回 null。
class SandboxEditorScreen extends StatefulWidget {
  const SandboxEditorScreen({
    super.key,
    required this.title,
    required this.initialCode,
    required this.fontScale,
  });

  final String title;
  final String initialCode;
  final double fontScale;

  @override
  State<SandboxEditorScreen> createState() => _SandboxEditorScreenState();
}

class _SandboxEditorScreenState extends State<SandboxEditorScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialCode,
  );
  late double _scale = widget.fontScale;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changeScale(double delta) {
    setState(() => _scale = (_scale + delta).clamp(0.8, 1.8));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: context.tr('sandboxFontSmaller'),
            onPressed: () => _changeScale(-0.1),
            icon: const Icon(Icons.text_decrease),
          ),
          IconButton(
            tooltip: context.tr('sandboxFontLarger'),
            onPressed: () => _changeScale(0.1),
            icon: const Icon(Icons.text_increase),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: Text(context.tr('sandboxEditorDone')),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _controller,
            autofocus: true,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14 * _scale,
              height: 1.5,
            ),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: context.tr('sandboxEditorHint'),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
            ),
          ),
        ),
      ),
    );
  }
}