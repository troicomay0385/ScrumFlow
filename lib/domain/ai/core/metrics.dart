import 'dart:math';

/// Ma trận nhầm lẫn 2×2 (Confusion Matrix) cho phân loại nhị phân:
/// - [tp] (True Positive): Thực tế trễ hạn (1), dự đoán trễ hạn (1).
/// - [fp] (False Positive): Thực tế đúng hạn (0), dự đoán nhầm là trễ hạn (1).
/// - [tn] (True Negative): Thực tế đúng hạn (0), dự đoán đúng hạn (0).
/// - [fn] (False Negative): Thực tế trễ hạn (1), bỏ sót dự đoán là đúng hạn (0).
class ConfusionMatrix {
  final int tp;
  final int fp;
  final int tn;
  final int fn;

  const ConfusionMatrix({
    required this.tp,
    required this.fp,
    required this.tn,
    required this.fn,
  });

  int get total => tp + fp + tn + fn;

  Map<String, dynamic> toJson() => {'tp': tp, 'fp': fp, 'tn': tn, 'fn': fn};

  factory ConfusionMatrix.fromJson(Map<String, dynamic> json) {
    return ConfusionMatrix(
      tp: (json['tp'] as num?)?.toInt() ?? 0,
      fp: (json['fp'] as num?)?.toInt() ?? 0,
      tn: (json['tn'] as num?)?.toInt() ?? 0,
      fn: (json['fn'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Một khoảng chia (bin) trong bảng hiệu chỉnh xác suất (Reliability / Calibration Curve).
class CalibrationBin {
  final int binIndex;
  final double lowerBound;
  final double upperBound;
  final int count;
  final double meanPredicted;
  final double fractionPositive;

  const CalibrationBin({
    required this.binIndex,
    required this.lowerBound,
    required this.upperBound,
    required this.count,
    required this.meanPredicted,
    required this.fractionPositive,
  });

  double get calibrationGap =>
      count == 0 ? 0.0 : (meanPredicted - fractionPositive).abs();

  Map<String, dynamic> toJson() => {
    'binIndex': binIndex,
    'lowerBound': lowerBound,
    'upperBound': upperBound,
    'count': count,
    'meanPredicted': meanPredicted,
    'fractionPositive': fractionPositive,
  };

  factory CalibrationBin.fromJson(Map<String, dynamic> json) {
    return CalibrationBin(
      binIndex: (json['binIndex'] as num?)?.toInt() ?? 0,
      lowerBound: (json['lowerBound'] as num?)?.toDouble() ?? 0.0,
      upperBound: (json['upperBound'] as num?)?.toDouble() ?? 0.1,
      count: (json['count'] as num?)?.toInt() ?? 0,
      meanPredicted: (json['meanPredicted'] as num?)?.toDouble() ?? 0.0,
      fractionPositive: (json['fractionPositive'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Tập hợp toàn bộ các chỉ số đánh giá chất lượng mô hình phân loại nhị phân.
class EvaluationMetrics {
  final double accuracy;
  final double precision;
  final double recall;
  final double f1;
  final double rocAuc;
  final double brierScore;
  final double expectedCalibrationError;
  final ConfusionMatrix confusionMatrix;
  final List<CalibrationBin> calibrationBins;

  EvaluationMetrics({
    required this.accuracy,
    required this.precision,
    required this.recall,
    required this.f1,
    required this.rocAuc,
    required this.brierScore,
    required this.expectedCalibrationError,
    required this.confusionMatrix,
    required List<CalibrationBin> calibrationBins,
  }) : calibrationBins = List<CalibrationBin>.unmodifiable(calibrationBins);

  Map<String, dynamic> toJson() => {
    'accuracy': accuracy,
    'precision': precision,
    'recall': recall,
    'f1': f1,
    'rocAuc': rocAuc,
    'brierScore': brierScore,
    'expectedCalibrationError': expectedCalibrationError,
    'confusionMatrix': confusionMatrix.toJson(),
    'calibrationBins': calibrationBins.map((b) => b.toJson()).toList(),
  };

  factory EvaluationMetrics.fromJson(Map<String, dynamic> json) {
    final bins = (json['calibrationBins'] as List<dynamic>? ?? const [])
        .map((e) => CalibrationBin.fromJson(e as Map<String, dynamic>))
        .toList();
    return EvaluationMetrics(
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      precision: (json['precision'] as num?)?.toDouble() ?? 0.0,
      recall: (json['recall'] as num?)?.toDouble() ?? 0.0,
      f1: (json['f1'] as num?)?.toDouble() ?? 0.0,
      rocAuc: (json['rocAuc'] as num?)?.toDouble() ?? 0.5,
      brierScore: (json['brierScore'] as num?)?.toDouble() ?? 0.25,
      expectedCalibrationError:
          (json['expectedCalibrationError'] as num?)?.toDouble() ?? 0.0,
      confusionMatrix: json['confusionMatrix'] is Map<String, dynamic>
          ? ConfusionMatrix.fromJson(
              json['confusionMatrix'] as Map<String, dynamic>,
            )
          : const ConfusionMatrix(tp: 0, fp: 0, tn: 0, fn: 0),
      calibrationBins: bins,
    );
  }
}

/// Bộ tính toán các độ đo đánh giá mô hình học máy (`MetricsCalculator`).
class MetricsCalculator {
  MetricsCalculator._();

  /// Đánh giá toàn diện từ danh sách nhãn thực tế [labels] và xác suất dự đoán [probabilities].
  static EvaluationMetrics evaluate({
    required List<int> labels,
    required List<double> probabilities,
    double threshold = 0.5,
    int numCalibrationBins = 10,
  }) {
    final n = min(labels.length, probabilities.length);
    if (n == 0) {
      return EvaluationMetrics(
        accuracy: 0.0,
        precision: 0.0,
        recall: 0.0,
        f1: 0.0,
        rocAuc: 0.5,
        brierScore: 0.0,
        expectedCalibrationError: 0.0,
        confusionMatrix: const ConfusionMatrix(tp: 0, fp: 0, tn: 0, fn: 0),
        calibrationBins: const [],
      );
    }

    int tp = 0;
    int fp = 0;
    int tn = 0;
    int fn = 0;
    double brierSum = 0.0;

    for (int i = 0; i < n; i++) {
      final y = labels[i] == 1 ? 1 : 0;
      final p = probabilities[i].isNaN ? 0.5 : probabilities[i].clamp(0.0, 1.0);
      final pred = p >= threshold ? 1 : 0;

      if (y == 1 && pred == 1) {
        tp++;
      } else if (y == 0 && pred == 1) {
        fp++;
      } else if (y == 0 && pred == 0) {
        tn++;
      } else {
        fn++;
      }

      final diff = p - y;
      brierSum += diff * diff;
    }

    final accuracy = (tp + tn) / n;
    final precision = (tp + fp) > 0 ? tp / (tp + fp) : 0.0;
    final recall = (tp + fn) > 0 ? tp / (tp + fn) : 0.0;
    final f1 = (precision + recall) > 0
        ? (2.0 * precision * recall) / (precision + recall)
        : 0.0;
    final brierScore = brierSum / n;
    final rocAuc = computeRocAuc(labels, probabilities);
    final bins = computeCalibrationBins(
      labels: labels,
      probabilities: probabilities,
      numBins: numCalibrationBins,
    );

    double ece = 0.0;
    for (final bin in bins) {
      if (bin.count > 0) {
        ece += (bin.count / n) * bin.calibrationGap;
      }
    }

    return EvaluationMetrics(
      accuracy: accuracy,
      precision: precision,
      recall: recall,
      f1: f1,
      rocAuc: rocAuc,
      brierScore: brierScore,
      expectedCalibrationError: ece,
      confusionMatrix: ConfusionMatrix(tp: tp, fp: fp, tn: tn, fn: fn),
      calibrationBins: bins,
    );
  }

  /// Tính diện tích dưới đường cong ROC (ROC-AUC) theo quy tắc hình thang
  /// có xử lý đồng hạng (ties) chính xác tương đương chuẩn Mann-Whitney U statistic.
  ///
  /// - Trả về `0.5` nếu dữ liệu rỗng, chỉ có 1 lớp duy nhất, hoặc mọi dự đoán bằng nhau.
  /// - Trả về `1.0` nếu mọi mẫu dương đều có xác suất dự đoán lớn hơn mọi mẫu âm.
  static double computeRocAuc(List<int> labels, List<double> probabilities) {
    final n = min(labels.length, probabilities.length);
    if (n == 0) return 0.5;

    final pairs = <(double, int)>[];
    int totalPos = 0;
    int totalNeg = 0;

    for (int i = 0; i < n; i++) {
      final y = labels[i] == 1 ? 1 : 0;
      final p = probabilities[i].isNaN ? 0.5 : probabilities[i].clamp(0.0, 1.0);
      pairs.add((p, y));
      if (y == 1) {
        totalPos++;
      } else {
        totalNeg++;
      }
    }

    if (totalPos == 0 || totalNeg == 0) return 0.5;

    // Sắp xếp theo xác suất dự đoán giảm dần
    pairs.sort((a, b) => b.$1.compareTo(a.$1));

    double aucArea = 0.0;
    double prevTp = 0.0;
    double prevFp = 0.0;
    double curTp = 0.0;
    double curFp = 0.0;

    int i = 0;
    while (i < n) {
      final currentScore = pairs[i].$1;
      // Gom tất cả các mẫu có cùng điểm số dự đoán (xử lý ties)
      while (i < n && (pairs[i].$1 - currentScore).abs() <= 1e-12) {
        if (pairs[i].$2 == 1) {
          curTp += 1.0;
        } else {
          curFp += 1.0;
        }
        i++;
      }
      // Cộng diện tích hình thang dưới đường cong ROC
      aucArea += (curFp - prevFp) * (curTp + prevTp) * 0.5;
      prevTp = curTp;
      prevFp = curFp;
    }

    return (aucArea / (totalPos * totalNeg)).clamp(0.0, 1.0);
  }

  /// Chia xác suất dự đoán vào [numBins] khoảng đều trên `[0.0, 1.0]` (mặc định 10 bin)
  /// để kiểm tra độ hiệu chỉnh xác suất (calibration).
  static List<CalibrationBin> computeCalibrationBins({
    required List<int> labels,
    required List<double> probabilities,
    int numBins = 10,
  }) {
    final safeBins = max(1, numBins);
    final n = min(labels.length, probabilities.length);
    final counts = List<int>.filled(safeBins, 0);
    final sumPred = List<double>.filled(safeBins, 0.0);
    final sumPos = List<int>.filled(safeBins, 0);

    for (int i = 0; i < n; i++) {
      final p = probabilities[i].isNaN ? 0.5 : probabilities[i].clamp(0.0, 1.0);
      final y = labels[i] == 1 ? 1 : 0;
      int binIdx = (p * safeBins).floor();
      if (binIdx >= safeBins) binIdx = safeBins - 1;
      if (binIdx < 0) binIdx = 0;

      counts[binIdx]++;
      sumPred[binIdx] += p;
      sumPos[binIdx] += y;
    }

    final result = <CalibrationBin>[];
    for (int b = 0; b < safeBins; b++) {
      final lower = b / safeBins;
      final upper = (b + 1) / safeBins;
      final c = counts[b];
      result.add(
        CalibrationBin(
          binIndex: b,
          lowerBound: lower,
          upperBound: upper,
          count: c,
          meanPredicted: c > 0 ? sumPred[b] / c : (lower + upper) * 0.5,
          fractionPositive: c > 0 ? sumPos[b] / c : 0.0,
        ),
      );
    }
    return result;
  }
}
