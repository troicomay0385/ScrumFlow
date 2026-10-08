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
