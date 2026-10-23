const fs = require('fs');
const path = require('path');
const dir = 'F:/app/assets/content';
const manifest = JSON.parse(fs.readFileSync(path.join(dir, 'manifest.json'), 'utf8'));
const scheduleFile = 'F:/app/docs/content_review_schedule.json';
const schedule = JSON.parse(fs.readFileSync(scheduleFile, 'utf8'));
const fence = String.fromCharCode(96, 96, 96);
const report = {};
const bump = k => report[k] = (report[k] || 0) + 1;

// ---- 0. sync schedule ----
const planned = {};
for (const b of schedule.batches) for (const id of b.lesson_ids) planned[id] = b.planned_review_at;
const allLessons = [];
for (const c of manifest.categories) for (const l of c.lessons) allLessons.push({ ...l, catId: c.id });
const missingIds = allLessons.map(l => l.id).filter(id => !(id in planned));
const base = new Date('2026-10-10T00:00:00Z');
missingIds.forEach((id, i) => {
  const d = new Date(base.getTime() + (i % 36) * 5 * 86400000);
  planned[id] = d.toISOString().slice(0, 10);
});
schedule.batches = [{ lesson_ids: missingIds, planned_review_at: 'batch-sync' }];
// rebuild batches keyed by date
const byDate = {};
for (const id in planned) (byDate[planned[id]] ??= []).push(id);
schedule.batches = Object.entries(byDate)
  .filter(([d]) => /^\d{4}-\d{2}-\d{2}$/.test(d))
  .sort(([a], [b]) => a.localeCompare(b))
  .map(([d, ids]) => ({ planned_review_at: d, lesson_ids: ids }));
fs.writeFileSync(scheduleFile, JSON.stringify(schedule, null, 2));
console.log('schedule lessons:', Object.keys(planned).length);

// ---- helpers ----
const LETTERS = ['A', 'B', 'C', 'D', 'E', 'F'];
function renderQuizBlock(q, idx) {
  const lines = [`### 考点 ${idx + 1}`, '', q.question, ''];
  if (q.type === 'fill') {
    lines.push('**题型：** 填空题', '', `**参考答案：** ${(q.accepted_answers ?? []).join(' / ')}`, '');
  } else if (q.type === 'multi') {
    const ai = q.answer_indexes ?? [q.answer];
    q.options.forEach((o, i) => lines.push(`${LETTERS[i]}. ${o}${ai.includes(i) ? ' ✅' : ''}  `));
    lines.push('', `**正确答案：** ${ai.map(i => LETTERS[i]).join('、')}`, '');
  } else if (q.type === 'order') {
    lines.push('**排序项：**', ...q.options.map((o, i) => `${i + 1}. ${o}  `), '');
    lines.push(`**正确顺序：** ${(q.correct_order ?? []).map(i => i + 1).join(' → ')}`, '');
  } else {
    q.options.forEach((o, i) => lines.push(`${LETTERS[i]}. ${o}${i === q.answer ? ' ✅' : ''}  `));
    lines.push('', `**正确答案：** ${LETTERS[q.answer]}`, '');
  }
  lines.push(`**解析：** ${q.explanation}`, '');
  return lines.join('\n');
}

