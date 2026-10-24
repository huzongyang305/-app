/**
 * 第 34 波：删掉课文考点精讲里与题库解析不同步的「干扰项X应排除」尾句。
 *
 * 背景：第 11 波曾在解析尾部点名一个干扰项，第 30 到 32 波已把题库侧的这类句子逐个核实或删净，
 * 但课文 考点精讲 的「判断依据」是那时逐字抄过去的副本。全库 130 条「干扰项「X」与题干…
 * 的要求对不上，应排除。」里有 2 条点名的 X 现在其实是该题的正确项（cross_types_variables 的
 * 「Rust」、visual_memory_layout 的「因为赋复制的是引用」），等于课文让学员去排除一个该选的答案；
 * 另有 27 条点名的还是干扰项，但题库解析里早就没这句了，课文只是没跟上。
 *
 * 判定：按块的题干定位到本课题库的那道题，逐句分两类。
 *   ① 点名的 X 在这道题里根本不是干扰项（甚至是正确项）——这句是错的，删；
 *   ② 点名的 X 确实是干扰项，但题库解析里已经没这句了——课文只是没跟上，默认留着，
 *      加 --stale 才一起删。
 * 题干在本课题库里对不上号的一律不动，只报数。
 *
 *   node tool/content_pipeline/wave34_md_stale_exclude_tail.js [--apply] [--stale]
 */
const fs = require('fs');

const APPLY = process.argv.includes('--apply');
const collectStale = process.argv.includes('--stale');
const MANIFEST = 'assets/content/manifest.json';
const TAIL = /干扰项「[^「」]{1,400}?」与题干「[^「」]{1,400}?」的要求对不上，应排除。/g;
const TAIL_ONE = /干扰项「[^「」]{1,400}?」与题干「[^「」]{1,400}?」的要求对不上，应排除。/;
const EXPLAIN = /^(\s*-\s*\*\*判断依据\*\*：)([\s\S]*)$/;
const STEM = /^\s*-\s*\*\*(?:题目|题干)\*\*：([\s\S]*)$/;

const flat = (s) => String(s).replace(/[\s`*_「」『』“”""]/g, '');
/** 题干里的（多选）（单选）等标注和末尾标点都不参与比对 */
const loose = (s) => flat(String(s).replace(/[（(](?:多选|单选|填空|排序)[）)]/g, ''));

const manifest = JSON.parse(fs.readFileSync(MANIFEST, 'utf8'));
const stats = { total: 0, kept: 0, wrong: 0, stale: 0, deleted: 0, empty: 0, noStem: 0, files: 0 };
const log = [];

for (const category of manifest.categories) {
  for (const lesson of category.lessons || []) {
    if (!lesson.file || !fs.existsSync(lesson.file)) continue;
    const raw = fs.readFileSync(lesson.file, 'utf8');
    const eol = raw.includes('\r\n') ? '\r\n' : '\n';
    const text = raw.replace(/\r\n/g, '\n');
    const start = text.indexOf('\n## 考点精讲');
    if (start < 0) continue;
    const rest = text.slice(start + 1);
    const cut = rest.slice(2).search(/\n##(?!#)/);
    const region = cut < 0 ? rest : rest.slice(0, cut + 2);

    const byStem = new Map((lesson.quiz || []).map((q) => [loose(q.question), q]));
    const lines = region.split('\n');
    let stem = null;
    let touched = false;
    for (let i = 0; i < lines.length; i++) {
      // 每个 ### 考点 块重新认领题干，避免上一块的题干串到没有题目的块里
      if (/^\s*#{2,4}\s/.test(lines[i])) stem = null;
      const s = lines[i].match(STEM);
      if (s) { stem = loose(s[1]); continue; }
      const hits = lines[i].match(TAIL);
      if (!hits) continue;
      const exp = lines[i].match(EXPLAIN);
      if (!exp) continue;
      stats.total += hits.length;
      const question = stem ? byStem.get(stem) : null;
      if (!question) { stats.noStem += hits.length; continue; }
      // 两件事分别决定要不要动手：这句在题库解析里还在不在（课文有没有跟着题库走），
      // 以及点名的 X 在本题里到底是不是干扰项（这句说的是不是事实）
      const correct = new Set(
        Array.isArray(question.answers) && question.answers.length
          ? question.answers
          : (typeof question.answer === 'number' ? [question.answer] : []),
      );
      const options = (question.options || []).map(flat);
      const saysFalse = hits.some((hit) => {
        const name = flat((hit.match(/干扰项「([^」]{1,400}?)」/) || [])[1] || '');
        return !options.some((o, i) => !correct.has(i) && o && name && (o.includes(name) || name.includes(o)));
      });
      const inExplanation = TAIL_ONE.test(String(question.explanation || ''));
      if (!saysFalse && inExplanation) { stats.kept += hits.length; continue; }
      if (!saysFalse) stats.stale += hits.length;
      if (!collectStale && !saysFalse) continue;
      const cleaned = lines[i].replace(TAIL, '').replace(/。{2,}/g, '。').replace(/\s+$/, '');
      // 整条判断依据只由这句撑着的课不能删空
      if (cleaned.length - exp[1].length < 20) { stats.empty += hits.length; continue; }
      lines[i] = cleaned;
      if (saysFalse) stats.wrong += hits.length;
      stats.deleted += hits.length;
      touched = true;
      log.push(`${lesson.id}｜${saysFalse ? '点名点到了非干扰项' : '解析里已没这句'}｜${hits[0].slice(0, 52)}…`);
    }
    if (!touched) continue;
    stats.files++;
    if (APPLY) {
      const next = text.slice(0, start + 1) + lines.join('\n') + (cut < 0 ? '' : rest.slice(region.length));
      fs.writeFileSync(lesson.file, eol === '\r\n' ? next.replace(/\n/g, '\r\n') : next);
    }
  }
}

console.log(
  `尾句 ${stats.total}｜与解析一致（保留）${stats.kept}｜点名点错 ${stats.wrong}｜` +
  `解析已删课文没跟上 ${stats.stale}${collectStale ? '（一并删）' : '（暂留，加 --stale 才动）'}｜` +
  `实删 ${stats.deleted}｜删空退回 ${stats.empty}｜题干对不上 ${stats.noStem}｜改动文件 ${stats.files}`,
);
for (const line of log) console.log('  ' + line);
console.log(APPLY ? '已写盘' : '（dry-run，加 --apply 才写盘）');
