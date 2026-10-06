import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Đối tượng được bình luận: 1 User Story (US-045) hoặc 1 Task (US-046).
///
/// Quyết định nơi lưu bình luận trên Firestore nên bình luận của story và
/// task không bao giờ lẫn vào nhau:
/// - Story: `projects/{projectId}/userStories/{storyId}/comments`
/// - Task:  `tasks/{taskId}/comments`
class CommentTarget extends Equatable {
  final String projectId;
  final String? storyId;
  final String? taskId;

  const CommentTarget.story({
    required this.projectId,
    required String this.storyId,
  }) : taskId = null;

  const CommentTarget.task({
    required this.projectId,
    required String this.taskId,
  }) : storyId = null;

  bool get isTask => taskId != null;

  @override
  List<Object?> get props => [projectId, storyId, taskId];
}

/// 1 bình luận trong User Story hoặc Task.
class CommentModel extends Equatable {
  final String id;
  final String projectId;

  /// Chỉ một trong hai có giá trị — tham chiếu về đối tượng được bình luận.
  final String? storyId;
  final String? taskId;

  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.projectId,
    this.storyId,
    this.taskId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      if (storyId != null) 'storyId': storyId,
      if (taskId != null) 'taskId': taskId,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    // `createdAt` là server timestamp: bình luận vừa gửi (chưa được server
    // xác nhận) tạm thời là null → coi như "vừa xong".
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return CommentModel(
      id: id,
      projectId: map['projectId'] as String? ?? '',
      storyId: map['storyId'] as String?,
      taskId: map['taskId'] as String?,
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }

  @override
  List<Object?> get props =>
      [id, projectId, storyId, taskId, authorId, authorName, content, createdAt];
}
