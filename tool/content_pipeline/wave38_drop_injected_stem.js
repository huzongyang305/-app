/**
 * 第 38 波：删掉课文判断依据里被截短的题干注入。
 *
 * 背景：早先一批填空题的解析在抄进课文时被塞进了一段题干原文，而且只塞了前半截：
 *   「…，题干「填空：补齐下面这段术语说明中的空缺，课程 `上下文瘦身、模型路由、缓」问的就是这一条。」
 *   「…要解决的是…，本题问的是填空：补齐下面这段术语说明中的空缺，课程 `AVL 旋转、红黑树性。」
 * 两处都把题干截成了半句，反引号还不闭合——Markdown 会把它后面的正文当成代码 continuing 渲染。
 * 题库解析里根本没有这段（写的是「题干问的就是这一条。」），所以按课文侧残留处理：整段删掉，
 * 前面的句子用句号收尾。题干本身就在上一行「- **题目**：」里，删掉不影响作答。
 *
 *   node tool/content_pipeline/wave38_drop_injected_stem.js [--apply] [--show]
 */
const fs = require('fs');

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const JUDGE = /^(\s*-\s*\*\*判断依据\*\*：)([\s\S]*)$/;

/// 形态 A：题干「填空：…课程 `X」问的就是这一条。→ 题干问的就是这一条。
/// 用结尾的「问的就是这一条。」定位，避免注入内容里自带的「」把匹配提前截断。
const SHAPE_A = /题干「填空[\s\S]*?」问的就是这一条。/g;
/// 同一处注入的另一种收尾：「…再逐项排除与题干「填空…」不符的说法。」
const SHAPE_A2 = /题干「填空[\s\S]*?」不符的说法。/g;
/// 形态 B：，本题问的是填空：…（到本句结束）→ 整段删掉。
const SHAPE_B = /[，、]?本题问的是填空[^。]*。?/g;

function repair(text) {
  let out = String(text || '');
  let a = 0;
  let b = 0;
  const stepA = out
    .replace(SHAPE_A, () => {
      a++;
      return '题干问的就是这一条。';
    })
    .replace(SHAPE_A2, () => {
      a++;
      return '题干不符的说法。';
    });
  const stepB = stepA.replace(SHAPE_B, () => {
    b++;
    return '';
  });
  out = stepB;
  if (a || b) {
    out = out
      .replace(/[，、]\s*(?=[。；！？])/g, '')
      .replace(/。{2,}/g, '。')
      .replace(/\s{2,}/g, ' ')
      .replace(/[，、]\s*$/, '。')
      .trim();
  }
  return [out, a, b];
}

const dir = 'assets/content';
let files = 0;
let lines = 0;
let shapeA = 0;
let shapeB = 0;
let leftover = 0;
const samples = [];

for (const name of fs.readdirSync(dir)) {
  if (!name.endsWith('.md')) continue;
  const path = `${dir}/${name}`;
  const text = fs.readFileSync(path, 'utf8');
  const nl = text.includes('\r\n') ? '\r\n' : '\n';
  const rows = text.split(/\r?\n/);
  let changed = 0;
  for (let i = 0; i < rows.length; i++) {
    const hit = JUDGE.exec(rows[i]);
    if (!hit) continue;
    if (!/题干「填空|本题问的是填空/.test(hit[2])) continue;
    const [repaired, a, b] = repair(hit[2]);
    lines++;
    shapeA += a;
    shapeB += b;
    if (/题干「填空|本题问的是填空|课程 `[^`\n]*$/.test(repaired)) {
      leftover++;
      if (SHOW) samples.push([`未洗干净 ${name}:${i + 1}`, repaired.slice(-160)]);
    }
    if (SHOW && samples.length < 26 && !/课程 `[^`\n]*$/.test(repaired)) {
      samples.push([`${name}:${i + 1}`, hit[2].slice(-160), repaired.slice(-160)]);
    }
    if (repaired !== hit[2]) {
      rows[i] = hit[1] + repaired;
      changed++;
    }
  }
  if (changed) {
    files++;
    if (APPLY) fs.writeFileSync(path, rows.join(nl));
  }
}

console.log(
  `判断依据行 ${lines}｜题干「…」收成「题干」${shapeA} 处｜删除注入半句 ${shapeB} 处｜未洗干净 ${leftover}｜改动文件 ${files}`
);
if (SHOW) {
  for (const sample of samples) {
    console.log(
      `\n[${sample[0]}]\n  原文 ${sample[1]}` + (sample[2] ? `\n  改后 ${sample[2]}` : '')
    );
  }
}
if (!APPLY) console.log('（试运行，加 --apply 才落盘）');
