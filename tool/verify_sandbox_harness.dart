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
    this.stdin = '',
    this.checkNetwork = false,
  });

  final String language;
  final String code;
  final List<String> expects;

  /// 沙箱 stdin 输入框内容，按行拆分后注入页面。
  final String stdin;

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
  // 输出上限：超过 2000 行时必须截断并给出明确提示，避免打满内存。
  _SandboxCase(
    'javascript',
    '''
for (let i = 0; i < 3000; i++) console.log("line " + i);
''',
    ['line 0', '输出已截断'],
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
  // —— 1.3 新增语言与标准输入 ——
  _SandboxCase(
    'javascript',
    '''
const name = readLine();
const age = Number(readLine());
console.log("name =", name);
console.log("next year =", age + 1);
''',
    ['name = 小明', 'next year = 18'],
    stdin: '小明\n17',
    checkNetwork: true,
  ),
  _SandboxCase(
    'python',
    '''
name = input()
age = int(input())
print("name =", name)
print("next year =", age + 1)
''',
    ['name = 小明', 'next year = 18'],
    stdin: '小明\n17',
  ),
  _SandboxCase(
    'scheme',
    '''
(define (square x) (* x x))
(display "square(12) = ")
(display (square 12))
(newline)
(display (map square (list 1 2 3)))
''',
    ['square(12) = 144', '(1 4 9)'],
    checkNetwork: true,
  ),
  _SandboxCase('markdown', '# 标题\n\n- 一\n- 二\n\n**粗体** 与 `code`\n', [
    '标题 1 个',
    '<h1>标题</h1>',
    '<strong>粗体</strong>',
    '<ul>',
  ]),
  _SandboxCase('regex', '\\d{4}-\\d{2}-\\d{2}\ng\n订单 A: 2026-01-05 下单', [
    '匹配数量：1',
    '2026-01-05',
  ]),
  _SandboxCase(
    'xml',
    '<book id="1"><title>Flutter</title><price>42.5</price><tag>移动</tag><tag>跨平台</tag></book>',
    ['XML 格式正确', 'book', '跨平台'],
  ),
  _SandboxCase('csv', 'name,score\n"小,明",92\n小红,88\n', [
    '共 2 行数据 / 2 列：name | score',
    '小,明',
    '小红',
  ]),
  _SandboxCase(
    'cpp',
    '''
#include <stdio.h>

int main() {
    int a, b;
    scanf("%d %d", &a, &b);
    printf("%d + %d = %d\\n", a, b, a + b);
    return 0;
}
''',
    ['3 + 4 = 7'],
    stdin: '3 4',
    checkNetwork: true,
  ),
  _SandboxCase(
    'cpp',
    '''
#include <iostream>
using namespace std;

int fib(int n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }

int main() {
    for (int i = 0; i < 8; i++) cout << fib(i) << " ";
    cout << endl;
    return 0;
}
''',
    ['0 1 1 2 3 5 8 13'],
  ),
  _SandboxCase(
    'cpp',
    '''
#include <vector>
int main() { return 0; }
''',
    ['暂不支持', 'vector'],
  ),
  _SandboxCase(
    'bash',
    '''
#!/bin/bash
total=0
for i in 1 2 3 4 5; do
  total=\$((total + i))
done
echo "sum=\$total"
''',
    ['sum=15'],
    checkNetwork: true,
  ),
  _SandboxCase(
    'bash',
    '''
echo "banana apple cherry" | tr ' ' '\\n' | sort
''',
    ['apple', 'banana', 'cherry'],
  ),
  _SandboxCase(
    'bash',
    '''
python3 --version
echo "exit=\$?"
''',
    ['command not found', 'exit=127'],
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
  'scheme': ['biwascheme/biwascheme-min.js'],
  'markdown': [],
  'regex': [],
  'xml': [],
  'csv': [],
  'cpp': ['jscpp/jscpp.bundle.js'],
  'bash': ['bash/bashkit.bundle.js'],
};

/// 需要以 base64 注入页面的 WebAssembly 运行时（与 MainActivity 的 wasm 字段一致）。
const _wasmRuntimes = <String, String>{'bash': 'bash/bashkit.wasm'};

/// 按原生层的规则组装页面：先内联运行时，再替换用户代码（避免代码里出现标记时误替换）。
String assembleHarness({
  required String harness,
  required String common,
  required List<String> runtimes,
  required String userCode,
  String stdin = '',
  String wasmBase64 = '',
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
  // 标准输入按行注入公共脚本，规则与原生层保持一致。
  final commonContent = common.replaceAll(
    '__SANDBOX_STDIN_ARRAY__',
    encodeJsArray(stdinLines(stdin)),
  );
  html = html.replaceFirst('/*__COMMON__*/', escapeInlineScript(commonContent));
  if (!html.contains('__USER_CODE__')) {
    throw StateError('模板缺少标记 __USER_CODE__');
  }
  html = html.replaceFirst('__USER_CODE__', encodeJsString(userCode));
  if (html.contains('/*__WASM_BASE64__*/')) {
    if (wasmBase64.isEmpty) {
      throw StateError('模板需要 WebAssembly 运行时，但没有提供对应二进制');
    }
    html = html.replaceFirst(
      '/*__WASM_BASE64__*/',
      'window.__SANDBOX_WASM_BASE64__ = ${jsonEncode(wasmBase64)};',
    );
  }
  return html;
}

/// 标准输入按行拆分；空输入返回空列表（与 MainActivity.stdinLines 一致）。
List<String> stdinLines(String stdin) {
  if (stdin.isEmpty) return const [];
  return stdin.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
}

/// 把标准输入拼成 JS 数组字面量（与 MainActivity.encodeJsArray 一致）。
String encodeJsArray(List<String> lines) =>
    '[${lines.map(encodeJsString).join(',')}]';

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

  // 无头浏览器在 load 事件后立刻 dump DOM，而 WebAssembly 运行时首次编译需要数秒。
  // 这里让页面在加载时请求一个“慢响应”，把 load 事件推迟到编译完成之后。
  // 只影响离线校验：App 内的 WebView 不依赖 load 事件。
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final extraRequests = <String>[];
  unawaited(() async {
    await for (final request in server) {
      if (request.uri.path == '/__delay__') {
        await Future<void>.delayed(const Duration(seconds: 6));
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        continue;
      }
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

  final delayTag =
      '<img src="http://127.0.0.1:${server.port}/__delay__" alt="" '
      'style="display:none">';
  for (var i = 0; i < _cases.length; i++) {
    final item = _cases[i];
    final harness = File('${sandboxDir.path}/harness/${item.language}.html')
        .readAsStringSync();
    final wasmPath = _wasmRuntimes[item.language];
    final html = assembleHarness(
      harness: harness,
      common: common,
      runtimes: (_runtimes[item.language] ?? const []).map(runtime).toList(),
      userCode: item.code,
      stdin: item.stdin,
      wasmBase64: wasmPath == null
          ? ''
          : base64Encode(
              File('${sandboxDir.path}/$wasmPath').readAsBytesSync(),
            ),
    );
    // WASM 语言的首屏编译更慢，需要延时资源兜底。
    final fileHtml = _wasmRuntimes.containsKey(item.language)
        ? html.replaceFirst('<body>', '<body>\n$delayTag')
        : html;
    final file = File('${workDir.path}/${item.language}_$i.html')
      ..writeAsStringSync(fileHtml);
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
      expects: item.expects,
    );
    failures += _report('${item.language} #$i', item, output);
  }

  // ② http:// 路径：确认运行时不会额外联网。
  stdout.writeln('== http:// 路径（检查额外网络请求）==');
  for (var i = 0; i < _cases.length; i++) {
    final item = _cases[i];
    if (!item.checkNetwork) continue;
    extraRequests.clear();
    final output = await _runHeadless(
      browser: browser,
      url: 'http://127.0.0.1:${server.port}/${item.language}$i',
      profileDir: profileDir.path,
      expects: item.expects,
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

/// 无头浏览器执行一次并解析输出节点。
///
/// 返回的第二项表示本次输出是否已包含全部期望文本，调用方据此决定是否重试。
Future<({String output, bool complete})> _runHeadlessOnce({
  required String browser,
  required String url,
  required String profileDir,
  required List<String> expects,
}) async {
  final result = await Process.run(
    browser,
    [
      '--headless=new',
      '--disable-gpu',
      '--no-first-run',
      '--no-proxy-server',
      '--user-data-dir=$profileDir',
      // sql.js 等 WASM 运行时首次加载较慢，给足虚拟时间预算。
      '--virtual-time-budget=30000',
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
    final stderr = result.stderr.toString().trim();
    final detail = StringBuffer('(未取到输出节点)');
    if (stderr.isNotEmpty) detail.write('\nstderr: $stderr');
    if (dom.isNotEmpty) detail.write('\n$dom');
    return (output: detail.toString(), complete: false);
  }
  final output = _unescapeHtml(match.group(1) ?? '').trim();
  final complete = expects.every(output.contains);
  return (output: output, complete: complete);
}

/// 执行无头浏览器校验，对 WASM/运行时首次加载的时序抖动做有限重试。
Future<String> _runHeadless({
  required String browser,
  required String url,
  required String profileDir,
  required List<String> expects,
}) async {
  const maxAttempts = 3;
  String last = '';
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    final outcome = await _runHeadlessOnce(
      browser: browser,
      url: url,
      profileDir: profileDir,
      expects: expects,
    );
    last = outcome.output;
    if (outcome.complete) return last;
    if (attempt < maxAttempts) {
      // 首次加载 sql.js 等大体积运行时可能来不及写入输出节点，稍后重试。
      await Future<void>.delayed(Duration(milliseconds: 1200 * attempt));
    }
  }
  return last;
}

String _unescapeHtml(String text) => text
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&');
