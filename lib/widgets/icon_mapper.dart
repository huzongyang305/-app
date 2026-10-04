import 'package:flutter/material.dart';

/// 把 manifest.json 中的图标名称映射为 Material 图标。
IconData iconFromName(String name) {
  switch (name) {
    case 'code':
      return Icons.code;
    case 'memory':
      return Icons.memory;
    case 'account_tree':
      return Icons.account_tree;
    case 'lan':
      return Icons.lan;
    case 'storage':
      return Icons.storage;
    case 'developer_board':
      return Icons.developer_board;
    case 'terminal':
      return Icons.terminal;
    case 'psychology':
      return Icons.psychology;
    case 'smart_toy':
      return Icons.smart_toy;
    case 'quiz':
      return Icons.quiz;
    case 'book':
      return Icons.menu_book;
    case 'star':
      return Icons.star;
    case 'note':
      return Icons.edit_note;
    case 'translate':
      return Icons.translate;
    case 'insights':
      return Icons.insights;
    case 'rocket':
      return Icons.rocket_launch;
    case 'security':
      return Icons.security;
    case 'phone_iphone':
      return Icons.phone_iphone;
    default:
      return Icons.school;
  }
}
