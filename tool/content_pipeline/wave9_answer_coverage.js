// 第九批：补齐治理规则要的正确项，并修掉 flatten 造出的异常标点。
// 规则口径同 tool/audit_content_governance.dart：解析里必须出现每个正确答案片段。
// 用法：node tool/content_pipeline/wave9_answer_coverage.js [--apply]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const P = 'assets/content/manifest.json';
const raw = fs.readFileSync(P, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

// 与 dart 侧 _normalizeAnswerText 保持一致：去空白与结尾标点，保留内部逗号。
const normalize = (s) => String(s).replace(/[`*_]/g, '').replace(/[\s。！？!?]+$/, '').replace(/\s+/g, ' ').trim();

function correctParts(q) {
  const opts = (q.options || []).map((x) => String(x));
  const idx = (v) => (typeof v === 'number' ? v : intOrNull(v));
  function intOrNull(v) { const n = Number(v); return Number.isInteger(n) ? n : null; }
  if (Number.isInteger(q.answer) && q.answer >= 0 && q.answer < opts.length) return [opts[q.answer]];
  const picks = (list) => (list || []).map(idx).filter((n) => n !== null && n >= 0 && n < opts.length).map((n) => opts[n]);
  if ((q.answers || []).length) return picks(q.answers);
  if ((q.correct_order || []).length) return picks(q.correct_order);
  return (q.accepted_answers || []).map((x) => String(x));
}

let filled = 0, punctFixed = 0, stillMissing = 0;
for (const c of manifest.categories) for (const l of c.lessons) for (const q of l.quiz || []) {
  let ex = String(q.explanation || '');
  if (!ex) continue;
  const cleaned = ex.replace(/([。；，])\1+/g, '$1').replace(/。，/g, '。').replace(/，。/g, '。').replace(/…；/g, '…');
  if (cleaned !== ex) { punctFixed++; ex = cleaned; }
  const nEx = normalize(ex);
  const missing = correctParts(q).map(normalize).filter((v) => v && !nEx.includes(v));
  if (missing.length) {
    ex = `${ex}本题还要同时命中${missing.join('、')}这条。`;
    filled++;
  }
  q.explanation = ex;
}
console.log(`补写缺失正确项 ${filled} 条，修异常标点 ${punctFixed} 条，仍缺 ${stillMissing} 条`);
if (APPLY) { fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol)); console.log('已写盘'); }
else console.log('（dry-run，加 --apply 才写盘）');
