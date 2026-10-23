// 第 11 波：重建仍带生成模板痕迹的解析。
// 命中形态：以「正确答案是「…」」开头、带「该判断与术语 / 错误表现方面」旧骨架、同一句
// 「本题正确项是X」重复多次、术语解释是「X 解决了什么问题，而不是只背术语」占位句，
// 以及早期波次追加的「本题还要同时命中核心知识这条。」这类占位补充句。
// 重建后每句都带本课标题或题干片段，避免跨课整句撞车；正确项原文用「」原样保留，
// 保证治理审计的「解析复述正确项」规则继续成立。
// 用法：node tool/content_pipeline/wave11_rebuild_residue.js [--apply] [--show]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const P = 'assets/content/manifest.json';
const eol = fs.readFileSync(P, 'utf8').includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(fs.readFileSync(P, 'utf8'));
const lessons = [];
for (const c of manifest.categories) for (const l of c.lessons) lessons.push(l);

const META_TERMS = new Set(['核心知识', '关键流程', '入门练习', '实战', '基础概念', '常见误区', '实践路径', '项目背景']);
const PLACEHOLDER = /解决了什么问题，而不是只背术语/;
const NEEDLES = [
  '正确答案是「', '该判断与术语', '错误表现方面', '解决了什么问题，而不是只背术语',
  '本课在「', '本课还在「', '本课把「', '课程摘要指出', '这道题对应的课程', '修正后要重跑', '对照「',
];
const BANNED = NEEDLES.concat(['本课在核心知识', '本课还在核心知识']);
// 旧模板里这些词之后的内容属于另一句，抽成分段时要在它们前面截断。
const STOP = /(?:，\s*干扰项|正是踩了这条|本题正确项是|本题取向|，应按|错误表现方面|易错点)/;

const zh = (v) => (v && typeof v === 'object' ? String(v.zh || v.en || '') : String(v || ''));
const flatten = (s) => String(s || '').replace(/\s+/g, ' ').trim();
// 句内标点降级：解析按 。！？； 断句，正文片段里的这些符号会切出无主语片段。
const soft = (s) => flatten(s).replace(/[。！？；]/g, '，').replace(/，{2,}/g, '，').replace(/^[，：]+|[，：]+$/g, '').trim();
// 去掉早期撞车扫描插入的（课名）注记，标题由本波统一安放。
const stripTitles = (s) => flatten(s).replace(/（[^（）]{1,44}）(?=[:：，]|$)/g, '').trim();
const cut = (s) => soft(String(s).split(STOP)[0]);

const normalize = (s) =>
  String(s)
    .replace(/（[A-Za-z0-9_.-]+ 第 \d+ 题）/g, '')
    .replace(/^[「『“"\s]+|[」』”"\s]+$/g, '')
    .replace(/[\s。！？!?]+$/g, '')
    .replace(/\s+/g, ' ')
    .trim();

function correctParts(q) {
  const opts = (q.options || []).map(String);
  if (typeof q.answer === 'number' && q.answer >= 0 && q.answer < opts.length) return [opts[q.answer]];
  if (Array.isArray(q.answers) && q.answers.length) {
    const idx = q.answers.map((v) => (typeof v === 'number' ? v : parseInt(v, 10))).filter((v) => !Number.isNaN(v));
    const picked = idx.map((i) => opts[i]).filter(Boolean);
    if (picked.length) return picked;
  }
  if (Array.isArray(q.correct_order) && q.correct_order.length) return q.correct_order.map(String);
  if (Array.isArray(q.accepted_answers) && q.accepted_answers.length) return q.accepted_answers.map(String);
  return [];
}

