import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/ai/risk_prediction_service.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/user_story_model.dart';
import '../../../data/repositories/backlog_repository.dart';
import '../../../data/repositories/sprint_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../domain/ai/core/ai_training_pipeline.dart';
import '../../../domain/ai/core/dataset.dart';
import 'model_lab_state.dart';

/// Cubit điều phối màn hình Phòng Thí Nghiệm Mô Hình AI (`ModelLabScreen` — US-071).
///
/// Hỗ trợ:
/// - Tải thông tin mô hình hiện hành từ `RiskPredictionService`.
/// - Đếm và trích xuất mẫu `real` từ các Task đã `Done` có `deadline` trong dự án (tuân thủ chống rò rỉ nhãn).
/// - Huấn luyện lại (Retrain) có cập nhật đường cong hàm mất mát (Loss Curve) theo từng epoch.
/// - Đặt lại về mô hình khởi tạo mặc định và xuất trọng số JSON.
class ModelLabCubit extends Cubit<ModelLabState> {
  final String projectId;
  final RiskPredictionService _predictionService;
  final TaskRepository? taskRepository;
  final BacklogRepository? backlogRepository;
  final SprintRepository? sprintRepository;

  int _requestToken = 0;

  ModelLabCubit({
    required this.projectId,
    RiskPredictionService? predictionService,
    this.taskRepository,
    this.backlogRepository,
    this.sprintRepository,
  }) : _predictionService = predictionService ?? RiskPredictionService(),
       super(const ModelLabState());

  Future<void> loadModelInfo({List<TaskModel>? preloadedTasks}) async {
    final token = ++_requestToken;
    if (isClosed) return;
    emit(state.copyWith(status: ModelLabStatus.loading, errorMessage: null));

    try {
      final artifact = await _predictionService.ensureModelLoaded(projectId);
      if (isClosed || token != _requestToken) return;

      final realSamples = await _collectRealSamples(
        preloadedTasks: preloadedTasks,
      );
      if (isClosed || token != _requestToken) return;

      emit(
        ModelLabState(
          status: ModelLabStatus.loaded,
          artifact: artifact,
          currentEpoch: artifact.history.epochsRun,
          totalEpochs: artifact.history.epochsRun,
          liveTrainLosses: artifact.history.trainLosses,
          liveValLosses: artifact.history.valLosses,
          detectedRealTaskCount: realSamples.length,
        ),
      );
    } catch (e) {
      if (isClosed || token != _requestToken) return;
      emit(
        state.copyWith(
          status: ModelLabStatus.error,
          errorMessage: 'Không thể tải thông tin mô hình AI: $e',
        ),
      );
    }
  }

  /// Huấn luyện lại mô hình kết hợp dữ liệu thực tế (`real`) của dự án với dữ liệu khởi tạo (`synthetic`).
  Future<void> retrainWithProjectData({
    List<TaskModel>? preloadedTasks,
    int seed = AiTrainingPipeline.defaultTrainSeed,
    int syntheticCount = 800,
    int epochs = 120,
  }) async {
    final token = ++_requestToken;
    if (isClosed) return;

    final prevMetrics = state.artifact?.testMetrics;
    emit(
      state.copyWith(
        status: ModelLabStatus.training,
        previousMetricsBeforeRetrain: prevMetrics,
        currentEpoch: 0,
        totalEpochs: epochs,
        liveTrainLosses: const [],
        liveValLosses: const [],
        errorMessage: null,
        infoBannerMessage: null,
      ),
    );

    try {
      final realSamples = await _collectRealSamples(
        preloadedTasks: preloadedTasks,
      );
      if (isClosed || token != _requestToken) return;

      final trainLosses = <double>[];
      final valLosses = <double>[];

      const pipeline = AiTrainingPipeline();
      final artifact = pipeline.trainModel(
        realSamples: realSamples,
        seed: seed,
        syntheticCount: syntheticCount,
        epochs: epochs,
        onEpochEnd: (epoch, trainLoss, valLoss) {
          trainLosses.add(trainLoss);
          valLosses.add(valLoss);
          if (!isClosed &&
              token == _requestToken &&
              (epoch % 15 == 0 || epoch == 1)) {
            emit(
              state.copyWith(
                status: ModelLabStatus.training,
                currentEpoch: epoch,
                totalEpochs: epochs,
                liveTrainLosses: List<double>.from(trainLosses),
                liveValLosses: List<double>.from(valLosses),
                detectedRealTaskCount: realSamples.length,
              ),
            );
          }
        },
      );

      // Đồng bộ lưu vào RiskPredictionService / AiModelStore
      await _predictionService.retrainModel(
        projectId: projectId,
        realSamples: realSamples,
        seed: seed,
        syntheticCount: syntheticCount,
      );

      if (isClosed || token != _requestToken) return;

      final msg = realSamples.length < 10
          ? 'Đã huấn luyện lại thành công (${realSamples.length} mẫu thực tế + $syntheticCount mẫu khởi tạo). Lưu ý: dữ liệu thật của dự án còn ít (< 10 mẫu).'
          : 'Đã huấn luyện lại thành công với ${realSamples.length} mẫu thực tế và $syntheticCount mẫu khởi tạo!';

      emit(
        ModelLabState(
          status: ModelLabStatus.loaded,
          artifact: artifact,
          previousMetricsBeforeRetrain: prevMetrics,
          currentEpoch: artifact.history.epochsRun,
          totalEpochs: epochs,
          liveTrainLosses: artifact.history.trainLosses,
          liveValLosses: artifact.history.valLosses,
          detectedRealTaskCount: realSamples.length,
          infoBannerMessage: msg,
        ),
      );
    } catch (e) {
      if (isClosed || token != _requestToken) return;
      emit(
        state.copyWith(
          status: ModelLabStatus.error,
          errorMessage: 'Lỗi khi huấn luyện lại mô hình: $e',
        ),
      );
    }
  }

