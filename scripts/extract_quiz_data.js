const fs = require('fs');
const path = require('path');

function extractQuizFromMarkdown(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const quiz = [];
  
  // 匹配每个问题块
  const questionBlocks = content.split(/### 问题\d+/).slice(1);
  
  for (let blockIndex = 0; blockIndex < questionBlocks.length; blockIndex++) {
    const block = questionBlocks[blockIndex];
    const lines = block.split('\n');
    
    // 提取问题文本和代码块
    let questionText = [];
    let codeBlock = null;
    let codeLanguage = null;
    let inCodeBlock = false;
    let codeLines = [];
    let foundOptions = false;
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      
      // 检测代码块开始
      if (line.trim().startsWith('```') && !inCodeBlock) {
        inCodeBlock = true;
        codeLanguage = line.trim().replace('```', '').trim() || 'text';
        codeLines = [];
        continue;
      }
      
      // 检测代码块结束
      if (line.trim() === '```' && inCodeBlock) {
        inCodeBlock = false;
        codeBlock = codeLines.join('\n');
        continue;
      }
      
      // 在代码块内
      if (inCodeBlock) {
        codeLines.push(line);
        continue;
      }
      
      // 检测选项开始（A. B. C. D.）
      if (line.match(/^[A-D]\./)) {
        foundOptions = true;
        break;
      }
      
      // 收集问题文本
      if (!foundOptions && line.trim() && !line.startsWith('**正确答案')) {
        questionText.push(line.trim());
      }
    }
    
    // 构建问题文本
    let question = questionText.join(' ').trim();
    
    // 提取选项
    const options = [];
    const optionRegex = /^([A-D])\.\s*(.+)$/gm;
    let match;
    while ((match = optionRegex.exec(block)) !== null) {
      options.push(match[2].trim());
    }
    
    // 提取正确答案
    const answerMatch = block.match(/\*\*正确答案：([A-D])\*\*/);
    let answerIndex = -1;
    if (answerMatch) {
      const answerLabel = answerMatch[1];
      answerIndex = answerLabel.charCodeAt(0) - 65; // A=0, B=1, C=2, D=3
    }
    
    // 提取解释
    const explanationMatch = block.match(/\*\*详细解释：\*\*\s*([\s\S]+?)(?=\n### 问题|\n## |\n---|\s*$)/);
    let explanation = '';
    if (explanationMatch) {
      explanation = explanationMatch[1].trim();
    }
    
    // 构建quiz条目
    if (question && options.length === 4 && answerIndex >= 0) {
      const quizItem = {
        type: codeBlock ? 'code' : 'single',
        question: question,
        options: options,
        answer: answerIndex,
        explanation: explanation
      };
      
      if (codeBlock) {
        quizItem.code = codeBlock;
        quizItem.language = codeLanguage;
      }
      
      quiz.push(quizItem);
    }
  }
  
  return quiz;
}

// 定义所有需要处理的课程文件
const courses = [
  // 前端框架专题
  'frontend_react_hooks',
  'frontend_vue_composition',
  'frontend_angular_basics',
  'frontend_nextjs_ssr',
  'frontend_svelte_reactive',
  'frontend_framework_comparison',
  'frontend_state_management',
  'frontend_performance_optimization',
  
  // 后端开发
  'backend_nodejs_express',
  'backend_fastapi_async',
  'backend_gin_echo',
  'backend_restful_api',
  'backend_graphql_apollo',
  'backend_database_integration',
  'backend_auth_jwt_oauth',
  'backend_microservices_patterns',
  
  // 机器学习实战
  'ml_tensorflow_pytorch_intro',
  'ml_computer_vision',
  'ml_natural_language_processing',
  'ml_recommendation_systems',
  'ml_time_series_prediction',
  'ml_model_deployment_mlops',
  'ml_data_preprocessing_feature_engineering',
  'ml_model_evaluation_hyperparameter_tuning',
  
  // 移动开发进阶
  'mobile_flutter_advanced',
  'mobile_swiftui_complete',
  'mobile_jetpack_compose_advanced',
  'mobile_react_native_deep',
  'mobile_cross_platform_comparison',
  'mobile_performance_optimization',
  'mobile_offline_first_architecture',
  'mobile_security_best_practices'
];

// 读取manifest.json
const manifestPath = 'F:/app/assets/content/manifest.json';
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

// 统计信息
let totalQuizzes = 0;
let updatedLessons = 0;

// 遍历所有课程
for (const courseId of courses) {
  const filePath = `F:/app/assets/content/${courseId}.md`;
  
  if (!fs.existsSync(filePath)) {
    console.log(`⚠️  文件不存在: ${filePath}`);
    continue;
  }
  
  // 提取quiz数据
  const quiz = extractQuizFromMarkdown(filePath);
  
  if (quiz.length === 0) {
    console.log(`⚠️  未提取到quiz: ${courseId}`);
    continue;
  }
  
  // 在manifest中查找对应的lesson
  let found = false;
  for (const category of manifest.categories) {
    for (const lesson of category.lessons) {
      if (lesson.id === courseId) {
        lesson.quiz = quiz;
        found = true;
        updatedLessons++;
        totalQuizzes += quiz.length;
        console.log(`✅ ${courseId}: ${quiz.length} 题`);
        break;
      }
    }
    if (found) break;
  }
  
  if (!found) {
    console.log(`⚠️  manifest中未找到: ${courseId}`);
  }
}

// 写回manifest.json
fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');

console.log('\n==============================');
console.log(`更新完成: ${updatedLessons} 个课程, ${totalQuizzes} 道题目`);
console.log('==============================');
