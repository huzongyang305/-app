/// 双语文本：教程标题、分类名称等需要随界面语言切换。
class LocalizedText {
  const LocalizedText({required this.zh, required this.en});

  final String zh;
  final String en;

  factory LocalizedText.fromJson(Map<String, dynamic> json) {
    return LocalizedText(
      zh: json['zh'] as String? ?? '',
      en: json['en'] as String? ?? json['zh'] as String? ?? '',
    );
  }

  /// 根据语言代码取对应文案，默认返回中文。
  String of(String localeCode) => localeCode == 'en' ? en : zh;
}
