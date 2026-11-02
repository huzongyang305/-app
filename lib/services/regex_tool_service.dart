import 'dart:async';
import 'dart:isolate';

/// 正则工具的执行结果。
class RegexToolResult {
  const RegexToolResult({required this.matches, required this.truncated});

  final List<RegexToolMatch> matches;

  /// 匹配数量达到上限，后续结果未展开。
  final bool truncated;
}

class RegexToolMatch {
  const RegexToolMatch({
    required this.text,
    required this.start,
    required this.end,
    required this.groups,
  });

  final String text;
  final int start;
  final int end;
  final List<String?> groups;
}

enum RegexToolError {
  invalidPattern,
  timeout,
  patternTooLong,
  textTooLong,
  failed,
}

class RegexToolException implements Exception {
  const RegexToolException(this.kind, [this.detail]);

  final RegexToolError kind;
  final String? detail;

  @override
  String toString() => detail ?? kind.name;
}

/// 在可终止的 isolate 中执行用户正则，避免灾难性回溯卡住 UI。
class RegexToolService {
  const RegexToolService._();

  static const int maxPatternLength = 1000;
  static const int maxTextLength = 100000;
  static const int maxMatches = 200;
  static const Duration defaultTimeout = Duration(seconds: 3);

  static Future<RegexToolResult> match({
    required String pattern,
    required String text,
    bool caseSensitive = true,
    bool multiLine = false,
    bool dotAll = false,
    bool unicode = false,
    int matchLimit = maxMatches,
    Duration timeout = defaultTimeout,
  }) async {
    if (pattern.length > maxPatternLength) {
      throw const RegexToolException(RegexToolError.patternTooLong);
    }
    if (text.length > maxTextLength) {
      throw const RegexToolException(RegexToolError.textTooLong);
    }

    final port = ReceivePort();
    final isolate = await Isolate.spawn(_regexWorker, <String, Object?>{
      'port': port.sendPort,
      'pattern': pattern,
      'text': text,
      'caseSensitive': caseSensitive,
      'multiLine': multiLine,
      'dotAll': dotAll,
      'unicode': unicode,
      'matchLimit': matchLimit,
    });
    var received = false;
    try {
      final message = await port.first.timeout(timeout);
      received = true;
      if (message is! Map) {
        throw const RegexToolException(RegexToolError.failed);
      }
      if (message['ok'] != true) {
        throw RegexToolException(
          message['invalid'] == true
              ? RegexToolError.invalidPattern
              : RegexToolError.failed,
          message['error'] as String?,
        );
      }
      final items = (message['items'] as List?) ?? const <Object?>[];
      return RegexToolResult(
        matches: items
            .whereType<Map>()
            .map(
              (item) => RegexToolMatch(
                text: '${item['text'] ?? ''}',
                start: item['start'] as int? ?? 0,
                end: item['end'] as int? ?? 0,
                groups: ((item['groups'] as List?) ?? const <Object?>[])
                    .map((group) => group as String?)
                    .toList(growable: false),
              ),
            )
            .toList(growable: false),
        truncated: message['truncated'] == true,
      );
    } on TimeoutException {
      throw const RegexToolException(RegexToolError.timeout);
    } finally {
      if (!received) {
        isolate.kill(priority: Isolate.immediate);
      }
      port.close();
    }
  }
}

void _regexWorker(Map<String, Object?> payload) {
  final port = payload['port'] as SendPort;
  try {
    final expression = RegExp(
      payload['pattern'] as String,
      caseSensitive: payload['caseSensitive'] as bool? ?? true,
      multiLine: payload['multiLine'] as bool? ?? false,
      dotAll: payload['dotAll'] as bool? ?? false,
      unicode: payload['unicode'] as bool? ?? false,
    );
    final text = payload['text'] as String;
    final limit = payload['matchLimit'] as int? ?? RegexToolService.maxMatches;
    final items = <Map<String, Object?>>[];
    var truncated = false;
    for (final match in expression.allMatches(text)) {
      if (items.length >= limit) {
        truncated = true;
        break;
      }
      items.add(<String, Object?>{
        'text': match.group(0) ?? '',
        'start': match.start,
        'end': match.end,
        'groups': <String?>[
          for (var index = 1; index <= match.groupCount; index++)
            match.group(index),
        ],
      });
    }
    port.send(<String, Object?>{
      'ok': true,
      'items': items,
      'truncated': truncated,
    });
  } on FormatException catch (error) {
    port.send(<String, Object?>{
      'ok': false,
      'invalid': true,
      'error': error.message,
    });
  } catch (error) {
    port.send(<String, Object?>{
      'ok': false,
      'invalid': false,
      'error': '$error',
    });
  }
}
