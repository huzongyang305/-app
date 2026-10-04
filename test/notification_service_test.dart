import 'package:code_learn_app/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 通知服务的降级行为测试。
///
/// 单元测试环境没有原生插件，服务必须「静默失活」：
/// 所有方法都能正常返回，绝不抛异常影响 App 其他功能。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('插件不可用时初始化失败但不抛异常', () async {
    final service = NotificationService();
    await expectLater(service.init(), completes);
    expect(service.isAvailable, isFalse);
  });

  test('重复初始化是幂等的', () async {
    final service = NotificationService();
    await service.init();
    await service.init();
    await expectLater(service.init(), completes);
  });

  test('权限申请在不可用时返回 false', () async {
    final service = NotificationService();
    expect(await service.requestPermission(), isFalse);
  });

  test('排期与取消在不可用时都被安全忽略', () async {
    final service = NotificationService();
    await expectLater(
      service.scheduleDailyReview(
        hour: 20,
        minute: 30,
        dueCount: 5,
        isEnglish: false,
      ),
      completes,
    );
    await expectLater(
      service.scheduleDailyReview(
        hour: 7,
        minute: 0,
        dueCount: 0,
        isEnglish: true,
      ),
      completes,
    );
    await expectLater(service.cancelDailyReview(), completes);
  });
}
