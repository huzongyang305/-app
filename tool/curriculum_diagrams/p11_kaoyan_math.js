// P11 考研数学（数学一 / 数学二 / 数学三）课程配图数据。
// 结构照抄 p10_co.js：键为 lesson_id，值含 image / alt / title / type 与内容字段。
// 数学类配图文字密度中等，统一收到 900px、WebP 质量 60，控制 APK 体积。
const diagrams = {
  kaoyan_math_overview: {
    image: 'diagram_kaoyan_math_overview.webp',
    alt: '考研数学三卷种的题型分值与复习三轮安排',
    title: '考研数学：卷种、题型与三轮复习',
    type: 'grid',
    rows: 3,
    cols: 3,
    rowLabels: ['数学一', '数学二', '数学三'],
    colLabels: ['内容占比', '不考或弱化', '三轮主线'],
    cells: [
      { r: 0, c: 0, text: '高数 60% · 线代 20% · 概率 20%' },
      { r: 0, c: 1, text: '范围最全，级数与曲面积分是难点' },
      { r: 0, c: 2, text: '基础→强化→冲刺，真题套卷收尾' },
      { r: 1, c: 0, text: '高数 80% · 线代 20%' },
      { r: 1, c: 1, text: '不考级数、概率、三重与曲线曲面积分' },
      { r: 1, c: 2, text: '把一元微积分与中值定理练到熟' },
      { r: 2, c: 0, text: '高数 60% · 线代 20% · 概率 20%' },
      { r: 2, c: 1, text: '不考空间解析几何与曲面积分，加差分方程' },
      { r: 2, c: 2, text: '经济应用题与概率计算并重' },
    ],
    notes: ['三种卷子都是 150 分 · 180 分钟 · 10 选择 + 6 填空 + 6 解答'],
    caption: '先确认卷种，再按占比分配时间：数二抓高数，数一补级数与曲面积分，数三补概率与经济应用。',
  },
  kaoyan_math_limit_continuity: {
    image: 'diagram_kaoyan_math_limit_continuity.webp',
    title: '求极限：先定型，再选工具',
    alt: '七种未定式到极限工具的选型流程',
    type: 'flow',
    steps: [
      { title: '定型', desc: '判断属于 0/0 还是 ∞/∞' },
      { title: '化简', desc: '因式分解、有理化、等价代换' },
      { title: '洛必达', desc: '化简后再求导，别硬算' },
      { title: '泰勒', desc: '加减法保留到同阶非零项' },
      { title: '收口', desc: '检验是否存在、是否需夹逼' },
    ],
    notes: ['1^∞ 型先取对数或用 e^{lim(u-1)v}；∞-∞ 先通分或提主部'],
    caption: '极限题的分差多半出在定型与工具选择，不在计算本身。',
  },
  kaoyan_math_matrix: {
    image: 'diagram_kaoyan_math_matrix.webp',
    alt: '行列式、矩阵、初等变换与秩的支撑关系',
    title: '线代计算的四层地基',
    type: 'layers',
    layers: [
      { title: '行列式', desc: '判定可逆、克拉默、特征方程', fill: '#eef4ff', stroke: '#6c8ff8' },
      { title: '矩阵运算', desc: '乘法不交换，转置与分块', fill: '#e8f2ff', stroke: '#6c8ff8' },
      { title: '初等变换', desc: '行变换保行秩，等价标准形', fill: '#e6f7f1', stroke: '#3fae8a' },
      { title: '秩与可逆', desc: 'r(A)=n ⇔ |A|≠0 ⇔ A 可逆', fill: '#fff4e6', stroke: '#e6a23c' },
    ],
    widths: [0.78, 0.86, 0.94, 1],
    caption: '行列式给结论、矩阵给语言、初等变换给手段、秩把三者串成一条判据。',
  },
  kaoyan_math_single_diff: {
    image: 'diagram_kaoyan_math_single_diff.webp',
    alt: '中值定理从条件到辅助函数的构造路径',
    title: '中值定理证明题：构造辅助函数',
    type: 'flow',
    steps: [
      { title: '读结论', desc: '把 ξ 换成 x 写出等式' },
      { title: '移项', desc: '整理成 F′(x)=0 的形状' },
      { title: '还原', desc: '积分回去得到 F(x)' },
      { title: '验条件', desc: '端点相等、连续、可导' },
      { title: '用定理', desc: '罗尔或拉格朗日收尾' },
    ],
    notes: ['含 k·f 时先想 e^{kx}f(x)；含 f/x 时先想 f(x)/x'],
    caption: '证明存在 ξ 的题，九成工作量在“猜出 F(x)”，验证只是走流程。',
  },
  kaoyan_math_integral: {
    image: 'diagram_kaoyan_math_integral.webp',
    alt: '不定积分、定积分与几何应用的方法分支',
    title: '积分计算的三条分支',
    type: 'tree',
    root: {
      text: '遇到积分题',
      children: [
        {
          text: '不定积分',
          children: [
            { text: '换元：根式与三角' },
            { text: '分部：反对幂指三' },
            { text: '有理式：部分分式' },
          ],
        },
        {
          text: '定积分',
          children: [
            { text: '奇偶与周期化简' },
            { text: '变限积分求导' },
            { text: '反常积分判敛' },
          ],
        },
        {
          text: '应用',
          children: [
            { text: '面积与旋转体积' },
            { text: '弧长与形心（数一）' },
            { text: '边际与弹性（数三）' },
          ],
        },
      ],
    },
    notes: ['先问有没有对称性，再动手算，能省一半时间'],
    caption: '定积分先用性质化简，再谈计算；直接硬算是最常见的失分方式。',
  },
  kaoyan_math_multivar_diff: {
    image: 'diagram_kaoyan_math_multivar_diff.webp',
    alt: '连续、偏导存在、可微三者之间的强弱关系',
    title: '多元微分的三个条件谁强谁弱',
    type: 'compare',
    columns: [
      {
        title: '偏导存在',
        items: [
          '只沿坐标轴方向变化',
          '推不出连续',
          '推不出可微',
          '求切线斜率够用',
        ],
      },
      {
        title: '可微',
        items: [
          '增量可写成线性主部',
          '一定连续',
          '一定偏导存在',
          'dz = f_x dx + f_y dy',
        ],
      },
      {
        title: '偏导连续',
        items: [
          '可微的常用充分条件',
          '考场判可微首选',
          '定义法验证最稳',
          '极值计算的前提',
        ],
      },
    ],
    notes: ['反例 f=xy/(x²+y²) 在原点偏导都存在却不可微'],
    caption: '「偏导存在」比想象中弱，「偏导连续」才是可微的可靠通行证。',
  },
  kaoyan_math_multiple_integral: {
    image: 'diagram_kaoyan_math_multiple_integral.webp',
    alt: '从二重积分到曲线曲面积分的升维路线',
    title: '重积分与曲线曲面积分：升维路线',
    type: 'timeline',
    total: 10,
    tasks: [
      { label: '二重积分', start: 0, duration: 3, desc: '直角与极坐标' },
      { label: '对称性与换元', start: 2, duration: 2, desc: '雅可比' },
      { label: '三重积分', start: 4, duration: 2, desc: '柱面与球面（数一）' },
      { label: '曲线积分', start: 5, duration: 3, desc: '一型二型与格林' },
      { label: '曲面积分', start: 7, duration: 3, desc: '高斯与斯托克斯' },
    ],
    notes: ['数二只考到二重积分；数三只考二重积分；三重与曲线曲面积分数一独有'],
    caption: '先练稳二重积分的对称性与换元，再谈升维，否则三重积分只会照抄公式。',
  },
  kaoyan_math_ode: {
    image: 'diagram_kaoyan_math_ode.webp',
    alt: '常微分方程按类型选择的识别流程',
    title: '微分方程：先识别类型再选方法',
    type: 'flow',
    steps: [
      { title: '降阶？', desc: '缺 y 或缺 x 可降一阶' },
      { title: '一阶型', desc: '可分离、齐次、线性公式' },
      { title: '常系数', desc: '特征方程写齐次通解' },
      { title: '定特解', desc: '按自由项形式待定系数' },
      { title: '代初值', desc: '用条件定常数并回代检验' },
    ],
    notes: ['自由项与齐次解同形时特解要乘 x 的相应幂次'],
    caption: '方程类型决定解法顺序；先分类再动笔，比反复试算快得多。',
  },
  kaoyan_math_series: {
    image: 'diagram_kaoyan_math_series.webp',
    alt: '数项级数与幂级数的判别与展开流程',
    title: '无穷级数：判敛、求和与展开',
    type: 'cycle',
    nodes: [
      { title: '先看通项', desc: '一般项不趋于 0 必发散' },
      { title: '正项判敛', desc: '比较、比值、根值' },
      { title: '交错级数', desc: '莱布尼茨条件收敛' },
      { title: '绝对收敛', desc: '绝对收敛必收敛' },
      { title: '幂级数', desc: '求收敛半径与端点' },
      { title: '求与展开', desc: '逐项求导与积分' },
    ],
    caption: '判敛与求和是同一条链上的两段：级数性质先定收敛域，再谈逐项运算。',
  },
  kaoyan_math_eigen_probability: {
    image: 'diagram_kaoyan_math_eigen_probability.webp',
    alt: '特征值对角化与概率统计高频题的对照',
    title: '线代后半段与概率高频题对照',
    type: 'compare',
    columns: [
      {
        title: '特征与二次型',
        items: [
          'Aα=λα，α 非零',
          '可对角化需 n 个无关特征向量',
          '实对称必正交对角化',
          '正定 ⇔ 特征值全正',
          '二次型配方法与正交法',
        ],
      },
      {
        title: '概率统计高频',
        items: [
          '分布函数先定型再求导',
          'X+Y 用卷积或分布函数法',
          'max 与 min 分别讨论',
          '期望方差按定义硬算',
          '最大似然先取对数再求导',
        ],
      },
    ],
    notes: ['数二不考概率统计；数一与数三概率统计范围基本一致，统计部分要求略有差异'],
    caption: '这两块都是“流程题”：特征值按四步走，概率按分布-数字特征-估计三层走。',
  },
};

module.exports = Object.fromEntries(
  Object.entries(diagrams).map(([id, def]) => [
    id,
    { width: 900, quality: 60, ...def },
  ]),
);
