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

  /// US-065: xem biểu đồ tiến độ Sprint (Doughnut Chart) trên Home Screen.
  viewSprintDashboard,
  viewTask,
  manageTask,
  updateAssignedTask,

  /// US-043: đổi người phụ trách task.
  assignTask,

  /// US-044: đặt/đổi deadline task.
  setTaskDeadline,

  /// US-045/US-046: bình luận trong User Story và Task.
  comment,

  /// US-066: ghi nhận thời gian làm việc (Work Log) cho task.
  logWork,
  viewMembers,
  manageMembers,
  changeMemberRole,

  /// US-069 / US-070: xem phân tích rủi ro AI (Task Risk Radar & Sprint Forecast).
  viewAiInsights,

  /// US-071: quản lý và huấn luyện mô hình trong AI Model Lab.
  manageAiModel,
}
