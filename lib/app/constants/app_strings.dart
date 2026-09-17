/// Tập trung tất cả chuỗi tiếng Việt trong ứng dụng.
///
/// Mọi text hiển thị cho người dùng đều lấy từ đây,
/// giúp dễ bảo trì và chuẩn bị cho đa ngôn ngữ sau này.
class AppStrings {
  AppStrings._();

  // ── App ────────────────────────────────────────────────────
  static const String appName = 'ScrumFlow';

  // ── Auth screens ───────────────────────────────────────────
  static const String login = 'Đăng nhập';
  static const String register = 'Đăng ký';
  static const String logout = 'Đăng xuất';
  static const String logoutConfirmTitle = 'Xác nhận đăng xuất';
  static const String logoutConfirmMessage =
      'Bạn có chắc chắn muốn đăng xuất không?';
  static const String cancel = 'Huỷ';
  static const String confirm = 'Xác nhận';

  // ── Form labels ────────────────────────────────────────────
  static const String fullName = 'Họ và tên';
  static const String email = 'Email';
  static const String password = 'Mật khẩu';
  static const String confirmPassword = 'Xác nhận mật khẩu';
  static const String forgotPassword = 'Quên mật khẩu?';
  static const String signInWithGoogle = 'Đăng nhập bằng Google';
  static const String noAccount = 'Chưa có tài khoản? ';
  static const String hasAccount = 'Đã có tài khoản? ';
  static const String registerNow = 'Đăng ký ngay';
  static const String loginNow = 'Đăng nhập ngay';

  // ── Form hints ─────────────────────────────────────────────
  static const String hintFullName = 'Nhập họ và tên';
  static const String hintEmail = 'Nhập email';
  static const String hintPassword = 'Nhập mật khẩu';
  static const String hintConfirmPassword = 'Nhập lại mật khẩu';

  // ── Validation ─────────────────────────────────────────────
  static const String validationFullNameRequired = 'Vui lòng nhập họ và tên';
  static const String validationEmailRequired = 'Vui lòng nhập email';
  static const String validationEmailInvalid = 'Email không hợp lệ';
  static const String validationPasswordRequired = 'Vui lòng nhập mật khẩu';
  static const String validationConfirmPasswordRequired =
      'Vui lòng xác nhận mật khẩu';
  static const String validationPasswordMismatch = 'Mật khẩu không khớp';

  // ── Password requirements ──────────────────────────────────
  static const String passwordReqMinLength = 'Tối thiểu 8 ký tự';
  static const String passwordReqUppercase = 'Có ít nhất 1 chữ hoa';
  static const String passwordReqDigit = 'Có ít nhất 1 chữ số';
  static const String passwordReqSpecialChar = 'Có ít nhất 1 ký tự đặc biệt';
  static const String passwordReqMatch = 'Mật khẩu xác nhận trùng khớp';

  // ── Success messages ───────────────────────────────────────
  static const String registerSuccess = 'Đăng ký thành công!';
  static const String loginSuccess = 'Đăng nhập thành công!';
  static const String logoutSuccess = 'Đã đăng xuất';
  static const String passwordResetSent =
      'Email đặt lại mật khẩu đã được gửi. Vui lòng kiểm tra hộp thư.';

  // ── Recent accounts ────────────────────────────────────────
  static const String recentAccounts = 'Tài khoản gần đây';
  static const String removeAccount = 'Xoá';
  static const String noRecentAccounts = 'Không có tài khoản gần đây';

  // ── Network ────────────────────────────────────────────────
  static const String noInternetConnection =
      'Không có kết nối mạng. Vui lòng kiểm tra và thử lại.';
  static const String connectionTimeout =
      'Kết nối quá thời gian. Vui lòng thử lại.';

  // ── Generic errors ─────────────────────────────────────────
  static const String unknownError =
      'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
  static const String unexpectedError =
      'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại sau.';
}
