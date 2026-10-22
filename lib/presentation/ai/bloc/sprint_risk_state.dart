import 'package:equatable/equatable.dart';

import '../../../data/ai/risk_prediction_service.dart';
import '../../../domain/ai/core/feature_spec.dart';

enum SprintRiskStatus { initial, loading, loaded, error }

class SprintRiskState extends Equatable {
  final SprintRiskStatus status;
  final Map<String, TaskRiskPrediction> predictionsByTaskId;
  final List<TaskRiskPrediction> rankedPredictions;
  final String? errorMessage;

  const SprintRiskState({
    this.status = SprintRiskStatus.initial,
    this.predictionsByTaskId = const {},
    this.rankedPredictions = const [],
    this.errorMessage,
  });

  /// Danh sách các task có rủi ro trung bình hoặc cao, đã sắp xếp giảm dần theo xác suất.
  List<TaskRiskPrediction> get highRiskTasks => rankedPredictions
      .where((p) => p.isPredictable && p.level == RiskLevel.high)
      .toList(growable: false);

  /// Danh sách các task có thể dự báo (chưa Done & có deadline), sắp xếp giảm dần.
  List<TaskRiskPrediction> get actionableRiskTasks =>
      rankedPredictions.where((p) => p.isPredictable).toList(growable: false);

  TaskRiskPrediction? predictionForTask(String taskId) =>
      predictionsByTaskId[taskId];

  @override
  List<Object?> get props => [
    status,
    predictionsByTaskId.length,
    rankedPredictions
        .map(
          (p) =>
              '${p.task.id}:${p.probability.toStringAsFixed(3)}:${p.skipReason}',
        )
        .join('|'),
    errorMessage,
  ];
}
