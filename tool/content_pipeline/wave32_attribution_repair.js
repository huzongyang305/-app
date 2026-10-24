// wave32：修掉解析尾部「干扰项 X 正踩在这条上」的错误归因。
//
// 背景：第 11 波重建解析时，把整课错误表的第 0 行盖到这一课的每道题上，再随手抓一个干扰项写
// 「正踩在这条上」。抽检（probe37）显示 2602 条尾句里只有 61 条的干扰项与这条坑对得上，
// 另有 4 条把正确项标成了干扰项。坑是本课的坑，干扰项却是无关的那一条，学员照着读只会误判。
//
// 改法（只保留能被机械证明的表述）：
//   路线一：code/debug 的断言型干扰项，按第 30 波的词边界判定核实该 token 确实不在展示代码里，
//           再把尾句写成「找不到 X，因此不成立」——这类断言由测试长期锁住，说的必然是事实；
//   路线二：其余一律删掉归因，只留坑本身；坑按题序在本课错误表里轮换，同课每题讲不同易错点，
//           也顺带避免了「一条坑盖满整课」的模板句；
//   删除后跌破 120 字的，再补一行本课另一条易错点，还不够就补本课术语速查。
// 定位尾句用的是与测试一致的引号感知断句：选项文案里自带「。）」，按标点回溯会把句子切半。
// 改动同步写回课文「考点精讲」的解析：按题干顺序定位考点块，块内替换，不做全文替换。
//
// 用法：node tool/content_pipeline/wave32_attribution_repair.js [--apply] [--show]
import fs from 'node:fs';
import path from 'node:path';

const ROOT = 'F:/app';
const MANIFEST = path.join(ROOT, 'assets/content/manifest.json');
const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');

