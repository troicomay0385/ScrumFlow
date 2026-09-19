import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/user_model.dart';

/// DataSource cho lưu trữ cục bộ: SQLite (cache) + Secure Storage (recent accounts).
///
/// **SQLite**: Cache thông tin user profile để hiển thị offline khi mất mạng.
/// **Secure Storage**: Lưu danh sách email tài khoản đã đăng nhập gần đây
///   (KHÔNG lưu password, token, hay credential).
///
/// [clearSessionData] xoá cache user nhưng giữ nguyên recent accounts
/// để lần đăng nhập sau vẫn hiển thị danh sách tài khoản cũ.
class LocalCacheDataSource {
  final FlutterSecureStorage _secureStorage;

  // SQLite database instance — lazy init qua [_getDatabase]
  Database? _database;

  // Key lưu danh sách recent accounts trong secure storage
  static const String _recentAccountsKey = 'recent_accounts';

  // SQLite table & database config
  static const String _tableName = 'cached_user';
  static const String _dbName = 'scrumflow_cache.db';
  static const int _dbVersion = 1;

  // Giới hạn số tài khoản gần đây được lưu
  static const int _maxRecentAccounts = 5;

  LocalCacheDataSource({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // ═══════════════════════════════════════════════════════════
  // SQLite — Cache user profile
  // ═══════════════════════════════════════════════════════════

  /// Lazy-init SQLite database.
  ///
  /// Tạo table `cached_user` nếu chưa tồn tại.
  /// Chỉ cache đúng 1 user (user đang đăng nhập).
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
      },
    );

    return _database!;
  }

  /// Cache thông tin user hiện tại vào SQLite.
  ///
  /// Xoá dữ liệu cũ trước khi insert (chỉ giữ 1 user).
  /// Dùng [ConflictAlgorithm.replace] phòng trường hợp trùng ID.
  Future<void> cacheUser(UserModel user) async {
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
    final db = await _getDatabase();
    final results = await db.query(_tableName, limit: 1);

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  /// Xoá toàn bộ cache user trong SQLite.
  ///
  /// Được gọi khi đăng xuất — xoá dữ liệu phiên cũ.
  Future<void> clearUserCache() async {
    final db = await _getDatabase();
    await db.delete(_tableName);
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
