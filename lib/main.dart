import 'package:flutter/material.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/storage_migration_service.dart';

/// 程序入口：先初始化本地存储，再启动界面。
///
/// 所有课程内容都在 assets 中，因此启动过程不需要网络。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final StorageService storage;
  try {
    storage = await StorageService.init();
  } on StorageMigrationException catch (error) {
    runApp(_StartupFailureApp(error: error));
    return;
  }

  // 本地复习提醒：初始化系统通知渠道；若用户此前已开启提醒，
  // 启动时顺带确认一次通知权限（用户拒绝也不会影响其他功能）。
  final notifications = NotificationService();
  await notifications.init();
  if (storage.read('review_reminder_enabled', defaultValue: false) == true) {
    await notifications.requestPermission();
  }

  runApp(CodeLearnApp(storage: storage, notifications: notifications));
}

/// 数据版本高于当前客户端时的只读错误页，不会自动清空用户数据。
class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp({required this.error});

  final StorageMigrationException error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.system_update_alt, size: 56),
                  const SizedBox(height: 18),
                  const Text(
                    '本地数据来自更新版本的 App。请先升级 App，当前版本不会修改或清空数据。',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Local data was created by a newer app version. Update the app first; this version will not modify or erase it.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'DB v${error.storedVersion} / App v${error.supportedVersion}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
