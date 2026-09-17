import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// DataSource cho Firebase Authentication.
///
/// **Đây là nơi duy nhất import `firebase_auth` và `google_sign_in`.**
///
/// Chức năng:
/// - Đăng ký / đăng nhập bằng email & password
/// - Đăng nhập bằng Google
/// - Đăng xuất
/// - Gửi email đặt lại mật khẩu
/// - Stream theo dõi trạng thái auth
///
/// Không map lỗi sang tiếng Việt — để exception tự throw lên Repository.
class FirebaseAuthDataSource {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthDataSource({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // ── Email / Password ───────────────────────────────────────

  /// Tạo tài khoản mới bằng email và password.
  /// Trả về [UserCredential] chứa thông tin user vừa tạo.
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Đăng nhập bằng email và password.
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── Google Sign-In ─────────────────────────────────────────

  /// Đăng nhập bằng Google.
  ///
  /// Luồng:
  /// 1. Hiển thị dialog chọn tài khoản Google
  /// 2. Lấy authentication token từ Google
  /// 3. Tạo Firebase credential từ Google token
  /// 4. Đăng nhập Firebase bằng credential
  ///
  /// Throw exception với code 'sign_in_canceled' nếu user huỷ chọn tài khoản.
  Future<UserCredential> signInWithGoogle() async {
    // Bước 1: Hiển thị dialog chọn tài khoản Google
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      // User huỷ chọn tài khoản
      throw FirebaseAuthException(
        code: 'sign_in_canceled',
        message: 'Google sign-in was canceled by user.',
      );
    }

    // Bước 2: Lấy authentication details
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Bước 3: Tạo Firebase credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Bước 4: Đăng nhập Firebase
    return await _auth.signInWithCredential(credential);
  }

  // ── Sign Out ───────────────────────────────────────────────

  /// Đăng xuất khỏi Firebase (và Google nếu [isGoogleUser] = true).
  ///
  /// Gọi [GoogleSignIn.signOut] để xoá cached Google account,
  /// cho phép user chọn tài khoản khác lần đăng nhập sau.
  Future<void> signOut({required bool isGoogleUser}) async {
    if (isGoogleUser) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  // ── Password Reset ─────────────────────────────────────────

  /// Gửi email đặt lại mật khẩu.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Auth State ─────────────────────────────────────────────

  /// Stream theo dõi thay đổi trạng thái authentication.
  ///
  /// Emit `null` khi user đăng xuất, [User] khi đăng nhập.
  /// Được dùng bởi AuthBloc (qua Repository) để auto-login.
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// User hiện tại đang đăng nhập (null nếu chưa đăng nhập).
  User? get currentUser => _auth.currentUser;
}

/// Exception tùy chỉnh cho lỗi Firebase Auth.
///
/// Dùng trong trường hợp cần throw lỗi không phải từ Firebase SDK
/// (ví dụ: user huỷ Google Sign-In) nhưng vẫn giữ format [code] + [message]
/// để Repository xử lý thống nhất.
class FirebaseAuthException implements Exception {
  final String code;
  final String message;

  const FirebaseAuthException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'FirebaseAuthException(code: $code, message: $message)';
}
