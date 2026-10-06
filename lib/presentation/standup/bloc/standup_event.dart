import 'package:equatable/equatable.dart';

abstract class StandupEvent extends Equatable {
  const StandupEvent();

  @override
  List<Object?> get props => [];
}

class SubmitStandupEvent extends StandupEvent {
  final String userId;
  final String userName;
  final String sprintId;
  final String yesterday;
  final String today;
  final String blockers;

  const SubmitStandupEvent({
    required this.userId,
    required this.userName,
    required this.sprintId,
    required this.yesterday,
    required this.today,
    required this.blockers,
  });

  @override
  List<Object?> get props => [userId, userName, sprintId, yesterday, today, blockers];
}

class FetchStandupHistoryEvent extends StandupEvent {
  final String? sprintId;
  final DateTime? startDate;
  final DateTime? endDate;

  const FetchStandupHistoryEvent({
    this.sprintId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [sprintId, startDate, endDate];
}
