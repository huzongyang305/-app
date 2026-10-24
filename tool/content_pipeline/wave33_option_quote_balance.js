// wave33：补回选项文案里丢掉的右引号「」。
//
// 抽检 wave32 时发现 requirements_modeling 与 se_tech_debt 各有一条选项写成
// 「作为<角色>，我想要<目标>（左引号有、右引号没有）。选项进解析、进课文之后，
// 整条解析的「」就不成对：断句器把后面所有句子当成一个引号跨度，长度与重复检查都会被掩盖。
// 这里把选项补成对，并把解析、课文里引用这段文案的地方一起补上右引号。
// 用法：node tool/content_pipeline/wave33_option_quote_balance.js [--apply] [--show]
import fs from 'node:fs';
import path from 'node:path';

const ROOT = 'F:/app';
const MANIFEST = path.join(ROOT, 'assets/content/manifest.json');
const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');

const raw = fs.readFileSync(MANIFEST, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

const broken = (s) => String(s || '').startsWith('「') && !String(s || '').endsWith('」');
const escape = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
/** 只补那些后面没跟右引号的出现，免得把本来就成对的那份加成「」」 */
const closeAfter = (text, phrase) =>
  text.replace(new RegExp(`${escape(phrase)}(?!」)`, 'g'), `${phrase}」`);
const stats = { options: 0, explanations: 0, files: 0 };
const perFile = new Map();

for (const category of manifest.categories) {
  for (const lesson of category.lessons || []) {
    const edits = [];
    for (const q of lesson.quiz || []) {
      for (let oi = 0; oi < (q.options || []).length; oi++) {
        const text = String(q.options[oi]);
        if (!broken(text)) continue;
        q.options[oi] = `${text}」`;
        stats.options++;
        const before = String(q.explanation || '');
        const next = closeAfter(before, text);
        if (next !== before) {
          q.explanation = next;
          stats.explanations++;
        }
        edits.push(text);
      }
      // 题干里引用同一段文案时也要成对
      const stem = String(q.question || '');
      const stemFix = edits.reduce((acc, t) => closeAfter(acc, t), stem);
      if (stemFix !== stem) q.question = stemFix;
    }
    if (!edits.length || !lesson.file) continue;
    const file = path.join(ROOT, lesson.file);
    if (!fs.existsSync(file)) continue;
    const text = fs.readFileSync(file, 'utf8');
    const nl = text.includes('\r\n') ? '\r\n' : '\n';
    const plain = text.replace(/\r\n/g, '\n');
    const out = edits.reduce((acc, t) => closeAfter(acc, t), plain);
    if (out !== plain) {
      stats.files++;
      perFile.set(file, { out, nl });
    }
  }
}

if (SHOW) {
  for (const [file] of perFile) console.log(`课文 ${path.relative(ROOT, file)}`);
}
console.log(`补右引号：选项 ${stats.options}｜解析 ${stats.explanations}｜课文文件 ${stats.files}`);
if (APPLY) {
  fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  for (const [file, { out, nl }] of perFile) fs.writeFileSync(file, out.split('\n').join(nl));
  console.log('已写盘');
} else console.log('（dry-run，加 --apply 才写盘）');
