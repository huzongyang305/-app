import 'package:flutter/material.dart';

class VirtualMentor {
  final String id;
  final String name;
  final String avatar;
  final String specialty;
  final String personality;
  final List<String> encouragingMessages;
  final Color themeColor;
  final MentorStyle style;

  VirtualMentor({
    required this.id,
    required this.name,
    required this.avatar,
    required this.specialty,
    required this.personality,
    required this.encouragingMessages,
    required this.themeColor,
    required this.style,
  });

  String getEncouragement(LearningContext context) {
    if (context.isStruggling) {
      return '遇到困难是正常的，这正是成长的机会！💪';
    } else if (context.achievements.isNotEmpty) {
      return '太棒了！你的努力得到了回报！🎉';
    } else if (context.streakDays > 7) {
      return '连续学习${context.streakDays}天，你真的很棒！🔥';
    } else {
      return encouragingMessages[DateTime.now().millisecondsSinceEpoch % encouragingMessages.length];
    }
  }

  factory VirtualMentor.fromJson(Map<String, dynamic> json) {
    return VirtualMentor(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      specialty: json['specialty'] as String,
      personality: json['personality'] as String,
      encouragingMessages: List<String>.from(json['encouragingMessages']),
      themeColor: Color(json['themeColor'] as int),
      style: MentorStyle.values.firstWhere(
        (e) => e.name == json['style'],
        orElse: () => MentorStyle.friendly,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'specialty': specialty,
      'personality': personality,
      'encouragingMessages': encouragingMessages,
      'themeColor': themeColor.value,
      'style': style.name,
    };
  }
}

enum MentorStyle {
  friendly,
  professional,
  humorous,
  strict,
  zen,
}

class LearningContext {
  final bool isStruggling;
  final List<String> achievements;
  final int streakDays;
  final double currentProgress;

  LearningContext({
    required this.isStruggling,
    required this.achievements,
    required this.streakDays,
    required this.currentProgress,
  });
}

class MentorService {
  static List<VirtualMentor> getAllMentors() {
    return [
      VirtualMentor(
        id: 'mentor_alex',
        name: 'Alex - 友好导师',
        avatar: 'assets/mentors/alex.png',
        specialty: '前端开发',
        personality: '热情友善，善于鼓励初学者',
        encouragingMessages: [
          '每一步都是进步，继续加油！',
          '你已经比昨天更优秀了！',
          '学习是一场马拉松，不是短跑。',
          '相信自己，你可以的！',
        ],
        themeColor: Colors.blue,
        style: MentorStyle.friendly,
      ),
      VirtualMentor(
        id: 'mentor_sarah',
        name: 'Sarah - 专业导师',
        avatar: 'assets/mentors/sarah.png',
        specialty: '后端架构',
        personality: '严谨专业，注重最佳实践',
        encouragingMessages: [
          '代码质量决定项目成败。',
          '深入理解原理，才能写出好代码。',
          '保持好奇心，持续学习新技术。',
          '专业源于细节的把控。',
        ],
        themeColor: Colors.purple,
        style: MentorStyle.professional,
      ),
      VirtualMentor(
        id: 'mentor_mike',
        name: 'Mike - 幽默导师',
        avatar: 'assets/mentors/mike.png',
        specialty: '全栈开发',
        personality: '风趣幽默，让学习充满乐趣',
        encouragingMessages: [
          'Bug是你最好的老师，虽然它不会说话 😄',
          '咖啡+代码=程序员的标准配置 ☕',
          '今天的bug，明天的feature！',
          '编程就像解谜游戏，享受过程吧！',
        ],
        themeColor: Colors.orange,
        style: MentorStyle.humorous,
      ),
      VirtualMentor(
        id: 'mentor_lisa',
        name: 'Lisa - 严格导师',
        avatar: 'assets/mentors/lisa.png',
        specialty: '算法与数据结构',
        personality: '要求严格，追求卓越',
        encouragingMessages: [
          '没有借口，只有结果。',
          '重复练习直到完美。',
          '高标准才能带来高质量。',
          '别满足于"能用"，要追求"最优"。',
        ],
        themeColor: Colors.red,
        style: MentorStyle.strict,
      ),
      VirtualMentor(
        id: 'mentor_zen',
        name: 'Zen - 禅意导师',
        avatar: 'assets/mentors/zen.png',
        specialty: '系统设计',
        personality: '平和宁静，引导深度思考',
        encouragingMessages: [
          '静心思考，答案自现。',
          '慢即是快，稳才能远。',
          '代码如诗，优雅至上。',
          '理解本质，形式自明。',
        ],
        themeColor: Colors.teal,
        style: MentorStyle.zen,
      ),
    ];
  }

  static VirtualMentor getDefaultMentor() {
    return getAllMentors()[0];
  }
}
