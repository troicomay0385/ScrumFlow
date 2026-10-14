/// Loại lỗi đã được phân loại để UI quyết định cách hiển thị (icon, có
/// cho "Thử lại" hay không) mà không cần biết lỗi đến từ Firebase, Dart
/// hay nghiệp vụ (US-063).
enum AppFailureType {
  /// Thiết bị không có kết nối mạng / không với tới được máy chủ.
  noConnection,

  /// Request quá thời gian chờ (client timeout hoặc `deadline-exceeded`).
  timeout,

  /// Lỗi phía máy chủ / dịch vụ Firebase (unavailable, internal...).
  server,

  /// Không đủ quyền (Firestore Security Rules / RBAC trong app).
  permission,

  /// Phiên đăng nhập hết hạn hoặc chưa đăng nhập.
  auth,

  /// Dữ liệu không tồn tại hoặc đã bị xoá.
  notFound,

  /// Dữ liệu không hợp lệ / vi phạm ràng buộc nghiệp vụ.
  validation,

  /// Lỗi không xác định.
  unknown,
}

/// Lỗi đã được chuẩn hoá, mang thông báo tiếng Việt an toàn để hiển thị
/// trực tiếp cho người dùng (không chứa stack trace hay mã kỹ thuật).
class AppFailure implements Exception {
  final AppFailureType type;
  final String message;

  const AppFailure(this.type, this.message);

  const AppFailure.noConnection([
    this.message =
        'Không có kết nối mạng. Vui lòng kiểm tra Wi-Fi hoặc '
        'dữ liệu di động rồi thử lại.',
  ]) : type = AppFailureType.noConnection;

  const AppFailure.timeout([
    this.message =
        'Máy chủ phản hồi quá lâu nên thao tác chưa hoàn tất. '
        'Vui lòng kiểm tra kết nối và thử lại.',
  ]) : type = AppFailureType.timeout;

  const AppFailure.server([
    this.message =
        'Máy chủ đang gặp sự cố hoặc tạm thời không khả dụng. '
        'Vui lòng thử lại sau ít phút.',
  ]) : type = AppFailureType.server;

  const AppFailure.unknown([
    this.message = 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.',
  ]) : type = AppFailureType.unknown;

  /// Chỉ các lỗi tạm thời mới nên cho "Thử lại". Lỗi quyền, xác thực,
  /// dữ liệu không hợp lệ thì thử lại vẫn sẽ thất bại y hệt.
  bool get isRetryable =>
      type == AppFailureType.noConnection ||
      type == AppFailureType.timeout ||
      type == AppFailureType.server ||
      type == AppFailureType.unknown;

  @override
  String toString() => message;
}
