import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/errors/app_error_handler.dart';
import '../../../app/errors/app_failure.dart';
import '../../../app/errors/stream_timeout.dart';
import '../../../app/services/connectivity_service.dart';
import '../../../data/models/work_log_model.dart';
import '../../../data/repositories/work_log_repository.dart';
import 'work_logs_state.dart';

/// Cubit lắng nghe danh sách thời gian làm việc (Work Log) theo thời gian thực (US-066).
class WorkLogsCubit extends Cubit<WorkLogsState> {
  static const Duration defaultFirstLoadTimeout = Duration(seconds: 15);

  final WorkLogRepository _repository;
  final Duration firstLoadTimeout;
  final ConnectivityService? connectivity;

  StreamSubscription<List<WorkLogModel>>? _subscription;
  String _currentTaskId = '';
  int _loadToken = 0;

  WorkLogsCubit(
    this._repository, {
    String? taskId,
    this.firstLoadTimeout = defaultFirstLoadTimeout,
    this.connectivity,
  }) : super(WorkLogsState.initial(taskId ?? '')) {
    if (taskId != null && taskId.isNotEmpty) {
      load(taskId);
    }
  }

  /// Tải và lắng nghe danh sách work log của [taskId].
  Future<void> load(String taskId) async {
    await _subscription?.cancel();
    _subscription = null;
    final currentToken = ++_loadToken;
    _currentTaskId = taskId;

    emit(WorkLogsState(
      status: WorkLogsStatus.loading,
      taskId: taskId,
    ));

    final conn = connectivity;
    if (conn != null && !await conn.isOnline()) {
      if (isClosed || currentToken != _loadToken) return;
      emit(state.copyWith(
        status: WorkLogsStatus.error,
        taskId: taskId,
        failure: const AppFailure.noConnection(),
      ));
      return;
    }

    if (isClosed || currentToken != _loadToken) return;

    _subscription = _repository
        .streamWorkLogs(taskId)
        .timeoutFirstEvent(firstLoadTimeout)
        .listen(
      (logs) {
        if (isClosed || currentToken != _loadToken) return;
        if (logs.isEmpty) {
          emit(state.copyWith(
            status: WorkLogsStatus.empty,
            workLogs: const [],
            clearFailure: true,
          ));
        } else {
          emit(state.copyWith(
            status: WorkLogsStatus.loaded,
            workLogs: logs,
            clearFailure: true,
          ));
        }
      },
      onError: (Object error) {
        if (isClosed || currentToken != _loadToken) return;
        emit(state.copyWith(
          status: WorkLogsStatus.error,
          taskId: taskId,
          failure: AppErrorHandler.classify(error),
        ));
      },
    );
  }

  /// Thử tải lại khi gặp lỗi.
  Future<void> retry() async {
    if (_currentTaskId.isNotEmpty) {
      await load(_currentTaskId);
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _subscription = null;
    return super.close();
  }
}
