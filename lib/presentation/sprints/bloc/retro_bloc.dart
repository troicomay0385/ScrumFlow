import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/sprint_retro_item_model.dart';
import '../../../data/repositories/sprint_retro_repository.dart';
import 'retro_event.dart';
import 'retro_state.dart';

/// Internal event — chỉ dùng trong file này để đưa dữ liệu stream vào BLoC.
class _RetroItemsReceived extends RetroEvent {
  final List<SprintRetroItemModel> items;
  const _RetroItemsReceived(this.items);
  @override
  List<Object?> get props => [items];
}

class RetroBloc extends Bloc<RetroEvent, RetroState> {
  final SprintRetroRepository _repository;
  StreamSubscription<List<SprintRetroItemModel>>? _sub;

  String _projectId = '';
  String _sprintId = '';

  RetroBloc({required SprintRetroRepository repository})
      : _repository = repository,
        super(RetroInitial()) {
    on<RetroSubscriptionRequested>(_onSubscriptionRequested);
    on<_RetroItemsReceived>(_onItemsReceived);
    on<VoteRetroOpinionEvent>(_onVoteOpinion);
  }

  Future<void> _onSubscriptionRequested(
    RetroSubscriptionRequested event,
    Emitter<RetroState> emit,
  ) async {
    _projectId = event.projectId;
    _sprintId = event.sprintId;
    emit(RetroLoading());
    await _sub?.cancel();
    _sub = _repository
        .streamRetroItems(event.projectId, event.sprintId)
        .listen(
          (items) {
            if (!isClosed) add(_RetroItemsReceived(items));
          },
          onError: (Object e) {
            if (!isClosed) emit(RetroError(e.toString()));
          },
        );
  }

  void _onItemsReceived(
    _RetroItemsReceived event,
    Emitter<RetroState> emit,
  ) {
    final current = state;
    if (current is RetroVoteAnimated) {
      // Giữ animation đang chạy, chỉ cập nhật data
      emit(RetroVoteAnimated(
        items: event.items,
        votedOpinionId: current.votedOpinionId,
      ));
    } else {
      emit(RetroLoaded(event.items));
    }
  }

  /// Optimistic update: toggle vote ngay trên local state, rồi sync Firestore.
  Future<void> _onVoteOpinion(
    VoteRetroOpinionEvent event,
    Emitter<RetroState> emit,
  ) async {
    final current = state;
    final List<SprintRetroItemModel> items;
    if (current is RetroLoaded) {
      items = current.items;
    } else if (current is RetroVoteAnimated) {
      items = current.items;
    } else {
      return;
    }

    // Optimistic: toggle voterIds ngay lập tức
    final updatedItems = items.map((item) {
      if (item.id != event.opinionId) return item;
      final voters = List<String>.from(item.voterIds);
      if (voters.contains(event.userId)) {
        voters.remove(event.userId);
      } else {
        voters.add(event.userId);
      }
      return item.copyWith(voterIds: voters);
    }).toList();

    // Emit RetroVoteAnimated để widget bắt và chạy animation tim
    emit(RetroVoteAnimated(
      items: updatedItems,
      votedOpinionId: event.opinionId,
    ));

    // Sau 600ms reset về RetroLoaded (animation xong)
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!isClosed) emit(RetroLoaded(updatedItems));

    // Sync lên Firestore (fire-and-forget)
    try {
      await _repository.toggleVote(
        projectId: _projectId,
        sprintId: _sprintId,
        itemId: event.opinionId,
        userId: event.userId,
      );
    } catch (_) {
      // Stream sẽ tự rollback nếu Firestore reject
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
