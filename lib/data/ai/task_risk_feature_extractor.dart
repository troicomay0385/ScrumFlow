import 'dart:math';

import '../../domain/ai/core/dataset.dart';
import '../../domain/ai/core/feature_spec.dart';
import '../models/performance_score_model.dart';
import '../models/sprint_model.dart';
import '../models/task_model.dart';
import '../models/user_story_model.dart';

/// Lý do một Task không đủ điều kiện dự báo rủi ro trễ hạn.
enum TaskRiskSkipReason {
  /// Task đã hoàn thành (`Done`).
  alreadyDone,

  /// Task chưa được đặt hạn hoàn thành (`deadline == null`).
  missingDeadline,
}

/// Bộ trích xuất đặc trưng (Feature Extractor) chuyển đổi mô hình dữ liệu
/// của ứng dụng (`TaskModel`, `UserStoryModel`, `SprintModel`, `MemberPerformanceScore`)
/// sang vector 10 chiều chuẩn của `TaskFeatureSpec`.
///
/// Tách biệt rõ 2 chế độ:
/// 1. [extractForLiveTask]: Dùng khi suy luận (inference) cho task đang mở.
/// 2. [extractLabeledSampleFromDoneTask]: Dùng khi trích xuất mẫu `real` từ
///    task đã `Done` để huấn luyện lại (US-071), tuân thủ nghiêm ngặt quy tắc
///    **chống rò rỉ nhãn** (không bao giờ sử dụng `task.updatedAt` trong vector đặc trưng).
class TaskRiskFeatureExtractor {
  const TaskRiskFeatureExtractor();

  /// Kiểm tra xem task có cần/đủ điều kiện dự báo rủi ro trực tiếp hay không.
  /// Trả về `null` nếu hợp lệ để dự báo, hoặc trả về [TaskRiskSkipReason].
  TaskRiskSkipReason? checkSkipReason(TaskModel task) {
    if (task.status.trim().toLowerCase() == 'done') {
      return TaskRiskSkipReason.alreadyDone;
    }
    if (task.deadline == null) {
      return TaskRiskSkipReason.missingDeadline;
    }
    return null;
  }

