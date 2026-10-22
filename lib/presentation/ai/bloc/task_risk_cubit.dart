import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/ai/risk_prediction_service.dart';
import '../../../data/models/performance_score_model.dart';
import '../../../data/models/project_member_display.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/user_story_model.dart';
import '../../../data/repositories/backlog_repository.dart';
import '../../../data/repositories/task_repository.dart';
import 'task_risk_state.dart';

/// Cubit phụ trách dự báo rủi ro trễ hạn & giả lập What-if cho 1 Task (US-069).
///
/// Tuân thủ kiến trúc của dự án:
/// - Chống stale state bằng `_requestToken`.
/// - Giới hạn thời gian phản hồi tối đa 15 giây (`_timeout`).
/// - Kiểm tra `isClosed` trước mọi lệnh `emit`.
class TaskRiskCubit extends Cubit<TaskRiskState> {
  static const Duration _timeout = Duration(seconds: 15);

  final RiskPredictionService _predictionService;
  final TaskRepository? taskRepository;
  final BacklogRepository? backlogRepository;
  final String projectId;
  final DateTime? Function()? nowProvider;

  int _requestToken = 0;
  List<TaskModel> _cachedProjectTasks = const [];
  UserStoryModel? _cachedStory;
  SprintModel? _cachedSprint;

  TaskRiskCubit({
    required this.projectId,
    RiskPredictionService? predictionService,
    this.taskRepository,
    this.backlogRepository,
    this.nowProvider,
  }) : _predictionService = predictionService ?? RiskPredictionService(),
       super(const TaskRiskState());

  Future<void> evaluateTask({
    required TaskModel task,
    List<ProjectMemberDisplay> members = const [],
    UserStoryModel? story,
    SprintModel? sprint,
    List<TaskModel>? allProjectTasks,
  }) async {
    final token = ++_requestToken;
    if (isClosed) return;
    emit(state.copyWith(status: TaskRiskStatus.loading, errorMessage: null));

    try {
      await _evaluateInternal(
        token: token,
        task: task,
        members: members,
        story: story,
        sprint: sprint,
        allProjectTasks: allProjectTasks,
      ).timeout(_timeout);
    } on TimeoutException {
      if (isClosed || token != _requestToken) return;
      emit(
        state.copyWith(
          status: TaskRiskStatus.error,
          errorMessage:
              'Quá thời gian phân tích rủi ro AI (15 giây). Vui lòng thử lại.',
        ),
      );
    } catch (e) {
      if (isClosed || token != _requestToken) return;
      emit(
        state.copyWith(
          status: TaskRiskStatus.error,
          errorMessage: 'Không thể phân tích rủi ro Task: $e',
        ),
      );
    }
  }

  Future<void> _evaluateInternal({
    required int token,
    required TaskModel task,
    required List<ProjectMemberDisplay> members,
    UserStoryModel? story,
    SprintModel? sprint,
    List<TaskModel>? allProjectTasks,
  }) async {
    final artifact = await _predictionService.ensureModelLoaded(projectId);
    if (isClosed || token != _requestToken) return;

    List<TaskModel> projectTasks = allProjectTasks ?? _cachedProjectTasks;
    if (projectTasks.isEmpty &&
        taskRepository != null &&
        projectId.isNotEmpty) {
      try {
        projectTasks = await taskRepository!
            .streamTasksByProject(projectId)
            .first
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        projectTasks = <TaskModel>[task];
      }
    }
    if (projectTasks.isEmpty) {
      projectTasks = <TaskModel>[task];
    }
    _cachedProjectTasks = projectTasks;

    UserStoryModel? effectiveStory = story ?? _cachedStory;
    if (effectiveStory == null &&
        backlogRepository != null &&
        projectId.isNotEmpty &&
        task.storyId.isNotEmpty) {
      try {
        final stories = await backlogRepository!.getStoriesByIds(
          projectId,
          <String>[task.storyId],
        );
        if (stories.isNotEmpty) {
          effectiveStory = stories.first;
        }
      } catch (_) {}
    }
    _cachedStory = effectiveStory;
    _cachedSprint = sprint ?? _cachedSprint;

    if (isClosed || token != _requestToken) return;

    final now = nowProvider != null ? nowProvider!() : null;
    final prediction = _predictionService.predictTaskRiskSync(
      artifact: artifact,
      task: task,
      story: effectiveStory,
      sprint: _cachedSprint,
      members: members,
      allProjectTasks: projectTasks,
      now: now,
    );

    final initialSim = prediction.isPredictable
        ? _predictionService.simulateWhatIfSync(
            artifact: artifact,
            task: task,
            originalProbability: prediction.probability,
            story: effectiveStory,
            sprint: _cachedSprint,
            scoresByUserId: {
              for (final s in prediction.memberScores) s.userId: s,
            },
            allProjectTasks: projectTasks,
            targetAssigneeId: task.assigneeId,
            targetAssigneeName: task.assigneeName,
            addedDays: 0,
            now: now,
          )
        : null;

    if (isClosed || token != _requestToken) return;
    emit(
      TaskRiskState(
        status: TaskRiskStatus.loaded,
        prediction: prediction,
        artifact: artifact,
        activeSimulation: initialSim,
        selectedAssigneeId: task.assigneeId,
        selectedAssigneeName: task.assigneeName,
        simulatedAddedDays: 0,
      ),
    );
  }

  /// Cập nhật giả lập What-if tức thì khi người dùng đổi người nhận hoặc kéo thanh trượt ngày hạn chót.
  void simulateWhatIf({
    String? assigneeId,
    String? assigneeName,
    int? addedDays,
  }) {
    if (isClosed) return;
    final currentPrediction = state.prediction;
    final artifact = state.artifact;
    if (currentPrediction == null ||
        !currentPrediction.isPredictable ||
        artifact == null) {
      return;
    }

    final nextAssigneeId = assigneeId ?? state.selectedAssigneeId;
    final nextAssigneeName = assigneeName ?? state.selectedAssigneeName;
    final nextAddedDays = (addedDays ?? state.simulatedAddedDays).clamp(0, 14);

    final scoresByUserId = <String, MemberPerformanceScore>{
      for (final s in currentPrediction.memberScores) s.userId: s,
    };

    final now = nowProvider != null ? nowProvider!() : null;
    final sim = _predictionService.simulateWhatIfSync(
      artifact: artifact,
      task: currentPrediction.task,
      originalProbability: currentPrediction.probability,
      story: currentPrediction.story ?? _cachedStory,
      sprint: currentPrediction.sprint ?? _cachedSprint,
      scoresByUserId: scoresByUserId,
      allProjectTasks: _cachedProjectTasks,
      targetAssigneeId: nextAssigneeId,
      targetAssigneeName: nextAssigneeName,
      addedDays: nextAddedDays,
      now: now,
    );

    if (isClosed) return;
    emit(
      state.copyWith(
        activeSimulation: sim,
        selectedAssigneeId: nextAssigneeId,
        selectedAssigneeName: nextAssigneeName,
        simulatedAddedDays: nextAddedDays,
      ),
    );
  }
}
