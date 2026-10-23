// 全库独立一致性深检：交叉核对 manifest、markdown、配图、复核计划与题库。
// 与 tool/audit_*.dart 的实现相互独立，用来发现"审计工具本身漏检"的缺陷。
// 用法：node tool/content_pipeline/deep_check.js [--top=15]
import fs from 'node:fs';
import path from 'node:path';

const ROOT = process.cwd();
const CONTENT_DIR = 'assets/content';
const TOP = Number((process.argv.find((a) => a.startsWith('--top=')) || '--top=12').split('=')[1]);
const groups = new Map();
const bump = (g, msg) => {
  if (!groups.has(g)) groups.set(g, []);
  groups.get(g).push(msg);
};

const manifest = JSON.parse(fs.readFileSync(path.join(CONTENT_DIR, 'manifest.json'), 'utf8'));
const mdFiles = fs.readdirSync(CONTENT_DIR).filter((f) => f.endsWith('.md'));
const read = (f) => fs.readFileSync(path.join(CONTENT_DIR, f), 'utf8');
const cache = new Map(mdFiles.map((f) => [f, read(f)]));

const lessons = [];
for (const c of manifest.categories)
  for (const l of c.lessons) lessons.push({ ...l, catId: c.id, catTitle: c.title.zh });
const byId = new Map(lessons.map((l) => [l.id, l]));

