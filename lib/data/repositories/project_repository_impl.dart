import '../../app/authorization/permission.dart';
import '../../app/authorization/project_role.dart';
import '../../app/authorization/role_permissions.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/project_datasource.dart';
import '../datasources/project_member_datasource.dart';
import '../datasources/local_cache_datasource.dart';
import '../models/project_model.dart';
import '../models/project_summary.dart';
import 'project_repository.dart';
import 'notification_repository.dart';

/// Implementation của [ProjectRepository].
///
/// Phối hợp [ProjectDataSource] (collection `projects`) và
/// [ProjectMemberDataSource] (collection `projectMembers`) — 2 write
/// riêng biệt (không dùng batch) vì Firestore Security Rules cho việc
/// bootstrap PO membership cần `get()` project doc ĐÃ COMMIT
/// (`createdBy == request.auth.uid`); trong 1 batched write, các thao
/// tác khác chưa chắc đã "nhìn thấy" nhau khi rule evaluate.
///
/// Nếu bước 2 (tạo PO membership) thất bại, project vừa tạo ở bước 1
/// sẽ bị xoá (rollback) để tránh để lại project "mồ côi" không ai quản trị.
class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectDataSource _projectDataSource;
  final ProjectMemberDataSource _memberDataSource;
  final FirebaseAuthDataSource _authDataSource;
  final NotificationRepository? _notificationRepository;
  final LocalCacheDataSource? _localCache;

  ProjectRepositoryImpl({
    required ProjectDataSource projectDataSource,
    required ProjectMemberDataSource memberDataSource,
    required FirebaseAuthDataSource authDataSource,
    NotificationRepository? notificationRepository,
    LocalCacheDataSource? localCache,
  })  : _projectDataSource = projectDataSource,
        _memberDataSource = memberDataSource,
        _authDataSource = authDataSource,
        _notificationRepository = notificationRepository,
        _localCache = localCache;

  String get _currentUserId {
    final uid = _authDataSource.currentUser?.uid;
    if (uid == null) {
      throw Exception('Bạn cần đăng nhập để thực hiện thao tác này.');
    }
    return uid;
  }

  @override
  Future<ProjectModel> createProject({
    required String name,
    required String description,
  }) async {
    final uid = _currentUserId;

    final project = await _projectDataSource.createProject(
      name: name,
      description: description,
      createdBy: uid,
    );

    try {
      await _memberDataSource.createMembership(
        projectId: project.id,
        userId: uid,
        role: ProjectRole.po,
        createdBy: uid,
      );
    } catch (e) {
      // Rollback — không để lại project không có thành viên quản trị nào.
      await _projectDataSource.deleteProject(project.id);
      rethrow;
    }

    return project;
  }

  @override
  Future<List<ProjectSummary>> getMyProjects() async {
    final uid = _currentUserId;

    final memberships = await _memberDataSource.getMembershipsForUser(uid);
    if (memberships.isEmpty) return [];

    final projectIds = memberships.map((m) => m.projectId).toList();
    final projects = await _projectDataSource.getProjectsByIds(projectIds);
    final projectById = {for (final p in projects) p.id: p};

    final summaries = <ProjectSummary>[];
    for (final membership in memberships) {
      final project = projectById[membership.projectId];
      // Project đã bị xoá nhưng membership còn sót lại → bỏ qua thay vì crash.
      if (project == null) continue;
      summaries.add(ProjectSummary(project: project, myRole: membership.role));
    }
    return summaries;
  }

  @override
  Future<ProjectModel?> getProject(String projectId) {
    return _projectDataSource.getProject(projectId);
  }

  @override
  Future<void> updateProject({
    required String projectId,
    required String name,
    required String description,
  }) async {
    final uid = _currentUserId;
    final membership = await _memberDataSource.getMembership(
      projectId: projectId,
      userId: uid,
    );
    if (membership == null ||
        !hasPermission(membership.role, Permission.manageProject)) {
      throw Exception('Bạn không có quyền chỉnh sửa thông tin project này.');
    }

    await _projectDataSource.updateProject(
      projectId: projectId,
      name: name,
      description: description,
    );

    if (_notificationRepository != null) {
      final memberships = await _memberDataSource.getMembers(projectId);
      final memberIds = memberships.map((m) => m.userId).where((id) => id != uid).toList();
      if (memberIds.isNotEmpty) {
        _notificationRepository.notifyProjectUpdated(
          memberIds: memberIds,
          projectName: name,
          projectId: projectId,
        );
      }
    }
  }

  @override
  Future<void> deleteProject(String projectId) async {
    final uid = _currentUserId;

    // Kiểm tra quyền: chỉ PO được xoá project
    final membership = await _memberDataSource.getMembership(
      projectId: projectId,
      userId: uid,
    );
    if (membership == null ||
        !hasPermission(membership.role, Permission.manageProject)) {
      throw Exception('Bạn không có quyền xoá project này.');
    }

    // Xoá tất cả membership của các thành viên khác trước
    final members = await _memberDataSource.getMembers(projectId);
    for (final m in members) {
      if (m.userId != uid) {
        try {
          await _memberDataSource.removeMember(
            projectId: projectId,
            userId: m.userId,
          );
        } catch (_) {}
      }
    }

    // Xoá project document
    await _projectDataSource.deleteProject(projectId);

    // Xoá membership của chính PO sau khi project đã xoá
    try {
      await _memberDataSource.removeMember(
        projectId: projectId,
        userId: uid,
      );
    } catch (_) {}

    // US-062: Xoá SQLite cache của project
    try {
      await _localCache?.clearProjectCache(projectId);
    } catch (_) {}
  }

  @override
  Stream<ProjectModel?> streamProject(String projectId) {
    return _projectDataSource.streamProject(projectId);
  }
}
