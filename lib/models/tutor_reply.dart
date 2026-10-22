/// 离线学习助手的一次回复。
///
/// 这里不调用大模型，而是基于本地课程索引做意图识别、知识检索和学习建议；
/// 优点是完全离线、结果可解释，也不会把学习数据发到网络。
class TutorReply {
  const TutorReply({
    required this.title,
    required this.body,
    this.lessonIds = const <String>[],
    this.followUps = const <String>[],
  });

  final String title;
  final String body;
  final List<String> lessonIds;
  final List<String> followUps;
}
