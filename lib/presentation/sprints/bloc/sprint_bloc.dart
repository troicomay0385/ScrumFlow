import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/errors/app_error_handler.dart';
import '../../../app/errors/app_failure.dart';
import '../../../app/errors/stream_timeout.dart';
import '../../../app/services/connectivity_service.dart';
import '../../../app/utils/event_transformers.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/repositories/sprint_repository.dart';
import 'sprint_event.dart';
import 'sprint_state.dart';

class SprintBloc extends Bloc<SprintEvent, SprintState> {
  /// Thời gian chờ tối đa cho lần nhận dữ liệu đầu tiên (US-063).
  static const Duration defaultFirstLoadTimeout = Duration(seconds: 15);

  final SprintRepository _repository;
  final ConnectivityService? _connectivityService;
  final Duration _firstLoadTimeout;
  StreamSubscription? _subscription;

  SprintBloc({
    required this._repository,
    this._connectivityService,
    this._firstLoadTimeout = defaultFirstLoadTimeout,
  }) : super(SprintInitial()) {
    // restartable: "Thử lại" huỷ subscription cũ trước khi mở cái mới.
    on<SprintSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: restartable(),
    );
    on<SprintSeedMockRequested>(_onSeedMockRequested);
    on<SprintCreateRequested>(_onCreateRequested);
    on<SprintStoryAddRequested>(_onStoryAddRequested);
    on<SprintStoriesAddRequested>(_onStoriesAddRequested);
    on<SprintStartRequested>(_onStartRequested);
    on<SprintCloseRequested>(_onCloseRequested);
  }

  /// Danh sách Sprint đang hiển thị — giữ lại khi phát kết quả thao tác để
  /// màn hình không bị nháy sang "Chưa có Sprint nào".
  List<SprintModel> get _currentSprints => switch (state) {
        SprintLoaded(:final sprints) => sprints,
        SprintActionCompleted(:final sprints) => sprints,
        SprintError(:final sprints) => sprints,
        _ => const <SprintModel>[],
      };

  Future<void> _onCreateRequested(
    SprintCreateRequested event,
    Emitter<SprintState> emit,
  ) async {
    try {
      await _repository.createSprint(
        projectId: event.projectId,
        name: event.name,
        goal: event.goal,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(SprintActionCompleted('Đã tạo Sprint mới.', sprints: _currentSprints));
    } catch (e) {
      emit(SprintError(
        AppErrorHandler.messageOf(e),
        sprints: _currentSprints,
      ));
    }
  }

  Future<void> _onStoryAddRequested(
    SprintStoryAddRequested event,
    Emitter<SprintState> emit,
  ) async {
    try {
      await _repository.addStoryToSprint(
        projectId: event.projectId,
        sprintId: event.sprintId,
        storyId: event.storyId,
      );
      emit(SprintActionCompleted(
        'Đã thêm User Story vào Sprint.',
        sprints: _currentSprints,
      ));
    } catch (e) {
      emit(SprintError(
        AppErrorHandler.messageOf(e),
        sprints: _currentSprints,
      ));
    }
  }

  Future<void> _onStoriesAddRequested(
    SprintStoriesAddRequested event,
    Emitter<SprintState> emit,
  ) async {
    try {
      await _repository.addStoriesToSprint(
        projectId: event.projectId,
        sprintId: event.sprintId,
        storyIds: event.storyIds,
      );
      emit(SprintActionCompleted(
        'Đã thêm ${event.storyIds.length} User Story vào Sprint.',
        sprints: _currentSprints,
      ));
    } catch (e) {
      emit(SprintError(
        AppErrorHandler.messageOf(e),
        sprints: _currentSprints,
      ));
    }
  }

  Future<void> _onSubscriptionRequested(
    SprintSubscriptionRequested event,
    Emitter<SprintState> emit,
  ) async {
    emit(SprintLoading());
    await _subscription?.cancel();

    final connectivity = _connectivityService;
    if (connectivity != null && !await connectivity.isOnline()) {
      emit(const SprintLoadFailure(AppFailure.noConnection()));
      return;
    }

    await emit.forEach(
      _repository
          .streamSprints(event.projectId)
          .timeoutFirstEvent(_firstLoadTimeout),
      onData: (sprints) => SprintLoaded(sprints: sprints),
      // Đã có danh sách đang hiển thị → giữ nguyên; chưa có → màn lỗi.
      onError: (error, stackTrace) =>
          state is SprintLoaded ||
                  state is SprintActionCompleted ||
                  state is SprintError
              ? state
              : SprintLoadFailure(AppErrorHandler.classify(error)),
    );
    // Stream kết thúc mà chưa có dữ liệu → không để loading vô tận.
    if (!emit.isDone && state is SprintLoading) {
      emit(const SprintLoadFailure(AppFailure.unknown()));
    }
  }

  Future<void> _onSeedMockRequested(
    SprintSeedMockRequested event,
    Emitter<SprintState> emit,
  ) async {
    try {
      await _repository.seedMockSprints(event.projectId);
    } catch (e) {
      emit(SprintError(
        'Không thể tạo dữ liệu mẫu: ${AppErrorHandler.messageOf(e)}',
        sprints: state is SprintLoaded ? (state as SprintLoaded).sprints : const [],
      ));
    }
  }

  /// US-049: Bắt đầu Sprint
  Future<void> _onStartRequested(
    SprintStartRequested event,
    Emitter<SprintState> emit,
  ) async {
    try {
      await _repository.startSprint(
        projectId: event.projectId,
        sprintId: event.sprintId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(SprintActionCompleted(
        'Sprint đã được bắt đầu thành công! 🚀',
        sprints: _currentSprints,
      ));
    } catch (e) {
      emit(SprintError(
        AppErrorHandler.messageOf(e),
        sprints: _currentSprints,
      ));
    }
  }

  /// US-050: Đóng Sprint
  Future<void> _onCloseRequested(
    SprintCloseRequested event,
    Emitter<SprintState> emit,
  ) async {
    try {
      await _repository.closeSprint(
        projectId: event.projectId,
        sprintId: event.sprintId,
        targetSprintId: event.targetSprintId,
        incompleteStoryIds: event.incompleteStoryIds,
      );
      final msg = event.incompleteStoryIds.isEmpty
          ? 'Sprint đã được đóng thành công! ✅'
          : 'Sprint đã đóng. ${event.incompleteStoryIds.length} User Story chưa hoàn thành đã được chuyển đi.';
      emit(SprintActionCompleted(msg, sprints: _currentSprints));
    } catch (e) {
      emit(SprintError(
        AppErrorHandler.messageOf(e),
        sprints: _currentSprints,
      ));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
