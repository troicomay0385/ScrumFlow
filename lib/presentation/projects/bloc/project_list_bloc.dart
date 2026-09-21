import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/project_repository.dart';
import 'project_list_event.dart';
import 'project_list_state.dart';

class ProjectListBloc extends Bloc<ProjectListEvent, ProjectListState> {
  final ProjectRepository _projectRepository;

  ProjectListBloc(this._projectRepository) : super(ProjectListInitial()) {
    on<ProjectListRequested>(_onRequested);
  }

  Future<void> _onRequested(
    ProjectListRequested event,
    Emitter<ProjectListState> emit,
  ) async {
    emit(ProjectListLoading());
    try {
      final projects = await _projectRepository.getMyProjects();
      emit(ProjectListLoaded(projects));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(ProjectListError(
          message.isEmpty ? 'Không thể tải danh sách project' : message));
    }
  }
}
