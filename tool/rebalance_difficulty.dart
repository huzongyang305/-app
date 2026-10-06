// P3 难度梯度治理：把「高级」收敛到真正需要复合背景或真实环境验证的课程。
//
// 用法：
//   dart tool/rebalance_difficulty.dart [--dry-run]
//
// 判定标准（写进内容规范，避免随意调整）：
//   高级：需要分布式/内核/GPU/安全攻防等复合背景，或必须依赖真实集群、
//         硬件与压测环境才能验证的课程；
//   进阶：在入门基础上完成一个完整能力模块，单机即可验证。
// 调整只改难度标签，同时更新 Markdown 的「学习阶段」元数据。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

/// lessonId → 新的难度标签。
const Map<String, String> reclassifications = <String, String>{
  // 计算机基础：汇编、离散数学、概率统计与嵌入式属于单机可验证的进阶内容。
  'assembly': '进阶',
  'discrete_math': '进阶',
  'probability': '进阶',
  'fundamentals_embedded_iot': '进阶',
  'fundamentals_project': '进阶',
  // 算法：工程化与常见图算法属于进阶，专题算法与理论保留高级。
  'sorting_advanced': '进阶',
  'cache_eviction': '进阶',
  'algorithms_project': '进阶',
  'algo_shortest_paths': '进阶',
  'algo_mst': '进阶',
  'algo_topological': '进阶',
  // 网络：单机可完成的协议与实战课下调为进阶。
  'cdn_proxy': '进阶',
  'websocket': '进阶',
  'network_project': '进阶',
  'auth_oauth': '进阶',
  'network_smtp': '进阶',
  // 安全：会话安全、SDL 与项目实战属于进阶。
  'security_auth_session': '进阶',
  'security_sdl': '进阶',
  'security_project': '进阶',
  // 数据库：单实例可完成的课程下调，分布式与治理类保留高级。
  'redis': '进阶',
  'sql_advanced': '进阶',
  'database_project': '进阶',
  'airflow_quality': '进阶',
  'db_postgresql_deep': '进阶',
  // 操作系统：基础机制与单机项目属于进阶。
  'virtual_memory': '进阶',
  'file_system': '进阶',
  'os_project': '进阶',
  // 工具链：可观测性与网关属于进阶，集群与 IaC 保留高级。
  'observability': '进阶',
  'gateway': '进阶',
  'toolchain_project': '进阶',
  // AI：应用层与协议层课程下调，训练、推理服务与安全保留高级。
  'ai_agent_evaluation': '进阶',
  'multimodal_rag': '进阶',
  'model_evaluation': '进阶',
  'agent_memory': '进阶',
  'ai_data_engineering': '进阶',
  'ai_rag_agent_project': '进阶',
  'ai_mcp': '进阶',
  'ai_a2a': '进阶',
  'ai_context_engineering': '进阶',
  'ai_computer_use': '进阶',
  'ai_browser_agent': '进阶',
  'ai_coding_agent': '进阶',
  'ai_graphrag': '进阶',
  'ai_vlm': '进阶',
  'ai_diffusion': '进阶',
  'ai_realtime_api': '进阶',
  'ai_governance': '进阶',
};

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;

  final before = <String, Map<String, int>>{};
  final after = <String, Map<String, int>>{};
  var changed = 0;
  final updatedFiles = <String>{};
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final categoryId = category['id'].toString();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final difficulty = lesson['difficulty'].toString();
      _count(before, categoryId, difficulty);
      final target = reclassifications[lesson['id']];
      if (target != null && target != difficulty) {
        lesson['difficulty'] = target;
        changed++;
        final path = lesson['file'] as String;
        if (!dryRun) {
          _updateMarkdown(path, difficulty, target);
          updatedFiles.add(path);
        }
      }
      _count(after, categoryId, lesson['difficulty'].toString());
    }
  }

  if (!dryRun && changed > 0) {
    manifest['difficulty_balance_version'] = 1;
    manifestFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      flush: true,
    );
  }
  final synced = dryRun ? 0 : _syncAllStages(manifest);
  stdout.writeln(
    '${dryRun ? '[dry-run] ' : ''}调整课程 $changed 篇，'
    '更新正文 ${updatedFiles.length} 个，同步学习阶段 $synced 处',
  );
  for (final entry in after.entries) {
    stdout.writeln('${entry.key}: ${before[entry.key]} → ${entry.value}');
  }
}

void _count(
  Map<String, Map<String, int>> target,
  String categoryId,
  String difficulty,
) {
  final counts = target.putIfAbsent(categoryId, () => <String, int>{});
  counts[difficulty] = (counts[difficulty] ?? 0) + 1;
}

void _updateMarkdown(String path, String oldTag, String newTag) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('找不到教程文件：$path');
    exitCode = 1;
    return;
  }
  var content = file.readAsStringSync();
  content = content.replaceAll('- 学习阶段：$oldTag', '- 学习阶段：$newTag');
  content = content.replaceAll(
    '· 学习阶段：$oldTag ·',
    '· 学习阶段：$newTag ·',
  );
  file.writeAsStringSync(content, flush: true);
}

/// 把 Markdown 里的学习阶段统一对齐到 manifest 的 difficulty 字段。
int _syncAllStages(Map<String, dynamic> manifest) {
  var synced = 0;
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final difficulty = lesson['difficulty'].toString();
      final file = File(lesson['file'] as String);
      if (!file.existsSync()) continue;
      final content = file.readAsStringSync();
      final updated = content.replaceAllMapped(
        RegExp(r'学习阶段：[^\s·]+'),
        (match) {
          if (match.group(0) == '学习阶段：$difficulty') return match.group(0)!;
          return '学习阶段：$difficulty';
        },
      );
      if (updated != content) {
        file.writeAsStringSync(updated, flush: true);
        synced++;
      }
    }
  }
  return synced;
}
