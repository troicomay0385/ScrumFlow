import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/user_model.dart';
import '../models/user_story_model.dart';
import '../models/task_model.dart';

/// DataSource cho lưu trữ cục bộ: SQLite (cache) + Secure Storage (recent accounts).
///
/// **SQLite**: Cache thông tin user profile, User Stories và Tasks để hiển thị
/// offline khi mất mạng (US-062).
/// **Secure Storage**: Lưu danh sách email tài khoản đã đăng nhập gần đây
///   (KHÔNG lưu password, token, hay credential).
///
/// [clearSessionData] xoá cache user nhưng giữ nguyên recent accounts
/// để lần đăng nhập sau vẫn hiển thị danh sách tài khoản cũ.
///
/// **Web:** `sqflite` không hỗ trợ Flutter Web (gọi vào sẽ throw) → trên
/// Web phần cache SQLite là no-op: không cache, [getCachedUser] luôn trả về
/// `null`. Cache offline là tính năng dành cho mobile (US-062); nếu không
/// chặn ở đây thì đăng xuất và tải hồ sơ user trên Chrome đều bị lỗi.
class LocalCacheDataSource {
  final FlutterSecureStorage _secureStorage;

  // SQLite database instance — lazy init qua [_getDatabase]
  Database? _database;

  // Key lưu danh sách recent accounts trong secure storage
  static const String _recentAccountsKey = 'recent_accounts';

  // SQLite table & database config
  static const String _tableName = 'cached_user';
  static const String _storyTableName = 'cached_user_stories';
  static const String _taskTableName = 'cached_tasks';
  static const String _dbName = 'scrumflow_cache.db';
  static const int _dbVersion = 2;

  // Giới hạn số tài khoản gần đây được lưu
  static const int _maxRecentAccounts = 5;

