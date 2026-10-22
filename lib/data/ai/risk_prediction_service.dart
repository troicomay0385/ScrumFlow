import 'package:flutter/foundation.dart';

import '../../domain/ai/core/ai_training_pipeline.dart';
import '../../domain/ai/core/dataset.dart';
import '../../domain/ai/core/explainer.dart';
import '../../domain/ai/core/feature_spec.dart';
import '../models/performance_score_model.dart';
import '../models/project_member_display.dart';
import '../models/sprint_model.dart';
import '../models/task_model.dart';
import '../models/user_story_model.dart';
import '../services/performance_score_service.dart';
import 'ai_model_store.dart';
import 'task_risk_feature_extractor.dart';

/// Loại điều chỉnh giả lập What-if cho một Task.
enum WhatIfActionType { reassignMember, extendDeadline, reassignAndExtend }

/// Một phương án giả lập điều chỉnh (What-if) cho Task (US-069).
class TaskWhatIfSuggestion {
  final WhatIfActionType actionType;
  final String titleVi;
  final String subtitleVi;
  final String? targetAssigneeId;
  final String? targetAssigneeName;
  final int addedDays;
  final DateTime? newDeadline;
  final double originalProbability;
  final double newProbability;
  final RiskLevel newRiskLevel;

  const TaskWhatIfSuggestion({
    required this.actionType,
    required this.titleVi,
    required this.subtitleVi,
    this.targetAssigneeId,
    this.targetAssigneeName,
    this.addedDays = 0,
    this.newDeadline,
    required this.originalProbability,
    required this.newProbability,
    required this.newRiskLevel,
  });

  /// Độ giảm rủi ro theo điểm phần trăm (ví dụ `0.24` = giảm 24%).
  double get riskReduction => originalProbability - newProbability;

  int get originalPercent => (originalProbability * 100).round();
  int get newPercent => (newProbability * 100).round();
  int get reductionPercentPoints => (originalPercent - newPercent);
}

/// Kết quả dự báo rủi ro trễ hạn cho 1 Task cụ thể (US-069).
class TaskRiskPrediction {
  final TaskModel task;
  final UserStoryModel? story;
  final SprintModel? sprint;
  final TaskRiskSkipReason? skipReason;
  final double probability;
  final RiskLevel level;
  final List<FeatureContribution> topReasons;
  final List<FeatureContribution> allContributions;
  final List<TaskWhatIfSuggestion> suggestions;
  final List<MemberPerformanceScore> memberScores;

  const TaskRiskPrediction({
    required this.task,
    this.story,
    this.sprint,
    this.skipReason,
    required this.probability,
    required this.level,
    required this.topReasons,
    required this.allContributions,
    this.suggestions = const [],
    this.memberScores = const [],
  });

  factory TaskRiskPrediction.skipped({
    required TaskModel task,
    required TaskRiskSkipReason skipReason,
    UserStoryModel? story,
    SprintModel? sprint,
  }) {
    return TaskRiskPrediction(
      task: task,
      story: story,
      sprint: sprint,
      skipReason: skipReason,
      probability: 0.0,
      level: RiskLevel.low,
      topReasons: const [],
      allContributions: const [],
    );
  }

  bool get isPredictable => skipReason == null;

  int get probabilityPercent => (probability * 100).round();
}

/// Tham số tuần tự hoá để chạy huấn luyện trên Isolate (`compute`).
class _IsolateTrainRequest {
  final List<Map<String, dynamic>> realSampleMaps;
  final int seed;
  final int syntheticCount;

  const _IsolateTrainRequest({
    required this.realSampleMaps,
    required this.seed,
    required this.syntheticCount,
  });
}

Map<String, dynamic> _trainInIsolate(_IsolateTrainRequest request) {
  final realSamples = request.realSampleMaps
      .map(LabeledSample.fromJson)
      .toList(growable: false);
  const pipeline = AiTrainingPipeline();
  final artifact = pipeline.trainModel(
    realSamples: realSamples,
    seed: request.seed,
    syntheticCount: request.syntheticCount,
  );
  return artifact.toJson();
}

/// Dịch vụ dự báo rủi ro trễ hạn Task (US-069) & quản lý huấn luyện mô hình (US-071).
///
/// Toàn bộ suy luận và huấn luyện diễn ra hoàn toàn cục bộ trên thiết bị,
/// không gọi bất kỳ API bên ngoài nào.
class RiskPredictionService {
  final AiModelStore _modelStore;
  final TaskRiskFeatureExtractor _extractor;
  final PerformanceScoreService _performanceScoreService;
  final bool useIsolateForTraining;

