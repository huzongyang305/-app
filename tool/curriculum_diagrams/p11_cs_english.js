// P11 计算机专业英语课程配图数据。
// 这组图以英文术语与中文解释并排为主，文字密度高，统一压到 900px、WebP quality 60。
const diagrams = {
  cs_english_overview: {
    image: 'diagram_cs_english_word_formation.webp',
    alt: '英语术语的三条生产线：派生、复合与缩略',
    title: '科技术语的三条生产线',
    type: 'tree',
    root: {
      text: '术语来源',
      children: [
        {
          text: '派生',
          children: [
            { text: '词根 serial' },
            { text: '前缀 de-' },
            { text: '后缀 -ization' },
          ],
        },
        {
          text: '复合',
          children: [
            { text: 'read-only' },
            { text: 'breakpoint' },
            { text: 'write-back' },
          ],
        },
        {
          text: '缩略',
          children: [
            { text: 'RAM 读成词' },
            { text: 'HTTP 念字母' },
            { text: 'ACID 需还原' },
          ],
        },
      ],
    },
    notes: ['先定方向与词性，再核对词根含义', '缩写一律先还原全称再理解'],
    caption: '同一个生词绝大多数能被拆成这三条线之一，认零件比背整词省力得多。',
  },
  cs_english_hardware: {
    image: 'diagram_cs_english_hardware_terms.webp',
    alt: '硬件文献词汇按出处场景分层的矩阵',
    title: '硬件术语的三类出处',
    type: 'grid',
    rows: 3,
    cols: 3,
    rowLabels: ['教材与论文', '数据手册', '编译器与工具链'],
    colLabels: ['高频词', '典型搭配', '中文易错译法'],
    cells: [
      { r: 0, c: 0, text: 'latency / throughput' },
      { r: 0, c: 1, text: 'reduce latency by 30%' },
      { r: 0, c: 2, text: 'latency 是时延不是带宽' },
      { r: 1, c: 0, text: 'pinout / datasheet' },
      { r: 1, c: 1, text: 'absolute maximum ratings' },
      { r: 1, c: 2, text: 'ratings 是额定值不是评分' },
      { r: 2, c: 0, text: 'pipelining / speculation' },
      { r: 2, c: 1, text: 'branch misprediction penalty' },
      { r: 2, c: 2, text: 'penalty 是代价不是惩罚' },
    ],
    notes: ['读数据手册先看 section 标题，再看表格列名'],
    caption: '同一批词在三类文本里的搭配不同，先认出文本类型再决定翻译策略。',
  },
  cs_english_os_software: {
    image: 'diagram_cs_english_os_terms_flow.webp',
    alt: '从需求到发布的软件工程术语链',
    title: '软件工程文档的术语链',
    type: 'flow',
    steps: [
      { title: 'requirement', desc: '需求：shall 句式给出可验证承诺' },
      { title: 'design / spec', desc: '设计：interface、module、coupling' },
      { title: 'implement', desc: '实现：refactor、dependency、mock' },
      { title: 'verify', desc: '验证：regression、coverage、flaky' },
      { title: 'release', desc: '发布：rollback、canary、churn' },
    ],
    caption: '把术语挂到流程节点上记忆，比按字母表背单词更容易在读写时取出。',
  },
  cs_english_network_web: {
    image: 'diagram_cs_english_http_exchange.webp',
    alt: '浏览器与服务器之间的 HTTP 报文交互',
    title: '一次 HTTP 交换里的英文',
    type: 'sequence',
    actors: ['客户端 UA', '网关 / 服务器', '日志与文档'],
    messages: [
      { from: 0, to: 1, label: 'GET /api/v1/items HTTP/1.1' },
      { from: 1, to: 1, label: 'Host / User-Agent 解析' },
      { from: 1, to: 0, label: 'HTTP/1.1 200 OK + ETag' },
      { from: 0, to: 1, label: 'If-None-Match 条件请求' },
      { from: 1, to: 2, label: 'status 499 / latency 记录' },
    ],
    caption: '报文行、首部字段名和日志列名是网络英语的三块地基，读三遍就能记住。',
  },
  cs_english_db_bigdata: {
    image: 'diagram_cs_english_data_stack.webp',
    alt: '数据系统分层与每层的英文术语',
    title: '数据栈的分层术语',
    type: 'layers',
    layers: [
      { title: 'OLTP 事务层', desc: 'ACID、isolation level、deadlock' },
      { title: '存储与索引层', desc: 'tablespace、B-tree、sharding' },
      { title: '批处理层', desc: 'partition、shuffle、checkpoint' },
      { title: '流处理层', desc: 'watermark、exactly-once、lag' },
      { title: '分析与治理层', desc: 'lineage、schema drift、data quality' },
    ],
    widths: [0.72, 0.82, 0.9, 1, 0.94],
    caption: '每一层的术语都带有各自的动词，读到 shuffle 就该意识到进入了批处理语境。',
  },
  cs_english_ai_ml: {
    image: 'diagram_cs_english_ml_paper_phrases.webp',
    alt: '传统机器学习与深度学习论文措辞对比',
    title: '两类论文摘要的措辞差异',
    type: 'compare',
    columns: [
      {
        title: '传统机器学习',
        items: [
          'feature engineering 特征工程',
          'cross-validation 交叉验证',
          'hyperparameter tuning 调参',
          'ablation study 消融实验',
          'outperforms the baseline',
        ],
      },
      {
        title: '深度学习与大模型',
        items: [
          'pre-train then fine-tune',
          'zero-shot / few-shot',
          'token, embedding, context window',
          'hallucination, alignment',
          'compute-optimal scaling',
        ],
      },
    ],
    notes: ['审稿意见常出现 reproducible、ablation、significance'],
    caption: '方法段动词决定技术动作：pre-train 是全量训练，fine-tune 是轻量再训练。',
  },
  cs_english_reading_strategy: {
    image: 'diagram_cs_english_sentence_parsing.webp',
    alt: '长难句拆解的五个步骤',
    title: '长难句拆解五步法',
    type: 'flow',
    direction: 'vertical',
    steps: [
      { title: '第一步 找谓语', desc: '一个句子只有一个主干谓语' },
      { title: '第二步 剥从句', desc: 'which / that / what 括起来' },
      { title: '第三步 拎分词', desc: 'Measured on ... 是状语不是主语' },
      { title: '第四步 配对连接词', desc: 'whereas、albeit、thereby 定逻辑' },
      { title: '第五步 重组中文', desc: '结论提前、原因后置、长定语拆短' },
    ],
    caption: '顺序固定、每步只做一件事，40 词的考研句子也会在两步之内现出主干。',
  },
  cs_english_tech_writing: {
    image: 'diagram_cs_english_writing_contrast.webp',
    alt: '弱技术写作与强技术写作的对照',
    title: 'README、注释与 Commit 的写法对照',
    type: 'compare',
    columns: [
      {
        title: '读起来费劲的写法',
        items: [
          'This function is used for processing data.',
          'fix bug',
          'TODO: improve this part later',
          'Dear sir, please help me to solve it.',
          'It works well and is very fast.',
        ],
      },
      {
        title: '可执行的写法',
        items: [
          'Parses a CSV row; returns null on malformed input.',
          'fix(parser): handle CRLF line endings in CSV rows',
          'TODO(#482): cache parsed rows to avoid re-parse',
          'Steps to reproduce: 1) run 2) observe 3) expected',
          'Reduces p99 latency from 180 ms to 45 ms.',
        ],
      },
    ],
    notes: ['主语写动作发出者，动词写及物动作，数字写口径'],
    caption: '技术写作的标准不是漂亮，而是让读者不用再问第二个问题。',
  },
};

module.exports = Object.fromEntries(
  Object.entries(diagrams).map(([id, def]) => [
    id,
    { width: 900, quality: 60, ...def },
  ]),
);
