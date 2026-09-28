import '../models/user_story_model.dart';

abstract class BacklogRepository {
  /// Lắng nghe danh sách User Stories real-time.
  Stream<List<UserStoryModel>> streamUserStories(String projectId);

  /// Lấy danh sách User Stories (one-shot).
  Future<List<UserStoryModel>> getUserStories(String projectId);

  /// Lấy chi tiết 1 User Story.
  Future<UserStoryModel?> getUserStory(String projectId, String storyId);

  /// Tạo hoặc cập nhật User Story.
  Future<void> saveUserStory(String projectId, UserStoryModel story);

  /// Tạo dữ liệu User Story mẫu với các User ảo.
  Future<void> seedMockStories(String projectId);
}
