/*
 * wave41_fix_doubled_words.js — 收掉模板拼接留下的相邻重复字
 *
 * 生成器把「引导词 + 片段」直接相连，片段本身常以同一个字开头，
 * 于是课文里出现「第三步按按任务…」「正确做法是是 `i & -i`」这类残句。
 * 只按最长锚点折叠，不动「按按钮」「没有有效值」这种本来就正确的写法。
 *
 *   node tool/content_pipeline/wave41_fix_doubled_words.js          # 试运行
 *   node tool/content_pipeline/wave41_fix_doubled_words.js --apply  # 落盘
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const CONTENT = path.join(ROOT, 'assets', 'content');

const PAIRS = [
  ['第三步按按', '第三步按'],
  ['检验方式是按按', '检验方式是按'],
  ['第一步按按', '第一步按'],
  ['改成改成', '改成'],
  ['复现复现', '复现'],
  ['会造成造成', '会造成'],
  ['正确做法是是', '正确做法是'],
  ['整数有有符号和无符号之分', '整数分为有符号和无符号两类'],
];

const apply = process.argv.indexOf('--apply') >= 0;
const files = fs.readdirSync(CONTENT).filter((f) => f.endsWith('.md')).sort();
// 题库解析里同源的残句要和课文一起改，否则 考点精讲 与 explanation 会再次不同步。
files.push('manifest.json');

let touched = 0;
const hits = new Map(PAIRS.map((p) => [p[0], 0]));
for (const f of files) {
  const p = path.join(CONTENT, f);
  const before = fs.readFileSync(p, 'utf8');
  let after = before;
  for (const [oldText, newText] of PAIRS) {
    const parts = after.split(oldText);
    if (parts.length > 1) {
      hits.set(oldText, hits.get(oldText) + parts.length - 1);
      after = parts.join(newText);
    }
  }
  if (after === before) continue;
  touched++;
  if (apply) fs.writeFileSync(p, after, 'utf8');
  else console.log(f + '  ' + PAIRS.filter((pr) => before.includes(pr[0])).map((pr) => pr[0]).join(' / '));
}

console.log('');
for (const [oldText, n] of hits) console.log('  ' + oldText.padEnd(24) + ' × ' + n);
console.log((apply ? '已修改 ' : '将修改 ') + touched + ' 个文件' + (apply ? '' : '（试运行，未落盘）'));
