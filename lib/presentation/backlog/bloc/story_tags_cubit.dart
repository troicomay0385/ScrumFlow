import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/utils/user_story_validator.dart';
import '../../../data/repositories/backlog_repository.dart';
import 'story_tags_state.dart';

/// Cubit gắn/xoá tag cho 1 User Story (US-014).
///
/// Thêm/xoá chỉ sửa bản nháp trên UI; [save] mới ghi lên Firestore, và chỉ
/// ghi field `tags` (qua [BacklogRepository.updateTags]) nên không làm mất
/// các field khác của story.
class StoryTagsCubit extends Cubit<StoryTagsState> {
  final BacklogRepository _repository;
  final String projectId;
  final String storyId;

  StoryTagsCubit(
    this._repository, {
    required this.projectId,
    required this.storyId,
    required List<String> initialTags,
  }) : super(StoryTagsState(
          savedTags: List.unmodifiable(initialTags),
          tags: List.unmodifiable(initialTags),
        ));

  /// Thêm tag vào bản nháp. Trả về thông báo lỗi nếu tag không hợp lệ
  /// (rỗng, quá dài, trùng, vượt số lượng), `null` nếu thêm thành công.
  String? addTag(String rawTag) {
    if (state.isSaving) return null;
    final error = UserStoryValidator.validateNewTag(rawTag, state.tags);
    if (error != null) return error;

    final tag = UserStoryValidator.normalizeTag(rawTag);
    emit(state.copyWith(
      tags: List.unmodifiable([...state.tags, tag]),
      status: StoryTagsStatus.idle,
    ));
    return null;
  }

  void removeTag(String tag) {
    if (state.isSaving) return;
    emit(state.copyWith(
      tags: List.unmodifiable(state.tags.where((t) => t != tag)),
      status: StoryTagsStatus.idle,
    ));
  }

  /// Bỏ các thay đổi chưa lưu, quay về tag đã lưu.
  void discardChanges() {
    if (state.isSaving) return;
    emit(state.copyWith(tags: state.savedTags, status: StoryTagsStatus.idle));
  }

  Future<void> save() async {
    if (state.isSaving || !state.isDirty) return;

    final tagsToSave = state.tags;
    emit(state.copyWith(status: StoryTagsStatus.saving));
    try {
      await _repository.updateTags(
        projectId: projectId,
        storyId: storyId,
        tags: tagsToSave,
      );
      emit(state.copyWith(
        savedTags: tagsToSave,
        status: StoryTagsStatus.saved,
      ));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        status: StoryTagsStatus.failure,
        message: message.isEmpty ? 'Không thể lưu tag' : message,
      ));
    }
  }
}
