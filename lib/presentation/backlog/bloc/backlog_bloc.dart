import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/errors/app_error_handler.dart';
import '../../../app/errors/app_failure.dart';
import '../../../app/errors/stream_timeout.dart';
import '../../../app/services/connectivity_service.dart';
import '../../../app/utils/event_transformers.dart';
import '../../../data/repositories/backlog_repository.dart';
import '../../../data/repositories/backlog_repository_impl.dart';
import '../utils/backlog_view.dart';
import 'backlog_event.dart';
import 'backlog_state.dart';

class BacklogBloc extends Bloc<BacklogEvent, BacklogState> {
  /// Thời gian chờ tối đa cho lần nhận dữ liệu đầu tiên (US-063).
  static const Duration defaultFirstLoadTimeout = Duration(seconds: 15);

  final BacklogRepository _repository;
  final ConnectivityService? _connectivityService;
  final Duration _firstLoadTimeout;
  StreamSubscription? _subscription;

  BacklogBloc({
    BacklogRepository? repository,
    this._connectivityService,
    this._firstLoadTimeout = defaultFirstLoadTimeout,
  })  : _repository = repository ?? BacklogRepositoryImpl(),
        super(BacklogInitial()) {
    // restartable: "Thử lại" huỷ subscription cũ trước khi mở cái mới,
    // không để nhiều listener chạy song song.
    on<BacklogSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: restartable(),
    );
    on<BacklogSeedMockRequested>(_onSeedMockRequested);
    on<BacklogSearchChanged>(_onSearchChanged);
    on<BacklogStatusFilterChanged>(_onStatusFilterChanged);
    on<BacklogPriorityFilterChanged>(_onPriorityFilterChanged);
    on<BacklogTagFilterChanged>(_onTagFilterChanged);
    on<BacklogFilterResetRequested>(_onFilterResetRequested);
    on<BacklogSortChanged>(_onSortChanged);
    on<BacklogDeleteStoriesRequested>(_onDeleteStoriesRequested);
    on<BacklogPaginatedLoadRequested>(_onPaginatedLoadRequested);
    on<BacklogNextPageRequested>(_onNextPageRequested);
  }

  Future<void> _onSubscriptionRequested(
    BacklogSubscriptionRequested event,
    Emitter<BacklogState> emit,
  ) async {
    emit(BacklogLoading());
    await _subscription?.cancel();

    final connectivity = _connectivityService;
    if (connectivity != null && !await connectivity.isOnline()) {
      emit(BacklogError.fromFailure(const AppFailure.noConnection()));
      return;
    }

    await emit.forEach(
      _repository
          .streamUserStories(event.projectId)
          .timeoutFirstEvent(_firstLoadTimeout),
      // Giữ nguyên filter/sort người dùng đã chọn khi stream đẩy dữ liệu
      // mới (vd. vừa tạo story) — chỉ thay danh sách gốc.
      onData: (stories) => state is BacklogLoaded
          ? (state as BacklogLoaded)
              .copyWith(stories: stories, isSeeding: false)
          : BacklogLoaded(stories: stories),
      // Đang hiển thị dữ liệu thì giữ nguyên (lỗi tạm thời của listener);
      // chưa có dữ liệu thì báo lỗi thân thiện kèm "Thử lại".
      onError: (error, stackTrace) => state is BacklogLoaded
          ? state
          : BacklogError.fromFailure(AppErrorHandler.classify(error)),
    );
    // Stream kết thúc mà chưa có dữ liệu → không để loading vô tận.
    if (!emit.isDone && state is BacklogLoading) {
      emit(BacklogError.fromFailure(const AppFailure.unknown()));
    }
  }

  /// Load trang đầu tiên theo phân trang server-side (US-054).
  Future<void> _onPaginatedLoadRequested(
    BacklogPaginatedLoadRequested event,
    Emitter<BacklogState> emit,
  ) async {
    emit(BacklogLoading());
    try {
      final result = await _repository.getUserStoriesPaginated(
        projectId: event.projectId,
        pageSize: event.pageSize,
        statusFilter: event.statusFilter,
      );
      emit(BacklogLoaded(
        stories: result.stories,
        lastDocument: result.lastDocument,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      emit(BacklogError.fromFailure(AppErrorHandler.classify(e)));
    }
  }

  /// Load trang tiếp theo (cursor-based) — append vào danh sách hiện có.
  Future<void> _onNextPageRequested(
    BacklogNextPageRequested event,
    Emitter<BacklogState> emit,
  ) async {
    final current = state;
    if (current is! BacklogLoaded || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      final result = await _repository.getUserStoriesPaginated(
        projectId: event.projectId,
        pageSize: event.pageSize,
        startAfterDoc: event.lastDocument ?? current.lastDocument,
        statusFilter: event.statusFilter ?? current.statusFilter,
      );
      emit(current.copyWith(
        stories: [...current.stories, ...result.stories],
        lastDocument: () => result.lastDocument,
        hasMore: result.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onSeedMockRequested(
    BacklogSeedMockRequested event,
    Emitter<BacklogState> emit,
  ) async {
    if (state is BacklogLoaded) {
      emit((state as BacklogLoaded).copyWith(isSeeding: true));
    }
    try {
      await _repository.seedMockStories(event.projectId);
      // Stream sẽ tự động emit danh sách mới
    } catch (e) {
      emit(BacklogError(
        'Không thể tạo dữ liệu mẫu: ${AppErrorHandler.messageOf(e)}',
      ));
    }
  }

  void _onSearchChanged(
    BacklogSearchChanged event,
    Emitter<BacklogState> emit,
  ) {
    final current = state;
    if (current is BacklogLoaded) {
      emit(current.copyWith(searchQuery: event.query));
    }
  }

  void _onStatusFilterChanged(
    BacklogStatusFilterChanged event,
    Emitter<BacklogState> emit,
  ) {
    final current = state;
    if (current is BacklogLoaded) {
      emit(current.copyWith(statusFilter: () => event.status));
    }
  }

  void _onPriorityFilterChanged(
    BacklogPriorityFilterChanged event,
    Emitter<BacklogState> emit,
  ) {
    final current = state;
    if (current is BacklogLoaded) {
      emit(current.copyWith(priorityFilter: () => event.priority));
    }
  }

  void _onTagFilterChanged(
    BacklogTagFilterChanged event,
    Emitter<BacklogState> emit,
  ) {
    final current = state;
    if (current is BacklogLoaded) {
      emit(current.copyWith(tagFilter: () => event.tag));
    }
  }

  void _onFilterResetRequested(
    BacklogFilterResetRequested event,
    Emitter<BacklogState> emit,
  ) {
    final current = state;
    if (current is BacklogLoaded) {
      emit(current.copyWith(
        searchQuery: '',
        statusFilter: () => null,
        priorityFilter: () => null,
        tagFilter: () => null,
        sortOption: BacklogSortOption.defaultOrder,
      ));
    }
  }

  void _onSortChanged(BacklogSortChanged event, Emitter<BacklogState> emit) {
    final current = state;
    if (current is BacklogLoaded) {
      emit(current.copyWith(sortOption: event.sortOption));
    }
  }

  Future<void> _onDeleteStoriesRequested(
    BacklogDeleteStoriesRequested event,
    Emitter<BacklogState> emit,
  ) async {
    try {
      await _repository.deleteUserStories(
        projectId: event.projectId,
        storyIds: event.storyIds,
      );
    } catch (e) {
      emit(BacklogError(
        'Lỗi xóa User Story: ${AppErrorHandler.messageOf(e)}',
      ));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
