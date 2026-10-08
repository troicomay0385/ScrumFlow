import '../../../data/repositories/sprint_repository.dart';

/// Use case đóng Sprint (US-050).
///
/// Chuyển Sprint từ trạng thái "Active" → "Completed".
/// Các User Story chưa Done có thể chuyển về Product Backlog hoặc Sprint tiếp theo.
class CloseSprintUseCase {
  final SprintRepository _repository;

  CloseSprintUseCase(this._repository);

  Future<void> call({
    required String projectId,
    required String sprintId,
    String? targetSprintId,
    required List<String> incompleteStoryIds,
  }) =>
      execute(
        projectId: projectId,
        sprintId: sprintId,
        targetSprintId: targetSprintId,
        incompleteStoryIds: incompleteStoryIds,
      );

  Future<void> execute({
    required String projectId,
    required String sprintId,
    String? targetSprintId,
    required List<String> incompleteStoryIds,
  }) async {
    if (projectId.trim().isEmpty) {
      throw Exception('projectId không hợp lệ (bị rỗng).');
    }
    if (sprintId.trim().isEmpty) {
      throw Exception('sprintId không hợp lệ (bị rỗng).');
    }

    await _repository.closeSprint(
      projectId: projectId,
      sprintId: sprintId,
      targetSprintId: targetSprintId,
      incompleteStoryIds: incompleteStoryIds,
    );
  }
}
