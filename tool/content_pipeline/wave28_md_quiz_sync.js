// 第 28 波：把课文「考点精讲」的选项文案与字母型答案重新对齐题库，并清理残留的反斜杠转义引号。
// 前面几波改写过题库的选项文案（补长干扰项、截短正确项）、重造过部分题干，课文里的选项列表和
// 字母答案没跟着走；少数课文甚至把 \"长什么样\" 这样的转义原文写进了正文。
// 于是学员在课文里看到的「B 项」和 App 里作答时的「B 项」不是同一句话。这里只做四类修复：
//   1) 反斜杠转义引号：成对时按正文是否含中文写成中文引号或普通引号，落单时去掉反斜杠；
//   2) 选项行文案替换成题库当前文案，行尾已有的 ✅/❌ 原样保留（不新增、不删除）；
//   3) 题干后只给了字母答案却完全没有选项列表的，按题库补出列表；
//   4) 字母型答案标注改成题库真值（选项文案本身就是字母串的，按文本型答案放过）。
// 用法：node tool/content_pipeline/wave28_md_quiz_sync.js [--apply] [--show]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const DIR = 'assets/content/';
const MANIFEST = DIR + 'manifest.json';
const raw = fs.readFileSync(MANIFEST, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

const L = 'ABCDEFGH';
const DROP_G = /[\s　*`_「」『』“”"']+/g;
const IS_DROP = (ch) => /[\s　*`_「」『』“”"']/.test(ch);
const nz = (s) => String(s || '').replace(DROP_G, '');
const CJK = /[一-龥]/;
const LETTER_RUN = /^[A-H](?:\s*(?:[、，,/→]|或|和)?\s*[A-H])*$/;
const MK_LINE = /^(\s*(?:[-*>]\s*)?(?:\*\*)?\s*(?:正确答案|正确项|正确选项|正确序号|参考答案|答案|[Aa]ns)(?:\s*\*\*)?\s*[:：]\s*)(.*)$/;
const OPT_RE = /(?:^|[\s（(：:])([A-H])\s*[.、]\s/g;
const STOP_RE = /\n|(?:\*\*)?\s*(?:正确答案|正确项|正确选项|参考答案|解析|判断依据|讲解|详细解释|[Aa]ns)\s*(?:\*\*)?\s*[:：]/;

function truthOf(q) {
  if (Array.isArray(q.answers) && q.answers.length) return { kind: 'multi', idx: q.answers.map(Number) };
  if (Array.isArray(q.correct_order) && q.correct_order.length) return { kind: 'order', idx: q.correct_order.map(Number) };
  if (typeof q.answer === 'number') return { kind: 'single', idx: [q.answer] };
  return { kind: 'none', idx: [] };
}
function flatMap(s) {
  const a = [], map = [];
  for (let i = 0; i < s.length; i++) if (!IS_DROP(s[i])) { a.push(s[i]); map.push(i); }
  return { flat: a.join(''), map };
}
function regionStart(md) { const i = md.indexOf('\n## 考点精讲'); return i < 0 ? 0 : i + 1; }
function regionEnd(md, s) { const j = md.slice(s + 2).search(/\n##(?!#)/); return j < 0 ? md.length : s + 2 + j; }
// 逐处把成对的 \"X\" 改成中文引号（正文含中文）或去掉反斜杠（纯代码），落单的 \" 去掉反斜杠。
// 同时清掉反斜杠配中文引号的残留。围栏代码块与行内代码由调用方跳过。
function unescapeQuotes(text) {
  let out = '', i = 0, n = 0;
  while (i < text.length) {
    const p = text.indexOf('\\"', i);
    if (p < 0) { out += text.slice(i); break; }
    out += text.slice(i, p);
    const q = text.indexOf('\\"', p + 2);
    const body = q > 0 ? text.slice(p + 2, q) : null;
    if (body !== null && body.length <= 80 && !body.includes('"') && !body.includes('\\"')) {
      out += CJK.test(body) ? '“' + body + '”' : '"' + body + '"';
      n++; i = q + 2;
    } else { out += '"'; n++; i = p + 2; }
  }
  const stray = (out.match(/\\[“”]/g) || []).length;
  return { text: out.replace(/\\([“”])/g, '$1'), n: n + stray };
}

// 从题干结束处往后，按 A. B. C. 连续出现切出选项（独立成行、缩进、与题干同行都支持）。
function scanOpts(text, from) {
  const hits = [];
  OPT_RE.lastIndex = 0;
  let mm;
  while ((mm = OPT_RE.exec(text))) {
    const lp = mm.index + mm[0].indexOf(mm[1]);
    if (lp < from) continue;
    if (mm[1] !== L[hits.length]) break;
    hits.push({ letter: mm[1], markStart: lp, textStart: mm.index + mm[0].length });
    if (hits.length >= 8) break;
  }
  return hits.map((h, i) => {
    const lim = i + 1 < hits.length ? hits[i + 1].markStart : text.length;
    const sub = text.slice(h.textStart, lim);
    const cut = sub.search(STOP_RE);
    const tail = sub.slice(0, cut < 0 ? sub.length : cut);
    // 行尾的 ✅/❌ 属于标注，不属于选项文案；替换文案时原样带回
    const gm = /^([\s\S]*?)\s*((?:[✅❌✓×]\s*)+)$/.exec(tail);
    return {
      ...h,
      end: h.textStart + tail.length,
      text: (gm ? gm[1] : tail).replace(/\s+/g, ' ').trim(),
      mark: gm ? gm[2].trim() : '',
    };
  });
}
// 用题干在考点块里定位，返回块文本、题干最后一个字符之后的块内偏移
function anchor(md, rs, re, key) {
  const { flat, map } = flatMap(md.slice(rs, re));
  const at = flat.indexOf(key);
  if (at < 0) return null;
  const p0 = rs + map[at];
  const seg = md.slice(p0, Math.min(md.length, p0 + 5200));
  const fromRaw = map[at + key.length - 1] - map[at] + 1;
  const nx = seg.slice(Math.max(1, fromRaw)).search(/\n#{3,4}\s*考点|考点\d+\s*[:：]/);
  return { p0, fromRaw, block: nx < 0 ? seg : seg.slice(0, nx + Math.max(1, fromRaw)) };
}

const stats = { quoteMd: 0, quoteMf: 0, optLines: 0, optsAdded: 0, markerFixed: 0, rejected: 0 };
const notes = [];
const rejects = [];
const note = (tag, id, msg) => { if (SHOW && notes.length < 140) notes.push(`${tag}｜${id}｜${msg}`); };

// —— 规则 1（题库侧）：解析字段里的转义引号 ——
for (const c of manifest.categories) {
  for (const l of c.lessons || []) {
    for (const q of l.quiz || []) {
      if (typeof q.explanation !== 'string' || !/\\["“”]/.test(q.explanation)) continue;
      const r = unescapeQuotes(q.explanation);
      if (r.text === q.explanation) continue;
      stats.quoteMf += r.n;
      note('题库转义', l.id, /.{0,16}\\["“”].{0,16}/.exec(q.explanation)[0]);
      q.explanation = r.text;
    }
  }
}
for (const c of manifest.categories) {
  for (const l of c.lessons || []) {
    const rel = String(l.file || l.id + '.md');
    const file = rel.startsWith(DIR) ? rel : DIR + rel;
    if (!fs.existsSync(file)) continue;
    const before = fs.readFileSync(file, 'utf8');
    const quiz = l.quiz || [];
    if (!/\\["“”]/.test(before) && !quiz.some((q) => (q.options || []).length && truthOf(q).idx.length)) continue;

    // 规则 1（课文侧）：跳过围栏代码块与行内代码
    let md = '';
    {
      const lines = before.split(/\r?\n/);
      let fence = false;
      for (const ln of lines) {
        if (/^\s*(```|~~~)/.test(ln)) { fence = !fence; md += ln + '\n'; continue; }
        if (fence || !/\\["“”]/.test(ln)) { md += ln + '\n'; continue; }
        const parts = ln.split(/(`[^`]*`)/);
        for (let i = 0; i < parts.length; i += 2) {
          const r = unescapeQuotes(parts[i]);
          parts[i] = r.text;
          stats.quoteMd += r.n;
        }
        md += parts.join('') + '\n';
      }
      md = md.replace(/\n$/, '');
    }

    for (const q of quiz) {
      const opts = (q.options || []).map(String);
      const t = truthOf(q);
      if (!opts.length || !t.idx.length) continue;
      // 本课内有别的题题干归一化后完全相同、选项却不一样时，无法判断哪块对应哪题，整题跳过
      const twin = quiz.some((o) => o !== q && nz(o.question) === nz(q.question)
        && nz((o.options || []).join('|')) !== nz((opts).join('|')));
      if (twin) { note('题干重复无法区分', l.id, String(q.question).slice(0, 26)); continue; }
      const fullKey = nz(q.question);
      const keys = [fullKey, fullKey.slice(0, 40)];
      let rs = regionStart(md), re = regionEnd(md, rs);
      let a = null, key = null;
      for (const k of keys) { a = anchor(md, rs, re, k); if (a) { key = k; break; } }
      if (!a) continue;

      const found = scanOpts(a.block, a.fromRaw);
      if (found.length === opts.length) {
        // 规则 2：只换文案，行尾 ✅❌ 原样带回
        const edits = [];
        found.forEach((o, i) => {
          const want = opts[i].replace(/\s+/g, ' ').trim();
          if (nz(o.text) === nz(want)) return;
          edits.push({ start: o.textStart, end: o.end, next: want + (o.mark ? ' ' + o.mark : '') });
          stats.optLines++;
          note('选项同步', l.id, `${o.letter}「${o.text.slice(0, 22)}」→「${want.slice(0, 22)}」`);
        });
        if (edits.length) {
          let next = a.block;
          for (const e of edits.reverse()) next = next.slice(0, e.start) + e.next + next.slice(e.end);
          md = md.slice(0, a.p0) + next + md.slice(a.p0 + a.block.length);
        }
      } else if (found.length === 0) {
        // 规则 3：只有字母答案、没有选项列表 → 在题干行后补出题库选项
        const after = a.block.slice(a.fromRaw);
        const mkLines = after.split(/\r?\n/).filter((ln) => MK_LINE.test(ln));
        if (mkLines.length !== 1) continue;
        const mk = MK_LINE.exec(mkLines[0]);
        const val = mk[2].replace(/\s*[（(].*$/, '').replace(/[*\s.。]+$/g, '').replace(/^[*\s]+/, '');
        if (!val || !LETTER_RUN.test(val)) continue;
        const lineEnd = (() => { const nl = a.block.indexOf('\n', a.fromRaw); return nl < 0 ? a.block.length : nl; })();
        // 题干行是列表项时补成缩进子项，否则按课文通用的裸「A. 」行
        const head = md.slice(md.lastIndexOf('\n', a.p0 - 1) + 1, a.p0 + a.fromRaw);
        const bullet = /^\s*[-*]\s/.test(head);
        const list = opts.map((o, i) => (bullet ? '  - ' : '') + L[i] + '. ' + o.replace(/\s+/g, ' ').trim()).join('\n');
        md = md.slice(0, a.p0 + lineEnd) + (bullet ? '\n' + list : '\n\n' + list + '\n') + md.slice(a.p0 + lineEnd);
        stats.optsAdded++;
        note('补选项列表', l.id, `${opts.length} 项｜${String(q.question).slice(0, 24)}`);
      }

      // 规则 4：字母型答案标注对齐题库真值
      {
        rs = regionStart(md); re = regionEnd(md, rs);
        a = anchor(md, rs, re, key);
        if (!a) continue;
        const after = a.block.slice(a.fromRaw);
        const lines = after.split(/\r?\n/);
        const idx = lines.findIndex((ln) => MK_LINE.test(ln));
        if (idx < 0) continue;
        const mm = MK_LINE.exec(lines[idx]);
        const val = mm[2].replace(/\s*[（(].*$/, '').replace(/[*\s.。]+$/g, '').replace(/^[*\s]+/, '');
        if (!val || !LETTER_RUN.test(val)) continue;
        // 选项文案自己就是「B+C+A」这类字母串时，这是文本型答案，不能当字母改
        if (opts.some((o) => nz(o) === nz(val))) continue;
        const sep = /、/.test(val) ? '、' : /→/.test(val) ? ' → ' : /\s/.test(val) ? ' ' : '';
        const truth = t.idx.map((x) => L[x]);
        const got = (val.match(/[A-H]/g) || []).map((x) => L.indexOf(x));
        const same = t.kind === 'order'
          ? got.join(',') === t.idx.join(',')
          : [...new Set(got)].sort().join(',') === [...new Set(t.idx)].sort().join(',');
        if (same) continue;
        const want = t.kind === 'order' ? truth.join(sep || ' → ') : [...new Set(truth)].sort().join(sep || '');
        lines[idx] = mm[1] + want;
        stats.markerFixed++;
        note('答案标注', l.id, `「${val}」→「${want}」｜${String(q.question).slice(0, 22)}`);
        md = md.slice(0, a.p0) + a.block.slice(0, a.fromRaw) + lines.join('\n') + md.slice(a.p0 + a.block.length);
      }
    }

    const nextText = md.split('\n').join(eol);
    if (nextText === before) continue;
    const lenBefore = before.replace(/\s/g, '').length, lenNow = md.replace(/\s/g, '').length;
    const lost = quiz.find((q) => q.question && !nz(md).includes(nz(q.question)));
    const why = (lenBefore >= 6000 && lenNow < 6000) || lenNow < lenBefore - 60
      ? `正文缩短 ${lenBefore}→${lenNow}`
      : lost ? `题干「${String(lost.question).slice(0, 26)}」不再出现`
      : /《[^》]+》的[“"]/.test(md) ? '出现《X》的“ 句式' : '';
    if (why) { stats.rejected++; rejects.push(`${l.id}：${why}`); continue; }
    if (APPLY) fs.writeFileSync(file, nextText);
  }
}

if (APPLY) fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2).split('\n').join(eol));
console.log(`课文转义引号 ${stats.quoteMd} 处｜题库解析转义 ${stats.quoteMf} 处｜选项文案替换 ${stats.optLines} 行｜补选项列表 ${stats.optsAdded} 题｜答案标注改写 ${stats.markerFixed} 处｜守卫退回 ${stats.rejected}`);
if (notes.length) console.log(notes.join('\n'));
if (rejects.length) console.log('守卫退回明细：\n' + rejects.join('\n'));
if (!APPLY) console.log('（dry-run，加 --apply 才写盘）');
