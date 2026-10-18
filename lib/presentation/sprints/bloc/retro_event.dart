import 'package:equatable/equatable.dart';

abstract class RetroEvent extends Equatable {
  const RetroEvent();
  @override
  List<Object?> get props => [];
}

/// Bắt đầu lắng nghe stream retro items theo project + sprint.
class RetroSubscriptionRequested extends RetroEvent {
  final String projectId;
  final String sprintId;
  const RetroSubscriptionRequested({
    required this.projectId,
    required this.sprintId,
  });
  @override
  List<Object?> get props => [projectId, sprintId];
}

/// Double Tap: toggle vote cho 1 ý kiến.
class VoteRetroOpinionEvent extends RetroEvent {
  final String opinionId;
  final String userId;
  const VoteRetroOpinionEvent({
    required this.opinionId,
    required this.userId,
  });
  @override
  List<Object?> get props => [opinionId, userId];
}
