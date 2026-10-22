import 'dart:math';

import '../../domain/ai/core/sprint_forecast_engine.dart';
import '../models/sprint_model.dart';
import '../models/user_story_model.dart';

/// Dịch vụ nối dữ liệu `SprintModel` + `UserStoryModel` của ScrumFlow với
/// động cơ mô phỏng Monte Carlo thuần Dart [`SprintForecastEngine`] (US-070).
///
/// ### Thứ tự ưu tiên nguồn thông lượng (Throughput Source Priority):
/// 1. **Các Sprint đã đóng (`Completed` / `Closed`):**
///    $$\text{velocity\_per\_day}_s = \frac{\sum_{i \in \text{Done}(s)} \text{SP}_i}{\max(1, \text{endDate}_s - \text{startDate}_s)}$$
/// 2. **Tốc độ hoàn thành theo ngày của Sprint đang chạy (`Active`):**
///    Tính chuỗi điểm hoàn thành mỗi ngày từ `story.completedAt ?? story.updatedAt`
///    của các Story có `status == 'Done'` trong Sprint hiện tại.
/// 3. **Phân phối Prior mặc định:**
///    Khi dự án hoàn toàn chưa có dữ liệu lịch sử, dùng `SprintForecastEngine.defaultPriorSamples`
///    và gắn cờ `isLowConfidence = true` để hiển thị cảnh báo trên UI.
class SprintForecastService {
  final SprintForecastEngine engine;

  const SprintForecastService({this.engine = const SprintForecastEngine()});

  /// Dự báo tiến độ hoàn thành cho [sprint] dựa trên danh sách [sprintStories]
  /// của Sprint hiện tại, toàn bộ [allSprints] và [allProjectStories] của dự án.
  SprintForecastResult forecastSprint({
    required SprintModel sprint,
    required List<UserStoryModel> sprintStories,
    List<SprintModel> allSprints = const [],
    List<UserStoryModel> allProjectStories = const [],
    Set<String> excludedStoryIds = const {},
    int numSimulations = 1000,
    DateTime? now,
    int seed = 42,
  }) {
    final referenceNow = now ?? DateTime.now();
    final start = DateTime(
      sprint.startDate.year,
      sprint.startDate.month,
      sprint.startDate.day,
    );
    final end = DateTime(
      sprint.endDate.year,
      sprint.endDate.month,
      sprint.endDate.day,
    );
    final today = DateTime(
      referenceNow.year,
      referenceNow.month,
      referenceNow.day,
    );

    final daysDiff = end.difference(start).inDays;
    final totalDays = max(1, daysDiff + 1);
    final currentDayIndex = today
        .difference(start)
        .inDays
        .clamp(0, totalDays - 1);
    final daysLeft = max(0, end.difference(today).inDays);

    // Áp dụng bộ lọc What-if loại trừ các Story được chọn thử nghiệm
    final effectiveStories = sprintStories
        .where((s) => !excludedStoryIds.contains(s.id))
        .toList();

    final incompleteModels = effectiveStories
        .where((s) => s.status.trim().toLowerCase() != 'done')
        .toList();

    final remainingPoints = incompleteModels.fold<int>(
      0,
      (sum, s) => sum + (s.storyPoints > 0 ? s.storyPoints : 1),
    );

    final incompleteCandidates = incompleteModels
        .map(
          (s) => ForecastStoryCandidate(
            storyId: s.id,
            storyKey: s.storyKey,
            title: s.title,
            storyPoints: s.storyPoints > 0 ? s.storyPoints : 1,
            priority: s.priority,
          ),
        )
        .toList();

    // 1. Trích xuất thông lượng/ngày từ các Sprint đã đóng (Completed / Closed)
    final historicalDaily = extractClosedSprintsDailyThroughput(
      currentSprintId: sprint.id,
      allSprints: allSprints,
      allProjectStories: allProjectStories.isNotEmpty
          ? allProjectStories
          : sprintStories,
    );

    // 2. Trích xuất chuỗi điểm hoàn thành theo ngày của Sprint hiện tại
    final activeDailyBurn = extractActiveSprintDailyBurn(
      sprint: sprint,
      sprintStories: sprintStories,
      currentDayIndex: currentDayIndex,
    );

    return engine.simulate(
      remainingPoints: remainingPoints.toDouble(),
      daysLeft: daysLeft,
      totalSprintDays: totalDays,
      currentDayIndex: currentDayIndex,
      historicalDailyThroughputs: historicalDaily,
      activeSprintDailyBurn: activeDailyBurn,
      incompleteStories: incompleteCandidates,
      numSimulations: numSimulations,
      rng: Random(seed),
    );
  }

  /// Trích xuất mẫu thông lượng theo ngày từ các Sprint đã đóng (`Completed` hoặc `Closed`).
  List<double> extractClosedSprintsDailyThroughput({
    required String currentSprintId,
    required List<SprintModel> allSprints,
    required List<UserStoryModel> allProjectStories,
  }) {
    final closedSprints = allSprints.where((s) {
      if (s.id == currentSprintId) return false;
      final st = s.status.trim().toLowerCase();
      return st == 'completed' || st == 'closed';
    }).toList();

    if (closedSprints.isEmpty) return const [];

    final storyMap = <String, UserStoryModel>{
      for (final s in allProjectStories) s.id: s,
    };

    final samples = <double>[];
    for (final closed in closedSprints) {
      final durationDays = max(
        1,
        closed.endDate.difference(closed.startDate).inDays,
      );
      int completedPoints = 0;
      for (final id in closed.storyIds) {
        final st = storyMap[id];
        if (st != null) {
          final isDone = st.status.trim().toLowerCase() == 'done';
          if (isDone) {
            completedPoints += (st.storyPoints > 0 ? st.storyPoints : 1);
          }
        }
      }
      // Nếu Sprint đã đóng có điểm hoàn thành > 0, tạo phân phối mẫu ngày quanh velocity/ngày
      if (completedPoints > 0) {
        final velocityPerDay = completedPoints / durationDays;
        // Tạo 5 điểm mẫu đại diện cho biến thiên ngày trong Sprint đã đóng (giữ đúng kỳ vọng = velocityPerDay)
        samples.addAll([
          max(0.0, velocityPerDay * 0.4),
          velocityPerDay * 0.8,
          velocityPerDay,
          velocityPerDay * 1.2,
          velocityPerDay * 1.6,
        ]);
      }
    }

    return samples;
  }

  /// Trích xuất chuỗi điểm hoàn thành theo từng ngày đã qua của Sprint hiện tại.
  List<double> extractActiveSprintDailyBurn({
    required SprintModel sprint,
    required List<UserStoryModel> sprintStories,
    required int currentDayIndex,
  }) {
    final doneStories = sprintStories
        .where((s) => s.status.trim().toLowerCase() == 'done')
        .toList();
    if (doneStories.isEmpty) return const [];

    final startDay = DateTime(
      sprint.startDate.year,
      sprint.startDate.month,
      sprint.startDate.day,
    );
    final elapsedDays = max(1, currentDayIndex + 1);
    final dailyBurns = List<double>.filled(elapsedDays, 0.0);

    for (final story in doneStories) {
      final finishedTime = story.completedAt ?? story.updatedAt;
      final finishedDay = DateTime(
        finishedTime.year,
        finishedTime.month,
        finishedTime.day,
      );
      final dayIdx = finishedDay
          .difference(startDay)
          .inDays
          .clamp(0, elapsedDays - 1);
      final pts = (story.storyPoints > 0 ? story.storyPoints : 1).toDouble();
      dailyBurns[dayIdx] += pts;
    }

    return dailyBurns;
  }
}
