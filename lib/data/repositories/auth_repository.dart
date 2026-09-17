import '../models/user_model.dart';

/// Interface (abstract class) cho Authentication Repository.
///
/// **AuthBloc chỉ phụ thuộc interface này** — không biết implementation cụ thể,
/// không import Firebase, không biết DataSource nào đang được dùng.
///
/// Lợi ích:
/// - Dễ mock khi unit test AuthBloc
/// - Có thể thay đổi backend (Firebase → Supabase...) mà không sửa BLoC
/// - Tuân thủ Dependency Inversion Principle
abstract class AuthRepository {
  /// Đăng ký tài khoản mới bằng email/password.
  ///
  /// Tự động tạo hồ sơ Firestore + cache offline.
  /// Throw [Exception] với message tiếng Việt nếu thất bại.
  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  /// Đăng nhập bằng email/password.
  ///
  /// Lưu email vào danh sách recent accounts.
  /// Throw [Exception] với message tiếng Việt nếu thất bại.
  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  /// Đăng nhập bằng tài khoản Google.
  ///
  /// Nếu là lần đầu → tự tạo hồ sơ Firestore.
  /// Throw [Exception] với message tiếng Việt nếu thất bại.
  Future<UserModel> signInWithGoogle();

  /// Đăng xuất.
  ///
  /// Xoá cache phiên (SQLite) nhưng giữ nguyên recent accounts.
  /// Nếu user đăng nhập bằng Google → signOut Google luôn.
  Future<void> signOut();

  /// Gửi email đặt lại mật khẩu.
  Future<void> sendPasswordReset(String email);

  /// Stream theo dõi trạng thái authentication.
  ///
  /// Emit [UserModel] khi đăng nhập, `null` khi đăng xuất.
  /// Dùng cho auto-login khi mở lại app.
  Stream<UserModel?> get authStateChanges;

  /// Lấy danh sách email tài khoản đã đăng nhập gần đây.
  Future<List<String>> getRecentAccounts();

  /// Lưu email vào danh sách tài khoản gần đây.
  Future<void> saveRecentAccount(String email);

  /// Xoá 1 email khỏi danh sách tài khoản gần đây.
  Future<void> removeRecentAccount(String email);

  /// Lấy thông tin user đã cache trong SQLite (hiển thị offline).
  Future<UserModel?> getCachedUser();
}
