import 'package:equatable/equatable.dart';

import '../../../app/authorization/permission.dart';
import '../../../app/authorization/project_role.dart';
import '../../../app/authorization/role_permissions.dart';
import '../../../data/models/project_member_display.dart';
import '../../../data/models/task_model.dart';

enum TaskDetailStatus { idle, saving, saved, failure }

/// State màn Task Detail (US-043 đổi assignee, US-044 đặt deadline).
class TaskDetailState extends Equatable {
  /// Task đang xem — cập nhật real-time; `null` nếu task đã bị xoá.
  final TaskModel? task;

  /// Thành viên thực tế của project — nguồn duy nhất cho danh sách assignee.
  final List<ProjectMemberDisplay> members;
  final bool membersLoaded;

  /// Role của user hiện tại trong project (`null` = không phải thành viên).
  final ProjectRole? role;

  /// Task đã gắn `projectId` trên Firestore → Security Rules cho phép
  /// đọc/ghi bình luận của task.
  final bool projectLinked;

  final TaskDetailStatus status;
  final String? message;

  const TaskDetailState({
    required this.task,
    this.members = const [],
    this.membersLoaded = false,
    this.role,
    this.projectLinked = false,
    this.status = TaskDetailStatus.idle,
    this.message,
  });

  bool get isSaving => status == TaskDetailStatus.saving;
  bool get canAssign => hasPermission(role, Permission.assignTask);
  bool get canSetDeadline => hasPermission(role, Permission.setTaskDeadline);

  TaskDetailState copyWith({
    TaskModel? task,
    bool clearTask = false,
    List<ProjectMemberDisplay>? members,
    bool? membersLoaded,
    ProjectRole? role,
    bool clearRole = false,
    bool? projectLinked,
    TaskDetailStatus? status,
    String? message,
  }) {
    return TaskDetailState(
      task: clearTask ? null : (task ?? this.task),
      members: members ?? this.members,
      membersLoaded: membersLoaded ?? this.membersLoaded,
      role: clearRole ? null : (role ?? this.role),
      projectLinked: projectLinked ?? this.projectLinked,
      status: status ?? this.status,
      message: message,
    );
  }

  @override
  List<Object?> get props =>
      [task, members, membersLoaded, role, projectLinked, status, message];
}
