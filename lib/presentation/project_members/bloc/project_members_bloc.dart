import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/authorization/permission.dart';
import '../../../app/authorization/project_role.dart';
import '../../../app/authorization/role_permissions.dart';
import '../../../data/models/project_member_display.dart';
import '../../../data/repositories/project_member_repository.dart';
import 'project_members_event.dart';
import 'project_members_state.dart';

/// Internal event — role hiện tại vừa thay đổi (từ stream real-time).
/// Không public vì UI không bao giờ tự tạo event này.
class _RoleChanged extends ProjectMembersEvent {
  final ProjectRole? role;
  const _RoleChanged(this.role);
  @override
  List<Object?> get props => [role];
}

class _MembersChanged extends ProjectMembersEvent {
  final List<ProjectMemberDisplay> members;
  const _MembersChanged(this.members);
  @override
  List<Object?> get props => [members];
}

class _StreamFailed extends ProjectMembersEvent {
  final String message;
  const _StreamFailed(this.message);
  @override
  List<Object?> get props => [message];
}

/// Bloc cho màn hình Quản lý thành viên.
///
/// Theo dõi role của user hiện tại REAL-TIME (mục N): nếu 1 PO khác đổi
/// role của user đang xem màn hình này, permission được cập nhật ngay —
/// ví dụ nếu bị hạ xuống Member, danh sách/quyền thao tác biến mất ngay
/// lập tức mà không cần reload màn hình.
class ProjectMembersBloc extends Bloc<ProjectMembersEvent, ProjectMembersState> {
  final ProjectMemberRepository _repository;

  String? _projectId;
  StreamSubscription<ProjectRole?>? _roleSubscription;
  StreamSubscription<List<ProjectMemberDisplay>>? _membersSubscription;

  /// Role hợp lệ (có quyền viewMembers) gần nhất — lưu riêng thay vì đọc
  /// lại từ [state], vì ở lần tải đầu tiên [state] vẫn còn là
  /// [ProjectMembersLoading] khi members stream trả dữ liệu đầu tiên
  /// (role stream và members stream không đồng bộ với nhau).
  ProjectRole? _currentRole;

  ProjectMembersBloc(this._repository) : super(ProjectMembersLoading()) {
    on<ProjectMembersStarted>(_onStarted);
    on<_RoleChanged>(_onRoleChanged);
    on<_MembersChanged>(_onMembersChanged);
    on<_StreamFailed>(_onStreamFailed);
    on<ProjectMemberAddRequested>(_onAddRequested);
    on<ProjectMemberRoleChangeRequested>(_onRoleChangeRequested);
    on<ProjectMemberRemoveRequested>(_onRemoveRequested);
    on<ProjectMemberActionAcknowledged>(_onActionAcknowledged);
  }

  void _onStarted(
    ProjectMembersStarted event,
    Emitter<ProjectMembersState> emit,
  ) {
    _projectId = event.projectId;
    emit(ProjectMembersLoading());

    _roleSubscription?.cancel();
    _roleSubscription =
        _repository.streamCurrentUserRole(event.projectId).listen(
      (role) => add(_RoleChanged(role)),
      onError: (Object e) => add(_StreamFailed(_readableError(e))),
    );
  }

  void _onRoleChanged(_RoleChanged event, Emitter<ProjectMembersState> emit) {
    final role = event.role;
    final projectId = _projectId;
    if (projectId == null) return;

    if (role == null) {
      _currentRole = null;
      _stopMembersSubscription();
      emit(const ProjectMembersError('Bạn không phải là thành viên của project này.'));
      return;
    }

    if (!hasPermission(role, Permission.viewMembers)) {
      _currentRole = null;
      _stopMembersSubscription();
      emit(ProjectMembersAccessDenied(role));
      return;
    }

    _currentRole = role;
    final current = state;
    if (current is ProjectMembersLoaded) {
      emit(current.copyWith(currentUserRole: role));
    }

    _membersSubscription ??=
        _repository.streamMembers(projectId).listen(
      (members) => add(_MembersChanged(members)),
      onError: (Object e) => add(_StreamFailed(_readableError(e))),
    );
  }

