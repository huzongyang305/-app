// 第 16 波：把残余的 45 条「关于「X」的检索页」占位参考链接换成该主题的官方/权威文档。
// 这些行不能直接删：删掉后本课只剩 1 条可用参考资料，会触发治理审计的“至少 2 条”警告。
// 用法：node tool/content_pipeline/wave16_real_reference.js [--apply]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const DIR = 'assets/content/';

// 每个文件对应一条已核实的权威资料（链接文本，URL）。全部经 HTTP 200 验证。
const MAP = {
  'backend_auth_jwt_oauth.md': ['OAuth 2.0 授权框架（RFC 6749）', 'https://datatracker.ietf.org/doc/html/rfc6749'],
  'backend_database_integration.md': ['MongoDB 官方手册', 'https://www.mongodb.com/docs/'],
  'backend_fastapi_async.md': ['FastAPI 异步路由官方指南', 'https://fastapi.tiangolo.com/async/'],
  'backend_gin_echo.md': ['Gin Web 框架官方文档', 'https://gin-gonic.com/en/docs/'],
  'backend_graphql_apollo.md': ['Apollo Server 官方文档', 'https://www.apollographql.com/docs/apollo-server/'],
  'backend_microservices_patterns.md': ['microservices.io：API Gateway 模式', 'https://microservices.io/patterns/apigateway.html'],
  'backend_nodejs_express.md': ['Express 官方指南', 'https://expressjs.com/'],
  'backend_restful_api.md': ['OpenAPI 规范', 'https://swagger.io/specification/'],
  'devops_cicd_pipeline.md': ['Jenkins Pipeline 官方手册', 'https://www.jenkins.io/doc/book/pipeline/'],
  'devops_deployment_strategies.md': ['Martin Fowler：金丝雀发布', 'https://martinfowler.com/bliki/CanaryRelease.html'],
  'devops_docker_registry.md': ['Docker Registry 官方文档', 'https://docs.docker.com/registry/'],
  'devops_github_actions.md': ['GitHub Actions 官方文档', 'https://docs.github.com/en/actions'],
  'devops_gitops_argocd.md': ['Argo CD 官方文档', 'https://argo-cd.readthedocs.io/en/stable/'],
  'devops_logging_tracing.md': ['Jaeger 官方文档', 'https://www.jaegertracing.io/docs/2.0/'],
  'devops_monitoring.md': ['Grafana 官方文档', 'https://grafana.com/docs/grafana/latest/'],
  'devops_terraform.md': ['Terraform 官方文档', 'https://developer.hashicorp.com/terraform/docs'],
  'discrete_math_combinatorics.md': ['Discrete Mathematics（OpenMathBooks）第 3 版', 'https://discrete.openmathbooks.org/dmoi3.html'],
  'discrete_math_graph_theory.md': ['Discrete Mathematics（OpenMathBooks）图论篇', 'https://discrete.openmathbooks.org/dmoi3/sec_gt-intro.html'],
  'discrete_math_logic.md': ['斯坦福哲学百科：经典逻辑', 'https://plato.stanford.edu/entries/logic-classical/'],
  'discrete_math_relations_functions.md': ['斯坦福哲学百科：关系（Relations）', 'https://plato.stanford.edu/entries/relations/'],
  'discrete_math_set_theory.md': ['斯坦福哲学百科：集合论', 'https://plato.stanford.edu/entries/set-theory/'],
  'frontend_angular_basics.md': ['Angular 依赖注入指南', 'https://angular.cn/guide/di'],
  'frontend_framework_comparison.md': ['JS 框架基准测试（krausest/js-framework-benchmark）', 'https://krausest.github.io/js-framework-benchmark/current.html'],
  'frontend_nextjs_ssr.md': ['Next.js 官方文档', 'https://nextjs.org/docs'],
  'frontend_performance_optimization.md': ['webpack 代码分割指南', 'https://webpack.js.org/guides/code-splitting/'],
  'frontend_react_hooks.md': ['React Hooks 官方参考', 'https://react.dev/reference/react/hooks'],
  'frontend_state_management.md': ['Pinia 官方入门', 'https://pinia.vuejs.org/getting-started.html'],
  'frontend_svelte_reactive.md': ['Svelte 官方文档：响应式概览', 'https://svelte.dev/docs/svelte/overview'],
  'frontend_vue_composition.md': ['Vue 3 组合式 API 常见问题', 'https://vuejs.org/guide/extras/composition-api-faq.html'],
  'ml_computer_vision.md': ['OpenCV 官方文档', 'https://docs.opencv.org/4.x/'],
  'ml_data_preprocessing_feature_engineering.md': ['scikit-learn 预处理与特征工程', 'https://scikit-learn.org/stable/modules/preprocessing.html'],
  'ml_model_deployment_mlops.md': ['MLflow 官方文档', 'https://mlflow.org/docs/latest/'],
  'ml_model_evaluation_hyperparameter_tuning.md': ['scikit-learn 网格搜索与超参数调优', 'https://scikit-learn.org/stable/modules/grid_search.html'],
  'ml_natural_language_processing.md': ['NLTK Book（自然语言处理入门教材）', 'https://www.nltk.org/book/'],
  'ml_recommendation_systems.md': ['scikit-surprise 推荐算法库文档', 'https://surprise.readthedocs.io/en/stable/'],
  'ml_tensorflow_pytorch_intro.md': ['PyTorch 官方文档', 'https://pytorch.org/docs/stable/index.html'],
  'ml_time_series_prediction.md': ['PyTorch LSTM 接口文档', 'https://pytorch.org/docs/stable/generated/torch.nn.LSTM.html'],
  'mobile_cross_platform_comparison.md': ['Flutter 支持的平台', 'https://flutter.cn/docs/reference/supported-platforms'],
  'mobile_flutter_advanced.md': ['Flutter 动画概览', 'https://flutter.cn/docs/ui/animations'],
  'mobile_jetpack_compose_advanced.md': ['Jetpack Compose 官方文档', 'https://developer.android.google.cn/develop/ui/compose/documentation'],
  'mobile_offline_first_architecture.md': ['Android Room 持久化官方指南', 'https://developer.android.google.cn/training/data-storage/room'],
  'mobile_performance_optimization.md': ['Flutter 性能最佳实践', 'https://flutter.cn/docs/perf/best-practices'],
  'mobile_react_native_deep.md': ['React Native 原生模块指南', 'https://reactnative.dev/docs/legacy/native-modules-android'],
  'mobile_security_best_practices.md': ['OWASP 移动端安全测试指南', 'https://mas.owasp.org/'],
  'mobile_swiftui_complete.md': ['The Swift Programming Language 官方教材', 'https://docs.swift.org/swift-book/documentation/the-swift-programming-language/'],
};

