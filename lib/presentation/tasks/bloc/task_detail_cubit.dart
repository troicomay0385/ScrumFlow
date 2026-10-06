import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/authorization/project_role.dart';
import '../../../data/models/project_member_display.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../../../data/repositories/task_repository.dart';
import 'task_detail_state.dart';

/// Cubit màn Task Detail: theo dõi task real-time, đổi người phụ trách
/// (US-043) và đặt deadline (US-044).
///
/// Mỗi thao tác chỉ ghi đúng field liên quan qua [TaskRepository] nên không
/// làm mất dữ liệu khác của task.
class TaskDetailCubit extends Cubit<TaskDetailState> {
  final TaskRepository _taskRepository;
  final ProjectMemberRepository _memberRepository;
  final String projectId;
  final DateTime Function() _now;

  StreamSubscription<TaskModel?>? _taskSub;
  StreamSubscription<List<ProjectMemberDisplay>>? _membersSub;
  StreamSubscription<ProjectRole?>? _roleSub;

  TaskDetailCubit({
    required this._taskRepository,
    required this._memberRepository,
    required this.projectId,
    required TaskModel task,
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(TaskDetailState(
          task: task,
          projectLinked: task.projectId == projectId,
        ));

  String get _taskId => state.task!.id;

  /// Bắt đầu lắng nghe task, danh sách thành viên và role hiện tại.
  void start() {
    final taskId = _taskId;
    _taskSub = _taskRepository.streamTask(taskId).listen(
      (task) {
        if (isClosed) return;
        emit(task == null
            ? state.copyWith(clearTask: true)
            : state.copyWith(task: task));
      },
      onError: (Object _) {},
    );
    _membersSub = _memberRepository.streamMembers(projectId).listen(
      (members) {
        if (!isClosed) {
          emit(state.copyWith(members: members, membersLoaded: true));
        }
      },
      onError: (Object _) {
        if (!isClosed) emit(state.copyWith(membersLoaded: true));
      },
    );
    _roleSub = _memberRepository.streamCurrentUserRole(projectId).listen(
      (role) {
        if (isClosed) return;
        emit(role == null
            ? state.copyWith(clearRole: true)
            : state.copyWith(role: role));
      },
      onError: (Object _) {},
    );
    _linkProjectIfNeeded(taskId);
  }

  /// Task cũ chưa có `projectId` → gắn vào project đang mở (1 lần).
  Future<void> _linkProjectIfNeeded(String taskId) async {
    if (state.projectLinked) return;
    try {
      await _taskRepository.attachProject(
        taskId: taskId,
        projectId: projectId,
      );
      if (!isClosed) emit(state.copyWith(projectLinked: true));
    } catch (_) {
      // Không gắn được (vd. không phải thành viên) → phần bình luận của
      // task giữ ở trạng thái chưa sẵn sàng, các phần khác vẫn xem được.
    }
  }

  /// US-043 — đổi người phụ trách. `userId == null` = bỏ phân công.
  ///
  /// Chỉ chấp nhận user có trong danh sách thành viên thực tế của project.
  Future<void> changeAssignee(String? userId) async {
    final task = state.task;
    if (task == null || state.isSaving) return;
    if (!state.canAssign) {
      return _fail('Bạn không có quyền đổi người phụ trách task này.');
    }
    if (userId == task.assigneeId) return;

    String? assigneeName;
    if (userId != null) {
      final member =
          state.members.where((m) => m.userId == userId).firstOrNull;
      if (member == null) {
        return _fail('Người được chọn không phải thành viên của project.');
      }
      assigneeName = memberDisplayName(member);
    }

    await _save(
      () => _taskRepository.updateTaskAssignee(
        taskId: task.id,
        taskTitle: task.title,
        assigneeId: userId,
        assigneeName: assigneeName,
      ),
      successMessage: userId == null
          ? 'Đã bỏ phân công task'
          : 'Đã giao task cho $assigneeName',
      fallbackError: 'Không thể đổi người phụ trách',
    );
  }

  /// US-044 — đặt/đổi deadline; `deadline == null` = xoá deadline.
  Future<void> setDeadline(DateTime? deadline) async {
    final task = state.task;
    if (task == null || state.isSaving) return;
    if (!state.canSetDeadline) {
      return _fail('Bạn không có quyền đặt deadline cho task này.');
    }

    final normalized = deadline == null
        ? null
        : DateTime(deadline.year, deadline.month, deadline.day);
    if (normalized == task.deadline) return;

    if (normalized != null) {
      final now = _now();
      final today = DateTime(now.year, now.month, now.day);
      if (normalized.isBefore(today)) {
        return _fail('Deadline không được ở trong quá khứ.');
      }
    }

    await _save(
      () => _taskRepository.updateTaskDeadline(
        taskId: task.id,
        deadline: normalized,
      ),
      successMessage:
          normalized == null ? 'Đã xoá deadline' : 'Đã lưu deadline',
      fallbackError: 'Không thể lưu deadline',
    );
  }

  Future<void> _save(
    Future<void> Function() action, {
    required String successMessage,
    required String fallbackError,
  }) async {
    emit(state.copyWith(status: TaskDetailStatus.saving));
    try {
      await action();
      if (isClosed) return;
      emit(state.copyWith(
        status: TaskDetailStatus.saved,
        message: successMessage,
      ));
    } catch (e) {
      if (isClosed) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      _fail(message.isEmpty ? fallbackError : message);
    }
  }

  void _fail(String message) {
    emit(state.copyWith(status: TaskDetailStatus.failure, message: message));
  }

  @override
  Future<void> close() {
    _taskSub?.cancel();
    _membersSub?.cancel();
    _roleSub?.cancel();
    return super.close();
  }
}

/// Tên hiển thị của 1 thành viên: họ tên → email → uid.
String memberDisplayName(ProjectMemberDisplay member) {
  final user = member.user;
  if (user != null && user.fullName.trim().isNotEmpty) {
    return user.fullName.trim();
  }
  if (user != null && user.email.trim().isNotEmpty) return user.email.trim();
  return member.userId;
}