  void _onMembersChanged(
    _MembersChanged event,
    Emitter<ProjectMembersState> emit,
  ) {
    final role = _currentRole;
    if (role == null) return;

    emit(ProjectMembersLoaded(currentUserRole: role, members: event.members));
  }

  void _onStreamFailed(_StreamFailed event, Emitter<ProjectMembersState> emit) {
    emit(ProjectMembersError(event.message));
  }

  Future<void> _onAddRequested(
    ProjectMemberAddRequested event,
    Emitter<ProjectMembersState> emit,
  ) async {
    final current = state;
    final projectId = _projectId;
    if (current is! ProjectMembersLoaded || projectId == null) return;

    if (!hasPermission(current.currentUserRole, Permission.manageMembers)) {
      emit(current.copyWith(
        actionStatus: MemberActionStatus.failure,
        actionMessage: 'Bạn không có quyền thêm thành viên.',
      ));
      return;
    }

    emit(current.copyWith(actionStatus: MemberActionStatus.inProgress));
    try {
      await _repository.addMemberByEmail(
        projectId: projectId,
        email: event.email,
        role: event.role,
      );
      emit(current.copyWith(
        actionStatus: MemberActionStatus.success,
        actionMessage: 'Đã thêm thành viên',
      ));
    } catch (e) {
      emit(current.copyWith(
        actionStatus: MemberActionStatus.failure,
        actionMessage: _readableError(e),
      ));
    }
  }

  Future<void> _onRoleChangeRequested(
    ProjectMemberRoleChangeRequested event,
    Emitter<ProjectMembersState> emit,
  ) async {
    final current = state;
    final projectId = _projectId;
    if (current is! ProjectMembersLoaded || projectId == null) return;

    if (!hasPermission(current.currentUserRole, Permission.changeMemberRole)) {
      emit(current.copyWith(
        actionStatus: MemberActionStatus.failure,
        actionMessage: 'Bạn không có quyền thay đổi vai trò thành viên.',
      ));
      return;
    }

    emit(current.copyWith(actionStatus: MemberActionStatus.inProgress));
    try {
      await _repository.updateMemberRole(
        projectId: projectId,
        targetUserId: event.targetUserId,
        newRole: event.newRole,
      );
      emit(current.copyWith(
        actionStatus: MemberActionStatus.success,
        actionMessage: 'Đã cập nhật vai trò',
      ));
    } catch (e) {
      emit(current.copyWith(
        actionStatus: MemberActionStatus.failure,
        actionMessage: _readableError(e),
      ));
    }
  }

  Future<void> _onRemoveRequested(
    ProjectMemberRemoveRequested event,
    Emitter<ProjectMembersState> emit,
  ) async {
    final current = state;
    final projectId = _projectId;
    if (current is! ProjectMembersLoaded || projectId == null) return;

    if (!hasPermission(current.currentUserRole, Permission.manageMembers)) {
      emit(current.copyWith(
        actionStatus: MemberActionStatus.failure,
        actionMessage: 'Bạn không có quyền xoá thành viên.',
      ));
      return;
    }

    emit(current.copyWith(actionStatus: MemberActionStatus.inProgress));
    try {
      await _repository.removeMember(
        projectId: projectId,
        targetUserId: event.targetUserId,
      );
      emit(current.copyWith(
        actionStatus: MemberActionStatus.success,
        actionMessage: 'Đã xoá thành viên',
      ));
    } catch (e) {
      emit(current.copyWith(
        actionStatus: MemberActionStatus.failure,
        actionMessage: _readableError(e),
      ));
    }
  }

  void _onActionAcknowledged(
    ProjectMemberActionAcknowledged event,
    Emitter<ProjectMembersState> emit,
  ) {
    final current = state;
    if (current is ProjectMembersLoaded) {
      emit(current.copyWith(
        actionStatus: MemberActionStatus.idle,
        actionMessage: null,
      ));
    }
  }

  void _stopMembersSubscription() {
    _membersSubscription?.cancel();
    _membersSubscription = null;
  }

  String _readableError(Object e) {
    final message = e.toString().replaceFirst('Exception: ', '');
    return message.isEmpty ? 'Đã xảy ra lỗi. Vui lòng thử lại.' : message;
  }

  @override
  Future<void> close() {
    _roleSubscription?.cancel();
    _membersSubscription?.cancel();
    return super.close();
  }
}
