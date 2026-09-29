import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/data/models/user_story_model.dart';

void main() {
  group('UserStoryModel', () {
    test('toMap and fromMap work symmetrically', () {
      final now = DateTime.now();
      final story = UserStoryModel(
        id: 'us_test_1',
        projectId: 'project_123',
        storyKey: 'US-005',
        title: 'Xem danh sách Backlog',
        description: 'Mô tả chi tiết',
        priority: 'CAO',
        storyPoints: 5,
        status: 'In Progress',
        assigneeId: 'mock_u1',
        assigneeName: 'Lê Phúc',
        assigneeEmail: 'phuc.po@scrumflow.com',
        createdAt: now,
        updatedAt: now,
      );

      final map = story.toMap();
      final fromMapStory = UserStoryModel.fromMap(map, 'us_test_1');

      expect(fromMapStory.id, equals('us_test_1'));
      expect(fromMapStory.storyKey, equals('US-005'));
      expect(fromMapStory.title, equals('Xem danh sách Backlog'));
      expect(fromMapStory.priority, equals('CAO'));
      expect(fromMapStory.storyPoints, equals(5));
      expect(fromMapStory.status, equals('In Progress'));
      expect(fromMapStory.assigneeName, equals('Lê Phúc'));
      expect(fromMapStory.assigneeEmail, equals('phuc.po@scrumflow.com'));
    });

    test('fromMap handles missing/null optional fields gracefully', () {
      final map = <String, dynamic>{
        'storyKey': 'US-006',
        'title': 'Chi tiết User Story',
      };

      final story = UserStoryModel.fromMap(map, 'us_test_2');

      expect(story.id, equals('us_test_2'));
      expect(story.storyKey, equals('US-006'));
      expect(story.title, equals('Chi tiết User Story'));
      expect(story.priority, equals('CAO'));
      expect(story.storyPoints, equals(3));
      expect(story.status, equals('To Do'));
      expect(story.assigneeName, isNull);
    });

    test('dữ liệu cũ không có tags/deadline/createdBy vẫn parse được', () {
      final story = UserStoryModel.fromMap(const {
        'storyKey': 'US-001',
        'title': 'Story cũ',
        'priority': 'TB',
      }, 'old');

      expect(story.tags, isEmpty);
      expect(story.deadline, isNull);
      expect(story.createdBy, isNull);
    });

    test('tags sai kiểu hoặc chứa phần tử không phải String được xử lý an toàn', () {
      expect(UserStoryModel.fromMap(const {'tags': 'Frontend'}).tags, isEmpty);
      expect(
        UserStoryModel.fromMap(const {
          'tags': ['Frontend', 42, null, 'UI'],
        }).tags,
        ['Frontend', 'UI'],
      );
    });

    test('tags, deadline, createdBy round-trip qua toMap/fromMap', () {
      final deadline = DateTime(2026, 10, 5);
      final story = UserStoryModel(
        id: 's1',
        projectId: 'p1',
        storyKey: 'US-057',
        title: 'Đăng nhập Google',
        description: '',
        tags: const ['Authentication', 'Frontend'],
        deadline: deadline,
        createdBy: 'uid-po',
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );

      final parsed = UserStoryModel.fromMap(story.toMap(), 's1');

      expect(parsed.tags, ['Authentication', 'Frontend']);
      expect(parsed.deadline, deadline);
      expect(parsed.createdBy, 'uid-po');
    });

    test('toMap không ghi createdBy khi null (dữ liệu mẫu qua được Rules)', () {
      final story = UserStoryModel(
        id: 'mock_us_001',
        projectId: 'p1',
        storyKey: 'US-001',
        title: 'Story mẫu',
        description: '',
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );
      expect(story.toMap().containsKey('createdBy'), isFalse);
    });

    test('copyWith(tags) giữ nguyên toàn bộ field khác', () {
      final story = UserStoryModel(
        id: 's1',
        projectId: 'p1',
        storyKey: 'US-010',
        title: 'Tạo story',
        description: 'Mô tả',
        priority: 'TB',
        storyPoints: 5,
        status: 'In Progress',
        deadline: DateTime(2026, 10, 1),
        createdBy: 'uid-po',
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );

      final updated = story.copyWith(tags: const ['Backlog']);

      expect(updated.tags, ['Backlog']);
      expect(updated, story.copyWith(tags: const ['Backlog']));
      expect(updated.title, story.title);
      expect(updated.priority, story.priority);
      expect(updated.status, story.status);
      expect(updated.storyPoints, story.storyPoints);
      expect(updated.deadline, story.deadline);
      expect(updated.createdBy, story.createdBy);
    });
  });
}
