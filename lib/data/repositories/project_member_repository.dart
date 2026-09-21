import '../../app/authorization/project_role.dart';
import '../models/project_member_display.dart';

/// Interface cho Project Member Repository — quản lý membership & role.
abstract class ProjectMemberRepository {
  /// Role của user hiện tại trong [projectId].
  ///
  /// `null` nếu user không phải thành viên project này.
  Future<ProjectRole?> getCurrentUserRole(String projectId);

  /// Stream role hiện tại — để UI tự cập nhật permission khi PO đổi role
  /// của mình (mục N — real-time update).
  Stream<ProjectRole?> streamCurrentUserRole(String projectId);

  /// Danh sách thành viên (kèm thông tin hiển thị: avatar/tên/email).
  ///
  /// Chỉ PO gọi được — Firestore Security Rules từ chối user khác.
  Stream<List<ProjectMemberDisplay>> streamMembers(String projectId);

  /// Thêm thành viên vào project bằng email (user phải đã có tài khoản).
  Future<void> addMemberByEmail({
    required String projectId,
    required String email,
    required ProjectRole role,
  });

  /// Đổi role của 1 thành viên.
  ///
  /// Không cho phép đổi role của chính user đang gọi (self-role
  /// protection — xem giải thích ở `firestore.rules`).
  Future<void> updateMemberRole({
    required String projectId,
    required String targetUserId,
    required ProjectRole newRole,
  });

  /// Xoá 1 thành viên khỏi project (không áp dụng cho chính mình).
  Future<void> removeMember({
    required String projectId,
    required String targetUserId,
  });
}
