// 生成 devops_monitoring_alert 的替换课条目 + 候选 manifest。
// 只做「读取真实 manifest -> 克隆条目 -> 覆盖字段 -> 落盘」，不手改 manifest.json。
const fs = require('fs');
const DIR = 'F:/app/assets/content';
const MANIFEST = JSON.parse(fs.readFileSync(DIR + '/manifest.json', 'utf8'));
const LESSON_ID = 'devops_monitoring_alert';

let source = null;
for (const c of MANIFEST.categories)
  for (const l of c.lessons) if (l.id === LESSON_ID) source = l;
if (!source) throw new Error('source lesson not found');

const md = fs.readFileSync(DIR + '/devops_alerting_slo.md', 'utf8');
const norm = (s) => String(s).replace(/\s+/g, '');

const quiz = [
  {
    question:
      'Alertmanager 里一个已经通知过的告警分组又新增了一条同类告警，但通知没有立刻发出；另外同一批仍在触发的告警每隔几小时被重复提醒。这两种行为分别由哪两个参数控制？',
    options: [
      '前者由 group_interval 控制，它管的正是已经通知过的分组里新增告警的补发节奏',
      '前者由 group_wait 控制，它决定的是任意两条通知之间全局共享的最小发送间隔',
      '两者都由 group_wait 控制，区别只在于这段等待时长的具体配置数值各不相同',
      '两者都由 repeat_interval 控制，分组相关参数只影响首次通知的发送时间点',
    ],
    answer: 0,
    explanation:
      '三个时间参数各管一段，串起来才是一组告警的完整通知时间线。group_wait 只作用于新分组首次通知之前的攒批窗口；组内新增告警的补发看 group_interval；仍在 firing 的重复提醒看 repeat_interval，它既不会改变分组内容也不会更换接收人。把 group_wait 理解成全局最小间隔、或指望 repeat_interval 兼顾新增告警，都会让通知要么刷屏、要么迟迟不发；恢复通知同样跟着分组节奏下发，不受 repeat_interval 支配。',
    type: 'single',
  },
  {
    question:
      '路由树里某个子路由把 continue 设为 true，Alertmanager 会怎样处理命中它的告警？',
    options: [
      '命中后立即结束整棵树的匹配，只向该路由配置的接收器发送一次通知',
      '把这条告警退回 Prometheus 重新打标签，然后从头再走一遍路由匹配',
      '忽略该路由配置的接收器，仅在日志里记录一次匹配结果而不发送通知',
      '向这份接收器发出通知后继续匹配同层其余路由，告警可能同时到多个接收器',
    ],
    answer: 3,
    explanation:
      '路由默认自顶向下取第一个命中的分支，continue 是这条规则的开关：置为 true 时当前分支照常发送，同层后续分支与更深层仍会被继续尝试，因此一条安全类告警可以同时叫醒值班并抄送安全组。它不会把告警退回上游修改标签，也不会吞掉本分支的接收器；反过来，需要抄送却忘记设 true，就会出现旁路团队长期收不到通知的隐性漏报，这类问题往往要等到事故复盘才被发现。',
    type: 'single',
  },
  {
    question:
      '抑制（inhibition）与静默（silence）在告警治理里的分工边界是什么？',
    options: [
      '抑制由配置预先声明，源告警存在时自动压掉同标签的下级告警；静默是人工设立的限时豁免窗，到期自动失效',
      '抑制的作用范围只能限定在单个进程内的告警，静默则必须按整个集群的标签设立，二者不可交叉',
      '静默会让 Prometheus 停止求值对应的告警规则，因此团队常常用它来降低告警引擎的计算负载',
      '计划内的变更窗口一律写抑制规则，根因已经确认的连锁告警一律开静默窗口，两者用法正好互换',
    ],
    answer: 0,
    explanation:
      '抑制处理的是可复现、能用标签结构描述的连锁噪声，例如整集群宕机时压掉几百条服务级 warning，它随配置文件评审维护、可以长期存在；静默处理一次性的计划事件，靠到期时间、署名与事由约束，过期就应当消失。两者都只影响通知，不改变 Prometheus 侧的 firing 状态，也不能相互替换：抑制要求 equal 标签在源与目标两边都存在才会生效，静默把标签写宽了会顺手静音整个集群。真想降低求值负载只能改规则与记录规则本身。',
    type: 'single',
  },
  {
    question:
      '某服务把可用性 SLO 定为 30 天内 99.9%，错误预算因此是 0.1%。关于这份预算与告警阈值、发布节奏的关系，下列哪项正确？',
    options: [
      '错误预算只能事后统计并写进周报，它与阈值怎么设定以及发布节奏快慢都没有关系',
      '预算余量充足时可以先做高风险变更，消耗过快时冻结非必要变更并把人力转回可靠性',
      '只要预算还有剩余，SLO 就会被自动放宽，此时触发的高级别告警可以不必再响应',
      '阈值必须写成 30 天可用性低于 99.9% 才报警，因为这是唯一一种可计算的表达式',
    ],
    answer: 1,
    explanation:
      '预算的意义在于把「这周能不能上高风险改动」变成可审计的算术，而不是一个装饰性的统计数字。0.1% 换算成停机大约四十多分钟，燃速类阈值正是在这个尺度上分配它。把预算当成免责额度是常见误解：已经影响用户的故障仍要按分级去响应，剩余多少并不改变单条告警的严重性；而把阈值直接写成周期末尾的可用性判定，要等到三十天快走完才叫人，起不到止损作用，正确做法是用短窗口的燃速去投影这条长周期承诺。',
    type: 'single',
  },
  {
    question:
      '基于错误预算的燃速告警通常要求短窗口与长窗口两个条件同时满足才触发，这样设计的目的是什么？',
    options: [
      '短窗口负责尽快发现劣化，长窗口负责确认劣化确实在持续，两者同时成立才说明预算真在被消耗',
      '短窗口决定要不要把样本写入数据库，长窗口决定通知发往哪一个接收器与发送渠道',
      '两个窗口必须取完全相同的长度，否则 PromQL 里的 rate 函数没法计算燃速倍数',
      '长窗口只是给 Grafana 画趋势图用的，真正触发告警的一直都是短窗口的那一项条件',
    ],
    answer: 0,
    explanation:
      '这是一对职责不同的约束。短窗口把发现延迟压到分钟级，但容易被毛刺和瞬时尖峰打穿；长窗口滤掉抖动、确认劣化在持续，可单独使用时等到条件成立预算已经烧掉大半。两个条件用 and 连接，等于同时要求现在很糟并且已经糟了一阵。窗口长度与 for 都按同一套乘算公式调节，但每加一段等待都会吃掉响应预算；此外低流量时段还要补一个最小请求数条件，否则少量失败就能把错误率推到几十个百分点。',
    type: 'single',
  },
  {
    question:
      '团队想度量并治理值班同学的告警疲劳，下列哪些做法属于有价值的长期手段？',
    options: [
      '统计每人每周被页面唤醒的次数，以及自动恢复、无人处理即关闭的告警占比',
      '跟踪平均确认时长与告警到正式事故的转化率，用来判断阈值是不是设得过松',
      '给每条规则登记负责人，定期评审并按没有可执行动作就降级或删除来修剪规则',
      '把更多规则统一提到 critical 级别并全部接入页面通道，以保证重要告警不漏掉',
    ],
    answers: [0, 1, 2],
    answer: 0,
    explanation:
      '疲劳要当作容量问题来量化。人均页面次数与自动关闭比例直接反映噪声水平，平均确认时长与告警到事故转化率分别刻画值班响应质量和阈值松紧，再配合 Top offender 排行就能定位到少数真正该改造的规则。给每条规则设负责人，并把没有可执行动作就降级变成定期评审的固定动作，才能让通知量结构性下降。把所有规则提级恰恰相反：当所有告警都紧急时，值班会开始整体忽略通知，真正的问题反而被埋没在噪声里。',
    type: 'multi',
  },
];

