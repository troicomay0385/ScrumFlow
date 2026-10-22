import 'dart:math';

import 'baseline_models.dart';
import 'dataset.dart';
import 'feature_spec.dart';
import 'logistic_regression.dart';
import 'metrics.dart';
import 'standardizer.dart';
import 'synthetic_history_generator.dart';

/// Kết quả huấn luyện và đánh giá hoàn chỉnh của một mô hình dự đoán rủi ro trễ hạn.
class TrainedRiskModelArtifact {
  static const int currentSchemaVersion = 1;

  int get schemaVersion => currentSchemaVersion;

  final LogisticRegression model;
  final Standardizer standardizer;
  final TrainingHistory history;
  final EvaluationMetrics testMetrics;
  final EvaluationMetrics majorityBaselineMetrics;
  final EvaluationMetrics formulaBaselineMetrics;
  final int syntheticSampleCount;
  final int realSampleCount;
  final double positiveLabelRatio;
  final String trainedAtIso;

  const TrainedRiskModelArtifact({
    required this.model,
    required this.standardizer,
    required this.history,
    required this.testMetrics,
    required this.majorityBaselineMetrics,
    required this.formulaBaselineMetrics,
    required this.syntheticSampleCount,
    required this.realSampleCount,
    required this.positiveLabelRatio,
    required this.trainedAtIso,
  });

  int get totalSamples => syntheticSampleCount + realSampleCount;

  Map<String, dynamic> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'model': model.toJson(),
    'standardizer': standardizer.toJson(),
    'history': history.toJson(),
    'testMetrics': testMetrics.toJson(),
    'majorityBaselineMetrics': majorityBaselineMetrics.toJson(),
    'formulaBaselineMetrics': formulaBaselineMetrics.toJson(),
    'syntheticSampleCount': syntheticSampleCount,
    'realSampleCount': realSampleCount,
    'positiveLabelRatio': positiveLabelRatio,
    'trainedAtIso': trainedAtIso,
  };

  factory TrainedRiskModelArtifact.fromJson(Map<String, dynamic> json) {
    final version = (json['schemaVersion'] as num?)?.toInt() ?? 0;
    if (version != currentSchemaVersion) {
      throw FormatException(
        'Phiên bản schema TrainedRiskModelArtifact không khớp: $version',
      );
    }
    return TrainedRiskModelArtifact(
      model: LogisticRegression.fromJson(json['model'] as Map<String, dynamic>),
      standardizer: Standardizer.fromJson(
        json['standardizer'] as Map<String, dynamic>,
      ),
      history: TrainingHistory.fromJson(
        json['history'] as Map<String, dynamic>,
      ),
      testMetrics: EvaluationMetrics.fromJson(
        json['testMetrics'] as Map<String, dynamic>,
      ),
      majorityBaselineMetrics: EvaluationMetrics.fromJson(
        json['majorityBaselineMetrics'] as Map<String, dynamic>,
      ),
      formulaBaselineMetrics: EvaluationMetrics.fromJson(
        json['formulaBaselineMetrics'] as Map<String, dynamic>,
      ),
      syntheticSampleCount:
          (json['syntheticSampleCount'] as num?)?.toInt() ?? 0,
      realSampleCount: (json['realSampleCount'] as num?)?.toInt() ?? 0,
      positiveLabelRatio:
          (json['positiveLabelRatio'] as num?)?.toDouble() ?? 0.5,
      trainedAtIso: json['trainedAtIso'] as String? ?? '',
    );
  }
}

/// Kết quả thí nghiệm loại bỏ từng nhóm đặc trưng (Feature Group Ablation Study).
class AblationResult {
  final String groupName;
  final List<int> droppedFeatureIndices;
  final List<String> droppedFeatureKeys;
  final EvaluationMetrics metrics;
  final double aucDrop;
  final double f1Drop;
  final double accuracyDrop;

  const AblationResult({
    required this.groupName,
    required this.droppedFeatureIndices,
    required this.droppedFeatureKeys,
    required this.metrics,
    required this.aucDrop,
    required this.f1Drop,
    required this.accuracyDrop,
  });

