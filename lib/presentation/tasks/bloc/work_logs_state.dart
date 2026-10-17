import 'package:equatable/equatable.dart';

import '../../../app/errors/app_failure.dart';
import '../../../data/models/work_log_model.dart';

enum WorkLogsStatus { loading, empty, loaded, error }

/// State danh sách thời gian làm việc (Work Log) của Task (US-066).
class WorkLogsState extends Equatable {
  final WorkLogsStatus status;
  final String taskId;
  final List<WorkLogModel> workLogs;
  final AppFailure? failure;

  const WorkLogsState({
    this.status = WorkLogsStatus.loading,
    this.taskId = '',
    this.workLogs = const [],
    this.failure,
  });

  const WorkLogsState.initial([String taskId = ''])
      : this(
          status: WorkLogsStatus.loading,
          taskId: taskId,
          workLogs: const [],
          failure: null,
        );

  String? get errorMessage => failure?.message;

  WorkLogsState copyWith({
    WorkLogsStatus? status,
    String? taskId,
    List<WorkLogModel>? workLogs,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return WorkLogsState(
      status: status ?? this.status,
      taskId: taskId ?? this.taskId,
      workLogs: workLogs ?? this.workLogs,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [status, taskId, workLogs, failure];
}
