// 语言入门课「通俗精讲」共享数据模型。
//
// 每门课提供一段手写讲解：先用一句话点题，再用生活比喻建立直觉，
// 然后逐行拆代码、演算输出、列出实际会遇到的坑并给出练习。
// 这些字段全部按课定制，避免跨课模板化长句触发内容门禁。

/// 一门语言入门课的通俗精讲素材。
class LanguageIntroDetail {
  const LanguageIntroDetail({
    required this.id,
    required this.sectionTitle,
    required this.codeLanguage,
    required this.oneLiner,
    required this.analogy,
    required this.code,
    required this.lineWalk,
    required this.runThrough,
    required this.pitfalls,
    required this.drill,
    this.extraHeading,
    this.extraBody,
  });

  /// 课程 id，与 manifest 中的 lesson id 一致。
  final String id;

  /// 章节标题后缀，例如「Python 第一个脚本」。
  final String sectionTitle;

  /// 代码块的语言标记，例如 python、cpp、bash。
  final String codeLanguage;

  /// 「一句话说清它是什么」：直接给结论，不铺垫。
  final String oneLiner;

  /// 「用生活比喻理解」：把抽象机制映射到日常场景。
  final String analogy;

  /// 「完整可运行代码」：读者可以直接复制执行的最小程序。
  final String code;

  /// 「逐行拆开看」：用 `- ` 列表写逐行解释。
  final String lineWalk;

  /// 「把程序跑一遍」：用 `- ` 列表写执行顺序与输出演算。
  final String runThrough;

  /// 「新手最容易踩的坑」：用 `- ` 列表写本课真实高频错误。
  final String pitfalls;

  /// 「动手练一练」：用 `- ` 列表写可验证的小任务。
  final String drill;

  /// 选填的额外小节标题，用于放本课特有的对照表。
  final String? extraHeading;

  /// 选填的额外小节正文。
  final String? extraBody;
}
