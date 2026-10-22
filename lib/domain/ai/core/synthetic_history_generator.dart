import 'dart:math';

import 'dataset.dart';
import 'feature_spec.dart';
import 'logistic_regression.dart';

/// Cấu hình thay đổi phân phối dữ liệu (Distribution Shift) dùng để kiểm tra
/// độ bền vững (robustness) của mô hình khi môi trường dự án thay đổi.
class DistributionShiftConfig {
  /// Độ lệch cộng thêm vào tải công việc trung bình của thành viên.
  final double workloadShift;

  /// Hệ số co giãn thời gian còn lại tới hạn (VD: < 1.0 nghĩa là hạn gấp hơn).
  final double deadlineScale;

  /// Tỷ lệ task chưa phân công trong tập dữ liệu lệch.
  final double unassignedRate;

  const DistributionShiftConfig({
    this.workloadShift = 0.0,
    this.deadlineScale = 1.0,
    this.unassignedRate = 0.18,
  });

  static const DistributionShiftConfig defaultConfig =
      DistributionShiftConfig();

  /// Kịch bản áp lực cao: tải thành viên tăng +0.25, hạn chót ngắn đi 25%, tỷ lệ chưa gán 28%.
  static const DistributionShiftConfig highPressureShift =
      DistributionShiftConfig(
        workloadShift: 0.25,
        deadlineScale: 0.75,
        unassignedRate: 0.28,
      );
}

/// Bộ sinh dữ liệu lịch sử tổng hợp (`SyntheticHistoryGenerator` — mục 4.7 MASTER_PROMPT).
///
/// Tạo dữ liệu khởi tạo (bootstrap) mô phỏng lịch sử thực hiện các Task Agile/Scrum:
/// - Mọi mẫu sinh ra đều được gắn nhãn rõ ràng `source = SampleSource.synthetic`.
/// - Có **nhiễu Gaussian** trên các đặc trưng đo lường.
/// - Có **tương tác phi tuyến nhẹ** (tải công việc cao × hạn chót gấp; task chưa bắt đầu khi đã trôi qua >70% thời gian).
/// - Có **nhiễu đảo nhãn ngẫu nhiên (label flip noise ~6%)** mô phỏng rủi ro ngoại cảnh (ốm đau, đổi yêu cầu đột xuất),
///   đảm bảo độ chính xác của mô hình nằm trong vùng thực tế ~78% – 90% (không bao giờ đạt mức giả tạo ≥ 97%).
class SyntheticHistoryGenerator {
  static const List<double> _fibonacciPoints = [1, 2, 3, 5, 8, 13, 21];

  final double labelFlipNoiseRate;
  final double latentGaussianNoiseStd;

  const SyntheticHistoryGenerator({
    this.labelFlipNoiseRate = 0.055,
    this.latentGaussianNoiseStd = 0.35,
  });

