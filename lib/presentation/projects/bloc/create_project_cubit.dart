import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/project_repository.dart';
import 'create_project_state.dart';

/// Cubit riêng cho màn hình Tạo project — chỉ 1 hành động duy nhất nên
/// dùng Cubit (đơn giản hơn Bloc đầy đủ event/state như AuthBloc) thay vì
/// tạo thêm 1 bộ Event chỉ để có 1 event.
class CreateProjectCubit extends Cubit<CreateProjectState> {
  final ProjectRepository _projectRepository;

  CreateProjectCubit(this._projectRepository) : super(CreateProjectIdle());

  Future<void> submit({
    required String name,
    required String description,
  }) async {
    emit(CreateProjectSubmitting());
    try {
      final project = await _projectRepository.createProject(
        name: name,
        description: description,
      );
      emit(CreateProjectSuccess(project));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(CreateProjectFailure(
          message.isEmpty ? 'Không thể tạo project' : message));
    }
  }
}
