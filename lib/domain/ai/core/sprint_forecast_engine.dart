import 'dart:math';

import 'feature_spec.dart';

/// Nguồn thông lượng (throughput) dùng cho mô phỏng Monte Carlo (US-070):
/// 1. [closedSprintsVelocity]: Lấy từ velocity của các Sprint đã đóng (`Completed`/`Closed`).
/// 2. [activeSprintBurnRate]: Lấy từ tốc độ hoàn thành theo ngày của Sprint đang chạy.
/// 3. [defaultPrior]: Dùng phân phối prior mặc định khi dự án chưa có lịch sử hoàn thành
///    (bật cờ `isLowConfidence = true` để cảnh báo trên UI).
enum ThroughputSourceType {
  closedSprintsVelocity,
  activeSprintBurnRate,
  defaultPrior;

  String get labelVi {
    switch (this) {
      case ThroughputSourceType.closedSprintsVelocity:
        return 'Velocity các Sprint đã đóng';
      case ThroughputSourceType.activeSprintBurnRate:
        return 'Tốc độ burn của Sprint hiện tại';
      case ThroughputSourceType.defaultPrior:
        return 'Ước lượng khởi tạo (dữ liệu lịch sử ít)';
    }
  }
}

/// Thông tin một User Story chưa hoàn thành dùng cho phân tích What-if loại bớt Story.
class ForecastStoryCandidate {
  final String storyId;
  final String storyKey;
  final String title;
  final int storyPoints;
  final String priority;

  const ForecastStoryCandidate({
    required this.storyId,
    required this.storyKey,
    required this.title,
    required this.storyPoints,
    this.priority = 'TB',
  });
}

/// Gợi ý What-if: nếu dời [story] ra khỏi Sprint hiện tại thì xác suất hoàn thành
/// đúng hạn tăng từ [baseProbability] lên [newProbability].
class StoryRemovalSuggestion {
  final ForecastStoryCandidate story;
  final double baseProbability;
  final double newProbability;

  const StoryRemovalSuggestion({
    required this.story,
    required this.baseProbability,
    required this.newProbability,
  });

  double get probabilityGain =>
      (newProbability - baseProbability).clamp(0.0, 1.0);
  int get basePercent => (baseProbability * 100).round();
  int get newPercent => (newProbability * 100).round();
}

/// Kết quả mô phỏng Monte Carlo cho một Sprint (US-070).
class SprintForecastResult {
  /// Xác suất hoàn thành toàn bộ điểm còn lại trong số ngày còn lại của Sprint `∈ [0, 1]`.
  final double completionProbability;

  /// Số ngày cần thêm để hoàn thành toàn bộ phần việc còn lại ở phân vị p10 (lạc quan),
  /// p50 (trung vị), p90 (thận trọng).
  final int daysToCompleteP10;
  final int daysToCompleteP50;
  final int daysToCompleteP90;

  /// Số điểm Story Points dự kiến còn tồn đọng vào ngày kết thúc Sprint (p10, p50, p90).
  final double expectedRemainingPointsP10;
  final double expectedRemainingPointsP50;
  final double expectedRemainingPointsP90;

  /// Chuỗi điểm còn lại theo từng ngày của toàn Sprint (độ dài = `totalSprintDays`)
  /// ở các mức phân vị p10 (lạc quan - thấp), p50 (trung vị), p90 (bi quan - cao)
  /// dùng để vẽ dải dự báo chồng lên `BurndownChartWidget`.
  /// Các ngày trong quá khứ (`< currentDayIndex`) có giá trị `null`.
  final List<double?> bandP10;
  final List<double?> bandP50;
  final List<double?> bandP90;

  final int currentDayIndex;
  final int totalSprintDays;
  final int remainingStoryPoints;
  final int simulationsRun;
  final ThroughputSourceType sourceType;
  final bool isLowConfidence;
  final double meanDailyThroughput;

