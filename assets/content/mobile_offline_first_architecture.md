# 离线优先架构与数据同步

![离线优先架构与数据同步示意：lesson security supply chain](images/lesson_security_supply_chain.webp)

## Chapter Overview

在移动场景中，网络连接并不总是可靠——地铁隧道、电梯、飞机模式都会导致断网。离线优先（Offline-First）架构让应用在网络不可用时依然可用，网络恢复后自动同步数据。就像邮局的信件投递系统：即使邮路中断，信件仍会暂存在本地邮局，待道路畅通后继续投递。本章将深入探讨本地数据库选型、冲突解决策略、增量同步机制和后台同步任务，帮助你构建真正resilient的移动应用。

## Learning Objectives

学完本章后，你将能够：

1. 设计离线优先的应用架构和数据流
2. 选择合适的本地存储方案（SQLite、Realm、WatermelonDB等）
3. 实现数据的增量同步和冲突解决机制
4. 处理后台同步任务和队列管理
5. 优化本地查询性能和数据一致性
6. 设计优雅的网络状态提示和用户体验

## Core Concepts with Life Analogies

### 离线优先：像笔记本的双备份策略

想象你用笔记本记录工作事项。离线优先就像你同时维护两个版本：纸质笔记本（本地数据库）和云文档（远程服务器）。你在纸上写字时（创建/修改数据），立即保存到纸质本（本地持久化），然后尝试同步到云端（网络请求）。如果此时没网（离线），没关系，纸质本上已经有记录了；等有网时（在线），再把未同步的内容上传到云端。这样无论网络状况如何，你的工作都不会中断。

### 冲突解决：像多人编辑同一份文档

当多个设备同时修改同一条数据时，就会产生冲突。这就像多人同时编辑Google Docs中的同一段落：A把"今天天气很好"改成"今天阳光明媚"，B把同一句改成"今天万里无云"。服务器收到两个不同版本时，需要决定保留哪个。常见的策略有：最后写入获胜（LWW，类似谁最后保存谁赢）、手动合并（让用户选择）、操作转换（OT，智能合并差异）、版本向量（记录每个设备的修改历史）。

### 增量同步：像快递的包裹追踪

全量同步就像每次收快递都重新寄送所有商品，效率低下。增量同步则像快递追踪系统：只发送变化的部分（新增、修改、删除的记录）。每个数据项都有一个版本号或时间戳，客户端告诉服务器"我上次同步到版本100"，服务器返回"版本101到105的变化"。这样大幅减少了数据传输量，提升了同步速度，降低了流量消耗。

## Progressive Code Examples

### 最小示例：基础本地存储

