import 'package:equatable/equatable.dart';
import '../../../../data/models/task_model.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<TaskModel> tasks;

  const TaskLoaded(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Emit sau khi [MarkTaskAsBlockedEvent] được xử lý thành công.
class TaskBlockedSuccess extends TaskState {
  final String taskId;
  final String message;

  const TaskBlockedSuccess({required this.taskId, required this.message});

  @override
  List<Object?> get props => [taskId, message];
}
