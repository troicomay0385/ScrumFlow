import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../app/authorization/permission.dart';
import '../../app/authorization/role_permissions.dart';
import '../../app/constants/firebase_error_mapper.dart';
import '../datasources/backlog_datasource.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/project_member_datasource.dart';
import '../models/user_story_model.dart';
import 'backlog_repository.dart';
import 'notification_repository.dart';

/// Implementation của [BacklogRepository].
///
/// Các thao tác ghi (tạo story, gắn tag) kiểm tra `Permission.manageBacklog`
/// ở đây TRƯỚC khi gọi Firestore — lớp bảo vệ thứ 2 bên cạnh Firestore
/// Security Rules (cùng cách làm với `ProjectRepositoryImpl.updateProject`).
class BacklogRepositoryImpl implements BacklogRepository {
  final BacklogDataSource _dataSource;
  final ProjectMemberDataSource _memberDataSource;
  final FirebaseAuthDataSource _authDataSource;
  final DateTime Function() _now;
  final NotificationRepository? _notificationRepository;

  BacklogRepositoryImpl({
    BacklogDataSource? dataSource,
    ProjectMemberDataSource? memberDataSource,
    FirebaseAuthDataSource? authDataSource,
    DateTime Function()? now,
    NotificationRepository? notificationRepository,
  })  : _dataSource = dataSource ?? BacklogDataSource(),
        _memberDataSource = memberDataSource ?? ProjectMemberDataSource(),
        _authDataSource = authDataSource ?? FirebaseAuthDataSource(),
        _now = now ?? DateTime.now,
        _notificationRepository = notificationRepository ?? NotificationRepository();

  @override
  Stream<List<UserStoryModel>> streamUserStories(String projectId) {
    return _dataSource.streamUserStories(projectId);
  }

  @override
  Future<List<UserStoryModel>> getUserStories(String projectId) {
    return _dataSource.getUserStories(projectId);
  }

  @override
  Future<PaginatedResult> getUserStoriesPaginated({
    required String projectId,
    required int pageSize,
    fs.DocumentSnapshot? startAfterDoc,
    String? statusFilter,
  }) {
    return _dataSource.getUserStoriesPaginated(
      projectId: projectId,
      pageSize: pageSize,
      startAfterDoc: startAfterDoc,
      statusFilter: statusFilter,
    );
  }

  @override
  Future<List<UserStoryModel>> getStoriesByIds(
    String projectId,
    List<String> storyIds,
  ) {
    return _dataSource.getStoriesByIds(projectId, storyIds);
  }


  @override
  Future<UserStoryModel?> getUserStory(String projectId, String storyId) {
    return _dataSource.getUserStory(projectId, storyId);
  }

  @override
  Future<void> saveUserStory(String projectId, UserStoryModel story) {
    return _dataSource.saveUserStory(projectId, story);
  }

  @override
  Future<UserStoryModel> createUserStory({
    required String projectId,
    required String title,
    required String description,
    required String priority,
    DateTime? deadline,
  }) {
    return _guard(() async {
      if (projectId.trim().isEmpty) {
        throw Exception('projectId không hợp lệ (bị rỗng).');
      }

      final uid = await _requireManageBacklog(projectId);
      final existing = await _dataSource.getUserStories(projectId);
      final now = _now();

      final story = UserStoryModel(
        id: '',
        projectId: projectId,
        storyKey: nextStoryKey(existing),
        title: title.trim(),
        description: description.trim(),
        priority: priority,
        // Theo convention dữ liệu hiện có: story mới luôn ở trạng thái
        // To Do; Story Points giữ mặc định của model cho tới US-013.
        status: 'To Do',
        deadline: deadline,
        createdBy: uid,
        createdAt: now,
        updatedAt: now,
      );
      final created = await _dataSource.createUserStory(projectId, story);
      
      if (_notificationRepository != null) {
        try {
          final members = await _memberDataSource.getMembers(projectId);
          final memberIds = members.map((m) => m.userId).toSet();
          // BỎ ĐI điều kiện lọc receiverId != currentUserId:
          // Đảm bảo ngay cả người tạo User Story (uid) vẫn nhận được thông báo để test 1 tài khoản
          if (uid.isNotEmpty) {
            memberIds.add(uid);
          }
          if (memberIds.isNotEmpty) {
            await _notificationRepository.notifyNewStory(
              memberIds: memberIds.toList(),
              storyTitle: title.trim(),
              projectId: projectId,
            );
          }
        } catch (e) {
          print('[NOTIFICATION ERROR] Lỗi gửi thông báo User Story: $e');
        }
      }

      return created;
    });
  }