  final Map<String, TrainedRiskModelArtifact> _memoryCache = {};
  final Map<String, Future<TrainedRiskModelArtifact>> _inFlightLoads = {};

  RiskPredictionService({
    AiModelStore? modelStore,
    TaskRiskFeatureExtractor? extractor,
    PerformanceScoreService? performanceScoreService,
    this.useIsolateForTraining = false,
  }) : _modelStore = modelStore ?? AiModelStore(),
       _extractor = extractor ?? const TaskRiskFeatureExtractor(),
       _performanceScoreService =
           performanceScoreService ?? const PerformanceScoreService();

  TaskRiskFeatureExtractor get extractor => _extractor;

  /// Đảm bảo dự án đã có mô hình huấn luyện sẵn (từ RAM -> SharedPreferences -> huấn luyện Bootstrap).
  Future<TrainedRiskModelArtifact> ensureModelLoaded(String projectId) async {
    final cleanId = projectId.trim().isEmpty ? 'default' : projectId.trim();
    final cached = _memoryCache[cleanId];
    if (cached != null) return cached;

    final inFlight = _inFlightLoads[cleanId];
    if (inFlight != null) return inFlight;

    final future = _loadOrTrainBootstrap(cleanId);
    _inFlightLoads[cleanId] = future;
    try {
      final artifact = await future;
      _memoryCache[cleanId] = artifact;
      return artifact;
    } finally {
      _inFlightLoads.remove(cleanId);
    }
  }

  Future<TrainedRiskModelArtifact> _loadOrTrainBootstrap(
    String projectId,
  ) async {
    final stored = await _modelStore.loadModel(projectId);
    if (stored != null) {
      return stored;
    }

    final trained = await _runTraining(
      realSamples: const [],
      seed: AiTrainingPipeline.defaultTrainSeed,
      syntheticCount: 800,
    );
    await _modelStore.saveModel(projectId, trained);
    return trained;
  }

  /// Huấn luyện lại mô hình với dữ liệu thật (`realSamples`) kết hợp tập khởi tạo (`synthetic`).
  Future<TrainedRiskModelArtifact> retrainModel({
    required String projectId,
    List<LabeledSample> realSamples = const [],
    int seed = AiTrainingPipeline.defaultTrainSeed,
    int syntheticCount = 800,
  }) async {
    final cleanId = projectId.trim().isEmpty ? 'default' : projectId.trim();
    final trained = await _runTraining(
      realSamples: realSamples,
      seed: seed,
      syntheticCount: syntheticCount,
    );
    _memoryCache[cleanId] = trained;
    await _modelStore.saveModel(cleanId, trained);
    return trained;
  }

  /// Đặt lại về mô hình khởi tạo mặc định (xóa mẫu real và huấn luyện lại trên seed chuẩn).
  Future<TrainedRiskModelArtifact> resetToDefaultModel(String projectId) async {
    final cleanId = projectId.trim().isEmpty ? 'default' : projectId.trim();
    await _modelStore.clearModel(cleanId);
    _memoryCache.remove(cleanId);
    return retrainModel(
      projectId: cleanId,
      realSamples: const [],
      seed: AiTrainingPipeline.defaultTrainSeed,
      syntheticCount: 800,
    );
  }

  Future<TrainedRiskModelArtifact> _runTraining({
    required List<LabeledSample> realSamples,
    required int seed,
    required int syntheticCount,
  }) async {
    if (useIsolateForTraining) {
      final request = _IsolateTrainRequest(
        realSampleMaps: realSamples.map((s) => s.toJson()).toList(),
        seed: seed,
        syntheticCount: syntheticCount,
      );
      final jsonMap = await compute(_trainInIsolate, request);
      return TrainedRiskModelArtifact.fromJson(jsonMap);
    }

    const pipeline = AiTrainingPipeline();
    return pipeline.trainModel(
      realSamples: realSamples,
      seed: seed,
      syntheticCount: syntheticCount,
    );
  }

  /// Dự báo rủi ro trễ hạn cho 1 Task đơn lẻ kèm giải thích Top-3 và gợi ý What-if.
  Future<TaskRiskPrediction> predictTaskRisk({
    required String projectId,
    required TaskModel task,
    UserStoryModel? story,
    SprintModel? sprint,
    List<ProjectMemberDisplay> members = const [],
    List<TaskModel> allProjectTasks = const [],
    DateTime? now,
  }) async {
    final artifact = await ensureModelLoaded(projectId);
    return predictTaskRiskSync(
      artifact: artifact,
      task: task,
      story: story,
      sprint: sprint,
      members: members,
      allProjectTasks: allProjectTasks,
      now: now,
    );
  }

