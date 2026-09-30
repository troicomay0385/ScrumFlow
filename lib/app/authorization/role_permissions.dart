import 'permission.dart';
import 'project_role.dart';

/// Bảng ánh xạ Role → tập quyền (Permission).
///
/// Đây là nơi DUY NHẤT quyết định "role X được làm gì" trong toàn bộ
/// app. Business logic và UI không được so sánh role trực tiếp
/// (vd. `if (role == ProjectRole.po)`), mà luôn hỏi qua [hasPermission]
/// để sau này thay đổi luật phân quyền chỉ cần sửa 1 chỗ.
const Map<ProjectRole, Set<Permission>> _rolePermissions = {
  ProjectRole.po: {
    Permission.viewProject,
    Permission.manageProject,
    Permission.viewBacklog,
    Permission.manageBacklog,
    Permission.viewSprint,
    Permission.viewTask,
    Permission.viewMembers,
    Permission.manageMembers,
    Permission.changeMemberRole,
  },
  ProjectRole.sm: {
    Permission.viewProject,
    Permission.viewBacklog,
    // Sprint 2 (US-007 → US-014): actor của các US quản lý Backlog là
    // "PO/SM" → SM được tạo/sửa/gắn tag User Story như PO.
    Permission.manageBacklog,
    Permission.viewSprint,
    Permission.manageSprint,
    Permission.viewTask,
    Permission.manageTask,
  },
  ProjectRole.member: {
    Permission.viewProject,
    Permission.viewBacklog,
    Permission.viewSprint,
    Permission.viewTask,
    Permission.updateAssignedTask,
  },
};

/// Kiểm tra role có permission hay không.
///
/// `role == null` (chưa xác định được role, vd. chưa load xong hoặc
/// user không phải member) → luôn `false`, không đoán quyền.
bool hasPermission(ProjectRole? role, Permission permission) {
  if (role == null) return false;
  return _rolePermissions[role]?.contains(permission) ?? false;
}