  /// Danh sách gợi ý What-if dời bớt Story chưa hoàn thành (xếp giảm dần theo mức tăng xác suất).
  final List<StoryRemovalSuggestion> whatIfSuggestions;

  SprintForecastResult({
    required this.completionProbability,
    required this.daysToCompleteP10,
    required this.daysToCompleteP50,
    required this.daysToCompleteP90,
    required this.expectedRemainingPointsP10,
    required this.expectedRemainingPointsP50,
    required this.expectedRemainingPointsP90,
    required List<double?> bandP10,
    required List<double?> bandP50,
    required List<double?> bandP90,
    required this.currentDayIndex,
    required this.totalSprintDays,
    required this.remainingStoryPoints,
    required this.simulationsRun,
    required this.sourceType,
    required this.isLowConfidence,
    required this.meanDailyThroughput,
    this.whatIfSuggestions = const [],
  }) : bandP10 = List<double?>.unmodifiable(bandP10),
       bandP50 = List<double?>.unmodifiable(bandP50),
       bandP90 = List<double?>.unmodifiable(bandP90);

  int get completionPercent => (completionProbability * 100).round();

  /// Rủi ro trễ Sprint = `1 - completionProbability`, phân loại theo cùng ngưỡng `RiskThresholds`.
  RiskLevel get sprintRiskLevel =>
      RiskThresholds.classify(1.0 - completionProbability);
}

/// Động cơ mô phỏng Monte Carlo thuần Dart dự báo tiến độ hoàn thành Sprint (`SprintForecastEngine` — US-070).
///
/// ### Nguyên lý thuật toán:
/// 1. **Xác định phân phối thông lượng ngày (Daily Throughput Distribution):**
///    - Ưu tiên (a): Lấy mẫu từ lịch sử thông lượng/ngày của các Sprint đã đóng (`historicalDailyThroughputs`).
///    - Ưu tiên (b): Nếu chưa có Sprint đóng, lấy từ chuỗi điểm hoàn thành theo ngày của Sprint hiện tại (`activeSprintDailyBurn`).
///    - Ưu tiên (c): Nếu chưa có dữ liệu burn, sử dụng mẫu prior mặc định (`[0.0, 0.5, 1.0, 1.5, 2.0, 2.5]` SP/ngày) và bật cờ `isLowConfidence = true`.
///
/// 2. **Mô phỏng Monte Carlo ($N = 1000$ kịch bản):**
///    - Với mỗi kịch bản $m \in \{1..N\}$, lấy mẫu có hoàn lại (bootstrap resampling kèm nhiễu nhẹ) thông lượng cho từng ngày còn lại của Sprint.
///    - Cập nhật quỹ đạo điểm còn lại: $R_{t+1} = \max(0, R_t - v_t)$.
///    - Đếm tỷ lệ kịch bản đạt $R_{\text{end}} = 0$ để suy ra $\hat{P}(\text{hoàn thành đúng hạn})$.
///    - Trích xuất phân vị thứ 10 (`p10`), 50 (`p50`) và 90 (`p90`) của quỹ đạo điểm còn lại theo từng ngày và số ngày cần để hoàn tất.
class SprintForecastEngine {
  /// Mẫu prior mặc định (Story Points / ngày) khi dự án hoàn toàn chưa có dữ liệu lịch sử.
  /// Tương ứng tốc độ trung bình ~1.25 SP/ngày (khoảng 17.5 SP cho một Sprint 14 ngày).
  static const List<double> defaultPriorSamples = [
    0.0,
    0.5,
    1.0,
    1.0,
    1.5,
    2.0,
    2.5,
  ];

  const SprintForecastEngine();

