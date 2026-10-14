import 'package:equatable/equatable.dart';

abstract class ProjectListEvent extends Equatable {
  const ProjectListEvent();

  @override
  List<Object?> get props => [];
}

/// Tải (hoặc tải lại) danh sách project của user hiện tại.
class ProjectListRequested extends ProjectListEvent {}

/// Xoá project (US-038). Chỉ PO được phép gọi.
class ProjectDeleteRequested extends ProjectListEvent {
  final String projectId;

  const ProjectDeleteRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}
