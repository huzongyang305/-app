import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 内容包完整性算法：稳定序列化 + SHA-256 校验和 + HMAC-SHA256 签名。
///
/// 该文件只依赖 dart:convert 与 crypto，可被命令行打包工具直接复用，
/// 不引入 Flutter，因此 `dart run tool/sign_content_pack.dart` 也能运行。
class ContentPackIntegrity {
  const ContentPackIntegrity._();

  /// 内置签名密钥：不是保密用途，而是防止文件在传输过程中被意外篡改。
  static const String signingKey = 'code-learn-content-pack-v1';

  /// 计算内容包校验和，排除 checksum / signature / imported_at 三个易变字段。
  static String checksumOf(Map<String, dynamic> pack) {
    final payload = canonicalJson(signablePayload(pack));
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// 使用指定密钥（默认内置密钥）生成 HMAC 签名。
  static String signWithKey(Map<String, dynamic> pack, {String? key}) {
    final payload = canonicalJson(signablePayload(pack));
    return Hmac(
      sha256,
      utf8.encode(key ?? signingKey),
    ).convert(utf8.encode(payload)).toString();
  }

  /// 校验 checksum 字段；未声明时返回 true，兼容早期未签名内容包。
  static bool verifyChecksum(Map<String, dynamic> pack) {
    final declared = pack['checksum']?.toString().trim() ?? '';
    if (declared.isEmpty) return true;
    final normalized = declared.replaceFirst(
      RegExp(r'^sha256:', caseSensitive: false),
      '',
    );
    return normalized.toLowerCase() == checksumOf(pack).toLowerCase();
  }

  /// 校验 signature 字段；未声明返回 false，由调用方决定是否放行。
  static bool verifySignature(Map<String, dynamic> pack) {
    final declared = pack['signature']?.toString().trim() ?? '';
    if (declared.isEmpty) return false;
    return declared.toLowerCase() == signWithKey(pack).toLowerCase();
  }

  /// 去掉校验字段后的可签名负载。
  static Map<String, dynamic> signablePayload(Map<String, dynamic> pack) {
    final result = <String, dynamic>{};
    for (final entry in pack.entries) {
      if (const ['checksum', 'signature', 'imported_at'].contains(entry.key)) {
        continue;
      }
      result[entry.key.toString()] = entry.value;
    }
    return result;
  }

  /// 稳定序列化：对象键排序、列表保持顺序，保证同一内容得到同一校验和。
  static String canonicalJson(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      final buffer = StringBuffer('{');
      for (var i = 0; i < keys.length; i++) {
        if (i > 0) buffer.write(',');
        buffer
          ..write(jsonEncode(keys[i]))
          ..write(':')
          ..write(canonicalJson(value[keys[i]]));
      }
      return (buffer..write('}')).toString();
    }
    if (value is List) {
      return '[${value.map(canonicalJson).join(',')}]';
    }
    return jsonEncode(value);
  }
}