  /// Thực hiện mô phỏng Monte Carlo dự báo khả năng hoàn thành Sprint.
  SprintForecastResult simulate({
    required double remainingPoints,
    required int daysLeft,
    int totalSprintDays = 14,
    int currentDayIndex = 0,
    List<double> historicalDailyThroughputs = const [],
    List<double> activeSprintDailyBurn = const [],
    List<ForecastStoryCandidate> incompleteStories = const [],
    int numSimulations = 1000,
    required Random rng,
  }) {
    final safeSimulations = max(10, numSimulations);
    final safeRemaining = max(0.0, remainingPoints);
    final safeDaysLeft = max(0, daysLeft);
    final safeTotalDays = max(
      1,
      max(totalSprintDays, currentDayIndex + safeDaysLeft + 1),
    );
    final safeCurrentIdx = currentDayIndex.clamp(0, safeTotalDays - 1);

    // Lựa chọn nguồn thông lượng theo đúng thứ tự ưu tiên (a) -> (b) -> (c)
    final ThroughputSourceType sourceType;
    final List<double> empiricalPool;
    final bool isLowConfidence;

    final validHistorical = historicalDailyThroughputs
        .where((v) => !v.isNaN && !v.isInfinite && v >= 0.0)
        .toList();
    final validActive = activeSprintDailyBurn
        .where((v) => !v.isNaN && !v.isInfinite && v >= 0.0)
        .toList();

    if (validHistorical.isNotEmpty) {
      sourceType = ThroughputSourceType.closedSprintsVelocity;
      empiricalPool = validHistorical;
      isLowConfidence = false;
    } else if (validActive.isNotEmpty && validActive.any((v) => v > 0)) {
      sourceType = ThroughputSourceType.activeSprintBurnRate;
      empiricalPool = validActive;
      isLowConfidence = validActive.length < 3;
    } else {
      sourceType = ThroughputSourceType.defaultPrior;
      empiricalPool = defaultPriorSamples;
      isLowConfidence = true;
    }

    final meanThroughput =
        empiricalPool.fold<double>(0.0, (a, b) => a + b) / empiricalPool.length;

    // Trường hợp biên 1: Đã hoàn thành toàn bộ điểm (remaining == 0)
    if (safeRemaining <= 1e-9) {
      final zeroBand = List<double?>.generate(
        safeTotalDays,
        (idx) => idx >= safeCurrentIdx ? 0.0 : null,
      );
      return SprintForecastResult(
        completionProbability: 1.0,
        daysToCompleteP10: 0,
        daysToCompleteP50: 0,
        daysToCompleteP90: 0,
        expectedRemainingPointsP10: 0.0,
        expectedRemainingPointsP50: 0.0,
        expectedRemainingPointsP90: 0.0,
        bandP10: zeroBand,
        bandP50: zeroBand,
        bandP90: zeroBand,
        currentDayIndex: safeCurrentIdx,
        totalSprintDays: safeTotalDays,
        remainingStoryPoints: 0,
        simulationsRun: safeSimulations,
        sourceType: sourceType,
        isLowConfidence: isLowConfidence,
        meanDailyThroughput: meanThroughput,
        whatIfSuggestions: const [],
      );
    }

    // Trường hợp biên 2: Hết thời gian (daysLeft == 0) nhưng vẫn còn việc (remaining > 0)
    if (safeDaysLeft == 0) {
      final constBand = List<double?>.generate(
        safeTotalDays,
        (idx) => idx == safeCurrentIdx ? safeRemaining : null,
      );
      final estDays = meanThroughput > 0.1
          ? (safeRemaining / meanThroughput).ceil()
          : 14;
      final suggestions = _computeWhatIfSuggestions(
        baseProbability: 0.0,
        remainingPoints: safeRemaining,
        daysLeft: safeDaysLeft,
        empiricalPool: empiricalPool,
        incompleteStories: incompleteStories,
        numSimulations: min(400, safeSimulations),
        rng: rng,
      );
      return SprintForecastResult(
        completionProbability: 0.0,
        daysToCompleteP10: max(1, (estDays * 0.7).round()),
        daysToCompleteP50: max(1, estDays),
        daysToCompleteP90: max(1, (estDays * 1.5).round()),
        expectedRemainingPointsP10: safeRemaining,
        expectedRemainingPointsP50: safeRemaining,
        expectedRemainingPointsP90: safeRemaining,
        bandP10: constBand,
        bandP50: constBand,
        bandP90: constBand,
        currentDayIndex: safeCurrentIdx,
        totalSprintDays: safeTotalDays,
        remainingStoryPoints: safeRemaining.round(),
        simulationsRun: safeSimulations,
        sourceType: sourceType,
        isLowConfidence: isLowConfidence,
        meanDailyThroughput: meanThroughput,
        whatIfSuggestions: suggestions,
      );
    }

    // Chạy mô phỏng Monte Carlo cho các ngày còn lại và tối đa 60 ngày mở rộng
    final maxHorizonDays = max(safeDaysLeft, 60);
    final futureSteps = safeTotalDays - safeCurrentIdx;
    final trajectoriesByStep = List<List<double>>.generate(
      futureSteps,
      (_) => List<double>.filled(safeSimulations, 0.0),
    );

    final daysToFinishList = List<int>.filled(safeSimulations, maxHorizonDays);
    final endRemainingList = List<double>.filled(safeSimulations, 0.0);
    int completedOnTimeCount = 0;

    for (int sim = 0; sim < safeSimulations; sim++) {
      double rem = safeRemaining;
      int? finishedDay;

      // Bước 0 là ngày hiện tại (currentDayIndex)
      trajectoriesByStep[0][sim] = rem;

      for (int d = 1; d <= maxHorizonDays; d++) {
        if (rem > 0.0) {
          final sampledBurn = _sampleDailyBurn(empiricalPool, rng);
          rem = max(0.0, rem - sampledBurn);
          if (rem <= 1e-9) {
            rem = 0.0;
            finishedDay ??= d;
          }
        }
        if (d < futureSteps) {
          trajectoriesByStep[d][sim] = rem;
        }
        if (d == safeDaysLeft) {
          endRemainingList[sim] = rem;
          if (rem <= 1e-9) {
            completedOnTimeCount++;
          }
        }
      }

      daysToFinishList[sim] = finishedDay ?? maxHorizonDays;
    }

    final completionProb = (completedOnTimeCount / safeSimulations).clamp(
      0.0,
      1.0,
    );

    daysToFinishList.sort();
    endRemainingList.sort();

    final daysP10 = _percentileInt(daysToFinishList, 0.10);
    final daysP50 = _percentileInt(daysToFinishList, 0.50);
    final daysP90 = _percentileInt(daysToFinishList, 0.90);

    final remP10 = _percentileDouble(endRemainingList, 0.10);
    final remP50 = _percentileDouble(endRemainingList, 0.50);
    final remP90 = _percentileDouble(endRemainingList, 0.90);

    final bandP10 = List<double?>.filled(safeTotalDays, null);
    final bandP50 = List<double?>.filled(safeTotalDays, null);
    final bandP90 = List<double?>.filled(safeTotalDays, null);

    for (int step = 0; step < futureSteps; step++) {
      final dayIdx = safeCurrentIdx + step;
      final values = trajectoriesByStep[step]..sort();
      bandP10[dayIdx] = _percentileDouble(values, 0.10);
      bandP50[dayIdx] = _percentileDouble(values, 0.50);
      bandP90[dayIdx] = _percentileDouble(values, 0.90);
    }

    final suggestions = _computeWhatIfSuggestions(
      baseProbability: completionProb,
      remainingPoints: safeRemaining,
      daysLeft: safeDaysLeft,
      empiricalPool: empiricalPool,
      incompleteStories: incompleteStories,
      numSimulations: min(500, safeSimulations),
      rng: rng,
    );

    return SprintForecastResult(
      completionProbability: completionProb,
      daysToCompleteP10: daysP10,
      daysToCompleteP50: daysP50,
      daysToCompleteP90: daysP90,
      expectedRemainingPointsP10: remP10,
      expectedRemainingPointsP50: remP50,
      expectedRemainingPointsP90: remP90,
      bandP10: bandP10,
      bandP50: bandP50,
      bandP90: bandP90,
      currentDayIndex: safeCurrentIdx,
      totalSprintDays: safeTotalDays,
      remainingStoryPoints: safeRemaining.round(),
      simulationsRun: safeSimulations,
      sourceType: sourceType,
      isLowConfidence: isLowConfidence,
      meanDailyThroughput: meanThroughput,
      whatIfSuggestions: suggestions,
    );
  }

