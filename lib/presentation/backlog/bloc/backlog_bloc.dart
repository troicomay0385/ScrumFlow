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
  }

  Future<void> _onSubscriptionRequested(
    BacklogSubscriptionRequested event,
    Emitter<BacklogState> emit,
  ) async {
    emit(BacklogLoading());
    await _subscription?.cancel();

    await emit.forEach(
      _repository.streamUserStories(event.projectId),
      onData: (stories) => BacklogLoaded(stories: stories),
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

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
