import '../../app/authorization/project_role.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/project_member_datasource.dart';
import '../models/project_member_display.dart';
import 'project_member_repository.dart';

/// Implementation của [ProjectMemberRepository].
///
/// Phối hợp [ProjectMemberDataSource] (membership/role) và
/// [FirestoreDataSource] (hồ sơ user — tái sử dụng datasource đã có
/// sẵn từ tính năng Auth thay vì tạo datasource user mới).
class ProjectMemberRepositoryImpl implements ProjectMemberRepository {
  final ProjectMemberDataSource _memberDataSource;
  final FirestoreDataSource _userDataSource;
  final FirebaseAuthDataSource _authDataSource;

  ProjectMemberRepositoryImpl({
    required ProjectMemberDataSource memberDataSource,
    required FirestoreDataSource userDataSource,
    required FirebaseAuthDataSource authDataSource,
  })  : _memberDataSource = memberDataSource,
        _userDataSource = userDataSource,
        _authDataSource = authDataSource;

  String get _currentUserId {
    final uid = _authDataSource.currentUser?.uid;
    if (uid == null) {
      throw Exception('Bạn cần đăng nhập để thực hiện thao tác này.');
    }
    return uid;
  }

  @override
  Future<ProjectRole?> getCurrentUserRole(String projectId) async {
    final membership = await _memberDataSource.getMembership(
      projectId: projectId,
      userId: _currentUserId,
    );
    return membership?.role;
  }

  @override
  Stream<ProjectRole?> streamCurrentUserRole(String projectId) {
    return _memberDataSource
        .streamMembership(projectId: projectId, userId: _currentUserId)
        .map((membership) => membership?.role);
  }

  @override
  Stream<List<ProjectMemberDisplay>> streamMembers(String projectId) {
    return _memberDataSource.streamMembers(projectId).asyncMap((members) async {
      final uids = members.map((m) => m.userId).toList();
      final usersById = await _userDataSource.getUserProfiles(uids);

      return members
          .map((m) =>
              ProjectMemberDisplay(membership: m, user: usersById[m.userId]))
          .toList();
    });
  }

  @override
  Future<void> addMemberByEmail({
    required String projectId,
    required String email,
    required ProjectRole role,
  }) async {
    final user = await _userDataSource.findUserByEmail(email.trim());
    if (user == null) {
      throw Exception('Không tìm thấy người dùng với email này.');
    }

    await _memberDataSource.createMembership(
      projectId: projectId,
      userId: user.id,
      role: role,
      createdBy: _currentUserId,
    );
  }

  @override
  Future<void> updateMemberRole({
    required String projectId,
    required String targetUserId,
    required ProjectRole newRole,
  }) async {
    if (targetUserId == _currentUserId) {
      throw Exception(
          'Bạn không thể tự thay đổi vai trò của chính mình. Hãy nhờ một Product Owner khác thực hiện.');
    }

    await _memberDataSource.updateRole(
      projectId: projectId,
      userId: targetUserId,
      newRole: newRole,
    );
  }

  @override
  Future<void> removeMember({
    required String projectId,
    required String targetUserId,
  }) async {
    if (targetUserId == _currentUserId) {
      throw Exception('Bạn không thể tự xoá chính mình khỏi project.');
    }

    await _memberDataSource.removeMember(
      projectId: projectId,
      userId: targetUserId,
    );
  }
}
