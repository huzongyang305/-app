// P12 全国计算机等级二级 Python 语言程序设计课程配图数据。
// 这组图按 p11_ncre.js 的写法组织：键是 lesson_id，值给出 image/alt/title/版式与说明。
// APK 体积预算紧，统一 width 900、quality 60，每课 1 张。
const diagrams = {
  ncre_python_basics: {
    image: 'diagram_ncre_python_basics.webp',
    alt: 'Python 语法骨架、数据类型与表达式的三行九格对照',
    title: '基本语法元素与数据类型：三行九格',
    type: 'grid',
    rows: 3,
    cols: 3,
    rowLabels: ['语法骨架', '数据类型', '表达式'],
    colLabels: ['核心写法', '考查角度', '失分点'],
    cells: [
      { r: 0, c: 0, text: '缩进与 # 注释' },
      { r: 0, c: 1, text: '块由缩进划定，没有花括号' },
      { r: 0, c: 2, text: 'Tab 与空格混用' },
      { r: 1, c: 0, text: 'int float complex' },
      { r: 1, c: 1, text: 'type() 与转换函数' },
      { r: 1, c: 2, text: 'input 返回的是字符串' },
      { r: 2, c: 0, text: '/ // % **' },
      { r: 2, c: 1, text: '优先级与结合方向' },
      { r: 2, c: 2, text: '把 // 当成普通除法' },
    ],
    notes: ['保留字不能当标识符：3.7 起 35 个，3.5.3 环境为 33 个'],
    caption: '二级 Python 的选择题把这三行各考一遍：先认写法，再判类型，最后算表达式。',
  },
  ncre_python_combo_type: {
    image: 'diagram_ncre_python_combo_type.webp',
    alt: 'Python 五类组合数据类型的分类树',
    title: '组合数据类型：五个分支两条主线',
    type: 'tree',
    root: {
      text: '组合数据类型',
      children: [
        { text: '列表 list', children: [{ text: '可变，可切片' }] },
        { text: '元组 tuple', children: [{ text: '不可变，可作键' }] },
        { text: '字符串 str', children: [{ text: '索引与切片' }] },
        { text: '字典 dict', children: [{ text: '键唯一且可哈希' }] },
        { text: '集合 set', children: [{ text: '无序且不重复' }] },
      ],
    },
    notes: ['可变性与有序性是两条判断主线：能否原地改、能否按下标取'],
    caption: '大纲把组合数据分成序列、映射、集合三类，题目先问类别，再问方法名。',
  },
  ncre_python_function_file: {
    image: 'diagram_ncre_python_function_file.webp',
    alt: '从函数定义到文件读写的六个环节',
    title: '函数、异常与文件：一条执行链',
    type: 'flow',
    steps: [
      { title: '定义函数', desc: 'def 与文档字符串缩进对齐' },
      { title: '参数传递', desc: '位置、关键字、默认值' },
      { title: '返回结果', desc: '多个返回值打包成元组' },
      { title: '异常保护', desc: 'try-except-else-finally' },
      { title: '打开文件', desc: '模式 r/w/a 与编码' },
      { title: '读写关闭', desc: 'with 自动 close' },
    ],
    notes: ['二级 Python 的 60 分操作题按得分点给分，函数与文件各占一处'],
    caption: '函数解决逻辑复用，异常解决出错收场，文件解决数据进出，三者串成一次运行。',
  },
};

module.exports = Object.fromEntries(
  Object.entries(diagrams).map(([id, def]) => [
    id,
    { width: 900, quality: 60, ...def },
  ]),
);
