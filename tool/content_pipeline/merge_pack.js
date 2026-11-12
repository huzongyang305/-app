#!/usr/bin/env node
/**
 * 新分类并库：把 tool/content_pipeline/packs/pack_<cat>.json 并进 manifest.json。
 *
 * 用法：
 *   node tool/content_pipeline/merge_pack.js                       # 演练全部分片
 *   node tool/content_pipeline/merge_pack.js --apply               # 真正写盘
 *   node tool/content_pipeline/merge_pack.js pack_ncre.json --apply # 只并指定分片
 *
 * 这是 manifest 的唯一写入口：并库前先校验（课时数、id 唯一、正文存在、
 * 单选答案全局分布），不通过就整体不写，避免半并状态把测试打红。
 * 并库后按顺序跑：
 *   dart tool/content_review_ledger.dart
 *   dart tool/schedule_review_batches.dart
 *   flutter test test/content_test.dart
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const MANIFEST_PATH = path.join(ROOT, 'assets', 'content', 'manifest.json');
const PACK_DIR = path.join(ROOT, 'tool', 'content_pipeline', 'packs');
const APPLY = process.argv.includes('--apply');
const ONLY = process.argv
  .slice(2)
  .filter((a) => !a.startsWith('--'))
  .map((a) => path.resolve(ROOT, a));

// 与 lib/services/icon_mapper.dart 支持的名称一致，写错会静默退化成书本图标。
const ICONS = new Set([
  'code', 'memory', 'account_tree', 'lan', 'storage', 'developer_board',
  'terminal', 'psychology', 'smart_toy', 'quiz', 'book', 'star', 'note',
  'translate', 'insights', 'rocket', 'security', 'phone_iphone', 'link',
  'cloud', 'transform', 'sports_esports', 'school',
]);
const DIFFICULTY = new Set(['入门', '基础', '进阶', '高级']);
// content_test 的 P0 质量门禁：单选四个下标各占 22%~28%。
const BALANCE = [22, 28];

const CATEGORY_KEYS = ['id', 'title', 'icon', 'color', 'lessons'];
const LESSON_KEYS = [
  'id', 'title', 'summary', 'file', 'minutes', 'keywords', 'difficulty',
  'order', 'prerequisites', 'related', 'lab', 'quiz',
];
const QUIZ_KEYS = [
  'type', 'question', 'options', 'answer', 'answers', 'correct_order',
  'accepted_answers', 'code', 'language', 'expected_output', 'explanation',
];

/** 按给定键序重建对象，未知键按原顺序追加在后面。 */
function pickKeys(source, order) {
  const out = {};
  for (const key of order) if (source[key] !== undefined) out[key] = source[key];
  for (const key of Object.keys(source)) {
    if (out[key] === undefined) out[key] = source[key];
  }
  return out;
}

const manifest = JSON.parse(fs.readFileSync(MANIFEST_PATH, 'utf8'));
if (!Array.isArray(manifest.categories)) {
  throw new Error('manifest.categories 不是数组，先人工确认结构再并库');
}

const existingCategories = new Set(manifest.categories.map((c) => c.id));
const existingLessons = new Set();
const singleAnswers = new Map(); // answer 下标 -> 数量（type=single）
for (const c of manifest.categories) {
  for (const l of c.lessons || []) {
    existingLessons.add(l.id);
    for (const q of l.quiz || []) {
      if ((q.type || 'single') !== 'single') continue;
      const index = Number(q.answer);
      singleAnswers.set(index, (singleAnswers.get(index) ?? 0) + 1);
    }
  }
}
let singleTotal = [...singleAnswers.values()].reduce((a, b) => a + b, 0);

function shareOf(index) {
  if (singleTotal === 0) return 0;
  return ((singleAnswers.get(index) ?? 0) * 100) / singleTotal;
}

const packFiles = (
  ONLY.length
    ? ONLY
    : fs
        .readdirSync(PACK_DIR)
        .filter((f) => f.startsWith('pack_') && f.endsWith('.json'))
        .map((f) => path.join(PACK_DIR, f))
).sort();

if (!packFiles.length) {
  console.log(`没有可并的片段（目录 ${path.relative(ROOT, PACK_DIR)} 为空）`);
  process.exit(0);
}

const staged = [];
const errors = [];