function extract(ex) {
  const termM = /(?:该判断与术语|涉及术语|术语)\s*`?([^`\n：（）]{1,32})`?\s*(?:（[^）]{1,44}）){0,2}\s*(?:对应|[:：])\s*([\s\S]*?)(?:错误表现方面|易错点|本题取|，应按|[。]\s*$|$)/.exec(ex);
  const pitM = /(?:错误表现方面|易错点)\s*[：:是]?\s*(.+?)(?:会|将)?造成(.+?)(?:，|,)?\s*(?:应按|改法\s*[：:]?|正确做法\s*[：:])\s*(.+?)(?:修复|。|$)/.exec(ex);
  return {
    term: termM ? stripTitles(termM[1]) : '',
    gloss: termM ? cut(termM[2]) : '',
    wrong: pitM ? cut(pitM[1]) : '',
    effect: pitM ? cut(pitM[2]) : '',
    fix: pitM ? cut(pitM[3]) : '',
  };
}

const tidy = (s) =>
  String(s)
    .replace(/，+。/g, '。')
    .replace(/[，、；]{2,}/g, '，')
    .replace(/。{2,}/g, '。')
    .replace(/\s{2,}/g, ' ')
    .trim();

let rebuilt = 0, skipped = 0;
const samples = [];

for (const l of lessons) {
  const title = flatten(zh(l.title));
  const summary = soft(zh(l.summary));
  for (const q of l.quiz || []) {
    const ex = q.explanation || '';
    const trip = (ex.match(/本题正确项是/g) || []).length >= 2;
    const hit = NEEDLES.some((m) => ex.includes(m)) || trip || /本题还要同时命中[^。]{0,12}这条。/.test(ex);
    if (!hit) continue;
    const parts = correctParts(q);
    if (!parts.length) { skipped++; continue; }
    const quoted = parts.map((p) => '「' + flatten(p) + '」');
    const stem = soft(q.question).slice(0, 34);
    const { term, gloss, wrong, effect, fix } = extract(ex);
    const seg = [];
    if (q.type === 'order') seg.push(`按《${title}》正文的先后，本题顺序是${quoted.join(' → ')}。`);
    else if (q.type === 'fill') seg.push(`《${title}》这题的填空口径是${quoted.join('或')}，正文写法与其中任一项一致即可。`);
    else if (quoted.length > 1) seg.push(`按《${title}》的正文口径，本题要同时选中${quoted.join('、')}。`);
    else seg.push(`按《${title}》的正文口径，本题正确项是${quoted[0]}。`);
    if (term && gloss && !PLACEHOLDER.test(gloss) && !META_TERMS.has(term)) {
      seg.push(`术语「${term}」在本课里的界定是${gloss}，题干「${stem}」问的就是这一条。`);
    } else if (summary) {
      seg.push(`题干「${stem}」要放回《${title}》的主线里看：${summary}。`);
    }
    if (wrong && effect) seg.push(`这一问常踩的坑是${wrong}，其后果是${effect}。`);
    if (fix) seg.push(`按《${title}》的口径，做「${stem}」这类判断时应${fix}。`);
    const inParts = new Set(parts.map(normalize));
    const distract = (q.options || []).map(String).find((o) => !inParts.has(normalize(o)) && normalize(o).length >= 4 && !META_TERMS.has(normalize(o))) || '';
    if (distract) seg.push(`干扰项「${flatten(distract)}」与题干「${stem}」的要求对不上，应排除。`);
    let next = tidy(seg.join(''));
    if (next.length < 124) {
      next = tidy(next + `作答时先回到《${title}》对应小节核对定义，再逐项排除与题干「${stem}」不符的说法。`);
    }
    const missing = parts.map(normalize).filter((v) => v && !normalize(next).includes(v));
    const dupLead = (next.match(/本题正确项是/g) || []).length > 1;
    if (next.length < 120 || missing.length || dupLead || BANNED.some((m) => next.includes(m))) { skipped++; continue; }
    if (SHOW && samples.length < 6) samples.push([`${l.id} [${q.type || 'single'}]`, ex, next]);
    rebuilt++;
    if (APPLY) q.explanation = next;
  }
}

console.log(`重建模板残留解析：${rebuilt} 条，跳过 ${skipped} 条`);
for (const [id, a, b] of samples) console.log(`\n--- ${id}\n旧：${a}\n新：${b}`);
if (APPLY) {
  fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('\n已写盘');
} else console.log('\n（dry-run，加 --apply 才写盘）');
