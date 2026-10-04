// 多语言沙箱离线校验工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/verify_sandbox_harness.dart
//
// 做的事情：完全按照 Android 原生层的方式组装沙箱 HTML（把运行时内联进
// 页面、把用户代码转义成 JS 字符串），写成临时文件后用无头 Edge 执行，
// 再比对输出。分两轮：
//   1. file:// 路径——与 App 内 WebView 的真实加载方式一致；
//   2. http:// 路径——用一个本地端口做对照，确认运行时不会偷偷联网。
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _browserCandidates = [
  r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
  r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
  r'C:\Program Files\Google\Chrome\Application\chrome.exe',
];

/// 一个待验证的用例。
class _SandboxCase {
  const _SandboxCase(
    this.language,
    this.code,
    this.expects, {
    this.checkNetwork = false,
  });

  final String language;
  final String code;
  final List<String> expects;

  /// 是否同时用 http:// 跑一遍，确认没有额外网络请求。
  final bool checkNetwork;
}

const _cases = <_SandboxCase>[
  _SandboxCase(
    'javascript',
    '''
const nums = [1, 2, 3, 4];
const total = nums.reduce((sum, n) => sum + n, 0);
console.log("total =", total);
console.log("squares =", nums.map((n) => n * n));
''',
    ['total = 10', 'squares = [1,4,9,16]'],
    checkNetwork: true,
  ),
  _SandboxCase(
    'javascript',
    '''
const obj = { a: 1 };
obj.b.c;
''',
    ['Error:'],
  ),
  _SandboxCase(
    'typescript',
    '''
interface Point { x: number; y: number }
function distance(p: Point): number {
  return Math.sqrt(p.x ** 2 + p.y ** 2);
}
enum Color { Red = 1, Green }
const names: string[] = ["甲", "乙"];
console.log("distance =", distance({ x: 3, y: 4 }));
console.log("enum =", Color[2]);
console.log("names =", names.join("-"));
''',
    ['distance = 5', 'enum = Green', 'names = 甲-乙'],
    checkNetwork: true,
  ),
  _SandboxCase(
    'typescript',
    '''
const value: number = 1;
value.;
''',
    ['Error:'],
  ),
  _SandboxCase(
    'typescript',
    '''
import fs from "fs";
console.log(fs);
''',
    ['沙箱内不支持导入模块'],
  ),
  _SandboxCase(
    'python',
    '''
import math
print("pi =", round(math.pi, 3))
for i in range(3):
    print("i =", i)
print([x * x for x in range(5)])
''',
    ['pi = 3.142', 'i = 2', '[0, 1, 4, 9, 16]'],
    checkNetwork: true,
  ),
  _SandboxCase(
    'python',
    '''
print(1 / 0)
''',
    ['ZeroDivisionError'],
  ),
  _SandboxCase(
    'python',
    '''
import json
import random
import datetime
import collections
import re
random.seed(7)
data = {"b": 2, "a": [1, 2, 3]}
print(json.dumps(data, ensure_ascii=False, sort_keys=True))
print(collections.Counter("abracadabra")["a"])
print(bool(re.match(r"\\d{3}", "123abc")))
print(datetime.date(2024, 1, 1).year)
''',
    ['{"a": [1, 2, 3], "b": 2}', '5', 'True', '2024'],
    checkNetwork: true,
  ),
  _SandboxCase(
    'lua',
    '''
local function fib(n)
  if n < 2 then return n end
  return fib(n - 1) + fib(n - 2)
end
print("fib(10) =", fib(10))
local t = {}
for i = 1, 3 do t[i] = i * i end
print("table =", t[1], t[2], t[3])
''',
    ['fib(10) =\t55', 'table =\t1\t4\t9'],
    checkNetwork: true,
  ),
  _SandboxCase(
    'lua',
    '''
print(nil + 1)
''',
    ['Error:', 'arithmetic'],
  ),
  _SandboxCase(
    'sql',
    '''
CREATE TABLE student (id INTEGER PRIMARY KEY, name TEXT, score REAL);
INSERT INTO student (name, score) VALUES ('小明', 92.5), ('小红', 88);
SELECT id, name, score FROM student ORDER BY score DESC;
''',
    ['id | name | score', '小明', '92.5'],
    checkNetwork: true,
  ),
  _SandboxCase(
    'sql',
    '''
SELECT * FROM missing_table;
''',
    ['Error:', 'missing_table'],
  ),
  _SandboxCase(
    'json',
    '''
{"name": "小明", "skills": ["Python", "SQL"], "age": 18}
''',
    ['"name": "小明"', '"skills"', '"age": 18'],
    checkNetwork: true,
  ),
  _SandboxCase(
    'json',
    '''
{name: 1}
''',
    ['Error:'],
  ),
];

