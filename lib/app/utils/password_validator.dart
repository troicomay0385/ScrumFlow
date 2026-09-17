/// Kết quả kiểm tra mật khẩu — mỗi tiêu chí là một bool.
///
/// Được sử dụng bởi [PasswordRequirementsChecklist] widget
/// để hiển thị trạng thái từng tiêu chí realtime.
class PasswordValidationResult {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasDigit;
  final bool hasSpecialChar;
  final bool passwordsMatch;

  const PasswordValidationResult({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasDigit,
    required this.hasSpecialChar,
    required this.passwordsMatch,
  });

  /// Tất cả tiêu chí đều đạt.
  bool get isValid =>
      hasMinLength &&
      hasUppercase &&
      hasDigit &&
      hasSpecialChar &&
      passwordsMatch;
}

/// Kiểm tra độ mạnh mật khẩu — class thuần Dart, không phụ thuộc Flutter.
///
/// Các tiêu chí:
/// - Tối thiểu 8 ký tự
/// - Có ít nhất 1 chữ hoa
/// - Có ít nhất 1 chữ số
/// - Có ít nhất 1 ký tự đặc biệt (!@#$%^&*...)
/// - Mật khẩu xác nhận trùng khớp
class PasswordValidator {
  PasswordValidator._();

  static const int _minLength = 8;

  /// Kiểm tra mật khẩu có đủ tối thiểu 8 ký tự.
  static bool hasMinLength(String password) {
    return password.length >= _minLength;
  }

  /// Kiểm tra mật khẩu có ít nhất 1 chữ hoa (A-Z).
  static bool hasUppercase(String password) {
    return password.contains(RegExp(r'[A-Z]'));
  }

  /// Kiểm tra mật khẩu có ít nhất 1 chữ số (0-9).
  static bool hasDigit(String password) {
    return password.contains(RegExp(r'[0-9]'));
  }

  /// Kiểm tra mật khẩu có ít nhất 1 ký tự đặc biệt.
  static bool hasSpecialChar(String password) {
    return password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\\/~`]'));
  }

  /// Kiểm tra mật khẩu và xác nhận mật khẩu có khớp nhau.
  /// Cả hai phải không rỗng để kết quả là true.
  static bool passwordsMatch(String password, String confirmPassword) {
    return password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        password == confirmPassword;
  }

  /// Kiểm tra toàn bộ tiêu chí và trả về [PasswordValidationResult].
  static PasswordValidationResult validate(
    String password,
    String confirmPassword,
  ) {
    return PasswordValidationResult(
      hasMinLength: hasMinLength(password),
      hasUppercase: hasUppercase(password),
      hasDigit: hasDigit(password),
      hasSpecialChar: hasSpecialChar(password),
      passwordsMatch: passwordsMatch(password, confirmPassword),
    );
  }

  /// Kiểm tra nhanh: tất cả tiêu chí đều đạt.
  static bool isValid(String password, String confirmPassword) {
    return validate(password, confirmPassword).isValid;
  }
}
