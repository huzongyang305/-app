// 第二批结构修复：把「旧骨架 + 新骨架并存」的课程合并，并去掉正文里的内部题号。
//   A) 11 门课（9 门 mobile + 2 门 backend）同时带英文旧骨架和中文规范骨架，
//      正文渲染两遍、自测题出现两套。这里把旧骨架按语义并入对应规范小节，
//      只删除与当前题库重复的旧自测块。
//   B) 57 个文件的 考点精讲 用 `### 问题N` 当小标题，把内部编号透给了用户。
//      统一改成 `### 考点 N`。
// 用法：node tool/content_pipeline/wave2_fixes.js [--apply]
import fs from 'node:fs';
import path from 'node:path';

const APPLY = process.argv.includes('--apply');
const LIST = process.argv.includes('--list');
const CONTENT_DIR = 'assets/content';
const manifest = JSON.parse(fs.readFileSync(path.join(CONTENT_DIR, 'manifest.json'), 'utf8'));
const lessons = [];
for (const c of manifest.categories) for (const l of c.lessons) lessons.push({ ...l, catId: c.id });

const CANONICAL = [
  '本节知识框架', '核心概念定义', '原理与运行机制', '典型应用场景', '代码/协议/SQL 示例',
  '时间/空间复杂度或性能分析', '常见误区与易错点', '与其他知识点的关系', '自测题与参考答案',
  '考点精讲', '术语速查', '参考资料与复核', '内容元数据',
];
// 旧骨架标题 → [目标规范小节, 并入后的小标题]；目标为 null 表示整块删除。
const LEGACY_MAP = [
  [/^chapter overview$/i, '本节知识框架', '课程导言'],
  [/^learning objectives$/i, '本节知识框架', '学习目标'],
  [/^english overview$/i, '本节知识框架', '课程导言'],
  [/^(章节摘要|本章摘要|课程概览与学习目标|章节总览)$/, '本节知识框架', '课程导言'],
  [/^学习目标$/, '本节知识框架', '学习目标'],
  [/^复习清单$/, '本节知识框架', '复习清单'],
  [/^核心概念与生活类比$/, '原理与运行机制', '生活类比拆解'],
  [/^core concepts with life analogies$/i, '原理与运行机制', '生活类比拆解'],
  [/^核心概念解析$/, '原理与运行机制', '核心概念解析'],
  [/^渐进式代码示例$/, '代码/协议/SQL 示例', '渐进式代码示例'],
  [/^progressive code examples$/i, '代码/协议/SQL 示例', '渐进式代码示例'],
  [/^常见陷阱与解决方案$/, '常见误区与易错点', '常见陷阱与解决方案'],
  [/^常见陷阱对照表$/, '常见误区与易错点', '常见陷阱对照表'],
  [/^common pitfalls table$/i, '常见误区与易错点', '常见陷阱与解决方案'],
  [/^(自测题|自测题目|自我测试)$/, null, null],
  [/^self-test questions$/i, null, null],
  [/^(进阶学习资源|延伸阅读)$/, '参考资料与复核', '进阶学习资源'],
  [/^与其他知识点关系$/, '与其他知识点的关系', '补充关联'],
  [/^(复杂度|复杂度与性能)$/, '时间/空间复杂度或性能分析', '补充性能分析'],
];
// 旧骨架里直接就是英文课名的整块（backend 两门课）。
const isEnglishTitleBlock = (title, lesson) => {
  const norm = (s) => String(s).toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
  return /[a-z]{4,}/.test(title) && !/[\u4e00-\u9fa5]/.test(title)
    && ['restful api design best practices', 'python fastapi asynchronous web development'].includes(norm(title));
};

