// 第 20 波：删掉干扰项里的通用填充句。
//
// rebalance_single_option_length.dart 的 B 策略为了抹平「最长项即答案」的长度线索，
// 从语料库给干扰项追加过两类子句：主题相关的（「但这会破坏事务边界」）和纯填充的
// （「但这会引入新的复杂度」「需要额外的验证与维护」）。后者换成任何一道题都能成立，
// 属于没有信息量的机器填充，比长度线索更伤内容质量，这里整体删掉；
// 主题相关的那类保留，但同一条选项里叠加两条以上的，只留最贴主题的一条。
// 正确项一律不动。
// 用法：node tool/content_pipeline/wave20_strip_filler_clauses.js [--apply] [--show]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const P = 'assets/content/manifest.json';
const raw = fs.readFileSync(P, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

const GENERIC = [
  '但这会带来额外的维护成本',
  '实际效果取决于具体实现',
  '但这会引入新的复杂度',
  '需要额外的验证与维护',
  '但它只覆盖了部分情况',
  '不过这需要额外的前提条件',
  '但它并不是通用的做法',
  '往往无法达到预期效果',
];
// 语料库里的主题句（tool/option_length_bias_lib.dart），只认这些，避免误删正文里合法的「但」子句。
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

const stripOne = (text, clause) => {
  const i = text.lastIndexOf(clause);
  if (i < 0) return null;
  let start = i;
  while (start > 0 && /[，、；;,\s]/.test(text[start - 1])) start--;
  return text.slice(0, start).trim() + text.slice(i + clause.length).replace(/^[，、；;,]/, '').trim();
};

let removedGeneric = 0, removedStacked = 0, touched = 0, expTouched = 0;
const samples = [];

// B 策略当时把补出来的干扰项同步进了「解析」正文，选项删干净后解析里还留着同一批填充句。
const cleanExplanation = (text) => {
  let out = text;
  for (const clause of GENERIC) {
    while (out.includes('，' + clause)) out = out.split('，' + clause).join('');
    while (out.includes(clause)) out = out.split(clause).join('');
  }
  out = out
    .replace(/[，、；]{2,}/g, '，')
    .replace(/，。/g, '。')
    .replace(/。{2,}/g, '。')
    .replace(/[，、；]+\./g, '.')
    .replace(/(?<=[，、；])\s+(?=。)/g, '')
    .replace(/\s{2,}/g, ' ')
    .trim();
  return out === text ? null : out;
};

for (const c of manifest.categories) {
  for (const l of c.lessons || []) {
    for (const q of l.quiz || []) {
      const options = Array.isArray(q.options) ? q.options : [];
      const answerIdx = typeof q.answer === 'number' ? q.answer : -1;
      for (let i = 0; i < options.length; i++) {
        if (i === answerIdx) continue;
        let text = String(q.options[i]);
        const original = text;
        for (const clause of GENERIC) {
          let next;
          while ((next = stripOne(text, clause)) !== null) { text = next; removedGeneric++; }
        }
        const kept = THEMED.filter((t) => text.includes(t));
        if (kept.length > 1) {
          // 只保留最后出现的那条主题句，其余按同样的边界规则删掉。
          const positions = kept.map((t) => ({ t, p: text.lastIndexOf(t) })).sort((a, b) => a.p - b.p);
          for (const drop of positions.slice(0, -1)) {
            const next = stripOne(text, drop.t);
            if (next !== null) { text = next; removedStacked++; }
          }
        }
        text = text.replace(/\s{2,}/g, ' ').trim();
        if (text && text !== original) {
          options[i] = text;
          touched++;
          if (SHOW && samples.length < 12) samples.push(`${l.id}｜${original} → ${text}`);
        }
      }
      if (typeof q.explanation === 'string') {
        const cleaned = cleanExplanation(q.explanation);
        // 解析被删空到不足 120 字符门槛时保持原样，交给后续 P0 检查暴露。
        if (cleaned && cleaned.length >= 120) { q.explanation = cleaned; expTouched++; }
      }
    }
  }
}

console.log(`删掉通用填充句 ${removedGeneric} 处、多余主题句 ${removedStacked} 处，改写选项 ${touched} 条，改写解析 ${expTouched} 条`);
if (samples.length) console.log(samples.join('\n'));
if (APPLY) {
  fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('已写盘');
} else console.log('（dry-run，加 --apply 才写盘）');
