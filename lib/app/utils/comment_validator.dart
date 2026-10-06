/// Validate nội dung bình luận (US-045, US-046) — thuần Dart, dùng chung
/// cho UI lẫn Repository. Giới hạn độ dài khớp với `firestore.rules`.
class CommentValidator {
  CommentValidator._();

  static const int maxLength = 1000;

  /// Trả về thông báo lỗi tiếng Việt, hoặc `null` nếu hợp lệ.
  static String? validate(String? content) {
    final value = content?.trim() ?? '';
    if (value.isEmpty) return 'Vui lòng nhập nội dung bình luận';
    if (value.length > maxLength) return 'Bình luận tối đa $maxLength ký tự';
    return null;
  }
}
