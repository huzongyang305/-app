const fs = require('fs');

const manifestPath = 'F:/app/assets/content/manifest.json';
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

// 1. 修复 Java Web开发顺序
const javaweb = manifest.categories.find(c => c.id === 'javaweb');
if (javaweb) {
  const order = [
    'java_servlet_jsp',           // 入门
    'java_spring_boot_intro',     // 入门
    'java_spring_mvc',            // 进阶
    'java_spring_security',       // 进阶
    'java_restful_api',           // 进阶
    'java_data_access',           // 进阶
    'java_microservices',         // 高级
    'java_testing',               // 进阶
    'java_performance_monitoring',// 高级
    'java_deployment',            // 高级
  ];
  
  const lessonMap = new Map(javaweb.lessons.map(l => [l.id, l]));
  const reordered = order
    .filter(id => lessonMap.has(id))
    .map((id, i) => ({ ...lessonMap.get(id), order: i }));
  
  // 添加剩余的课程
  javaweb.lessons.forEach(l => {
    if (!order.includes(l.id)) {
      reordered.push({ ...l, order: reordered.length });
    }
  });
  
  javaweb.lessons = reordered;
  console.log('✅ Java Web开发：已重新排序');
}

// 2. 修复机器学习实战顺序
const ml = manifest.categories.find(c => c.id === 'ml_practice');
if (ml) {
  const order = [
    'ml_tensorflow_pytorch_intro',              // 入门
    'ml_data_preprocessing_feature_engineering',// 入门
    'ml_computer_vision',                       // 进阶
    'ml_natural_language_processing',           // 进阶
    'ml_recommendation_systems',                // 进阶
    'ml_time_series_prediction',                // 进阶
    'ml_model_evaluation_hyperparameter_tuning',// 进阶
    'ml_model_deployment_mlops',                // 进阶
  ];
  
  const lessonMap = new Map(ml.lessons.map(l => [l.id, l]));
  const reordered = order
    .filter(id => lessonMap.has(id))
    .map((id, i) => ({ ...lessonMap.get(id), order: i }));
  
  ml.lessons.forEach(l => {
    if (!order.includes(l.id)) {
      reordered.push({ ...l, order: reordered.length });
    }
  });
  
  ml.lessons = reordered;
  console.log('✅ 机器学习实战：已重新排序');
}

// 3. 修复前端框架专题顺序
const frontend = manifest.categories.find(c => c.id === 'frontend_frameworks');
if (frontend) {
  const order = [
    'frontend_react_hooks',           // 入门
    'frontend_vue_composition',       // 入门
    'frontend_angular_basics',        // 入门
    'frontend_svelte_reactive',       // 入门
    'frontend_state_management',      // 进阶
    'frontend_nextjs_ssr',            // 进阶
    'frontend_performance_optimization', // 进阶
    'frontend_framework_comparison',  // 进阶
  ];
  
  const lessonMap = new Map(frontend.lessons.map(l => [l.id, l]));
  const reordered = order
    .filter(id => lessonMap.has(id))
    .map((id, i) => ({ ...lessonMap.get(id), order: i }));
  
  frontend.lessons.forEach(l => {
    if (!order.includes(l.id)) {
      reordered.push({ ...l, order: reordered.length });
    }
  });
  
  frontend.lessons = reordered;
  console.log('✅ 前端框架专题：已重新排序');
}

// 4. 修复后端开发顺序
const backend = manifest.categories.find(c => c.id === 'backend_development');
if (backend) {
  const order = [
    'backend_restful_api',            // 入门
    'backend_nodejs_express',         // 入门
    'backend_fastapi_async',          // 进阶
    'backend_gin_echo',               // 进阶
    'backend_database_integration',   // 进阶
    'backend_auth_jwt_oauth',         // 进阶
    'backend_graphql_apollo',         // 进阶
    'backend_microservices_patterns', // 高级
  ];
  
  const lessonMap = new Map(backend.lessons.map(l => [l.id, l]));
  const reordered = order
    .filter(id => lessonMap.has(id))
    .map((id, i) => ({ ...lessonMap.get(id), order: i }));
  
  backend.lessons.forEach(l => {
    if (!order.includes(l.id)) {
      reordered.push({ ...l, order: reordered.length });
    }
  });
  
  backend.lessons = reordered;
  console.log('✅ 后端开发：已重新排序');
}

// 保存
fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
console.log('\n✅ 所有课程顺序已修复并保存');
