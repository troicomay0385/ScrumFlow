import 'package:equatable/equatable.dart';

import '../../../app/errors/app_failure.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/models/sprint_progress.dart';

/// Trạng thái của Sprint Dashboard (US-065).
enum SprintDashboardStatus {
  loading,
  noSprint,
  loaded,
  error,
}

class SprintDashboardState extends Equatable {
  final SprintDashboardStatus status;
  final String projectId;
  final SprintModel? sprint;
  final SprintProgress? progress;
  final AppFailure? failure;

  const SprintDashboardState({
    required this.status,
    this.projectId = '',
    this.sprint,
    this.progress,
    this.failure,
  });

  const SprintDashboardState.initial()
      : this(status: SprintDashboardStatus.loading);

  SprintDashboardState copyWith({
    SprintDashboardStatus? status,
    String? projectId,
    SprintModel? sprint,
    bool clearSprint = false,
    SprintProgress? progress,
    bool clearProgress = false,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return SprintDashboardState(
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      sprint: clearSprint ? null : (sprint ?? this.sprint),
      progress: clearProgress ? null : (progress ?? this.progress),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
        status,
        projectId,
        sprint,
        progress,
        failure,
      ];
}