  /// Dự báo đồng bộ (dùng khi đã có `TrainedRiskModelArtifact` trong bộ nhớ, < 1 ms/task).
  TaskRiskPrediction predictTaskRiskSync({
    required TrainedRiskModelArtifact artifact,
    required TaskModel task,
    UserStoryModel? story,
    SprintModel? sprint,
    List<ProjectMemberDisplay> members = const [],
    List<TaskModel> allProjectTasks = const [],
    DateTime? now,
  }) {
    final skipReason = _extractor.checkSkipReason(task);
    if (skipReason != null) {
      return TaskRiskPrediction.skipped(
        task: task,
        skipReason: skipReason,
        story: story,
        sprint: sprint,
      );
    }

    final memberScores = _performanceScoreService.calculateScores(
      members: members,
      allProjectTasks: allProjectTasks,
      now: now,
    );
    final scoresByUserId = <String, MemberPerformanceScore>{
      for (final s in memberScores) s.userId: s,
    };

    final rawFeatures = _extractor.extractForLiveTask(
      task: task,
      story: story,
      sprint: sprint,
      memberScoresByUserId: scoresByUserId,
      allProjectTasks: allProjectTasks,
      now: now,
    );

    final explanation = Explainer.explain(
      rawFeatures: rawFeatures,
      standardizer: artifact.standardizer,
      model: artifact.model,
      topK: 3,
    );

    final suggestions = _buildWhatIfSuggestions(
      artifact: artifact,
      task: task,
      story: story,
      sprint: sprint,
      memberScores: memberScores,
      scoresByUserId: scoresByUserId,
      allProjectTasks: allProjectTasks,
      originalProbability: explanation.probability,
      now: now,
    );

    return TaskRiskPrediction(
      task: task,
      story: story,
      sprint: sprint,
      probability: explanation.probability,
      level: explanation.riskLevel,
      topReasons: explanation.topContributions,
      allContributions: explanation.allContributions,
      suggestions: suggestions,
      memberScores: memberScores,
    );
  }

  /// Tính toán tức thì kịch bản giả lập What-if khi người dùng chọn người phụ trách mới
  /// hoặc kéo thanh trượt cộng thêm ngày hạn chót (`addedDays`).
  TaskWhatIfSuggestion simulateWhatIfSync({
    required TrainedRiskModelArtifact artifact,
    required TaskModel task,
    required double originalProbability,
    UserStoryModel? story,
    SprintModel? sprint,
    Map<String, MemberPerformanceScore>? scoresByUserId,
    List<TaskModel>? allProjectTasks,
    String? targetAssigneeId,
    String? targetAssigneeName,
    int addedDays = 0,
    DateTime? now,
  }) {
    final baseDeadline = task.deadline ?? (now ?? DateTime.now());
    final newDeadline = addedDays != 0
        ? baseDeadline.add(Duration(days: addedDays))
        : task.deadline;

    final effectiveFeatures = _extractor.extractForLiveTask(
      task: task,
      story: story,
      sprint: sprint,
      memberScoresByUserId: scoresByUserId,
      allProjectTasks: allProjectTasks,
      now: now,
      overrideAssigneeId: targetAssigneeId,
      overrideDeadline: newDeadline,
    );

    final z = artifact.standardizer.transform(effectiveFeatures);
    final newProb = artifact.model.predictProba(z);
    final newLevel = RiskThresholds.classify(newProb);

    final bool changedAssignee =
        targetAssigneeId != null && targetAssigneeId != task.assigneeId;
    final bool changedDeadline = addedDays > 0;

    final WhatIfActionType actionType;
    final String titleVi;
    if (changedAssignee && changedDeadline) {
      actionType = WhatIfActionType.reassignAndExtend;
      titleVi =
          'Giao cho ${targetAssigneeName ?? "thành viên khác"} & dời hạn +$addedDays ngày';
    } else if (changedAssignee) {
      actionType = WhatIfActionType.reassignMember;
      titleVi = 'Giao cho ${targetAssigneeName ?? "thành viên khác"}';
    } else {
      actionType = WhatIfActionType.extendDeadline;
      titleVi = 'Gia hạn deadline thêm +$addedDays ngày';
    }

    final int origPct = (originalProbability * 100).round();
    final int newPct = (newProb * 100).round();
    final int diff = origPct - newPct;
    final String subtitleVi = diff > 0
        ? 'Rủi ro giảm từ $origPct% xuống $newPct% (-$diff%)'
        : (diff < 0
              ? 'Rủi ro tăng từ $origPct% lên $newPct% (+${-diff}%)'
              : 'Mức rủi ro giữ nguyên ở $newPct%');

    return TaskWhatIfSuggestion(
      actionType: actionType,
      titleVi: titleVi,
      subtitleVi: subtitleVi,
      targetAssigneeId: targetAssigneeId ?? task.assigneeId,
      targetAssigneeName: targetAssigneeName ?? task.assigneeName,
      addedDays: addedDays,
      newDeadline: newDeadline,
      originalProbability: originalProbability,
      newProbability: newProb,
      newRiskLevel: newLevel,
    );
  }

