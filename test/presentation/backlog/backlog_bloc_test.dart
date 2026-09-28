import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/data/repositories/backlog_repository.dart';
import 'package:scrumflow/presentation/backlog/bloc/backlog_bloc.dart';
import 'package:scrumflow/presentation/backlog/bloc/backlog_event.dart';
import 'package:scrumflow/presentation/backlog/bloc/backlog_state.dart';

class MockBacklogRepository implements BacklogRepository {
  final _controller = StreamController<List<UserStoryModel>>.broadcast();
  List<UserStoryModel> stories = [];

  MockBacklogRepository(this.stories);

  @override
  Stream<List<UserStoryModel>> streamUserStories(String projectId) {
    Future.microtask(() => _controller.add(stories));
    return _controller.stream;
  }

  @override
  Future<List<UserStoryModel>> getUserStories(String projectId) async => stories;

  @override
  Future<UserStoryModel?> getUserStory(String projectId, String storyId) async {
    final found = stories.where((s) => s.id == storyId);
    return found.isNotEmpty ? found.first : null;
  }

  @override
  Future<void> saveUserStory(String projectId, UserStoryModel story) async {}

  @override
  Future<void> seedMockStories(String projectId) async {}

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('BacklogBloc Filtering, Searching & Sorting', () {
    late MockBacklogRepository mockRepository;
    late List<UserStoryModel> sampleStories;
    final now = DateTime.now();

    setUp(() {
      sampleStories = [
        UserStoryModel(
          id: '1',
          projectId: 'p1',
          storyKey: 'US-001',
          title: 'Đăng ký tài khoản',
          description: 'Người dùng đăng ký bằng email',
          priority: 'CAO',
          storyPoints: 3,
          status: 'Done',
          tags: const ['#Auth', '#Security'],
          dueDate: now.subtract(const Duration(days: 2)),
          assigneeName: 'Trần Thúy',
          createdAt: now,
          updatedAt: now,
        ),
        UserStoryModel(
          id: '2',
          projectId: 'p1',
          storyKey: 'US-002',
          title: 'Đăng nhập hệ thống',
          description: 'Đăng nhập tài khoản',
          priority: 'TB',
          storyPoints: 5,
          status: 'In Progress',
          tags: const ['#Auth'],
          dueDate: now.add(const Duration(days: 1)),
          assigneeName: 'Nguyễn Hiếu',
          createdAt: now,
          updatedAt: now,
        ),
        UserStoryModel(
          id: '3',
          projectId: 'p1',
          storyKey: 'US-003',
          title: 'Đăng xuất ứng dụng',
          description: 'Đăng xuất an toàn',
          priority: 'THẤP',
          storyPoints: 1,
          status: 'To Do',
          tags: const ['#Auth', '#UI'],
          dueDate: now.add(const Duration(days: 5)),
          assigneeName: 'Lê Phúc',
          createdAt: now,
          updatedAt: now,
        ),
        UserStoryModel(
          id: '4',
          projectId: 'p1',
          storyKey: 'US-056',
          title: 'Mở khóa vân tay sinh trắc học',
          description: 'Xác thực sinh trắc học',
          priority: 'CAO',
          storyPoints: 8,
          status: 'To Do',
          tags: const ['#Security', '#Biometric'],
          dueDate: null, // Không có deadline
          assigneeName: 'Lê Phúc',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      mockRepository = MockBacklogRepository(sampleStories);
    });

    test('US-007: Search by keyword filters correctly', () async {
      final bloc = BacklogBloc(repository: mockRepository);
      bloc.add(const BacklogSubscriptionRequested('p1'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BacklogLoading>(),
          isA<BacklogLoaded>(),
        ]),
      );

      // Tìm theo StoryKey "056"
      bloc.add(const BacklogSearchChanged('056'));
      await expectLater(
        bloc.stream,
        emits(predicate<BacklogState>((s) =>
            s is BacklogLoaded &&
            s.filteredStories.length == 1 &&
            s.filteredStories.first.storyKey == 'US-056')),
      );

      // Tìm theo Tên Assignee "Thúy"
      bloc.add(const BacklogSearchChanged('thúy'));
      await expectLater(
        bloc.stream,
        emits(predicate<BacklogState>((s) =>
            s is BacklogLoaded &&
            s.filteredStories.length == 1 &&
            s.filteredStories.first.assigneeName == 'Trần Thúy')),
      );

      // Tìm theo Tag "#Biometric"
      bloc.add(const BacklogSearchChanged('#biometric'));
      await expectLater(
        bloc.stream,
        emits(predicate<BacklogState>((s) =>
            s is BacklogLoaded &&
            s.filteredStories.length == 1 &&
            s.filteredStories.first.storyKey == 'US-056')),
      );

      await bloc.close();
    });

    test('US-008: Multi-criteria filtering (status, priority, tag)', () async {
      final bloc = BacklogBloc(repository: mockRepository);
      bloc.add(const BacklogSubscriptionRequested('p1'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BacklogLoading>(),
          isA<BacklogLoaded>(),
        ]),
      );

      // Lọc theo Status 'To Do' -> Mong đợi 2 stories (US-003, US-056)
      bloc.add(const BacklogStatusFilterChanged('To Do'));
      await expectLater(
        bloc.stream,
        emits(predicate<BacklogState>((s) =>
            s is BacklogLoaded &&
            s.filteredStories.length == 2 &&
            s.filteredStories.every((item) => item.status == 'To Do'))),
      );

      // Kết hợp lọc thêm Priority 'CAO' -> Chỉ còn 1 story (US-056)
      bloc.add(const BacklogPriorityFilterChanged('CAO'));
      await expectLater(
        bloc.stream,
        emits(predicate<BacklogState>((s) =>
            s is BacklogLoaded &&
            s.filteredStories.length == 1 &&
            s.filteredStories.first.storyKey == 'US-056')),
      );

      // Đặt lại bộ lọc -> Trả về đủ 4 stories
      bloc.add(const BacklogFilterResetRequested());
      await expectLater(
        bloc.stream,
        emits(predicate<BacklogState>(
            (s) => s is BacklogLoaded && s.filteredStories.length == 4)),
      );

      await bloc.close();
    });

    test('US-009: Sorting backlog by various criteria', () async {
      final bloc = BacklogBloc(repository: mockRepository);
      bloc.add(const BacklogSubscriptionRequested('p1'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BacklogLoading>(),
          isA<BacklogLoaded>(),
        ]),
      );

      // 1. Sắp xếp theo Story Points giảm dần
      bloc.add(const BacklogSortChanged(BacklogSortBy.pointsDesc));
      await expectLater(
        bloc.stream,
        emits(predicate<BacklogState>((s) {
          if (s is! BacklogLoaded) return false;
          final points = s.filteredStories.map((e) => e.storyPoints).toList();
          return points[0] == 8 && points[1] == 5 && points[2] == 3 && points[3] == 1;
        })),
      );

      // 2. Sắp xếp theo Deadline gần nhất (dueDateAsc)
      bloc.add(const BacklogSortChanged(BacklogSortBy.dueDateAsc));
      await expectLater(
        bloc.stream,
        emits(predicate<BacklogState>((s) {
          if (s is! BacklogLoaded) return false;
          // US-001 (quá hạn 2 ngày) -> US-002 (hạn 1 ngày) -> US-003 (hạn 5 ngày) -> US-056 (null ở cuối)
          return s.filteredStories.first.storyKey == 'US-001' &&
              s.filteredStories.last.storyKey == 'US-056';
        })),
      );

      // 3. Sắp xếp theo Độ ưu tiên giảm dần (CAO -> TB -> THẤP)
      bloc.add(const BacklogSortChanged(BacklogSortBy.priorityDesc));
      await expectLater(
        bloc.stream,
        emits(predicate<BacklogState>((s) {
          if (s is! BacklogLoaded) return false;
          final priorities = s.filteredStories.map((e) => e.priority).toList();
          return priorities.first == 'CAO' && priorities.last == 'THẤP';
        })),
      );

      await bloc.close();
    });
  });
}
