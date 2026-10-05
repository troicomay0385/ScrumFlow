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
