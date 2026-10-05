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

UserStoryModel story(String key, String priority, {String status = 'To Do'}) {
  return UserStoryModel(
    id: key,
    projectId: 'p1',
    storyKey: key,
    title: key,
    description: '',
    priority: priority,
    status: status,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );
}

void main() {
  const projectId = 'p1';
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

  blocTest<BacklogBloc, BacklogState>(
    'xóa hàng loạt User Stories gọi repository deleteUserStories (US-053)',
    build: () {
      when(() => repository.deleteUserStories(
            projectId: projectId,
            storyIds: ['US-001', 'US-002'],
          )).thenAnswer((_) async {});
      return BacklogBloc(repository: repository);
    },
    act: (bloc) => bloc.add(const BacklogDeleteStoriesRequested(
      projectId: projectId,
      storyIds: ['US-001', 'US-002'],
    )),
    verify: (_) {
      verify(() => repository.deleteUserStories(
            projectId: projectId,
            storyIds: ['US-001', 'US-002'],
          )).called(1);
    },
  );
}
