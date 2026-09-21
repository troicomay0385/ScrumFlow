import 'package:equatable/equatable.dart';

import '../../../app/authorization/project_role.dart';

abstract class ProjectMembersEvent extends Equatable {
  const ProjectMembersEvent();

  @override
  List<Object?> get props => [];
}

/// Bắt đầu theo dõi màn hình Quản lý thành viên của 1 project —
/// subscribe role hiện tại (real-time) + danh sách thành viên.
class ProjectMembersStarted extends ProjectMembersEvent {
  final String projectId;

  const ProjectMembersStarted(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class ProjectMemberAddRequested extends ProjectMembersEvent {
  final String email;
  final ProjectRole role;

  const ProjectMemberAddRequested({required this.email, required this.role});

  @override
  List<Object?> get props => [email, role];
}

class ProjectMemberRoleChangeRequested extends ProjectMembersEvent {
  final String targetUserId;
  final ProjectRole newRole;

  const ProjectMemberRoleChangeRequested({
    required this.targetUserId,
    required this.newRole,
  });

  @override
  List<Object?> get props => [targetUserId, newRole];
}

class ProjectMemberRemoveRequested extends ProjectMembersEvent {
  final String targetUserId;

  const ProjectMemberRemoveRequested(this.targetUserId);

  @override
  List<Object?> get props => [targetUserId];
}

/// UI gọi sau khi đã hiển thị kết quả hành động (SnackBar/dialog) để
/// đưa [MemberActionStatus] về `idle`, tránh hiển thị lại cùng 1 kết quả
/// khi widget rebuild.
class ProjectMemberActionAcknowledged extends ProjectMembersEvent {}
