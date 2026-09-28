import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/backlog_repository.dart';
import '../../../data/repositories/backlog_repository_impl.dart';
import 'backlog_event.dart';
import 'backlog_state.dart';

class BacklogBloc extends Bloc<BacklogEvent, BacklogState> {
  final BacklogRepository _repository;
  StreamSubscription? _subscription;

  BacklogBloc({BacklogRepository? repository})
      : _repository = repository ?? BacklogRepositoryImpl(),
        super(BacklogInitial()) {
    on<BacklogSubscriptionRequested>(_onSubscriptionRequested);
    on<BacklogSeedMockRequested>(_onSeedMockRequested);
    on<BacklogSearchChanged>(_onSearchChanged);
    on<BacklogStatusFilterChanged>(_onStatusFilterChanged);
    on<BacklogPriorityFilterChanged>(_onPriorityFilterChanged);
    on<BacklogTagFilterChanged>(_onTagFilterChanged);
    on<BacklogSortChanged>(_onSortChanged);
    on<BacklogFilterResetRequested>(_onFilterResetRequested);
  }

  Future<void> _onSubscriptionRequested(
    BacklogSubscriptionRequested event,
    Emitter<BacklogState> emit,
  ) async {
    emit(BacklogLoading());
    await _subscription?.cancel();

    await emit.forEach(
      _repository.streamUserStories(event.projectId),
      onData: (stories) {
        if (state is BacklogLoaded) {
          final current = state as BacklogLoaded;
          return current.copyWith(stories: stories);
        }
        return BacklogLoaded(stories: stories);
      },
      onError: (error, stackTrace) =>
          BacklogError('Lỗi tải Product Backlog: $error'),
    );
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
      emit(BacklogError('Không thể tạo dữ liệu mẫu: $e'));
    }
  }

  void _onSearchChanged(
    BacklogSearchChanged event,
    Emitter<BacklogState> emit,
  ) {
    if (state is BacklogLoaded) {
      emit((state as BacklogLoaded).copyWith(searchQuery: event.query));
    }
  }

  void _onStatusFilterChanged(
    BacklogStatusFilterChanged event,
    Emitter<BacklogState> emit,
  ) {
    if (state is BacklogLoaded) {
      emit((state as BacklogLoaded).copyWith(statusFilter: event.status));
    }
  }

  void _onPriorityFilterChanged(
    BacklogPriorityFilterChanged event,
    Emitter<BacklogState> emit,
  ) {
    if (state is BacklogLoaded) {
      emit((state as BacklogLoaded).copyWith(priorityFilter: event.priority));
    }
  }

  void _onTagFilterChanged(
    BacklogTagFilterChanged event,
    Emitter<BacklogState> emit,
  ) {
    if (state is BacklogLoaded) {
      emit((state as BacklogLoaded).copyWith(tagFilter: event.tag));
    }
  }

  void _onSortChanged(
    BacklogSortChanged event,
    Emitter<BacklogState> emit,
  ) {
    if (state is BacklogLoaded) {
      emit((state as BacklogLoaded).copyWith(sortBy: event.sortBy));
    }
  }

  void _onFilterResetRequested(
    BacklogFilterResetRequested event,
    Emitter<BacklogState> emit,
  ) {
    if (state is BacklogLoaded) {
      emit((state as BacklogLoaded).copyWith(
        searchQuery: '',
        statusFilter: 'Tất cả',
        priorityFilter: 'Tất cả',
        tagFilter: 'Tất cả',
        sortBy: BacklogSortBy.priorityDesc,
      ));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
