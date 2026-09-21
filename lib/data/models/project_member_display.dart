import 'package:equatable/equatable.dart';

import 'project_member_model.dart';
import 'user_model.dart';

/// Kết hợp [ProjectMemberModel] (role/membership) với [UserModel]
/// (avatar/tên/email) để hiển thị trong màn hình Quản lý thành viên.
///
/// Tách riêng khỏi [ProjectMemberModel] vì đây là dữ liệu ghép cho
/// mục đích hiển thị (UI-facing), không phải shape lưu trong Firestore.
class ProjectMemberDisplay extends Equatable {
  final ProjectMemberModel membership;
  final UserModel? user;

  const ProjectMemberDisplay({required this.membership, required this.user});

  String get userId => membership.userId;

  @override
  List<Object?> get props => [membership, user];
}
