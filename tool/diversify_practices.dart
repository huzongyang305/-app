// 练习差异化工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/diversify_practices.dart [--dry-run]
//
// 把批量生成的统一练习文案，替换为按课程方向变化的练习说明，并加入本课关键词。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String marker = '<!-- practice-diversified:v1 -->';
const String genericIntro = '练习按「复述 → 改写 → 迁移」递进。不要只阅读，至少完成前两项。';

const Map<String, String> categoryGroups = <String, String>{
  'flutter': 'language',
  'html_css': 'language',
  'python': 'language',
  'cpp': 'language',
  'java': 'language',
  'javascript': 'language',
  'csharp': 'language',
  'go': 'language',
  'rust': 'language',
  'typescript': 'language',
  'shell': 'language',
  'fundamentals': 'systems',
  'network': 'systems',
  'os': 'systems',
  'toolchain': 'systems',
  'distributed': 'systems',
  'algorithms': 'data',
  'database': 'data',
  'math': 'data',
  'software_engineering': 'product',
  'project_practice': 'product',
  'cross_language': 'product',
  'visual_guide': 'product',
  'ai': 'ai',
};

const Map<String, String> groupIntros = <String, String>{
  'language': '先跑通最小示例，再改写一个输入，最后把它迁移成一个小工具或测试用例。',
  'systems': '先画出链路，再注入一个故障，最后用日志、指标或抓包结果验证恢复过程。',
  'data': '先手算一组小数据，再写实现，最后对比复杂度、边界和不同数据分布。',
  'product': '先把目标写成可验收标准，再完成最小交付，最后复盘风险、回滚和改进项。',
  'ai': '先建立少量离线样例，再改变一个提示或数据变量，最后比较质量、延迟、成本和安全性。',
};

const Map<String, String> categoryIntros = <String, String>{
  'flutter': '先做一个最小 Widget，再切换状态与约束，最后在窄屏和深色模式下验证布局。',
  'html_css': '先写最小语义结构，再调整布局与样式，最后检查键盘、窄屏和对比度。',
  'python': '先写可运行脚本，再用类型注解与测试保护核心函数，最后处理真实输入。',
  'cpp': '先开启警告编译最小程序，再验证内存与边界，最后用 Sanitizer 跑一遍。',
  'java': '先跑通最小类与测试，再补异常和并发边界，最后观察线程与资源变化。',
  'javascript': '先在 Node 或浏览器复现行为，再改写异步与错误路径，最后补测试。',
  'csharp': '先建最小控制台程序，再补类型、异步和异常路径，最后用 dotnet test 验证。',
  'go': '先写最小程序并用 go test 验证，再补 context、并发上限和错误传播。',
  'rust': '先让 cargo check 通过，再补所有权、错误和并发边界，最后运行 clippy。',
  'typescript': '先让类型检查通过，再制造一次类型错误，最后补运行时校验与测试。',
  'shell': '先加严格模式，再在临时目录验证成功与失败路径，最后补回滚。',
  'fundamentals': '先用表格或时序图描述机制，再手算一个最小例子，最后用程序验证。',
  'network': '先抓一次真实请求或画出协议交互，再注入延迟或丢包，最后解释每层变化。',
  'os': '先画出进程、线程或资源状态，再模拟调度与竞争，最后记录状态迁移。',
  'toolchain': '先在临时环境执行完整命令链，再模拟失败，最后验证回滚和清理。',
  'distributed': '先画拓扑与数据流，再注入节点或网络故障，最后验证恢复与一致性。',
  'algorithms': '先手算 8 个元素的状态变化，再实现并统计操作次数与复杂度。',
  'database': '先写 schema 与查询，再补边界和失败数据，最后看执行计划与锁等待。',
  'math': '先手算 3 步小例子，再画图或用程序验证，最后说明假设与误差。',
  'software_engineering': '先写验收标准，再做最小交付，最后用评审、测试或复盘验证。',
  'project_practice': '先拆任务和风险，再完成一个可交付增量，最后记录回滚与改进。',
  'cross_language': '用两种语言实现同一行为，再对比语法、错误、性能和生态差异。',
  'visual_guide': '先不看原图手绘流程，再标出状态变化，最后用自己的话解释关键一步。',
  'ai': '先写评测样例，再改一个提示、模型或数据变量，最后比较质量、成本与安全。',
};

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final force = args.contains('--force');
  final manifest = jsonDecode(
    await File(manifestPath).readAsString(),
  ) as Map<String, dynamic>;
  var changed = 0;
  var skipped = 0;

  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final categoryId = category['id'] as String;
    final intro =
        categoryIntros[categoryId] ??
        groupIntros[categoryGroups[categoryId] ?? 'systems']!;
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final file = File(lesson['file'] as String);
      var content = await file.readAsString();
      if (content.contains(marker) && !force) {
        skipped++;
        continue;
      }
      if (!content.contains(genericIntro) && !force) {
        skipped++;
        continue;
      }

      final keywords =
          (lesson['keywords'] as List?)
              ?.map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .take(3)
              .join('、') ??
          '';
      if (content.contains(genericIntro)) {
        content = content.replaceFirst(genericIntro, intro);
      } else {
        final oldIntro = groupIntros.values.firstWhere(
          (item) => content.contains(item),
          orElse: () => '',
        );
        if (oldIntro.isEmpty) {
          skipped++;
          continue;
        }
        content = content.replaceFirst(oldIntro, intro);
      }
      if (!content.contains(marker)) {
        content = content.replaceFirst(
          '## 动手练习',
          '## 动手练习\n\n$marker\n\n> 本课练习重点：围绕「$keywords」完成复述、实验和交付，每个结果都要能被别人检查。',
        );
      }
      content = content
          .replaceFirst('### 练习 1：不看原文复述（10 分钟）', '### 练习 1：建立心智模型（10 分钟）')
          .replaceFirst('### 练习 2：示例改写（20 分钟）', '### 练习 2：做一次可控实验（20 分钟）')
          .replaceFirst('### 练习 3：迁移任务（30 分钟）', '### 练习 3：交付一个小结果（30 分钟）');
      if (!dryRun) {
        await file.writeAsString(content, flush: true);
      }
      changed++;
    }
  }

  stdout.writeln('${dryRun ? '待差异化' : '已差异化'}：$changed 篇，无需处理：$skipped 篇');
}
