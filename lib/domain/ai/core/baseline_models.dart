import 'feature_spec.dart';

/// Baseline (a): Mô hình dự đoán theo lớp đa số (`MajorityClassBaseline`).
///
/// Luôn dự đoán nhãn xuất hiện nhiều nhất trên tập huấn luyện (hoặc trả về
/// xác suất cố định bằng tỷ lệ lớp dương trên tập huấn luyện).
/// Do mọi mẫu đều nhận cùng một điểm xác suất nên ROC-AUC của baseline (a) luôn bằng `0.5`.
class MajorityClassBaseline {
  final int majorityClass;
  final double positiveProbability;

  const MajorityClassBaseline({
    required this.majorityClass,
    required this.positiveProbability,
  });

  factory MajorityClassBaseline.fit(List<int> trainLabels) {
    if (trainLabels.isEmpty) {
      return const MajorityClassBaseline(
        majorityClass: 0,
        positiveProbability: 0.0,
      );
    }
    int pos = 0;
    for (final y in trainLabels) {
      if (y == 1) pos++;
    }
    final ratio = pos / trainLabels.length;
    return MajorityClassBaseline(
      majorityClass: ratio >= 0.5 ? 1 : 0,
      positiveProbability: ratio,
    );
  }

  double predictProba(List<double> _) => positiveProbability;

  int predictClass(List<double> _) => majorityClass;

  List<double> predictProbaAll(List<List<double>> X) =>
      List<double>.filled(X.length, positiveProbability);
}

/// Baseline (b): Bản sao công thức cứng US-057 / US-058 (`HardcodedFormulaBaseline`).
///
/// Tái hiện đúng thuật toán tính điểm hiệu suất thành viên của `PerformanceScoreService`
/// trong lõi thuần Dart (không import `PerformanceScoreService` để tránh kéo theo
/// phụ thuộc `cloud_firestore` làm hỏng `dart run`):
///
/// $$\text{finalScore} = 0.5 \cdot \text{onTimeRate} + 0.3 \cdot \text{workloadFactor} + 0.2 \cdot \text{ratingScore}$$
///
/// Trong đó:
/// - $\text{onTimeRate} \in [0, 1]$
/// - $\text{workloadFactor} = \text{clamp}(1 - \frac{\text{inProgress}}{\text{workloadMax}}, 0, 1)$
/// - $\text{ratingScore} = 1.0$ (gán cứng theo US-058)
///
/// Khi chuyển đổi sang xác suất rủi ro trễ hạn của Task:
/// - Thành phần biến thiên của điểm hiệu suất nằm trong $[0, 0.8]$ (do $0.2 \cdot \text{ratingScore} = 0.2$ cố định).
/// - Đảo ngược thành điểm rủi ro:
///   $$\text{riskProba} = 1.0 - \frac{0.5 \cdot \text{onTimeRate} + 0.3 \cdot \text{workloadFactor}}{0.8}$$
class HardcodedFormulaBaseline {
  final double w1;
  final double w2;
  final double w3;
  final int workloadMax;

  const HardcodedFormulaBaseline({
    this.w1 = 0.5,
    this.w2 = 0.3,
    this.w3 = 0.2,
    this.workloadMax = 5,
  });

  /// Công thức gốc US-058 tính `finalScore` cho một thành viên từ thống kê task.
  /// Được kiểm chứng khớp tuyệt đối 100% với `PerformanceScoreService` trong unit test.
  double calculateMemberFinalScore({
    required int completedOnTime,
    required int completedOverdue,
    required int inProgress,
  }) {
    final completedTasks = completedOnTime + completedOverdue;
    final double onTimeRate = completedTasks > 0
        ? (completedOnTime / completedTasks).clamp(0.0, 1.0)
        : 1.0;
    final double workloadFactor = (1.0 - (inProgress / workloadMax.toDouble()))
        .clamp(0.0, 1.0);
    const double ratingScore = 1.0;

    return (w1 * onTimeRate + w2 * workloadFactor + w3 * ratingScore).clamp(
      0.0,
      1.0,
    );
  }

  /// Tính `finalScore` US-058 trực tiếp từ vector đặc trưng thô `rawFeatures` của Task.
  double computeUs058ScoreFromFeatures(List<double> rawFeatures) {
    final onTimeRate =
        rawFeatures.length > TaskFeatureSpec.idxAssigneeOnTimeRate
        ? rawFeatures[TaskFeatureSpec.idxAssigneeOnTimeRate].clamp(0.0, 1.0)
        : 1.0;
    // Feature idxAssigneeWorkload = inProgress / workloadMax
    final workloadRatio =
        rawFeatures.length > TaskFeatureSpec.idxAssigneeWorkload
        ? rawFeatures[TaskFeatureSpec.idxAssigneeWorkload]
        : 0.0;
    final workloadFactor = (1.0 - workloadRatio).clamp(0.0, 1.0);
    const ratingScore = 1.0;
    return (w1 * onTimeRate + w2 * workloadFactor + w3 * ratingScore).clamp(
      0.0,
      1.0,
    );
  }

  /// Đảo ngược điểm hiệu suất US-057/058 thành xác suất rủi ro trễ hạn `∈ [0, 1]`.
  double predictProba(List<double> rawFeatures) {
    final onTimeRate =
        rawFeatures.length > TaskFeatureSpec.idxAssigneeOnTimeRate
        ? rawFeatures[TaskFeatureSpec.idxAssigneeOnTimeRate].clamp(0.0, 1.0)
        : 1.0;
    final workloadRatio =
        rawFeatures.length > TaskFeatureSpec.idxAssigneeWorkload
        ? rawFeatures[TaskFeatureSpec.idxAssigneeWorkload]
        : 0.0;
    final workloadFactor = (1.0 - workloadRatio).clamp(0.0, 1.0);

    final activeWeightSum = (w1 + w2) > 0 ? (w1 + w2) : 0.8;
    final normalizedPerf =
        ((w1 * onTimeRate + w2 * workloadFactor) / activeWeightSum).clamp(
          0.0,
          1.0,
        );
    return (1.0 - normalizedPerf).clamp(0.0, 1.0);
  }

  int predictClass(List<double> rawFeatures, {double threshold = 0.5}) {
    return predictProba(rawFeatures) >= threshold ? 1 : 0;
  }

  List<double> predictProbaAll(List<List<double>> rawFeatureMatrix) =>
      rawFeatureMatrix.map(predictProba).toList(growable: false);
}