  @override
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
  }) {
    return _guard(() async {
      await _requireManageBacklog(projectId);
      final existing = await _dataSource.getUserStory(projectId, storyId);
      if (existing == null) {
        throw Exception('User Story không tồn tại hoặc đã bị xoá.');
      }

      final updated = existing.copyWith(
        title: title.trim(),
        description: description.trim(),
        priority: priority,
        storyPoints: storyPoints,
        deadline: deadline,
        assigneeId: assigneeId,
        assigneeName: assigneeName,
        assigneeEmail: assigneeEmail,
        clearAssignee: clearAssignee,
        updatedAt: _now(),
      );

      await _dataSource.updateUserStory(projectId, updated);
      return updated;
    });
  }

  @override
  Future<void> updateTags({
    required String projectId,
    required String storyId,
    required List<String> tags,
  }) {
    return _guard(() async {
      await _requireManageBacklog(projectId);
      await _dataSource.updateTags(projectId, storyId, tags, _now());
    });
  }

  @override
  Future<void> deleteUserStory({
    required String projectId,
    required String storyId,
  }) {
    return deleteUserStories(projectId: projectId, storyIds: [storyId]);
  }

  @override
  Future<void> deleteUserStories({
    required String projectId,
    required List<String> storyIds,
  }) {
    return _guard(() async {
      await _requireManageBacklog(projectId);
      await _dataSource.deleteUserStories(projectId, storyIds);
    });
  }

  @override
  Future<void> updateStoryStatus({
    required String projectId,
    required String storyId,
    required String newStatus,
  }) {
    return _guard(() async {
      final validStatuses = ['To Do', 'In Progress', 'Done', 'Rejected'];
      if (!validStatuses.contains(newStatus)) {
        throw Exception('Trạng thái không hợp lệ: $newStatus');
      }

      final uid = _authDataSource.currentUser?.uid;
      if (uid == null) {
        throw Exception('Bạn cần đăng nhập để thực hiện thao tác này.');
      }
      final membership = await _memberDataSource.getMembership(
        projectId: projectId,
        userId: uid,
      );
      if (membership == null ||
          !hasPermission(membership.role, Permission.manageBacklog)) {
        throw Exception('Chỉ PO/SM mới có quyền cập nhật trạng thái');
      }

      final now = _now();
      final isCompleted = newStatus == 'Done' || newStatus == 'Rejected';

      await _dataSource.updateStoryStatus(
        projectId: projectId,
        storyId: storyId,
        status: newStatus,
        updatedAt: now,
        completedAt: isCompleted ? now : null,
        clearCompletedAt: !isCompleted,
      );
    });
  }

  @override
  Future<void> seedMockStories(String projectId) {
    return _dataSource.seedMockStories(projectId);
  }

  /// Sinh storyKey kế tiếp dạng `US-xxx` = số lớn nhất hiện có + 1.
  ///
  /// Lưu ý: tính phía client nên 2 người tạo cùng lúc có thể trùng key
  /// (KHÔNG trùng document — mỗi story vẫn có document id riêng).
  static String nextStoryKey(List<UserStoryModel> stories) {
    final pattern = RegExp(r'^US-(\d+)$');
    var maxNumber = 0;
    for (final story in stories) {
      final match = pattern.firstMatch(story.storyKey);
      final number = match == null ? null : int.tryParse(match.group(1)!);
      if (number != null && number > maxNumber) maxNumber = number;
    }
    return 'US-${(maxNumber + 1).toString().padLeft(3, '0')}';
  }

  Future<String> _requireManageBacklog(String projectId) async {
    final uid = _authDataSource.currentUser?.uid;
    if (uid == null) {
      throw Exception('Bạn cần đăng nhập để thực hiện thao tác này.');
    }
    final membership = await _memberDataSource.getMembership(
      projectId: projectId,
      userId: uid,
    );
    if (membership == null ||
        !hasPermission(membership.role, Permission.manageBacklog)) {
      throw Exception(
          'Chỉ Product Owner hoặc Scrum Master mới được chỉnh sửa Product Backlog.');
    }
    return uid;
  }

  /// Chuyển lỗi Firebase/timeout sang thông báo tiếng Việt qua
  /// [FirebaseErrorMapper] — UI không bao giờ thấy lỗi kỹ thuật thô.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on fs.FirebaseException catch (e) {
      throw Exception(FirebaseErrorMapper.mapErrorCode(e.code));
    } on TimeoutException {
      throw Exception(FirebaseErrorMapper.mapErrorCode('deadline-exceeded'));
    }
  }
}
