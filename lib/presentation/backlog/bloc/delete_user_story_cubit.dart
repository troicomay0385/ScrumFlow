import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/backlog_repository.dart';
import 'delete_user_story_state.dart';

/// Cubit cho thao tác Xóa User Story (US-012).
///
/// Chống bấm lặp khi đang xóa. Sau khi xóa thành công, stream Firestore
/// và local cache sẽ tự động cập nhật danh sách Backlog trên các thiết bị.
class DeleteUserStoryCubit extends Cubit<DeleteUserStoryState> {
  final BacklogRepository _repository;
  final String _projectId;

  DeleteUserStoryCubit(this._repository, this._projectId)
      : super(DeleteUserStoryIdle());

  Future<void> deleteStory(String storyId) async {
    // Chống bấm lặp
    if (state is DeleteUserStoryDeleting || state is DeleteUserStorySuccess) {
      return;
    }

    emit(DeleteUserStoryDeleting());
    try {
      await _repository.deleteUserStory(
        projectId: _projectId,
        storyId: storyId,
      );
      emit(DeleteUserStorySuccess(storyId));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(DeleteUserStoryFailure(
        message.isEmpty ? 'Không thể xóa User Story' : message,
      ));
    }
  }
}
