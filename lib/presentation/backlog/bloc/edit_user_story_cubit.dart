import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/utils/user_story_validator.dart';
import '../../../data/models/user_story_model.dart';
import '../../../data/repositories/backlog_repository.dart';
import 'edit_user_story_state.dart';

/// Cubit cho form Chỉnh sửa User Story (US-011) & Gán Story Points (US-013).
///
/// Tương tự [CreateUserStoryCubit]: 1 hành động duy nhất (submit) nên dùng
/// Cubit. Sau khi cập nhật thành công KHÔNG cần tự refresh danh sách:
/// `BacklogBloc` đang lắng nghe stream Firestore nên thay đổi tự xuất hiện.
class EditUserStoryCubit extends Cubit<EditUserStoryState> {
  final BacklogRepository _repository;
  final String _projectId;

  EditUserStoryCubit(this._repository, this._projectId)
      : super(EditUserStoryIdle());

  Future<void> submit({
    required UserStoryModel original,
    required String title,
    required String description,
    required String? priority,
    required int storyPoints,
    DateTime? deadline,
    String? assigneeId,
    String? assigneeName,
    String? assigneeEmail,
    bool clearAssignee = false,
  }) async {
    // Chống bấm lặp: đang gửi hoặc đã sửa xong thì bỏ qua.
    if (state is EditUserStorySubmitting || state is EditUserStorySuccess) {
      return;
    }

    final validationError = UserStoryValidator.validateTitle(title) ??
        UserStoryValidator.validateDescription(description) ??
        UserStoryValidator.validatePriority(priority);
    if (validationError != null) {
      emit(EditUserStoryFailure(validationError));
      return;
    }

    if (storyPoints < 1 || storyPoints > 100) {
      emit(const EditUserStoryFailure(
          'Story Points phải từ 1 đến 100.'));
      return;
    }

    emit(EditUserStorySubmitting());
    try {
      final updated = await _repository.updateUserStory(
        projectId: _projectId,
        storyId: original.id,
        title: title,
        description: description,
        priority: priority!,
        storyPoints: storyPoints,
        deadline: deadline,
        assigneeId: assigneeId,
        assigneeName: assigneeName,
        assigneeEmail: assigneeEmail,
        clearAssignee: clearAssignee,
      );
      emit(EditUserStorySuccess(updated));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(EditUserStoryFailure(
          message.isEmpty ? 'Không thể cập nhật User Story' : message));
    }
  }
}
