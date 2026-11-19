import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/custom_question.dart';
import '../services/ocr_service.dart';
import '../services/progress_provider.dart';
import '../theme/app_theme.dart';

/// 拍照收录错题：选图 → 本机文字识别 → 确认题干与答案 → 写入错题本。
///
/// 识别只是草稿，用户点保存才算收录；图片本身不入库。传入 [existing]
/// 即进入编辑模式，只改文字，不再走识别。
class OcrCaptureScreen extends StatefulWidget {
  const OcrCaptureScreen({super.key, this.existing, this.ocr});

  final CustomQuestion? existing;

  /// 识别服务；不传则用默认的 MethodChannel 实现，测试可注入假通道。
  final OcrService? ocr;

  @override
  State<OcrCaptureScreen> createState() => _OcrCaptureScreenState();
}

class _OcrCaptureScreenState extends State<OcrCaptureScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final OcrService _ocr = widget.ocr ?? OcrService();

  late final TextEditingController _question;
  late final TextEditingController _answer;
  late final TextEditingController _explanation;

  OcrOutcome? _outcome;
  bool _recognizing = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _question = TextEditingController(text: existing?.question ?? '');
    _answer = TextEditingController(text: existing?.answer ?? '');
    _explanation = TextEditingController(text: existing?.explanation ?? '');
  }

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    _explanation.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  /// 选图并识别；用户取消时保持原样，识别失败也保留已填内容。
  Future<void> _capture(ImageSource source) async {
    if (_recognizing) return;
    setState(() {
      _recognizing = true;
      _outcome = null;
    });
    final outcome = await _ocr.capture(source: source);
    if (!mounted) return;
    setState(() {
      _recognizing = false;
      _outcome = outcome;
    });
    if (outcome == null) return;
    final suggestion = suggestFromOcr(outcome.text);
    if (_question.text.trim().isEmpty) _question.text = suggestion.question;
    if (_answer.text.trim().isEmpty) _answer.text = suggestion.answer;
    if (_explanation.text.trim().isEmpty) {
      _explanation.text = suggestion.explanation;
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final progress = context.read<ProgressProvider>();
    final question = _question.text.trim();
    final answer = _answer.text.trim();
    final explanation = _explanation.text.trim();
    final existing = widget.existing;
    if (existing == null) {
      final saved = await progress.addCustomQuestion(
        question: question,
        answer: answer,
        explanation: explanation,
      );
      if (saved == null) return;
    } else {
      await progress.updateCustomQuestion(
        existing.id,
        question: question,
        answer: answer,
        explanation: explanation,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String? _required(String? value, String key) =>
      (value ?? '').trim().isEmpty ? context.trRead(key) : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(_isEdit ? 'ocrEditTitle' : 'ocrCaptureTitle')),
        actions: [
          if (!_isEdit) ...[
            IconButton(
              icon: const Icon(Icons.photo_camera_outlined),
              tooltip: context.tr('ocrTakePhoto'),
              onPressed: _recognizing
                  ? null
                  : () => _capture(ImageSource.camera),
            ),
            IconButton(
              icon: const Icon(Icons.photo_library_outlined),
              tooltip: context.tr('ocrFromGallery'),
              onPressed: _recognizing
                  ? null
                  : () => _capture(ImageSource.gallery),
            ),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            if (!_isEdit)
              _RecognitionBanner(
                recognizing: _recognizing,
                outcome: _outcome,
                imagePath: _outcome?.imagePath ?? '',
              ),
            if (!_isEdit) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                context.tr('ocrOfflineNote'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _question,
              minLines: 2,
              maxLines: 8,
              autofocus: !_isEdit,
              decoration: InputDecoration(
                labelText: context.tr('ocrQuestionLabel'),
                hintText: context.tr('ocrQuestionHint'),
              ),
              validator: (value) => _required(value, 'ocrNeedFields'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _answer,
              minLines: 1,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: context.tr('ocrAnswerLabel'),
                hintText: context.tr('ocrAnswerHint'),
              ),
              validator: (value) => _required(value, 'ocrNeedFields'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _explanation,
              minLines: 2,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: context.tr('ocrExplanationLabel'),
                hintText: context.tr('ocrExplanationHint'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _recognizing ? null : _save,
              child: Text(context.tr(_isEdit ? 'ocrSaveUpdate' : 'ocrSave')),
            ),
          ],
        ),
      ),
    );
  }
}

/// 识别状态提示：一行说明当前进展，图片只做本次预览、不入库。
class _RecognitionBanner extends StatelessWidget {
  const _RecognitionBanner({
    required this.recognizing,
    required this.outcome,
    required this.imagePath,
  });

  final bool recognizing;
  final OcrOutcome? outcome;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = outcome;
    final IconData icon;
    final Color accent;
    final String message;
    if (recognizing) {
      icon = Icons.hourglass_top;
      accent = theme.colorScheme.primary;
      message = context.tr('ocrRecognizing');
    } else if (current == null) {
      icon = Icons.photo_camera_outlined;
      accent = theme.colorScheme.primary;
      message = context.tr('ocrPhotoHint');
    } else {
      switch (current.status) {
        case OcrStatus.ok:
          icon = Icons.check_circle_outline;
          accent = AppPalette.success;
          message = context.tr('ocrDone');
        case OcrStatus.empty:
          icon = Icons.image_not_supported_outlined;
          accent = AppPalette.warning;
          message = context.tr('ocrEmpty');
        case OcrStatus.unavailable:
          icon = Icons.cloud_off_rounded;
          accent = AppPalette.warning;
          message = context.tr('ocrUnavailable');
        case OcrStatus.failed:
          icon = Icons.error_outline;
          accent = AppPalette.danger;
          message = context.tr('ocrFailed');
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: AppRadii.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: accent),
            ),
          ),
          if (!recognizing && imagePath.isNotEmpty)
            SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: AppRadii.chip,
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const SizedBox(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
