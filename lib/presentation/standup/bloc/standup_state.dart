import 'package:equatable/equatable.dart';
import '../../../data/models/standup_model.dart';


abstract class StandupState extends Equatable {
  const StandupState();

  @override
  List<Object?> get props => [];
}

class StandupInitial extends StandupState {}

class StandupSubmitting extends StandupState {}

class StandupSubmitSuccess extends StandupState {}

class StandupSubmitFailure extends StandupState {
  final String error;

  const StandupSubmitFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class StandupHistoryLoading extends StandupState {}

class StandupHistoryLoaded extends StandupState {
  final List<StandupModel> standups;

  const StandupHistoryLoaded(this.standups);

  @override
  List<Object?> get props => [standups];
}

class StandupHistoryFailure extends StandupState {
  final String error;

  const StandupHistoryFailure(this.error);

  @override
  List<Object?> get props => [error];
}
