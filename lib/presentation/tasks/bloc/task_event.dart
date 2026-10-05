import 'package:equatable/equatable.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class TaskSubscriptionRequested extends TaskEvent {
  final String storyId;
  const TaskSubscriptionRequested(this.storyId);

  @override
  List<Object?> get props => [storyId];
}

class TaskBoardSubscriptionRequested extends TaskEvent {
  final List<String> storyIds;
  const TaskBoardSubscriptionRequested(this.storyIds);

  @override
  List<Object?> get props => [storyIds];
}

class TaskStatusUpdated extends TaskEvent {
  final String taskId;
  final String newStatus;
  const TaskStatusUpdated(this.taskId, this.newStatus);

  @override
  List<Object?> get props => [taskId, newStatus];
}

class TaskCreated extends TaskEvent {
  final String storyId;
  final String title;
  final String description;
  final String? assigneeId;
  final String? assigneeName;

  const TaskCreated({
    required this.storyId,
    required this.title,
    this.description = '',
    this.assigneeId,
    this.assigneeName,
  });

  @override
  List<Object?> get props => [storyId, title, description, assigneeId, assigneeName];
}
