/// Độ ưu tiên hợp lệ của User Story — giá trị lưu trong Firestore field
/// `priority` (giữ nguyên convention sẵn có của dữ liệu mẫu: CAO/TB/THẤP).
///
/// Thứ tự trong [values] chính là thứ tự nghiệp vụ (cao → thấp), được dùng
/// khi sắp xếp Backlog theo ưu tiên (US-009) thay vì so sánh chuỗi.
class UserStoryPriority {
  UserStoryPriority._();

  static const String high = 'CAO';
  static const String medium = 'TB';
  static const String low = 'THẤP';

  static const List<String> values = [high, medium, low];

  static bool isValid(String? value) => values.contains(value);

  /// Hạng sắp xếp: CAO = 0, TB = 1, THẤP = 2. Giá trị lạ (dữ liệu cũ/hỏng)
  /// xếp cuối cùng thay vì crash.
  static int rank(String priority) {
    final index = values.indexOf(priority.toUpperCase());
    return index >= 0 ? index : values.length;
  }

  static String displayName(String priority) {
    switch (priority) {
      case high:
        return 'Cao';
      case medium:
        return 'Trung bình';
      case low:
        return 'Thấp';
      default:
        return priority;
    }
  }
}