  Map<String, dynamic> toJson() => {
    'groupName': groupName,
    'droppedFeatureIndices': droppedFeatureIndices,
    'droppedFeatureKeys': droppedFeatureKeys,
    'accuracy': metrics.accuracy,
    'f1': metrics.f1,
    'rocAuc': metrics.rocAuc,
    'aucDrop': aucDrop,
    'f1Drop': f1Drop,
    'accuracyDrop': accuracyDrop,
  };
}

/// Pipeline huấn luyện và thẩm định mô hình chuẩn (`AiTrainingPipeline` — thuần Dart).
class AiTrainingPipeline {
  static const int defaultTrainSeed = 42;
  static const int defaultHoldoutSeed = 2026;

  const AiTrainingPipeline();

  /// Huấn luyện mô hình từ tập khởi tạo `synthetic` kết hợp mẫu `realSamples` (nếu có).
  TrainedRiskModelArtifact trainModel({
    List<LabeledSample> realSamples = const [],
    int seed = defaultTrainSeed,
    int syntheticCount = 800,
    int epochs = 120,
    void Function(int epoch, double trainLoss, double valLoss)? onEpochEnd,
  }) {
    const generator = SyntheticHistoryGenerator();
    final trainDataset = generator.generate(
      count: syntheticCount,
      rng: Random(seed),
    );
    final holdoutDataset = generator.generate(
      count: 300,
      rng: Random(defaultHoldoutSeed),
    );

    final combinedTrainSamples = <LabeledSample>[
      ...trainDataset.samples,
      ...realSamples,
    ];
    final combinedTrainPool = Dataset(
      samples: combinedTrainSamples,
      featureNames: TaskFeatureSpec.keys,
    );

    return trainAndEvaluate(
      trainPool: combinedTrainPool,
      holdoutTest: holdoutDataset,
      rng: Random(seed),
      epochs: epochs,
      onEpochEnd: onEpochEnd,
    );
  }

  /// Huấn luyện mô hình trên tập `trainPool` (tự chia 85% train / 15% validation cho early stopping)
  /// và đánh giá độc lập trên tập `holdoutTest`.
  static TrainedRiskModelArtifact trainAndEvaluate({
    required Dataset trainPool,
    required Dataset holdoutTest,
    required Random rng,
    int epochs = 120,
    int batchSize = 32,
    double learningRate = 0.08,
    double l2Lambda = 0.008,
    String? trainedAtIso,
    void Function(int epoch, double trainLoss, double valLoss)? onEpochEnd,
  }) {
    final (trainSet, valSet) = trainPool.stratifiedSplit(
      testRatio: 0.15,
      rng: rng,
    );

    final effectiveTrain = trainSet.isEmpty ? trainPool : trainSet;
    final effectiveVal = valSet.isEmpty ? effectiveTrain : valSet;

    final standardizer = Standardizer.fit(
      effectiveTrain.featureMatrix,
      defaultDim: TaskFeatureSpec.featureCount,
    );

    final trainXNorm = standardizer.transformAll(effectiveTrain.featureMatrix);
    final valXNorm = standardizer.transformAll(effectiveVal.featureMatrix);
    final testXNorm = standardizer.transformAll(holdoutTest.featureMatrix);

    final model = LogisticRegression.initialized(
      dimension: standardizer.dimension,
      rng: rng,
    );

    final history = model.fit(
      trainX: trainXNorm,
      trainY: effectiveTrain.labels,
      valX: valXNorm,
      valY: effectiveVal.labels,
      rng: rng,
      epochs: epochs,
      batchSize: batchSize,
      learningRate: learningRate,
      l2Lambda: l2Lambda,
      onEpochEnd: onEpochEnd,
    );

    // Đánh giá trên tập Holdout Test độc lập
    final modelTestProbs = testXNorm
        .map(model.predictProba)
        .toList(growable: false);
    final testMetrics = MetricsCalculator.evaluate(
      labels: holdoutTest.labels,
      probabilities: modelTestProbs,
    );

    // Baseline (a): Luôn dự đoán lớp đa số
    final majorityBaseline = MajorityClassBaseline.fit(effectiveTrain.labels);
    final majorityProbs = majorityBaseline.predictProbaAll(
      holdoutTest.featureMatrix,
    );
    final majorityMetrics = MetricsCalculator.evaluate(
      labels: holdoutTest.labels,
      probabilities: majorityProbs,
    );

    // Baseline (b): Công thức cứng US-057/058
    const formulaBaseline = HardcodedFormulaBaseline();
    final formulaProbs = formulaBaseline.predictProbaAll(
      holdoutTest.featureMatrix,
    );
    final formulaMetrics = MetricsCalculator.evaluate(
      labels: holdoutTest.labels,
      probabilities: formulaProbs,
    );

    final totalSynthetic =
        trainPool.syntheticCount + holdoutTest.syntheticCount;
    final totalReal = trainPool.realCount + holdoutTest.realCount;
    final totalSamples = trainPool.length + holdoutTest.length;
    final totalPos = trainPool.positiveCount + holdoutTest.positiveCount;
    final posRatio = totalSamples > 0 ? totalPos / totalSamples : 0.0;

    return TrainedRiskModelArtifact(
      model: model,
      standardizer: standardizer,
      history: history,
      testMetrics: testMetrics,
      majorityBaselineMetrics: majorityMetrics,
      formulaBaselineMetrics: formulaMetrics,
      syntheticSampleCount: totalSynthetic,
      realSampleCount: totalReal,
      positiveLabelRatio: posRatio,
      trainedAtIso: trainedAtIso ?? DateTime.now().toIso8601String(),
    );
  }

