/// Map mã lỗi Firebase sang thông báo tiếng Việt dễ hiểu cho người dùng.
///
/// Được sử dụng bởi [AuthRepositoryImpl] để chuyển đổi
/// [FirebaseAuthException.code] thành message hiển thị trên UI.
/// Không import Firebase SDK — chỉ nhận mã lỗi dạng String.
class FirebaseErrorMapper {
  FirebaseErrorMapper._();

  /// Nhận mã lỗi Firebase (ví dụ: 'email-already-in-use')
  /// và trả về thông báo tiếng Việt tương ứng.
  static String mapErrorCode(String code) {
    switch (code) {
      // ── Đăng ký ──────────────────────────────────────────
      case 'email-already-in-use':
        return 'Email này đã được sử dụng. '
            'Vui lòng dùng email khác hoặc đăng nhập.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ. '
            'Vui lòng kiểm tra lại.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được kích hoạt. '
            'Vui lòng liên hệ quản trị viên.';

      // ── Đăng nhập ────────────────────────────────────────
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này. '
            'Vui lòng kiểm tra lại hoặc đăng ký mới.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác. Vui lòng thử lại.';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không hợp lệ. '
            'Vui lòng kiểm tra email và mật khẩu.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hoá. '
            'Vui lòng liên hệ quản trị viên.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử đăng nhập thất bại. '
            'Vui lòng đợi một lúc rồi thử lại.';

      // ── Mạng ─────────────────────────────────────────────
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. '
            'Vui lòng kiểm tra kết nối internet và thử lại.';

      // ── Google Sign-In ───────────────────────────────────
      case 'sign_in_canceled':
      case 'sign_in_cancelled':
        return 'Đăng nhập Google đã bị huỷ.';
      case 'account-exists-with-different-credential':
        return 'Email này đã được liên kết với phương thức đăng nhập khác. '
            'Vui lòng dùng phương thức ban đầu.';

      // ── Quên mật khẩu ────────────────────────────────────
      case 'missing-email':
        return 'Vui lòng nhập địa chỉ email.';

      // ── Mặc định ─────────────────────────────────────────
      default:
        return 'Đã xảy ra lỗi không xác định ($code). '
            'Vui lòng thử lại sau.';
    }
  }
}
