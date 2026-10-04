import 'localized_text.dart';

/// 测验题目。
///
/// 基础选择题使用 `answerIndex`；多选、填空、排序等新题型在其基础上扩展：
/// - `multi`：`answerIndexes` 保存全部正确选项；
/// - `fill`：`acceptedAnswers` 保存可接受答案，输入时忽略大小写与空白；
/// - `order`：`correctOrder` 保存正确顺序在 `options` 中的下标；
/// - `code` / `debug`：`code` 展示代码，`language` 与 `expectedOutput` 供沙箱辅助。
class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.explanation,
    this.type = 'single',
    this.code,
    this.answerIndexes = const <int>[],
    this.acceptedAnswers = const <String>[],
    this.correctOrder = const <int>[],
    this.language,
    this.expectedOutput,
  });

  final String question;
  final List<String> options;

  /// 兼容旧数据：单选正确答案下标，也是多选题第一项答案下标。
  final int answerIndex;

  final String explanation;

  /// 题型：single / multi / fill / order / code / debug。
  final String type;

  /// 代码输出、排错等题型的代码片段。
  final String? code;

  /// 多选题的完整答案集合；为空时回退到 answerIndex。
  final List<int> answerIndexes;

  /// 填空题可接受答案（支持多个等价写法）。
  final List<String> acceptedAnswers;

  /// 排序题的正确顺序，值是 `options` 的下标。
  final List<int> correctOrder;

  /// 代码题型对应的离线沙箱语言标识（javascript / typescript / python 等）。
  final String? language;

  /// 代码题目的参考输出，用于展示解析或“在沙箱中运行”提示。
  final String? expectedOutput;

  List<int> get correctIndexes =>
      answerIndexes.isEmpty ? <int>[answerIndex] : answerIndexes;

  bool get isSingleChoice =>
      type == 'single' || type == 'code' || type == 'debug';

  bool get isInteractive =>
      type == 'fill' || type == 'order' || type == 'multi';

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawAnswer = json['answer'];
    final options = (json['options'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList();

    final rawIndexes = json['answers'] ?? json['correct_indexes'];
    final answerIndexes = rawIndexes is List
        ? rawIndexes
              .map((item) => item is int ? item : int.tryParse(item.toString()))
              .whereType<int>()
              .toList()
        : const <int>[];

    final acceptedAnswers = <String>[
      ...(json['accepted_answers'] as List<dynamic>? ?? const []).map(
        (item) => item.toString(),
      ),
    ];
    if (rawAnswer is String) acceptedAnswers.add(rawAnswer);

    final answerIndex = rawAnswer is int
        ? rawAnswer
        : (answerIndexes.isNotEmpty ? answerIndexes.first : 0);

    final correctOrder = (json['correct_order'] as List<dynamic>? ?? const [])
        .map((item) => item is int ? item : int.tryParse(item.toString()))
        .whereType<int>()
        .toList();

    return QuizQuestion(
      question: json['question'] as String? ?? '',
      options: options,
      answerIndex: answerIndex,
      explanation: json['explanation'] as String? ?? '',
      type: json['type'] as String? ?? 'single',
      code: json['code'] as String?,
      answerIndexes: answerIndexes,
      acceptedAnswers: acceptedAnswers,
      correctOrder: correctOrder,
      language: json['language'] as String?,
      expectedOutput: json['expected_output'] as String?,
    );
  }
}

/// 知识点（教程）：元数据来自 manifest.json，正文来自 assets 中的 Markdown 文件。
class Lesson {
  const Lesson({
    required this.id,
    required this.categoryId,
    this.group,
    this.difficulty = '基础',
    this.order = 0,
    required this.title,
    required this.summary,
    required this.assetFile,
    this.assetFileEn,
    required this.minutes,
    required this.keywords,
    required this.quiz,
  });

  final String id;
  final String categoryId;

  /// 知识点分组（例如编程语言分类下的 Python / C++ / Java / JavaScript）。
  /// 为空表示该分类不做二次分组。
  final String? group;

  /// 难度标签：入门 / 基础 / 进阶 / 高级。
  final String difficulty;

  /// 课程内的推荐学习顺序（从 0 开始，由内容索引给出）。
  final int order;
  final LocalizedText title;
  final LocalizedText summary;
  final String assetFile;
  final String? assetFileEn;
  final int minutes;
  final List<String> keywords;
  final List<QuizQuestion> quiz;

  /// 是否提供可单独加载的完整英文正文。
  bool get hasEnglishBody => assetFileEn?.trim().isNotEmpty ?? false;

  factory Lesson.fromJson(Map<String, dynamic> json, String categoryId) {
    return Lesson(
      id: json['id'] as String,
      categoryId: categoryId,
      group: json['group'] as String?,
      difficulty: json['difficulty'] as String? ?? '基础',
      order: json['order'] as int? ?? 0,
      title: LocalizedText.fromJson(
        (json['title'] as Map).cast<String, dynamic>(),
      ),
      summary: LocalizedText.fromJson(
        (json['summary'] as Map).cast<String, dynamic>(),
      ),
      assetFile: json['file'] as String,
      assetFileEn: json['file_en'] as String?,
      minutes: json['minutes'] as int? ?? 10,
      keywords: (json['keywords'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      quiz: (json['quiz'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                QuizQuestion.fromJson((item as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }
}