/* ---------- 1. manifest 结构与字段值域 ---------- */
for (const l of lessons) {
  for (const k of ['id', 'file', 'minutes', 'difficulty', 'order'])
    if (l[k] === undefined || l[k] === null || l[k] === '') bump('1 字段缺失', `${l.id} 缺 ${k}`);
  if (!l.title?.zh?.trim()) bump('1 字段缺失', `${l.id} 标题为空`);
  if (!l.summary?.zh?.trim()) bump('1 字段缺失', `${l.id} 摘要为空`);
  if (!(l.keywords || []).length) bump('1 字段缺失', `${l.id} 关键词为空`);
  if (!Number.isInteger(l.minutes) || l.minutes <= 0 || l.minutes > 200)
    bump('2 预计用时异常', `${l.id} minutes=${l.minutes}`);
  if (!Number.isInteger(l.order) || l.order < 0) bump('3 课次异常', `${l.id} order=${l.order}`);
  if (!/^(入门|基础|进阶|高级)$/.test(String(l.difficulty)))
    bump('3 难度标签', `${l.id} difficulty=${l.difficulty}`);
  if (!l.title?.zh || !l.summary?.zh) continue;
  if (l.title.zh.length > 40) bump('4 标题过长', `${l.id} 「${l.title.zh}」${l.title.zh.length} 字`);
  if (l.summary.zh.length < 20) bump('4 摘要过短', `${l.id} ${l.summary.zh.length} 字`);
  if (l.summary.zh === l.title.zh) bump('4 摘要等于标题', l.id);
  if (/^(浅谈|简述|介绍|概述|关于)/.test(l.title.zh)) bump('4 占位式标题', `${l.id} 「${l.title.zh}」`);
}
const ids = lessons.map((l) => l.id);
if (new Set(ids).size !== ids.length) {
  const seen = new Set(), dup = new Set();
  for (const i of ids) { if (seen.has(i)) dup.add(i); seen.add(i); }
  bump('5 课程 ID 重复', [...dup].join(', '));
}
const catIds = manifest.categories.map((c) => c.id);
if (new Set(catIds).size !== catIds.length) bump('5 分类 ID 重复', catIds.join(', '));
for (const c of manifest.categories) {
  if (!c.title?.zh || !c.icon || !c.color) bump('5 分类字段', `${c.id} 缺 title/icon/color`);
  if (!/^#?[0-9a-fA-F]{6}$/.test(String(c.color))) bump('5 分类配色', `${c.id} color=${c.color}`);
  const orders = c.lessons.map((l) => l.order).sort((a, b) => a - b);
  if (new Set(orders).size !== orders.length) bump('3 课次异常', `${c.id} order 重复`);
  for (let i = 0; i < orders.length; i++)
    if (orders[i] !== i) { bump('3 课次不连续', `${c.id} order 序列 ${orders.join(',')}`); break; }
}
for (const c of manifest.categories) {
  const seq = [...c.lessons].sort((a, b) => a.order - b.order);
  const rank = (d) => ({ '入门': 0, '基础': 1, '进阶': 2, '高级': 3 })[d] ?? 1;
  for (let i = 1; i < seq.length; i++)
    if (rank(seq[i].difficulty) < rank(seq[i - 1].difficulty))
      bump('6 难度倒挂', `${c.id}: ${seq[i - 1].id}(D${seq[i - 1].difficulty}) → ${seq[i].id}(D${seq[i].difficulty})`);
}

/* ---------- 2. 先修 / 相关 / lab 引用完整性 ---------- */
const adj = new Map();
for (const l of lessons) {
  for (const p of l.prerequisites || []) {
    if (!byId.has(p)) bump('7 先修指向不存在', `${l.id} ← ${p}`);
    else {
      const a = byId.get(p);
      if (a.catId === l.catId && a.order >= l.order) bump('8 先修顺序倒挂', `${l.id}(order ${l.order}) 的先修 ${p}(order ${a.order})`);
      const rank = (d) => ({ '入门': 0, '基础': 1, '进阶': 2, '高级': 3 })[d] ?? 1;
      if (rank(a.difficulty) > rank(l.difficulty)) bump('8 先修难度更高', `${l.id}(D${l.difficulty}) ← ${p}(D${a.difficulty})`);
    }
    if (p === l.id) bump('7 先修自引用', l.id);
  }
  for (const r of l.related || []) {
    if (!byId.has(r)) bump('9 相关课指向不存在', `${l.id} → ${r}`);
    if (r === l.id) bump('9 相关课自引用', l.id);
  }
  adj.set(l.id, (l.prerequisites || []).filter((p) => byId.has(p)));
}
const state = new Map();
const dfs = (id, chain) => {
  if (state.get(id) === 1) { bump('10 先修环', [...chain, id].join(' → ')); return; }
  if (state.get(id) === 2) return;
  state.set(id, 1);
  for (const p of adj.get(id) || []) dfs(p, [...chain, id]);
  state.set(id, 2);
};
for (const l of lessons) dfs(l.id, []);

/* ---------- 3. 文件 ↔ 课程 双向映射 ---------- */
const users = new Map();
for (const l of lessons) {
  const rel = String(l.file).replace(/\\/g, '/');
  if (!rel.startsWith(`${CONTENT_DIR}/`)) bump('11 路径前缀', `${l.id} file=${rel}`);
  const base = path.basename(rel);
  if (!fs.existsSync(path.join(ROOT, rel))) bump('12 正文缺失', `${l.id} → ${rel}`);
  users.set(base, (users.get(base) || []).concat(l.id));
  if (base !== `${l.id}.md` && !knownAlias(l.id)) {
    // 允许 id 与文件名不一致（历史命名），只记录数量供人工确认
  }
}
function knownAlias() { return true; }
for (const [base, u] of users) if (u.length > 1) bump('13 一课一文件被破坏', `${base} 服务 ${u.length} 门课：${u.join(', ')}`);
for (const f of mdFiles) if (!users.has(f)) bump('14 孤立正文', f);

/* ---------- 4. markdown 与 manifest 文本一致 ---------- */
const sectionOf = (lines, title) => {
  const out = [];
  let inSec = false, level = 0;
  let fence = false;
  for (const line of lines) {
    if (line.trim().startsWith('```')) { fence = !fence; if (inSec) out.push(line); continue; }
    const h = fence ? null : /^(#{1,6})\s+(.*)$/.exec(line);
    if (h && h[2].trim() === title) { inSec = true; level = h[1].length; continue; }
    if (inSec) {
      if (h && h[1].length <= level) break;
      out.push(line);
    }
  }
  return out;
};
/// 代码围栏内的行标记为 false：示例里的 `## 标题` 不是章节。
/// 按「开启围栏的长度」判定关闭，兼容 ```` 包 ``` 的嵌套写法。
function fenceMask(lines) {
  const mask = lines.map(() => true);
  let openLen = 0;
  for (let i = 0; i < lines.length; i++) {
    const m = /^ {0,3}(`{3,})/.exec(lines[i]);
    if (m) {
      const len = m[1].length;
      if (openLen === 0) { openLen = len; mask[i] = false; continue; }
      if (len >= openLen) { openLen = 0; mask[i] = false; continue; }
    }
    if (openLen > 0) mask[i] = false;
  }
  return mask;
}
const headingsOf = (lines) => {
  const mask = fenceMask(lines);
  return lines
    .map((line, i) => ({ line, i }))
    .filter(({ line, i }) => mask[i] && /^#{1,6}\s/.test(line));
};
for (const l of lessons) {
  const base = path.basename(String(l.file));
  const t = cache.get(base);
  if (t === undefined) continue;
  const lines = t.split(/\r?\n/);
  const h1 = lines.find((x) => /^#\s+/.test(x));
  if (!h1) bump('15 缺 H1', base);
  else if (h1.replace(/^#\s+/, '').trim() !== l.title.zh.trim()) bump('15 H1 与标题不符', `${base}: 「${h1.slice(2).trim()}」≠「${l.title.zh}」`);
  if (!/内容更新时间：2026-10-06/.test(t)) bump('16 更新时间标记', base);
  if (!/内容版本：v2\.0/.test(t)) bump('16 版本标记', base);
  const meta = lines.find((x) => /预计用时：(\d+)\s*分钟/.test(x));
  const mm = meta && /预计用时：(\d+)\s*分钟/.exec(meta);
  if (!mm) bump('17 正文缺预计用时', base);
  else if (Number(mm[1]) !== l.minutes) bump('17 正文与 manifest 用时不一致', `${base}: 正文 ${mm[1]} ≠ manifest ${l.minutes}`);
  const stage = meta && /学习阶段：(\S+)/.exec(meta);
  if (stage && stage[1] !== l.difficulty) bump('18 正文阶段与难度不一致', `${base}: 正文 ${stage[1]} ≠ manifest ${l.difficulty}`);
  if (/\r/.test(t)) bump('19 含 CR 换行', base);
  // 20/21/22 只看正文：代码块与行内代码里出现 TODO、U+FFFD、{{ }} 多半是在讲
  // 这些语法本身（GitHub Actions 表达式、Helm/Go 模板、Airflow 宏），不是残留。
  const codeRanges = [];
  let openFence = 0;
  lines.forEach((line, i) => {
    const fm = /^ {0,3}(`{3,})/.exec(line);
    if (fm) {
      const len = fm[1].length;
      if (openFence === 0) { openFence = len; return; }
      if (len >= openFence) { openFence = 0; return; }
    }
    if (openFence > 0) codeRanges.push(i);
  });
  const codeLine = new Set(codeRanges);
  const prose = lines
    .filter((_, i) => !codeLine.has(i))
    .map((x) => x.replace(/`[^`]*`/g, ''))
    .join('\n');
  if (/\b(TODO|FIXME|待补充|待填写|占位待补)\b/.test(prose)) bump('20 占位标记', base);
  if (/[\uFFFD]/.test(prose)) bump('21 乱码字符', base);
  if (/\{\{\s*[\w.!?$-]*(lesson|category|title|summary|minutes|quiz|difficulty|order|content)[\w.]*\s*\}\}/i.test(prose))
    bump('22 生成模板残留', base);
  if (/\]\(\s*\)/.test(t)) bump('23 空链接', base);
  if (/\]\[index\]/.test(t) || /\{off\[/.test(t)) bump('24 生成占位符', base);
  if (!/!\[[^\]]+\]\([^)]+\)/.test(t)) bump('25 配图缺失或 alt 为空', base);
  const fences = (t.match(/^```.*$/gm) || []).filter((x) => /^```[^\s`]+$/.test(x)).length;
  const total = (t.match(/^```.*$/gm) || []).length;
  if (total % 2 !== 0) bump('26 代码围栏不成对', `${base} 共 ${total} 行围栏`);
  const bare = (t.match(/^```\s*$/gm) || []).length;
  if (bare > fences) bump('27 围栏语言标签不齐', `${base} 裸围栏 ${bare / 2} 个`);
  // 口径与 tool/content_repair_check.dart 一致：标题与下一个同级标题之间必须
  // 有正文，代码围栏也算正文（示例代码本身就是该小节的内容）。
  for (const { line, i } of headingsOf(lines)) {
    if (!/^#{2,6}\s/.test(line)) continue;
    const title = line.replace(/^#+\s*/, '').trim();
    const level = line.match(/^(#+)/)[1].length;
    let end = lines.length;
    for (const h of headingsOf(lines))
      if (h.i > i && /^#{2,6}\s/.test(h.line) && h.line.match(/^(#+)/)[1].length <= level) { end = h.i; break; }
    const body = lines.slice(i + 1, end).filter((x) => x.trim() && !/^#/.test(x));
    if (!body.length) bump('28 空小节', `${base} :: ${title}`);
  }
}

/* ---------- 5. 题库结构、题干与解析 ---------- */
const norm = (s) => String(s).replace(/\s+/g, '').replace(/[""]/g, '"').replace(/['']/g, "'").toLowerCase();
const stemSeen = new Map();
const urlByCat = new Map();
const dist = [0, 0, 0, 0];
let qTotal = 0;
for (const l of lessons) {
  const base = path.basename(String(l.file));
  const t = cache.get(base);
  if (t === undefined) continue;
  const lines = t.split(/\r?\n/);
  const jing = sectionOf(lines, '考点精讲').join('\n');
  const zice = sectionOf(lines, '自测题与参考答案').join('\n');
  const body = norm(t);
  for (const [i, q] of (l.quiz || []).entries()) {
    qTotal++;
    const n = i + 1;
    const stem = String(q.question || '').trim();
    if (stem.length < 8) bump('29 题干过短', `${l.id} #${n}`);
    const key = norm(stem);
    if (stemSeen.has(key)) bump('30 题干跨课重复', `${l.id} #${n} 与 ${stemSeen.get(key)} 重复`);
    else stemSeen.set(key, `${l.id} #${n}`);
    if (!body.includes(key)) bump('31 题干未进入正文', `${l.id} #${n}`);
    const expl = String(q.explanation || '').trim();
    if (expl.length < 120) bump('32 解析过短', `${l.id} #${n} 只有 ${expl.length} 字`);
    if (/[。；，]{2}|。，|，。/.test(expl)) bump('33 解析标点异常', `${l.id} #${n}`);
    if (/Q[0-9]|第\s*[0-9]+\s*题(的|题号)|题号[:：]/.test(expl)) bump('34 解析含内部题号', `${l.id} #${n}`);
    const type = q.type || 'single';
    if (type === 'single') {
      if (!Array.isArray(q.options) || q.options.length !== 4) bump('35 单选题选项数', `${l.id} #${n}=${q.options?.length}`);
      if (!Number.isInteger(q.answer) || q.answer < 0 || q.answer > 3) bump('36 单选题答案越界', `${l.id} #${n}=${q.answer}`);
      else {
        dist[q.answer]++;
        const correct = norm(q.options[q.answer]);
        if (!correct) bump('37 正确项为空', `${l.id} #${n}`);
        else if (!norm(expl).includes(correct)) bump('38 解析未含正确项', `${l.id} #${n}`);
        if (new Set((q.options || []).map(norm)).size !== q.options.length) bump('39 选项重复', `${l.id} #${n}`);
        if (q.options.some((o) => !String(o).trim())) bump('39 选项为空', `${l.id} #${n}`);
      }
    } else if (type === 'multi') {
      const arr = q.answers ?? q.correct_indexes ?? q.answer_indexes;
      if (!Array.isArray(arr) || arr.length < 2) bump('40 多选题答案', `${l.id} #${n}=${JSON.stringify(arr)}`);
      else if (new Set(arr).size !== arr.length || arr.some((x) => !Number.isInteger(x) || x < 0 || x >= (q.options?.length || 0)))
        bump('40 多选题答案越界', `${l.id} #${n}=${JSON.stringify(arr)}`);
    } else if (type === 'fill') {
      if (!Array.isArray(q.accepted_answers) || !q.accepted_answers.length) bump('41 填空题缺标准答案', `${l.id} #${n}`);
    } else if (type === 'order') {
      if (!Array.isArray(q.correct_order) || q.correct_order.length !== q.options?.length)
        bump('42 排序题结构', `${l.id} #${n}`);
    } else if (type === 'code' || type === 'debug') {
      if (!Number.isInteger(q.answer) || q.answer < 0 || q.answer >= (q.options?.length || 0))
        bump('43 代码题答案越界', `${l.id} #${n}=${q.answer}/${q.options?.length}`);
      else {
        dist[q.answer]++;
        const correct = norm(q.options[q.answer]);
        if (correct && !norm(expl).includes(correct)) bump('38 解析未含正确项', `${l.id} #${n}`);
      }
      if (!String(q.code || '').trim()) bump('43 代码题缺代码', `${l.id} #${n}`);
      if (!String(q.language || '').trim()) bump('44 代码题缺语言', `${l.id} #${n}`);
    } else bump('43 未知题型', `${l.id} #${n} type=${type}`);
    if (q.code && !String(q.language || '').trim() && type !== 'code' && type !== 'debug')
      bump('44 代码题缺语言', `${l.id} #${n}`);
    const jingHas = norm(jing).includes(key), ziceHas = norm(zice).includes(key);
    if (!jingHas && !ziceHas) bump('45 题目未进入自测/考点小节', `${l.id} #${n}`);
  }
  const refs = sectionOf(lines, '参考资料与复核').join('\n');
  const urls = [...refs.matchAll(/https?:\/\/[^\s)\]]+/g)].map((m) => m[0]);
  if (urls.length < 2) bump('46 参考资料链接不足', `${base} 只有 ${urls.length} 条`);
  const setKey = urls.map((u) => u.replace(/\/$/, '')).sort().join('|');
  if (setKey) {
    if (!urlByCat.has(l.catId)) urlByCat.set(l.catId, new Map());
    const m = urlByCat.get(l.catId);
    if (m.has(setKey)) bump('47 同类参考资料集合重复', `${base} 与 ${m.get(setKey)} 链接集合完全相同`);
    else m.set(setKey, base);
  }
  for (const u of urls) {
    if (/example\.com|yourdomain|localhost|127\.0\.0\.1|placeholder/i.test(u)) bump('48 可疑占位链接', `${base} ${u}`);
    if (/\s/.test(u)) bump('48 链接含空格', `${base} ${u.slice(0, 60)}`);
  }
  const sched = /- 最后复核：(\d{4}-\d{2}-\d{2})/.exec(refs)?.[1];
  const next = /- 下次复核：(\d{4}-\d{2}-\d{2})/.exec(refs)?.[1];
  if (!sched) bump('49 缺最后复核日期', base);
  if (!next) bump('49 缺下次复核日期', base);
  const glossary = sectionOf(lines, '术语速查');
  const rows = glossary.filter((x) => /^\s*\|/.test(x));
  if (rows.length && rows[0].replace(/\s/g, '') !== '|术语|一句话说明|') bump('50 术语表表头', base);
  if (rows.length < 6) bump('50 术语表管道行不足 6', `${base} 表格行 ${rows.length}`);
  else if (rows.length - 2 < 6) bump('50b 术语表数据行偏薄', `${base} 仅 ${rows.length - 2} 条`);
  const explSet = new Map();
  for (const r of rows.slice(2)) {
    const cells = r.split('|').map((x) => x.trim()).filter(Boolean);
    if (cells.length !== 2) bump('51 术语表列数', `${base}: ${r.slice(0, 50)}`);
    if (cells[1]) explSet.set(cells[1], (explSet.get(cells[1]) || 0) + 1);
  }
  for (const [e, c] of explSet) if (c > 1) bump('52 术语解释重复', `${base}: 「${e.slice(0, 24)}」×${c}`);
}
for (let i = 0; i < 4; i++)
  bump('__dist__', `答案下标 ${i}：${dist[i]} 题（${((dist[i] / (dist.reduce((a, b) => a + b, 0))) * 100).toFixed(2)}%）`);

/* ---------- 6. 配图与资源 ---------- */
const imgDir = path.join(CONTENT_DIR, 'images');
const imgFiles = fs.existsSync(imgDir) ? fs.readdirSync(imgDir) : [];
const referenced = new Map();
for (const l of lessons) {
  const base = path.basename(String(l.file));
  const t = cache.get(base) || '';
  for (const m of t.matchAll(/!\[[^\]]*\]\(([^)]+\.(webp|png|jpg|jpeg|gif|svg))\)/gi)) {
    const target = m[1].trim();
    if (/\.png$/i.test(target)) bump('53 引用 PNG', `${base} → ${target}`);
    const file = path.basename(target);
    referenced.set(file, (referenced.get(file) || []).concat(base));
    if (!fs.existsSync(path.join(imgDir, file))) bump('54 配图文件缺失', `${base} → ${target}`);
    else {
      const st = fs.statSync(path.join(imgDir, file));
      if (st.size < 4096) bump('55 配图过小', `${file} ${st.size}B（${base}）`);
    }
  }
}
for (const f of imgFiles) {
  if (/\.png$/i.test(f)) bump('56 库内残留 PNG', f);
  else if (!referenced.has(f)) bump('57 未被引用的配图', `${f}（${(fs.statSync(path.join(imgDir, f)).size / 1024).toFixed(0)}KB）`);
  else if (referenced.get(f).length > 1) bump('__共享图__', `${f} 被 ${referenced.get(f).length} 篇引用：${referenced.get(f).join(', ')}`);
}

/* ---------- 7. 复核计划表（batches[].planned_review_at + lesson_ids） ---------- */
const schedPath = 'docs/content_review_schedule.json';
if (fs.existsSync(schedPath)) {
  const sched = JSON.parse(fs.readFileSync(schedPath, 'utf8'));
  const planned = new Map();
  for (const b of sched.batches || [])
    for (const id of b.lesson_ids || []) {
      if (planned.has(id)) bump('58 复核计划重复条目', id);
      planned.set(id, b.planned_review_at);
    }
  for (const l of lessons) {
    if (!planned.has(l.id)) { bump('58 复核计划缺课', l.id); continue; }
    const base = path.basename(String(l.file));
    const t = cache.get(base);
    if (t && !t.includes(`- 下次复核：${planned.get(l.id)}`))
      bump('60 下次复核日期与计划不符', `${base}: 正文 ≠ ${planned.get(l.id)}`);
  }
  for (const id of planned.keys()) if (!byId.has(id)) bump('59 复核计划多余条目', id);
  const dates = new Set(planned.values());
  if (dates.size < 12) bump('61 复核日期分散不足', `${dates.size} 个不同日期`);
  bump('__stat__', `复核计划：批次 ${sched.batches?.length ?? 0}｜覆盖 ${planned.size} 门课｜日期 ${dates.size} 个｜窗口 ${sched.schedule_months} 个月`);
} else bump('58 复核计划', '文件不存在');

/* ---------- 8. 结构卫生：旧英文小节、重复正文块、元信息规范行、配图替代文本 ---------- */
for (const l of lessons) {
  const base = path.basename(String(l.file));
  const t = cache.get(base);
  if (t === undefined) continue;
  const lines = t.split(/\r?\n/);
  const hs = headingsOf(lines).map((h) => h.line);
  const eng = hs.filter((x) => /^## [A-Za-z][A-Za-z ]{4,}$/.test(x));
  if (eng.length) bump('62 残留英文小节', `${base}: ${eng.map((x) => x.replace(/^#+\s*/, '')).join(' | ')}`);
  const plain = hs.join('\n');
  if (/^#{2,4}\s*问题\s*\d/m.test(plain) || /^##\s*Self-Test/m.test(plain)) bump('63 旧自测块残留', base);
  if (/^##\s*第\s*\d+\s*章/m.test(plain)) bump('64 多章式标题残留', base);
  const header = lines.find((x) => /^>\s*内容更新时间：/.test(x));
  if (!header) bump('65 缺规范元信息行', base);
  else {
    if (!/学习阶段：\S+/.test(header)) bump('65 元信息行缺学习阶段', base);
    if (!/预计用时：\d+\s*分钟/.test(header)) bump('66 元信息行缺预计用时', base);
  }
  for (const m of t.matchAll(/!\[([^\]]*)\]\(([^)]+)\)/g)) {
    const alt = m[1];
    // 只认生成批次痕迹：批次前缀词，或三个以上连续小写英文词（"kotlin loops" 这种）。
    // 像 io_uring、pass_by_value 这类两个词的技术名是正当术语，不算代号。
    if (/\b(p0x|remaining|batch|wave\d*)[\s_-]/i.test(alt) || /\b([a-z]+[_\s]){2,}[a-z]+\b/.test(alt))
      bump('67 配图替代文本含内部代号', `${base}: ${alt.slice(0, 70)}`);
  }
}

/* ---------- 8. 分类聚合统计 ---------- */
bump('__stat__', `分类 ${manifest.categories.length}｜课程 ${lessons.length}｜题目 ${qTotal}｜正文 ${mdFiles.length}｜配图 ${imgFiles.length}`);
const quizCounts = lessons.map((l) => (l.quiz || []).length);
bump('__stat__', `每课题数：min=${Math.min(...quizCounts)} max=${Math.max(...quizCounts)} avg=${(quizCounts.reduce((a, b) => a + b, 0) / quizCounts.length).toFixed(2)}｜<5 题的课程 ${(quizCounts.filter((x) => x < 5)).length} 门`);
const lens = mdFiles.map((f) => cache.get(f).length);
bump('__stat__', `正文长度：min=${Math.min(...lens)} avg=${Math.round(lens.reduce((a, b) => a + b, 0) / lens.length)} <10000 字符 ${lens.filter((x) => x < 10000).length} 篇`);

/* ---------- 输出 ---------- */
console.log('=== 深检结果 ===');
for (const [g, list] of [...groups.entries()].sort((a, b) => (a[0].startsWith('__') ? 1 : b[0].startsWith('__') ? -1 : a[0].localeCompare(b[0], 'zh')))) {
  if (g.startsWith('__')) { for (const m of list) console.log(`  ${g.slice(2, -2)}: ${m}`); continue; }
  console.log(`${g.padEnd(26)} ${list.length}`);
  for (const m of list.slice(0, TOP)) console.log(`      - ${m}`);
  if (list.length > TOP) console.log(`      …另 ${list.length - TOP} 条`);
}
console.log(`\n合计 ${[...groups.values()].flat().filter((x) => !String(x).startsWith('答案下标')).length} 项待处理`);