  /// Sinh [count] mẫu dữ liệu tổng hợp (mặc định 800 task) từ bộ sinh ngẫu nhiên [rng].
  Dataset generate({
    int count = 800,
    required Random rng,
    DistributionShiftConfig shift = DistributionShiftConfig.defaultConfig,
  }) {
    final samples = <LabeledSample>[];

    for (int i = 0; i < count; i++) {
      // 0. storyPoints: chọn từ dãy Fibonacci (thiên về 2, 3, 5, 8)
      final spIdx = _sampleWeightedIndex(rng, const [
        0.12,
        0.20,
        0.26,
        0.20,
        0.12,
        0.07,
        0.03,
      ]);
      final storyPoints = _fibonacciPoints[spIdx];

      // 1. priorityRank: 0 (THẤP), 1 (TB), 2 (CAO)
      final priorityRank = _sampleWeightedIndex(rng, const [
        0.25,
        0.45,
        0.30,
      ]).toDouble();

      // 8. sprintElapsedRatio: tiến độ thời gian của Sprint hiện tại [0.0, 1.2]
      final sprintElapsedRatio =
          (0.1 + rng.nextDouble() * 0.95 + _normal(rng) * 0.04).clamp(0.0, 1.2);

      // 3. elapsedRatio: tỷ lệ thời gian task đã trôi qua, tương quan nhẹ với sprint
      final rawElapsed =
          0.65 * (rng.nextDouble() * 1.35) +
          0.35 * sprintElapsedRatio +
          _normal(rng) * 0.08;
      final elapsedRatio = rawElapsed.clamp(0.0, 1.5);

      // 2. daysToDeadline: nghịch biến với elapsedRatio + nhiễu Gaussian
      final baseDays =
          (1.0 - elapsedRatio) * 10.0 * shift.deadlineScale +
          _normal(rng) * 2.2;
      final daysToDeadline = baseDays.clamp(-7.0, 14.0);

      // 9. unassigned: chưa có người phụ trách
      final isUnassigned = rng.nextDouble() < shift.unassignedRate;
      final unassigned = isUnassigned ? 1.0 : 0.0;

      // 5. statusProgress: nếu chưa gán thì thường vẫn ở To Do (0.0)
      final double statusProgress;
      if (isUnassigned) {
        statusProgress = rng.nextDouble() < 0.82 ? 0.0 : 0.5;
      } else {
        final inProgProb = (0.30 + 0.45 * elapsedRatio).clamp(0.15, 0.85);
        statusProgress = rng.nextDouble() < inProgProb ? 0.5 : 0.0;
      }

      // 4. loggedHoursPerDay: phụ thuộc vào statusProgress + nhiễu
      final baseHours = statusProgress > 0
          ? (1.2 + rng.nextDouble() * 3.2 + _normal(rng) * 0.5)
          : (rng.nextDouble() * 0.8);
      final loggedHoursPerDay = baseHours.clamp(0.0, 12.0);

      // 6 & 7. assigneeOnTimeRate & assigneeWorkload
      final double assigneeOnTimeRate;
      final double assigneeWorkload;
      if (isUnassigned) {
        assigneeOnTimeRate = TaskFeatureSpec
            .definitions[TaskFeatureSpec.idxAssigneeOnTimeRate]
            .defaultCheckpointValue;
        assigneeWorkload = 0.0;
      } else {
        assigneeOnTimeRate =
            (0.35 + rng.nextDouble() * 0.65 + _normal(rng) * 0.05).clamp(
              0.0,
              1.0,
            );
        final rawWorkload =
            (rng.nextInt(6) / 5.0) + shift.workloadShift + _normal(rng) * 0.06;
        assigneeWorkload = rawWorkload.clamp(0.0, 1.5);
      }

      final features = <double>[
        storyPoints,
        priorityRank,
        daysToDeadline,
        elapsedRatio,
        loggedHoursPerDay,
        statusProgress,
        assigneeOnTimeRate,
        assigneeWorkload,
        sprintElapsedRatio,
        unassigned,
      ];

      // Tính xác suất trễ hạn tiềm ẩn (Ground-Truth DGP):
      // Kết hợp thành phần tuyến tính + tương tác phi tuyến nhẹ + nhiễu tiềm ẩn Gaussian
      final linearScore =
          1.45 *
          (0.14 * (storyPoints - 5.0) +
              0.28 * (priorityRank - 1.0) -
              0.32 * (daysToDeadline - 2.5) +
              2.35 * (elapsedRatio - 0.68) -
              0.30 * (loggedHoursPerDay - 1.6) -
              1.35 * (statusProgress - 0.25) -
              2.50 * (assigneeOnTimeRate - 0.68) +
              1.65 * (assigneeWorkload - 0.45) +
              0.85 * (sprintElapsedRatio - 0.55) +
              1.25 * unassigned);

      // Tương tác phi tuyến 1: Tải công việc cao đi kèm thời gian còn lại gấp
      final overloadUrgencyInteraction =
          0.65 *
          max(0.0, assigneeWorkload - 0.6) *
          max(0.0, 2.5 - daysToDeadline);

      // Tương tác phi tuyến 2: Đã qua 75% thời gian nhưng trạng thái vẫn ở To Do (0.0)
      final lateUnstartedPenalty =
          (elapsedRatio > 0.75 && statusProgress == 0.0) ? 0.70 : 0.0;

      final noisyLogit =
          linearScore +
          overloadUrgencyInteraction +
          lateUnstartedPenalty +
          _normal(rng) * latentGaussianNoiseStd;

      final probDelay = LogisticRegression.sigmoid(noisyLogit);
      int label = rng.nextDouble() < probDelay ? 1 : 0;

      // Đảo nhãn ngẫu nhiên (5–8%) mô phỏng biến cố thực tế không quan sát được
      if (rng.nextDouble() < labelFlipNoiseRate) {
        label = 1 - label;
      }

      samples.add(
        LabeledSample(
          id: 'syn_$i',
          features: features,
          label: label,
          source: SampleSource.synthetic,
        ),
      );
    }

    return Dataset(samples: samples, featureNames: TaskFeatureSpec.keys);
  }

  /// Sinh biến ngẫu nhiên chuẩn chuẩn tắc $N(0, 1)$ bằng phép biến đổi Box-Muller.
  static double _normal(Random rng) {
    final u1 = max(1e-10, rng.nextDouble());
    final u2 = rng.nextDouble();
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
  }

  static int _sampleWeightedIndex(Random rng, List<double> weights) {
    final u = rng.nextDouble();
    double cumulative = 0.0;
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (u <= cumulative) return i;
    }
    return weights.length - 1;
  }
}
