import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/data/repositories/backlog_repository.dart';
import 'package:scrumflow/presentation/backlog/bloc/backlog_bloc.dart';
import 'package:scrumflow/presentation/backlog/bloc/backlog_event.dart';
import 'package:scrumflow/presentation/backlog/bloc/backlog_state.dart';
import 'package:scrumflow/presentation/backlog/utils/backlog_view.dart';

class MockBacklogRepository extends Mock implements BacklogRepository {}

UserStoryModel story(
  String key,
  String priority, {
  String status = 'To Do',
  DateTime? deadline,
}) {
  return UserStoryModel(
    id: key,
    projectId: 'p1',
    storyKey: key,
    title: key,
    description: '',
    priority: priority,
    status: status,
    deadline: deadline,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );
}

void main() {
  const projectId = 'p1';

  group('BacklogBloc — Origin/Main Tests', () {
    late MockBacklogRepository repository;
    late StreamController<List<UserStoryModel>> controller;

    final low = story('US-001', 'THẤP');
    final high = story('US-002', 'CAO');
    final highDone = story('US-003', 'CAO', status: 'Done');

    setUp(() {
      repository = MockBacklogRepository();
      controller = StreamController<List<UserStoryModel>>.broadcast();
      when(() => repository.streamUserStories(projectId))
          .thenAnswer((_) => controller.stream);
    });

    tearDown(() => controller.close());

    blocTest<BacklogBloc, BacklogState>(
      'đổi tiêu chí sort → visibleStories sắp xếp lại, stories gốc giữ nguyên',
      build: () => BacklogBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const BacklogSubscriptionRequested(projectId));
        await Future<void>.delayed(Duration.zero);
        controller.add([low, high]);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BacklogSortChanged(BacklogSortOption.priority));
      },
      expect: () => [
        isA<BacklogLoading>(),
        isA<BacklogLoaded>()
            .having((s) => s.visibleStories, 'visible', [low, high]),
        isA<BacklogLoaded>()
            .having((s) => s.sortOption, 'sort', BacklogSortOption.priority)
            .having((s) => s.visibleStories, 'visible', [high, low])
            .having((s) => s.stories, 'stories', [low, high]),
      ],
    );

    blocTest<BacklogBloc, BacklogState>(
      'stream đẩy dữ liệu mới (vd. vừa tạo story) vẫn giữ filter + sort đã chọn',
      build: () => BacklogBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const BacklogSubscriptionRequested(projectId));
        await Future<void>.delayed(Duration.zero);
        controller.add([low]);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BacklogSortChanged(BacklogSortOption.priority));
        bloc.add(const BacklogStatusFilterChanged('To Do'));
        await Future<void>.delayed(Duration.zero);
        controller.add([low, highDone, high]);
      },
      skip: 4,
      expect: () => [
        isA<BacklogLoaded>()
            .having((s) => s.sortOption, 'sort', BacklogSortOption.priority)
            .having((s) => s.statusFilter, 'filter', 'To Do')
            .having((s) => s.visibleStories, 'visible', [high, low])
            .having((s) => s.stories.length, 'total', 3),
      ],
    );

    blocTest<BacklogBloc, BacklogState>(
      'filter về "Tất cả" (null) hiển thị lại toàn bộ',
      build: () => BacklogBloc(repository: repository),
      seed: () => BacklogLoaded(
        stories: [low, highDone],
        statusFilter: 'Done',
      ),
      act: (bloc) => bloc.add(const BacklogStatusFilterChanged(null)),
      expect: () => [
        isA<BacklogLoaded>()
            .having((s) => s.statusFilter, 'filter', isNull)
            .having((s) => s.visibleStories, 'visible', [low, highDone]),
      ],
    );
  });

  group('BacklogBloc Filtering, Searching & Sorting (Duy US-007, US-008, US-009)', () {
    late MockBacklogRepository mockRepository;
    late StreamController<List<UserStoryModel>> controller;
    late List<UserStoryModel> sampleStories;
    final now = DateTime.now();

    setUp(() {
      mockRepository = MockBacklogRepository();
      controller = StreamController<List<UserStoryModel>>.broadcast();
      when(() => mockRepository.streamUserStories('p1'))
          .thenAnswer((_) => controller.stream);

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
          deadline: now.subtract(const Duration(days: 2)),
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
          deadline: now.add(const Duration(days: 1)),
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
          deadline: now.add(const Duration(days: 5)),
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
          deadline: null,
          assigneeName: 'Lê Phúc',
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    tearDown(() => controller.close());

    test('US-007: Search by keyword filters correctly', () async {
      final bloc = BacklogBloc(repository: mockRepository);
      bloc.add(const BacklogSubscriptionRequested('p1'));

      final expectFuture = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BacklogLoading>(),
          isA<BacklogLoaded>(),
          predicate<BacklogState>((s) =>
              s is BacklogLoaded &&
              s.filteredStories.length == 1 &&
              s.filteredStories.first.storyKey == 'US-056'),
          predicate<BacklogState>((s) =>
              s is BacklogLoaded &&
              s.filteredStories.length == 1 &&
              s.filteredStories.first.assigneeName == 'Trần Thúy'),
          predicate<BacklogState>((s) =>
              s is BacklogLoaded &&
              s.filteredStories.length == 1 &&
              s.filteredStories.first.storyKey == 'US-056'),
        ]),
      );

      await Future<void>.delayed(Duration.zero);
      controller.add(sampleStories);
      await Future<void>.delayed(Duration.zero);

      // Tìm theo StoryKey "056"
      bloc.add(const BacklogSearchChanged('056'));
      await Future<void>.delayed(Duration.zero);

      // Tìm theo Tên Assignee "Thúy"
      bloc.add(const BacklogSearchChanged('thúy'));
      await Future<void>.delayed(Duration.zero);

      // Tìm theo Tag "#Biometric"
      bloc.add(const BacklogSearchChanged('#biometric'));

      await expectFuture;
      await bloc.close();
    });

    test('US-008: Multi-criteria filtering (status, priority, tag)', () async {
      final bloc = BacklogBloc(repository: mockRepository);
      bloc.add(const BacklogSubscriptionRequested('p1'));

      final expectFuture = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BacklogLoading>(),
          isA<BacklogLoaded>(),
          predicate<BacklogState>((s) =>
              s is BacklogLoaded &&
              s.filteredStories.length == 2 &&
              s.filteredStories.every((item) => item.status == 'To Do')),
          predicate<BacklogState>((s) =>
              s is BacklogLoaded &&
              s.filteredStories.length == 1 &&
              s.filteredStories.first.storyKey == 'US-056'),
          predicate<BacklogState>(
              (s) => s is BacklogLoaded && s.filteredStories.length == 4),
        ]),
      );

      await Future<void>.delayed(Duration.zero);
      controller.add(sampleStories);
      await Future<void>.delayed(Duration.zero);

      // Lọc theo Status 'To Do' -> Mong đợi 2 stories (US-003, US-056)
      bloc.add(const BacklogStatusFilterChanged('To Do'));
      await Future<void>.delayed(Duration.zero);

      // Kết hợp lọc thêm Priority 'CAO' -> Chỉ còn 1 story (US-056)
      bloc.add(const BacklogPriorityFilterChanged('CAO'));
      await Future<void>.delayed(Duration.zero);

      // Đặt lại bộ lọc -> Trả về đủ 4 stories
      bloc.add(const BacklogFilterResetRequested());

      await expectFuture;
      await bloc.close();
    });

    test('US-009: Sorting backlog by various criteria', () async {
      final bloc = BacklogBloc(repository: mockRepository);
      bloc.add(const BacklogSubscriptionRequested('p1'));

      final expectFuture = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BacklogLoading>(),
          isA<BacklogLoaded>(),
          predicate<BacklogState>((s) {
            if (s is! BacklogLoaded) return false;
            final points = s.filteredStories.map((e) => e.storyPoints).toList();
            return points[0] == 8 && points[1] == 5 && points[2] == 3 && points[3] == 1;
          }),
          predicate<BacklogState>((s) {
            if (s is! BacklogLoaded) return false;
            return s.filteredStories.first.storyKey == 'US-001' &&
                s.filteredStories.last.storyKey == 'US-056';
          }),
          predicate<BacklogState>((s) {
            if (s is! BacklogLoaded) return false;
            final priorities = s.filteredStories.map((e) => e.priority).toList();
            return priorities.first == 'CAO' && priorities.last == 'THẤP';
          }),
        ]),
      );

      await Future<void>.delayed(Duration.zero);
      controller.add(sampleStories);
      await Future<void>.delayed(Duration.zero);

      // 1. Sắp xếp theo Story Points giảm dần
      bloc.add(const BacklogSortChanged(BacklogSortBy.pointsDesc));
      await Future<void>.delayed(Duration.zero);

      // 2. Sắp xếp theo Deadline gần nhất (dueDateAsc)
      bloc.add(const BacklogSortChanged(BacklogSortBy.dueDateAsc));
      await Future<void>.delayed(Duration.zero);

      // 3. Sắp xếp theo Độ ưu tiên giảm dần (CAO -> TB -> THẤP)
      bloc.add(const BacklogSortChanged(BacklogSortBy.priorityDesc));

      await expectFuture;
      await bloc.close();
    });
  });
}
