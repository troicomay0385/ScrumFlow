import 'package:equatable/equatable.dart';

import '../../../data/ai/risk_prediction_service.dart';
import '../../../domain/ai/core/ai_training_pipeline.dart';

enum TaskRiskStatus { initial, loading, loaded, error }

class TaskRiskState extends Equatable {
  final TaskRiskStatus status;
  final TaskRiskPrediction? prediction;
  final TrainedRiskModelArtifact? artifact;
  final TaskWhatIfSuggestion? activeSimulation;
  final String? selectedAssigneeId;
  final String? selectedAssigneeName;
  final int simulatedAddedDays;
  final String? errorMessage;

  const TaskRiskState({
    this.status = TaskRiskStatus.initial,
    this.prediction,
    this.artifact,
    this.activeSimulation,
    this.selectedAssigneeId,
    this.selectedAssigneeName,
    this.simulatedAddedDays = 0,
    this.errorMessage,
  });

  TaskRiskState copyWith({
    TaskRiskStatus? status,
    TaskRiskPrediction? prediction,
    TrainedRiskModelArtifact? artifact,
    TaskWhatIfSuggestion? activeSimulation,
    bool clearSimulation = false,
    String? selectedAssigneeId,
    String? selectedAssigneeName,
    int? simulatedAddedDays,
    String? errorMessage,
  }) {
    return TaskRiskState(
      status: status ?? this.status,
      prediction: prediction ?? this.prediction,
      artifact: artifact ?? this.artifact,
      activeSimulation: clearSimulation
          ? null
          : (activeSimulation ?? this.activeSimulation),
      selectedAssigneeId: selectedAssigneeId ?? this.selectedAssigneeId,
      selectedAssigneeName: selectedAssigneeName ?? this.selectedAssigneeName,
      simulatedAddedDays: simulatedAddedDays ?? this.simulatedAddedDays,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    prediction?.task.id,
    prediction?.task.updatedAt,
    prediction?.task.assigneeId,
    prediction?.task.deadline,
    prediction?.probability,
    prediction?.skipReason,
    activeSimulation?.targetAssigneeId,
    activeSimulation?.addedDays,
    activeSimulation?.newProbability,
    selectedAssigneeId,
    selectedAssigneeName,
    simulatedAddedDays,
    errorMessage,
  ];
}
