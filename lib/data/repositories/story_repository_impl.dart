import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../app/authorization/permission.dart';
import '../../app/authorization/project_role.dart';
import '../../app/authorization/role_permissions.dart';
import '../../app/constants/firebase_error_mapper.dart';
import '../../domain/repositories/story_repository.dart';
import '../datasources/backlog_datasource.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/project_member_datasource.dart';

/// Implementation của [StoryRepository] (US-048).
class StoryRepositoryImpl implements StoryRepository {
  final BacklogDataSource _dataSource;
  final ProjectMemberDataSource _memberDataSource;
  final FirebaseAuthDataSource _authDataSource;
  final DateTime Function() _now;

  StoryRepositoryImpl({
    BacklogDataSource? dataSource,
    ProjectMemberDataSource? memberDataSource,
    FirebaseAuthDataSource? authDataSource,
    DateTime Function()? now,
  })  : _dataSource = dataSource ?? BacklogDataSource(),
        _memberDataSource = memberDataSource ?? ProjectMemberDataSource(),
        _authDataSource = authDataSource ?? FirebaseAuthDataSource(),
        _now = now ?? DateTime.now;

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

      await _requirePoOrSm(projectId);

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

  /// Kiểm tra vai trò của người dùng: chỉ PO hoặc SM mới có quyền.
  Future<String> _requirePoOrSm(String projectId) async {
    final uid = _authDataSource.currentUser?.uid;
    if (uid == null) {
      throw Exception('Bạn cần đăng nhập để thực hiện thao tác này.');
    }

    final membership = await _memberDataSource.getMembership(
      projectId: projectId,
      userId: uid,
    );

    if (membership == null ||
        (membership.role != ProjectRole.po &&
            membership.role != ProjectRole.sm &&
            !hasPermission(membership.role, Permission.manageBacklog))) {
      throw Exception('Chỉ PO/SM mới có quyền cập nhật trạng thái');
    }

    return uid;
  }

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
