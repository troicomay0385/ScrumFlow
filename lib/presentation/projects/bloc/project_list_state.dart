import 'package:equatable/equatable.dart';

import '../../../app/errors/app_failure.dart';
import '../../../data/models/project_summary.dart';

abstract class ProjectListState extends Equatable {
  const ProjectListState();

  @override
  List<Object?> get props => [];
}

class ProjectListInitial extends ProjectListState {}

class ProjectListLoading extends ProjectListState {}

class ProjectListLoaded extends ProjectListState {
  final List<ProjectSummary> projects;

  const ProjectListLoaded(this.projects);

  @override
  List<Object?> get props => [projects];
}

class ProjectListError extends ProjectListState {
  final String message;

  /// Loại lỗi để UI chọn icon và quyết định có cho "Thử lại" (US-063).
  final AppFailureType failureType;

  const ProjectListError(
    this.message, {
    this.failureType = AppFailureType.unknown,
  });

  AppFailure get failure => AppFailure(failureType, message);

  @override
  List<Object?> get props => [message, failureType];
}