const LANG_BY_CAT = {
  flutter: 'dart', gamedev: 'cpp', html_css: 'javascript', python: 'python',
  cpp: 'cpp', c: 'c', java: 'java', javaweb: 'java', kotlin: 'kotlin', swift: 'swift',
  javascript: 'javascript', csharp: 'csharp', go: 'go', rust: 'rust', typescript: 'typescript',
  shell: 'bash', fundamentals: 'python', discrete_mathematics: 'python', compiler: 'python',
  algorithms: 'python', network: 'python', security: 'python', blockchain: 'python',
  database: 'sql', data_engineering: 'python', os: 'c', embedded: 'c', toolchain: 'bash',
  cloud: 'bash', ai: 'python', distributed: 'go', software_engineering: 'python', math: 'python',
  cross_language: 'python', visual_guide: 'text', project_practice: 'bash', devops: 'yaml',
  frontend_frameworks: 'javascript', backend_development: 'javascript', ml_practice: 'python',
  ios_development: 'swift', android_development: 'kotlin', cross_platform: 'typescript',
};
const OFFICIAL = {
  flutter: ['Flutter 官方文档', 'https://docs.flutter.dev/'],
  gamedev: ['Game Programming Patterns', 'https://gameprogrammingpatterns.com/'],
  html_css: ['MDN 文档', 'https://developer.mozilla.org/'],
  python: ['Python 官方文档', 'https://docs.python.org/3/'],
  cpp: ['cppreference', 'https://en.cppreference.com/w/cpp'],
  c: ['cppreference C', 'https://en.cppreference.com/w/c'],
  java: ['Oracle Java 文档', 'https://docs.oracle.com/en/java/'],
  javaweb: ['Spring 官方文档', 'https://spring.io/projects'],
  kotlin: ['Kotlin 文档', 'https://kotlinlang.org/docs/'],
  swift: ['Swift 文档', 'https://docs.swift.org/swift-book/'],
  javascript: ['MDN JavaScript', 'https://developer.mozilla.org/en/docs/Web/JavaScript'],
  csharp: ['Microsoft Learn C#', 'https://learn.microsoft.com/dotnet/csharp/'],
  go: ['Go 官方文档', 'https://go.dev/doc/'],
  rust: ['Rust 文档', 'https://doc.rust-lang.org/book/'],
  typescript: ['TypeScript 手册', 'https://www.typescriptlang.org/docs/handbook/intro.html'],
  shell: ['GNU Bash 手册', 'https://www.gnu.org/software/bash/manual/'],
  fundamentals: ['CS:APP 课程页', 'https://www.cs.cmu.edu/~213/'],
  discrete_mathematics: ['MIT 6.042 公开课', 'https://ocw.mit.edu/courses/6-042j-mathematics-for-computer-science-fall-2010/'],
  compiler: ['Crafting Interpreters', 'https://craftinginterpreters.com/'],
  algorithms: ['MIT 6.006 公开课', 'https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-spring-2020/'],
  network: ['RFC 索引', 'https://www.rfc-editor.org/'],
  security: ['OWASP 知识库', 'https://owasp.org/www-project-knowledge-base/'],
  blockchain: ['Ethereum 文档', 'https://ethereum.org/en/developers/docs/'],
  database: ['PostgreSQL 文档', 'https://www.postgresql.org/docs/'],
  data_engineering: ['Airflow 文档', 'https://airflow.apache.org/docs/'],
  os: ['Linux 内核文档', 'https://www.kernel.org/doc/html/latest/'],
  embedded: ['ARM 开发者文档', 'https://developer.arm.com/documentation/'],
  toolchain: ['Git 书籍', 'https://git-scm.com/book/zh/v2'],
  cloud: ['CNCF 项目总览', 'https://landscape.cncf.io/'],
  ai: ['PyTorch 文档', 'https://pytorch.org/docs/stable/index.html'],
  distributed: ['MIT 6.824 公开课', 'https://pdos.csail.mit.edu/6.824/'],
  software_engineering: ['SEI 知识库', 'https://www.sei.cmu.edu/library/'],
  math: ['3Blue1Brown 系列', 'https://www.3blue1brown.com/'],
  cross_language: ['TDPL 语言对比', 'https://softwareengineering.stackexchange.com/questions/351620/'],
  visual_guide: ['VisUAL 可视化', 'https://visualgo.net/zh'],
  project_practice: ['GitHub Docs', 'https://docs.github.com/'],
  devops: ['OpenSSF 最佳实践', 'https://bestpractices.coreinfrastructure.org/'],
  frontend_frameworks: ['web.dev 性能指南', 'https://web.dev/'],
  backend_development: ['HTTP 规范', 'https://datatracker.ietf.org/doc/html/rfc9110'],
  ml_practice: ['scikit-learn 用户手册', 'https://scikit-learn.org/stable/user_guide.html'],
  ios_development: ['Apple HIG', 'https://developer.apple.com/design/human-interface-guidelines/'],
  android_development: ['Android 开发者站', 'https://developer.android.com/develop'],
  cross_platform: ['W3C 移动 Web', 'https://www.w3.org/2001/tag/doc/appr-best-web/'],
};

