import '../models/sprint_model.dart';

abstract class SprintRepository {
  Stream<List<SprintModel>> streamSprints(String projectId);
	Future<SprintModel> createSprint({
	required String projectId,
	required String name,
	required String goal,
	required DateTime startDate,
	required DateTime endDate,
  });
  Future<void> addStoryToSprint({
    required String projectId,
    required String sprintId,
    required String storyId,
  });
  Future<void> addStoriesToSprint({
    required String projectId,
    required String sprintId,
    required List<String> storyIds,
  });
  Future<void> removeStoriesFromSprint({
    required String projectId,
    required String sprintId,
    required List<String> storyIds,
  });
  Future<void> moveStoriesToSprint({
    required String projectId,
    String? sourceSprintId,
    String? targetSprintId,
    required List<String> storyIds,
  });

  /// US-049: Chuyển Sprint từ Planned → Active.
  /// Ràng buộc: chỉ PO/SM, chỉ 1 sprint active/project, sprint ≥ 1 story.
  Future<void> startSprint({
    required String projectId,
    required String sprintId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// US-050: Chuyển Sprint từ Active → Completed (atomic WriteBatch).
  /// [incompleteStoryIds] là các story chưa Done; [targetSprintId] = null → về backlog.
  Future<void> closeSprint({
    required String projectId,
    required String sprintId,
    String? targetSprintId,
    required List<String> incompleteStoryIds,
  });

  Future<void> seedMockSprints(String projectId);
  Future<SprintModel> seedSprint({
    required String projectId,
    required String name,
    required String goal,
    required DateTime startDate,
    required DateTime endDate,
    String status = 'Active',
    List<String> storyIds = const [],
  });
}