**Flutter - 使用sqflite：**

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE items(id INTEGER PRIMARY KEY, title TEXT, content TEXT, synced INTEGER DEFAULT 0)',
        );
      },
    );
  }
  
  Future<void> insertItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('items', item);
  }
  
  Future<List<Map<String, dynamic>>> getUnsyncedItems() async {
    final db = await database;
    return await db.query('items', where: 'synced = ?', whereArgs: [0]);
  }
}
```

### 完整示例：离线优先笔记应用

**数据模型和本地存储层：**

```dart
// models/note.dart
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final int version;
  final bool isSynced;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.version = 1,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'version': version,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isDeleted: map['is_deleted'] == 1,
      version: map['version'],
      isSynced: map['is_synced'] == 1,
    );
  }

  Note copyWith({
    String? title,
    String? content,
    bool? isDeleted,
    int? version,
    bool? isSynced,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version + 1,
      isSynced: isSynced ?? false,
    );
  }
}
```

**本地数据库服务：**

```dart
// services/local_database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class LocalDatabaseService {
  static Database? _database;
  static const String tableName = 'notes';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'notes.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE $tableName (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            version INTEGER DEFAULT 1,
            is_synced INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) {
        // 处理数据库升级
        if (oldVersion < 2) {
          db.execute('ALTER TABLE $tableName ADD COLUMN version INTEGER DEFAULT 1');
        }
      },
    );
  }

  // CRUD操作
  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.insert(tableName, note.toMap());
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(
      tableName,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Note?> getNoteById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  Future<List<Note>> getAllNotes({bool includeDeleted = false}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: includeDeleted ? null : 'is_deleted = ?',
      whereArgs: includeDeleted ? null : [0],
      orderBy: 'updated_at DESC',
    );
    
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> getUnsyncedNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<void> markAsSynced(String id, int version) async {
    final db = await database;
    await db.update(
      tableName,
      {'is_synced': 1, 'version': version},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

**同步服务：**

```dart
// services/sync_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note.dart';
import 'local_database_service.dart';

class SyncService {
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final String baseUrl = 'https://api.example.com';
  
  // 同步状态
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// 执行双向同步
  Future<void> sync() async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    try {
      // 1. 上传本地未同步的更改
      await _uploadChanges();
      
      // 2. 下载服务器的最新数据
      await _downloadChanges();
      
      print('同步完成');
    } catch (e) {
      print('同步失败: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// 上传本地更改到服务器
  Future<void> _uploadChanges() async {
    final unsyncedNotes = await _localDb.getUnsyncedNotes();
    
    for (final note in unsyncedNotes) {
      try {
        final response = await http.put(
          Uri.parse('$baseUrl/notes/${note.id}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(note.toMap()),
        );
        
        if (response.statusCode == 200) {
          final serverData = jsonDecode(response.body);
          await _localDb.markAsSynced(note.id, serverData['version']);
        } else if (response.statusCode == 409) {
          // 冲突处理
          await _handleConflict(note, response.body);
        }
      } catch (e) {
        print('上传笔记 ${note.id} 失败: $e');
        // 继续处理其他笔记，不因单个失败而中断
      }
    }
  }

  /// 从服务器下载最新数据
  Future<void> _downloadChanges() async {
    // 获取本地最新版本号
    final notes = await _localDb.getAllNotes(includeDeleted: true);
    final lastVersion = notes.isNotEmpty 
        ? notes.map((n) => n.version).reduce((a, b) => a > b ? a : b)
        : 0;
    
    // 请求增量更新
    final response = await http.get(
      Uri.parse('$baseUrl/notes/since?version=$lastVersion'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> updates = jsonDecode(response.body);
      
      for (final update in updates) {
        final serverNote = Note.fromMap(update);
        final localNote = await _localDb.getNoteById(serverNote.id);
        
        if (localNote == null) {
          // 新笔记，直接插入
          await _localDb.insertNote(serverNote.copyWith(isSynced: true));
        } else if (serverNote.version > localNote.version) {
          // 服务器版本更新，覆盖本地
          await _localDb.updateNote(serverNote.copyWith(isSynced: true));
        }
        // 如果本地版本更新或相同，保持不变（已在_uploadChanges中处理）
      }
    }
  }

  /// 处理冲突
  Future<void> _handleConflict(Note localNote, String responseBody) async {
    final serverData = jsonDecode(responseBody);
    final serverNote = Note.fromMap(serverData);
    
    // 简单策略：最后写入获胜
    if (serverNote.updatedAt.isAfter(localNote.updatedAt)) {
      // 服务器版本更新，接受服务器数据
      await _localDb.updateNote(serverNote.copyWith(isSynced: true));
    } else {
      // 本地版本更新，重新上传
      await _uploadSingleNote(localNote);
    }
  }

  Future<void> _uploadSingleNote(Note note) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notes/${note.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(note.toMap()),
    );
    
    if (response.statusCode == 200) {
      final serverData = jsonDecode(response.body);
      await _localDb.markAsSynced(note.id, serverData['version']);
    }
  }
}
```

**ViewModel和业务逻辑：**

```dart
// viewmodels/notes_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/local_database_service.dart';
import '../services/sync_service.dart';

class NotesViewModel extends ChangeNotifier {
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final SyncService _syncService = SyncService();
  
  List<Note> _notes = [];
  List<Note> get notes => _notes;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  NotesViewModel() {
    loadNotes();
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _notes = await _localDb.getAllNotes();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '加载笔记失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createNote(String title, String content) async {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _localDb.insertNote(note);
    await loadNotes(); // 刷新列表
    
    // 异步同步，不阻塞UI
    _syncInBackground();
  }

  Future<void> updateNote(Note note, String title, String content) async {
    final updatedNote = note.copyWith(title: title, content: content);
    await _localDb.updateNote(updatedNote);
    await loadNotes();
    
    _syncInBackground();
  }

  Future<void> deleteNote(String id) async {
    await _localDb.deleteNote(id);
    await loadNotes();
    
    _syncInBackground();
  }

  Future<void> syncNow() async {
    _isSyncing = true;
    notifyListeners();
    
    try {
      await _syncService.sync();
      await loadNotes(); // 同步后刷新
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '同步失败: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void _syncInBackground() {
    // 延迟同步，避免频繁请求
    Future.delayed(Duration(seconds: 2), () {
      if (!_syncService.isSyncing) {
        syncNow();
      }
    });
  }
}
```

**UI界面：**

```dart
// screens/notes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../models/note.dart';

class NotesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotesViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('我的笔记'),
          actions: [
            Consumer<NotesViewModel>(
              builder: (context, viewModel, _) {
                return IconButton(
                  icon: viewModel.isSyncing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.sync),
                  onPressed: viewModel.isSyncing ? null : () => viewModel.syncNow(),
                  tooltip: '同步',
                );
              },
            ),
          ],
        ),
        body: Consumer<NotesViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return Center(child: CircularProgressIndicator());
            }
            
            if (viewModel.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(viewModel.errorMessage!),
                    ElevatedButton(
                      onPressed: viewModel.loadNotes,
                      child: Text('重试'),
                    ),
                  ],
                ),
              );
            }
            
            if (viewModel.notes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note_add, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('暂无笔记', style: TextStyle(fontSize: 18)),
                    Text('点击右下角按钮创建新笔记'),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              itemCount: viewModel.notes.length,
              itemBuilder: (context, index) {
                final note = viewModel.notes[index];
                return Dismissible(
                  key: Key(note.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    viewModel.deleteNote(note.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('笔记已删除')),
                    );
                  },
                  child: ListTile(
                    title: Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: note.isSynced
                        ? Icon(Icons.cloud_done, color: Colors.green, size: 18)
                        : Icon(Icons.cloud_upload, color: Colors.orange, size: 18),
                    onTap: () {
                      // 导航到编辑页面
                    },
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // 打开创建笔记对话框
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
```

### 实践示例：后台同步任务

**Android - WorkManager实现后台同步：**

```kotlin
// SyncWorker.kt
import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.WorkerFactory
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class SyncWorker(
    context: Context,
    params: WorkerParameters,
    private val syncService: SyncService
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return withContext(Dispatchers.IO) {
            try {
                syncService.sync()
                Result.success()
            } catch (e: Exception) {
                // 指数退避重试
                if (runAttemptCount < 3) {
                    Result.retry()
                } else {
                    Result.failure()
                }
            }
        }
    }
}

// 调度同步任务
fun scheduleSync(context: Context) {
    val constraints = Constraints.Builder()
        .setRequiredNetworkType(NetworkType.CONNECTED)
        .build()
    
    val syncRequest = PeriodicWorkRequestBuilder<SyncWorker>(
        repeatInterval = 15,
        repeatIntervalTimeUnit = TimeUnit.MINUTES
    )
        .setConstraints(constraints)
        .setBackoffCriteria(
            BackoffPolicy.EXPONENTIAL,
            5,
            TimeUnit.MINUTES
        )
        .build()
    
    WorkManager.getInstance(context).enqueueUniquePeriodicWork(
        "sync_work",
        ExistingPeriodicWorkPolicy.KEEP,
        syncRequest
    )
}
```

**iOS - Background Fetch实现后台同步：**

```swift
// AppDelegate.swift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, 
                    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // 执行后台同步
        SyncService.shared.sync { success, error in
            if let error = error {
                print("后台同步失败: \(error)")
                completionHandler(.failed)
            } else if success {
                completionHandler(.newData)
            } else {
                completionHandler(.noData)
            }
        }
    }
}

// Info.plist配置
/*
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
</array>
*/
```

## Common Pitfalls Table

| 陷阱 | 表现 | 原因 | 解决方案 |
|------|------|------|----------|
| 未处理网络波动 | 同步失败后数据丢失 | 假设网络始终可用 | 实现重试机制和离线队列，确保数据最终一致性 |
| 冲突解决策略不当 | 用户数据被意外覆盖 | 使用简单的LWW策略忽略业务语义 | 根据数据类型选择合适的冲突策略，必要时让用户手动合并 |
| 全量同步而非增量 | 流量消耗大、同步慢 | 每次都拉取全部数据 | 使用时间戳或版本号实现增量同步，只传输变化数据 |
| 本地数据库未加密 | 敏感数据泄露风险 | 明文存储用户隐私信息 | 使用SQLCipher加密SQLite，或对敏感字段单独加密 |
| 同步频率过高 | 电池消耗快、服务器压力大 | 频繁触发同步任务 | 使用指数退避算法，结合网络状态和用户行为智能调度 |
| 未清理过期数据 | 本地存储无限增长 | 删除的数据仍占用空间 | 定期清理软删除标记的数据，设置数据保留策略 |
| UI未反映同步状态 | 用户困惑数据是否安全 | 缺少同步进度和状态提示 | 显示同步图标、进度条和最后同步时间，提供手动同步入口 |
| 事务处理不完整 | 数据不一致 | 多表操作未使用事务 | 使用数据库事务确保原子性，失败时回滚 |
| 忽略时区问题 | 时间戳混乱 | 本地时间和服务器时间不一致 | 统一使用UTC时间存储，显示时转换为本地时区 |
| 后台任务被系统杀死 | 同步中断 | iOS/Android限制后台执行时间 | 使用WorkManager/BackgroundTasks框架，遵守平台规范 |

## Self-Test Questions

### 问题1

离线优先架构的核心原则是什么？

A. 只在有网络时才允许用户使用应用  
B. 所有数据操作先在本地执行，再异步同步到服务器  
C. 禁用所有需要网络的功能  
D. 将所有数据永久保存在本地，不同步到服务器  

**正确答案：B**

**详细解释：** 离线优先（Offline-First）的核心理念是"本地优先，异步同步"。用户的每一次数据操作（创建、修改、删除）都首先写入本地数据库，保证即时响应和可用性。然后在后台尝试将变更同步到远程服务器。如果网络不可用，变更会在本地排队，待网络恢复后自动同步。这种模式确保了应用在任何网络条件下都能正常工作，提供了最佳的用户体验。选项A违背了离线优先的初衷；选项C功能受限；选项D无法实现多设备数据共享。

### 问题2

在处理数据同步冲突时，"最后写入获胜"（LWW）策略的主要缺点是什么？

A. 实现复杂度高  
B. 需要同步所有历史版本  
C. 可能导致用户数据被意外覆盖而丢失  
D. 只适用于数值类型数据  

**正确答案：C**

**详细解释：** LWW（Last Write Wins）策略简单地保留时间戳最新的版本，丢弃其他版本。虽然实现简单，但它忽略了数据的语义和用户意图。例如，用户A在10:00修改了文档标题，用户B在10:01修改了同一文档的内容，LWW会保留B的完整版本，导致A的标题修改丢失。更好的策略包括：操作转换（OT）合并差异、CRDT（无冲突复制数据类型）自动合并、或让用户手动选择保留哪个版本。LWW适用于对数据一致性要求不高的场景，如日志记录、统计数据等。

### 问题3

为什么增量同步比全量同步更适合移动应用？

A. 增量同步的代码更简单  
B. 增量同步可以保证100%的数据一致性  
C. 增量同步不需要服务器支持  
D. 增量同步减少了数据传输量，节省流量和时间  

**正确答案：D**

**详细解释：** 增量同步只传输自上次同步以来发生变化的数据，而全量同步每次都传输完整数据集。对于包含大量数据的应用（如邮件、聊天记录、商品列表），增量同步可以显著减少网络流量、降低同步耗时、节省用户流量费用。实现增量同步通常需要服务器支持版本控制或变更日志（Change Log），客户端记录最后同步的版本号或时间戳。选项A错误，增量同步逻辑更复杂；选项C错误，需要服务器配合；选项D错误，两种方式的 consistency 取决于具体实现。

### 问题4

在离线优先应用中，如何处理敏感数据（如密码、token）的本地存储？

A. 明文存储在SharedPreferences或UserDefaults中  
B. 使用Base64编码后存储  
C. 使用加密存储，如Android的EncryptedSharedPreferences或iOS的Keychain  
D. 不存储任何敏感数据，每次都从服务器获取  

**正确答案：C**

**详细解释：** 敏感数据必须加密存储。Base64只是编码而非加密，可以轻松解码，不提供安全性。Android提供了EncryptedSharedPreferences（基于AES-256）和Jetpack Security库；iOS提供了Keychain Services，数据使用硬件级加密保护。对于更复杂的场景，可以使用SQLCipher加密整个SQLite数据库。选项A极其危险，root/jailbreak设备可轻松读取；选项D不现实，某些场景必须本地缓存token以维持登录状态。

### 问题5

关于后台同步任务的调度，以下哪种策略最合理？

A. 每秒钟执行一次同步以确保数据实时性  
B. 仅在用户手动触发时同步  
C. 结合网络状态、电池电量和用户行为智能调度，并使用指数退避重试  
D. 在应用启动时同步一次，之后不再同步  

**正确答案：C**

**详细解释：** 合理的后台同步策略应该平衡数据新鲜度、电池寿命和网络消耗。最佳实践包括：1) 检测网络类型（WiFi优先，移动网络谨慎）；2) 监控电池电量（低电量时减少同步）；3) 观察用户行为模式（活跃时段增加频率，空闲时段降低）；4) 使用指数退避算法处理失败重试（5分钟→10分钟→20分钟...）；5) 利用平台提供的后台任务框架（Android WorkManager、iOS BackgroundTasks）。选项A会快速耗尽电池；选项B用户体验差；选项D数据会过时。

