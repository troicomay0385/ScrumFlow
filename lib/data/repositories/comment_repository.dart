import '../models/comment_model.dart';

/// Interface cho Comment Repository — bình luận trong User Story (US-045)
/// và Task (US-046).
abstract class CommentRepository {
  /// Stream real-time bình luận của [target], cũ → mới.
  Stream<List<CommentModel>> streamComments(CommentTarget target);

  /// Gửi 1 bình luận với tư cách user đang đăng nhập.
  ///
  /// Throw `Exception` kèm thông báo tiếng Việt nếu nội dung rỗng/quá dài,
  /// chưa đăng nhập, không phải thành viên project hoặc Firestore lỗi.
  Future<void> addComment({
    required CommentTarget target,
    required String content,
  });
}
