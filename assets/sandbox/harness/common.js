// 各语言沙箱共用的输出收集脚本。
//
// 约定：
//   1. 运行前调用 __sandboxBegin() 开始捕获输出；
//   2. 结束时调用 __sandboxFinish()，把文本回传给 Android 的 SandboxBridge；
//   3. 页面里的 <pre id="sandbox-output"> 会同步写入结果，便于排查问题。
(function () {
  var logs = (window.__sandboxLogs = []);
  var loadErrors = (window.__sandboxLoadErrors = []);
  var capturing = false;
  var finished = false;

  // 输出上限：死循环或疯狂打印时，避免把 WebView 的内存吃满。
  var MAX_LINES = 2000;
  var MAX_CHARS = 200000;
  var totalChars = 0;
  var droppedLines = 0;

  function stringify(value) {
    try {
      if (typeof value === 'string') return value;
      if (typeof value === 'undefined') return 'undefined';
      if (value === null) return 'null';
      if (typeof value === 'bigint') return String(value) + 'n';
      if (value instanceof Error) return value.stack || String(value);
      if (typeof Uint8Array !== 'undefined' && value instanceof Uint8Array) {
        return 'Uint8Array(' + value.length + ')';
      }
      return JSON.stringify(value);
    } catch (error) {
      return String(value);
    }
  }

  function push(line) {
    var text = String(line);
    // 结构化表格标记由运行时按行数上限自行收敛，不参与文本输出上限，
    // 否则用户先打印大量日志时会把表格数据截断，界面就退化成了纯文本。
    if (text.indexOf('##SANDBOX_TABLE##') === 0) {
      logs.push(text);
      return;
    }
    if (logs.length >= MAX_LINES || totalChars >= MAX_CHARS) {
      droppedLines++;
      return;
    }
    var room = MAX_CHARS - totalChars;
    if (text.length > room) {
      text = text.slice(0, room) + '…（本行过长已截断）';
      droppedLines++;
    }
    totalChars += text.length + 1;
    logs.push(text);
  }

  window.__sandboxStringify = stringify;
  window.__sandboxPush = push;

  // 标准输入：原生层把用户在界面上填写的文本按行转换成 JS 数组字面量，
  // 直接替换下面的占位标记后再内联执行。
  var stdinLines = (__SANDBOX_STDIN_ARRAY__ || []).slice();
  window.__sandboxStdinRemaining = function () {
    return stdinLines.length;
  };
  window.__sandboxStdinLines = function () {
    return stdinLines.slice();
  };
  window.__sandboxReadLine = function (promptText) {
    if (promptText !== undefined && promptText !== null && promptText !== '') {
      push(String(promptText));
    }
    if (!stdinLines.length) return null;
    return stdinLines.shift();
  };
  window.__sandboxBegin = function () {
    capturing = true;
    // 运行时脚本在加载阶段报的错提前记下来，用户能看到明确原因。
    loadErrors.forEach(function (text) {
      push(text);
    });
    loadErrors.length = 0;
  };
  window.__sandboxFinish = function () {
    if (finished) return;
    finished = true;
    var text = logs.join('\n');
    if (droppedLines > 0) {
      var notice = '…… 输出已截断：还有 ' + droppedLines + ' 行未显示（上限 ' +
        MAX_LINES + ' 行 / ' + (MAX_CHARS / 1000) + ' 千字符）。';
      text = text ? text + '\n' + notice : notice;
    }
    var pre = document.getElementById('sandbox-output');
    if (pre) pre.textContent = text;
    try {
      SandboxBridge.onResult(text);
    } catch (error) {
      // 非 Android 环境（例如离线校验）没有注入桥接对象，忽略即可。
      document.title = 'SANDBOX_OUTPUT';
    }
  };

  // 运行时脚本在加载阶段可能打印调试信息，因此先装钩子、后开启捕获。
  ['log', 'info', 'warn', 'error'].forEach(function (name) {
    var original = console[name] ? console[name].bind(console) : function () {};
    var prefix = name === 'error' ? 'Error: ' : (name === 'warn' ? 'Warning: ' : '');
    console[name] = function () {
      var args = Array.prototype.slice.call(arguments);
      if (capturing) push(prefix + args.map(stringify).join(' '));
      if (name === 'error') original.apply(null, args);
    };
  });

  window.onerror = function (message, source, lineno, colno, error) {
    var text = 'Error: ' + (error && error.stack ? error.stack : message);
    if (!capturing) {
      loadErrors.push(text);
      return false;
    }
    push(text);
    window.__sandboxFinish();
    return true;
  };

  // 捕获阶段的 error 事件能拿到脚本/资源的加载失败（例如 WebView 版本过低）。
  window.addEventListener('error', function (event) {
    var target = event.target;
    if (!target || target === window) return;
    var name = target.src || target.href || target.tagName || '资源';
    var text = 'Error: 运行时加载失败：' + name;
    if (!capturing) {
      loadErrors.push(text);
      return;
    }
    push(text);
    window.__sandboxFinish();
  }, true);

  window.addEventListener('unhandledrejection', function (event) {
    if (!capturing) return;
    var reason = event.reason;
    push('Error: ' + (reason && reason.stack ? reason.stack : String(reason)));
    window.__sandboxFinish();
  });

  // 沙箱不联网，也不打包 node_modules，模块导入统一给出清晰提示。
  window.__sandboxRequire = function (name) {
    throw new Error('沙箱内不支持导入模块：' + name);
  };
})();