const fenceMask = (lines) => {
  const mask = lines.map(() => true);
  let open = 0;
  lines.forEach((line, i) => {
    const m = /^ {0,3}(`{3,})/.exec(line);
    if (m) {
      const len = m[1].length;
      if (open === 0) { open = len; mask[i] = false; return; }
      if (len >= open) { open = 0; mask[i] = false; return; }
    }
    if (open > 0) mask[i] = false;
  });
  return mask;
};
const load = (p) => {
  const raw = fs.readFileSync(p, 'utf8');
  return { lines: raw.split(/\r?\n/), eol: raw.includes('\r\n') ? '\r\n' : '\n' };
};
// 「第 N 章 …」式标题按关键词并入最贴近的规范小节，内容不丢、层级归一。
const routeChapter = (title) => {
  const m = /^第\s*(\d+)\s*章[：:·\s]*(.*)$/.exec(title);
  if (!m) return null;
  const body = m[2].trim() || title;
  const label = `第 ${m[1]} 讲·${body}`;
  // 章名本身就是规范小节名（含少量别名）时直接并过去，不再加一层小标题。
  const ALIAS = {
    '代码示例': '代码/协议/SQL 示例',
    '代码/协议/SQL示例': '代码/协议/SQL 示例',
    '时间/空间复杂度与性能分析': '时间/空间复杂度或性能分析',
    '本节知识框架': '本节知识框架',
  };
  const direct = ALIAS[body] || CANONICAL.find((c) => c === body);
  if (direct) return [direct, null];
  if (/陷阱|排错|易错/.test(body)) return ['常见误区与易错点', label];
  if (/实战|案例|场景/.test(body)) return ['典型应用场景', label];
  if (/复习|总结|路线|导言|概览|介绍|目标/.test(body)) return ['本节知识框架', label];
  if (/代码|配置|示例|脚本|yaml|sql/i.test(body)) return ['代码/协议/SQL 示例', label];
  if (/性能|优化|复杂度/.test(body)) return ['时间/空间复杂度或性能分析', label];
  if (/附录|速查|清单|列表/.test(body)) return ['术语速查', label];
  return ['原理与运行机制', label];
};
// 「附录 A：PromQL 速查表」式标题并入参考资料小节。
const routeAppendix = (title) => {
  const m = /^附录\s*[A-Za-z０-９A-Z]+[：:·\s]*(.*)$/.exec(title);
  if (!m) return null;
  return ['参考资料与复核', `附录·${(m[1] || title).trim()}`];
};
const h2Index = (lines) => {
  const mask = fenceMask(lines);
  const out = [];
  lines.forEach((line, i) => {
    if (mask[i] && /^##\s+\S/.test(line)) out.push({ i, title: line.replace(/^##\s+/, '').trim() });
  });
  return out;
};
const normalize = (s) => String(s).replace(/\s+/g, '').replace(/[*_`>#]/g, '');
const lessonStems = (l) => {
  const mdPath = path.join(CONTENT_DIR, path.basename(String(l.file)));
  if (!fs.existsSync(mdPath)) return null;
  return (l.quiz || []).map((q) => normalize(q.question));
};

let mergedFiles = 0, mergedBlocks = 0, droppedSelfTests = 0, skipped = [];
const mergedTitles = new Map();
// 返回 [目标规范小节, 并入后小标题]；目标为 null 表示整块删除。
const legacyRoute = (title, lesson) => {
  const hit = LEGACY_MAP.find(([re]) => re.test(title));
  if (hit) return [hit[1], hit[2]];
  const chapter = routeChapter(title);
  if (chapter) return chapter;
  const appendix = routeAppendix(title);
  if (appendix) return appendix;
  if (isEnglishTitleBlock(title, lesson)) return ['本节知识框架', '课程导言'];
  return null;
};
for (const l of lessons) {
  const p = path.join(CONTENT_DIR, path.basename(String(l.file)));
  if (!fs.existsSync(p)) continue;
  const { lines, eol } = load(p);
  const heads = h2Index(lines);
  const legacy = heads.filter((h) => !CANONICAL.includes(h.title) && legacyRoute(h.title, l));
  if (!legacy.length) continue;
  // 只处理「成体系的旧骨架」：单个额外小节（如延伸阅读）是合规的补充结构，不动。
  // 但英文标题本身就是缺陷，一处也要清。
  const englishLeft = legacy.some((h) => !/[\u4e00-\u9fa5]/.test(h.title));
  if (legacy.length < 4 && !englishLeft) continue;
  // 只在「旧骨架与规范骨架并存」时合并，避免误伤本来就自由组织好的课。
  const canonicalCount = heads.filter((h) => CANONICAL.includes(h.title)).length;
  if (canonicalCount < 8) continue;

  // 切块：preamble + 每个 H2 到下一个 H2 之前。
  const preamble = lines.slice(0, heads[0].i);
  const blocks = heads.map((h, k) => ({
    title: h.title,
    body: lines.slice(h.i + 1, k + 1 < heads.length ? heads[k + 1].i : lines.length),
  }));

  const byTitle = new Map();
  const keep = [];
  for (const b of blocks) {
    if (CANONICAL.includes(b.title) && !byTitle.has(b.title)) { byTitle.set(b.title, b); keep.push(b); continue; }
    if (!CANONICAL.includes(b.title)) { keep.push(b); continue; }
    byTitle.get(b.title).body.push(...b.body); // 规范小节重复出现时合并
  }
  let localMerged = 0, localDropped = 0;
  for (const b of blocks) {
    if (CANONICAL.includes(b.title)) continue;
    const route = legacyRoute(b.title, l);
    if (!route) continue;
    const [target, label] = route;
    if (target === null) {
      // 旧自测块与当前题库同源，删除前先确认题干仍在、复习清单也还剩够三条。
      const stems = lessonStems(l) || [];
      const restBody = keep.filter((x) => x !== b).map((x) => x.body.join('\n')).join('\n');
      const restText = normalize(restBody);
      const checklist = (restBody.match(/^- \[ \]/gm) || []).length;
      if (stems.every((s) => restText.includes(s)) && checklist >= 3) {
        const src = keep.indexOf(b);
        if (src >= 0) keep.splice(src, 1);
        localDropped++;
      } else skipped.push(`${path.basename(p)}：${b.title} 块仍承载独有题干或复习清单，保留`);
      continue;
    }
    const dst = byTitle.get(target);
    if (!dst) continue;
    const trimmed = b.body.filter((x, i) => !(i === 0 && x.trim() === ''));
    if (label === null) {
      dst.body.push('', ...trimmed); // 章名与小节同名：内容直接接在后面
    } else {
      const inner = trimmed.map((x) => (/^###\s/.test(x) ? `#${x}` : x));
      dst.body.push('', `### ${label}`, ...inner);
    }
    const src = keep.indexOf(b);
    if (src >= 0) keep.splice(src, 1);
    localMerged++;
    mergedTitles.set(b.title, (mergedTitles.get(b.title) || 0) + 1);
  }

  // 被丢弃的旧自测块：必须确认当前题库题干仍在 考点精讲 里，否则不合并。
  const stems = lessonStems(l);
  if (stems) {
    const outText = normalize(
      [preamble.join('\n'), ...keep.map((b) => `## ${b.title}\n${b.body.join('\n')}`)].join('\n'),
    );
    const missing = stems.filter((s) => !outText.includes(s));
    if (missing.length) { skipped.push(`${path.basename(p)}：合并后缺 ${missing.length} 条题干`); continue; }
  }

  // 规范小节按官方顺序重排，项目课特有的附加小节（验证命令、专属规格、交付物）
  // 放在内容元数据之前，避免合并后顺序错乱。
  const extras = keep.filter((b) => !CANONICAL.includes(b.title));
  const canon = CANONICAL.map((t) => keep.find((b) => b.title === t)).filter(Boolean);
  const meta = canon.find((b) => b.title === '内容元数据');
  const ordered = meta ? [...canon.filter((b) => b !== meta), ...extras, meta] : [...canon, ...extras];
  const out = [...preamble, ...ordered.map((b) => [`## ${b.title}`, ...b.body, '']).flat()];
  const text = out.join(eol);
  if (text.replace(/\s/g, '').length < 6000) { skipped.push(`${path.basename(p)}：合并后正文过短`); continue; }
  if ((text.match(/^- \[ \]/gm) || []).length < 3) { skipped.push(`${path.basename(p)}：合并后复习清单不足 3 条`); continue; }
  mergedFiles++; mergedBlocks += localMerged; droppedSelfTests += localDropped;
  if (LIST) {
    const legacyTitles = blocks.filter((b) => !CANONICAL.includes(b.title)).map((b) => b.title).slice(0, 8);
    console.log(`  ${path.basename(p)} :: 并入 ${localMerged} 删除 ${localDropped} :: ${legacyTitles.join(' | ')}`);
  }
  if (APPLY) fs.writeFileSync(p, text);
  const preview = (process.argv.find((a) => a.startsWith('--preview=')) || '').split('=')[1];
  if (preview && path.basename(p) === preview) {
    fs.writeFileSync(path.join('tool', 'reports', `preview_${preview}`), text);
    console.log(`  预览已写入 tool/reports/preview_${preview}`);
  }
}

// 全库：把 `### 问题N` 这类内部编号小标题换成可读写法。
// 考点精讲 用「考点 N」，其余小节用「第 N 题」。
let globalRenamed = 0, globalFiles = 0;
for (const l of lessons) {
  const p = path.join(CONTENT_DIR, path.basename(String(l.file)));
  if (!fs.existsSync(p)) continue;
  const { lines, eol } = load(p);
  const heads = h2Index(lines);
  if (!heads.length) continue;
  const sectionAt = new Map();
  heads.forEach((h, k) => {
    const end = k + 1 < heads.length ? heads[k + 1].i : lines.length;
    for (let i = h.i; i < end; i++) sectionAt.set(i, h.title);
  });
  const counters = new Map();
  let n = 0;
  for (let i = 0; i < lines.length; i++) {
    const m = /^###\s*问题\s*(\d+)\s*$/.exec(lines[i]);
    if (!m) continue;
    const sec = sectionAt.get(i) || '';
    const label = sec === '考点精讲' ? '考点' : '第';
    const c = (counters.get(sec + label) || 0) + 1;
    counters.set(sec + label, c);
    lines[i] = label === '考点' ? `### 考点 ${c}` : `### 第 ${c} 题`;
    globalRenamed++; n++;
  }
  if (n) { globalFiles++; if (APPLY) fs.writeFileSync(p, lines.join(eol)); }
}

console.log(`旧骨架并入规范小节：${mergedFiles} 个文件，${mergedBlocks} 块，删除重复旧自测块 ${droppedSelfTests} 个`);
console.log(
  '并入了哪些旧标题：\n  ' +
    [...mergedTitles.entries()].sort((a, b) => b[1] - a[1]).slice(0, 14).map(([k, v]) => `${k}×${v}`).join('\n  '),
);
console.log(`考点精讲内部题号改名：${globalRenamed} 处（${globalFiles} 个文件）`);
if (skipped.length) console.log('跳过：\n  ' + skipped.join('\n  '));
console.log(APPLY ? '已写盘' : '（dry-run，加 --apply 才写盘）');
