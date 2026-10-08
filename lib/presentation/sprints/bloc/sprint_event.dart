import 'package:equatable/equatable.dart';

abstract class SprintEvent extends Equatable {
  const SprintEvent();

  @override
  List<Object?> get props => [];
}

class SprintCreateRequested extends SprintEvent {
  final String projectId;
  final String name;
  final String goal;
  final DateTime startDate;
  final DateTime endDate;

  const SprintCreateRequested({
	required this.projectId,
	required this.name,
	required this.goal,
	required this.startDate,
	required this.endDate,
  });

  @override
  List<Object?> get props => [projectId, name, goal, startDate, endDate];
}

class SprintStoryAddRequested extends SprintEvent {
  final String projectId;
  final String sprintId;
  final String storyId;

  const SprintStoryAddRequested({
	required this.projectId,
	required this.sprintId,
	required this.storyId,
  });

  @override
  List<Object?> get props => [projectId, sprintId, storyId];
}

class SprintStoriesAddRequested extends SprintEvent {
  final String projectId;
  final String sprintId;
  final List<String> storyIds;

  const SprintStoriesAddRequested({
    required this.projectId,
    required this.sprintId,
    required this.storyIds,
  });

  @override
  List<Object?> get props => [projectId, sprintId, storyIds];
}

class SprintSubscriptionRequested extends SprintEvent {
  final String projectId;

  const SprintSubscriptionRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class SprintSeedMockRequested extends SprintEvent {
  final String projectId;

  const SprintSeedMockRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// US-049: Yêu cầu bắt đầu Sprint (Planned → Active).
class SprintStartRequested extends SprintEvent {
  final String projectId;
  final String sprintId;
  final DateTime startDate;
  final DateTime endDate;

  const SprintStartRequested({
    required this.projectId,
    required this.sprintId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [projectId, sprintId, startDate, endDate];
}

/// US-050: Yêu cầu đóng Sprint (Active → Completed).
class SprintCloseRequested extends SprintEvent {
  final String projectId;
  final String sprintId;

  /// null → chuyển về Product Backlog; non-null → chuyển sang Sprint tiếp theo
  final String? targetSprintId;
  final List<String> incompleteStoryIds;

  const SprintCloseRequested({
    required this.projectId,
    required this.sprintId,
    this.targetSprintId,
    required this.incompleteStoryIds,
  });

  @override
  List<Object?> get props => [projectId, sprintId, targetSprintId, incompleteStoryIds];
}
