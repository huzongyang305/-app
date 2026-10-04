// 将 P2 新增课程的英文正文路径写入 manifest（开发期使用）。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

const Map<String, String> englishFiles = <String, String>{
  'project_python_cli_todo': 'assets/content_en/project_python_cli_todo.md',
  'project_rest_api_sqlite': 'assets/content_en/project_rest_api_sqlite.md',
  'project_rag_agent_service': 'assets/content_en/project_rag_agent_service.md',
  'project_debug_performance_triage':
      'assets/content_en/project_debug_performance_triage.md',
  'project_interview_coding_system_design':
      'assets/content_en/project_interview_coding_system_design.md',
};

Future<void> main() async {
  final file = File(manifestPath);
  final manifest =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  var linked = 0;
  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final path = englishFiles[lesson['id'] as String];
      if (path == null) continue;
      if (!File(path).existsSync()) {
        stderr.writeln('缺少英文正文：$path');
        exitCode = 1;
        return;
      }
      lesson['file_en'] = path;
      linked++;
    }
  }
  manifest['english_content_version'] = 1;
  manifest['english_content_updated_at'] = '2026-10-04';
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
    flush: true,
  );
  stdout.writeln('已链接英文正文：$linked 篇');
}
