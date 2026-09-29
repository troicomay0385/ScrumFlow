import '../constants/user_story_priority.dart';

/// Validate dữ liệu nhập cho User Story (US-010 tạo mới, US-014 gắn tag)
/// — class thuần Dart, dùng chung cho form UI lẫn Cubit để luật validate
/// chỉ nằm ở một chỗ.
///
/// Các hàm `validate*` trả về thông báo lỗi tiếng Việt, hoặc `null` nếu hợp lệ.
class UserStoryValidator {
  UserStoryValidator._();

  static const int maxTitleLength = 200;
  static const int maxDescriptionLength = 2000;
  static const int maxTagLength = 30;
  static const int maxTagsPerStory = 10;

  static String? validateTitle(String? title) {
    final value = title?.trim() ?? '';
    if (value.isEmpty) return 'Vui lòng nhập tiêu đề User Story';
    if (value.length > maxTitleLength) {
      return 'Tiêu đề tối đa $maxTitleLength ký tự';
    }
    return null;
  }

  /// Mô tả không bắt buộc (khớp dữ liệu cũ + màn chi tiết đã có sẵn
  /// placeholder "Chưa có mô tả chi tiết"), chỉ giới hạn độ dài.
  static String? validateDescription(String? description) {
    final value = description?.trim() ?? '';
    if (value.length > maxDescriptionLength) {
      return 'Mô tả tối đa $maxDescriptionLength ký tự';
    }
    return null;
  }

  static String? validatePriority(String? priority) {
    if (!UserStoryPriority.isValid(priority)) {
      return 'Vui lòng chọn độ ưu tiên hợp lệ';
    }
    return null;
  }

  /// Chuẩn hoá tag: bỏ khoảng trắng thừa ở đầu/cuối và giữa các từ.
  static String normalizeTag(String tag) =>
      tag.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Validate 1 tag sắp được thêm vào [existingTags].
  /// Trùng tag được so sánh không phân biệt hoa/thường.
  static String? validateNewTag(String? tag, List<String> existingTags) {
    final value = normalizeTag(tag ?? '');
    if (value.isEmpty) return 'Tên tag không được để trống';
    if (value.length > maxTagLength) {
      return 'Tag tối đa $maxTagLength ký tự';
    }
    final lower = value.toLowerCase();
    if (existingTags.any((t) => t.toLowerCase() == lower)) {
      return 'Tag "$value" đã tồn tại';
    }
    if (existingTags.length >= maxTagsPerStory) {
      return 'Mỗi User Story chỉ gắn tối đa $maxTagsPerStory tag';
    }
    return null;
  }
}