const PLACEHOLDER = /^(\s*-\s*主题延伸：)\[关于「[^」]*」的检索页\]\(https?:\/\/zh\.wikipedia\.org\/w\/index\.php\?search=[^)]*\)\s*$/;

let replaced = 0, missed = 0;
const unmapped = [];
for (const [file, [text, url]] of Object.entries(MAP)) {
  const p = DIR + file;
  if (!fs.existsSync(p)) { console.log(`缺失文件：${file}`); continue; }
  const raw = fs.readFileSync(p, 'utf8');
  const eol = raw.includes('\r\n') ? '\r\n' : '\n';
  const lines = raw.split(/\r?\n/);
  let hit = false;
  for (let i = 0; i < lines.length; i++) {
    const m = PLACEHOLDER.exec(lines[i]);
    if (!m) continue;
    lines[i] = `${m[1]}[${text}](${url})`;
    hit = true;
    replaced++;
  }
  if (!hit) { missed++; unmapped.push(file); continue; }
  if (APPLY) fs.writeFileSync(p, lines.join(eol));
}
console.log(`替换真实参考链接：${replaced} 条；未命中占位行：${missed} 个文件`);
if (unmapped.length) console.log('未命中：' + unmapped.join('、'));
const leftover = [];
for (const f of fs.readdirSync(DIR).filter((f) => f.endsWith('.md'))) {
  if (fs.readFileSync(DIR + f, 'utf8').includes('zh.wikipedia.org/w/index.php?search=')) leftover.push(f);
}
console.log(`仍含维基检索占位锚点的课文：${leftover.length}`);
if (!APPLY) console.log('（dry-run，加 --apply 才写盘）');