---

**章节小结：**

通过本章学习，你已经掌握了构建离线优先应用的核心技能：本地数据库设计、增量同步机制、冲突解决策略和后台任务调度。记住，离线优先不仅是技术实现，更是一种用户体验理念——无论网络状况如何，应用都应该可靠、响应迅速。从本地存储的选择到同步策略的设计，每一步都需要权衡数据一致性、性能和用户体验。下一章我们将深入移动安全领域，学习如何保护应用和用户数据免受攻击。

## 本节知识框架

**课程定位**：分类「cross_platform」· 学习阶段 高级 · 建议用时 25 分钟。

本课主线：本地数据库选型、冲突解决、增量同步与后台任务

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照考点精讲定位原因。

## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| 离线优先 | 本地数据库选型、冲突解决、增量同步与后台任务相关：正文给出可操作定义与适用边界。 |
| 数据同步 | 本地数据库选型、冲突解决、增量同步与后台任务相关：正文给出可操作定义与适用边界。 |
| 冲突解决 | 本地数据库选型、冲突解决、增量同步与后台任务相关：正文给出可操作定义与适用边界。 |
| SQLite | 本地数据库选型、冲突解决、增量同步与后台任务相关：正文给出可操作定义与适用边界。 |
| 后台任务 | 本地数据库选型、冲突解决、增量同步与后台任务相关：正文给出可操作定义与适用边界。 |

