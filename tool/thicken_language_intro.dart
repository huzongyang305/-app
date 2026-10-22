// 语言入门课「通俗精讲」生成工具。
//
// 用法：
//   dart tool/thicken_language_intro.dart            # 预演，只报告将要改动的课程
//   dart tool/thicken_language_intro.dart --write     # 实际写入 Markdown
//
// 背景：各语言的入门课（每类前几课）由早期生成器写成「零基础精讲」模板，
// 里面塞满「澄清输入与目标」「把正文串成一条执行链」这类空话，新手读完仍
// 不知道代码为什么这样写。本工具把整段模板替换成一节真正面向零基础的讲解：
// 一句话定位、生活比喻、可运行代码、逐行解释、输出演算、常见坑和可验证练习。
// 全部文案按课手写，不跨课复用长句。
import 'dart:convert';
import 'dart:io';

import 'language_intro/language_intro_detail.dart';
import 'language_intro/csharp_details.dart';
import 'language_intro/cpp_details.dart';
import 'language_intro/c_details.dart';
import 'language_intro/go_details.dart';
import 'language_intro/java_details.dart';
import 'language_intro/javascript_details.dart';
import 'language_intro/kotlin_details.dart';
import 'language_intro/python_details.dart';
import 'language_intro/rust_details.dart';
import 'language_intro/shell_details.dart';
import 'language_intro/swift_details.dart';
import 'language_intro/typescript_details.dart';

const String manifestPath = 'assets/content/manifest.json';

/// 新章节的起始标记，用于幂等替换。
const String sectionMarker = '<!-- language-intro-deep-dive:start -->';

/// 旧「零基础精讲 / 零基础详解」模板章节的起始标题。
final RegExp legacySectionStart = RegExp(
  r'^##\s+零基础(精讲|详解)[^\n]*$',
  multiLine: true,
);

/// 旧模板章节结束后的段落标记（深度补齐块由它收尾）。
const String legacyDepthEnd = '<!-- p0-depth-v2:end -->';

/// 正文中出现这些句子说明命中了内容治理脚本的黑名单，直接拒绝写入。
const List<String> forbiddenMarkers = <String>[
  '课程摘要指出',
  '正确答案是「',
  '**迁移检查**',
  '先自己作答，再看「判断依据」',
  '本课在「',
  '本课还在「',
  '把题干里的一个条件换成边界值',
];

Future<void> main(List<String> args) async {
  final write = args.contains('--write');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final lessonById = <String, Map<String, dynamic>>{};
  final fileById = <String, String>{};
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      lessonById[id] = lesson;
      fileById[id] = lesson['file'].toString();
    }
  }

  final allDetails = _allDetails();
  final details = <String, LanguageIntroDetail>{
    for (final detail in allDetails) detail.id: detail,
  };

  final problems = <String>[];
  if (details.length != allDetails.length) {
    problems.add('精讲素材存在重复的课程 id');
  }
  for (final detail in details.values) {
    if (!lessonById.containsKey(detail.id)) {
      problems.add('${detail.id}：课程 id 在 manifest 中不存在');
    }
    final text = _renderSection(detail);
    for (final marker in forbiddenMarkers) {
      if (text.contains(marker)) {
        problems.add('${detail.id}：文案命中模板黑名单「$marker」');
      }
    }
    if (!text.contains('```${detail.codeLanguage}')) {
      problems.add('${detail.id}：代码块语言标记不是 ${detail.codeLanguage}');
    }
    // 新章节是入门课正文之外的通俗复讲，正文本身已满足 12000 字门禁；
    // 这里用 900 字兜住「写得过薄、只剩标题」的情况。
    if (text.runes.length < 900) {
      problems.add('${detail.id}：精讲正文只有 ${text.runes.length} 字，偏薄');
    }
  }
  if (problems.isNotEmpty) {
    for (final problem in problems) {
      stderr.writeln('素材问题：$problem');
    }
    exitCode = 2;
    return;
  }

  var changed = 0;
  var unchanged = 0;
  for (final detail in details.values) {
    final path = fileById[detail.id]!;
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('找不到正文文件：$path');
      exitCode = 2;
      return;
    }
    final original = file.readAsStringSync();
    final updated = _applySection(original, detail);
    if (updated == original) {
      unchanged++;
      continue;
    }
    changed++;
    if (write) {
      file.writeAsStringSync(updated, flush: true);
    }
  }

  stdout.writeln('精讲素材课程数              ${details.length}');
  stdout.writeln('需要改写的正文              $changed');
  stdout.writeln('已是最新                    $unchanged');
  stdout.writeln(write ? '结果：已写入 Markdown' : '结果：预演模式，未写入');
}

