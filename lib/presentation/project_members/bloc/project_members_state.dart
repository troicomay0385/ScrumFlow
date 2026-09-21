import 'package:equatable/equatable.dart';

import '../../../app/authorization/project_role.dart';
import '../../../data/models/project_member_display.dart';

enum MemberActionStatus { idle, inProgress, success, failure }

abstract class ProjectMembersState extends Equatable {
  const ProjectMembersState();

  @override
  List<Object?> get props => [];
}

class ProjectMembersLoading extends ProjectMembersState {}

/// User hiện tại không phải thành viên project này (không tồn tại
/// membership) — không có dữ liệu nào để hiển thị.
class ProjectMembersError extends ProjectMembersState {
  final String message;

  const ProjectMembersError(this.message);

  @override
  List<Object?> get props => [message];
}

/// User là thành viên hợp lệ nhưng role không có quyền `viewMembers`
/// (SM/Member theo permission matrix hiện tại).
class ProjectMembersAccessDenied extends ProjectMembersState {
  final ProjectRole currentUserRole;

  const ProjectMembersAccessDenied(this.currentUserRole);

  @override
  List<Object?> get props => [currentUserRole];
}

class ProjectMembersLoaded extends ProjectMembersState {
  final ProjectRole currentUserRole;
  final List<ProjectMemberDisplay> members;
  final MemberActionStatus actionStatus;
  final String? actionMessage;

  const ProjectMembersLoaded({
    required this.currentUserRole,
    required this.members,
    this.actionStatus = MemberActionStatus.idle,
    this.actionMessage,
  });

  ProjectMembersLoaded copyWith({
    ProjectRole? currentUserRole,
    List<ProjectMemberDisplay>? members,
    MemberActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return ProjectMembersLoaded(
      currentUserRole: currentUserRole ?? this.currentUserRole,
      members: members ?? this.members,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props =>
      [currentUserRole, members, actionStatus, actionMessage];
}