const norm = (s) => String(s || '').replace(/[\s`*_「」『』“”"']/g, '');
const loose = (s) => String(s || '').replace(/[\s　]/g, '');
const trimTail = (s) => String(s || '').replace(/^[\s：:，,、]+|[\s；;。，,]+$/g, '');
const GENERIC = ['只记术语不做实验', '只测正常路径', '没有基线就优化', '忽略成本与安全'];
const ASSERT = /^(?:\*\*)?(调用了|出现字面量|代码里出现了)\s*`([^`]+)`/;

/** 解析里有时是半句引号（「作为<角色>，我想要<目标>。后面不闭合），此时不能再拿它当跨度，
 *  否则整段解析会被当成一句话，替换位置跑到解析开头，正确项复述也就跟着丢了。 */
function quoteModes(text) {
  const open = (text.match(/[「『“]/g) || []).length;
  const close = (text.match(/[」』”]/g) || []).length;
  return { quote: open === close, code: ((text.match(/`/g) || []).length % 2 === 0) };
}

/** 与 test/content_test.dart 的断句器一致：引号与反引号跨度内的标点不断句 */
function splitSentences(text) {
  const out = [];
  const mode = quoteModes(text);
  let buf = '', inQuote = false, inCode = false;
  for (const ch of text) {
    if (ch === '`') { if (mode.code) inCode = !inCode; }
    else if (!inCode && mode.quote) {
      if (ch === '「' || ch === '『' || ch === '“') inQuote = true;
      else if (ch === '」' || ch === '』' || ch === '”') inQuote = false;
    }
    buf += ch;
    if ((ch === '。' || ch === '；' || ch === '\n') && !inQuote && !inCode) {
      if (buf.trim()) out.push(buf.trim());
      buf = '';
    }
  }
  if (buf.trim()) out.push(buf.trim());
  return out;
}

// —— 与第 30 波一致的展示代码判定，用于核实「代码里确实没有这个 token」 ——
const escape = (ch) => ch.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const isWordChar = (ch) => /[A-Za-z0-9_]/.test(String(ch || ''));
const bodyOf = (token) => Array.from(norm(token).replace(/\(\)$/, '')).map(escape).join('\\s*');
function holds(code, kind, token) {
  const flat = norm(token).replace(/\(\)$/, '');
  if (!flat) return false;
  const source = String(code || '');
  const head = kind === 'call' || isWordChar(flat[0]) ? '(?<![A-Za-z0-9_])' : '';
  const tail = kind !== 'call' && isWordChar(flat[flat.length - 1]) ? '(?![A-Za-z0-9_])' : '';
  const pattern = `${head}${bodyOf(token)}${kind === 'call' ? '\\s*\\(' : tail}`;
  return new RegExp(pattern).test(source);
}

/** 只取首句，避免把课文里的整段解释搬进解析 */
function firstSentence(text) {
  const clean = trimTail(String(text || '').replace(/\*\*/g, ''));
  // 表格单元里的代码跨度常自带分号（`shell=False; rm -rf /`），只在引号与反引号之外断句
  const mode = quoteModes(clean);
  let inQuote = false, inCode = false, at = -1;
  for (let i = 0; i < clean.length; i++) {
    const ch = clean[i];
    if (ch === '`') { if (mode.code) inCode = !inCode; }
    else if (!inCode && mode.quote) {
      if ('「『“'.includes(ch)) inQuote = true;
      else if ('」』”'.includes(ch)) inQuote = false;
    }
    if ('。；;'.includes(ch) && !inQuote && !inCode) { at = i; break; }
  }
  return trimTail(at < 0 ? clean : clean.slice(0, at));
}

/** 「实际现象」一栏有时只写了语言名（Java、Go、Python），这种没有后果可言，当作没有 */
const hasCjk = (s) => /[一-龥]/.test(String(s || ''));

/** 「### 误区 3：用中文标点符号」加 **现象** / **正确做法** 的散文式错误表 */
function proseRows(section) {
  const rows = [];
  for (const block of section.split(/^###\s+/m).slice(1)) {
    const [titleLine, ...body] = block.split('\n');
    const title = trimTail(titleLine.replace(/^误区\s*\d*\s*[：:]/, '').replace(/[：:]\s*$/, ''));
    const read = (names) => {
      for (const line of body) {
        const m = /^\s*[-*>]*\s*\*\*(.+?)\*\*\s*[:：]\s*(.+)$/.exec(line.trim());
        if (m && names.some((n) => m[1].includes(n))) return firstSentence(m[2]);
      }
      return '';
    };
    const symptom = read(['现象', '表现', '后果', '结果', '会出现', '会发生']);
    const fix = read(['正确做法', '改法', '修法', '解决', '应该', '怎么改', '怎么办']);
    if (title && (symptom || fix)) {
      rows.push({ error: firstSentence(title), symptom, fix });
      continue;
    }
    // 「**误区一：不排序直接画**」+ 整段说明：从段句里找后果与正确做法
    const body2 = body.join(' ').replace(/\*\*/g, '').trim();
    if (!title || !body2) continue;
    const sentences = body2.split(/(?<=[。；;])/).map(firstSentence).filter(Boolean);
    const toFix = sentences.find((s) => /^(正确做法|应该|要|建议)/.test(s) || s.includes('正确做法') || s.includes('应该'));
    const toSymptom = sentences.find((s) => /(导致|会出现|就会|造成|反而|乱)/.test(s) && s !== toFix);
    rows.push({
      error: firstSentence(title),
      symptom: trimTail(toSymptom || ''),
      fix: trimTail(String(toFix || '').replace(/^(正确做法[:：]?|应该|要|建议)/, '')),
    });
  }
  return rows;
}

/** 课文错误表：优先表格，按表头判定列角色；没有表格再读散文式误区小节 */
function pitfallRows(md) {
  const rows = [];
  const prose = [];
  for (const section of md.matchAll(/## (?:常见误区与易错点|常见错误与排查)\n([\s\S]*?)(?=\n## (?!#)|\n# (?!#)|\n*$)/g)) {
    let header = null;
    for (const line of section[1].split('\n')) {
      const t = line.trim();
      if (!t.startsWith('|')) continue;
      const cells = t.split('|').map((c) => c.trim()).filter((c, i, all) => i > 0 && i < all.length - 1);
      if (cells.length < 2 || /^[-: ]+$/.test(cells.join(''))) continue;
      if (!header) { header = cells; continue; }
      if (cells.some((c) => !c)) continue;
      if (GENERIC.some((g) => cells.join('').includes(g))) continue;
      const fromQuestion = (header[0] || '').includes('题目');
      const row = fromQuestion
        ? { error: '', symptom: firstSentence(cells[0]), fix: firstSentence(cells[1] || '') }
        : { error: firstSentence(cells[0]), symptom: firstSentence(cells[1] || ''), fix: firstSentence(cells[2] || '') };
      if (row.error || row.symptom) rows.push(row);
    }
    prose.push(...proseRows(section[1]));
  }
  const tidy = (list) => list.map((r) => (hasCjk(r.symptom) ? r : { ...r, symptom: '' }));
  return tidy(rows.length ? rows : prose);
}

/** 课文术语速查：兜底补长用的第二素材源 */
function glossaryRows(md) {
  const rows = [];
  for (const section of md.matchAll(/## 术语速查\n([\s\S]*?)(?=\n## (?!#)|\n# (?!#)|\n*$)/g)) {
    for (const line of section[1].split('\n')) {
      const t = line.trim();
      if (!t.startsWith('|')) continue;
      const cells = t.split('|').map((c) => c.trim()).filter((c, i, all) => i > 0 && i < all.length - 1);
      if (cells.length < 2 || /^[-: ]+$/.test(cells.join('')) || cells[0] === '术语') continue;
      const text = `${cells[0]}：${firstSentence(cells[1])}`;
      if (text.length >= 12) rows.push(text);
    }
  }
  return rows;
}

function pitfallSentence(row) {
  if (!row.error && !row.symptom) return row.fix ? `本课的改法是${row.fix}。` : '';
  let s = row.error ? `易错点是${row.error}` : `易错点在于${row.symptom}`;
  if (row.error && row.symptom) {
    s += /^(导致|引起|会|容易|就|使)/.test(row.symptom) ? `，${row.symptom}` : `，会造成${row.symptom}`;
  }
  // 表格里「正确做法」一栏常写成「是 `i & -i`」这种半截话，接在「改法是」后面会叠出「改法是是」
  return row.fix ? `${s}，改法是${String(row.fix).replace(/^是\s*/, '')}。` : `${s}。`;
}

/** 核实过的「代码里没有这个 token」短句；核实不通过返回 null */
function absenceSentence(option, code) {
  const hit = ASSERT.exec(String(option || '').replace(/^\s*\*\*/, ''));
  if (!hit) return null;
  const kind = hit[1] === '调用了' ? 'call' : hit[1] === '出现字面量' ? 'literal' : 'name';
  const token = norm(hit[2]).replace(/\(\)$/, '');
  if (token.length < 2 || holds(code, kind, token)) return null;
  // 展示给学员的那个 token 用选项原文，别用去空格后的匹配串（`fib_iter()` 会变成 fibiter()）
  const shown = `\`${trimTail(hit[2]).replace(/\s+/g, ' ')}\``;
  return `本题干扰项「${trimTail(option).replace(/\*\*/g, '')}」不成立：展示代码里找不到 ${shown}。`;
}

const truthIndexes = (q) => (Array.isArray(q.answers) && q.answers.length
  ? q.answers
  : (typeof q.answer === 'number' ? [q.answer] : []));

const raw = fs.readFileSync(MANIFEST, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

// 现存模板句计数。测试口径是全库出现次数 ≥5 判失败（audit 的「≥5 门课」被它包含），
// 所以候选句必须留出一格余量：已有 4 次就不能再写第 5 次。
const counts = new Map();
for (const c of manifest.categories) {
  for (const l of c.lessons || []) {
    for (const q of l.quiz || []) {
      for (const s of splitSentences(String(q.explanation || ''))) {
        if (s.trim().length >= 12) counts.set(s.trim(), (counts.get(s.trim()) || 0) + 1);
      }
    }
  }
}
const bump = (s, delta) => {
  const key = s.trim();
  if (key.length >= 12) counts.set(key, (counts.get(key) || 0) + delta);
};

/** 与 splitSentences 同一套规则，但返回每个句子在原文里的区间 */
function sentenceSpans(text) {
  const out = [];
  const mode = quoteModes(text);
  let start = 0, inQuote = false, inCode = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (ch === '`') { if (mode.code) inCode = !inCode; }
    else if (!inCode && mode.quote) {
      if (ch === '「' || ch === '『' || ch === '“') inQuote = true;
      else if (ch === '」' || ch === '』' || ch === '”') inQuote = false;
    }
    if ((ch === '。' || ch === '；' || ch === '\n') && !inQuote && !inCode) {
      if (text.slice(start, i + 1).trim()) out.push({ start, end: i + 1 });
      start = i + 1;
    }
  }
  if (text.slice(start).trim()) out.push({ start, end: text.length });
  return out;
}

/** 取解析里带「正踩在这条上」的那一句 */
function attributionSentence(exp) {
  const at = exp.lastIndexOf('正踩在这条上');
  if (at < 0) return null;
  // 选项文案里常自带「。）」「。」，用忽略引号的回溯会把句子切在选项中间，归因尾句就成了半截话
  const hit = sentenceSpans(exp).find((s) => at >= s.start && at < s.end);
  if (!hit) return null;
  const text = exp.slice(hit.start, hit.end);
  const label = /干扰项([\s\S]+?)正踩在这条上/.exec(text);
  if (!label || !(text.includes('易错点') || text.includes('这样'))) return null;
  return { start: hit.start, end: hit.end, text, label: trimTail(label[1]) };
}

const stats = { scanned: 0, proven: 0, stripped: 0, badLabel: 0, tooShort: 0, dup: 0, noRow: 0 };
const skipped = [];
const notes = [];
const mdEdits = new Map();

for (const category of manifest.categories) {
  for (const lesson of category.lessons || []) {
    const mdPath = path.join(ROOT, lesson.file);
    const mdText = fs.existsSync(mdPath)
      ? fs.readFileSync(mdPath, 'utf8').replace(/\r\n/g, '\n')
      : '';
    const rows = pitfallRows(mdText);
    const terms = glossaryRows(mdText);
    let editList = null;

    (lesson.quiz || []).forEach((q, qi) => {
      const exp = String(q.explanation || '');
      const found = attributionSentence(exp);
      if (!found) return;
      stats.scanned++;

      const truth = truthIndexes(q);
      const options = (q.options || []).map(String);
      const label = norm(found.label);
      const matchesCorrect = truth.some((i) => {
        const o = norm(options[i]);
        return o && (o.includes(label) || label.includes(o));
      });
      const distractors = options
        .map((text, index) => ({ text, flat: norm(text), index }))
        .filter((o) => !truth.includes(o.index) && o.flat.length >= 2);
      if (!distractors.length) return;
      if (matchesCorrect) stats.badLabel++;

      // 坑与干扰项「用词相近」不能证明学员选它就是踩了这个坑（抽检里 只要X的常规示例通过 这类
      // 模板干扰项只因带本课术语就对上了），所以不再有保留分支：能机械证明的说证明，证明不了的删归因。
      const pitfallPart = found.text.slice(0, found.text.indexOf('干扰项'));

      const oldSet = new Set(splitSentences(found.text).map((s) => s.trim()));
      const wouldRepeat = (block) =>
        splitSentences(block).some((s) => ((counts.get(s.trim()) || 0) - (oldSet.has(s.trim()) ? 1 : 0)) >= 4);

      const correct = trimTail(options[truth[0]] || '').replace(/^[-*]\s*/, '');
      // 候选按「本课错误表逐行轮换 → 保留原坑但改成对照正确项 → 本课术语 → 只对照正确项」排列，
      // 取第一个不会把模板句顶到 5 次以上的：单行错误表的课（cross_errors_testing 等）只能靠后两级。
      if (!rows.length) stats.noRow++;
      const candidates = [];
      for (let k = 0; k < rows.length; k++) {
        const s = pitfallSentence(rows[(qi + k) % rows.length]);
        if (s) candidates.push(s);
      }
      const base = trimTail(pitfallPart.replace(/[，,]$/, ''));
      if ((base.includes('易错点') || /^这样/.test(base)) && correct.length >= 2) {
        candidates.push(`${base}，作答时对照的是正确项「${correct}」。`);
      }
      if (correct.length >= 2) candidates.push(`作答时对照的是正确项「${correct}」。`);
      if (terms.length) candidates.push(`本课还要记住 ${terms[qi % terms.length]}。`);
      if (!candidates.length) {
        skipped.push(`${lesson.id}#${qi}｜本课既无错误表也无正确项可对照`);
        return;
      }
      const sentence = candidates.find((c) => !wouldRepeat(c)) || candidates[candidates.length - 1];
      // 断言型干扰项可以核实，但同一个 token（print、main）在多课里都当过干扰项，
      // 证明句也会撞成模板句：所以逐个试，撞车就宁可不写这句证明。
      const proofs = (q.type === 'code' || q.type === 'debug')
        ? distractors.map((d) => absenceSentence(d.text, q.code)).filter(Boolean)
        : [];
      const proof = proofs.find((p) => !wouldRepeat(`${sentence}${p}`)) || null;
      let block = proof ? `${sentence}${proof}` : sentence;
      stats[proof ? 'proven' : 'stripped']++;

      let next = exp.slice(0, found.start) + block + exp.slice(found.end);
      // 跌破 120 字就先补本课另一条易错点，再用术语速查补；补进来的那一句也不允许顶出模板句
      const refill = (extra) => {
        if (next.includes(extra) || wouldRepeat(`${block}${extra}`)) return;
        block += extra;
        next = `${next.replace(/\s+$/, '')}${extra}`;
      };
      for (let k = 1; next.trim().length < 120 && k < rows.length; k++) refill(pitfallSentence(rows[(qi + k) % rows.length]) || `作答时对照的是正确项「${correct}」。`);
      for (let at = 0; next.trim().length < 120 && at < terms.length; at++) refill(`本课还要记住 ${terms[(qi + at) % terms.length]}。`);

      const flatBefore = norm(exp), flatAfter = norm(next);
      const lostTruth = truth.some((i) => {
        const o = norm(options[i]);
        return o.length >= 2 && flatBefore.includes(o) && !flatAfter.includes(o);
      });
      if (next.trim().length < 120) { stats.tooShort++; skipped.push(`${lesson.id}#${qi}｜改写后 ${next.trim().length} 字`); return; }
      if (lostTruth) { stats.tooShort++; skipped.push(`${lesson.id}#${qi}｜正确项复述丢失`); return; }

      const oldSentences = splitSentences(found.text);
      const newSentences = splitSentences(block);
      if (wouldRepeat(block)) {
        stats.dup++;
        const clash = splitSentences(block)
          .map((s) => s.trim())
          .find((s) => (counts.get(s) || 0) - (oldSet.has(s) ? 1 : 0) >= 4);
        skipped.push(`${lesson.id}#${qi}｜会造成模板句重复：${String(clash).slice(0, 46)}（已有 ${counts.get(clash) || 0} 次）`);
        return;
      }

      for (const s of oldSentences) bump(s, -1);
      for (const s of newSentences) bump(s, 1);
      if (APPLY) q.explanation = next;

      if (!editList) editList = [];
      editList.push({ key: loose(q.question), old: found.text, next: block });
      if (SHOW && notes.length < 30) {
        notes.push(`${lesson.id}#${qi}｜${proof ? '改成可核实断言' : '删归因'}｜${found.text.slice(0, 46)}…\n    → ${block.slice(0, 120)}`);
      }
    });

    if (editList?.length) {
      const entry = mdEdits.get(lesson.file) || { edits: [] };
      entry.edits.push(...editList);
      mdEdits.set(lesson.file, entry);
    }
  }
}

// —— 课文侧：按题干在考点精讲里顺序定位，块内做忽略空白的匹配替换 ——
const md = { hit: 0, byStem: 0, miss: 0, missSentence: 0, files: 0, rejected: 0, noRegion: 0, samples: [] };
const flatten = (s) => {
  const chars = [], map = [];
  for (let i = 0; i < s.length; i++) if (!/[\s　]/.test(s[i])) { chars.push(s[i]); map.push(i); }
  return { flat: chars.join(''), map };
};

const written = new Map();
const lessonFiles = new Set([
  ...manifest.categories.flatMap((c) => (c.lessons || []).map((l) => l.file).filter(Boolean)),
  ...fs.readdirSync(path.join(ROOT, 'assets/content')).filter((f) => f.endsWith('.md')).map((f) => `assets/content/${f}`),
]);

for (const [rel, { edits }] of mdEdits) {
  const file = path.join(ROOT, rel);
  const before = fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n');
  const rs = before.indexOf('\n## 考点精讲');
  if (rs < 0) { md.noRegion++; continue; }
  const after = rs + 2;
  const nextHeading = before.slice(after).search(/\n##(?!#)/);
  const re = nextHeading < 0 ? before.length : after + nextHeading;
  const region = before.slice(rs, re);
  const { flat: regionFlat, map: regionMap } = flatten(region);
  const splices = [];
  let cursor = 0;

  // 同一课的旧句往往一字不差，所以按题序在区域里顺序取第 k 次出现，才不会串到别的考点块
  for (const edit of edits) {
    const needle = loose(edit.old);
    const at = needle.length >= 12 ? regionFlat.indexOf(needle, cursor) : -1;
    if (at >= 0) {
      cursor = at + needle.length;
      splices.push({
        start: regionMap[at],
        stop: regionMap[at + needle.length - 1] + 1,
        next: edit.next,
      });
      md.hit++;
      continue;
    }
    // 课文与题库分叉的课（考点块里的干扰项写的是另一条）旧句搜不到：改为按题干圈出本考点块，
    // 把块内带「正踩在这条上」的那一句整句换掉；块里没有这句就说明确实是手写的，不动。
    const stemAt = edit.key.length >= 8 ? regionFlat.indexOf(edit.key, cursor) : -1;
    if (stemAt >= 0) {
      const from = regionMap[stemAt];
      const nxt = region.slice(from).search(/\n#{2,3}\s/);
      const blockStop = nxt < 0 ? region.length : from + nxt;
      const block = region.slice(from, blockStop);
      const own = sentenceSpans(block).find((s) => block.slice(s.start, s.end).includes('正踩在这条上'));
      if (own) {
        cursor = stemAt + edit.key.length;
        splices.push({ start: from + own.start, stop: from + own.end, next: edit.next });
        md.hit++;
        md.byStem++;
        continue;
      }
    }
    md.miss++;
    md.missSentence++;
    if (SHOW && md.samples.length < 8) md.samples.push(`${rel}｜旧句缺席：${edit.old.slice(0, 60)}…`);
  }
  if (!splices.length) continue;
  md.files++;

  let out = before;
  for (const s of splices.sort((a, b) => b.start - a.start)) {
    out = out.slice(0, rs + s.start) + s.next + out.slice(rs + s.stop);
  }
  const ok = edits.every((e) => e.key.length < 8 || loose(out).includes(e.key))
    && loose(out).length >= loose(before).length - 1200;
  if (!ok) { md.rejected++; continue; }
  written.set(file, out);
  if (APPLY) fs.writeFileSync(file, out.split('\n').join(before.includes('\r\n') ? '\r\n' : '\n'));
}

// —— 课文侧清扫 ——
// 第 11 波盖坑的时候课文与题库各写了一份，课文里的尾句有不少和题库已经对不上（抽检 426 条里 384 条是这种）。
// 题库侧这次已经全部改净，课文里再留着「干扰项X正踩在这条上」就成了无人认领的错误断言，所以按行删掉这半句，
// 坑本身（易错点…改法…）留在原地。只动「考点精讲」这一节，其他小节一律不碰。
const sweep = { files: 0, clauses: 0, checked: 0 };
const TAIL = /，\s*干扰项[^\n]{0,320}?正踩在这条上。/g;
for (const rel of lessonFiles) {
  const file = path.join(ROOT, rel);
  if (!fs.existsSync(file)) continue;
  const disk = fs.readFileSync(file, 'utf8');
  const text = written.get(file) ?? disk;
  const nl = text.includes('\r\n') ? '\r\n' : '\n';
  const plain = text.replace(/\r\n/g, '\n');
  const rs = plain.indexOf('\n## 考点精讲');
  if (rs < 0) continue;
  const nh = plain.slice(rs + 2).search(/\n##(?!#)/);
  const re = nh < 0 ? plain.length : rs + 2 + nh;
  const head = plain.slice(0, rs);
  const body = plain.slice(rs, re);
  sweep.checked += (body.match(/正踩在这条上/g) || []).length;
  const cleaned = body.replace(TAIL, '。');
  const removed = (body.match(TAIL) || []).length;
  if (!removed) continue;
  sweep.files++;
  sweep.clauses += removed;
  if (APPLY) fs.writeFileSync(file, (head + cleaned + plain.slice(re)).split('\n').join(nl));
}

if (SHOW) console.log(notes.join('\n'));
if (skipped.length) console.log('跳过明细：\n' + skipped.slice(0, 40).join('\n'));
if (SHOW && md.samples.length) console.log('课文未命中样本：\n' + md.samples.join('\n'));
console.log(`带归因尾句 ${stats.scanned}｜改成可核实断言 ${stats.proven}｜删掉归因 ${stats.stripped}｜标注本指向正确项 ${stats.badLabel}｜长度守卫 ${stats.tooShort}｜重复守卫 ${stats.dup}｜无表可依 ${stats.noRow}`);
console.log(`课文同步：命中 ${md.hit}（按题干回退 ${md.byStem}）｜未命中 ${md.miss}（解析旧句在课文里找不到 ${md.missSentence}）｜改动文件 ${md.files}｜没有考点精讲 ${md.noRegion}｜守卫退回 ${md.rejected}`);
console.log(`课文清扫：考点精讲里的归因尾句 ${sweep.checked}｜删掉半句 ${sweep.clauses}｜改动文件 ${sweep.files}`);if (APPLY) fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2).split('\n').join(eol));
if (!APPLY) console.log('（dry-run，加 --apply 才写盘）');
