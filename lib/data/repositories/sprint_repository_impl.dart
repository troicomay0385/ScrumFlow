import 'dart:async';
import '../../app/authorization/permission.dart';
import '../../app/authorization/role_permissions.dart';
import '../datasources/sprint_datasource.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/project_member_datasource.dart';
import '../models/sprint_model.dart';
import 'sprint_repository.dart';

class SprintRepositoryImpl implements SprintRepository {
  final SprintDataSource _dataSource;
  final ProjectMemberDataSource _memberDataSource;
  final FirebaseAuthDataSource _authDataSource;

  SprintRepositoryImpl({
    SprintDataSource? dataSource,
    ProjectMemberDataSource? memberDataSource,
    FirebaseAuthDataSource? authDataSource,
  })  : _dataSource = dataSource ?? SprintDataSource(),
        _memberDataSource = memberDataSource ?? ProjectMemberDataSource(),
        _authDataSource = authDataSource ?? FirebaseAuthDataSource();

  @override
  Stream<List<SprintModel>> streamSprints(String projectId) {
    return _dataSource.streamSprints(projectId);
  }

  @override
  Future<SprintModel> createSprint({
    required String projectId,
    required String name,
    required String goal,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final uid = await _requireManageSprint(projectId);
    if (!endDate.isAfter(startDate)) {
      throw Exception('Ngày kết thúc phải sau ngày bắt đầu.');
    }
    final now = DateTime.now();
    return _dataSource.createSprint(SprintModel(
      id: '',
      projectId: projectId,
      name: name.trim(),
      goal: goal.trim(),
      startDate: startDate,
      endDate: endDate,
      createdBy: uid,
      createdAt: now,
      updatedAt: now,
    ));
  }

  @override
  Future<void> addStoryToSprint({
    required String projectId,
    required String sprintId,
    required String storyId,
  }) async {
    await addStoriesToSprint(
      projectId: projectId,
      sprintId: sprintId,
      storyIds: [storyId],
    );
  }

  @override
  Future<void> addStoriesToSprint({
    required String projectId,
    required String sprintId,
    required List<String> storyIds,
  }) async {
    await _requireManageSprint(projectId);
    await _dataSource.addStoriesToSprint(
      projectId: projectId,
      sprintId: sprintId,
      storyIds: storyIds,
    );
  }

  @override
  Future<void> removeStoriesFromSprint({
    required String projectId,
    required String sprintId,
    required List<String> storyIds,
  }) async {
    await _requireManageSprint(projectId);
    await _dataSource.removeStoriesFromSprint(
      projectId: projectId,
      sprintId: sprintId,
      storyIds: storyIds,
    );
  }

  @override
  Future<void> moveStoriesToSprint({
    required String projectId,
    String? sourceSprintId,
    String? targetSprintId,
    required List<String> storyIds,
  }) async {
    await _requireManageSprint(projectId);
    if (sourceSprintId != null && sourceSprintId.isNotEmpty) {
      await _dataSource.removeStoriesFromSprint(
        projectId: projectId,
        sprintId: sourceSprintId,
        storyIds: storyIds,
      );
    }
    if (targetSprintId != null && targetSprintId.isNotEmpty) {
      await _dataSource.addStoriesToSprint(
        projectId: projectId,
        sprintId: targetSprintId,
        storyIds: storyIds,
      );
    }
  }

  /// US-049: Chuyển Sprint từ Planned → Active.
  @override
  Future<void> startSprint({
    required String projectId,
    required String sprintId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _requireManageSprint(projectId);

    // Lấy toàn bộ sprints trong project để kiểm tra ràng buộc
    final allSprints = await _dataSource.streamSprints(projectId).first;

    final target = allSprints.firstWhere(
      (s) => s.id == sprintId,
      orElse: () => throw Exception('Sprint không tồn tại.'),
    );

    // Ràng buộc 1: Sprint phải ở trạng thái Planned
    if (target.status.toLowerCase() != 'planned') {
      throw Exception('Chỉ Sprint ở trạng thái "Planned" mới có thể được bắt đầu.');
    }

    // Ràng buộc 2: Chỉ 1 Sprint Active trong project
    final hasActive = allSprints.any(
      (s) => s.id != sprintId && s.status.toLowerCase() == 'active',
    );
    if (hasActive) {
      throw Exception('Dự án đã có 1 Sprint đang hoạt động (Active). Hãy đóng Sprint đó trước khi bắt đầu Sprint mới.');
    }

    // Ràng buộc 3: Sprint phải có ít nhất 1 User Story
    if (target.storyIds.isEmpty) {
      throw Exception('Sprint phải có ít nhất 1 User Story trước khi bắt đầu.');
    }

    await _dataSource.startSprint(
      projectId: projectId,
      sprintId: sprintId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// US-050: Đóng Sprint Active → Completed.
  @override
  Future<void> closeSprint({
    required String projectId,
    required String sprintId,
    String? targetSprintId,
    required List<String> incompleteStoryIds,
  }) async {
    await _requireManageSprint(projectId);

    // Kiểm tra sprint đang Active
    final allSprints = await _dataSource.streamSprints(projectId).first;
    final target = allSprints.firstWhere(
      (s) => s.id == sprintId,
      orElse: () => throw Exception('Sprint không tồn tại.'),
    );
    if (target.status.toLowerCase() != 'active') {
      throw Exception('Chỉ Sprint đang "Active" mới có thể được đóng.');
    }

    await _dataSource.closeSprint(
      projectId: projectId,
      sprintId: sprintId,
      targetSprintId: targetSprintId,
      incompleteStoryIds: incompleteStoryIds,
    );
  }

  Future<String> _requireManageSprint(String projectId) async {
    final uid = _authDataSource.currentUser?.uid;
    if (uid == null) throw Exception('Bạn cần đăng nhập để thực hiện thao tác này.');
    final membership = await _memberDataSource.getMembership(
      projectId: projectId,
      userId: uid,
    );
    if (membership == null || !hasPermission(membership.role, Permission.manageSprint)) {
      throw Exception('Bạn không có quyền quản lý Sprint này.');
    }
    return uid;
  }

  @override
  Future<void> seedMockSprints(String projectId) {
    return _dataSource.seedMockSprints(projectId);
  }

  @override
  Future<SprintModel> seedSprint({
    required String projectId,
    required String name,
    required String goal,
    required DateTime startDate,
    required DateTime endDate,
    String status = 'Active',
    List<String> storyIds = const [],
  }) async {
    final uid = _authDataSource.currentUser?.uid;
    final now = DateTime.now();
    return _dataSource.createSprint(SprintModel(
      id: '',
      projectId: projectId,
      name: name.trim(),
      goal: goal.trim(),
      startDate: startDate,
      endDate: endDate,
      status: status,
      storyIds: storyIds,
      createdBy: uid,
      createdAt: now,
      updatedAt: now,
    ));
  }
}

