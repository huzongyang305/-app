const fs = require('fs');
const path = require('path');
const DIR = 'F:/app/assets/content';
const MANIFEST = JSON.parse(fs.readFileSync(process.argv[3] || path.join(DIR, 'manifest.json'), 'utf8'));
const SCHEDULE = JSON.parse(fs.readFileSync('F:/app/docs/content_review_schedule.json', 'utf8'));
const planned = {};
for (const b of SCHEDULE.batches) for (const id of b.lesson_ids) planned[id] = b.planned_review_at;
const norm = (s) => String(s).replace(/\s+/g, '');
const FENCE = String.fromCharCode(96, 96, 96);
const CANON = ['本节知识框架', '核心概念定义', '原理与运行机制', '典型应用场景', '代码/协议/SQL 示例', '时间/空间复杂度或性能分析', '常见误区与易错点', '与其他知识点的关系', '自测题与参考答案', '考点精讲', '术语速查', '参考资料与复核', '内容元数据'];
const LEGACY = ['常见错误对照表', '常见错误', '常见错误速查', '常见误区', '常见坑', '常见陷阱', '常见问题', '常见问题与对策', '常见问题与排查顺序', '常见风险速查', '常见失败模式', '常见反模式速查', '反模式', '失败模式', '新手最容易踩的八个坑', '新手最容易踩的六个坑', '必须注意的坑', '五个高频坑', '三个经典坑', '易错点回顾', '自测清单', '逐节复习与自检', '深度追问与自测', '本课自测清单与错误对照', '实践任务'];
const MD_MARKERS = ['先自己作答，再看「判断依据」', '**迁移检查**', '本课在「', '本课还在「', '本课在核心知识', '本课还在核心知识', '课程摘要指出', '回到正文对应章节补足概念', '把题干里的一个条件换成边界值', '把现象和原因写在一起', '错误信息通常会指出出错行和期望符号'];
const EX_MARKERS = ['这道题对应的课程', '修正后要重跑', '本课在「', '本课还在「', '本课把「', '本课在核心知识', '本课还在核心知识', '对照「', '课程摘要'];

