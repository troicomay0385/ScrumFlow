import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/data/repositories/backlog_repository.dart';
import 'package:scrumflow/presentation/backlog/bloc/backlog_bloc.dart';
import 'package:scrumflow/presentation/backlog/bloc/backlog_event.dart';
import 'package:scrumflow/presentation/backlog/bloc/backlog_state.dart';
import 'package:scrumflow/presentation/backlog/utils/backlog_view.dart';

class MockBacklogRepository extends Mock implements BacklogRepository {}

void main() {
  final sampleStories = [
    UserStoryModel(
      id: '1',
      projectId: 'p1',
      storyKey: 'US-001',
      title: 'Đăng nhập Firebase',
      description: 'Cho phép đăng nhập bằng email',
      priority: 'CAO',
      status: 'To Do',
      tags: const ['Auth', 'Backend'],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    UserStoryModel(
      id: '2',
      projectId: 'p1',
      storyKey: 'US-002',
      title: 'Thiết kế Dashboard',
      description: 'Giao diện tổng quan cho Scrum Master',
      priority: 'TB',
      status: 'In Progress',
      tags: const ['UI', 'Frontend'],
      createdAt: DateTime(2026, 1, 2),
      updatedAt: DateTime(2026, 1, 2),
    ),
    UserStoryModel(
      id: '3',
      projectId: 'p1',
      storyKey: 'US-003',
      title: 'Tối ưu hiệu năng',
      description: 'Giảm thời gian load',
      priority: 'THẤP',
      status: 'Done',
      tags: const ['Performance'],
      createdAt: DateTime(2026, 1, 3),
      updatedAt: DateTime(2026, 1, 3),
    ),
  ];

  group('applyBacklogView Logic (US-007, US-008)', () {
    test('US-007: Tìm kiếm theo tiêu đề không phân biệt hoa thường', () {
      final result = applyBacklogView(sampleStories, searchQuery: 'đăng nhập');
      expect(result.length, 1);
      expect(result.first.storyKey, 'US-001');
    });

    test('US-007: Tìm kiếm theo mã storyKey', () {
      final result = applyBacklogView(sampleStories, searchQuery: 'US-002');
      expect(result.length, 1);
      expect(result.first.storyKey, 'US-002');
    });

    test('US-007: Tìm kiếm theo tag', () {
      final result = applyBacklogView(sampleStories, searchQuery: 'Backend');
      expect(result.length, 1);
      expect(result.first.storyKey, 'US-001');
    });

    test('US-008: Lọc theo Mức ưu tiên (Priority CAO/TB/THẤP)', () {
      final result = applyBacklogView(sampleStories, priorityFilter: 'TB');
      expect(result.length, 1);
      expect(result.first.storyKey, 'US-002');
    });

    test('US-008: Lọc theo Tag', () {
      final result = applyBacklogView(sampleStories, tagFilter: 'Performance');
      expect(result.length, 1);
      expect(result.first.storyKey, 'US-003');
    });

    test('US-008: Kết hợp nhiều tiêu chí (Search + Status + Priority)', () {
      final result = applyBacklogView(
        sampleStories,
        searchQuery: 'Dashboard',
        statusFilter: 'In Progress',
        priorityFilter: 'TB',
      );
      expect(result.length, 1);
      expect(result.first.storyKey, 'US-002');
    });
  });

  group('BacklogBloc Search & Filter Events (US-007, US-008)', () {
    late MockBacklogRepository repository;

    setUp(() {
      repository = MockBacklogRepository();
      when(() => repository.streamUserStories('p1'))
          .thenAnswer((_) => Stream.value(sampleStories));
    });

    test('BacklogSearchChanged và BacklogPriorityFilterChanged cập nhật state chính xác',
        () async {
      final bloc = BacklogBloc(repository: repository);
      bloc.add(const BacklogSubscriptionRequested('p1'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BacklogLoading>(),
          isA<BacklogLoaded>(),
        ]),
      );

      // Thay đổi tìm kiếm
      bloc.add(const BacklogSearchChanged('Dashboard'));
      await expectLater(
        bloc.stream,
        emits(predicate<BacklogLoaded>((s) {
          return s.searchQuery == 'Dashboard' &&
              s.visibleStories.length == 1 &&
              s.visibleStories.first.storyKey == 'US-002';
        })),
      );

      // Thay đổi priority filter
      bloc.add(const BacklogPriorityFilterChanged('CAO'));
      await expectLater(
        bloc.stream,
        emits(predicate<BacklogLoaded>((s) {
          return s.priorityFilter == 'CAO' && s.visibleStories.isEmpty;
        })),
      );

      // Reset filter
      bloc.add(const BacklogFilterResetRequested());
      await expectLater(
        bloc.stream,
        emits(predicate<BacklogLoaded>((s) {
          return s.searchQuery == '' &&
              s.priorityFilter == null &&
              s.statusFilter == null &&
              s.tagFilter == null &&
              s.visibleStories.length == 3;
        })),
      );

      await bloc.close();
    });
  });
}
