import 'package:equatable/equatable.dart';

import '../../app/authorization/project_role.dart';

/// Model đại diện cho 1 document trong collection `projectMembers`.
///
/// Doc ID = `'${projectId}_${userId}'` (xem [membershipIdFor]) — cố định
/// theo cặp (projectId, userId) để:
/// - Ngăn 1 user có 2 membership trùng nhau trong cùng 1 project.
/// - Firestore Security Rules kiểm tra quyền bằng `get()`/`exists()`
///   trực tiếp mà không cần query.
class ProjectMemberModel extends Equatable {
  final String id;
  final String projectId;
  final String userId;
  final ProjectRole role;

  /// `true` nếu giá trị `role` thô trong Firestore không hợp lệ
  /// (đã fallback về [ProjectRole.member] — quyền thấp nhất) — dùng để
  /// UI có thể cảnh báo thay vì âm thầm coi như dữ liệu bình thường.
  final bool hasInvalidRole;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectMemberModel({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.role,
    this.hasInvalidRole = false,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  static String membershipIdFor({
    required String projectId,
    required String userId,
  }) =>
      '${projectId}_$userId';

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'userId': userId,
      'role': role.toFirestoreValue(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProjectMemberModel.fromMap(String id, Map<String, dynamic> map) {
    final parsedRole = ProjectRole.fromFirestoreValue(map['role'] as String?);
    return ProjectMemberModel(
      id: id,
      projectId: map['projectId'] as String,
      userId: map['userId'] as String,
      role: parsedRole ?? ProjectRole.member,
      hasInvalidRole: parsedRole == null,
      createdBy: map['createdBy'] as String? ?? map['userId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, projectId, userId, role, createdBy, createdAt, updatedAt];
}
