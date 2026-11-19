import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// 选图回调，抽出来是为了让测试不必依赖真实相机与相册。
typedef ImageSelector = Future<XFile?> Function(ImageSource source);

/// 一次识别的结果状态，用于区分「没认出来」和「本机不支持识别」。
enum OcrStatus {
  /// 识别到文字。
  ok,

  /// 图片可读，但图里没有可识别的文字。
  empty,

  /// 当前平台没有识别通道（例如桌面运行或旧版 APK）。
  unavailable,

  /// 原生识别报错。
  failed,
}

class OcrOutcome {
  const OcrOutcome({required this.status, this.text = '', this.imagePath = ''});

  final OcrStatus status;
  final String text;

  /// 选中图片的本地路径，仅用于本次编辑预览，不入库。
  final String imagePath;

  bool get hasText => status == OcrStatus.ok && text.trim().isNotEmpty;
}

/// 识别结果的表单建议。
class OcrSuggestion {
  const OcrSuggestion({
    this.question = '',
    this.answer = '',
    this.explanation = '',
  });

  final String question;
  final String answer;
  final String explanation;
}

/// 设备端文字识别：拍照 / 选图 → ML Kit 中文识别 → 可编辑文本。
///
/// 识别完全在设备内完成，图片不会离开本机；原生通道缺失时降级为
/// [OcrStatus.unavailable]，调用方仍可让用户手动录入。
class OcrService {
  OcrService({MethodChannel? channel, ImageSelector? pick})
    : _channel = channel ?? const MethodChannel(channelName),
      _pick = pick ?? _defaultPick;

  static const String channelName = 'code_learn_app/ocr';

  /// 识别前把长边压到该像素：ML Kit 官方建议的输入尺度，也能避免大图 OOM。
  static const double _maxEdge = 1800;

  final MethodChannel _channel;
  final ImageSelector _pick;

  bool _isAvailable = true;

  /// 是否仍认为本机具备识别能力；一旦通道缺失就不再反复尝试。
  bool get isAvailable => _isAvailable;

  /// 取一张图并识别其中的文字；用户取消选择时返回 null。
  Future<OcrOutcome?> capture({required ImageSource source}) async {
    final XFile? file;
    try {
      file = await _pick(source);
    } on PlatformException catch (error) {
      debugPrint('选图失败：$error');
      return const OcrOutcome(status: OcrStatus.failed);
    }
    if (file == null) return null;
    final outcome = await recognize(file.path);
    return OcrOutcome(
      status: outcome.status,
      text: outcome.text,
      imagePath: file.path,
    );
  }

  /// 识别指定图片文件里的文字。
  Future<OcrOutcome> recognize(String imagePath) async {
    if (imagePath.isEmpty) {
      return const OcrOutcome(status: OcrStatus.failed);
    }
    try {
      final text = await _channel.invokeMethod<String>(
        'recognizeText',
        <String, dynamic>{'path': imagePath},
      );
      _isAvailable = true;
      return OcrOutcome(
        status: (text ?? '').trim().isEmpty ? OcrStatus.empty : OcrStatus.ok,
        text: text ?? '',
        imagePath: imagePath,
      );
    } on MissingPluginException {
      _isAvailable = false;
      return OcrOutcome(status: OcrStatus.unavailable, imagePath: imagePath);
    } on PlatformException catch (error) {
      debugPrint('文字识别失败：$error');
      return OcrOutcome(status: OcrStatus.failed, imagePath: imagePath);
    }
  }

  static Future<XFile?> _defaultPick(ImageSource source) {
    final picker = ImagePicker();
    return picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: _maxEdge,
      maxHeight: _maxEdge,
    );
  }
}

/// 答案与解析的行首标记，中英文都覆盖：识别到的题面通常按
/// 「题干 → 答案 → 解析」排列，靠这些标记切分能省掉大部分手工粘贴。
final RegExp _answerMarker = RegExp(
  r'^(参考答案|正确答案|标准答案|答案|answer)\s*[:：]?\s*',
  caseSensitive: false,
);
final RegExp _explanationMarker = RegExp(
  r'^(解析|详解|解答|说明|解释|explanation)\s*[:：]?\s*',
  caseSensitive: false,
);

/// 单段最长保留的字符数，防止整页识别文本一次性塞进一条记录。
const int _segmentLimit = 2000;

/// 按行首标记把识别文本拆成题干 / 答案 / 解析建议。
///
/// 只做搬运不做判断：标记之后的内容归入对应段落，没标记的行并入题干，
/// 用户仍需在表单里确认——识别不能保证答案本身正确。
OcrSuggestion suggestFromOcr(String raw) {
  final lines = raw
      .split(RegExp(r'\r\n|\r|\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty);
  final question = <String>[];
  final answer = <String>[];
  final explanation = <String>[];
  var bucket = question;
  for (final line in lines) {
    if (_explanationMarker.hasMatch(line)) {
      bucket = explanation;
      _append(bucket, _stripMarker(line, _explanationMarker));
      continue;
    }
    if (_answerMarker.hasMatch(line)) {
      bucket = answer;
      _append(bucket, _stripMarker(line, _answerMarker));
      continue;
    }
    _append(bucket, line);
  }
  return OcrSuggestion(
    question: _join(question),
    answer: _join(answer),
    explanation: _join(explanation),
  );
}

void _append(List<String> bucket, String text) {
  final trimmed = text.trim();
  if (trimmed.isNotEmpty) bucket.add(trimmed);
}

/// 去掉行首的标记词，保留其后的实际内容（「答案 A」里的 A 不能丢）。
String _stripMarker(String line, RegExp marker) =>
    line.replaceFirst(marker, '');

String _join(List<String> lines) {
  if (lines.isEmpty) return '';
  final text = lines.join('\n');
  return text.length <= _segmentLimit ? text : text.substring(0, _segmentLimit);
}
