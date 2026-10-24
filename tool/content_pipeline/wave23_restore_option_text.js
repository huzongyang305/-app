// 第 23 波：恢复被“截短正确项”策略削掉的答案内容，并清除残留的语料填充子句。
//
// 背景：rebalance_single_option_length.dart 为了抹平「最长项即答案」的长度线索，
// 用过 A2 策略把正确项的尾部子句直接砍掉。长度线索是小问题，正确答案缺信息是大问题：
// 例如 JWT 的三部分被砍成「头部（Header）」，多阶段构建的目的只剩「分离构建环境和运行环境」。
// 这里以 HEAD 的 manifest 为基准把被截断的选项整条恢复，随后再把 B 策略语料库
// （GENERIC + THEMED，含「同时这会…」变体）追加到选项上的填充子句统一删除——
// 这类子句换到任何一道题都能成立，属于噪声。选项文本每改一次，解析里对应的引用同步替换。
// 用法：node tool/content_pipeline/wave23_restore_option_text.js [--apply] [--show]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const P = 'assets/content/manifest.json';
const BASE = process.env.BASE_MANIFEST || 'C:/Users/m1899/Documents/Qoder/2026-10-19/1cff233e/.tmp/manifest_head.json';

const raw = fs.readFileSync(P, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);
const base = JSON.parse(fs.readFileSync(BASE, 'utf8'));

const GENERIC = [
  '但这会带来额外的维护成本', '实际效果取决于具体实现', '但这会引入新的复杂度', '需要额外的验证与维护',
  '但它只覆盖了部分情况', '不过这需要额外的前提条件', '但它并不是通用的做法', '往往无法达到预期效果',
];
const THEMED = [
  '但这会拖慢关键路径的响应', '但这会增加每帧的开销', '但这会让抖动更明显', '实际收益取决于具体负载',
  '但在高并发下会明显劣化', '但这只是把开销挪到了别处', '但这会占用更多内存', '但这会加重回收压力',
  '但生命周期结束后仍可能被引用', '实际占用取决于运行环境', '但这并不能根治泄漏', '但这会留下攻击面',
  '但这无法抵御主动攻击', '但这需要额外的密钥管理', '但在边界输入下并不安全', '但这只是隐藏了风险',
  '但这会降低可维护性', '但这会让后续改动更难', '但这会增加理解成本', '但很快就会出现重复代码',
  '但耦合会越来越重', '但这会让包体更大', '但这会拖慢构建速度', '但这会引入额外的依赖',
  '但需要额外的缓存与清理', '但这会牺牲可复现性', '但这会带来一致性问题', '但这在数据量大时不可行',
  '但这会破坏事务边界', '但这会加重锁竞争', '但这无法保证正确性', '但这会增加往返次数',
  '但这会在弱网下失败', '但这会放大延迟', '但这会需要额外的重试机制', '但这需要额外的重试机制',
  '但这会掩盖真实的缺陷', '但这会让用例变得脆弱', '但这只覆盖了理想路径', '但这无法复现线上问题',
  '但这会拖慢反馈速度',
];
// B 策略在同一条选项上叠加第二句时把开头的「但这」改写成「同时这」，属于同一批语料。
const CLAUSES = [...GENERIC, ...THEMED];
const tailOf = (c) => (c.startsWith('但这') ? c.slice(2) : c.startsWith('但') ? c.slice(1) : c);
for (const c of [...CLAUSES]) CLAUSES.push('同时这' + tailOf(c));

const norm = (s) => String(s || '').replace(/[\s，、；;：:。.．]/g, '');
const stripOne = (text, clause) => {
  const i = text.lastIndexOf(clause);
  if (i < 0) return null;
  let start = i;
  while (start > 0 && /[，、；;,\s]/.test(text[start - 1])) start--;
  return text.slice(0, start).trim() + text.slice(i + clause.length).replace(/^[，、；;,]/, '').trim();
};

const baseIndex = new Map();
for (const c of base.categories) for (const l of c.lessons || []) baseIndex.set(l.id, l);

let restored = 0, stripped = 0, expSynced = 0, checked = 0, net = 0;
const samples = [];
const netSamples = [];

for (const c of manifest.categories) {
  for (const l of c.lessons || []) {
    const bl = baseIndex.get(l.id);
    if (!bl) continue;
    for (let qi = 0; qi < (l.quiz || []).length; qi++) {
      const q = l.quiz[qi];
      const bq = (bl.quiz || [])[qi];
      if (!bq || !Array.isArray(q.options) || !Array.isArray(bq.options)) continue;
      checked++;
      const renames = [];
      for (let i = 0; i < q.options.length; i++) {
        const cur = String(q.options[i]);
        const old = String(bq.options[i] ?? '');
        let text = cur;
        // 1) 当前文本是 HEAD 文本的前缀（忽略标点）=> 曾被截短，整条恢复。
        if (old && norm(cur).length >= 4 && norm(old).startsWith(norm(cur)) &&
            norm(old).length - norm(cur).length >= 4 && old !== cur) {
          text = old;
          restored++;
          if (SHOW && samples.length < 20) samples.push(`恢复 ${l.id} q${qi}[${i}]：${cur} → ${old}`);
        }
        // 2) 删除语料库追加的填充子句（同一条上可能叠了两条）。
        const beforeStrip = text;
        for (const clause of CLAUSES) {
          let next;
          while ((next = stripOne(text, clause)) !== null) text = next;
        }
        text = text.replace(/\s{2,}/g, ' ').trim();
        if (text !== beforeStrip) stripped++;
        if (text && text !== cur) {
          net++;
          if (SHOW && netSamples.length < 24) netSamples.push(`${l.id} q${qi}[${i}]：${cur} → ${text}`);
          renames.push([cur, text]);
          q.options[i] = text;
        }
      }
      // 解析里引用的是旧文本，逐条换成新文本（长的先换，避免子串误替换）。
      if (renames.length && typeof q.explanation === 'string') {
        let ex = q.explanation;
        for (const [from, to] of renames.sort((a, b) => b[0].length - a[0].length)) {
          if (from.length >= 6 && ex.includes(from)) ex = ex.split(from).join(to);
        }
        if (ex !== q.explanation) {
          if (ex.trim().length >= 120) { q.explanation = ex; expSynced++; }
        }
      }
    }
  }
}

console.log(
  `比对题目 ${checked} 道：命中截短 ${restored} 条、语料子句 ${stripped} 处，` +
    `实际改写选项 ${net} 条，同步解析 ${expSynced} 条`,
);
if (netSamples.length) console.log(netSamples.join('\n'));
if (APPLY) {
  fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('已写盘');
} else console.log('（dry-run，加 --apply 才写盘）');
