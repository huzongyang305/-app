// P13 计算机专业英语第二批（文献精读 / 论文写作 / 文档与面试）课程配图数据。
// 写法照 p12_ncre_b.js：键是 lesson id，值给出 image/alt/title/版式与说明。
// APK 体积预算紧，统一 width 900、quality 60，每课 1 张。
const diagrams = {
  cs_english_ai_ml: {
    image: 'diagram_cs_english_ai_ml.webp',
    alt: 'AI 论文四段式的英文信号词与对应读法',
    title: '论文四段推进：信号词、句法与图表',
    type: 'grid',
    rows: 4,
    cols: 3,
    rowLabels: ['Abstract', 'Introduction', 'Method', 'Evaluation'],
    colLabels: ['英文信号词', '它在说什么', '易误读之处'],
    cells: [
      { r: 0, c: 0, text: 'we propose / state of the art' },
      { r: 0, c: 1, text: '一句贡献加一句结论' },
      { r: 0, c: 2, text: '把 propose 读成转述他人' },
      { r: 1, c: 0, text: 'however / remains an open problem' },
      { r: 1, c: 1, text: '前人不足即研究缺口' },
      { r: 1, c: 2, text: '忽略 however 后的转折' },
      { r: 2, c: 0, text: 'as shown in Figure 2 / consists of' },
      { r: 2, c: 1, text: '模块拆解与数据流' },
      { r: 2, c: 2, text: '分词后置定语当谓语读' },
      { r: 3, c: 0, text: 'outperforms by / ablation study' },
      { r: 3, c: 1, text: '对照基线的量化增益' },
      { r: 3, c: 2, text: '把误差棒读成性能差距' },
    ],
    notes: ['先定位落在哪一段，再决定精读还是扫读', '数字一律带着口径读：数据集、指标、随机种子'],
    caption: '读 AI 论文靠三件事：认出信号词、拆长短语、把图表的坐标与误差棒读对。',
  },
  cs_english_paper_writing: {
    image: 'diagram_cs_english_paper_writing.webp',
    alt: '中式英文与地道英文在四类句子上的对照',
    title: '写作与审稿回复：四组句式对照',
    type: 'compare',
    columns: [
      {
        title: '直译腔写法',
        items: [
          'do the optimization',
          'make the performance be improved',
          'In our experiment, we will get 92%',
          'a fewer number of errors',
          'less GPU-hours',
        ],
      },
      {
        title: '动词化改写',
        items: [
          'We optimized the system',
          'throughput improved by 18%',
          'We trained 200 epochs and observed',
          'fewer failed runs',
          'fewer GPU-hours',
        ],
      },
      {
        title: 'Rebuttal 三步',
        items: [
          'Thank you for pointing this out',
          'We agree / We clarify',
          'added in Section 4',
          'left to future work',
          '表格里给出行号与页码',
        ],
      },
    ],
    notes: ['名词化是直译腔的第一征兆', '礼貌不等于让步：承认关切，不承认结论'],
    caption: '同一层意思，英文写作有三处要判断：时态、动词化、以及审稿回复的语气。',
  },
  cs_english_docs_interview: {
    image: 'diagram_cs_english_docs_interview.webp',
    alt: '从 README 到英文面试的六个环节',
    title: '文档、提交信息与面试：一条交付链',
    type: 'flow',
    steps: [
      { title: 'README', desc: '章节惯例与祈使句' },
      { title: 'API doc', desc: 'must / may 标强度' },
      { title: 'Commit', desc: 'add 而非 added' },
      { title: 'Error & log', desc: '先抓名词短语' },
      { title: 'Self-intro', desc: '30 秒定位自己' },
      { title: 'STAR', desc: '情境任务行动结果' },
    ],
    notes: ['文档写「怎么做」，面试讲「做成过什么」，两者句式不同不可混用'],
    caption: '从仓库里的英文到嘴里的英文，动词选择始终是同一件事：说清谁做了什么、结果如何。',
  },
};

module.exports = Object.fromEntries(
  Object.entries(diagrams).map(([id, def]) => [
    id,
    { width: 900, quality: 60, ...def },
  ]),
);
