// 扩充 P2 新增项目课的测验解析，使每条解析不少于 120 字符。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

const Map<String, List<String>> additions = <String, List<String>>{
  'project_python_cli_todo': <String>[
    '把校验放在入口层还能让错误信息和退出码一一对应，测试时可以分别验证参数解析失败与业务失败，不会让两类问题混在同一个堆栈里。',
    '原子写入必须保证临时文件与目标文件在同一个目录、同一个文件系统，替换才会是原子的；跨目录移动可能退化成复制并在中途失败。',
    '此外应该固定字段顺序和编码，遇到非 ASCII 标题时先确认编码参数，再比较不同版本输出的差异，避免把编码噪音当成契约变化。',
    '错误信息还应区分参数错误与数据错误，并在帮助文本中列出退出码含义，让调用脚本不依赖解析人类可读的提示文本。',
  ],
  'project_rest_api_sqlite': <String>[
    '服务端要把幂等键与请求体摘要一起保存，同一个键携带不同参数时返回冲突，避免客户端误用同一个键提交两笔不同业务。',
    '事务边界还应尽量短，不要在持有写锁时调用外部网络；否则锁等待会放大成整个服务的延迟抖动。',
    '业务冲突还应带上稳定的错误码和当前可用库存等安全字段，客户端据此提示用户或调整数量，而不是盲目重试。',
    '状态机应明确列出允许的迁移并写入测试；对于需要人工介入的场景，返回的冲突响应要附上工单或客服指引。',
  ],
  'project_rag_agent_service': <String>[
    '检索结果还要保留来源、标题和片段位置，生成后逐条校验引用编号，才能区分真正基于证据的回答与看似合理的编造。',
    '混合检索后仍需重排和去重，避免同一段内容占据全部上下文名额，也要控制上下文长度以免关键证据被模型忽略。',
    '拒答时还应记录触发原因和相关分数，运营可以据此补充文档或调整阈值，而不是用降低标准的方式掩盖知识缺口。',
    '工具调用还要设置超时、结果大小上限和审计日志，出现异常参数或高频调用时能够及时熔断并追溯到具体请求。',
  ],
  'project_debug_performance_triage': <String>[
    '基线和实验要固定数据集、并发量与机器环境，否则两次报告的差异可能来自数据变化而不是代码改动，结论无法复用。',
    '分析分位数时还要结合样本量；样本太少时 P99 会剧烈波动，应同时查看直方图、错误率和慢请求的分布形态。',
    '单变量实验还要预先写下预期结果和回滚条件，实验结束后无论成败都记录结论，避免团队重复验证同一个假设。',
    '报告应包含环境、提交版本、数据集和原始输出，并说明指标波动范围；只有能被他人在相同条件下复现的收益才算成立。',
  ],
  'project_interview_coding_system_design': <String>[
    '澄清阶段还要确认函数签名、返回值形式和是否允许修改输入，这些信息会直接影响边界处理与空间复杂度。',
    '推导过程中要说明每一步消除了哪种重复工作，以及为什么当前数据结构能把关键操作降到目标复杂度。',
    '测试时还应覆盖历史重复位置已滑出窗口的情况，确认左边界只前进不后退，从而验证窗口内始终无重复。',
    '量化估算要写出假设和计算过程，并指出最可能的瓶颈；设计追问通常围绕容量、一致性、失败恢复和成本展开。',
  ],
};

Future<void> main() async {
  final file = File(manifestPath);
  final manifest =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  var updated = 0;
  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final extras = additions[lesson['id'] as String];
      if (extras == null) continue;
      final quiz = lesson['quiz'] as List;
      for (
        var index = 0;
        index < quiz.length && index < extras.length;
        index++
      ) {
        final question = (quiz[index] as Map).cast<String, dynamic>();
        final extra = extras[index];
        final explanation = question['explanation'] as String;
        // 修复历史重复追加：去掉多出来的一段后保留“原文 + 一次补充”。
        if (explanation.endsWith('$extra$extra')) {
          question['explanation'] = explanation.substring(
            0,
            explanation.length - extra.length,
          );
          updated++;
          continue;
        }
        // 幂等保护：重复运行时不再追加同一段说明。
        if (explanation.endsWith(extra)) continue;
        question['explanation'] = '$explanation$extra';
        updated++;
      }
    }
  }
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
    flush: true,
  );
  stdout.writeln('已扩充解析：$updated 条');
}
