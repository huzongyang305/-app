// 多语言沙箱资源准备工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/prepare_sandbox.dart <npm_packages_root>
//
// 从已解压的 npm 包目录复制 Brython、Fengari、sql.js 运行时，
// 并把 sql.js 的 wasm 转成内联 base64，避免 WebView 的 file:// 限制。
//
// TypeScript 转译器（sucrase）需要先打包成单文件：
//   node tool/bundle_sucrase.js <sucrase包>/dist/index.js \
//     assets/sandbox/sucrase/sucrase.bundle.js
// 该文件已经在仓库里，除非升级 sucrase 版本，否则不用重新生成。
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('请传入 npm 包解压目录');
    exitCode = 1;
    return;
  }
  final root = Directory(args.first);
  final out = Directory('assets/sandbox');
  out.createSync(recursive: true);

  void copyPackageFile(String packageDir, String relative, String dest) {
    final source = File('${root.path}/$packageDir/package/$relative');
    if (!source.existsSync()) {
      throw StateError('缺少文件：${source.path}');
    }
    final target = File('${out.path}/$dest');
    target.parent.createSync(recursive: true);
    source.copySync(target.path);
    stdout.writeln('复制 $dest');
  }

  copyPackageFile('brython-3.14.3', 'brython.js', 'brython/brython.js');
  copyPackageFile(
    'brython-3.14.3',
    'brython_stdlib.js',
    'brython/brython_stdlib.js',
  );
  copyPackageFile(
    'fengari-web-0.1.4',
    'dist/fengari-web.bundle.js',
    'fengari/fengari-web.bundle.js',
  );
  copyPackageFile('sql.js-1.14.2', 'dist/sql-wasm.js', 'sqljs/sql-wasm.js');

  final sucraseBundle = File('${out.path}/sucrase/sucrase.bundle.js');
  if (!sucraseBundle.existsSync()) {
    throw StateError(
      '缺少 ${sucraseBundle.path}，请先运行 tool/bundle_sucrase.js 生成。',
    );
  }
  stdout.writeln('确认 sucrase/sucrase.bundle.js 已存在');

  final wasm = File('${root.path}/sql.js-1.14.2/package/dist/sql-wasm.wasm');
  final base64 = base64Encode(wasm.readAsBytesSync());
  File('${out.path}/sqljs/sql-wasm-binary.js')
      .writeAsStringSync('window.SQL_WASM_BASE64="$base64";\n');
  stdout.writeln('生成 sqljs/sql-wasm-binary.js');
}
