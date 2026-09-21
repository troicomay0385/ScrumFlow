import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/authorization/project_role.dart';
import '../models/project_member_model.dart';

/// DataSource cho Cloud Firestore collection `projectMembers`.
///
/// Đây là nơi duy nhất đọc/ghi membership + role. Doc ID luôn là
/// `ProjectMemberModel.membershipIdFor(projectId, userId)` — xem giải
/// thích trong model.
class ProjectMemberDataSource {
  final FirebaseFirestore _firestore;

  ProjectMemberDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _membersCollection =>
      _firestore.collection('projectMembers');

  /// Tạo membership mới (thêm thành viên, hoặc bootstrap PO khi tạo project).
  ///
  /// Throw nếu membership đã tồn tại (không cho ghi đè âm thầm — Security
  /// Rules cũng chặn việc này ở phía server).
  Future<ProjectMemberModel> createMembership({
    required String projectId,
    required String userId,
    required ProjectRole role,
    required String createdBy,
  }) async {
    final id = ProjectMemberModel.membershipIdFor(
      projectId: projectId,
      userId: userId,
    );
    final docRef = _membersCollection.doc(id);

    final existing = await docRef.get();
    if (existing.exists) {
      throw Exception('Người dùng này đã là thành viên của project.');
    }

    final now = DateTime.now();
    final member = ProjectMemberModel(
      id: id,
      projectId: projectId,
      userId: userId,
      role: role,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
    await docRef.set(member.toMap());
    return member;
  }

  Future<ProjectMemberModel?> getMembership({
    required String projectId,
    required String userId,
  }) async {
    final id =
        ProjectMemberModel.membershipIdFor(projectId: projectId, userId: userId);
    final doc = await _membersCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ProjectMemberModel.fromMap(doc.id, doc.data()!);
  }

  /// Stream role hiện tại của user trong project — dùng để UI/permission
  /// tự cập nhật real-time khi admin đổi role (yêu cầu mục N).
  Stream<ProjectMemberModel?> streamMembership({
    required String projectId,
    required String userId,
  }) {
    final id =
        ProjectMemberModel.membershipIdFor(projectId: projectId, userId: userId);
    return _membersCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ProjectMemberModel.fromMap(doc.id, doc.data()!);
    });
  }

  /// Stream toàn bộ thành viên của 1 project — chỉ PO đọc được theo
  /// Security Rules, gọi cho non-PO sẽ nhận lỗi permission-denied.
  Stream<List<ProjectMemberModel>> streamMembers(String projectId) {
    return _membersCollection
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectMemberModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Lấy toàn bộ membership của 1 user (project nào user đó tham gia).
  Future<List<ProjectMemberModel>> getMembershipsForUser(String userId) async {
    final snapshot =
        await _membersCollection.where('userId', isEqualTo: userId).get();
    return snapshot.docs
        .map((doc) => ProjectMemberModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> updateRole({
    required String projectId,
    required String userId,
    required ProjectRole newRole,
  }) async {
    final id =
        ProjectMemberModel.membershipIdFor(projectId: projectId, userId: userId);
    await _membersCollection.doc(id).update({
      'role': newRole.toFirestoreValue(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeMember({
    required String projectId,
    required String userId,
  }) async {
    final id =
        ProjectMemberModel.membershipIdFor(projectId: projectId, userId: userId);
    await _membersCollection.doc(id).delete();
  }
}
