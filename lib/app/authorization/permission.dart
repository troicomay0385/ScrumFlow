/// Danh sách hành động cần kiểm soát quyền truy cập trong app.
///
/// Đây là baseline cho toàn bộ nghiệp vụ Scrum (Project/Backlog/Sprint/
/// Task/Members). Ở giai đoạn hiện tại chỉ nhóm quyền liên quan tới
/// Project & Members được thực sự sử dụng (Backlog/Sprint/Task chưa
/// có màn hình/tính năng tương ứng) — khai báo sẵn ở đây để khi các
/// User Story sau bổ sung tính năng, KHÔNG cần sửa lại Role model hay
/// Security Rules, chỉ cần bổ sung mapping trong `role_permissions.dart`.
enum Permission {
  viewProject,
  manageProject,
  viewBacklog,
  manageBacklog,
  viewSprint,
  manageSprint,
  viewTask,
  manageTask,
  updateAssignedTask,
  viewMembers,
  manageMembers,
  changeMemberRole,
}