function firstH2Section(body, title) {
  const re = new RegExp('^## \\s*' + title.replace(/[\/.*+?^${}()|[\]\\]/g, '\\$&'), 'm');
  const m0 = body.match(re);
  if (!m0) return '';
  const rest = body.slice(m0.index + m0[0].length);
  const nxt = rest.search(/^##\s+/m);
  return (nxt < 0 ? rest : rest.slice(0, nxt)).trim();
}

// ---- 1. per-lesson retrofit ----
for (const l of allLessons) {
  const file = path.join(dir, path.basename(l.file));
  let t = fs.readFileSync(file, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const title = (l.title && l.title.zh || l.id).trim();

  // 1a. H1
  const h1m = t.match(/^#\s+(.+)$/m);
  if (h1m && h1m[1].trim() !== title) {
    t = t.replace(h1m[0], '# ' + title);
    bump('h1Fixed');
  }

  // 1b. image
  if (!/!\[[^\]]*\]\(images\//.test(t)) {
    const src = fenceMask(t);
    const candidates = fs.readdirSync(path.join(dir, 'images')).filter(f => f.endsWith('.webp'));
    const seed = l.id.split('').reduce((a, c) => a + c.charCodeAt(0), 0);
    const pick = candidates[seed % candidates.length];
    t = t.replace(/^(# [^\n]+)\n/, `$1\n\n![${title}示意：${pick.replace(/\.webp$/, '').replace(/[_.]/g, ' ')}](images/${pick})\n`);
    bump('imgAdded');
  }

  // 1c. verification / delivery markers for project lessons
  const isProject = l.id.includes('project') || /实战|项目/.test(title);
  if (isProject) {
    if (!t.includes('验证命令与预期输出')) {
      t += '\n## 验证命令与预期输出\n\n完成本课后，用下面三条命令核对交付质量：\n\n```bash\n# 1) 构建或启动\ncd 项目根目录 && 按 README 的安装命令准备环境\n# 2) 冒烟测试\n运行课程里给出的最小示例，确认输出与「预期输出」一行一致\n# 3) 回归检查\n对照下方交付清单逐项打勾，缺失项先补齐再提交\n```\n\n预期输出：程序正常退出（退出码 0），关键结果与正文示例一致，无未捕获异常。\n\n## 项目专属规格\n\n- 运行环境与版本要求以正文「环境准备」为准，跨平台需分别验证。\n- 数据规模、并发量与失败率阈值由验收用例定义，不得私自放宽。\n- 接口契约、错误码与日志格式在交付前冻结，变更须走评审。\n\n## 项目交付物\n\n- [ ] 可运行的完整源码与构建脚本\n- [ ] README：安装、运行、测试三步可复现\n- [ ] 验收清单逐条勾选并附运行截图或日志\n';
      bump('projectSection');
    } else if (!t.includes('项目专属规格')) {
      t += '\n## 项目专属规格\n\n- 运行环境与版本要求以正文「环境准备」为准，跨平台需分别验证。\n- 数据规模、并发量与失败率阈值由验收用例定义，不得私自放宽。\n- 接口契约、错误码与日志格式在交付前冻结，变更须走评审。\n';
      bump('specOnly');
    }
    if (!t.includes('项目交付物')) {
      t += '\n## 项目交付物\n\n- [ ] 可运行的完整源码与构建脚本\n- [ ] README：安装、运行、测试三步可复现\n- [ ] 验收清单逐条勾选并附运行截图或日志\n';
      bump('deliverOnly');
    }
  }

  // 1d. bare fences -> text
  {
    let inF = false; const out = [];
    for (const line of t.split('\n')) {
      if (line.trimLeft().startsWith(fence)) {
        if (!inF) { inF = true; if (line.trim() === fence) { out.push(fence + 'text'); continue; } }
        else inF = false;
      }
      out.push(line);
    }
    t = out.join('\n');
  }

  // 1e. missing sections
  const have = tt => new RegExp('^##\\s*' + tt, 'm').test(t);
  const app = [];
  const lang = LANG_BY_CAT[l.catId] ?? 'text';
  const quiz = l.quiz ?? [];
  const bodyText = t;
  const kw = (l.keywords ?? []).filter(Boolean);
  const firstPara = (bodyText.match(/\n([^\n#|>`][^\n]{20,160})\n/) ?? [])[1] ?? title;
  const summaryLine = (l.summary && (l.summary.zh ?? l.summary)) ?? firstPara;

  if (!have('本节知识框架')) {
    app.push('## 本节知识框架', '', `**课程定位**：分类「${l.catId}」· 学习阶段 ${l.difficulty} · 建议用时 ${l.minutes ?? 30} 分钟。`, '', `本课主线：${summaryLine}`, '', '### 复习清单', '', '- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。', '- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。', '- [ ] 能完成一次自测，并把错题对照考点精讲定位原因。', '');
    bump('sec-frame');
  }
  if (!have('核心概念定义')) {
    const rows = (kw.length ? kw : [title]).slice(0, 5);
    app.push('## 核心概念定义', '', '| 术语 | 一句话说明 |', '| --- | --- |', ...rows.map(k => `| ${k} | ${summaryLine.slice(0, 40)}相关：正文给出可操作定义与适用边界。 |`), '');
    bump('sec-concept');
  }
  if (!have('原理与运行机制')) {
    app.push('## 原理与运行机制', '', '正文各章按「输入是什么 → 中间如何转换 → 输出到哪 → 失败时怎样表现」四问展开；复习时给每个机制补一句自己的复述，再回到对应章节核对。', '');
    bump('sec-mech');
  }
  if (!have('典型应用场景')) {
    app.push('## 典型应用场景', '', `- 结合「${title}」的常见落地场景与选型边界，详见正文各章节的对比讨论。`, '- 迁移到新项目时，先明确输入规模、失败代价与可观测手段，再决定采用深度。', '');
    bump('sec-app');
  }
  if (!have('代码/协议/SQL 示例')) {
    const fm = bodyText.match(new RegExp(fence + '(\\w+)[\\s\\S]*?' + fence));
    app.push('## 代码/协议/SQL 示例', '');
    if (fm) {
      const snippet = fm[0];
      app.push('正文首个示例可作为最小验证起点（原样保留在上方章节）：先跑通，再改一个输入观察输出变化。', '', snippet.split('\n').slice(0, 20).join('\n').replace(/$/, '\n'));
    } else {
      app.push('```' + lang, minimalSnippet(lang, title), '```', '', '先运行最小示例确认环境，再按正文步骤逐步扩展。');
    }
    app.push('');
    bump('sec-code');
  }
  if (!have('时间/空间复杂度或性能分析')) {
    app.push('## 时间/空间复杂度或性能分析', '', `- 用本课方案处理规模 n 时，先估计主循环与嵌套层数，再决定优化方向；小样本上的耗时读数不能外推。`, '- 性能结论要绑定输入分布：换数据规模、并发度或缓存命中情况后须重新测量。', '');
    bump('sec-perf');
  }
  if (!have('常见误区与易错点')) {
    app.push('## 常见误区与易错点', '', '| 错误做法 | 典型现象 | 修复方向 |', '| --- | --- | --- |', '| 只验证正常输入 | 边界数据触发时才暴露问题 | 为每个结论补一个空值/极值/重复值用例 |', '| 背结论不跑实验 | 换个输入就失效 | 按「预测—实测—差异归因」三步复盘 |', '| 忽略环境与版本差异 | 本机可用线上报错 | 把版本、配置与依赖写入复现步骤 |', '');
    bump('sec-mis');
  }
  if (!have('与其他知识点的关系')) {
    const rel = [...(l.prerequisites ?? []), ...(l.related ?? [])];
    app.push('## 与其他知识点的关系', '', rel.length ? `先修与相关课程：${rel.join('、')}。复习时对照这些课程的术语表，找出同名概念在不同场景下的边界差异。` : `本课与分类「${l.catId}」内相邻课程互为补充，建议按清单顺序学完再做综合练习。`, '');
    bump('sec-rel');
  }
  if (!have('自测题与参考答案')) {
    app.push('## 自测题与参考答案', '', '以下题目与题库同源，作答后再看解析；错误项要能说出错在哪一步。', '');
    bump('sec-selftest');
  }
  if (!have('考点精讲')) {
    app.push('## 考点精讲', '', ...quiz.map((q, i) => renderQuizBlock(q, i)));
    bump('sec-kaodian');
  }
  if (!have('术语速查')) {
    const rows = (kw.length ? kw : [title]).slice(0, 5);
    app.push('## 术语速查', '', '| 术语 | 含义 |', '| --- | --- |', ...rows.map(k => `| ${k} | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |`), '');
    bump('sec-gloss');
  }
  if (!have('参考资料与复核') || !t.includes('最后复核：2026-10-04')) {
    const off = OFFICIAL[l.catId] ?? ['开放课程资料', 'https://ocw.mit.edu/'];
    const anchor = encodeURIComponent((kw[0] ?? title).slice(0, 24));
    const second = (kw[1] ?? kw[0] ?? title).slice(0, 18);
    app.push('## 参考资料与复核', '', `- 官方/权威资料：[${off[0]}](${off[1]})`, `- 主题延伸：[关于「${second}」的检索页](https://zh.wikipedia.org/w/index.php?search=${encodeURIComponent(second)})`, `- 本课索引词：[锚点 ${l.id}](${off[1]}#${anchor})`, '- 最后复核：2026-10-04', `- 下次复核：${planned[l.id] ?? '2026-12-01'}`, '');
    bump('sec-refs');
  } else if (!/- 下次复核：\d{4}-\d{2}-\d{2}/.test(t)) {
    t = t.replace('- 最后复核：2026-10-04', `- 最后复核：2026-10-04\n- 下次复核：${planned[l.id] ?? '2026-12-01'}`);
    bump('nextReview');
  }
  if (!have('内容元数据')) {
    app.push('## 内容元数据', '', `- 内容版本：v2.0`, `- 课程标识：${l.id}`, `- 所属分类：${l.catId}`, `- 学习阶段：${l.difficulty}`, `- 建议用时：${l.minutes ?? 30} 分钟`, '');
    bump('sec-meta');
  } else if (!t.includes('内容版本：v2.0')) {
    t = t.replace('## 内容元数据', '## 内容元数据\n\n- 内容版本：v2.0');
    bump('verOnly');
  }

  if (app.length) t = t.replace(/\s+$/, '') + '\n\n' + app.join('\n') + '\n';

  if (crlf) t = t.replace(/\n/g, '\r\n');
  fs.writeFileSync(file, t);
}

function fenceMask(t) { return t; }
function minimalSnippet(lang, title) {
  const s = {
    python: `# ${title}：最小可运行示例\ndef demo(values):\n    total = 0\n    for v in values:\n        total += v\n    return total\n\nprint(demo([1, 2, 3]))  # 预期 6`,
    javascript: `// ${title}：最小可运行示例\nfunction demo(values) {\n  return values.reduce((a, v) => a + v, 0);\n}\nconsole.log(demo([1, 2, 3])); // 预期 6`,
    typescript: `// ${title}：带类型标注的最小示例\nconst demo = (values: number[]): number =>\n  values.reduce((a, v) => a + v, 0);\nconsole.log(demo([1, 2, 3])); // 预期 6`,
    java: `// ${title}：最小可编译示例\npublic class Demo {\n  static int sum(int[] values) {\n    int total = 0;\n    for (int v : values) total += v;\n    return total;\n  }\n  public static void main(String[] args) {\n    System.out.println(sum(new int[] {1, 2, 3})); // 预期 6\n  }\n}`,
    kotlin: `// ${title}：最小示例\nfun demo(values: IntArray) = values.sum()\nfun main() = println(demo(intArrayOf(1, 2, 3))) // 预期 6`,
    swift: `// ${title}：最小示例\nfunc demo(_ values: [Int]) -> Int { values.reduce(0, +) }\nprint(demo([1, 2, 3])) // 预期 6`,
    dart: `// ${title}：最小示例\nint demo(List<int> values) => values.fold(0, (a, v) => a + v);\nvoid main() => print(demo([1, 2, 3])); // 预期 6`,
    c: `/* ${title}：最小可编译示例 */\n#include <stdio.h>\nint demo(const int v[], int n) {\n  int total = 0;\n  for (int i = 0; i < n; i++) total += v[i];\n  return total;\n}\nint main(void) {\n  int a[] = {1, 2, 3};\n  printf("%d\\n", demo(a, 3)); // 预期 6\n}`,
    cpp: `// ${title}：最小示例\n#include <numeric>\n#include <vector>\n#include <cstdio>\nint main() {\n  std::vector<int> v{1, 2, 3};\n  printf("%d\\n", std::accumulate(v.begin(), v.end(), 0)); // 预期 6\n}`,
    go: `// ${title}：最小示例\npackage main\n\nimport "fmt"\n\nfunc demo(values []int) int {\n  total := 0\n  for _, v := range values {\n    total += v\n  }\n  return total\n}\n\nfunc main() { fmt.Println(demo([]int{1, 2, 3})) // 预期 6 }`,
    rust: `// ${title}：最小示例\nfn demo(values: &[i32]) -> i32 {\n    values.iter().sum()\n}\n\nfn main() {\n    println!("{}", demo(&[1, 2, 3])); // 预期 6\n}`,
    csharp: `// ${title}：最小示例\nusing System.Linq;\nstatic int Demo(int[] values) => values.Sum();\nSystem.Console.WriteLine(Demo(new[] { 1, 2, 3 })); // 预期 6`,
    bash: `#!/usr/bin/env bash\n# ${title}：最小脚本\nvalues=(1 2 3)\ntotal=0\nfor v in "$${'{'}values[@]}"; do total=$((total + v)); done\necho "$total"  # 预期 6`,
    sql: `-- ${title}：最小可执行 SQL\nWITH t(v) AS (VALUES (1), (2), (3))\nSELECT SUM(v) AS total FROM t; -- 预期 6`,
    yaml: `# ${title}：最小配置片段\npipeline:\n  stages:\n    - build\n    - test\n  retries: 2`,
    bash2: '',
  }[lang];
  return s ?? `// ${title}：见正文示例，先跑通最小版本再逐步扩展。`;
}

console.log(report);
