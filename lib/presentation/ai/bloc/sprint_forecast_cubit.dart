import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/ai/sprint_forecast_service.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/models/user_story_model.dart';
import '../../../data/repositories/backlog_repository.dart';
import 'sprint_forecast_state.dart';

/// Cubit quản lý trạng thái dự báo tiến độ hoàn thành Sprint bằng Monte Carlo (US-070)
/// và chế độ thử nghiệm What-if dời bớt User Story chưa hoàn thành.
class SprintForecastCubit extends Cubit<SprintForecastState> {
  final String projectId;
  final SprintForecastService _forecastService;
  final BacklogRepository? backlogRepository;

  SprintModel? _currentSprint;
  List<UserStoryModel> _sprintStories = const [];
  List<SprintModel> _allSprints = const [];
  List<UserStoryModel> _allProjectStories = const [];
  Set<String> _excludedStoryIds = const {};

  SprintForecastCubit({
    required this.projectId,
    SprintForecastService? forecastService,
    this.backlogRepository,
  }) : _forecastService = forecastService ?? const SprintForecastService(),
       super(const SprintForecastInitial());

  /// Tính toán dự báo Monte Carlo cho [sprint] với danh sách [sprintStories] và [allSprints].
  Future<void> computeForecast({
    required SprintModel sprint,
    required List<UserStoryModel> sprintStories,
    List<SprintModel> allSprints = const [],
    List<UserStoryModel>? allProjectStories,
  }) async {
    emit(const SprintForecastLoading());
    try {
      _currentSprint = sprint;
      _sprintStories = sprintStories;
      _allSprints = allSprints;
      _excludedStoryIds = const {};

      if (allProjectStories != null) {
        _allProjectStories = allProjectStories;
      } else if (backlogRepository != null) {
        try {
          _allProjectStories = await backlogRepository!
              .getUserStories(projectId)
              .timeout(const Duration(seconds: 6));
        } catch (_) {
          _allProjectStories = sprintStories;
        }
      } else {
        _allProjectStories = sprintStories;
      }

      if (isClosed) return;
      _recomputeAndEmit();
    } catch (e) {
      if (!isClosed) {
        emit(
          SprintForecastError(
            'Không thể tính toán dự báo Sprint: ${e.toString()}',
          ),
        );
      }
    }
  }

  /// Bật/tắt loại trừ 1 User Story trong bảng thử nghiệm What-if (chỉ tính trên bộ nhớ,
  /// tuyệt đối không sửa dữ liệu Sprint thật).
  void toggleExcludedStory(String storyId) {
    if (_currentSprint == null) return;
    final next = Set<String>.from(_excludedStoryIds);
    if (!next.remove(storyId)) {
      next.add(storyId);
    }
    _excludedStoryIds = next;
    _recomputeAndEmit();
  }

  /// Khôi phục trạng thái dự báo gốc (bỏ toàn bộ lựa chọn What-if).
  void resetWhatIf() {
    if (_currentSprint == null || _excludedStoryIds.isEmpty) return;
    _excludedStoryIds = const {};
    _recomputeAndEmit();
  }

  void _recomputeAndEmit() {
    final sprint = _currentSprint;
    if (sprint == null || isClosed) return;

    final baseForecast = _forecastService.forecastSprint(
      sprint: sprint,
      sprintStories: _sprintStories,
      allSprints: _allSprints,
      allProjectStories: _allProjectStories,
      excludedStoryIds: const {},
    );

    final activeForecast = _excludedStoryIds.isEmpty
        ? baseForecast
        : _forecastService.forecastSprint(
            sprint: sprint,
            sprintStories: _sprintStories,
            allSprints: _allSprints,
            allProjectStories: _allProjectStories,
            excludedStoryIds: _excludedStoryIds,
          );

    final incompleteStories = _sprintStories
        .where((s) => s.status.trim().toLowerCase() != 'done')
        .toList();

    emit(
      SprintForecastLoaded(
        sprint: sprint,
        sprintStories: _sprintStories,
        incompleteStories: incompleteStories,
        baseForecast: baseForecast,
        activeForecast: activeForecast,
        excludedStoryIds: Set<String>.unmodifiable(_excludedStoryIds),
      ),
    );
  }
}