  /// Trích xuất vector 10 đặc trưng cho một Task đang mở (hoặc giả lập What-if).
  List<double> extractForLiveTask({
    required TaskModel task,
    UserStoryModel? story,
    SprintModel? sprint,
    Map<String, MemberPerformanceScore>? memberScoresByUserId,
    List<TaskModel>? allProjectTasks,
    DateTime? now,
    String? overrideAssigneeId,
    bool clearAssignee = false,
    DateTime? overrideDeadline,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final effectiveDeadline = overrideDeadline ?? task.deadline;
    final effectiveAssigneeId = clearAssignee
        ? null
        : (overrideAssigneeId ?? task.assigneeId);

    final double storyPoints =
        (story?.storyPoints.toDouble() ??
                TaskFeatureSpec
                    .definitions[TaskFeatureSpec.idxStoryPoints]
                    .defaultCheckpointValue)
            .clamp(1.0, 21.0);

    final double priorityRank = _mapPriorityRank(story?.priority);

    double daysToDeadline = TaskFeatureSpec
        .definitions[TaskFeatureSpec.idxDaysToDeadline]
        .defaultCheckpointValue;
    double elapsedRatio = TaskFeatureSpec
        .definitions[TaskFeatureSpec.idxElapsedRatio]
        .defaultCheckpointValue;

    if (effectiveDeadline != null) {
      final remainingHours =
          effectiveDeadline.difference(effectiveNow).inMinutes / 60.0;
      daysToDeadline = (remainingHours / 24.0).clamp(-7.0, 14.0);

      final totalPlannedHours = max(
        24.0,
        effectiveDeadline.difference(task.createdAt).inMinutes / 60.0,
      );
      final elapsedHours = max(
        0.0,
        effectiveNow.difference(task.createdAt).inMinutes / 60.0,
      );
      elapsedRatio = (elapsedHours / totalPlannedHours).clamp(0.0, 1.5);
    }

    final ageDays = max(
      1.0,
      effectiveNow.difference(task.createdAt).inMinutes / (24.0 * 60.0),
    );
    final loggedHours = task.loggedHours.isNaN || task.loggedHours.isInfinite
        ? 0.0
        : max(0.0, task.loggedHours);
    final double loggedHoursPerDay = (loggedHours / ageDays).clamp(0.0, 12.0);

    final double statusProgress = _mapLiveStatusProgress(task.status);

    final bool isUnassigned =
        effectiveAssigneeId == null || effectiveAssigneeId.trim().isEmpty;
    final double unassigned = isUnassigned ? 1.0 : 0.0;

    double assigneeOnTimeRate = TaskFeatureSpec
        .definitions[TaskFeatureSpec.idxAssigneeOnTimeRate]
        .defaultCheckpointValue;
    double assigneeWorkload = 0.0;

    if (!isUnassigned) {
      final cleanId = effectiveAssigneeId.trim();
      final precomputed = memberScoresByUserId?[cleanId];
      if (precomputed != null) {
        assigneeOnTimeRate = precomputed.onTimeRate.clamp(0.0, 1.0);
        // Nếu đang giả lập giao task này cho một thành viên mới chưa đứng tên task,
        // cộng thêm 1 task vào tải đang làm của người đó nếu task đang mở.
        final bool isSwitchingToNewMember = task.assigneeId?.trim() != cleanId;
        final extraInProgress = isSwitchingToNewMember ? 1 : 0;
        assigneeWorkload =
            ((precomputed.inProgressTasks + extraInProgress) / 5.0).clamp(
              0.0,
              1.5,
            );
      } else if (allProjectTasks != null) {
        final stats = _computeAssigneeStats(
          assigneeId: cleanId,
          tasks: allProjectTasks,
          excludeTaskId: null,
        );
        assigneeOnTimeRate = stats.onTimeRate;
        final bool isSwitchingToNewMember = task.assigneeId?.trim() != cleanId;
        final extraInProgress = isSwitchingToNewMember ? 1 : 0;
        assigneeWorkload = ((stats.inProgressCount + extraInProgress) / 5.0)
            .clamp(0.0, 1.5);
      } else {
        assigneeOnTimeRate = 0.75;
        assigneeWorkload = 0.2;
      }
    }

    final double sprintElapsedRatio = _computeSprintElapsedRatio(
      sprint: sprint,
      now: effectiveNow,
    );

    return <double>[
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
  }

  /// Trích xuất mẫu huấn luyện `real` từ một Task đã `Done` và có `deadline`.
  ///
  /// **Quy tắc chống rò rỉ nhãn (Anti-Label Leakage — mục 4.9 MASTER_PROMPT):**
  /// - Nhãn `label = task.updatedAt.isAfter(task.deadline!) ? 1 : 0`.
  /// - Vector đặc trưng `features` **TUYỆT ĐỐI KHÔNG** sử dụng `task.updatedAt`:
  ///   + `daysToDeadline`: tính tại mốc giữa kỳ kế hoạch `0.5 * (deadline - createdAt)`.
  ///   + `elapsedRatio`: hằng số checkpoint `0.5`.
  ///   + `loggedHoursPerDay`: hằng số checkpoint `1.5`.
  ///   + `statusProgress`: hằng số checkpoint `0.5`.
  ///   + `assigneeOnTimeRate` & `assigneeWorkload`: tính leave-one-out
  ///     (loại bỏ chính `task.id` khỏi danh sách `allProjectTasks`).
  LabeledSample? extractLabeledSampleFromDoneTask({
    required TaskModel task,
    UserStoryModel? story,
    SprintModel? sprint,
    List<TaskModel> allProjectTasks = const [],
  }) {
    if (task.status.trim().toLowerCase() != 'done' || task.deadline == null) {
      return null;
    }

    final deadline = task.deadline!;
    final int label = task.updatedAt.isAfter(deadline) ? 1 : 0;

    final double storyPoints =
        (story?.storyPoints.toDouble() ??
                TaskFeatureSpec
                    .definitions[TaskFeatureSpec.idxStoryPoints]
                    .defaultCheckpointValue)
            .clamp(1.0, 21.0);

    final double priorityRank = _mapPriorityRank(story?.priority);

    // Thời gian còn lại tại mốc checkpoint giữa kỳ (không phụ thuộc updatedAt!)
    final plannedHours = deadline.difference(task.createdAt).inMinutes / 60.0;
    final double daysToDeadline = (0.5 * (plannedHours / 24.0)).clamp(
      -7.0,
      14.0,
    );

    const double elapsedRatio = TaskFeatureSpec.realCheckpointElapsedRatio;
    const double loggedHoursPerDay =
        TaskFeatureSpec.realCheckpointLoggedHoursPerDay;
    const double statusProgress = TaskFeatureSpec.realCheckpointStatusProgress;

    final bool isUnassigned =
        task.assigneeId == null || task.assigneeId!.trim().isEmpty;
    final double unassigned = isUnassigned ? 1.0 : 0.0;

    double assigneeOnTimeRate = TaskFeatureSpec
        .definitions[TaskFeatureSpec.idxAssigneeOnTimeRate]
        .defaultCheckpointValue;
    double assigneeWorkload = TaskFeatureSpec
        .definitions[TaskFeatureSpec.idxAssigneeWorkload]
        .defaultCheckpointValue;

    if (!isUnassigned && allProjectTasks.isNotEmpty) {
      final stats = _computeAssigneeStats(
        assigneeId: task.assigneeId!.trim(),
        tasks: allProjectTasks,
        excludeTaskId: task.id, // Leave-one-out chống rò rỉ nhãn!
      );
      assigneeOnTimeRate = stats.onTimeRate;
      assigneeWorkload = (stats.inProgressCount / 5.0).clamp(0.0, 1.5);
    }

    // Tiến độ thời gian Sprint tại mốc tạo task (không dùng updatedAt)
    final double sprintElapsedRatio = sprint != null
        ? _computeSprintElapsedRatio(sprint: sprint, now: task.createdAt)
        : 0.5;

    return LabeledSample(
      features: <double>[
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
      ],
      label: label,
      source: SampleSource.real,
      id: task.id,
    );
  }

  /// Trích xuất toàn bộ mẫu `real` hợp lệ từ danh sách task của dự án.
  List<LabeledSample> extractRealSamplesFromProject({
    required List<TaskModel> allProjectTasks,
    Map<String, UserStoryModel> storiesById = const {},
    Map<String, SprintModel> sprintsByStoryId = const {},
  }) {
    final samples = <LabeledSample>[];
    for (final task in allProjectTasks) {
      final sample = extractLabeledSampleFromDoneTask(
        task: task,
        story: storiesById[task.storyId],
        sprint: sprintsByStoryId[task.storyId],
        allProjectTasks: allProjectTasks,
      );
      if (sample != null) {
        samples.add(sample);
      }
    }
    return samples;
  }

  double _mapPriorityRank(String? priority) {
    if (priority == null) return 1.0;
    final normalized = priority.trim().toUpperCase();
    if (normalized == 'CAO' || normalized == 'HIGH') return 2.0;
    if (normalized == 'THẤP' || normalized == 'THAP' || normalized == 'LOW') {
      return 0.0;
    }
    return 1.0;
  }

  double _mapLiveStatusProgress(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'in progress') return 0.5;
    if (normalized == 'done') return 1.0;
    return 0.0;
  }

  double _computeSprintElapsedRatio({
    required SprintModel? sprint,
    required DateTime now,
  }) {
    if (sprint == null) return 0.5;
    final totalHours = max(
      24.0,
      sprint.endDate.difference(sprint.startDate).inMinutes / 60.0,
    );
    final elapsedHours = now.difference(sprint.startDate).inMinutes / 60.0;
    return (elapsedHours / totalHours).clamp(0.0, 1.2);
  }

  _AssigneeStats _computeAssigneeStats({
    required String assigneeId,
    required List<TaskModel> tasks,
    required String? excludeTaskId,
  }) {
    int onTime = 0;
    int overdue = 0;
    int inProgress = 0;

    for (final t in tasks) {
      if (excludeTaskId != null && t.id == excludeTaskId) continue;
      if (t.assigneeId?.trim() != assigneeId) continue;

      final statusNorm = t.status.trim().toLowerCase();
      if (statusNorm == 'done') {
        if (t.deadline == null || !t.updatedAt.isAfter(t.deadline!)) {
          onTime++;
        } else {
          overdue++;
        }
      } else if (statusNorm == 'in progress') {
        inProgress++;
      }
    }

    final totalDone = onTime + overdue;
    final double onTimeRate = totalDone > 0
        ? (onTime / totalDone).clamp(0.0, 1.0)
        : 1.0;
    return _AssigneeStats(onTimeRate: onTimeRate, inProgressCount: inProgress);
  }
}

class _AssigneeStats {
  final double onTimeRate;
  final int inProgressCount;

  const _AssigneeStats({
    required this.onTimeRate,
    required this.inProgressCount,
  });
}
