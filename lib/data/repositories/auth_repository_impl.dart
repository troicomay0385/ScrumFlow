import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../app/constants/app_strings.dart';
import '../../app/constants/firebase_error_mapper.dart';
import '../../app/services/connectivity_service.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/local_cache_datasource.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

/// Implementation của [AuthRepository].
///
/// Phối hợp 3 DataSource + ConnectivityService:
///
/// ```
/// AuthRepositoryImpl
///   ├── FirebaseAuthDataSource   → đăng ký, đăng nhập, đăng xuất
///   ├── FirestoreDataSource      → tạo/đọc hồ sơ user
///   ├── LocalCacheDataSource     → cache offline + recent accounts
///   └── ConnectivityService      → pre-check mạng
/// ```
///
/// **Luồng xử lý lỗi** (áp dụng cho mọi method):
/// 1. Pre-check mạng → throw sớm nếu offline
/// 2. Gọi datasource trong try/catch
/// 3. Catch [fb.FirebaseAuthException] → map sang tiếng Việt qua [FirebaseErrorMapper]
/// 4. Catch [FirebaseAuthException] (custom) → map tương tự
/// 5. Catch [Exception] chung → thông báo generic
///
/// Bước 1 là optional early return. Bước 2-5 luôn chạy bất kể
/// connectivity nói gì, vì mạng có thể thay đổi giữa chừng.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _authDataSource;
  final FirestoreDataSource _firestoreDataSource;
  final LocalCacheDataSource _localCacheDataSource;
  final ConnectivityService _connectivityService;

  AuthRepositoryImpl({
    required FirebaseAuthDataSource authDataSource,
    required FirestoreDataSource firestoreDataSource,
    required LocalCacheDataSource localCacheDataSource,
    required ConnectivityService connectivityService,
  })  : _authDataSource = authDataSource,
        _firestoreDataSource = firestoreDataSource,
        _localCacheDataSource = localCacheDataSource,
        _connectivityService = connectivityService;

  // ═══════════════════════════════════════════════════════════
  // Đăng ký (US-001)
  // ═══════════════════════════════════════════════════════════

  @override
  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    // Pre-check mạng — hiện thông báo sớm nếu offline
    await _ensureConnectivity();

    try {
      // 1. Tạo tài khoản Firebase Auth
      final credential =
          await _authDataSource.signUpWithEmail(email, password);
      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception(AppStrings.unknownError);
      }

      // 2. Tạo UserModel
      final user = UserModel.fromFirebaseUser(
        firebaseUser,
        fullName: fullName,
        loginProvider: 'email',
      );

      // 3. Lưu hồ sơ vào Firestore
      await _firestoreDataSource.createUserProfile(user);

      // 4. Cache vào SQLite cho offline
      await _localCacheDataSource.cacheUser(user);

      // 5. Lưu email vào recent accounts
      await _localCacheDataSource.saveRecentAccount(email);

      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrorMapper.mapErrorCode(e.code));
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrorMapper.mapErrorCode(e.code));
    } catch (e) {
      // Nếu đã là Exception do chính mình throw → rethrow
      if (e is Exception) rethrow;
      throw Exception(AppStrings.unexpectedError);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Đăng nhập email/password (US-002)
  // ═══════════════════════════════════════════════════════════

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await _ensureConnectivity();

    try {
      // 1. Đăng nhập Firebase Auth
      final credential =
          await _authDataSource.signInWithEmail(email, password);
      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception(AppStrings.unknownError);
      }

      // 2. Lấy hồ sơ từ Firestore
      UserModel? user =
          await _firestoreDataSource.getUserProfile(firebaseUser.uid);

      // 3. Nếu chưa có profile (edge case: tài khoản tạo ngoài app) → tạo mới
      if (user == null) {
        user = UserModel.fromFirebaseUser(
          firebaseUser,
          fullName: firebaseUser.displayName ?? email.split('@').first,
          loginProvider: 'email',
        );
        await _firestoreDataSource.createUserProfile(user);
      }

      // 4. Cache vào SQLite
      await _localCacheDataSource.cacheUser(user);

      // 5. Lưu email vào recent accounts
      await _localCacheDataSource.saveRecentAccount(email);

      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrorMapper.mapErrorCode(e.code));
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrorMapper.mapErrorCode(e.code));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(AppStrings.unexpectedError);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Đăng nhập Google (US-002)
  // ═══════════════════════════════════════════════════════════

  @override
  Future<UserModel> signInWithGoogle() async {
    await _ensureConnectivity();

    try {
      // 1. Đăng nhập Google → Firebase
      final credential = await _authDataSource.signInWithGoogle();
      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception(AppStrings.unknownError);
      }

      // 2. Kiểm tra xem đã có profile Firestore chưa
      final profileExists =
          await _firestoreDataSource.userProfileExists(firebaseUser.uid);

      UserModel user;

      if (profileExists) {
        // Đã có → đọc profile hiện tại
        final existingUser =
            await _firestoreDataSource.getUserProfile(firebaseUser.uid);
        user = existingUser!;
      } else {
        // Lần đầu đăng nhập Google → tạo profile mới
        user = UserModel.fromFirebaseUser(
          firebaseUser,
          fullName: firebaseUser.displayName ?? 'Người dùng',
          loginProvider: 'google',
        );
        await _firestoreDataSource.createUserProfile(user);
      }

      // 3. Cache vào SQLite
      await _localCacheDataSource.cacheUser(user);

      // 4. Lưu email vào recent accounts
      if (user.email.isNotEmpty) {
        await _localCacheDataSource.saveRecentAccount(user.email);
      }

      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrorMapper.mapErrorCode(e.code));
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrorMapper.mapErrorCode(e.code));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(AppStrings.unexpectedError);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Đăng xuất (US-003)
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> signOut() async {
    try {
      // Xác định user đăng nhập bằng Google hay email
      // để biết có cần signOut Google không
      final cachedUser = await _localCacheDataSource.getCachedUser();
      final isGoogleUser = cachedUser?.loginProvider == 'google';

      // 1. Đăng xuất Firebase (+ Google nếu cần)
      await _authDataSource.signOut(isGoogleUser: isGoogleUser);

      // 2. Xoá cache phiên nhưng GIỮ NGUYÊN recent accounts
      await _localCacheDataSource.clearSessionData();
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrorMapper.mapErrorCode(e.code));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(AppStrings.unexpectedError);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Quên mật khẩu
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> sendPasswordReset(String email) async {
    await _ensureConnectivity();

    try {
      await _authDataSource.sendPasswordResetEmail(email);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrorMapper.mapErrorCode(e.code));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(AppStrings.unexpectedError);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Auth State Stream (auto-login)
  // ═══════════════════════════════════════════════════════════

  @override
  Stream<UserModel?> get authStateChanges {
    return _authDataSource.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      // Thử lấy profile từ Firestore
      try {
        final user =
            await _firestoreDataSource.getUserProfile(firebaseUser.uid);
        if (user != null) {
          // Cập nhật cache
          await _localCacheDataSource.cacheUser(user);
          return user;
        }
      } catch (_) {
        // Nếu lỗi mạng → thử đọc từ cache offline
      }

      // Fallback: đọc từ SQLite cache
      final cachedUser = await _localCacheDataSource.getCachedUser();
      if (cachedUser != null) return cachedUser;

      // Trường hợp cuối: tạo UserModel tối thiểu từ Firebase User
      return UserModel.fromFirebaseUser(
        firebaseUser,
        fullName: firebaseUser.displayName ?? '',
        loginProvider: 'email',
      );
    });
  }

  // ═══════════════════════════════════════════════════════════
  // Recent Accounts
  // ═══════════════════════════════════════════════════════════

  @override
  Future<List<String>> getRecentAccounts() {
    return _localCacheDataSource.getRecentAccounts();
  }

  @override
  Future<void> saveRecentAccount(String email) {
    return _localCacheDataSource.saveRecentAccount(email);
  }

  @override
  Future<void> removeRecentAccount(String email) {
    return _localCacheDataSource.removeRecentAccount(email);
  }

  // ═══════════════════════════════════════════════════════════
  // Cached User (offline)
  // ═══════════════════════════════════════════════════════════

  @override
  Future<UserModel?> getCachedUser() {
    return _localCacheDataSource.getCachedUser();
  }

  // ═══════════════════════════════════════════════════════════
  // Private helpers
  // ═══════════════════════════════════════════════════════════

  /// Pre-check kết nối mạng.
  ///
  /// Nếu chắc chắn không có mạng → throw Exception sớm
  /// để user nhận được thông báo nhanh hơn (không phải đợi timeout).
  ///
  /// Đây CHỈ là pre-check — mọi Firebase call vẫn luôn nằm trong try/catch.
  Future<void> _ensureConnectivity() async {
    final hasConnection = await _connectivityService.checkConnectivity();
    if (!hasConnection) {
      throw Exception(AppStrings.noInternetConnection);
    }
  }
}
