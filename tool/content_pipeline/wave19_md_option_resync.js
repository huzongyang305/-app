// 第 19 波：把课文里「考点精讲」的选项与解析同步到题库当前文案。
// 第 17 波与 rebalance_single_option_length.dart 改写了 manifest 里的选项文本（补长干扰项、
// 截短正确项），课文 markdown 的选项列表和 **详细解释：** 段仍是旧文案，学员在课文里看到的
// 选项会和答题时不一致。这里按题干匹配题块，只在旧新文案有明显前缀关系时替换，并守住 6000 字符下限。
// 用法：node tool/content_pipeline/wave19_md_option_resync.js [--apply] [--show]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const MANIFEST = 'assets/content/manifest.json';
const DIR = 'assets/content/';
const raw = fs.readFileSync(MANIFEST, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

const norm = (s) =>
  String(s).replace(/[\s\u3000]+/g, '').replace(/^[「『“"']+|[」』”"']+$/g, '').replace(/[*_`]/g, '').trim();

// 只有互为前缀（且公共前缀足够长）才认定是同一条文案的新旧版本，避免误伤别的列表。
function isSameLine(oldText, newText) {
  const a = norm(oldText);
  const b = norm(newText);
  if (!a || !b || a === b) return a === b;
  const shorter = a.length < b.length ? a : b;
  const longer = a.length < b.length ? b : a;
  return shorter.length >= 6 && longer.startsWith(shorter.slice(0, Math.max(6, shorter.length - 4)));
}

const OPTION = /^\s*([A-H])[.、]\s*(.+?)(\s*)$/;
// 课文选项行尾常带 ✅/❌ 标注答案，重写时必须原样保留。
const MARK = /\s*[✅❌✓×]+\s*$/;

let files = 0, optLines = 0, expHits = 0, expTouched = 0, inFence = false, skipped = [];
const GENERIC_CLAUSES = [
  '但这会带来额外的维护成本', '实际效果取决于具体实现', '但这会引入新的复杂度', '需要额外的验证与维护',
  '但它只覆盖了部分情况', '不过这需要额外的前提条件', '但它并不是通用的做法', '往往无法达到预期效果',
];
const report = [];

for (const c of manifest.categories) {
  for (const l of c.lessons || []) {
    const rel = String(l.file || l.id + '.md');
    const file = rel.startsWith(DIR) ? rel : DIR + rel;
    if (!fs.existsSync(file)) continue;
    const before = fs.readFileSync(file, 'utf8');
    if (!/考点|自测题/.test(before)) continue;
    const lines = before.split(/\r?\n/);
    let touched = 0, fileExp = 0;

    // 找出所有「连续选项行」区块，以及紧随其后的正确答案标记。
    for (let i = 0; i < lines.length; i++) {
      const m = OPTION.exec(lines[i]);
      if (!m || m[1] !== 'A') continue;
      let j = i;
      const run = [];
      while (j < lines.length) {
        const mm = OPTION.exec(lines[j]);
        if (!mm) break;
        const full = mm[2];
        const mark = (MARK.exec(full) || [''])[0];
        run.push({ line: j, letter: mm[1], text: full.replace(MARK, '').trim(), mark });
        j++;
      }
      if (run.length < 2 || j === i) { i = j; continue; }
      // 题干 = 选项块上方最近的非空、非标题、非分隔行
      let q = i - 1;
      while (q >= 0 && (/^\s*$/.test(lines[q]) || /^#{1,6}\s/.test(lines[q]) || /^\s*---\s*$/.test(lines[q]) || /^\*\*题目/.test(lines[q]))) q--;
      const stem = q >= 0 ? norm(lines[q].replace(/^[>：:\s]+/, '')) : '';
      if (stem.length < 8) { i = j; continue; }
      const quiz = (l.quiz || []).find((x) => {
        const nq = norm(x.question);
        return nq && (nq === stem || nq.startsWith(stem.slice(0, 20)) || stem.startsWith(nq.slice(0, 20)));
      });
      if (!quiz || !Array.isArray(quiz.options) || quiz.options.length !== run.length) { i = j; continue; }
      // 课文用 ✅ 标注答案时，标注位置必须与题库 answer 一致，否则说明这块匹配错了，整块跳过。
      const marked = run.findIndex((r) => /✅|✓/.test(r.mark));
      if (marked >= 0 && typeof quiz.answer === 'number' && marked !== quiz.answer) {
        skipped.push(`${l.id}：课文 ✅ 标在 ${run[marked].letter}，题库答案为 ${String.fromCharCode(65 + quiz.answer)}（跳过整块）`);
        i = j; continue;
      }
      for (let k = 0; k < run.length; k++) {
        const oldText = run[k].text.trim();
        const newText = String(quiz.options[k]).trim();
        if (oldText === newText || !isSameLine(oldText, newText)) continue;
        lines[run[k].line] = `${run[k].letter}. ${newText}${run[k].mark}  `;
        // 解析段里若原样引用了旧选项文案，一并替换。
        for (let p = j; p < Math.min(j + 12, lines.length); p++) {
          if (!/^\*\*(详细解释|参考答案|判断依据)/.test(lines[p])) continue;
          if (!lines[p].includes(oldText)) continue;
          lines[p] = lines[p].split(oldText).join(newText);
          expHits++;
        }
        touched++; optLines++;
        if (SHOW && report.length < 40) report.push(`${l.id}｜${oldText} → ${newText}`);
      }
      i = j;
    }

    // 课文的 **详细解释：** 段落里同样残留着从题库同步过去的通用填充句，一并删掉。
    inFence = false;
    for (let k = 0; k < lines.length; k++) {
      if (/^s*```/.test(lines[k])) { inFence = !inFence; continue; }
      if (inFence) continue;
      let text = lines[k];
      for (const clause of GENERIC_CLAUSES) {
        while (text.includes('，' + clause)) text = text.split('，' + clause).join('');
        while (text.includes(clause)) text = text.split(clause).join('');
      }
      if (text !== lines[k]) {
        lines[k] = text.replace(/[，、；]{2,}/g, '，').replace(/，。/g, '。').replace(/。{2,}/g, '。');
        fileExp++; expTouched++;
      }
    }
    if (!touched && !fileExp) continue;
    const next = lines.join(eol);
    if (next.replace(/\s/g, '').length < 6000) { skipped.push(`${l.id}（低于 6000 字符，保持原样）`); continue; }
    files++;
    if (APPLY) fs.writeFileSync(file, next);
  }
}

console.log(`同步课文选项：${optLines} 行（涉及 ${files} 个文件），解析同步 ${expHits} 段，删填充句 ${expTouched} 行`);
if (report.length) console.log(report.join('\n'));
if (skipped.length) console.log('因长度守卫跳过：' + skipped.join('、'));
if (!APPLY) console.log('（dry-run，加 --apply 才写盘）');
