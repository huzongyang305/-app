// 第 24 波：把单选/填空题里的「本题还要同时命中X这条」改成单选口径。
//
// 早期给解析补「复述正确项」时，不分题型统一追加了这句尾。多选/排序题里「同时命中」是
// 对的（第 21 波已经把它们换成「本题要同时选中…」「本题顺序是…」），但单选、代码、
// 填空题留着这句会误导学习者以为一道单选题要点两个选项。这里按题型换成
// 「本题正确项是X。」/「本题要填的是X。」，选项原文一字不动，保证「解析复述正确项」的硬指标仍成立。
// 用法：node tool/content_pipeline/wave24_single_answer_phrase.js [--apply] [--show]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const P = 'assets/content/manifest.json';
const raw = fs.readFileSync(P, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

const MARK = '本题还要同时命中';
const isMultiOrder = (q) =>
  (Array.isArray(q.answers) && q.answers.length > 1) ||
  q.type === 'order' ||
  (Array.isArray(q.correct_order) && q.correct_order.length > 1);

let fixed = 0, kept = 0, rejected = 0;
const samples = [];

for (const c of manifest.categories) {
  for (const l of c.lessons || []) {
    for (const q of l.quiz || []) {
      if (typeof q.explanation !== 'string' || !q.explanation.includes(MARK)) continue;
      // 多选/排序题保留「同时命中」口径。
      if (isMultiOrder(q)) { kept++; continue; }

      const from = q.explanation.indexOf(MARK) + MARK.length;
      const tail = q.explanation.slice(from);
      const at = tail.indexOf('这条');
      if (at < 0) { rejected++; continue; }
      const phrase = tail.slice(0, at).replace(/[，、；;,\s]+$/, '');
      if (!phrase) { rejected++; continue; }

      const lead = q.type === 'fill' ? '本题要填的是' : '本题正确项是';
      const head = q.explanation.slice(0, from - MARK.length);
      // 句尾「这条」后面还挂着内容时一并接上，避免截断。
      const rest = tail.slice(at + 2).replace(/^。/, '');
      let next = `${head}${lead}${phrase}。${rest}`;
      next = next
        .replace(/[，、；]{2,}/g, '，')
        .replace(/。{2,}/g, '。')
        .replace(/，。/g, '。')
        .replace(/\s{2,}/g, ' ')
        .trim();

      // 硬指标守卫：长度门槛 + 必须仍复述正确项原文。
      const correct = (q.type === 'fill'
        ? (q.accepted_answers || [])
        : isMultiOrder(q) ? [] : [q.options?.[q.answer]]
      ).map((t) => String(t || '').replace(/[\s，、；;：:。.．]/g, '')).filter(Boolean);
      const flat = next.replace(/[\s，、；;：:。.．]/g, '');
      if (next.length < 120 || (correct.length && !correct.some((t) => flat.includes(t)))) {
        rejected++;
        continue;
      }

      q.explanation = next;
      fixed++;
      if (SHOW && samples.length < 10) samples.push(`${l.id}｜${lead}：${phrase.slice(0, 40)}`);
    }
  }
}

console.log(`改写单选口径尾句 ${fixed} 条，多选/排序保留 ${kept} 条，守卫退回 ${rejected} 条`);
if (samples.length) console.log(samples.join('\n'));
if (APPLY) {
  fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('已写盘');
} else console.log('（dry-run，加 --apply 才写盘）');
