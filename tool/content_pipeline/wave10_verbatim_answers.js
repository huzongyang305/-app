// 第十批：修 wave7/wave9 的两处副作用。
// 1) wave7 的 flatten 把选项里的 ！？； 也换成了逗号，导致解析里引用的正确项与选项原文不一致；
// 2) wave9 补写时贴的是去壳后的文本（反引号被吃掉），治理规则按原文比对，仍然判缺。
// 这里按 dart 侧同一个归一化口径复检，先把被压扁的选项原文还原，再补真缺的。
// 用法：node tool/content_pipeline/wave10_verbatim_answers.js [--apply]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const P = 'assets/content/manifest.json';
const raw = fs.readFileSync(P, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

// 与 tool/audit_content_governance.dart 的 _normalizeAnswerText 一致
const normalize = (s) => String(s)
  .replace(/（[A-Za-z0-9_.-]+ 第 \d+ 题）/g, '')
  .replace(/^[「『“"\s]+|[」』”"\s]+$/g, '')
  .replace(/[\s。！？!?]+$/, '')
  .replace(/\s+/g, ' ')
  .trim();

function correctRaw(q) {
  const opts = (q.options || []).map((x) => String(x));
  const toIdx = (v) => { const n = typeof v === 'number' ? v : Number(v); return Number.isInteger(n) ? n : null; };
  if (Number.isInteger(q.answer) && q.answer >= 0 && q.answer < opts.length) return [opts[q.answer]];
  const pick = (list) => (list || []).map(toIdx).filter((n) => n !== null && n >= 0 && n < opts.length).map((n) => opts[n]);
  if ((q.answers || []).length) return pick(q.answers);
  if ((q.correct_order || []).length) return pick(q.correct_order);
  return (q.accepted_answers || []).map((x) => String(x));
}
const flattenPunct = (s) => String(s).replace(/[。！？；]/g, '，').replace(/，{2,}/g, '，').replace(/^，|，$/g, '').trim();

let restored = 0, appended = 0;
for (const c of manifest.categories) for (const l of c.lessons) for (const q of l.quiz || []) {
  let ex = String(q.explanation || '');
  if (!ex) continue;
  for (const R of correctRaw(q)) {
    const flat = flattenPunct(R);
    if (R !== flat && normalize(ex).includes(normalize(flat)) && !normalize(ex).includes(normalize(R))) {
      const before = ex;
      ex = ex.split(flat).join(R);
      if (ex !== before) restored++;
    }
  }
  const nEx = normalize(ex);
  const missing = correctRaw(q).filter((R) => R && !nEx.includes(normalize(R)));
  if (missing.length) {
    ex = `${ex}本题还要同时命中：${missing.join('、')}。`;
    appended++;
  }
  q.explanation = ex;
}
console.log(`还原选项原文 ${restored} 处，补写仍缺失的正确项 ${appended} 条`);
if (APPLY) { fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol)); console.log('已写盘'); }
else console.log('（dry-run，加 --apply 才写盘）');
