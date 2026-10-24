// 第 18 波：修复 9 门 Java/JavaWeb 课里被双重转义的中文引号。
// 生成阶段把 “ ” 写成了字面量 “\u201C”“\u201D”，manifest 与课文里都存成了
// 反斜杠加 u201C 的文本，App 界面会直接显示这串转义码。只处理这四个码位，
// 其它 \uXXXX（代码示例里的合法转义）一律不动；代码围栏内的内容跳过。
// 用法：node tool/content_pipeline/wave18_unescape_quotes.js [--apply]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const MANIFEST = 'assets/content/manifest.json';
const CODE = /\\u201[Cc]|\\u201[Dd]/;
const SUBSTITUTE = (s) =>
  s.replace(/\\u201[Cc]/g, '“').replace(/\\u201[Dd]/g, '”');

let mdFiles = 0, mdLines = 0, fenceSkipped = 0;
for (const f of fs.readdirSync('assets/content')) {
  if (!f.endsWith('.md')) continue;
  const p = 'assets/content/' + f;
  const raw = fs.readFileSync(p, 'utf8');
  if (!CODE.test(raw)) continue;
  const eol = raw.includes('\r\n') ? '\r\n' : '\n';
  const lines = raw.split(/\r?\n/);
  let inFence = false, changed = 0;
  for (let i = 0; i < lines.length; i++) {
    if (/^\s*```/.test(lines[i])) { inFence = !inFence; continue; }
    if (!CODE.test(lines[i])) continue;
    if (inFence) { fenceSkipped++; continue; }
    lines[i] = SUBSTITUTE(lines[i]);
    changed++;
  }
  if (changed) {
    mdFiles++; mdLines += changed;
    if (APPLY) fs.writeFileSync(p, lines.join(eol));
  }
}

const mraw = fs.readFileSync(MANIFEST, 'utf8');
const eol = mraw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(mraw);
let fields = 0;
const walk = (v) => {
  if (typeof v === 'string') return;
  if (Array.isArray(v)) {
    for (let i = 0; i < v.length; i++) {
      const item = v[i];
      if (typeof item === 'string') {
        if (CODE.test(item)) { v[i] = SUBSTITUTE(item); fields++; }
      } else walk(item);
    }
    return;
  }
  if (!v || typeof v !== 'object') return;
  for (const k of Object.keys(v)) {
    const child = v[k];
    if (typeof child === 'string') {
      if (CODE.test(child)) { v[k] = SUBSTITUTE(child); fields++; }
    } else walk(child);
  }
};
for (const c of manifest.categories) {
  for (const l of c.lessons || []) walk(l);
}
console.log(`课文修复：${mdFiles} 个文件、${mdLines} 行（代码围栏内跳过 ${fenceSkipped} 行）；manifest 修复字段 ${fields} 个`);
if (APPLY) {
  fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('已写盘');
} else console.log('（dry-run，加 --apply 才写盘）');
