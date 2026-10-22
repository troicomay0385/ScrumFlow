import 'package:equatable/equatable.dart';

import '../../../data/models/sprint_model.dart';
import '../../../data/models/user_story_model.dart';
import '../../../domain/ai/core/sprint_forecast_engine.dart';

sealed class SprintForecastState extends Equatable {
  const SprintForecastState();

  @override
  List<Object?> get props => [];
}

class SprintForecastInitial extends SprintForecastState {
  const SprintForecastInitial();
}

class SprintForecastLoading extends SprintForecastState {
  const SprintForecastLoading();
}

class SprintForecastLoaded extends SprintForecastState {
  final SprintModel sprint;
  final List<UserStoryModel> sprintStories;
  final List<UserStoryModel> incompleteStories;

  /// Kết quả dự báo gốc của Sprint (khi chưa loại bớt Story nào).
  final SprintForecastResult baseForecast;

  /// Kết quả dự báo hiện tại (đã áp dụng bộ lọc What-if [excludedStoryIds]).
  final SprintForecastResult activeForecast;

  /// Tập ID các User Story đang được thử dời khỏi Sprint trong chế độ What-if.
  final Set<String> excludedStoryIds;

  const SprintForecastLoaded({
    required this.sprint,
    required this.sprintStories,
    required this.incompleteStories,
    required this.baseForecast,
    required this.activeForecast,
    this.excludedStoryIds = const {},
  });

  bool get hasWhatIfChanges => excludedStoryIds.isNotEmpty;

  @override
  List<Object?> get props => [
    sprint.id,
    sprintStories.length,
    incompleteStories.length,
    baseForecast.completionProbability,
    activeForecast.completionProbability,
    excludedStoryIds,
  ];
}

class SprintForecastError extends SprintForecastState {
  final String message;

  const SprintForecastError(this.message);

  @override
  List<Object?> get props => [message];
}
