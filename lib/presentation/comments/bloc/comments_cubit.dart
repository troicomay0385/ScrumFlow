import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/utils/comment_validator.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/repositories/comment_repository.dart';
import 'comments_state.dart';

/// Cubit bình luận dùng chung cho User Story (US-045) và Task (US-046) —
/// [target] quyết định bình luận thuộc về story hay task nào.
class CommentsCubit extends Cubit<CommentsState> {
  final CommentRepository _repository;
  final CommentTarget target;
  StreamSubscription<List<CommentModel>>? _subscription;

  CommentsCubit(this._repository, {required this.target})
      : super(const CommentsState());

  /// Lắng nghe bình luận real-time (gọi lại để thử tải lại khi lỗi).
  Future<void> start() async {
    await _subscription?.cancel();
    emit(state.copyWith(status: CommentsStatus.loading));
    _subscription = _repository.streamComments(target).listen(
      (comments) {
        if (isClosed) return;
        emit(state.copyWith(
          status: CommentsStatus.loaded,
          comments: comments,
          sendError: state.sendError,
        ));
      },
      onError: (Object error) {
        if (isClosed) return;
        emit(state.copyWith(
          status: CommentsStatus.failure,
          loadError: _messageOf(error, 'Không thể tải bình luận'),
          sendError: state.sendError,
        ));
      },
    );
  }

  /// Gửi bình luận. Trả về `true` nếu gửi thành công (UI xoá ô nhập).
  Future<bool> send(String content) async {
    if (state.isSending) return false;

    final validationError = CommentValidator.validate(content);
    if (validationError != null) {
      emit(state.copyWith(
        loadError: state.loadError,
        sendError: validationError,
      ));
      return false;
    }

    emit(state.copyWith(loadError: state.loadError, isSending: true));
    try {
      await _repository.addComment(target: target, content: content.trim());
      if (isClosed) return true;
      emit(state.copyWith(loadError: state.loadError, isSending: false));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
        loadError: state.loadError,
        isSending: false,
        sendError: _messageOf(e, 'Không thể gửi bình luận'),
      ));
      return false;
    }
  }

  String _messageOf(Object error, String fallback) {
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.isEmpty ? fallback : message;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
