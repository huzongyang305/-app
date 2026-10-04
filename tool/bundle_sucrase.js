// 把 sucrase（CommonJS 版）打包成单文件，供 App 内置 TypeScript 沙箱使用。
//
// 用法（开发期，需本机 Node）：
//   node tool/bundle_sucrase.js <sucrase包目录>/dist/index.js <输出文件>
//
// 说明：sucrase 官方只提供 CommonJS / ESM 两种模块目录，浏览器里无法直接
// 用 <script src> 加载，这里用一个极小的 CommonJS 运行时把它合并成单文件，
// 体积约 400 KB，远小于 TypeScript 官方编译器的 9 MB。
const fs = require('fs');
const path = require('path');

const entryFile = process.argv[2];
const outFile = process.argv[3];
const globalName = process.argv[4] || 'Sucrase';

if (!entryFile || !outFile) {
  console.error('用法: node tool/bundle_sucrase.js <入口 index.js> <输出文件>');
  process.exit(1);
}

const modules = [];
const idByFile = new Map();
const externalRequests = new Set();

// 浏览器里不可用的 Node 依赖，用最小实现顶替。
// 这些模块只在「选项校验 / 生成 source map / 报错定位」等分支里用到，
// 沙箱用不到 source map，选项也是写死的，因此垫片足够。
const shims = {
  'ts-interface-checker': `
    // 宽松校验器：类型描述函数只返回占位对象，strictCheck/check/assert 一律通过。
    function typeStub() { return { __sandboxType: true }; }
    ['union', 'lit', 'enumlit', 'iface', 'array', 'opt', 'obj', 'dict', 'tuple',
     'rest', 'func', 'intersection', 'alias', 'exact'].forEach(function (name) {
      exports[name] = function () { return typeStub(); };
    });
    function makeChecker() {
      return {
        strictCheck: function () {},
        check: function () { return null; },
        assert: function () {},
      };
    }
    exports.createCheckers = function (spec) {
      var out = {};
      for (var key in spec) out[key] = makeChecker();
      return out;
    };
  `,
  '@jridgewell/gen-mapping': `
    // 沙箱不生成 source map，被调用时给出明确错误。
    function unsupported() {
      throw new Error('沙箱未内置 source map 支持');
    }
    exports.GenMapping = unsupported;
    exports.addMapping = unsupported;
    exports.addSegment = unsupported;
    exports.setSourceContent = unsupported;
    exports.toEncodedMap = unsupported;
    exports.toDecodedMap = unsupported;
  `,
  'lines-and-columns': `
    // 仅用于把字符下标换算成行列号，供语法错误提示使用。
    function LinesAndColumns(string) {
      this.lineStarts = [0];
      for (var i = 0; i < string.length; i++) {
        if (string.charCodeAt(i) === 10) this.lineStarts.push(i + 1);
      }
    }
    LinesAndColumns.prototype.locationForIndex = function (index) {
      var line = 0;
      while (line + 1 < this.lineStarts.length && this.lineStarts[line + 1] <= index) line++;
      return { line: line, column: index - this.lineStarts[line] };
    };
    LinesAndColumns.prototype.indexForLocation = function (location) {
      if (location.line >= this.lineStarts.length) return null;
      return this.lineStarts[location.line] + location.column;
    };
    exports.LinesAndColumns = LinesAndColumns;
    exports.default = LinesAndColumns;
  `,
};

const isVirtual = (file) => file.charCodeAt(0) === 0;

function resolveRequest(request, fromFile) {
  if (Object.prototype.hasOwnProperty.call(shims, request)) {
    return `\0${request}`;
  }
  if (!request.startsWith('.')) {
    // 非相对依赖只出现在生成的代码字符串里（例如 JSX 自动导入），
    // 不是真正的模块依赖，原样保留即可。
    externalRequests.add(`${request} @ ${path.basename(fromFile)}`);
    return null;
  }
  const base = path.resolve(path.dirname(fromFile), request);
  const candidates = [base, `${base}.js`, path.join(base, 'index.js')];
  for (const candidate of candidates) {
    if (fs.existsSync(candidate) && fs.statSync(candidate).isFile()) {
      return candidate;
    }
  }
  throw new Error(`无法解析依赖 ${request}（来自 ${fromFile}）`);
}

function addModule(file) {
  const absolute = isVirtual(file) ? file : path.resolve(file);
  if (idByFile.has(absolute)) return idByFile.get(absolute);
  const id = modules.length;
  idByFile.set(absolute, id);
  modules.push({ id, file: absolute, code: '' });
  const source = isVirtual(absolute)
    ? shims[absolute.slice(1)]
    : fs.readFileSync(absolute, 'utf8');
  const rewritten = source.replace(
    /require\(\s*(['"])([^'"]+)\1\s*\)/g,
    (match, _quote, request) => {
      const target = resolveRequest(request, absolute);
      if (target === null) return match;
      return `__require(${addModule(target)})`;
    },
  );
  modules[id].code = rewritten;
  return id;
}

const entryId = addModule(entryFile);

const body = modules
  .map((mod) => `${mod.id}:\nfunction(module, exports, __require) {\n${mod.code}\n}`)
  .join(',\n');

const bundle = `/* 由 tool/bundle_sucrase.js 生成，请勿手工修改。 */
(function() {
  var modules = {
${body}
  };
  var cache = {};
  function __require(id) {
    if (cache[id]) return cache[id].exports;
    var module = cache[id] = { exports: {} };
    modules[id](module, module.exports, __require);
    return module.exports;
  }
  var root = typeof self !== 'undefined' ? self : this;
  root.${globalName} = __require(${entryId});
})();
`;

fs.mkdirSync(path.dirname(path.resolve(outFile)), { recursive: true });
fs.writeFileSync(outFile, bundle, 'utf8');
console.log(
  `已生成 ${outFile}：${modules.length} 个模块，${(Buffer.byteLength(bundle) / 1024).toFixed(0)} KB`,
);
if (externalRequests.size > 0) {
  console.log(`跳过的非相对依赖：${[...externalRequests].join(', ')}`);
}
