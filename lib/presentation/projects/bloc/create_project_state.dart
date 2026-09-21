import 'package:equatable/equatable.dart';

import '../../../data/models/project_model.dart';

abstract class CreateProjectState extends Equatable {
  const CreateProjectState();

  @override
  List<Object?> get props => [];
}

class CreateProjectIdle extends CreateProjectState {}

class CreateProjectSubmitting extends CreateProjectState {}

class CreateProjectSuccess extends CreateProjectState {
  final ProjectModel project;

  const CreateProjectSuccess(this.project);

  @override
  List<Object?> get props => [project];
}

class CreateProjectFailure extends CreateProjectState {
  final String message;

  const CreateProjectFailure(this.message);

  @override
  List<Object?> get props => [message];
}