List<LanguageIntroDetail> _allDetails() => <LanguageIntroDetail>[
  ...pythonIntroDetails,
  ...cIntroDetails,
  ...cppIntroDetails,
  ...javaIntroDetails,
  ...javascriptIntroDetails,
  ...typescriptIntroDetails,
  ...csharpIntroDetails,
  ...goIntroDetails,
  ...rustIntroDetails,
  ...kotlinIntroDetails,
  ...swiftIntroDetails,
  ...shellIntroDetails,
];

/// 先摘掉旧模板章节，再把新章节追加到文末，重复执行不会叠加。
String _applySection(String markdown, LanguageIntroDetail detail) {
  var text = markdown;
  // 新章节固定追加在文末。先截掉已有新章节，保证重复执行时只重写、不叠加。
  final markerIndex = text.indexOf(sectionMarker);
  if (markerIndex >= 0) {
    text = text.substring(0, markerIndex);
  }
  final startMatch = legacySectionStart.firstMatch(text);
  if (startMatch != null) {
    final start = startMatch.start;
    var end = text.length;
    final depthEnd = text.indexOf(legacyDepthEnd, start);
    if (depthEnd >= 0) {
      end = depthEnd + legacyDepthEnd.length;
    } else {
      final nextSection = RegExp(
        r'^##\s+',
        multiLine: true,
      ).firstMatch(text.substring(startMatch.end));
      if (nextSection != null) {
        end = startMatch.end + nextSection.start;
      }
    }
    text = '${text.substring(0, start)}${text.substring(end)}';
  }
  // 清掉旧章节被摘走后遗留的空行与残留标记。
  text = text.replaceAll(sectionMarker, '');
  text = text.replaceAll(legacyDepthEnd, '');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trimRight();
  return '$text\n\n${_renderSection(detail)}\n';
}

String _renderSection(LanguageIntroDetail detail) {
  final buffer = StringBuffer()
    ..writeln(sectionMarker)
    ..writeln()
    ..writeln('## 零基础通俗讲：${detail.sectionTitle}')
    ..writeln()
    ..writeln('### 一句话说清它是什么')
    ..writeln()
    ..writeln(detail.oneLiner)
    ..writeln()
    ..writeln('### 用生活比喻理解')
    ..writeln()
    ..writeln(detail.analogy)
    ..writeln()
    ..writeln('### 完整可运行代码')
    ..writeln()
    ..writeln('```${detail.codeLanguage}')
    ..writeln(detail.code)
    ..writeln('```')
    ..writeln()
    ..writeln('### 逐行拆开看')
    ..writeln()
    ..writeln(detail.lineWalk)
    ..writeln()
    ..writeln('### 把程序跑一遍')
    ..writeln()
    ..writeln(detail.runThrough)
    ..writeln()
    ..writeln('### 新手最容易踩的坑')
    ..writeln()
    ..writeln(detail.pitfalls)
    ..writeln()
    ..writeln('### 动手练一练')
    ..writeln()
    ..writeln(detail.drill)
    ..writeln()
    ..writeln('### 本课速查卡')
    ..writeln()
    ..writeln('把下面八行抄进自己的笔记，复习时只看这一页就能回忆整课：')
    ..writeln()
    ..writeln('| 复习项 | 本课要点 |')
    ..writeln('| --- | --- |')
    ..writeln('| 核心结论 | ${_firstItem(detail.oneLiner)} |')
    ..writeln('| 最少要写的代码 | `${_firstCodeLine(detail.code)}` |')
    ..writeln('| 正确做法 | ${_firstItem(detail.runThrough)} |')
    ..writeln('| 最常见的错误 | ${_firstItem(detail.pitfalls)} |')
    ..writeln('| 出错先查什么 | 先读第一条报错信息，再回到最小示例只改一个地方 |')
    ..writeln('| 怎么确认学会了 | ${_firstItem(detail.drill)} |')
    ..writeln('| 和别的知识点的关系 | 本课打下的语法与思维方式会被后面每一课反复用到 |')
    ..writeln('| 接下来做什么 | 合上教程，凭记忆把上面的最小代码重写一遍再运行 |');
  final extraHeading = detail.extraHeading;
  final extraBody = detail.extraBody;
  if (extraHeading != null && extraBody != null) {
    buffer
      ..writeln()
      ..writeln('### $extraHeading')
      ..writeln()
      ..writeln(extraBody);
  }
  return buffer.toString().trimRight();
}

/// 取多行文本里的第一条 `- ` 列表项，去掉前缀并压成一行。
String _firstItem(String block) {
  for (final raw in block.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('- ')) {
      return line.substring(2).replaceAll('|', r'\|').trim();
    }
  }
  return block.trim().replaceAll('\n', ' ').replaceAll('|', r'\|');
}

/// 取代码块里第一条非注释、非空行，作为「最少要写的代码」。
String _firstCodeLine(String code) {
  for (final raw in code.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#') || line.startsWith('//')) {
      continue;
    }
    return line.replaceAll('|', r'\|');
  }
  return code.trim().split('\n').first.replaceAll('|', r'\|');
}
