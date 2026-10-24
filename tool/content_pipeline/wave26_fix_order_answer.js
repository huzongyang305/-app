// 第 26 波：让多选/排序题的解析与真实答案对上。
//
// 排序题和多选题同时写着 `answer`（一个下标）和 `answers` / `correct_order`（真正的判分依据）。
// 审计与解析生成器都先看 `answer`，于是把「多选的第一个正确项」「排序的第一步」当成了整道题的答案：
//   1. 45 条排序题解析因此写成「本题顺序是「核心知识」。」，后面三步没了；
//   2. 还有 7 处把序列里的正常一步称为「干扰项…应排除」，与题目本身矛盾。
// 这里先把多余的 `answer` 删掉（App 判分走 answers/correct_order，见 lib/models/lesson.dart:55
// 与 lib/models/quiz_answer.dart:141，删掉后不再有回退歧义），再把排序首句补成完整序列，
// 并删掉把正确序列项说成干扰项的句子。最后顺手清掉上一波守卫退回的截断残句。
// 用法：node tool/content_pipeline/wave26_fix_order_answer.js [--apply] [--show]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const P = 'assets/content/manifest.json';
const raw = fs.readFileSync(P, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

const flatten = (s) => String(s == null ? '' : s).replace(/\s+/g, ' ').trim();
const nz = (s) => flatten(s).replace(/[`「」『』“”"'’]/g, '').replace(/[。！？；，、：\s]/g, '');
const norm = (s) =>
  String(s || '')
    .replace(/（[A-Za-z0-9_.-]+ 第 \d+ 题）/g, '')
    .replace(/^[「『“"\s]+|[」』”"\s]+$/g, '')
    .replace(/[\s。！？!?]+$/g, '')
    .replace(/\s+/g, ' ')
    .trim();
const BAD_PUNCT = /[。；，]{2,}|。，|，。|…；/;
const tidy = (t) =>
  t.replace(/[，、；]{2,}/g, '，').replace(/。{2,}/g, '。').replace(/，。/g, '。').replace(/\s{2,}/g, ' ').trim();

const mentionsDomain = (lesson, text) =>
  (lesson.title && text.includes(lesson.title)) ||
  (lesson.keywords || []).some((k) => String(k).length >= 2 && text.includes(k));

/// 判分用的正确答案：只看 answers / correct_order / accepted_answers，忽略多余的 answer 下标。
function truthOf(q) {
  const opts = (q.options || []).map(String);
  const idx = (list) =>
    (Array.isArray(list) ? list : [])
      .map((v) => (typeof v === 'number' ? v : parseInt(String(v), 10)))
      .filter((i) => Number.isInteger(i) && i >= 0 && i < opts.length);
  const answers = idx(q.answers);
  if (answers.length) return { kind: 'multi', texts: answers.map((i) => opts[i]), idx: answers };
  const order = idx(q.correct_order);
  if (order.length) return { kind: 'order', texts: order.map((i) => opts[i]), idx: order };
  if (Array.isArray(q.accepted_answers) && q.accepted_answers.length)
    return { kind: 'fill', texts: [String(q.accepted_answers[0])], idx: [] };
  const direct = typeof q.answer === 'number' ? q.answer : -1;
  if (direct >= 0 && direct < opts.length) return { kind: 'single', texts: [opts[direct]], idx: [direct] };
  return { kind: 'none', texts: [], idx: [] };
}

const passGuards = (lesson, q, ex, truth) => {
  if (ex.length < 120) return false;
  if (BAD_PUNCT.test(ex)) return false;
  const flat = norm(ex);
  const parts = truth.texts.map(norm).filter(Boolean);
  if (parts.some((p) => !flat.includes(p))) return false;
  if ((q.type === 'code' || q.type === 'debug') && !mentionsDomain(lesson, ex)) return false;
  return true;
};

const stats = {
  droppedAnswer: 0, orderLead: 0, distractRemoved: 0, tailCut: 0, quoteCut: 0, rejected: 0, mapFixed: 0,
};

// 三条通用改法都会把解析压到 120 字门槛以下，这一题单独重写：去掉截断的题干引号，
// 用题干自己给出的定义收尾（内容原样来自本题题干，不新增说法）。
const EXPLANATION_MAP = new Map([
  [
    'visual_k8s_scheduling#4',
    '《图解 Kubernetes 调度与探针》这题的填空口径是「优雅下线」，正文写法与其中任一项一致即可。' +
      '术语「调度」在本课里的界定是在多个就绪任务之间分配 CPU、线程或执行机会。' +
      '本题空缺处对应的正文说法是：实例从负载均衡摘除后等待连接和请求排空，再安全停止进程。',
  ],
]);
const samples = [];
const note = (kind, id, text) => {
  if (SHOW && samples.length < 16) samples.push(`${kind} ${id}｜${text}`);
};

for (const c of manifest.categories) {
  for (const l of c.lessons || []) {
    const title = flatten(l.title && l.title.zh ? l.title.zh : l.title);
    (l.quiz || []).forEach((q, qi) => {
      const truth = truthOf(q);
      const opts = (q.options || []).map(String);
      const distractors = opts.filter((_, i) => !truth.idx.includes(i));

      // 1) 多选/排序题上的 `answer` 是冗余下标，留着会让「正确答案」退化成第一项
      if (typeof q.answer === 'number' && (truth.kind === 'multi' || truth.kind === 'order')) {
        delete q.answer;
        stats.droppedAnswer++;
      }

      let ex = typeof q.explanation === 'string' ? q.explanation : '';
      if (!ex) return;

      const mapped = EXPLANATION_MAP.get(`${l.id}#${qi}`);
      if (mapped && /题干「[^」]*」/.test(ex) && passGuards(l, q, mapped, truth)) {
        note('单条重写', l.id, mapped.slice(-52));
        q.explanation = mapped;
        stats.mapFixed++;
        return;
      }

      // 2) 排序题首句补成完整序列
      if (truth.kind === 'order' && truth.texts.length > 1) {
        const lead = `按《${title}》正文的先后，本题顺序是${truth.texts.map((t) => `「${flatten(t)}」`).join(' → ')}。`;
        const missingAny = truth.texts.some((t) => t && !nz(ex).includes(nz(t)));
        if (missingAny) {
          const leadRe = /^按《[^》]{1,60}》正文的先后，本题顺序是[\s\S]*?」。/;
          const candidate = leadRe.test(ex) ? ex.replace(leadRe, lead) : lead + ex;
          if (passGuards(l, q, tidy(candidate), truth)) {
            note('顺序首句', l.id, tidy(candidate).slice(0, 90));
            ex = tidy(candidate);
            stats.orderLead++;
          } else stats.rejected++;
        }
      }

      // 3) 把正确序列项/正确项称作「干扰项」的句子删掉
      for (const re of [
        /[，、。]?干扰项「([^」]{1,120})」与题干[^。]*的要求对不上，应排除。/g,
        /[，、。]?干扰项「([^」]{1,120})」正踩在这条上/g,
      ]) {
        ex = ex.replace(re, (whole, cap) => {
          const key = nz(cap);
          const isCorrect = truth.texts.some((t) => key && nz(t).includes(key) || key && key.includes(nz(t)));
          if (!isCorrect) return whole;
          const pick = distractors.map(flatten).filter((o) => nz(o).length >= 4)[0];
          if (re.source.includes('正踩在') && pick) return `，干扰项「${pick}」正踩在这条上`;
          stats.distractRemoved++;
          note('误标干扰项', l.id, whole.slice(0, 60));
          return '。';
        });
        ex = tidy(ex);
      }

      // 4) 截断的「本课…要解决的是…」模板尾句：能删就删，删完没复述答案就补一句填空口径
      const tailMatch = /本课[^。」「]{1,40}要解决的是[\s\S]*$/.exec(ex);
      if (tailMatch) {
        const base = tidy(ex.slice(0, tailMatch.index).replace(/[，、；：]+$/, '') + '。');
        let candidate = base;
        if (!passGuards(l, q, base, truth) && truth.kind === 'fill') {
          candidate = tidy(base + `本题要填的是${flatten(truth.texts[0])}。`);
        }
        if (passGuards(l, q, candidate, truth)) {
          note('模板尾句', l.id, `${ex.slice(tailMatch.index, tailMatch.index + 40)}… → ${candidate.slice(-40)}`);
          ex = candidate;
          stats.tailCut++;
        } else stats.rejected++;
      }

      // 5) 引号里被截断的题干（反引号不配对）：整段引号删掉，只留「题干」二字；
      //    删完掉到 120 字以下的，改用题干开头的完整一句顶上；再不行就换成填空口径收尾。
      const brokenQuote = /题干「([^」]{1,200}?)」/;
      const firstQuote = brokenQuote.exec(ex);
      if (firstQuote && (firstQuote[1].match(/`/g) || []).length % 2 === 1) {
        const cut = tidy(ex.replace(/题干「([^」]{1,200}?)」/g, (whole, inner) =>
          (inner.match(/`/g) || []).length % 2 === 1 ? '题干' : whole));
        const head = flatten(String(q.question || '')).split('。')[0].slice(0, 40);
        const kept = head && !head.includes('`')
          ? tidy(ex.replace(/题干「[^」]{1,200}?」/g, `题干「${head}」`))
          : null;
        // 前两条都会让解析掉到门槛以下：把「题干…」半句整段去掉，改用复述空缺答案收尾
        const lean = tidy(
          ex
            .replace(/，题干「[^」]{1,200}?」问的就是这一条。/g, '。')
            .replace(/题干「[^」]{1,200}?」/g, '题干') +
            `本题要填的是${flatten(truth.texts[0] || '')}。`,
        );
        const pick = [
          ['cut', cut],
          ['补全题干', kept],
          ['填空口径收尾', lean],
        ].find(([, text]) => text && passGuards(l, q, text, truth));
        if (pick) {
          stats.quoteCut++;
          note(`截断题干引号→${pick[0]}`, l.id, pick[1].slice(-56));
          ex = pick[1];
        } else stats.rejected++;
      }

      if (!passGuards(l, q, ex, truth) && ex !== q.explanation) { stats.rejected++; return; }
      q.explanation = ex;
    });
  }
}

console.log(
  `删除冗余 answer ${stats.droppedAnswer} 个、重写排序首句 ${stats.orderLead} 条、删误标干扰项句 ${stats.distractRemoved} 处、删模板尾句 ${stats.tailCut} 条、删截断题干引号 ${stats.quoteCut} 处、单条重写 ${stats.mapFixed} 条，守卫退回 ${stats.rejected} 次`,
);
if (samples.length) console.log(samples.join('\n'));
if (APPLY) {
  fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('已写盘');
} else console.log('（dry-run，加 --apply 才写盘）');
