import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/constants/sprint_status.dart';
import '../../../app/errors/app_error_handler.dart';
import '../../../app/errors/app_failure.dart';
import '../../../app/errors/stream_timeout.dart';
import '../../../app/services/connectivity_service.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/models/sprint_progress.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/sprint_repository.dart';
import '../../../data/repositories/task_repository.dart';
import 'sprint_dashboard_state.dart';

/// Cubit quản lý dữ liệu Sprint Dashboard (tiến độ Sprint Active - US-065).
class SprintDashboardCubit extends Cubit<SprintDashboardState> {
  static const Duration defaultFirstLoadTimeout = Duration(seconds: 15);

  final SprintRepository _sprintRepository;
  final TaskRepository _taskRepository;
  final Duration firstLoadTimeout;
  final ConnectivityService? connectivity;

  StreamSubscription<List<SprintModel>>? _sprintSub;
  StreamSubscription<List<TaskModel>>? _taskSub;

  SprintModel? _currentActiveSprint;
  String _lastProjectId = '';
  int _loadToken = 0;

  SprintDashboardCubit(
    this._sprintRepository,
    this._taskRepository, {
    this.firstLoadTimeout = defaultFirstLoadTimeout,
    this.connectivity,
  }) : super(const SprintDashboardState.initial());

  /// Tải thông tin tiến độ Sprint của [projectId].
  ///
  /// - Huỷ mọi subscription trước đó.
  /// - Quản lý token tăng dần để bỏ qua kết quả trễ khi chuyển đổi project nhanh.
  /// - Kiểm tra kết nối mạng trước khi lắng nghe stream.
  Future<void> load(String projectId) async {
    await _cancelSubscriptions();
    final currentToken = ++_loadToken;
    _lastProjectId = projectId;
    _currentActiveSprint = null;

    emit(SprintDashboardState(
      status: SprintDashboardStatus.loading,
      projectId: projectId,
    ));

    final conn = connectivity;
    if (conn != null && !await conn.isOnline()) {
      if (isClosed || currentToken != _loadToken) return;
      emit(state.copyWith(
        status: SprintDashboardStatus.error,
        projectId: projectId,
        failure: const AppFailure.noConnection(),
      ));
      return;
    }

    if (isClosed || currentToken != _loadToken) return;

    _sprintSub = _sprintRepository
        .streamSprints(projectId)
        .timeoutFirstEvent(firstLoadTimeout)
        .listen(
      (sprints) {
        if (isClosed || currentToken != _loadToken) return;
        _onSprintsUpdated(sprints, currentToken, projectId);
      },
      onError: (Object error) {
        if (isClosed || currentToken != _loadToken) return;
        _taskSub?.cancel();
        _taskSub = null;
        emit(state.copyWith(
          status: SprintDashboardStatus.error,
          projectId: projectId,
          failure: AppErrorHandler.classify(error),
        ));
      },
    );
  }

  void _onSprintsUpdated(
    List<SprintModel> sprints,
    int currentToken,
    String projectId,
  ) {
    final activeSprint = sprints
        .where((s) =>
            s.status.toLowerCase() == SprintStatus.active.toLowerCase())
        .firstOrNull;

    if (activeSprint == null) {
      _taskSub?.cancel();
      _taskSub = null;
      _currentActiveSprint = null;
      emit(state.copyWith(
        status: SprintDashboardStatus.noSprint,
        projectId: projectId,
        clearSprint: true,
        clearProgress: true,
        clearFailure: true,
      ));
      return;
    }

    final currentSprint = _currentActiveSprint;
    _currentActiveSprint = activeSprint;

    final bool shouldResubscribe = _taskSub == null ||
        currentSprint == null ||
        currentSprint.id != activeSprint.id ||
        !listEquals(currentSprint.storyIds, activeSprint.storyIds);

    if (shouldResubscribe) {
      _taskSub?.cancel();
      emit(state.copyWith(
        sprint: activeSprint,
        projectId: projectId,
      ));

      _taskSub = _taskRepository
          .streamTasksByStories(activeSprint.storyIds)
          .timeoutFirstEvent(firstLoadTimeout)
          .listen(
        (tasks) {
          if (isClosed || currentToken != _loadToken) return;
          emit(state.copyWith(
            status: SprintDashboardStatus.loaded,
            projectId: projectId,
            sprint: _currentActiveSprint ?? activeSprint,
            progress: SprintProgress.fromTasks(tasks),
            clearFailure: true,
          ));
        },
        onError: (Object error) {
          if (isClosed || currentToken != _loadToken) return;
          emit(state.copyWith(
            status: SprintDashboardStatus.error,
            projectId: projectId,
            failure: AppErrorHandler.classify(error),
          ));
        },
      );
    } else {
      // Chỉ đổi tên/ngày/... của Sprint -> Cập nhật sprint mà không subscribe lại task
      emit(state.copyWith(
        sprint: activeSprint,
        projectId: projectId,
      ));
    }
  }

  /// Thử lại tải dữ liệu cho project gần nhất (bỏ qua nếu đang loading).
  void retry() {
    if (state.status == SprintDashboardStatus.loading) return;
    final targetId =
        _lastProjectId.isNotEmpty ? _lastProjectId : state.projectId;
    if (targetId.isNotEmpty) {
      load(targetId);
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _sprintSub?.cancel();
    _sprintSub = null;
    await _taskSub?.cancel();
    _taskSub = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    return super.close();
  }
}
