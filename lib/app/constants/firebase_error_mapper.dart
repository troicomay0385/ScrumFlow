/// Map mã lỗi Firebase sang thông báo tiếng Việt dễ hiểu cho người dùng.
///
/// Được sử dụng bởi [AuthRepositoryImpl] để chuyển đổi
/// [FirebaseAuthException.code] thành message hiển thị trên UI.
/// Không import Firebase SDK — chỉ nhận mã lỗi dạng String.
class FirebaseErrorMapper {
  FirebaseErrorMapper._();

  /// Nhận mã lỗi Firebase (ví dụ: 'email-already-in-use', 'INVALID_LOGIN_CREDENTIALS')
  /// và trả về thông báo tiếng Việt tương ứng.
  static String mapErrorCode(String code) {
    // Chuẩn hoá mã lỗi: chuyển thành chữ thường và đổi '_' thành '-'
    final normalizedCode = code.trim().toLowerCase().replaceAll('_', '-');

    switch (normalizedCode) {
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
      case 'invalid-login-credentials':
        return 'Thông tin đăng nhập không hợp lệ. '
            'Vui lòng kiểm tra lại email và mật khẩu.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hoá. '
            'Vui lòng liên hệ quản trị viên.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử đăng nhập thất bại. '
            'Vui lòng đợi một lúc rồi thử lại.';
      case 'channel-error':
        return 'Thông tin nhập vào không hợp lệ hoặc bị trống. '
            'Vui lòng kiểm tra lại.';

      // ── Mạng & Hệ thống ─────────────────────────────────────
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. '
            'Vui lòng kiểm tra kết nối internet và thử lại.';
      case 'internal-error':
      case 'internal':
        return 'Đã xảy ra lỗi hệ thống từ Firebase. '
            'Vui lòng thử lại sau.';
      case 'permission-denied':
        return 'Không có quyền truy cập dữ liệu. '
            'Vui lòng kiểm tra lại phân quyền tài khoản.';
      case 'unavailable':
        return 'Dịch vụ cơ sở dữ liệu tạm thời không khả dụng. '
            'Vui lòng thử lại sau.';

      // ── Google Sign-In ───────────────────────────────────
      case 'sign-in-canceled':
      case 'sign-in-cancelled':
        return 'Đăng nhập Google đã bị huỷ.';
      case 'account-exists-with-different-credential':
        return 'Email này đã được liên kết với phương thức đăng nhập khác. '
            'Vui lòng dùng phương thức ban đầu.';

      // ── Quên mật khẩu ────────────────────────────────────
      case 'missing-email':
        return 'Vui lòng nhập địa chỉ email.';

      // ── Mặc định ─────────────────────────────────────────
      default:
        return 'Đã xảy ra lỗi hệ thống ($code). '
            'Vui lòng thử lại sau.';
    }
  }

  /// Map mã lỗi và thông báo từ [PlatformException] (đặc biệt là Google Sign-In trên Android).
  static String mapPlatformError(String code, [String? message]) {
    final lowerMessage = (message ?? '').toLowerCase();
    final lowerCode = code.toLowerCase();

    if (lowerMessage.contains('apiexception: 10') ||
        lowerMessage.contains('apiexception: 12500') ||
        lowerMessage.contains('developer_error')) {
      return 'Lỗi cấu hình Google Sign-In (ApiException 10): '
          'Chưa đăng ký mã chứng chỉ SHA-1 của thiết bị này trên Firebase Console. '
          'Vui lòng thêm SHA-1 vào cài đặt dự án Firebase.';
    }

    if (lowerMessage.contains('apiexception: 7') ||
        lowerCode.contains('network') ||
        lowerMessage.contains('network')) {
      return 'Không thể kết nối đến dịch vụ Google. Vui lòng kiểm tra lại kết nối mạng.';
    }

    if (lowerCode == 'sign_in_canceled' ||
        lowerCode == 'sign-in-canceled' ||
        lowerCode == 'sign_in_cancelled') {
      return 'Đăng nhập Google đã bị huỷ.';
    }

    if (lowerCode == 'sign_in_failed') {
      return 'Đăng nhập Google không thành công. '
          'Vui lòng kiểm tra Google Play Services hoặc thử lại.';
    }

    return mapErrorCode(code);
  }
}

