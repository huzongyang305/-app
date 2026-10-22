import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/settings_provider.dart';
import 'app_strings.dart';

/// 在任意 Widget 中通过 context.l10n('key') 取界面文案。
extension AppStringsExtension on BuildContext {
  AppStrings get strings {
    final code = watch<SettingsProvider>().localeCode;
    return AppStrings(code);
  }

  String tr(String key) => strings.get(key);

  /// 事件回调 / 异步流程里安全读取当前语言代码（不订阅 Provider）。
  String get localeCodeRead => read<SettingsProvider>().localeCode;

  /// 带占位符的取词：trArgs('homeRecentCount', {'n': 3})。
  /// 词条里写 {n}，调用处传入实际值。
  String trArgs(String key, Map<String, Object?> args) {
    var text = strings.get(key);
    args.forEach((name, value) {
      text = text.replaceAll('{$name}', value == null ? '' : '$value');
    });
    return text;
  }

  /// 事件回调 / 异步流程里安全取词：只读不订阅，避免在 build 之外建立依赖。
  String trRead(String key) =>
      AppStrings(read<SettingsProvider>().localeCode).get(key);

  String trReadArgs(String key, Map<String, Object?> args) {
    var text = trRead(key);
    args.forEach((name, value) {
      text = text.replaceAll('{$name}', value == null ? '' : '$value');
    });
    return text;
  }

  /// 难度在数据里存中文，展示时按当前语言映射。
  String difficultyLabel(String difficulty) {
    switch (difficulty) {
      case '入门':
        return tr('difficultyBeginner');
      case '基础':
        return tr('difficultyBasic');
      case '进阶':
        return tr('difficultyIntermediate');
      case '高级':
        return tr('difficultyAdvanced');
      default:
        return difficulty;
    }
  }
}
