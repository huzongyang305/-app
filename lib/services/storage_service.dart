import 'package:hive_flutter/hive_flutter.dart';

import 'storage_migration_service.dart';

/// 本地存储接口。
///
/// 正式运行使用 [HiveStorageService]（数据落在设备本地，完全离线）；
/// 测试使用 [InMemoryStorageService]，避免依赖真实文件 IO。
abstract class StorageService {
  static const String boxName = 'app_data';

  dynamic read(String key, {dynamic defaultValue});

  Future<void> write(String key, dynamic value);

  Future<void> delete(String key);

  Set<String> readStringSet(String key);

  /// 当前盒子中的全部键，迁移与诊断工具使用。
  Iterable<String> get keys;

  /// 在 runApp 之前调用：初始化 Hive 并打开数据盒子。
  static Future<StorageService> init() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(boxName);
    final storage = HiveStorageService(box);
    await StorageMigrationService.run(storage);
    return storage;
  }

  /// 供测试使用的内存实现。
  static StorageService inMemory() => InMemoryStorageService();
}

/// 基于 Hive 的本地存储实现。
class HiveStorageService implements StorageService {
  HiveStorageService(this._box);

  final Box<dynamic> _box;

  @override
  dynamic read(String key, {dynamic defaultValue}) {
    final value = _box.get(key);
    return value ?? defaultValue;
  }

  @override
  Future<void> write(String key, dynamic value) => _box.put(key, value);

  @override
  Future<void> delete(String key) => _box.delete(key);

  /// Hive 存的是 `List<dynamic>`，统一转换成 `Set<String>` 方便业务层使用。
  @override
  Set<String> readStringSet(String key) => _toStringSet(_box.get(key));

  @override
  Iterable<String> get keys => _box.keys.cast<String>();
}

/// 纯内存实现，仅用于测试。
class InMemoryStorageService implements StorageService {
  final Map<String, dynamic> _data = <String, dynamic>{};

  @override
  dynamic read(String key, {dynamic defaultValue}) =>
      _data[key] ?? defaultValue;

  @override
  Future<void> write(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Set<String> readStringSet(String key) => _toStringSet(_data[key]);

  @override
  Iterable<String> get keys => _data.keys;
}

Set<String> _toStringSet(dynamic raw) {
  if (raw is List) {
    return raw.map((item) => item.toString()).toSet();
  }
  return <String>{};
}
