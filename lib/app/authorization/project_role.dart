/// Vai trò nghiệp vụ của một user bên trong MỘT project cụ thể.
///
/// Một user có thể tham gia nhiều project với role khác nhau,
/// vì vậy role KHÔNG gắn với user mà gắn với membership
/// (xem `ProjectMemberModel`).
enum ProjectRole {
  po,
  sm,
  member;

  /// Tên hiển thị tiếng Việt cho UI.
  String get displayName {
    switch (this) {
      case ProjectRole.po:
        return 'Product Owner';
      case ProjectRole.sm:
        return 'Scrum Master';
      case ProjectRole.member:
        return 'Member';
    }
  }

  /// Giá trị lưu trong Firestore field `role`.
  String toFirestoreValue() {
    switch (this) {
      case ProjectRole.po:
        return 'PO';
      case ProjectRole.sm:
        return 'SM';
      case ProjectRole.member:
        return 'MEMBER';
    }
  }

  /// Parse giá trị Firestore → [ProjectRole].
  ///
  /// Trả về `null` nếu giá trị không hợp lệ (KHÔNG throw) —
  /// caller quyết định fallback (thường là quyền thấp nhất) để
  /// tránh crash app khi dữ liệu Firestore bị hỏng/không hợp lệ.
  static ProjectRole? fromFirestoreValue(String? value) {
    switch (value) {
      case 'PO':
        return ProjectRole.po;
      case 'SM':
        return ProjectRole.sm;
      case 'MEMBER':
        return ProjectRole.member;
      default:
        return null;
    }
  }
}
