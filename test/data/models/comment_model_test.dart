import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/utils/comment_validator.dart';
import 'package:scrumflow/app/utils/date_formatter.dart';
import 'package:scrumflow/data/models/comment_model.dart';

void main() {
  group('CommentTarget', () {
    test('story và task là 2 đối tượng tách biệt', () {
      const story = CommentTarget.story(projectId: 'p1', storyId: 's1');
      const task = CommentTarget.task(projectId: 'p1', taskId: 't1');
      expect(story.isTask, isFalse);
      expect(story.storyId, 's1');
      expect(story.taskId, isNull);
      expect(task.isTask, isTrue);
      expect(task.taskId, 't1');
      expect(task.storyId, isNull);
      expect(story, isNot(task));
    });
  });

  group('CommentModel', () {
    final createdAt = DateTime(2026, 10, 6, 8, 30);

    test('toMap của comment story chỉ tham chiếu storyId', () {
      final map = CommentModel(
        id: 'c1',
        projectId: 'p1',
        storyId: 's1',
        authorId: 'u1',
        authorName: 'Phúc',
        content: 'Đã hoàn thành giao diện.',
        createdAt: createdAt,
      ).toMap();
      expect(map['projectId'], 'p1');
      expect(map['storyId'], 's1');
      expect(map.containsKey('taskId'), isFalse);
      expect(map['authorId'], 'u1');
      expect(map['createdAt'], Timestamp.fromDate(createdAt));
    });

    test('toMap của comment task chỉ tham chiếu taskId', () {
      final map = CommentModel(
        id: 'c1',
        projectId: 'p1',
        taskId: 't1',
        authorId: 'u1',
        authorName: 'Hiếu',
        content: 'Nhớ kiểm tra validation.',
        createdAt: createdAt,
      ).toMap();
      expect(map['taskId'], 't1');
      expect(map.containsKey('storyId'), isFalse);
    });

    test('fromMap đọc Timestamp; createdAt null (đang chờ server) không crash',
        () {
      final comment = CommentModel.fromMap({
        'projectId': 'p1',
        'taskId': 't1',
        'authorId': 'u1',
        'authorName': 'Hiếu',
        'content': 'Xong',
        'createdAt': Timestamp.fromDate(createdAt),
      }, 'c1');
      expect(comment.id, 'c1');
      expect(comment.createdAt, createdAt);
      expect(comment.taskId, 't1');

      final pending = CommentModel.fromMap({'content': 'x', 'createdAt': null}, 'c2');
      expect(pending.authorName, '');
      expect(pending.createdAt, isA<DateTime>());
    });
  });

  group('CommentValidator', () {
    test('từ chối bình luận rỗng / toàn khoảng trắng / quá dài', () {
      expect(CommentValidator.validate(null), isNotNull);
      expect(CommentValidator.validate(''), isNotNull);
      expect(CommentValidator.validate('   \n\t '), isNotNull);
      expect(CommentValidator.validate('x' * 1001), 'Bình luận tối đa 1000 ký tự');
    });

    test('chấp nhận bình luận hợp lệ', () {
      expect(CommentValidator.validate('Đã hoàn thành UI.'), isNull);
      expect(CommentValidator.validate('x' * 1000), isNull);
    });
  });

  group('formatRelativeTimeVi', () {
    final now = DateTime(2026, 10, 6, 12);

    test('hiển thị thời gian tương đối', () {
      String f(Duration ago) => formatRelativeTimeVi(now.subtract(ago), now: now);
      expect(f(const Duration(seconds: 20)), 'Vừa xong');
      expect(f(const Duration(minutes: 10)), '10 phút trước');
      expect(f(const Duration(hours: 3)), '3 giờ trước');
      expect(f(const Duration(days: 2)), '2 ngày trước');
      expect(f(const Duration(days: 30)), '06/09/2026');
    });
  });
}
