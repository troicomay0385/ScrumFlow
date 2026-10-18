import 'package:equatable/equatable.dart';
import '../../../data/models/sprint_retro_item_model.dart';

abstract class RetroState extends Equatable {
  const RetroState();
  @override
  List<Object?> get props => [];
}

class RetroInitial extends RetroState {}

class RetroLoading extends RetroState {}

class RetroLoaded extends RetroState {
  final List<SprintRetroItemModel> items;
  const RetroLoaded(this.items);

  List<SprintRetroItemModel> get wentWell =>
      items.where((i) => i.column == RetroColumnType.wentWell).toList();
  List<SprintRetroItemModel> get couldImprove =>
      items.where((i) => i.column == RetroColumnType.couldImprove).toList();
  List<SprintRetroItemModel> get actionItems =>
      items.where((i) => i.column == RetroColumnType.actionItem).toList();

  @override
  List<Object?> get props => [items];
}

class RetroError extends RetroState {
  final String message;
  const RetroError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Emit tạm thời sau VoteRetroOpinionEvent để kích hoạt animation ở UI.
class RetroVoteAnimated extends RetroState {
  final List<SprintRetroItemModel> items;
  final String votedOpinionId;
  const RetroVoteAnimated({required this.items, required this.votedOpinionId});

  List<SprintRetroItemModel> get wentWell =>
      items.where((i) => i.column == RetroColumnType.wentWell).toList();
  List<SprintRetroItemModel> get couldImprove =>
      items.where((i) => i.column == RetroColumnType.couldImprove).toList();
  List<SprintRetroItemModel> get actionItems =>
      items.where((i) => i.column == RetroColumnType.actionItem).toList();

  @override
  List<Object?> get props => [items, votedOpinionId];
}