  /// Tính toán nhanh Top-3 gợi ý What-if: nếu dời 1 Story chưa hoàn thành ra khỏi Sprint
  /// thì xác suất hoàn thành đúng hạn sẽ tăng lên bao nhiêu.
  List<StoryRemovalSuggestion> _computeWhatIfSuggestions({
    required double baseProbability,
    required double remainingPoints,
    required int daysLeft,
    required List<double> empiricalPool,
    required List<ForecastStoryCandidate> incompleteStories,
    required int numSimulations,
    required Random rng,
  }) {
    if (incompleteStories.isEmpty) return const [];

    final suggestions = <StoryRemovalSuggestion>[];
    final baseSeed = rng.nextInt(1 << 30);

    for (final story in incompleteStories) {
      final pts = max(1, story.storyPoints).toDouble();
      final reducedRemaining = max(0.0, remainingPoints - pts);
      final newProb = _quickCompletionProbability(
        remainingPoints: reducedRemaining,
        daysLeft: daysLeft,
        empiricalPool: empiricalPool,
        numSimulations: numSimulations,
        seed: baseSeed,
      );
      suggestions.add(
        StoryRemovalSuggestion(
          story: story,
          baseProbability: baseProbability,
          newProbability: max(baseProbability, newProb),
        ),
      );
    }

    suggestions.sort((a, b) {
      final cmp = b.newProbability.compareTo(a.newProbability);
      if (cmp != 0) return cmp;
      return b.story.storyPoints.compareTo(a.story.storyPoints);
    });

    return suggestions.take(3).toList(growable: false);
  }

