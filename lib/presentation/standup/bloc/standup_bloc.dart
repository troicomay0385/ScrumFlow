import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/standup_model.dart';
import '../../../data/repositories/standup_repository.dart';
import 'standup_event.dart';
import 'standup_state.dart';

class StandupBloc extends Bloc<StandupEvent, StandupState> {
  final StandupRepository _repository;

  StandupBloc({required StandupRepository repository})
      : _repository = repository,
        super(StandupInitial()) {
    on<SubmitStandupEvent>(_onSubmitStandup);
    on<FetchStandupHistoryEvent>(_onFetchStandupHistory);
  }

  Future<void> _onFetchStandupHistory(FetchStandupHistoryEvent event, Emitter<StandupState> emit) async {
    emit(StandupHistoryLoading());
    try {
      List<StandupModel> standups = [];
      if (event.sprintId != null) {
        standups = await _repository.getStandupsBySprintId(event.sprintId!);
      } else if (event.startDate != null && event.endDate != null) {
        standups = await _repository.getStandupsByDateRange(
          startDate: event.startDate!,
          endDate: event.endDate!,
        );
      }
      emit(StandupHistoryLoaded(standups));
    } catch (e) {
      emit(StandupHistoryFailure(e.toString()));
    }
  }

  Future<void> _onSubmitStandup(SubmitStandupEvent event, Emitter<StandupState> emit) async {
    emit(StandupSubmitting());
    try {
      final standup = StandupModel(
        id: '', // Sẽ được sinh tự động ở repository/firestore
        userId: event.userId,
        userName: event.userName,
        sprintId: event.sprintId,
        createdAt: DateTime.now(),
        yesterday: event.yesterday,
        today: event.today,
        blockers: event.blockers,
      );
      await _repository.addStandup(standup);
      emit(StandupSubmitSuccess());
    } catch (e) {
      emit(StandupSubmitFailure(e.toString()));
    }
  }
}