/// 语言 -> 需要内联的运行时文件（相对 assets/sandbox）。
const _runtimes = <String, List<String>>{
  'javascript': [],
  'typescript': ['sucrase/sucrase.bundle.js'],
  'python': ['brython/brython.js', 'brython/brython_stdlib.js'],
  'lua': ['fengari/fengari-web.bundle.js'],
  'sql': ['sqljs/sql-wasm.js', 'sqljs/sql-wasm-binary.js'],
  'json': [],
};

/// 按原生层的规则组装页面：先内联运行时，再替换用户代码（避免代码里出现标记时误替换）。
String assembleHarness({
  required String harness,
  required String common,
  required List<String> runtimes,
  required String userCode,
}) {
  var html = harness;
  for (var i = 0; i < runtimes.length; i++) {
    final marker = '/*__RUNTIME_${i + 1}__*/';
    if (!html.contains(marker)) {
      throw StateError('模板缺少标记 $marker');
    }
    html = html.replaceFirst(marker, escapeInlineScript(runtimes[i]));
  }
  if (!html.contains('/*__COMMON__*/')) {
    throw StateError('模板缺少标记 /*__COMMON__*/');
  }
  html = html.replaceFirst('/*__COMMON__*/', escapeInlineScript(common));
  if (!html.contains('__USER_CODE__')) {
    throw StateError('模板缺少标记 __USER_CODE__');
  }
  return html.replaceFirst('__USER_CODE__', encodeJsString(userCode));
}

/// 内联脚本里出现 </script 会提前结束 script 标签，需要转义（JS 里含义不变）。
String escapeInlineScript(String source) =>
    source.replaceAll('</script', r'<\/script');

/// 把用户代码转成 JS 字符串字面量：先做 JSON 编码，再处理 </script 与行分隔符。
String encodeJsString(String code) =>
    jsonEncode(code)
        .replaceAll('</script', r'<\/script')
        .replaceAll('\u2028', r'\u2028')
        .replaceAll('\u2029', r'\u2029');

