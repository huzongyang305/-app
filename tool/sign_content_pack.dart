import 'dart:convert';
import 'dart:io';

import 'package:code_learn_app/services/content_pack_integrity.dart';

/// 为离线内容包写入 checksum 与 signature 字段。
///
/// 用法：
///   dart run tool/sign_content_pack.dart `pack.json` [输出文件]
///
/// 不传输出文件时原地更新。签名使用 App 内置的公开密钥，
/// 目的是发现传输损坏与意外篡改，而不是做版权保护。
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      '用法: dart run tool/sign_content_pack.dart <pack.json> [out.json]',
    );
    exitCode = 64;
    return;
  }

  final input = File(args.first);
  if (!input.existsSync()) {
    stderr.writeln('找不到文件: ${input.path}');
    exitCode = 66;
    return;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(input.readAsStringSync());
  } on FormatException catch (error) {
    stderr.writeln('JSON 解析失败: ${error.message}');
    exitCode = 65;
    return;
  }
  if (decoded is! Map) {
    stderr.writeln('内容包根节点必须是 JSON 对象');
    exitCode = 65;
    return;
  }

  final pack = decoded.cast<String, dynamic>();
  pack.remove('checksum');
  pack.remove('signature');
  pack['checksum'] = 'sha256:${ContentPackIntegrity.checksumOf(pack)}';
  pack['signature'] = ContentPackIntegrity.signWithKey(pack);

  final output = File(args.length > 1 ? args[1] : input.path);
  output.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(pack));
  stdout.writeln('已写入校验和与签名: ${output.path}');
  stdout.writeln('checksum = ${pack['checksum']}');
}
