#!/usr/bin/env node
/**
 * 内容包预检：新分类在并进 manifest 之前，用与 test/content_test.dart 一致的口径校验。
 *
 * 用法：
 *   node tool/content_pipeline/validate_pack.js build/audit/pack_ncre.json [更多片段...]
 *   node tool/content_pipeline/validate_pack.js --order-base=7 pack_ruankao_c.json
 *
 * append 分片（分类里写 "mode":"append"）校验的是往已入库分类尾部补课，
 * order 从该分类现有课数往后数；同一次调用里多个 append 分片会自动累加偏移，
 * 分两批写同一分类时可用 --order-base 指定这一批的真实起点。
 *
 * 片段格式（与 manifest.categories[i] 同构，只是单独成文件）：
 *   { "category": { "id","title":{"zh","en"},"icon","color","lessons":[...] } }
 *
 * 错误（error）会导致并库后 flutter test 直接红灯；告警（warn）是体积、分布类风险提示。
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const MANIFEST = JSON.parse(
  fs.readFileSync(path.join(ROOT, 'assets/content/manifest.json'), 'utf8'),
);
const CATEGORY_BY_ID = new Map(MANIFEST.categories.map((c) => [c.id, c]));
const IMAGE_FILES = new Set(
  fs.readdirSync(path.join(ROOT, 'assets/content/images')),
);

const CANONICAL = [
  '本节知识框架',
  '核心概念定义',
  '原理与运行机制',
  '典型应用场景',
  '代码/协议/SQL 示例',
  '时间/空间复杂度或性能分析',
  '常见误区与易错点',
  '与其他知识点的关系',
  '自测题与参考答案',
  '考点精讲',
  '术语速查',
  '参考资料与复核',
  '内容元数据',
];
const LEGACY = [
  '常见错误对照表', '常见错误', '常见错误速查', '常见误区', '常见坑', '常见陷阱',
  '常见问题', '常见问题与对策', '常见问题与排查顺序', '常见风险速查', '常见失败模式',
  '常见反模式速查', '反模式', '失败模式', '新手最容易踩的八个坑', '新手最容易踩的六个坑',
  '必须注意的坑', '五个高频坑', '三个经典坑', '易错点回顾', '自测清单', '逐节复习与自检',
  '深度追问与自测', '本课自测清单与错误对照', '实践任务',
];
const MD_TEMPLATE = [
  '先自己作答，再看「判断依据」', '**迁移检查**', '本课在「', '本课还在「',
  '本课在核心知识', '本课还在核心知识', '课程摘要指出', '回到正文对应章节补足概念',
  '把题干里的一个条件换成边界值', '把现象和原因写在一起', '错误信息通常会指出出错行和期望符号',
];
const EXPLANATION_TEMPLATE = [
  '这道题对应的课程', '修正后要重跑', '本课在「', '本课还在「', '本课把「',
  '本课在核心知识', '本课还在核心知识', '对照「', '课程摘要',
];
const PLACEHOLDER_HOSTS = [
  'localhost', '127.0.0.1', 'example.com', 'example.org', 'your-server',
  'your_api', '192.168.', '0.0.0.0', 'zh.wikipedia.org/wiki?',
];
const DIFFICULTY = ['入门', '基础', '进阶', '高级'];
const TYPES = ['single', 'multi', 'fill', 'order', 'code', 'debug'];
const LETTERS = 'ABCDEFGH';
const DROPPED = /[\s　*_「」『』“”"`\u0060]/g;
const FLATTEN_ONLY = /[\s`]/g;
const METADATA_DATE = '内容更新时间：2026-10-06';

/** 屏蔽代码围栏内部，避免把示例里的 `## 标题` 当成章节。 */
function maskFences(markdown) {
  let inFence = false;
  return markdown
    .split('\n')
    .map((line) => {
      if (/^```/.test(line)) {
        inFence = !inFence;
        return line;
      }
      return inFence ? ' '.repeat(line.length) : line;
    })
    .join('\n');
}

function headingRegExp(title, flags = 'm') {
  return new RegExp(`^##\\s+${title.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&')}\\s*$`, flags);
}

function sectionOf(markdown, title) {
  const match = headingRegExp(title).exec(markdown);
  if (!match) return '';
  const rest = markdown.slice(match.index + match[0].length);
  const next = /^##\s+/m.exec(rest);
  return next ? rest.slice(0, next.index) : rest;
}

const norm = (text) => String(text).replace(DROPPED, '');

/** 与 content_test.dart 的 splitExplanationSentences 一致：不切开引号与代码跨度。 */
function sentences(text) {
  const out = [];
  let buffer = '';
  let quote = false;
  let code = false;
  for (const char of text) {
    if (char === '`') code = !code;
    else if (!code) {
      if ('「『“'.includes(char)) quote = true;
      else if ('」』”'.includes(char)) quote = false;
    }
    buffer += char;
    if ((char === '。' || char === '；' || char === '\n') && !quote && !code) {
      if (buffer.trim()) out.push(buffer.trim());
      buffer = '';
    }
  }
  if (buffer.trim()) out.push(buffer.trim());
  return out;
}

function checkLesson(lesson, category, ctx) {
  const errors = [];
  const warns = [];
  const fail = (message) => errors.push(`[${lesson.id}] ${message}`);
  const warn = (message) => warns.push(`[${lesson.id}] ${message}`);

  if (!lesson.id.startsWith(`${category.id}_`)) fail(`课时 id 未以 ${category.id}_ 开头`);
  if (ctx.ids.has(lesson.id)) fail('课时 id 与现有题库或本片其他课重复');
  ctx.ids.add(lesson.id);
  const expectedFile = `assets/content/${lesson.id}.md`;
  if (lesson.file !== expectedFile) fail(`file 应为 ${expectedFile}`);
  if (typeof lesson.minutes !== 'number' || lesson.minutes < 20 || lesson.minutes > 60) {
    fail(`minutes=${lesson.minutes} 不在 20~60`);
  }
  if (!lesson.summary || !lesson.summary.zh || !lesson.summary.en) fail('summary 缺中英');
  if (!lesson.title || !lesson.title.zh || !lesson.title.en) fail('title 缺中英');
  if (!Array.isArray(lesson.keywords) || lesson.keywords.length < 3) fail('keywords 少于 3 个');
  if (!DIFFICULTY.includes(lesson.difficulty)) fail(`难度非法：${lesson.difficulty}`);
  if (lesson.order !== ctx.orderCursor) fail(`order=${lesson.order}，应为 ${ctx.orderCursor}`);
  if (lesson.lab) warn(`非语言分类不建议绑定 lab：${lesson.lab}`);

  const quiz = Array.isArray(lesson.quiz) ? lesson.quiz : [];
  if (quiz.length < 3 || quiz.length > 6) fail(`题目数 ${quiz.length} 不在 3~6`);

  let markdown = '';
  const absolute = path.join(ROOT, expectedFile);
  if (!fs.existsSync(absolute)) {
    fail(`课文文件不存在：${expectedFile}`);
    return { errors, warns, questions: [], singles: [] };
  }
  markdown = fs.readFileSync(absolute, 'utf8').replace(/\r\n/g, '\n');
  const masked = maskFences(markdown);

  if (markdown.length < 6000) fail(`正文 ${markdown.length} 字符，低于硬门禁 6000`);
  else if (markdown.length < 10000) warn(`正文 ${markdown.length} 字符，低于同库目标 10000`);
  const firstLine = markdown.split('\n')[0].trim();
  if (firstLine !== `# ${lesson.title.zh}`) fail(`H1 与标题不符：${firstLine}`);

  for (const title of CANONICAL) {
    const all = [...masked.matchAll(headingRegExp(title, 'gm'))].length;
    if (all === 0) fail(`缺少章节「## ${title}」`);
    else if (all > 1) fail(`章节「## ${title}」出现 ${all} 次`);
  }
  for (const title of LEGACY) {
    if (headingRegExp(title).test(masked)) fail(`出现旧标题「## ${title}」`);
  }
  for (const marker of MD_TEMPLATE) {
    if (markdown.includes(marker)) fail(`课文含模板句「${marker}」`);
  }
  if (/[（(]\s*[A-Za-z0-9_]+\s*第\s*\d+\s*题\s*[)）]/.test(markdown)) {
    fail('课文残留内部题号（形如「xxx 第 3 题」）');
  }
  if ((masked.match(/^\s*- \[ \] /gm) || []).length < 3) fail('复习清单不足 3 条');
  if ((masked.match(/^```/gm) || []).length % 2 !== 0) fail('代码围栏没有成对闭合');
  if (!/^```(?!text|markdown)[A-Za-z0-9_+-]+/m.test(masked)) {
    fail('没有带语言标记的真实代码块（```text 与 ```markdown 不计入）');
  }
  if (!markdown.includes(METADATA_DATE)) fail(`缺少「${METADATA_DATE}」`);

  const imageRefs = [...markdown.matchAll(/!\[[^\]]*\]\((images\/[^)]+)\)/g)]
    .map((match) => match[1]);
  if (imageRefs.length === 0) fail('没有引用本地配图');
  for (const ref of imageRefs) {
    const name = ref.split('/').pop();
    if (name.toLowerCase().endsWith('.png')) fail(`配图仍是 PNG：${ref}`);
    // Android 资源解析区分大小写，Windows 不区分，必须按目录真实文件名精确比对。
    if (!IMAGE_FILES.has(name)) fail(`配图文件不存在（注意大小写）：${ref}`);
  }

  const referenceSection = sectionOf(masked, '参考资料与复核');
  const links = [...new Set(
    [...referenceSection.matchAll(/\[[^\]]+\]\((https?:\/\/[^)\s]+)\)/g)].map((m) => m[1]),
  )];
  if (links.length < 2) fail(`参考资料与复核里的链接只有 ${links.length} 条，需 ≥2`);
  for (const host of PLACEHOLDER_HOSTS) {
    if (markdown.includes(host)) fail(`参考链接含占位或本机域名：${host}`);
  }

  const glossary = sectionOf(masked, '术语速查');
  const rows = glossary.split('\n').filter((line) => line.trimStart().startsWith('|')).length;
  if (rows < 6) fail(`术语速查只有 ${rows - 2} 条，需 ≥4 条`);

  const region = sectionOf(masked, '考点精讲');
  const normalizedRegion = norm(region);
  const normalizedDoc = norm(markdown);

  for (let index = 0; index < quiz.length; index++) {
    const question = quiz[index];
    const label = `${lesson.id} 第 ${index + 1} 题`;
    const pushFail = (message) => errors.push(`[${label}] ${message}`);
    const questionText = String(question.question || '');
    if (!TYPES.includes(question.type)) pushFail(`题型非法：${question.type}`);
    if (questionText.trim().length < 12) pushFail('题干过短');
    if (/《.+》/.test(questionText)) pushFail('题干出现《》元问题');
    if (String(question.explanation || '').trim().length < 120) pushFail('解析短于 120 字');
    for (const marker of EXPLANATION_TEMPLATE) {
      if (String(question.explanation || '').includes(marker)) pushFail(`解析含模板句「${marker}」`);
    }
    if (/正踩在这条上/.test(question.explanation || '')) pushFail('解析出现「正踩在这条上」归因');

    const options = Array.isArray(question.options) ? question.options : [];
    const optionNorms = options.map(norm);
    const correct = new Set(
      question.type === 'order'
        ? question.correct_order || []
        : question.type === 'multi'
          ? question.answers || question.correct_indexes || (question.answer == null ? [] : [question.answer])
          : question.type === 'fill'
            ? []
            : [question.answer],
    );

    if (question.type === 'single' || question.type === 'code' || question.type === 'debug') {
      if (options.length < 2) pushFail('选项不足 2 个');
      if (!Number.isInteger(question.answer) || question.answer < 0 || question.answer >= options.length) {
        pushFail(`answer=${question.answer} 越界`);
      } else {
        const quoted = `本题正确项是「${options[question.answer]}」`;
        if (!String(question.explanation || '').includes(quoted)) {
          pushFail('解析没有逐字复述正确项（需含「本题正确项是「…」」）');
        }
        if (!normalizedDoc.includes(norm(options[question.answer]))) {
          pushFail('正确项文本没有进入课文');
        }
        if ((question.type || 'single') === 'single') {
          // content_test 的下标配额只算 type=single；manifest 里省略 type 也按单选处理。
          ctx.singles.push({
            answer: question.answer,
            correctLength: options[question.answer].trim().length,
            others: options.filter((_, i) => i !== question.answer).map((o) => o.trim().length),
          });
        }
      }
      if ((question.type === 'code' || question.type === 'debug') && !String(question.code || '').trim()) {
        pushFail('代码题缺 code 字段');
      }
    } else if (question.type === 'multi') {
      const answers = question.answers || question.correct_indexes;
      if (!Array.isArray(answers) || answers.length < 2) pushFail('多选题正确答案少于 2 个');
      else if (answers.some((a) => a < 0 || a >= options.length)) pushFail('多选题答案越界');
      else if (new Set(answers).size !== answers.length) pushFail('多选题答案重复');
      else {
        for (const a of answers) {
          if (!String(question.explanation || '').includes(`「${options[a]}」`)) {
            pushFail(`解析没有复述第 ${a} 个正确项`);
          }
        }
      }
      if (options.length < 3) pushFail('多选题选项不足 3 个');
    } else if (question.type === 'fill') {
      if (!Array.isArray(question.accepted_answers) || question.accepted_answers.length === 0) {
        pushFail('填空题缺 accepted_answers');
      }
    } else if (question.type === 'order') {
      const order = question.correct_order;
      if (!Array.isArray(order) || order.length !== options.length) {
        pushFail('排序题 correct_order 必须覆盖全部选项');
      } else if (new Set(order).size !== options.length) {
        pushFail('排序题 correct_order 有重复下标');
      } else if (order.some((a) => a < 0 || a >= options.length)) {
        pushFail('排序题 correct_order 越界');
      }
      if (options.length < 3) pushFail('排序题选项不足 3 个');
    }

    // 解析点名的「干扰项「X」」必须是这道题自己的干扰项，且不能是正确项。
    for (const match of String(question.explanation || '').matchAll(/干扰项「([^」]{2,120})」/g)) {
      const want = norm(match[1]);
      const distractors = optionNorms.filter((_, i) => !correct.has(i));
      if (!distractors.includes(want)) pushFail(`点名的「${match[1]}」不是本题干扰项原文`);
    }
    // 代码题断言必须是本题选项原文的前缀。
    for (const match of String(question.explanation || '').matchAll(/(?:调用了|出现字面量|代码里出现了)\s*`[^`]+`/g)) {
      const want = match[0].replace(FLATTEN_ONLY, '');
      if (!optionNorms.map((o) => o.replace(FLATTEN_ONLY, '')).some((o) => o.includes(want))) {
        pushFail(`解析引用的「${match[0]}」不是任何选项原文`);
      }
    }
    // 课文必须覆盖题干，且精讲里标注的答案字母要与题库真值一致。
    const key = norm(questionText);
    if (!normalizedRegion.includes(key)) {
      if (!normalizedDoc.includes(key)) pushFail('课文没有覆盖该题干');
      else warn('题干在课文里、但不在考点精讲区域（建议移入精讲）');
    }
    const markerLine = new RegExp(
      `^\\s*(?:[-*>]\\s*)?(?:\\*\\*)?\\s*(?:正确答案|正确项|正确选项|正确序号|参考答案|答案|[Aa]ns)(?:\\s*\\*\\*)?\\s*[:：]\\s*(.*)$`,
      'm',
    );
    const afterQuestion = (() => {
      const plain = region.replace(DROPPED, '');
      void plain;
      const lines = region.split('\n');
      const position = lines.findIndex((line) => norm(line).includes(key.slice(0, 20)));
      return position < 0 ? '' : lines.slice(position, position + 12).join('\n');
    })();
    const marker = markerLine.exec(afterQuestion);
    if (marker) {
      const value = marker[1].replace(/[（(].*$/, '').replace(/[*\s.。]+$/, '');
      if (/^[A-H](?:[\s、，/→或和]*[A-H])*$/.test(value) &&
          !options.some((o) => norm(o) === norm(value))) {
        const marked = [...value.replace(/[^A-H]/g, '')].map((c) => LETTERS.indexOf(c));
        const truth = question.type === 'order'
          ? question.correct_order || []
          : question.type === 'multi'
            ? question.answers || []
            : [question.answer];
        const same = question.type === 'order'
          ? marked.join(',') === truth.join(',')
          : [...marked].sort().join() === [...truth].sort().join();
        if (!same) {
          pushFail(`精讲标注「${value}」与题库真值 ${(truth.map((i) => LETTERS[i]) || []).join('')} 不一致`);
        }
      }
    }
    ctx.questions.push({ lesson: lesson.id, question });
  }

  const hasCodeQuestion = quiz.some((q) => q.type === 'code' || q.type === 'debug');
  if (!hasCodeQuestion) ctx.noCodeLessons.push(lesson.id);
  if (lesson.id.includes('project') || /实战|项目/.test(lesson.title.zh)) {
    if (!markdown.includes('项目交付物')) fail('项目课缺少「项目交付物」');
  }

  return { errors, warns };
}

function main() {
  const argv = process.argv.slice(2);
  const fragments = argv.filter((arg) => !arg.startsWith('--'));
  const baseArg = argv.find((arg) => arg.startsWith('--order-base='));
  const orderBaseOverride = baseArg ? Number(baseArg.slice('--order-base='.length)) : null;
  if (fragments.length === 0) {
    console.error('用法：node tool/content_pipeline/validate_pack.js [--order-base=N] <pack.json> [...]');
    process.exit(2);
  }

  const ctx = {
    ids: new Set(MANIFEST.categories.flatMap((c) => c.lessons.map((l) => l.id))),
    orderCursor: 0,
    questions: [],
    singles: [],
    noCodeLessons: [],
  };

  const errors = [];
  const warns = [];
  const appendedCount = new Map();
  for (const fragment of fragments) {
    const pack = JSON.parse(fs.readFileSync(fragment, 'utf8'));
    const category = pack.category || pack;
    // append 分片不建新分类，只往已并库的分类尾部补课，order/难度都要接着原序列排。
    const append = category.mode === 'append';
    const required = ['id', 'icon', 'color', 'lessons'];
    for (const key of required) {
      if (!category[key]) errors.push(`${fragment}: 分类缺 ${key}`);
    }
    if (!category.title || !category.title.zh || !category.title.en) {
      errors.push(`${fragment}: 分类 title 缺中英`);
    }
    if (!/^[0-9A-Fa-f]{6}$/.test(String(category.color || ''))) {
      errors.push(`${fragment}: color 应为 6 位十六进制`);
    }
    if (category.mode !== undefined && category.mode !== 'append') {
      errors.push(`${fragment}: mode 只支持 "append"，当前「${category.mode}」`);
    }
    const existing = CATEGORY_BY_ID.get(category.id);
    if (existing && !append) {
      errors.push(`${fragment}: 分类 id 已存在：${category.id}（补课请在分类里加 "mode":"append"）`);
    }
    if (!existing && append) {
      errors.push(`${fragment}: 标了 append 但分类 ${category.id} 还没并进 manifest`);
    }
    let orderBase = 0;
    let ladder = [];
    if (existing) {
      if (existing.icon !== category.icon) {
        errors.push(`${fragment}: icon「${category.icon}」与已入库的「${existing.icon}」不一致`);
      }
      if (String(existing.color).toUpperCase() !== String(category.color).toUpperCase()) {
        errors.push(`${fragment}: color「${category.color}」与已入库的「${existing.color}」不一致`);
      }
      if (existing.title.zh !== category.title.zh) {
        warns.push(`${fragment}: 分类中文标题与已入库的不一致，以 manifest 为准`);
      }
      // 同一轮里分批往同一个分类补课，后一批的起点要接着前一批往后数。
      const already = appendedCount.get(category.id) ?? 0;
      const start = orderBaseOverride ?? existing.lessons.length;
      orderBase = start + already;
      appendedCount.set(category.id, already + category.lessons.length);
      ladder = existing.lessons.map((l) => DIFFICULTY.indexOf(l.difficulty));
    }
    const total = orderBase + category.lessons.length;
    if (total < 3) errors.push(`${fragment}: 课程数 ${total} 少于 3`);
    category.lessons.forEach((lesson, index) => {
      ctx.orderCursor = orderBase + index;
      const before = errors.length;
      const result = checkLesson(lesson, category, ctx);
      errors.push(...result.errors);
      warns.push(...result.warns);
      if (errors.length === before) {
        const rank = DIFFICULTY.indexOf(lesson.difficulty);
        const prev = ladder[ladder.length - 1];
        // content_test 要求同一分类内难度不减、最后一课不能是入门。
        if (rank < prev) {
          errors.push(
            `[${lesson.id}] 难度「${lesson.difficulty}」低于前一课「${DIFFICULTY[prev]}」，会打乱阶梯`,
          );
        }
        if (rank === 0) {
          errors.push(`[${lesson.id}] append 的课排在分类末尾，不能标「入门」`);
        }
        ladder.push(rank);
      }
    });
  }

  // 全局题库口径：题干唯一、解析句子不重复 5 次、单选下标分布保持在 22%~28%。
  const existingQuestions = MANIFEST.categories.flatMap((c) =>
    c.lessons.flatMap((l) => (l.quiz || []).map((q) => ({ lesson: l.id, question: q }))),
  );
  const all = existingQuestions.concat(ctx.questions);
  const normalizedQuestions = all.map((item) => norm(item.question.question));
  const duplicates = normalizedQuestions.length - new Set(normalizedQuestions).size;
  if (duplicates > 0) errors.push(`与现有题库存在 ${duplicates} 条重复题干`);

  const sentenceCounts = new Map();
  for (const item of all) {
    for (const sentence of sentences(String(item.question.explanation || ''))) {
      if (sentence.length < 12) continue;
      sentenceCounts.set(sentence, (sentenceCounts.get(sentence) || 0) + 1);
    }
  }
  const templateHits = [...sentenceCounts.entries()].filter(
    ([sentence, count]) => count >= 5 &&
      ctx.questions.some((item) => String(item.question.explanation || '').includes(sentence)),
  );
  if (templateHits.length > 0) {
    errors.push(`解析模板句（全库重复 ≥5 次）：${templateHits.length} 种，例：${templateHits.slice(0, 2).map(([s]) => s).join(' / ')}`);
  }

  const existingSingles = existingQuestions
    .map((item) => item.question)
    .filter((q) => (q.type || 'single') === 'single');
  const counts = [0, 0, 0, 0];
  for (const q of existingSingles) {
    if (q.answer >= 0 && q.answer < 4) counts[q.answer] += 1;
  }
  for (const item of ctx.singles) {
    if (item.answer >= 0 && item.answer < 4) counts[item.answer] += 1;
  }
  const totalSingles = existingSingles.length + ctx.singles.length;
  for (let index = 0; index < 4; index += 1) {
    const percent = (counts[index] * 100) / totalSingles;
    if (percent < 22 || percent > 28) {
      errors.push(`并库后单选答案下标 ${index} 占比 ${percent.toFixed(1)}%，需保持在 22%~28%`);
    }
  }

  let stronglyLongest = 0;
  for (const item of ctx.singles) {
    const second = [...item.others].sort((a, b) => b - a)[0] ?? -1;
    if (second >= 0 && item.correctLength - second >= 8) stronglyLongest += 1;
  }
  const existingLongest = existingSingles.filter((q) => {
    if (q.answer >= (q.options || []).length) return false;
    const correct = String(q.options[q.answer]).trim().length;
    const others = q.options.filter((_, i) => i !== q.answer).map((o) => String(o).trim().length);
    const second = Math.max(...others);
    return second >= 0 && correct - second >= 8;
  }).length;
  const rate = ((existingLongest + stronglyLongest) * 100) / (existingSingles.length + ctx.singles.length);
  if (rate >= 30) errors.push(`并库后正确项明显最长比例 ${rate.toFixed(1)}%，需低于 30%`);

  if (ctx.noCodeLessons.length > 0) {
    warns.push(`${ctx.noCodeLessons.length} 门课没有 code/debug 题（全库门禁要求 ≥90% 覆盖）：${ctx.noCodeLessons.slice(0, 6).join(', ')}`);
  }

  console.log(`预检 ${fragments.join(', ')}`);
  console.log(`新课时 ${ctx.questions.length} 题 · 现有 ${existingQuestions.length} 题`);
  if (warns.length) {
    console.log(`\n— 告警 ${warns.length} —`);
    warns.slice(0, 40).forEach((text) => console.log('  ! ' + text));
  }
  if (errors.length) {
    console.log(`\n— 错误 ${errors.length} —`);
    errors.forEach((text) => console.log('  x ' + text));
    process.exit(1);
  }
  console.log('\n全部硬门禁通过。');
}

main();
