import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import 'code_block.dart';

/// 拦截 Markdown 的 <pre> 节点，替换成带复制按钮的代码块。
class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return CodeBlock(
      code: element.textContent,
      language: _detectLanguage(element),
    );
  }

  /// 从 <pre><code class="language-python"> 中解析语言名称。
  String? _detectLanguage(md.Element element) {
    final className = element.attributes['class'];
    if (className != null && className.startsWith('language-')) {
      return className.substring('language-'.length);
    }

    for (final child in element.children ?? const <md.Node>[]) {
      if (child is md.Element && child.tag == 'code') {
        final codeClass = child.attributes['class'];
        if (codeClass != null && codeClass.startsWith('language-')) {
          return codeClass.substring('language-'.length);
        }
        break;
      }
    }
    return null;
  }
}
