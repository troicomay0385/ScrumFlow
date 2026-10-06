import 'package:equatable/equatable.dart';

import '../../../data/models/comment_model.dart';

enum CommentsStatus { loading, loaded, failure }

/// State khu vực bình luận của 1 User Story / Task (US-045, US-046).
class CommentsState extends Equatable {
  final CommentsStatus status;
  final List<CommentModel> comments;

  /// Lỗi khi tải danh sách bình luận.
  final String? loadError;

  final bool isSending;

  /// Lỗi khi gửi bình luận (nội dung rỗng, không có quyền, mất mạng...).
  final String? sendError;

  const CommentsState({
    this.status = CommentsStatus.loading,
    this.comments = const [],
    this.loadError,
    this.isSending = false,
    this.sendError,
  });

  CommentsState copyWith({
    CommentsStatus? status,
    List<CommentModel>? comments,
    String? loadError,
    bool? isSending,
    String? sendError,
  }) {
    return CommentsState(
      status: status ?? this.status,
      comments: comments ?? this.comments,
      loadError: loadError,
      isSending: isSending ?? this.isSending,
      sendError: sendError,
    );
  }

  @override
  List<Object?> get props =>
      [status, comments, loadError, isSending, sendError];
}
