import 'package:equatable/equatable.dart';

import '../../../domain/ai/core/ai_training_pipeline.dart';
import '../../../domain/ai/core/metrics.dart';

enum ModelLabStatus { initial, loading, loaded, training, error }

class ModelLabState extends Equatable {
  final ModelLabStatus status;
  final TrainedRiskModelArtifact? artifact;
  final EvaluationMetrics? previousMetricsBeforeRetrain;
  final int currentEpoch;
  final int totalEpochs;
  final List<double> liveTrainLosses;
  final List<double> liveValLosses;
  final int detectedRealTaskCount;
  final String? infoBannerMessage;
  final String? errorMessage;

  const ModelLabState({
    this.status = ModelLabStatus.initial,
    this.artifact,
    this.previousMetricsBeforeRetrain,
    this.currentEpoch = 0,
    this.totalEpochs = 120,
    this.liveTrainLosses = const [],
    this.liveValLosses = const [],
    this.detectedRealTaskCount = 0,
    this.infoBannerMessage,
    this.errorMessage,
  });

  /// Cảnh báo khi số lượng mẫu `real` trong dự án còn ít (< 10 mẫu).
  bool get hasLowRealDataWarning => detectedRealTaskCount < 10;

  ModelLabState copyWith({
    ModelLabStatus? status,
    TrainedRiskModelArtifact? artifact,
    EvaluationMetrics? previousMetricsBeforeRetrain,
    int? currentEpoch,
    int? totalEpochs,
    List<double>? liveTrainLosses,
    List<double>? liveValLosses,
    int? detectedRealTaskCount,
    String? infoBannerMessage,
    String? errorMessage,
  }) {
    return ModelLabState(
      status: status ?? this.status,
      artifact: artifact ?? this.artifact,
      previousMetricsBeforeRetrain:
          previousMetricsBeforeRetrain ?? this.previousMetricsBeforeRetrain,
      currentEpoch: currentEpoch ?? this.currentEpoch,
      totalEpochs: totalEpochs ?? this.totalEpochs,
      liveTrainLosses: liveTrainLosses ?? this.liveTrainLosses,
      liveValLosses: liveValLosses ?? this.liveValLosses,
      detectedRealTaskCount:
          detectedRealTaskCount ?? this.detectedRealTaskCount,
      infoBannerMessage: infoBannerMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    artifact?.trainedAtIso,
    artifact?.realSampleCount,
    artifact?.syntheticSampleCount,
    artifact?.testMetrics.f1,
    previousMetricsBeforeRetrain?.f1,
    currentEpoch,
    totalEpochs,
    liveTrainLosses.length,
    detectedRealTaskCount,
    infoBannerMessage,
    errorMessage,
  ];
}
