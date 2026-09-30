import 'package:equatable/equatable.dart';
import '../../../data/models/sprint_model.dart';

abstract class SprintState extends Equatable {
  const SprintState();

  @override
  List<Object?> get props => [];
}

class SprintInitial extends SprintState {}

class SprintLoading extends SprintState {}

class SprintLoaded extends SprintState {
  final List<SprintModel> sprints;

  const SprintLoaded({required this.sprints});

  @override
  List<Object?> get props => [sprints];
}

class SprintError extends SprintState {
  final String message;

  const SprintError(this.message);

  @override
  List<Object?> get props => [message];
}
