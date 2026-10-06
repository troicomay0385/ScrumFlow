import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/comment_model.dart';

/// DataSource bình luận trên Cloud Firestore (US-045, US-046).
///
/// Bình luận nằm trong subcollection `comments` của chính User Story /
/// Task được bình luận — xem [CommentTarget].
class CommentDataSource {
  final FirebaseFirestore _firestore;

  CommentDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _commentsRef(CommentTarget target) {
    final parent = target.isTask
        ? _firestore.collection('tasks').doc(target.taskId)
        : _firestore
            .collection('projects')
            .doc(target.projectId)
            .collection('userStories')
            .doc(target.storyId);
    return parent.collection('comments');
  }

  /// Stream real-time bình luận, cũ → mới.
  Stream<List<CommentModel>> streamComments(CommentTarget target) {
    return _commentsRef(target).orderBy('createdAt').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Thêm 1 bình luận. `createdAt` do server gán nên client không giả
  /// mạo được thời gian. Lỗi được throw lên Repository xử lý.
  Future<void> addComment(CommentTarget target, CommentModel comment) async {
    await _commentsRef(target).add({
      ...comment.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 15));
  }
}
