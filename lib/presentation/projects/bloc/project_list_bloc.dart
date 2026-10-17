import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/errors/app_error_handler.dart';
import '../../../app/errors/app_failure.dart';
import '../../../app/services/connectivity_service.dart';
import '../../../data/repositories/project_repository.dart';
import 'project_list_event.dart';
import 'project_list_state.dart';

class ProjectListBloc extends Bloc<ProjectListEvent, ProjectListState> {
  /// Thời gian chờ tối đa cho 1 lần tải danh sách project (US-063).
  static const Duration defaultTimeout = Duration(seconds: 15);

  final ProjectRepository _projectRepository;
  final ConnectivityService? _connectivityService;
  final Duration _timeout;

  ProjectListBloc(
    this._projectRepository, {
    this._connectivityService,
    this._timeout = defaultTimeout,
  }) : super(ProjectListInitial()) {
    on<ProjectListRequested>(_onRequested);
    on<ProjectDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onRequested(
    ProjectListRequested event,
    Emitter<ProjectListState> emit,
  ) async {
    // Đang tải rồi (bấm "Thử lại"/kéo refresh liên tục) → bỏ qua để không
    // bắn nhiều request trùng lặp.
    if (state is ProjectListLoading) return;

    emit(ProjectListLoading());
    try {
      final connectivity = _connectivityService;
      if (connectivity != null && !await connectivity.isOnline()) {
        throw const AppFailure.noConnection();
      }
      final projects = await _projectRepository.getMyProjects().timeout(
        _timeout,
      );
      emit(ProjectListLoaded(projects));
    } catch (e) {
      final failure = AppErrorHandler.classify(e);
      emit(ProjectListError(failure.message, failureType: failure.type));
    }
  }

  Future<void> _onDeleteRequested(
    ProjectDeleteRequested event,
    Emitter<ProjectListState> emit,
  ) async {
    try {
      await _projectRepository.deleteProject(event.projectId);
      // Tải lại danh sách sau khi xoá thành công
      add(ProjectListRequested());
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(ProjectListError(
          message.isEmpty ? 'Không thể xoá project' : message));
    }
  }
}