## 原理与运行机制

正文各章按「输入是什么 → 中间如何转换 → 输出到哪 → 失败时怎样表现」四问展开；复习时给每个机制补一句自己的复述，再回到对应章节核对。

## 典型应用场景

- 结合「离线优先架构与数据同步」的常见落地场景与选型边界，详见正文各章节的对比讨论。
- 迁移到新项目时，先明确输入规模、失败代价与可观测手段，再决定采用深度。

## 代码/协议/SQL 示例

正文首个完整示例如下，先运行确认环境，再按正文步骤改一个输入观察输出变化。

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE items(id INTEGER PRIMARY KEY, title TEXT, content TEXT, synced INTEGER DEFAULT 0)',
        );
      },
    );
  }
  
  Future<void> insertItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('items', item);
  }
  
  Future<List<Map<String, dynamic>>> getUnsyncedItems() async {
    final db = await database;
    return await db.query('items', where: 'synced = ?', whereArgs: [0]);
  }
}
```

## 时间/空间复杂度或性能分析

- 用本课方案处理规模 n 时，先估计主循环与嵌套层数，再决定优化方向；小样本上的耗时读数不能外推。
- 性能结论要绑定输入分布：换数据规模、并发度或缓存命中情况后须重新测量。

## 常见误区与易错点

| 错误做法 | 典型现象 | 修复方向 |
| --- | --- | --- |
| 只验证正常输入 | 边界数据触发时才暴露问题 | 为每个结论补一个空值/极值/重复值用例 |
| 背结论不跑实验 | 换个输入就失效 | 按「预测—实测—差异归因」三步复盘 |
| 忽略环境与版本差异 | 本机可用线上报错 | 把版本、配置与依赖写入复现步骤 |

## 与其他知识点的关系

本课与分类「cross_platform」内相邻课程互为补充，建议按清单顺序学完再做综合练习。

## 自测题与参考答案

以下题目与题库同源，作答后再看解析；错误项要能说出错在哪一步。

## 考点精讲

### 考点 1

离线优先架构的核心原则是什么？

A. 只在有网络时才允许用户使用应用  
B. 所有数据操作先在本地执行，再异步同步到服务器 ✅  
C. 禁用所有需要网络的功能  
D. 将所有数据永久保存在本地，不同步到服务器  

**正确答案：** B

**解析：** 离线优先的核心是把本地数据库当作唯一可信数据源：读写先落在本地（如 SQLite/Room/CoreData），界面永远从本地取数据保证秒开与可用；网络恢复后再把变更异步同步到服务端。选项「只在有网时才允许使用」和「禁用所有联网功能」都违背了离线可用的目标，「永不同步」则会造成多设备数据分叉。

### 考点 2

在处理数据同步冲突时，"最后写入获胜"（LWW）策略的主要缺点是什么？

A. 实现复杂度高  
B. 需要同步所有历史版本  
C. 可能导致用户数据被意外覆盖而丢失 ✅  
D. 只适用于数值类型数据  

**正确答案：** C

**解析：** LWW 依据时间戳选择较新的写入，实现确实简单，但两台设备离线各自修改同一记录时，后同步的一方会直接覆盖前者的改动，用户毫不知情地丢数据。它的缺点不是实现复杂，也不要求保存全部历史版本，对字符串、枚举等非数值数据同样适用。工程上常配合冲突检测表或字段级合并策略来弥补。

### 考点 3

为什么增量同步比全量同步更适合移动应用？

A. 增量同步的代码更简单  
B. 增量同步可以保证100%的数据一致性  
C. 增量同步不需要服务器支持  
D. 增量同步减少了数据传输量，节省流量和时间 ✅  

**正确答案：** D

**解析：** 全量同步每次都要拉取整个数据集，移动场景下流量、电量和等待时间都不可接受。增量同步只传输自上次同步以来变化的记录，配合变更日志或版本号（如 last_modified）可把传输量降到最低。代价是需要服务端维护变更游标，且断点续传与删除墓碑要单独设计，代码并不比全量简单。

### 考点 4

在离线优先应用中，如何处理敏感数据（如密码、token）的本地存储？

A. 明文存储在SharedPreferences或UserDefaults中  
B. 使用Base64编码后存储  
C. 使用加密存储，如Android的EncryptedSharedPreferences或iOS的Keychain ✅  
D. 不存储任何敏感数据，每次都从服务器获取  

**正确答案：** C

**解析：** 敏感凭据必须走系统级安全存储：Android 用 EncryptedSharedPreferences 或 Keystore，iOS 用 Keychain 并设置合适的可访问性级别。明文存放等于把密钥写给任何拿到设备或备份的人；Base64 只是编码不是加密，随手可解。每次都找服务器取虽安全但破坏离线可用性，token 应短期有效并支持离线刷新。

### 考点 5

关于后台同步任务的调度，以下哪种策略最合理？

A. 每秒钟执行一次同步以确保数据实时性  
B. 仅在用户手动触发时同步  
C. 结合网络状态、电池电量和用户行为智能调度，并使用指数退避重试 ✅  
D. 在应用启动时同步一次，之后不再同步  

**正确答案：** C

**解析：** 后台同步要兼顾实时性与资源消耗：每秒轮询会迅速耗尽流量与电量，只靠手动触发又无法保证多端一致。合理策略是结合网络类型、充电状态与用户活跃时段触发，本地变更用 WorkManager/Background Tasks 排队，失败时按指数退避重试并设上限，同时留出合并窗口减少请求风暴。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| 离线优先 | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| 数据同步 | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| 冲突解决 | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| SQLite | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |
| 后台任务 | 定位线索见正文小节；速查表只保留名称，避免脱离上下文使用。 |

## 参考资料与复核

- [本课资料锚点 mobile_offline_first](https://zh.wikipedia.org/w/index.php?search=mobile_offline_first)

- 官方/权威资料：[W3C 移动 Web](https://www.w3.org/2001/tag/doc/appr-best-web/)
- 主题延伸：[关于「数据同步」的检索页](https://zh.wikipedia.org/w/index.php?search=%E6%95%B0%E6%8D%AE%E5%90%8C%E6%AD%A5)
- 本课索引词：[锚点 mobile_offline_first](https://www.w3.org/2001/tag/doc/appr-best-web/#%E7%A6%BB%E7%BA%BF%E4%BC%98%E5%85%88)
- 最后复核：2026-10-04
- 下次复核：2027-01-23

## 内容元数据

- 内容更新时间：2026-10-06

- 内容版本：v2.0
- 课程标识：mobile_offline_first
- 所属分类：cross_platform
- 学习阶段：高级
- 建议用时：25 分钟
