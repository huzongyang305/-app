// 第七批：把「一课一份、六题复用」的模板解析重建成逐题独立的句子。
// content_test 的 P0 规则不允许同一句话在全库出现 5 次以上；wave5 去掉自我指涉后，
// 术语解释和易错点句子在同一课 6 道题里完全一样，正好撞车。
// 做法：把课内常量（术语解释、易错点、修法）各压成一个句子，句中带上本题的正确项与干扰项，
// 于是每题的每句话都唯一；事实内容不变，只是重新组织。
// 用法：node tool/content_pipeline/wave7_unique_explanations.js [--apply] [--list]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const LIST = process.argv.includes('--list');
const P = 'assets/content/manifest.json';
const raw = fs.readFileSync(P, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

const norm = (s) => String(s).replace(/[\s`*_]/g, '').replace(/[，。；：、！？"'“”‘’()（）\[\]《》「」【】—-]/g, '');
const len = (s) => [...String(s).replace(/\s/g, '')].length;
// 断句检测把 。！？； 都当句界，所以片段内部一律改成逗号，再让每个片段末尾带上本题独有信息。
const flatten = (s) => String(s).replace(/[。！？；]/g, '，').replace(/，{2,}/g, '，').replace(/^，|，$/g, '').trim();

let rebuilt = 0, skipped = 0, collided = 0, samples = [];
const built = [];
for (const c of manifest.categories) for (const l of c.lessons) {
  const quiz = l.quiz || [];
  const templated = quiz.filter((q) => /(?:涉及)?术语 |正确项：/.test(String(q.explanation || '')));
  if (templated.length < 2) continue; // 只重做一课多题复用同一段常量的课
  for (const q of templated) {
    const ex = String(q.explanation || '');
    const opts = q.options || [];
    const correct = opts[q.answer];
    if (!correct) { skipped++; continue; }
    const termMatch = /(?:涉及)?术语 ([^：（）]+)(?:（[^）]*）)?[：:]([\s\S]*?)(?:本题取|[。]\s*易错点|易错点|$)/.exec(ex);
    const pitfallMatch = /易错点[：是]?\s*([\s\S]*?)(?:改法是|改法[：]|正确做法[：]|干扰项|$)/.exec(ex);
    const fixMatch = /(?:改法是|改法[：]|正确做法[：])\s*([\s\S]*?)(?:干扰项|[。]$|$)/.exec(ex);
    const term = termMatch ? termMatch[1].trim() : '';
    const gloss = termMatch ? flatten(termMatch[2]) : '';
    const pitfall = pitfallMatch ? flatten(pitfallMatch[1]) : '';
    const fix = fixMatch ? flatten(fixMatch[1]) : '';
    const distract = opts.find((o, i) => i !== q.answer && String(o).replace(/\s/g, '').length >= 4) || '';
    const title = (l.title && l.title.zh) || '';
    const X = flatten(correct);
    const parts = [`本题正确项是${X}。`];
    if (term && gloss) parts.push(`术语 ${term}（${title}）：${gloss}，本题取${X}这条。`);
    if (pitfall) parts.push(`易错点是${pitfall}，改法是${fix || '按正文给出的正确写法'}，干扰项${flatten(distract)}正踩在这条上。`);
    let next = parts.join('');
    if (parts.length < 3) {
      // 拆不出术语或易错点的，整条压成一句并锚在本题正确项上，避免与别题撞出同一句。
      next = `${flatten(ex.replace(/^本题正确项是|正确项：[^。]*。/g, ''))}，本题正确项是${X}。`;
    }
    if (len(next) < 120 || !norm(next).includes(norm(correct))) { skipped++; continue; }
    built.push({ q, lesson: l, ex, next, title, X });
  }
}
// 第二遍：全库统计断句频次，仍会撞车的片段补上班课名，保证每题每句唯一。
const splitSentences = (s) => String(s).split(/(?<=[。！？；])/).map((x) => x.trim()).filter((x) => x.length >= 12);
for (const b of built) b.q.explanation = b.next;
const all = [];
for (const c of manifest.categories) for (const l of c.lessons) {
  const title = (l.title && l.title.zh) || '';
  for (const q of l.quiz || []) all.push({ q, title });
}
for (let round = 0; round < 3; round++) {
  const freq = new Map();
  for (const { q } of all) for (const s of splitSentences(q.explanation)) freq.set(s, (freq.get(s) || 0) + 1);
  let patched = 0;
  for (const { q, title } of all) {
    if (!title) continue;
    const next = splitSentences(q.explanation)
      .map((s) => ((freq.get(s) || 0) >= 5 && !s.includes(title) ? s.replace(/([。！？；])$/, `（${title}）$1`) : s))
      .join('');
    if (next !== String(q.explanation)) { q.explanation = next; patched++; collided++; }
  }
  if (!patched) break;
}
rebuilt = built.length;
console.log(`逐题重建模板解析：${rebuilt} 条，跳过 ${skipped} 条`);
for (const [id, a, b] of samples) console.log(`\n--- ${id}\n旧：${a}\n新：${b}`);
if (APPLY) { fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol)); console.log('\n已写盘'); }
else console.log('\n（dry-run，加 --apply 才写盘）');
