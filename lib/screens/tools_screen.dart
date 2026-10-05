import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../l10n/l10n_extension.dart';
import '../services/settings_provider.dart';
import 'code_sandbox_screen.dart';
import 'flashcard_screen.dart';
import 'interactive_lab_screen.dart';
import 'system_lab_screen.dart';

/// 离线开发者工具箱：输入 → 转换 → 复制，全部在本地完成，不联网。
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = <String, List<ToolSpec>>{
      'toolsGroupEncode': [
        ToolSpec(
          'base64_encode',
          'toolBase64Encode',
          Icons.code,
          'toolHintBase64Encode',
          (s, _) => base64Encode(utf8.encode(s)),
        ),
        ToolSpec(
          'base64_decode',
          'toolBase64Decode',
          Icons.code_off,
          'toolHintBase64Decode',
          (s, t) =>
              _tryDecode(s, (v) => utf8.decode(base64Decode(v.trim())), t),
        ),
        ToolSpec(
          'url_encode',
          'toolUrlEncode',
          Icons.link,
          'toolHintUrlEncode',
          (s, _) => Uri.encodeComponent(s),
        ),
        ToolSpec(
          'url_decode',
          'toolUrlDecode',
          Icons.link_off,
          'toolHintUrlDecode',
          (s, _) => Uri.decodeComponent(s.trim()),
        ),
        ToolSpec(
          'radix',
          'toolRadix',
          Icons.pin,
          'toolHintRadix',
          (s, t) => _radix(s, t),
        ),
      ],
      'toolsGroupJsonText': [
        ToolSpec(
          'json_pretty',
          'toolJsonPretty',
          Icons.data_object,
          'toolHintJson',
          (s, _) => _json(s, pretty: true),
        ),
        ToolSpec(
          'json_min',
          'toolJsonMin',
          Icons.compress,
          'toolHintJson',
          (s, _) => _json(s, pretty: false),
        ),
        ToolSpec(
          'text_stats',
          'toolTextStats',
          Icons.analytics_outlined,
          'toolHintText',
          (s, t) => _stats(s, t),
        ),
      ],
      'toolsGroupTimeHash': [
        ToolSpec(
          'ts_to_date',
          'toolTsToDate',
          Icons.schedule,
          'toolHintTs',
          (s, t) => _tsToDate(s, t),
        ),
        ToolSpec(
          'date_to_ts',
          'toolDateToTs',
          Icons.event,
          'toolHintDate',
          (s, t) => _dateToTs(s, t),
        ),
        ToolSpec(
          'md5',
          'toolMd5',
          Icons.tag,
          'toolHintText',
          (s, _) => md5.convert(utf8.encode(s)).toString(),
        ),
        ToolSpec(
          'sha256',
          'toolSha256',
          Icons.tag,
          'toolHintText',
          (s, _) => sha256.convert(utf8.encode(s)).toString(),
        ),
      ],
      'toolsGroupOther': [
        ToolSpec(
          'color',
          'toolColor',
          Icons.palette_outlined,
          'toolHintColor',
          (s, t) => _color(s, t),
        ),
        ToolSpec(
          'regex',
          'toolRegex',
          Icons.pattern,
          'toolHintRegex',
          (s, t) => _regex(s, t),
        ),
        ToolSpec(
          'uuid',
          'toolUuid',
          Icons.fingerprint,
          '',
          (_, _) => _uuid(),
          noInput: true,
        ),
      ],
    };

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('toolsTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            context.trArgs('toolsLocalOnly', {
              'n': groups.values.fold<int>(0, (sum, list) => sum + list.length),
            }),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.terminal, color: theme.colorScheme.primary),
              title: Text(context.tr('sandboxTitle')),
              subtitle: Text(context.tr('sandboxHint')),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CodeSandboxScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                Icons.account_tree_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(context.tr('systemLab')),
              subtitle: Text(context.tr('systemLabHint')),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SystemLabScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                Icons.science_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(context.tr('interactiveLab')),
              subtitle: Text(context.tr('interactiveLabHint')),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const InteractiveLabScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                Icons.style_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(context.tr('flashcardTitle')),
              subtitle: Text(context.tr('flashcardEntryHint')),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const FlashcardScreen()),
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Text(
                context.tr(entry.key),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final tool in entry.value)
                    ListTile(
                      leading: Icon(
                        tool.icon,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      title: Text(context.tr(tool.titleKey)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ToolRunnerScreen(spec: tool),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 工具定义：一次输入对应一次转换。
/// 标题与提示存 l10n key，渲染时按当前语言取词。
class ToolSpec {
  const ToolSpec(
    this.id,
    this.titleKey,
    this.icon,
    this.hintKey,
    this.run, {
    this.noInput = false,
  });

  final String id;
  final String titleKey;
  final IconData icon;
  final String hintKey;
  final String Function(String input, AppStrings strings) run;
  final bool noInput;
}

class ToolRunnerScreen extends StatefulWidget {
  const ToolRunnerScreen({super.key, required this.spec});

  final ToolSpec spec;

  @override
  State<ToolRunnerScreen> createState() => _ToolRunnerScreenState();
}

class _ToolRunnerScreenState extends State<ToolRunnerScreen> {
  final TextEditingController _input = TextEditingController();
  String _output = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.spec.noInput) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _run() {
    try {
      final value = widget.spec.run(
        _input.text,
        AppStrings(context.read<SettingsProvider>().localeCode),
      );
      setState(() {
        _output = value;
        _error = null;
      });
    } catch (error) {
      setState(() {
        _output = '';
        _error = context.trReadArgs('toolsFailed', {'error': error});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorPreview = RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(_output.trim())
        ? Color(int.parse(_output.trim().substring(1), radix: 16) | 0xFF000000)
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(widget.spec.titleKey))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!widget.spec.noInput) ...[
            TextField(
              controller: _input,
              maxLines: 6,
              minLines: 3,
              decoration: InputDecoration(
                hintText: context.tr(widget.spec.hintKey),
                suffixIcon: IconButton(
                  tooltip: context.tr('toolsClear'),
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _input.clear();
                    setState(() {
                      _output = '';
                      _error = null;
                    });
                  },
                ),
              ),
              onChanged: (_) {
                if (widget.spec.id.startsWith('json') ||
                    widget.spec.id == 'text_stats') {
                  _run();
                }
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _run,
              icon: const Icon(Icons.play_arrow),
              label: Text(context.tr('toolsConvert')),
            ),
            const SizedBox(height: 16),
          ],
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          if (_output.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  context.tr('toolsResult'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _output));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('toolsCopied')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_all_outlined, size: 16),
                  label: Text(context.tr('toolsCopy')),
                ),
              ],
            ),
            if (colorPreview != null) ...[
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: colorPreview,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                _output,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------- 各工具的实现 ----------

String _tryDecode(
  String input,
  String Function(String) convert,
  AppStrings strings,
) {
  try {
    return convert(input);
  } catch (_) {
    return strings.get('toolsInvalidBase64');
  }
}

String _radix(String input, AppStrings strings) {
  final value = int.parse(input.trim());
  return '${strings.get('toolsRadixDecimal')}: $value\n'
      '${strings.get('toolsRadixBinary')}: ${value.toRadixString(2)}\n'
      '${strings.get('toolsRadixOctal')}: ${value.toRadixString(8)}\n'
      '${strings.get('toolsRadixHex')}: ${value.toRadixString(16).toUpperCase()}\n'
      '${strings.get('toolsRadixByte')}: '
      '${value >= 0 && value <= 255 ? value.toRadixString(2).padLeft(8, '0') : '—'}';
}

String _json(String input, {required bool pretty}) {
  if (input.trim().isEmpty) return '';
  final decoded = jsonDecode(input);
  return pretty
      ? const JsonEncoder.withIndent('  ').convert(decoded)
      : jsonEncode(decoded);
}

String _stats(String input, AppStrings strings) {
  if (input.isEmpty) return '';
  final han = RegExp(r'[\u4e00-\u9fff]').allMatches(input).length;
  final words = input
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .length;
  final digits = RegExp(r'[0-9]').allMatches(input).length;
  final letters = RegExp(r'[A-Za-z]').allMatches(input).length;
  return '${strings.get('toolsStatsChars')}: ${input.length}\n'
      '${strings.get('toolsStatsLines')}: ${input.split('\n').length}\n'
      '${strings.get('toolsStatsWords')}: $words\n'
      '${strings.get('toolsStatsHan')}: $han\n'
      '${strings.get('toolsStatsLetters')}: $letters\n'
      '${strings.get('toolsStatsDigits')}: $digits\n'
      '${strings.get('toolsStatsBytes')}: ${utf8.encode(input).length}';
}

String _tsToDate(String input, AppStrings strings) {
  var value = int.parse(input.trim());
  if (value < 100000000000) value *= 1000; // 秒 → 毫秒
  final date = DateTime.fromMillisecondsSinceEpoch(value);
  return '${strings.get('toolsTimeLocal')}: ${date.toString().split('.').first}\n'
      '${strings.get('toolsTimeUtc')}: ${date.toUtc().toString().split('.').first}\n'
      '${strings.get('toolsTimeIso')}: ${date.toIso8601String()}';
}

String _dateToTs(String input, AppStrings strings) {
  final text = input.trim().replaceAll('/', '-').replaceAll(' ', 'T');
  final date = DateTime.parse(text);
  return '${strings.get('toolsTsSeconds')}: ${date.millisecondsSinceEpoch ~/ 1000}\n'
      '${strings.get('toolsTsMillis')}: ${date.millisecondsSinceEpoch}\n'
      '${strings.get('toolsTimeIso')}: ${date.toIso8601String()}';
}

String _color(String input, AppStrings strings) {
  var hex = input.trim().replaceAll('#', '');
  if (hex.length == 8) hex = hex.substring(2); // 去掉 AA 透明度
  if (hex.length != 6) {
    throw FormatException(strings.get('toolsColorFormat'));
  }
  final value = int.parse(hex, radix: 16);
  final r = (value >> 16) & 0xFF;
  final g = (value >> 8) & 0xFF;
  final b = value & 0xFF;
  return '#${hex.toUpperCase()}\nRGB: rgb($r, $g, $b)\nRGBA: rgba($r, $g, $b, 1)\n'
      'Flutter: Color(0xFF${hex.toUpperCase()})';
}

String _regex(String input, AppStrings strings) {
  final lines = input.split('\n');
  if (lines.isEmpty) return '';
  final pattern = lines.first.trim();
  final text = lines.skip(1).join('\n');
  final matches = RegExp(pattern).allMatches(text).toList();
  if (matches.isEmpty) return strings.get('toolsRegexNone');
  final buffer = StringBuffer(
    '${strings.get('toolsRegexCount').replaceAll('{n}', '${matches.length}')}\n',
  );
  for (var i = 0; i < matches.length; i++) {
    final m = matches[i];
    final item = strings
        .get('toolsRegexItem')
        .replaceAll('{i}', '${i + 1}')
        .replaceAll('{text}', '${m.group(0)}')
        .replaceAll('{start}', '${m.start}')
        .replaceAll('{end}', '${m.end}');
    final groups = m.groupCount > 0
        ? strings
              .get('toolsRegexGroup')
              .replaceAll(
                '{groups}',
                List.generate(m.groupCount, (j) => m.group(j + 1)).join(' | '),
              )
        : '';
    buffer.writeln('$item$groups');
  }
  return buffer.toString().trimRight();
}

String _uuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40; // 版本 4
  bytes[8] = (bytes[8] & 0x3F) | 0x80; // 变体
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
