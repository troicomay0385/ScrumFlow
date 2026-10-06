import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    if (current is TaskLoaded) {
      final updated = current.tasks.map((t) {
        return t.id == event.taskId ? t.copyWith(status: event.newStatus) : t;
      }).toList();
      emit(TaskLoaded(updated));
    }
    // Ghi lên Firestore (stream sẽ confirm lại)
    try {
      print('[TASK BLOC] Kéo thả task ${event.taskId} sang trạng thái: ${event.newStatus}');
      await _repository.updateTaskStatus(event.taskId, event.newStatus);
    } catch (e) {
      // Rollback nếu lỗi
      print('[TASK BLOC ERROR] Lỗi cập nhật trạng thái task: $e');
      if (!isClosed) add(_TaskError('Lỗi cập nhật trạng thái: $e'));
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
      );
      // Không cần emit gì — stream listener sẽ tự push TaskLoaded mới
    } catch (e) {
      emit(TaskError('Lỗi tạo task: $e'));
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