for (const file of packFiles) {
  const label = path.relative(ROOT, file);
  let pack;
  try {
    pack = JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (error) {
    errors.push(`${label}: JSON 解析失败 —— ${error.message}`);
    continue;
  }
  const category = pack.category;
  if (!category || !category.id || !Array.isArray(category.lessons)) {
    errors.push(`${label}: 缺少 category.id 或 category.lessons`);
    continue;
  }
  const packRel = `${label}`;

  if (existingCategories.has(category.id)) {
    errors.push(`${packRel}: 分类 ${category.id} 已存在于 manifest，需人工决定是补课还是换 id`);
    continue;
  }
  if (!ICONS.has(category.icon)) {
    errors.push(`${packRel}: icon「${category.icon}」不在 icon_mapper 支持列表里`);
  }
  if (!/^[0-9A-Fa-f]{6}$/.test(String(category.color || ''))) {
    errors.push(`${packRel}: color 必须是 6 位 hex，当前「${category.color}」`);
  }
  if (category.lessons.length < 3) {
    errors.push(
      `${packRel}: 只有 ${category.lessons.length} 课，分类门禁要求 ≥3 课（先把这个分片放着一轮）`,
    );
    continue;
  }

  const lessons = [];
  const seenInPack = new Set();
  category.lessons.forEach((lesson, index) => {
    const where = `${packRel} ${lesson.id}`;
    if (!lesson.id || seenInPack.has(lesson.id) || existingLessons.has(lesson.id)) {
      errors.push(`${where}: 课时 id 缺失或重复`);
      return;
    }
    seenInPack.add(lesson.id);
    if (lesson.order !== index) lesson.order = index; // 统一成 0 基下标
    if (!DIFFICULTY.has(lesson.difficulty)) {
      errors.push(`${where}: difficulty「${lesson.difficulty}」不在四档之内`);
    }
    const mdPath = path.join(ROOT, lesson.file || `assets/content/${lesson.id}.md`);
    if (!fs.existsSync(mdPath)) {
      errors.push(`${where}: 正文文件不存在 ${path.relative(ROOT, mdPath)}`);
    } else if (fs.statSync(mdPath).size < 6000) {
      errors.push(`${where}: 正文只有 ${fs.statSync(mdPath).size} 字节，低于门禁`);
    }
    const quiz = lesson.quiz || [];
    if (quiz.length < 3 || quiz.length > 6) {
      errors.push(`${where}: 题量 ${quiz.length} 不在 3~6 之间`);
    }
    quiz.forEach((q, qi) => {
      const type = q.type || 'single';
      if (type !== 'single') return;
      const answer = Number(q.answer);
      if (!(answer >= 0 && answer < (q.options || []).length)) {
        errors.push(`${where} #${qi + 1}: 单选答案下标 ${q.answer} 越界`);
        return;
      }
      singleAnswers.set(answer, (singleAnswers.get(answer) ?? 0) + 1);
      singleTotal += 1;
    });
    lessons.push({
      ...pickKeys(lesson, LESSON_KEYS),
      quiz: quiz.map((q) => pickKeys(q, QUIZ_KEYS)),
    });
  });
  if (lessons.length !== category.lessons.length) {
    errors.push(`${packRel}: 有课时被判定不合格，整个分类本轮不并`);
    continue;
  }
  staged.push({
    ...pickKeys(category, CATEGORY_KEYS),
    lessons,
  });
  // 本分类内部先检查一遍，避免并完才发现分布超标。
  for (let index = 0; index < 4; index += 1) {
    const percent = shareOf(index);
    if (percent < BALANCE[0] || percent > BALANCE[1]) {
      errors.push(
        `${packRel}: 并入库后单选下标 ${index} 占比 ${percent.toFixed(1)}%，超出门禁 ${BALANCE.join('~')}%`,
      );
    }
  }
}

console.log(
  `并库演练：现有 ${manifest.categories.length} 类 / ${existingLessons.size} 课 / ${singleTotal} 道单选`,
);
for (const c of staged) {
  const questions = c.lessons.reduce((sum, l) => sum + (l.quiz || []).length, 0);
  console.log(
    `  + ${c.id}（${c.title.zh}）${c.lessons.length} 课 ${questions} 题`,
  );
}
for (let index = 0; index < 4; index += 1) {
  console.log(`  单选下标 ${index}: ${shareOf(index).toFixed(1)}%`);
}

if (errors.length) {
  console.log(`\n— 错误 ${errors.length} —`);
  for (const e of errors.slice(0, 40)) console.log('  x ' + e);
  console.log('未写盘。');
  process.exit(1);
}

if (!staged.length) {
  console.log('没有可并的分类。');
  process.exit(0);
}

if (!APPLY) {
  console.log('\n演练通过。加 --apply 才会真正写 manifest.json。');
  process.exit(0);
}

manifest.categories.push(...staged);
fs.writeFileSync(MANIFEST_PATH, JSON.stringify(manifest, null, 2));
console.log(`\n已写入 manifest.json：新增 ${staged.length} 个分类。`);
