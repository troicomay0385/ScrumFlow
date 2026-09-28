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
      expect(fromMapStory.tags, isEmpty);
      expect(fromMapStory.dueDate, isNull);
    });

    test('toMap and fromMap preserve tags and dueDate', () {
      final now = DateTime.now();
      final deadline = now.add(const Duration(days: 3));
      final story = UserStoryModel(
        id: 'us_test_tags',
        projectId: 'project_123',
        storyKey: 'US-007',
        title: 'Tìm kiếm User Story',
        description: 'Mô tả tìm kiếm',
        priority: 'CAO',
        storyPoints: 5,
        status: 'To Do',
        tags: const ['#Search', '#Backlog'],
        dueDate: deadline,
        createdAt: now,
        updatedAt: now,
      );

      final map = story.toMap();
      final fromMapStory = UserStoryModel.fromMap(map, 'us_test_tags');

      expect(fromMapStory.tags, equals(['#Search', '#Backlog']));
      expect(fromMapStory.dueDate?.day, equals(deadline.day));
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
      expect(story.tags, isEmpty);
      expect(story.dueDate, isNull);
      expect(story.assigneeName, isNull);
    });
  });
}