  LocalCacheDataSource({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // ═══════════════════════════════════════════════════════════
  // SQLite — Database init
  // ═══════════════════════════════════════════════════════════

  /// Lazy-init SQLite database.
  ///
  /// Tạo table `cached_user`, `cached_user_stories`, `cached_tasks`
  /// nếu chưa tồn tại.
  Future<Database> _getDatabase() async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            fullName TEXT NOT NULL,
            email TEXT NOT NULL,
            photoUrl TEXT,
            createdAt TEXT NOT NULL,
            loginProvider TEXT NOT NULL
          )
        ''');
        await _createStoryTable(db);
        await _createTaskTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 → v2: thêm bảng cache cho UserStory và Task (US-062)
        if (oldVersion < 2) {
          await _createStoryTable(db);
          await _createTaskTable(db);
        }
      },
    );

    return _database!;
  }

  Future<void> _createStoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_storyTableName (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        jsonData TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_story_project ON $_storyTableName(projectId)',
    );
  }

  Future<void> _createTaskTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_taskTableName (
        id TEXT PRIMARY KEY,
        projectId TEXT,
        storyId TEXT NOT NULL,
        jsonData TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_task_story ON $_taskTableName(storyId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_task_project ON $_taskTableName(projectId)',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SQLite — Cache user profile
  // ═══════════════════════════════════════════════════════════

  /// Cache thông tin user hiện tại vào SQLite.
  ///
  /// Xoá dữ liệu cũ trước khi insert (chỉ giữ 1 user).
  /// Dùng [ConflictAlgorithm.replace] phòng trường hợp trùng ID.
  Future<void> cacheUser(UserModel user) async {
    if (kIsWeb) return;
    final db = await _getDatabase();
    // Xoá tất cả user cũ — chỉ cache user đang đăng nhập
    await db.delete(_tableName);
    await db.insert(
      _tableName,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Đọc user đã cache từ SQLite.
  ///
  /// Trả về `null` nếu chưa có cache (chưa từng đăng nhập
  /// hoặc đã bị xoá khi đăng xuất).
  Future<UserModel?> getCachedUser() async {
    if (kIsWeb) return null;
    final db = await _getDatabase();
    final results = await db.query(_tableName, limit: 1);

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  /// Xoá toàn bộ cache user trong SQLite.
  ///
  /// Được gọi khi đăng xuất — xoá dữ liệu phiên cũ.
  Future<void> clearUserCache() async {
    if (kIsWeb) return;
    final db = await _getDatabase();
    await db.delete(_tableName);
  }

  // ═══════════════════════════════════════════════════════════
  // SQLite — Cache User Stories (US-062)
  // ═══════════════════════════════════════════════════════════

  /// Cache danh sách User Stories của 1 project.
  ///
  /// Xoá dữ liệu cũ của project trước khi insert batch mới (đảm bảo
  /// dữ liệu offline luôn đồng bộ với lần tải cuối từ Firestore).
  Future<void> cacheUserStories(String projectId, List<UserStoryModel> stories) async {
    if (kIsWeb) return;
    final db = await _getDatabase();

    final batch = db.batch();
    // Xoá stories cũ của project này
    batch.delete(
      _storyTableName,
      where: 'projectId = ?',
      whereArgs: [projectId],
    );
    // Insert batch mới
    for (final story in stories) {
      batch.insert(
        _storyTableName,
        {
          'id': story.id,
          'projectId': projectId,
          'jsonData': jsonEncode(story.toMap()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Đọc danh sách User Stories đã cache theo project.
  ///
  /// Trả về List rỗng nếu chưa có cache.
  Future<List<UserStoryModel>> getCachedUserStories(String projectId) async {
    if (kIsWeb) return [];
    final db = await _getDatabase();
    final results = await db.query(
      _storyTableName,
      where: 'projectId = ?',
      whereArgs: [projectId],
    );

    return results.map((row) {
      final map = jsonDecode(row['jsonData'] as String) as Map<String, dynamic>;
      return UserStoryModel.fromMap(map);
    }).toList();
  }

  /// Xoá 1 User Story khỏi cache.
  Future<void> deleteCachedStory(String storyId) async {
    if (kIsWeb) return;
    final db = await _getDatabase();
    await db.delete(
      _storyTableName,
      where: 'id = ?',
      whereArgs: [storyId],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SQLite — Cache Tasks (US-062)
  // ═══════════════════════════════════════════════════════════

  /// Cache danh sách Tasks của 1 User Story.
  ///
  /// Xoá tasks cũ của story trước khi insert batch mới.
  Future<void> cacheTasks(String storyId, List<TaskModel> tasks) async {
    if (kIsWeb) return;
    final db = await _getDatabase();

    final batch = db.batch();
    batch.delete(
      _taskTableName,
      where: 'storyId = ?',
      whereArgs: [storyId],
    );
    for (final task in tasks) {
      batch.insert(
        _taskTableName,
        {
          'id': task.id,
          'projectId': task.projectId ?? '',
          'storyId': task.storyId,
          'jsonData': jsonEncode(task.toMap()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Đọc danh sách Tasks đã cache theo User Story.
  Future<List<TaskModel>> getCachedTasks(String storyId) async {
    if (kIsWeb) return [];
    final db = await _getDatabase();
    final results = await db.query(
      _taskTableName,
      where: 'storyId = ?',
      whereArgs: [storyId],
    );

    return results.map((row) {
      final map = jsonDecode(row['jsonData'] as String) as Map<String, dynamic>;
      return TaskModel.fromMap(map);
    }).toList();
  }

  /// Đọc danh sách Tasks đã cache theo danh sách User Stories (US-065).
  Future<List<TaskModel>> getCachedTasksByStories(List<String> storyIds) async {
    if (kIsWeb || storyIds.isEmpty) return [];
    final db = await _getDatabase();
    final placeholders = List.filled(storyIds.length, '?').join(',');
    final results = await db.query(
      _taskTableName,
      where: 'storyId IN ($placeholders)',
      whereArgs: storyIds,
    );

    return results.map((row) {
      final map = jsonDecode(row['jsonData'] as String) as Map<String, dynamic>;
      return TaskModel.fromMap(map);
    }).toList();
  }

  /// Đọc tất cả Tasks đã cache trong 1 project.
  Future<List<TaskModel>> getCachedTasksByProject(String projectId) async {
    if (kIsWeb) return [];
    final db = await _getDatabase();
    final results = await db.query(
      _taskTableName,
      where: 'projectId = ?',
      whereArgs: [projectId],
    );

    return results.map((row) {
      final map = jsonDecode(row['jsonData'] as String) as Map<String, dynamic>;
      return TaskModel.fromMap(map);
    }).toList();
  }

  /// Đọc 1 Task đã cache theo ID.
  Future<TaskModel?> getCachedTask(String taskId) async {
    if (kIsWeb) return null;
    final db = await _getDatabase();
    final results = await db.query(
      _taskTableName,
      where: 'id = ?',
      whereArgs: [taskId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    final map = jsonDecode(results.first['jsonData'] as String) as Map<String, dynamic>;
    return TaskModel.fromMap(map);
  }

  /// Xoá 1 Task khỏi cache.
  Future<void> deleteCachedTask(String taskId) async {
    if (kIsWeb) return;
    final db = await _getDatabase();
    await db.delete(
      _taskTableName,
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// Xoá cache của 1 project cụ thể (stories + tasks).
  Future<void> clearProjectCache(String projectId) async {
    if (kIsWeb) return;
    final db = await _getDatabase();

    final batch = db.batch();
    batch.delete(_storyTableName, where: 'projectId = ?', whereArgs: [projectId]);
    batch.delete(_taskTableName, where: 'projectId = ?', whereArgs: [projectId]);
    await batch.commit(noResult: true);
  }

  // ═══════════════════════════════════════════════════════════
  // Secure Storage — Recent account emails
  // ═══════════════════════════════════════════════════════════

  /// Lưu email vào danh sách tài khoản gần đây.
  ///
  /// - Nếu email đã tồn tại → đưa lên đầu (mới nhất)
  /// - Giới hạn tối đa [_maxRecentAccounts] email
  /// - Lưu dưới dạng JSON array trong secure storage
  Future<void> saveRecentAccount(String email) async {
    final accounts = await getRecentAccounts();

    // Xoá nếu đã tồn tại (sẽ thêm lại ở đầu)
    accounts.remove(email);

    // Thêm vào đầu danh sách
    accounts.insert(0, email);

    // Giới hạn số lượng
    final trimmed = accounts.take(_maxRecentAccounts).toList();

    await _secureStorage.write(
      key: _recentAccountsKey,
      value: jsonEncode(trimmed),
    );
  }

  /// Đọc danh sách email tài khoản gần đây.
  ///
  /// Trả về List rỗng nếu chưa có dữ liệu.
  Future<List<String>> getRecentAccounts() async {
    final raw = await _secureStorage.read(key: _recentAccountsKey);

    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<String>();
  }

  /// Xoá 1 email khỏi danh sách tài khoản gần đây.
  Future<void> removeRecentAccount(String email) async {
    final accounts = await getRecentAccounts();
    accounts.remove(email);

    await _secureStorage.write(
      key: _recentAccountsKey,
      value: jsonEncode(accounts),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Session management
  // ═══════════════════════════════════════════════════════════

  /// Xoá dữ liệu phiên (cache user) nhưng **giữ nguyên** recent accounts.
  ///
  /// Gọi khi đăng xuất — user sẽ vẫn thấy danh sách tài khoản cũ
  /// ở màn hình đăng nhập lần sau.
  Future<void> clearSessionData() async {
    await clearUserCache();
  }
}

