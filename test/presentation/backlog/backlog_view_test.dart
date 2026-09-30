import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/presentation/backlog/utils/backlog_view.dart';

UserStoryModel story(
  String key, {
  String priority = 'TB',
  String status = 'To Do',
  DateTime? deadline,
}) {
  return UserStoryModel(
    id: key,
    projectId: 'p1',
    storyKey: key,
    title: 'Story $key',
    description: '',
    priority: priority,
    status: status,
    deadline: deadline,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );
}

List<String> keys(List<UserStoryModel> stories) =>
    stories.map((s) => s.storyKey).toList();

void main() {
  group('applyBacklogView — sort ưu tiên (US-009)', () {
    test('sắp xếp CAO → TB → THẤP theo nghiệp vụ, không theo alphabet', () {
      final stories = [
        story('US-001', priority: 'THẤP'),
        story('US-002', priority: 'CAO'),
        story('US-003', priority: 'TB'),
        story('US-004', priority: 'CAO'),
      ];

      final result =
          applyBacklogView(stories, sortOption: BacklogSortOption.priority);

      // Cùng ưu tiên giữ nguyên thứ tự gốc (sort ổn định).
      expect(keys(result), ['US-002', 'US-004', 'US-003', 'US-001']);
    });

    test('priority lạ (dữ liệu hỏng) xếp cuối, không crash', () {
      final result = applyBacklogView(
        [story('US-001', priority: '???'), story('US-002', priority: 'THẤP')],
        sortOption: BacklogSortOption.priority,
      );
      expect(keys(result), ['US-002', 'US-001']);
    });
  });

  group('applyBacklogView — sort deadline (US-009)', () {
    test('deadline gần nhất trước, story không có deadline xếp cuối', () {
      final stories = [
        story('US-001', deadline: DateTime(2026, 10, 20)),
        story('US-002'),
        story('US-003', deadline: DateTime(2026, 10, 1)),
        story('US-004', deadline: DateTime(2026, 10, 5)),
      ];

      final result =
          applyBacklogView(stories, sortOption: BacklogSortOption.deadline);

      expect(keys(result), ['US-003', 'US-004', 'US-001', 'US-002']);
    });

    test('toàn bộ story không có deadline → không crash, xếp phụ theo ưu tiên',
        () {
      final result = applyBacklogView(
        [
          story('US-001', priority: 'THẤP'),
          story('US-002', priority: 'CAO'),
        ],
        sortOption: BacklogSortOption.deadline,
      );
      expect(keys(result), ['US-002', 'US-001']);
    });
  });

  group('applyBacklogView — tính toàn vẹn', () {
    final stories = [
      story('US-001', priority: 'THẤP', status: 'Done'),
      story('US-002', priority: 'CAO', deadline: DateTime(2026, 10, 9)),
      story('US-003', priority: 'TB', status: 'Done', deadline: DateTime(2026, 10, 2)),
      story('US-004', priority: 'CAO'),
    ];

    test('sort không làm mất/nhân đôi story và không sửa list gốc', () {
      final original = List.of(stories);
      for (final option in BacklogSortOption.values) {
        final result = applyBacklogView(stories, sortOption: option);
        expect(result.length, stories.length);
        expect(result.toSet(), stories.toSet());
      }
      expect(stories, original);
    });

    test('mặc định giữ nguyên thứ tự gốc', () {
      expect(keys(applyBacklogView(stories)),
          ['US-001', 'US-002', 'US-003', 'US-004']);
    });

    test('filter + sort hoạt động cùng nhau', () {
      final result = applyBacklogView(
        stories,
        statusFilter: 'To Do',
        sortOption: BacklogSortOption.deadline,
      );
      expect(keys(result), ['US-002', 'US-004']);

      final done = applyBacklogView(
        stories,
        statusFilter: 'Done',
        sortOption: BacklogSortOption.priority,
      );
      expect(keys(done), ['US-003', 'US-001']);
    });
  });
}
