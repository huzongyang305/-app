const fs = require('fs');

const manifestPath = 'F:/app/assets/content/manifest.json';
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

function extractQuizFromMarkdown(filePath) {
  if (!fs.existsSync(filePath)) return [];
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
    if (answerMatch) answerIndex = answerMatch[1].charCodeAt(0) - 65;
    const explanationMatch = block.match(/\*\*详细解释：\*\*\s*([\s\S]+?)(?=\n### 问题|\n## |\n---|\s*$)/);
    let explanation = explanationMatch ? explanationMatch[1].trim() : '';
    
    if (question && options.length === 4 && answerIndex >= 0) {
      const quizItem = { type: codeBlock ? 'code' : 'single', question, options, answer: answerIndex, explanation };
      if (codeBlock) { quizItem.code = codeBlock; quizItem.language = codeLanguage; }
      quiz.push(quizItem);
    }
  }
  return quiz;
}

// 找出缺少quiz的课程并提取
let fixed = 0;
for (const cat of manifest.categories) {
  for (const lesson of cat.lessons) {
    if (!lesson.quiz || lesson.quiz.length === 0) {
      const filePath = 'F:/app/' + lesson.file;
      const quiz = extractQuizFromMarkdown(filePath);
      if (quiz.length > 0) {
        lesson.quiz = quiz;
        fixed++;
        console.log(`✅ ${cat.id}/${lesson.id}: ${quiz.length} 题`);
      } else {
        console.log(`⚠️ ${cat.id}/${lesson.id}: 无quiz数据`);
      }
    }
  }
}

fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
console.log(`\n✅ 修复了 ${fixed} 门课程的quiz数据`);
