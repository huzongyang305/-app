/// 本地存储诊断结果。
class StorageDiagnostic {
  const StorageDiagnostic({
    required this.keyCount,
    required this.estimatedBytes,
    required this.categories,
    required this.orphanKeys,
    required this.cacheKeys,
    required this.notes,
  });

  final int keyCount;
  final int estimatedBytes;
  final Map<String, int> categories;
  final List<String> orphanKeys;
  final List<String> cacheKeys;
  final List<String> notes;

  double get estimatedMiB => estimatedBytes / 1024 / 1024;
}