  /// Thực hiện Ablation Study: lần lượt xoá (gán về 0 sau chuẩn hoá) từng nhóm đặc trưng
  /// và đo mức độ sụt giảm của ROC-AUC, F1, Accuracy.
  static List<AblationResult> runAblationStudy({
    required Dataset trainPool,
    required Dataset holdoutTest,
    required EvaluationMetrics fullModelMetrics,
    required int baseSeed,
  }) {
    final groups = <(String, List<int>)>[
      (
        'Nhóm Thời hạn & Tiến độ (daysToDeadline, elapsedRatio, statusProgress, sprintElapsedRatio)',
        [
          TaskFeatureSpec.idxDaysToDeadline,
          TaskFeatureSpec.idxElapsedRatio,
          TaskFeatureSpec.idxStatusProgress,
          TaskFeatureSpec.idxSprintElapsedRatio,
        ],
      ),
      (
        'Nhóm Năng lực & Tải thành viên (assigneeOnTimeRate, assigneeWorkload, unassigned)',
        [
          TaskFeatureSpec.idxAssigneeOnTimeRate,
          TaskFeatureSpec.idxAssigneeWorkload,
          TaskFeatureSpec.idxUnassigned,
        ],
      ),
      (
        'Nhóm Phạm vi & Ưu tiên Story (storyPoints, priorityRank, loggedHoursPerDay)',
        [
          TaskFeatureSpec.idxStoryPoints,
          TaskFeatureSpec.idxPriorityRank,
          TaskFeatureSpec.idxLoggedHoursPerDay,
        ],
      ),
    ];

    final results = <AblationResult>[];

    for (final (groupName, indices) in groups) {
      final maskedTrain = _maskFeatures(trainPool, indices);
      final maskedTest = _maskFeatures(holdoutTest, indices);
      final artifact = trainAndEvaluate(
        trainPool: maskedTrain,
        holdoutTest: maskedTest,
        rng: Random(baseSeed),
      );

      final droppedKeys = indices
          .map((i) => TaskFeatureSpec.definitions[i].key)
          .toList();

      results.add(
        AblationResult(
          groupName: groupName,
          droppedFeatureIndices: indices,
          droppedFeatureKeys: droppedKeys,
          metrics: artifact.testMetrics,
          aucDrop: fullModelMetrics.rocAuc - artifact.testMetrics.rocAuc,
          f1Drop: fullModelMetrics.f1 - artifact.testMetrics.f1,
          accuracyDrop:
              fullModelMetrics.accuracy - artifact.testMetrics.accuracy,
        ),
      );
    }

    return results;
  }

  static Dataset _maskFeatures(Dataset dataset, List<int> zeroedIndices) {
    final indexSet = zeroedIndices.toSet();
    final maskedSamples = dataset.samples
        .map((s) {
          final copy = List<double>.from(s.features);
          for (final idx in indexSet) {
            if (idx >= 0 && idx < copy.length) {
              copy[idx] = 0.0;
            }
          }
          return LabeledSample(
            id: s.id,
            features: copy,
            label: s.label,
            source: s.source,
          );
        })
        .toList(growable: false);

    return Dataset(samples: maskedSamples, featureNames: dataset.featureNames);
  }
}