// ---- 用题库文本反向生成 考点精讲，保证题干、选项与解析逐字一致 ----
const letters = ['A', 'B', 'C', 'D', 'E'];
function renderKeyPoints(items) {
  const blocks = items.map((q, i) => {
    const type = q.type || 'single';
    const lines = ['### 考点 ' + (i + 1), '', '题目：' + q.question];
    q.options.forEach((opt, k) => lines.push(letters[k] + '. ' + opt));
    const key =
      type === 'multi'
        ? (q.answers || []).map((k) => letters[k]).join('')
        : letters[q.answer];
    lines.push('正确答案：' + key, '', '解析：' + q.explanation);
    return lines.join('\n');
  });
  return '## 考点精讲\n\n' + blocks.join('\n\n') + '\n';
}
function spliceSection(text, title, body) {
  const lines = text.split('\n');
  const start = lines.findIndex((l) => l.trim() === '## ' + title);
  if (start < 0) throw new Error('section not found: ' + title);
  let end = lines.length;
  for (let i = start + 1; i < lines.length; i++)
    if (/^##\s/.test(lines[i])) { end = i; break; }
  const out = lines.slice(0, start).concat(body.split('\n'), lines.slice(end));
  return out.join('\n').replace(/\n{4,}/g, '\n\n\n');
}
const updated = spliceSection(md, '考点精讲', renderKeyPoints(quiz));
if (updated !== md) {
  fs.writeFileSync(DIR + '/devops_alerting_slo.md', updated, 'utf8');
  console.log('考点精讲 已按题库同步重写');
}
const doc = updated;

// ---- 自检：解析长度 / 题干与选项在正文中出现 / 正确项不是明显最长 ----
const EX_MARKERS = [
  '这道题对应的课程', '修正后要重跑', '本课在「', '本课还在「', '本课把「',
  '本课在核心知识', '本课还在核心知识', '对照「', '课程摘要',
];
const MD_MARKERS = [
  '先自己作答，再看「判断依据」', '**迁移检查**', '本课在「', '本课还在「',
  '本课在核心知识', '本课还在核心知识', '课程摘要指出', '回到正文对应章节补足概念',
  '把题干里的一个条件换成边界值', '把现象和原因写在一起', '错误信息通常会指出出错行和期望符号',
];
const problems = [];
for (const [i, q] of quiz.entries()) {
  const n = i + 1;
  if (String(q.explanation).length < 120) problems.push(`q${n} 解析过短 ${String(q.explanation).length}`);
  for (const m of EX_MARKERS) if (String(q.explanation).includes(m)) problems.push(`q${n} 解析含禁用串 ${m}`);
  if (q.question.includes('…')) problems.push(`q${n} 题干含省略号`);
  if (!norm(doc).includes(norm(q.question))) problems.push(`q${n} 题干未出现在正文`);
  const type = q.type || 'single';
  if (type === 'multi' && (q.answers || []).length < 2) problems.push(`q${n} 多选不足两项`);
  const correctIdx = type === 'single' ? q.answer : (q.answers || [0])[0];
  const lens = q.options.map((s) => s.trim().length);
  const others = lens.filter((_, k) => k !== correctIdx);
  const gap = lens[correctIdx] - Math.max(...others);
  if (gap >= 8) problems.push(`q${n} 正确项明显最长 +${gap} lens=[${lens}]`);
  // 选项与答案字母必须逐条出现在考点精讲里
  for (const [k, opt] of q.options.entries()) {
    if (!norm(doc).includes(norm(`${letters[k]}. ${opt}`))) problems.push(`q${n} 选项${letters[k]}未在正文逐字出现`);
  }
  const key = type === 'multi'
    ? (q.answers || []).map((k) => letters[k]).join('')
    : letters[q.answer];
  if (!norm(doc).includes(norm(`正确答案：${key}`))) problems.push(`q${n} 正文缺少正确答案：${key}`);
  if (!norm(doc).includes(norm(q.explanation))) problems.push(`q${n} 正文解析与题库不一致`);
}
for (const m of MD_MARKERS) if (doc.includes(m)) problems.push(`正文含禁用串 ${m}`);

// ---- 题干全库唯一（含另一条并行改造的 Android 候选条目）----
// 只关心本课新题干：基线 manifest 里 flutter_release 与 android_flutter_release
// 原本就互为重复，不属于本课要修的问题。
const stems = new Map();
const addStem = (text, owner) => {
  const k = norm(text);
  if (!stems.has(k)) stems.set(k, []);
  stems.get(k).push(owner);
};
for (const c of MANIFEST.categories)
  for (const l of c.lessons)
    if (l.id !== LESSON_ID) for (const q of l.quiz || []) addStem(q.question, l.id);
for (const alt of ['new_android_flutter_release.json']) {
  const p = 'F:/app/' + alt;
  if (!fs.existsSync(p)) continue;
  const obj = JSON.parse(fs.readFileSync(p, 'utf8'));
  for (const q of obj.quiz || []) addStem(q.question, 'candidate:' + obj.id);
}
for (const q of quiz) {
  const owners = stems.get(norm(q.question)) || [];
  if (owners.length) problems.push(`题干与 ${owners.join(',')} 冲突：${q.question.slice(0, 24)}`);
}
if (problems.length) {
  console.log('SELF-CHECK FAIL\n  ' + problems.join('\n  '));
  process.exit(1);
}

// ---- 组装替换条目：保留原 id/difficulty/order/minutes/prerequisites/related/code_quiz/lab ----
const lesson = JSON.parse(JSON.stringify(source));
lesson.title = {
  zh: '告警工程：分组路由、错误预算与燃速阈值',
  en: 'Alert Engineering: Routing, Budgets and Burn Rates',
};
lesson.summary = {
  zh: 'Alertmanager 分组路由、抑制与静默边界、SLO 错误预算燃速告警与告警疲劳治理。',
  en: 'Alertmanager grouping and routing, inhibition versus silence, SLO error-budget burn rates, fatigue metrics and postmortem loops.',
};
lesson.keywords = ['分组路由', '抑制与静默', '错误预算', '多窗口燃速', '告警疲劳'];
lesson.file = 'assets/content/devops_alerting_slo.md';
lesson.quiz = quiz;

fs.writeFileSync(
  'F:/app/new_devops_monitoring_alert.json',
  JSON.stringify(lesson, null, 2) + '\n',
  'utf8',
);

const CAND = JSON.parse(JSON.stringify(MANIFEST));
for (const c of CAND.categories)
  for (let i = 0; i < c.lessons.length; i++)
    if (c.lessons[i].id === LESSON_ID) c.lessons[i] = lesson;
fs.writeFileSync(
  'F:/app/manifest_devops_monitoring_alert_candidate.json',
  JSON.stringify(CAND, null, 2),
  'utf8',
);

console.log('written. kept fields:', [
  'id', 'difficulty', 'order', 'minutes', 'prerequisites', 'related', 'code_quiz', 'lab',
].filter((k) => k in lesson).join(','));
console.log('title.zh:', lesson.title.zh, '| has 实战/项目:', /实战|项目/.test(lesson.title.zh));
console.log('quiz size:', lesson.quiz.length, '| types:', lesson.quiz.map((q) => q.type || 'single').join(','));
