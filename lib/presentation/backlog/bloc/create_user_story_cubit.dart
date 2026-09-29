import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/utils/user_story_validator.dart';
import '../../../data/repositories/backlog_repository.dart';
import 'create_user_story_state.dart';

/// Cubit cho form Tạo User Story (US-010) — 1 hành động duy nhất nên dùng
/// Cubit giống `CreateProjectCubit`.
///
/// Sau khi tạo thành công KHÔNG cần tự refresh danh sách: `BacklogBloc`
/// đang lắng nghe stream Firestore nên story mới tự xuất hiện.
class CreateUserStoryCubit extends Cubit<CreateUserStoryState> {
  final BacklogRepository _repository;
  final String _projectId;

  CreateUserStoryCubit(this._repository, this._projectId)
      : super(CreateUserStoryIdle());

  Future<void> submit({
    required String title,
    required String description,
    required String? priority,
    DateTime? deadline,
  }) async {
    // Chống bấm lặp: đang gửi hoặc đã tạo xong thì bỏ qua mọi lần submit
    // tiếp theo → không bao giờ tạo 2 document cho cùng 1 lần nhập.
    if (state is CreateUserStorySubmitting || state is CreateUserStorySuccess) {
      return;
    }

    final validationError = UserStoryValidator.validateTitle(title) ??
        UserStoryValidator.validateDescription(description) ??
        UserStoryValidator.validatePriority(priority);
    if (validationError != null) {
      emit(CreateUserStoryFailure(validationError));
      return;
    }

    emit(CreateUserStorySubmitting());
    try {
      final story = await _repository.createUserStory(
        projectId: _projectId,
        title: title,
        description: description,
        priority: priority!,
        deadline: deadline,
      );
      emit(CreateUserStorySuccess(story));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(CreateUserStoryFailure(
          message.isEmpty ? 'Không thể tạo User Story' : message));
    }
  }
}