  double _quickCompletionProbability({
    required double remainingPoints,
    required int daysLeft,
    required List<double> empiricalPool,
    required int numSimulations,
    required int seed,
  }) {
    if (remainingPoints <= 1e-9) return 1.0;
    if (daysLeft <= 0) return 0.0;

    final localRng = Random(seed);
    int success = 0;
    for (int s = 0; s < numSimulations; s++) {
      double burned = 0.0;
      for (int d = 0; d < daysLeft; d++) {
        burned += _sampleDailyBurn(empiricalPool, localRng);
      }
      if (burned >= remainingPoints - 1e-9) {
        success++;
      }
    }
    return (success / numSimulations).clamp(0.0, 1.0);
  }

  /// Lấy mẫu bootstrap có hoàn lại từ `pool` kèm nhiễu liên tục nhẹ (±15%)
  /// để phản ánh biến thiên tự nhiên hàng ngày của đội phát triển.
  static double _sampleDailyBurn(List<double> pool, Random rng) {
    if (pool.isEmpty) return 1.0;
    final base = pool[rng.nextInt(pool.length)];
    final jitter = 0.85 + rng.nextDouble() * 0.30;
    return max(0.0, base * jitter);
  }

  static int _percentileInt(List<int> sorted, double p) {
    if (sorted.isEmpty) return 0;
    final idx = ((sorted.length - 1) * p.clamp(0.0, 1.0)).round().clamp(
      0,
      sorted.length - 1,
    );
    return sorted[idx];
  }

  static double _percentileDouble(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0.0;
    final pos = (sorted.length - 1) * p.clamp(0.0, 1.0);
    final lower = pos.floor().clamp(0, sorted.length - 1);
    final upper = pos.ceil().clamp(0, sorted.length - 1);
    if (lower == upper) return sorted[lower];
    final weight = pos - lower;
    return sorted[lower] * (1.0 - weight) + sorted[upper] * weight;
  }
}