function mask(md) {
  let f = false;
  return md.split('\n').map((l) => {
    if (l.trimLeft().startsWith(FENCE)) { f = !f; return ' '.repeat(l.length); }
    return f ? ' '.repeat(l.length) : l;
  });
}
function sectionOf(lines, title) {
  const re = new RegExp('^##\\s*' + title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\s*$');
  const s = lines.findIndex((l) => re.test(l));
  if (s < 0) return '';
  let e = lines.length;
  for (let i = s + 1; i < lines.length; i++) if (/^##\s/.test(lines[i])) { e = i; break; }
  return lines.slice(s, e).join('\n');
}

const target = process.argv[2];
const allStems = new Map();
const catRefs = new Map();
let found = null;
for (const c of MANIFEST.categories) {
  for (const l of c.lessons) {
    for (const q of l.quiz || []) {
      const k = norm(q.question);
      if (!allStems.has(k)) allStems.set(k, []);
      allStems.get(k).push(l.id);
    }
    if (l.id === target) found = { c, l };
  }
}
if (!found) { console.log('LESSON NOT FOUND: ' + target); process.exit(1); }
const { c, l } = found;
const p = path.isAbsolute(l.file) ? l.file : path.join('F:/app', l.file);
const errs = [];
if (!fs.existsSync(p)) { console.log('MISSING FILE ' + p); process.exit(1); }
const raw = fs.readFileSync(p, 'utf8');
const lines = mask(raw);
const checked = lines.join('\n');

if (raw.length < 6000) errs.push('too short: ' + raw.length);
const h1 = (raw.match(/^# (.+)$/m) || [])[1];
if (!h1 || h1.trim() !== ((l.title || {}).zh || '').trim()) errs.push('H1 mismatch: ' + h1 + ' vs ' + l.title.zh);
for (const t of CANON) {
  const n = lines.filter((x) => new RegExp('^##\\s*' + t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\s*$').test(x)).length;
  if (n !== 1) errs.push('canonical section ' + t + ' count=' + n);
}
for (const t of LEGACY) if (new RegExp('^##\\s*' + t + '\\s*$', 'm').test(checked)) errs.push('legacy heading ' + t);
if ((checked.match(/^- \[ \] /gm) || []).length < 3) errs.push('fewer than 3 checklist items');
const gloss = sectionOf(lines, '术语速查').split('\n').map((x) => x.trim()).filter((x) => x.startsWith('|'));
if (!gloss.length) errs.push('no glossary table');
else {
  if (gloss[0] !== '| 术语 | 一句话说明 |') errs.push('glossary header: ' + gloss[0]);
  if (gloss.length < 6) errs.push('glossary rows: ' + (gloss.length - 2));
  if (gloss.some((x) => x.includes('判断依据') || x.includes('正确答案是'))) errs.push('glossary has parsing residue');
}
const refs = sectionOf(lines, '参考资料与复核');
if (!refs.includes('- 最后复核：2026-10-04')) errs.push('missing 最后复核：2026-10-04');
const want = planned[l.id];
if (!want) errs.push('not in review schedule');
else if (!refs.includes('- 下次复核：' + want)) errs.push('下次复核 should be ' + want);
const refUrls = [...new Set([...refs.matchAll(/\[[^\]]+\]\((https?:\/\/[^)\s]+)\)/g)].map((m) => m[1]))].sort();
if (refUrls.length < 2) errs.push('reference section links: ' + refUrls.length);
if ((raw.match(/https?:\/\//g) || []).length < 2) errs.push('fewer than 2 http links in file');
if (/images\/[^)]+\.png/.test(raw)) errs.push('PNG reference');
if (!/!\[[^\]]*\]\(images\/[^)]+\.webp\)/.test(raw)) errs.push('no webp image');
const img = (raw.match(/!\[[^\]]*\]\((images\/[^)]+\.webp)\)/) || [])[1];
if (img && !fs.existsSync(path.join(DIR, img))) errs.push('image file missing: ' + img);
if (/\{off\[|\]\[index\]/.test(raw)) errs.push('template placeholder left');
if (/复核补充/.test(raw)) errs.push('复核补充 residue');
if (checked.includes('| 题目 | 容易踩的做法 | 正确结论 |')) errs.push('auto error table');
for (const m of MD_MARKERS) if (raw.includes(m)) errs.push('markdown template marker: ' + m);
if (/[（(]\s*[A-Za-z0-9_]+\s*第\s*\d+\s*题\s*[)]/.test(raw)) errs.push('internal question id in markdown');
// empty sections at any level (mirrors content_test.dart: headings only outside fences, body may be inside a fence)
const rawLines = raw.split('\n');
const heads = [];
let fenceFlag = false;
rawLines.forEach((x, i) => {
  if (x.trimLeft().startsWith(FENCE)) { fenceFlag = !fenceFlag; return; }
  if (fenceFlag) return;
  const m = /^(#{2,6})\s+(.*)$/.exec(x);
  if (m) heads.push([i, m[1].length, m[2].trim()]);
});
for (let k = 0; k < heads.length; k++) {
  let e = rawLines.length;
  for (let n = k + 1; n < heads.length; n++) if (heads[n][1] <= heads[k][1]) { e = heads[n][0]; break; }
  let has = false;
  for (let i = heads[k][0] + 1; i < e; i++) { const t = rawLines[i].trim(); if (t && !t.startsWith('#')) { has = true; break; } }
  if (!has) errs.push('empty section: ' + heads[k][2]);
}
// fences
let open = null, f = false, nonText = 0;
raw.split('\n').forEach((x, i) => {
  const t = x.trimLeft();
  if (!t.startsWith(FENCE)) return;
  if (!f) { f = true; const info = t.slice(3).trim(); if (!info) errs.push('bare fence at line ' + (i + 1)); else if (info !== 'text') nonText++; open = i; }
  else { f = false; open = null; }
});
if (f) errs.push('unclosed fence from line ' + (open + 1));
if (!nonText) errs.push('no non-text code fence');
// quiz coverage
for (let i = 0; i < (l.quiz || []).length; i++) {
  const q = l.quiz[i];
  const blob = JSON.stringify(q);
  if (blob.includes('本课主题')) errs.push('quiz#' + (i + 1) + ' placeholder title');
  if (/[（(]\s*[A-Za-z0-9_]+\s*第\s*\d+\s*题\s*[)]/.test(blob)) errs.push('quiz#' + (i + 1) + ' internal id');
  if (String(q.question).includes('…')) errs.push('quiz#' + (i + 1) + ' truncated stem');
  if (String(q.explanation || '').length < 120) errs.push('quiz#' + (i + 1) + ' explanation <120: ' + String(q.explanation || '').length);
  for (const m of EX_MARKERS) if (String(q.explanation || '').includes(m)) errs.push('quiz#' + (i + 1) + ' explanation marker ' + m);
  if (!norm(raw).includes(norm(q.question))) errs.push('quiz#' + (i + 1) + ' stem not in markdown');
  const type = q.type || 'single';
  const multi = q.answers || q.answer_indexes || q.correct_indexes || [];
  if (type === 'single' && (typeof q.answer !== 'number' || q.answer < 0 || q.answer >= (q.options || []).length)) errs.push('quiz#' + (i + 1) + ' bad answer index');
  if (type === 'multi' && multi.length < 2) errs.push('quiz#' + (i + 1) + ' multi needs >=2');
  if (type === 'fill' && !(q.accepted_answers || []).length) errs.push('quiz#' + (i + 1) + ' fill needs accepted_answers');
  if (type === 'order' && (q.correct_order || []).length !== (q.options || []).length) errs.push('quiz#' + (i + 1) + ' order mismatch');
  const dup = allStems.get(norm(q.question)) || [];
  if (dup.length > 1) errs.push('quiz#' + (i + 1) + ' stem duplicated with ' + dup.join(','));
}
// per-category reference signature uniqueness
for (const other of c.lessons) {
  if (other.id === l.id) continue;
  const op = path.join('F:/app', other.file);
  if (!fs.existsSync(op)) continue;
  const oref = sectionOf(mask(fs.readFileSync(op, 'utf8')), '参考资料与复核');
  const ours = [...new Set([...oref.matchAll(/\[[^\]]+\]\((https?:\/\/[^)\s]+)\)/g)].map((m) => m[1]))].sort().join('\n');
  if (ours === refUrls.join('\n')) errs.push('same reference link set as ' + other.id);
}
console.log(errs.length ? 'FAIL ' + l.id + '\n  ' + errs.join('\n  ') : 'OK ' + l.id + ' (' + raw.length + ' chars, ' + (l.quiz || []).length + ' questions)');