  /// Dự báo hàng loạt cho toàn bộ danh sách Task trong Sprint hoặc Story,
  /// trả về cả danh sách đã sắp xếp theo xác suất rủi ro giảm dần.
  Future<List<TaskRiskPrediction>> predictBatchTasks({
    required String projectId,
    required List<TaskModel> tasks,
    Map<String, UserStoryModel> storiesById = const {},
    Map<String, SprintModel> sprintsByStoryId = const {},
    List<ProjectMemberDisplay> members = const [],
    List<TaskModel>? allProjectTasks,
    DateTime? now,
  }) async {
    final artifact = await ensureModelLoaded(projectId);
    final effectiveAllTasks = allProjectTasks ?? tasks;

    final memberScores = _performanceScoreService.calculateScores(
      members: members,
      allProjectTasks: effectiveAllTasks,
      now: now,
    );
    final scoresByUserId = <String, MemberPerformanceScore>{
      for (final s in memberScores) s.userId: s,
    };

    final results = <TaskRiskPrediction>[];
    for (final task in tasks) {
      final story = storiesById[task.storyId];
      final sprint = sprintsByStoryId[task.storyId];
      final skipReason = _extractor.checkSkipReason(task);
      if (skipReason != null) {
        results.add(
          TaskRiskPrediction.skipped(
            task: task,
            skipReason: skipReason,
            story: story,
            sprint: sprint,
          ),
        );
        continue;
      }

      final rawFeatures = _extractor.extractForLiveTask(
        task: task,
        story: story,
        sprint: sprint,
        memberScoresByUserId: scoresByUserId,
        allProjectTasks: effectiveAllTasks,
        now: now,
      );

      final explanation = Explainer.explain(
        rawFeatures: rawFeatures,
        standardizer: artifact.standardizer,
        model: artifact.model,
        topK: 3,
      );

      final suggestions = _buildWhatIfSuggestions(
        artifact: artifact,
        task: task,
        story: story,
        sprint: sprint,
        memberScores: memberScores,
        scoresByUserId: scoresByUserId,
        allProjectTasks: effectiveAllTasks,
        originalProbability: explanation.probability,
        now: now,
      );

      results.add(
        TaskRiskPrediction(
          task: task,
          story: story,
          sprint: sprint,
          probability: explanation.probability,
          level: explanation.riskLevel,
          topReasons: explanation.topContributions,
          allContributions: explanation.allContributions,
          suggestions: suggestions,
          memberScores: memberScores,
        ),
      );
    }

    return results;
  }

  List<TaskWhatIfSuggestion> _buildWhatIfSuggestions({
    required TrainedRiskModelArtifact artifact,
    required TaskModel task,
    required UserStoryModel? story,
    required SprintModel? sprint,
    required List<MemberPerformanceScore> memberScores,
    required Map<String, MemberPerformanceScore> scoresByUserId,
    required List<TaskModel> allProjectTasks,
    required double originalProbability,
    required DateTime? now,
  }) {
    final candidates = <TaskWhatIfSuggestion>[];

    // 1. Giả lập đổi sang từng thành viên khác trong dự án
    for (final score in memberScores) {
      if (score.userId == task.assigneeId) continue;
      final sim = simulateWhatIfSync(
        artifact: artifact,
        task: task,
        originalProbability: originalProbability,
        story: story,
        sprint: sprint,
        scoresByUserId: scoresByUserId,
        allProjectTasks: allProjectTasks,
        targetAssigneeId: score.userId,
        targetAssigneeName: score.userName,
        addedDays: 0,
        now: now,
      );
      if (sim.riskReduction >= 0.03) {
        candidates.add(sim);
      }
    }

    // 2. Giả lập gia hạn deadline thêm +1, +2, +3, +5 ngày
    for (final days in const [1, 2, 3, 5]) {
      final sim = simulateWhatIfSync(
        artifact: artifact,
        task: task,
        originalProbability: originalProbability,
        story: story,
        sprint: sprint,
        scoresByUserId: scoresByUserId,
        allProjectTasks: allProjectTasks,
        addedDays: days,
        now: now,
      );
      if (sim.riskReduction >= 0.03) {
        candidates.add(sim);
      }
    }

    candidates.sort((a, b) => b.riskReduction.compareTo(a.riskReduction));
    return candidates.take(5).toList(growable: false);
  }
}
