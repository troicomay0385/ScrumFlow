import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/ai/risk_prediction_service.dart';
import '../../../data/models/project_member_display.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/user_story_model.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../../../data/repositories/task_repository.dart';
import 'sprint_risk_state.dart';

/// Cubit dự báo rủi ro trễ hạn cho toàn bộ Task trong một Sprint hoặc User Story (US-069).
///
/// Lắng nghe stream task hoặc danh sách task truyền vào, tính toán cục bộ bằng
/// [RiskPredictionService], sắp xếp giảm dần theo xác suất trễ hạn.
class SprintRiskCubit extends Cubit<SprintRiskState> {
  static const Duration _timeout = Duration(seconds: 15);

  final RiskPredictionService _predictionService;
  final TaskRepository? taskRepository;
  final ProjectMemberRepository? memberRepository;
  final String projectId;
  final DateTime? Function()? nowProvider;

  StreamSubscription<List<TaskModel>>? _tasksSub;
  int _loadToken = 0;

  SprintRiskCubit({
    required this.projectId,
    RiskPredictionService? predictionService,
    this.taskRepository,
    this.memberRepository,
    this.nowProvider,
  }) : _predictionService = predictionService ?? RiskPredictionService(),
       super(const SprintRiskState());

  /// Theo dõi danh sách Task thuộc các User Stories trong Sprint và dự báo rủi ro.
  Future<void> watchSprintTasks({
    required SprintModel sprint,
    required List<UserStoryModel> stories,
    List<ProjectMemberDisplay>? members,
  }) async {
    await _tasksSub?.cancel();
    final token = ++_loadToken;
    if (isClosed) return;

    final storyIds = stories
        .map((s) => s.id)
        .where((id) => id.isNotEmpty)
        .toList();
    if (storyIds.isEmpty) {
      emit(const SprintRiskState(status: SprintRiskStatus.loaded));
      return;
    }

    emit(const SprintRiskState(status: SprintRiskStatus.loading));

    final storiesById = <String, UserStoryModel>{
      for (final s in stories) s.id: s,
    };
    final sprintsByStoryId = <String, SprintModel>{
      for (final s in stories) s.id: sprint,
    };

    List<ProjectMemberDisplay> effectiveMembers = members ?? const [];
    if (effectiveMembers.isEmpty && memberRepository != null) {
      try {
        effectiveMembers = await memberRepository!
            .streamMembers(projectId)
            .first
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }

    if (isClosed || token != _loadToken) return;

    final taskRepo = taskRepository;
    if (taskRepo == null) {
      emit(const SprintRiskState(status: SprintRiskStatus.loaded));
      return;
    }

    bool firstEventReceived = false;
    final timeoutTimer = Timer(_timeout, () {
      if (!firstEventReceived && !isClosed && token == _loadToken) {
        _tasksSub?.cancel();
        emit(
          const SprintRiskState(
            status: SprintRiskStatus.error,
            errorMessage:
                'Quá thời gian tải dữ liệu Task của Sprint (15 giây).',
          ),
        );
      }
    });

    _tasksSub = taskRepo
        .streamTasksByStories(storyIds)
        .listen(
          (tasks) async {
            firstEventReceived = true;
            timeoutTimer.cancel();
            await _computeAndEmit(
              token: token,
              tasks: tasks,
              storiesById: storiesById,
              sprintsByStoryId: sprintsByStoryId,
              members: effectiveMembers,
            );
          },
          onError: (Object error) {
            firstEventReceived = true;
            timeoutTimer.cancel();
            if (isClosed || token != _loadToken) return;
            emit(
              SprintRiskState(
                status: SprintRiskStatus.error,
                errorMessage: 'Không thể tải danh sách Task: $error',
              ),
            );
          },
        );
  }

  /// Đánh giá trực tiếp danh sách Task sẵn có (ví dụ từ `TaskBloc` trên `TaskBoardScreen`).
  Future<void> evaluateTasksList({
    required List<TaskModel> tasks,
    Map<String, UserStoryModel> storiesById = const {},
    Map<String, SprintModel> sprintsByStoryId = const {},
    List<ProjectMemberDisplay> members = const [],
  }) async {
    final token = ++_loadToken;
    if (isClosed) return;
    await _computeAndEmit(
      token: token,
      tasks: tasks,
      storiesById: storiesById,
      sprintsByStoryId: sprintsByStoryId,
      members: members,
    );
  }

  Future<void> _computeAndEmit({
    required int token,
    required List<TaskModel> tasks,
    required Map<String, UserStoryModel> storiesById,
    required Map<String, SprintModel> sprintsByStoryId,
    required List<ProjectMemberDisplay> members,
  }) async {
    try {
      final now = nowProvider != null ? nowProvider!() : null;
      final predictions = await _predictionService.predictBatchTasks(
        projectId: projectId,
        tasks: tasks,
        storiesById: storiesById,
        sprintsByStoryId: sprintsByStoryId,
        members: members,
        allProjectTasks: tasks,
        now: now,
      );

      if (isClosed || token != _loadToken) return;

      final byId = <String, TaskRiskPrediction>{
        for (final p in predictions) p.task.id: p,
      };
      final ranked = List<TaskRiskPrediction>.from(predictions)
        ..sort((a, b) {
          if (a.isPredictable != b.isPredictable) {
            return a.isPredictable ? -1 : 1;
          }
          return b.probability.compareTo(a.probability);
        });

      emit(
        SprintRiskState(
          status: SprintRiskStatus.loaded,
          predictionsByTaskId: byId,
          rankedPredictions: ranked,
        ),
      );
    } catch (e) {
      if (isClosed || token != _loadToken) return;
      emit(
        SprintRiskState(
          status: SprintRiskStatus.error,
          errorMessage: 'Lỗi dự báo rủi ro AI: $e',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _tasksSub?.cancel();
    return super.close();
  }
}
