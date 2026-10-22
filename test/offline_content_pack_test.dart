import 'dart:convert';

import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/offline_content_pack_service.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('离线内容包校验、覆盖、追加与移除', () async {
    final storage = StorageService.inMemory();
    final service = OfflineContentPackService(storage: storage);
    final pack = service.decode(
      jsonEncode(<String, dynamic>{
        'schema': OfflineContentPackService.schema,
        'schema_version': OfflineContentPackService.schemaVersion,
        'pack_id': 'test-pack',
        'name': 'P2 Test Pack',
        'version': '2026.10',
        'lessons': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'python_first_script',
            'category_id': 'python',
            'title': <String, String>{
              'zh': '离线更新后的第一课',
              'en': 'Updated first lesson',
            },
            'summary': <String, String>{
              'zh': '来自离线内容包',
              'en': 'From an offline pack',
            },
            'markdown': '# Offline update\n\nPack markdown marker.',
          },
          <String, dynamic>{
            'id': 'offline_sample_lesson',
            'category_id': 'python',
            'title': <String, String>{
              'zh': '内容包新增课程',
              'en': 'Pack-added lesson',
            },
            'summary': <String, String>{
              'zh': '无需重新安装 APK',
              'en': 'No APK reinstall required',
            },
            'markdown': '# Added offline lesson',
          },
        ],
      }),
    );
    await service.persist(pack);

    final provider = ContentProvider(storage: storage);
    await provider.load();

    expect(provider.offlinePackInfo?.id, 'test-pack');
    expect(provider.offlinePackInfo?.lessonCount, 2);
    expect(provider.lessonById('python_first_script')?.title.zh, '离线更新后的第一课');
    expect(provider.lessonById('offline_sample_lesson'), isNotNull);
    expect(
      await provider.markdownOf(provider.lessonById('python_first_script')!),
      contains('Pack markdown marker.'),
    );

    await provider.removeOfflinePack();
    expect(provider.offlinePackInfo, isNull);
    expect(provider.lessonById('offline_sample_lesson'), isNull);
    expect(
      provider.lessonById('python_first_script')?.title.zh,
      isNot('离线更新后的第一课'),
    );
  });

  test('离线内容包拒绝错误 schema 和空课程', () {
    final service = OfflineContentPackService();
    expect(
      () => service.decode(jsonEncode(<String, dynamic>{'schema': 'wrong'})),
      throwsA(isA<ContentPackException>()),
    );
    expect(
      () => service.decode(
        jsonEncode(<String, dynamic>{
          'schema': OfflineContentPackService.schema,
          'schema_version': 1,
          'pack_id': 'empty',
          'version': '1',
          'lessons': <dynamic>[],
        }),
      ),
      throwsA(isA<ContentPackException>()),
    );
  });
}
