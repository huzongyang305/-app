// 第 21 波：修正多选与排序题的解析口径。
//
// 抽查发现的问题有两类：
//   1. 多选题（answers 多个下标）和排序题（correct_order）的解析仍以单选口径开头
//      「本题正确项是X」，学员看完只知道其中一项，漏选其余正确项；
//   2. 解析尾部「干扰项X正踩在这条上」里的 X 有时其实是正确项——那是按选项顺序取第一项
//      造成的错位，等于把正确答案说成错误答案，属于事实性错误。
// 这里只改这两处表述，术语解释与易错点正文保持原样；正确项原文用「」原样复述，
// 保证治理审计的“解析复述正确项”规则继续成立。
// 用法：node tool/content_pipeline/wave21_multi_order_explanations.js [--apply] [--show]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const P = 'assets/content/manifest.json';
const raw = fs.readFileSync(P, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

const flatten = (s) => String(s || '').replace(/\s+/g, ' ').trim();
const nz = (s) => flatten(s).replace(/[`「」『』“”"'’]/g, '').replace(/[。！？；，、：\s]/g, '');

const isMulti = (q) => Array.isArray(q.answers) && q.answers.length > 1 && q.type !== 'order';
const isOrder = (q) => q.type === 'order' || (Array.isArray(q.correct_order) && q.correct_order.length > 1 && !q.answers);

let leadFixed = 0, leadPrepended = 0, phraseFixed = 0, distractFixed = 0, distractDropped = 0, kept = 0, rejected = 0;
const samples = [];

for (const c of manifest.categories) {
  for (const l of c.lessons || []) {
    const title = flatten(l.title && l.title.zh ? l.title.zh : l.title);
    for (const q of l.quiz || []) {
      if (!isMulti(q) && !isOrder(q)) continue;
      const opts = (q.options || []).map(String);
      const correctIdx = isOrder(q)
        ? (q.correct_order || []).map((v) => (typeof v === 'number' ? v : opts.indexOf(String(v)))).filter((v) => v >= 0)
        : q.answers.map((v) => (typeof v === 'number' ? v : parseInt(v, 10))).filter((v) => !Number.isNaN(v));
      const correctTexts = (isOrder(q) ? correctIdx.map((i) => opts[i]) : correctIdx.map((i) => opts[i]).filter(Boolean));
      if (correctTexts.length < 2) { kept++; continue; }
      const distractors = opts.filter((o, i) => !correctIdx.includes(i));
      let ex = String(q.explanation || '');
      const before = ex;

      // 1) 首句改为“要同时选中 / 顺序是”口径。
      const quoted = correctTexts.map((t) => `「${flatten(t)}」`);
      const lead = isOrder(q)
        ? `按《${title}》正文的先后，本题顺序是${quoted.join(' → ')}。`
        : `按《${title}》的正文口径，本题要同时选中${quoted.join('、')}，漏掉任一项都算没答全。`;
      // 首句可能直接以「本题正确项是」开头，也可能被前面的「按《某课》的正文口径，」带偏，
      // 两种都要换成多选/排序口径。
      const withLead = ex.replace(
        /^(?:按《[^》]{1,40}》的正文口径，)?本题正确项是[^。]*。/,
        lead,
      );
      if (withLead !== ex) leadFixed++;
      ex = withLead;

      // 1a) 少数解析没有以「本题正确项是」起笔（直接从术语解释开始），补上多选/排序口径首句，
      //     这样删掉「本题取X这条」之后仍然复述得全所有正确项。
      if (!/本题要同时选中|本题顺序是/.test(ex)) {
        ex = lead + ex;
        leadPrepended++;
      }

      // 1b) 术语解释后面还挂着「本题取X这条」，同样是单选口径：多选/排序题里删掉这半句，
      //     术语定义本身保留。缺正确项复述或长度不够时由后面的守卫退回原文。
      const withPhrase = ex.replace(/，?本题取[^。]{1,80}?这条/g, '');
      if (withPhrase !== ex) phraseFixed++;
      ex = withPhrase;

      // 2) 「干扰项X正踩在这条上」中的 X 若其实是正确项，换成真正的干扰项或直接删掉这半句。
      ex = ex.replace(/，?干扰项([^。]{2,60}?)正踩在这条上/g, (whole, cap) => {
        const key = nz(cap);
        const claimsCorrect = correctTexts.some((t) => key && nz(t).includes(key.slice(0, Math.max(6, key.length - 6))));
        if (!claimsCorrect) return whole;
        const pick = distractors.map(flatten).filter((o) => nz(o).length >= 4)[0];
        if (!pick) { distractDropped++; return '。'; }
        distractFixed++;
        return `，干扰项「${pick}」正踩在这条上`;
      });

      ex = ex.replace(/[，、；]{2,}/g, '，').replace(/。{2,}/g, '。').replace(/，。/g, '。').trim();
      const missing = correctTexts.map(nz).filter((t) => t && !nz(ex).includes(t));
      if (ex === before) { kept++; continue; }
      if (ex.length < 120 || missing.length) { rejected++; continue; }
      if (SHOW && samples.length < 6) samples.push(`${l.id}\n旧：${before.slice(0, 160)}\n新：${ex.slice(0, 160)}`);
      if (APPLY) q.explanation = ex;
    }
  }
}

console.log(
  `改写多选题/排序题解析：首句 ${leadFixed} 条、补首句 ${leadPrepended} 条、删“本题取…这条” ${phraseFixed} 条、` +
    `纠正错误干扰项指代 ${distractFixed} 处（删掉 ${distractDropped} 处）；` +
    `因长度或复述不完整退回 ${rejected} 条，未改动 ${kept} 条`,
);
if (samples.length) console.log(samples.join('\n--- '));
if (APPLY) {
  fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('已写盘');
} else console.log('（dry-run，加 --apply 才写盘）');
