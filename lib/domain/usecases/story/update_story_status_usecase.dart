import '../../repositories/story_repository.dart';

/// Use case cập nhật trạng thái User Story (US-048).
///
/// Các trạng thái hợp lệ bao gồm: "To Do", "In Progress", "Done", "Rejected".
class UpdateStoryStatusUseCase {
  final StoryRepository _repository;

  static const List<String> validStatuses = [
    'To Do',
    'In Progress',
    'Done',
    'Rejected',
  ];

  UpdateStoryStatusUseCase(this._repository);

  Future<void> call({
    required String projectId,
    required String storyId,
    required String newStatus,
  }) =>
      execute(
        projectId: projectId,
        storyId: storyId,
        newStatus: newStatus,
      );

  Future<void> execute({
    required String projectId,
    required String storyId,
    required String newStatus,
  }) async {
    if (projectId.trim().isEmpty) {
      throw Exception('projectId không hợp lệ (bị rỗng).');
    }
    if (storyId.trim().isEmpty) {
      throw Exception('storyId không hợp lệ (bị rỗng).');
    }
    if (!validStatuses.contains(newStatus)) {
      throw Exception('Trạng thái không hợp lệ: $newStatus');
    }

    return await _repository.updateStoryStatus(
      projectId: projectId,
      storyId: storyId,
      newStatus: newStatus,
    );
  }
}
