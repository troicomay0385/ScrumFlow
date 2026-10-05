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
  Future<void> seedMockSprints(String projectId);
}