Future<void> main(List<String> args) async {
  final sandboxDir = Directory('${Directory.current.path}/assets/sandbox');
  if (!sandboxDir.existsSync()) {
    stderr.writeln('找不到 assets/sandbox，请在项目根目录执行。');
    exitCode = 1;
    return;
  }
  final browser = _resolveBrowser();
  if (browser.isEmpty) {
    stderr.writeln('未找到 Edge/Chrome，无法执行校验。');
    exitCode = 1;
    return;
  }

  final common = File('${sandboxDir.path}/harness/common.js')
      .readAsStringSync();
  final runtimeCache = <String, String>{};
  String runtime(String relative) => runtimeCache.putIfAbsent(
    relative,
    () => File('${sandboxDir.path}/$relative').readAsStringSync(),
  );

  final workDir = Directory.systemTemp.createTempSync('sandbox_verify_');
  final profileDir = Directory.systemTemp.createTempSync('sandbox_profile_');
  final fileUris = <String>[];
  final pages = <String, String>{};
  final sizes = <String, int>{};
  for (var i = 0; i < _cases.length; i++) {
    final item = _cases[i];
    final harness = File('${sandboxDir.path}/harness/${item.language}.html')
        .readAsStringSync();
    final html = assembleHarness(
      harness: harness,
      common: common,
      runtimes: (_runtimes[item.language] ?? const []).map(runtime).toList(),
      userCode: item.code,
    );
    final file = File('${workDir.path}/${item.language}_$i.html')
      ..writeAsStringSync(html);
    fileUris.add(file.uri.toString());
    pages['/${item.language}$i'] = html;
    sizes[item.language] = html.length;
  }

  var failures = 0;

  // ① file:// 路径：和 App 内 WebView 的加载方式一致。
  stdout.writeln('== file:// 路径（与 App 内一致）==');
  for (var i = 0; i < _cases.length; i++) {
    final item = _cases[i];
    final output = await _runHeadless(
      browser: browser,
      url: fileUris[i],
      profileDir: profileDir.path,
    );
    failures += _report('${item.language} #$i', item, output);
  }

  // ② http:// 路径：确认运行时不会额外联网。
  stdout.writeln('== http:// 路径（检查额外网络请求）==');
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final extraRequests = <String>[];
  unawaited(() async {
    await for (final request in server) {
      final page = pages[request.uri.path];
      if (page == null) {
        // favicon 是浏览器自动请求，不算沙箱行为。
        if (request.uri.path != '/favicon.ico') {
          extraRequests.add(request.uri.toString());
        }
        request.response.statusCode = HttpStatus.notFound;
      } else {
        request.response.headers.contentType = ContentType(
          'text',
          'html',
          charset: 'utf-8',
        );
        request.response.write(page);
      }
      await request.response.close();
    }
  }());
  for (var i = 0; i < _cases.length; i++) {
    final item = _cases[i];
    if (!item.checkNetwork) continue;
    extraRequests.clear();
    final output = await _runHeadless(
      browser: browser,
      url: 'http://127.0.0.1:${server.port}/${item.language}$i',
      profileDir: profileDir.path,
    );
    failures += _report('${item.language} #$i（联网检查）', item, output);
    if (extraRequests.isNotEmpty) {
      stdout.writeln('  额外网络请求：${extraRequests.join(' / ')}');
      failures++;
    }
  }
  await server.close(force: true);

  stdout.writeln(
    '页面大小：${sizes.entries.map((e) => '${e.key} ${(e.value / 1024).round()} KB').join('，')}',
  );
  stdout.writeln(
    '共 ${_cases.length * 1 + _cases.where((c) => c.checkNetwork).length} 次执行，失败 $failures 个。',
  );
  _cleanup(workDir);
  _cleanup(profileDir);
  if (failures > 0) exitCode = 1;
}

String _resolveBrowser() {
  final explicit = Platform.environment['CHROME_EXECUTABLE']?.trim();
  if (explicit != null && explicit.isNotEmpty && File(explicit).existsSync()) {
    return explicit;
  }
  for (final path in _browserCandidates) {
    if (File(path).existsSync()) return path;
  }
  if (!Platform.isWindows) {
    for (final executable in const [
      'google-chrome',
      'chromium',
      'chromium-browser',
    ]) {
      final result = Process.runSync('which', <String>[executable]);
      final path = result.stdout.toString().trim();
      if (result.exitCode == 0 && path.isNotEmpty && File(path).existsSync()) {
        return path;
      }
    }
  }
  return '';
}

int _report(String title, _SandboxCase item, String output) {
  final missing = item.expects.where((text) => !output.contains(text)).toList();
  if (missing.isEmpty) {
    stdout.writeln('通过  $title');
    return 0;
  }
  stdout.writeln('失败  $title');
  stdout.writeln('  期望包含：${item.expects.join(' / ')}');
  stdout.writeln('  实际输出：');
  for (final line in output.split('\n')) {
    stdout.writeln('    $line');
  }
  return 1;
}

void _cleanup(Directory dir) {
  try {
    dir.deleteSync(recursive: true);
  } catch (_) {
    // 无头浏览器可能仍占用临时目录，忽略清理失败。
  }
}

Future<String> _runHeadless({
  required String browser,
  required String url,
  required String profileDir,
}) async {
  final result = await Process.run(
    browser,
    [
      '--headless=new',
      '--disable-gpu',
      '--no-first-run',
      '--no-proxy-server',
      '--user-data-dir=$profileDir',
      '--virtual-time-budget=20000',
      '--dump-dom',
      url,
    ],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  final dom = result.stdout.toString();
  final match = RegExp(r'<pre id="sandbox-output"[^>]*>([\s\S]*?)</pre>')
      .firstMatch(dom);
  if (match == null) {
    return '(未取到输出节点)\n$dom';
  }
  return _unescapeHtml(match.group(1) ?? '').trim();
}

String _unescapeHtml(String text) => text
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&');
