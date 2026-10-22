const fs = require('fs');

const manifestPath = 'F:/app/assets/content/manifest.json';
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

// 找到离散数学分类
const dmCategory = manifest.categories.find(c => c.id === 'discrete_mathematics');
if (!dmCategory) {
  console.log('❌ 未找到 discrete_mathematics 分类');
  process.exit(1);
}

// 新增的课程
const newLessons = [
  {
    id: 'discrete_math_set_theory',
    title: { zh: '集合论基础', en: 'Set Theory Fundamentals' },
    summary: { zh: '掌握集合概念、运算和恒等式证明。', en: 'Master set concepts, operations and identity proofs.' },
    file: 'assets/content/discrete_math_set_theory.md',
    minutes: 45,
    keywords: ['集合论', '幂集', '集合运算', '德摩根律'],
    difficulty: '进阶',
    order: 1,
    quiz: []
  },
  {
    id: 'discrete_math_relations_functions',
    title: { zh: '关系与函数', en: 'Relations and Functions' },
    summary: { zh: '理解二元关系性质、等价关系、函数类型与复合。', en: 'Understand relation properties, equivalence relations, function types and composition.' },
    file: 'assets/content/discrete_math_relations_functions.md',
    minutes: 50,
    keywords: ['关系', '函数', '等价关系', '双射'],
    difficulty: '进阶',
    order: 2,
    quiz: []
  },
  {
    id: 'discrete_math_graph_theory',
    title: { zh: '图论基础', en: 'Graph Theory Fundamentals' },
    summary: { zh: '学习图的定义、路径、树、着色和最短路径算法。', en: 'Learn graph definitions, paths, trees, coloring and shortest path algorithms.' },
    file: 'assets/content/discrete_math_graph_theory.md',
    minutes: 50,
    keywords: ['图论', '树', '欧拉路径', 'Dijkstra'],
    difficulty: '进阶',
    order: 3,
    quiz: []
  },
  {
    id: 'discrete_math_combinatorics',
    title: { zh: '组合数学', en: 'Combinatorics' },
    summary: { zh: '掌握计数原理、排列组合、鸽巢原理和容斥原理。', en: 'Master counting principles, permutations, combinations, pigeonhole and inclusion-exclusion.' },
    file: 'assets/content/discrete_math_combinatorics.md',
    minutes: 45,
    keywords: ['组合数学', '排列', '组合', '鸽巢原理'],
    difficulty: '进阶',
    order: 4,
    quiz: []
  },
  {
    id: 'discrete_math_logic',
    title: { zh: '命题逻辑与谓词逻辑', en: 'Propositional and Predicate Logic' },
    summary: { zh: '理解命题演算、真值表、量词和推理规则。', en: 'Understand propositional calculus, truth tables, quantifiers and inference rules.' },
    file: 'assets/content/discrete_math_logic.md',
    minutes: 50,
    keywords: ['逻辑', '命题', '量词', '推理'],
    difficulty: '进阶',
    order: 5,
    quiz: []
  }
];

// 保留原有课程，调整order
const existingLessons = dmCategory.lessons.map((l, i) => ({ ...l, order: 0 }));
dmCategory.lessons = [...newLessons, ...existingLessons];

// 重新编号order
dmCategory.lessons.forEach((l, i) => l.order = i);

// 保存
fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
console.log(`✅ 离散数学分类已更新：${dmCategory.lessons.length} 课`);

// 提取quiz数据
const { execSync } = require('child_process');

// 为新增课程提取quiz
for (const lesson of newLessons) {
  const filePath = `F:/app/assets/content/${lesson.file.replace('assets/content/', '')}`;
  if (!fs.existsSync(filePath)) {
    console.log(`⚠️ 文件不存在: ${filePath}`);
    continue;
  }
  
  const content = fs.readFileSync(filePath, 'utf8');
  const quiz = [];
  const questionBlocks = content.split(/### 问题\d+/).slice(1);
  
  for (const block of questionBlocks) {
    const lines = block.split('\n');
    let questionText = [];
    let codeBlock = null;
    let codeLanguage = null;
    let inCodeBlock = false;
    let codeLines = [];
    let foundOptions = false;
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (line.trim().startsWith('```') && !inCodeBlock) {
        inCodeBlock = true;
        codeLanguage = line.trim().replace('```', '').trim() || 'text';
        codeLines = [];
        continue;
      }
      if (line.trim() === '```' && inCodeBlock) {
        inCodeBlock = false;
        codeBlock = codeLines.join('\n');
        continue;
      }
      if (inCodeBlock) { codeLines.push(line); continue; }
      if (line.match(/^[A-D]\./)) { foundOptions = true; break; }
      if (!foundOptions && line.trim() && !line.startsWith('**正确答案')) {
        questionText.push(line.trim());
      }
    }
    
    let question = questionText.join(' ').trim();
    const options = [];
    const optionRegex = /^([A-D])\.\s*(.+)$/gm;
    let match;
    while ((match = optionRegex.exec(block)) !== null) {
      options.push(match[2].trim());
    }
    const answerMatch = block.match(/\*\*正确答案：([A-D])\*\*/);
    let answerIndex = -1;
    if (answerMatch) {
      answerIndex = answerMatch[1].charCodeAt(0) - 65;
    }
    const explanationMatch = block.match(/\*\*详细解释：\*\*\s*([\s\S]+?)(?=\n### 问题|\n## |\n---|\s*$)/);
    let explanation = '';
    if (explanationMatch) {
      explanation = explanationMatch[1].trim();
    }
    
    if (question && options.length === 4 && answerIndex >= 0) {
      const quizItem = { type: codeBlock ? 'code' : 'single', question, options, answer: answerIndex, explanation };
      if (codeBlock) { quizItem.code = codeBlock; quizItem.language = codeLanguage; }
      quiz.push(quizItem);
    }
  }
  
  // 更新manifest中的quiz
  const cat = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  const dm = cat.categories.find(c => c.id === 'discrete_mathematics');
  const lessonEntry = dm.lessons.find(l => l.id === lesson.id);
  if (lessonEntry) {
    lessonEntry.quiz = quiz;
    console.log(`✅ ${lesson.id}: ${quiz.length} 题`);
  }
  fs.writeFileSync(manifestPath, JSON.stringify(cat, null, 2), 'utf8');
}

console.log('\n✅ 离散数学课程quiz数据已提取并保存');
