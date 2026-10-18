// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/errors/app_error_handler.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/repositories/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _repository;
  StreamSubscription<List<TaskModel>>? _taskSub;

  TaskBloc({required TaskRepository repository})
      : _repository = repository,
        super(TaskInitial()) {
    on<TaskSubscriptionRequested>(_onSubscriptionRequested);
    on<TaskStatusUpdated>(_onStatusUpdated);
    on<TaskCreated>(_onTaskCreated);
    on<MarkTaskAsBlockedEvent>(_onMarkTaskAsBlocked);
    on<_TasksReceived>((event, emit) => emit(TaskLoaded(event.tasks)));
    on<_TaskError>((event, emit) => emit(TaskError(event.message)));
  }

  /// Bắt đầu lắng nghe tasks theo storyId — emit Loading rồi cập nhật realtime
  Future<void> _onSubscriptionRequested(
    TaskSubscriptionRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    await _taskSub?.cancel();
    _taskSub = _repository.streamTasksByStory(event.storyId).listen(
      (tasks) {
        if (!isClosed) add(_TasksReceived(tasks));
      },
      onError: (Object e) {
        if (!isClosed) add(_TaskError(e.toString()));
      },
    );
  }

  /// Cập nhật trạng thái task trên Firestore → stream tự cập nhật UI
  Future<void> _onStatusUpdated(
    TaskStatusUpdated event,
    Emitter<TaskState> emit,
  ) async {
    // Cập nhật optimistic: đổi trạng thái ngay trên UI
    final current = state;
    List<TaskModel>? previousTasks;
    if (current is TaskLoaded) {
      previousTasks = current.tasks;
      final updated = current.tasks.map((t) {
        return t.id == event.taskId ? t.copyWith(status: event.newStatus) : t;
      }).toList();
      emit(TaskLoaded(updated));
    }
    // Ghi lên Firestore (stream sẽ confirm lại)
    try {
      await _repository.updateTaskStatus(event.taskId, event.newStatus);
    } catch (e) {
      // Rollback lại danh sách cũ trước khi phát thông báo lỗi
      if (previousTasks != null) {
        emit(TaskLoaded(previousTasks));
      }
      final message = AppErrorHandler.messageOf(e);
      emit(TaskError(
        message.isEmpty ? 'Không thể cập nhật trạng thái task' : message,
      ));
    }
  }

  /// Tạo task mới trên Firestore → stream tự cập nhật UI
  Future<void> _onTaskCreated(
    TaskCreated event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _repository.createTask(
        storyId: event.storyId,
        title: event.title,
        description: event.description,
        assigneeId: event.assigneeId,
        assigneeName: event.assigneeName,
        projectId: event.projectId,
      );
      // Không cần emit gì — stream listener sẽ tự push TaskLoaded mới
    } catch (e) {
      emit(TaskError('Lỗi tạo task: $e'));
    }
  }

  /// Đánh dấu Task bị Blocker và push notification tới Scrum Master.
  Future<void> _onMarkTaskAsBlocked(
    MarkTaskAsBlockedEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _repository.markTaskAsBlocked(
        taskId: event.taskId,
        reason: event.reason,
        projectId: event.projectId,
      );
      emit(TaskBlockedSuccess(
        taskId: event.taskId,
        message: '🚧 Đã gắn Blocker. Scrum Master đã được thông báo.',
      ));
    } catch (e) {
      final message = AppErrorHandler.messageOf(e);
      emit(TaskError(
        message.isEmpty ? 'Không thể gắn Blocker cho task.' : message,
      ));
    }
  }

  @override
  Future<void> close() {
    _taskSub?.cancel();
    return super.close();
  }
}

// ── Internal events ──────────────────────────────────────────────────────────

class _TasksReceived extends TaskEvent {
  final List<TaskModel> tasks;
  const _TasksReceived(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class _TaskError extends TaskEvent {
  final String message;
  const _TaskError(this.message);

  @override
  List<Object?> get props => [message];
}