  /// Đặt lại về mô hình khởi tạo mặc định (chỉ dùng dữ liệu bootstrap chuẩn).
  Future<void> resetToDefaultModel() async {
    final token = ++_requestToken;
    if (isClosed) return;
    emit(state.copyWith(status: ModelLabStatus.training, errorMessage: null));

    try {
      final artifact = await _predictionService.resetToDefaultModel(projectId);
      if (isClosed || token != _requestToken) return;

      emit(
        ModelLabState(
          status: ModelLabStatus.loaded,
          artifact: artifact,
          currentEpoch: artifact.history.epochsRun,
          totalEpochs: artifact.history.epochsRun,
          liveTrainLosses: artifact.history.trainLosses,
          liveValLosses: artifact.history.valLosses,
          detectedRealTaskCount: state.detectedRealTaskCount,
          infoBannerMessage: 'Đã đặt lại về mô hình khởi tạo mặc định.',
        ),
      );
    } catch (e) {
      if (isClosed || token != _requestToken) return;
      emit(
        state.copyWith(
          status: ModelLabStatus.error,
          errorMessage: 'Không thể đặt lại mô hình: $e',
        ),
      );
    }
  }

  /// Xuất chuỗi JSON trọng số + bộ chuẩn hoá của mô hình hiện tại để sao chép.
  String exportWeightsJson() {
    final artifact = state.artifact;
    if (artifact == null) return '{}';
    final payload = {
      'schemaVersion': artifact.schemaVersion,
      'trainedAtIso': artifact.trainedAtIso,
      'syntheticSampleCount': artifact.syntheticSampleCount,
      'realSampleCount': artifact.realSampleCount,
      'weights': artifact.model.weights,
      'bias': artifact.model.bias,
      'standardizerMeans': artifact.standardizer.means,
      'standardizerStds': artifact.standardizer.stds,
      'testMetrics': artifact.testMetrics.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<List<LabeledSample>> _collectRealSamples({
    List<TaskModel>? preloadedTasks,
  }) async {
    List<TaskModel> tasks = preloadedTasks ?? const [];
    if (tasks.isEmpty && taskRepository != null && projectId.isNotEmpty) {
      try {
        tasks = await taskRepository!
            .streamTasksByProject(projectId)
            .first
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    if (tasks.isEmpty) return const [];

    final storiesById = <String, UserStoryModel>{};
    if (backlogRepository != null && projectId.isNotEmpty) {
      try {
        final stories = await backlogRepository!.getUserStories(projectId);
        for (final s in stories) {
          storiesById[s.id] = s;
        }
      } catch (_) {}
    }

    final sprintsByStoryId = <String, SprintModel>{};
    if (sprintRepository != null && projectId.isNotEmpty) {
      try {
        final sprints = await sprintRepository!
            .streamSprints(projectId)
            .first
            .timeout(const Duration(seconds: 4));
        for (final sp in sprints) {
          for (final sid in sp.storyIds) {
            sprintsByStoryId[sid] = sp;
          }
        }
      } catch (_) {}
    }

    return _predictionService.extractor.extractRealSamplesFromProject(
      allProjectTasks: tasks,
      storiesById: storiesById,
      sprintsByStoryId: sprintsByStoryId,
    );
  }
}
