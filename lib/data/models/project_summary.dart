import 'package:equatable/equatable.dart';

import '../../app/authorization/project_role.dart';
import 'project_model.dart';

/// Project + role của user hiện tại trong project đó.
///
/// Dùng cho màn hình "Project của tôi" — mỗi project hiển thị kèm
/// role để user biết ngay mình là PO/SM/Member mà không cần mở
/// project ra mới biết.
class ProjectSummary extends Equatable {
  final ProjectModel project;
  final ProjectRole myRole;

  const ProjectSummary({required this.project, required this.myRole});

  @override
  List<Object?> get props => [project, myRole];
}
