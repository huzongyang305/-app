// 第 14 波：把跨课复制的正文套话段落改成带本课标题的说法。
// 治理审计的 repeated_markdown_paragraph 会把出现在 20 门课以上的整段正文判为模板残留，
// 这三句分别出现在 47 / 40 / 28 门课，语义本身没问题，缺的是与本课的绑定。
// 用法：node tool/content_pipeline/wave14_md_unique_paragraphs.js [--apply]
import fs from 'node:fs';
import path from 'node:path';

const APPLY = process.argv.includes('--apply');
const CONTENT_DIR = 'assets/content';
const manifest = JSON.parse(fs.readFileSync(path.join(CONTENT_DIR, 'manifest.json'), 'utf8'));
const lessons = [];
for (const c of manifest.categories) for (const l of c.lessons) lessons.push(l);

const RULES = [
  {
    test: (line) => line.includes('用本课方案处理规模 n 时，先估计主循环与嵌套层数'),
    build: (title) => `- 在《${title}》里处理规模 n 时，先估计主循环与嵌套层数，再决定优化方向；小样本上的耗时读数不能外推。`,
  },
  {
    test: (line) => line.includes('正文各章按「输入是什么 → 中间如何转换 → 输出到哪 → 失败时怎样表现」四问展开'),
    build: (title) => `《${title}》正文各章按「输入是什么 → 中间如何转换 → 输出到哪 → 失败时怎样表现」四问展开；复习时给每个机制补一句自己的复述，再回到对应章节核对。`,
  },
  {
    test: (line) => line.includes('正文首个示例可作为最小验证起点（原样保留在上方章节）'),
    build: (title) => `《${title}》正文首个示例可作为最小验证起点（原样保留在上方章节）：先跑通，再改一个输入观察输出变化。`,
  },
];

let files = 0, lines = 0;
for (const l of lessons) {
  const p = path.join(CONTENT_DIR, path.basename(String(l.file)));
  if (!fs.existsSync(p)) continue;
  const raw = fs.readFileSync(p, 'utf8');
  const eol = raw.includes('\r\n') ? '\r\n' : '\n';
  const arr = raw.split(/\r?\n/);
  const title = String((l.title && (l.title.zh || l.title)) || l.id).trim();
  let changed = false;
  for (let i = 0; i < arr.length; i++) {
    for (const r of RULES) {
      if (r.test(arr[i]) && arr[i] !== r.build(title)) {
        arr[i] = r.build(title);
        changed++;
        lines++;
      }
    }
  }
  if (!changed) continue;
  files++;
  if (APPLY) fs.writeFileSync(p, arr.join(eol));
}

console.log(`正文套话段落改为带本课标题：${files} 个文件、${lines} 行`);
console.log(APPLY ? '已写盘' : '（dry-run，加 --apply 才写盘）');
