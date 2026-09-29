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

  /// Tạo mới 1 User Story trong Product Backlog của [projectId] (US-010).
  ///
  /// Chỉ user có `Permission.manageBacklog` (PO/SM). Tự sinh `storyKey`
  /// kế tiếp và gắn `createdBy` = uid hiện tại. Throw [Exception] với thông
  /// báo tiếng Việt khi không có quyền hoặc ghi Firestore thất bại.
  Future<UserStoryModel> createUserStory({
    required String projectId,
    required String title,
    required String description,
    required String priority,
    DateTime? deadline,
  });

  /// Thay toàn bộ danh sách tag của 1 User Story (US-014) — chỉ cập nhật
  /// field `tags`, không đụng các field khác.
  Future<void> updateTags({
    required String projectId,
    required String storyId,
    required List<String> tags,
  });

  /// Tạo dữ liệu User Story mẫu với các User ảo.
  Future<void> seedMockStories(String projectId);
}
