import '../datasources/backlog_datasource.dart' show PaginatedResult;
import '../models/user_story_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;

abstract class BacklogRepository {
  /// Lắng nghe danh sách User Stories real-time.
  Stream<List<UserStoryModel>> streamUserStories(String projectId);

  /// Lấy danh sách User Stories (one-shot).
  Future<List<UserStoryModel>> getUserStories(String projectId);

  /// Lấy 1 trang User Stories theo cursor-based pagination (US-054).
  ///
  /// Chỉ load [pageSize] items/lần từ Firestore thay vì toàn bộ backlog.
  /// [startAfterDoc] là con trỏ cuối trang trước (null = trang đầu).
  /// [statusFilter] lọc theo trạng thái trên server (null = tất cả).
  Future<PaginatedResult> getUserStoriesPaginated({
    required String projectId,
    required int pageSize,
    DocumentSnapshot? startAfterDoc,
    String? statusFilter,
  });

  /// Lấy danh sách User Stories theo tập hợp IDs (dùng cho Task Board theo Sprint).
  Future<List<UserStoryModel>> getStoriesByIds(
    String projectId,
    List<String> storyIds,
  );

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

  /// Cập nhật nội dung User Story (US-011) & Story Points (US-013).
  ///
  /// Chỉ user có `Permission.manageBacklog` (PO/SM). Cập nhật các field
  /// cho phép (title, description, priority, storyPoints, deadline) —
  /// KHÔNG đụng tags/projectId/createdBy/storyKey/status.
  Future<UserStoryModel> updateUserStory({
    required String projectId,
    required String storyId,
    required String title,
    required String description,
    required String priority,
    required int storyPoints,
    DateTime? deadline,
    String? assigneeId,
    String? assigneeName,
    String? assigneeEmail,
    bool clearAssignee = false,
  });

  /// Thay toàn bộ danh sách tag của 1 User Story (US-014) — chỉ cập nhật
  /// field `tags`, không đụng các field khác.
  Future<void> updateTags({
    required String projectId,
    required String storyId,
    required List<String> tags,
  });

  /// Xóa 1 User Story (US-012).
  Future<void> deleteUserStory({
    required String projectId,
    required String storyId,
  });

  /// Xóa hàng loạt User Stories (US-053).
  Future<void> deleteUserStories({
    required String projectId,
    required List<String> storyIds,
  });

  /// Cập nhật trạng thái User Story (US-048).
  ///
  /// Chỉ PO hoặc SM mới được phép thực hiện.
  Future<void> updateStoryStatus({
    required String projectId,
    required String storyId,
    required String newStatus,
  });

  /// Tạo dữ liệu User Story mẫu với các User ảo.
  Future<void> seedMockStories(String projectId);
}

