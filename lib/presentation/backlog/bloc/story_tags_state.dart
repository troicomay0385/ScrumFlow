import 'package:equatable/equatable.dart';

enum StoryTagsStatus { idle, saving, saved, failure }

/// State chỉnh sửa tag của 1 User Story (US-014).
///
/// [tags] là bản nháp đang chỉnh trên UI; [savedTags] là bản đã lưu trên
/// Firestore — khác nhau nghĩa là còn thay đổi chưa lưu ([isDirty]).
class StoryTagsState extends Equatable {
  final List<String> savedTags;
  final List<String> tags;
  final StoryTagsStatus status;
  final String? message;

  const StoryTagsState({
    required this.savedTags,
    required this.tags,
    this.status = StoryTagsStatus.idle,
    this.message,
  });

  bool get isSaving => status == StoryTagsStatus.saving;

  bool get isDirty {
    if (tags.length != savedTags.length) return true;
    for (var i = 0; i < tags.length; i++) {
      if (tags[i] != savedTags[i]) return true;
    }
    return false;
  }

  StoryTagsState copyWith({
    List<String>? savedTags,
    List<String>? tags,
    StoryTagsStatus? status,
    String? message,
  }) {
    return StoryTagsState(
      savedTags: savedTags ?? this.savedTags,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      message: message,
    );
  }

  @override
  List<Object?> get props => [savedTags, tags, status, message];
}
