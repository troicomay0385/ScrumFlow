abstract class StoryRepository {
  /// Cập nhật trạng thái User Story (US-048).
  ///
  /// Chỉ PO hoặc SM mới được phép thực hiện thao tác này.
  /// Khi chuyển sang 'Done' hoặc 'Rejected', trường completedAt sẽ được cập nhật.
  Future<void> updateStoryStatus({
    required String projectId,
    required String storyId,
    required String newStatus,
  });
}
