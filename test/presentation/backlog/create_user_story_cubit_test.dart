import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/data/repositories/backlog_repository.dart';
import 'package:scrumflow/presentation/backlog/bloc/create_user_story_cubit.dart';
import 'package:scrumflow/presentation/backlog/bloc/create_user_story_state.dart';

class MockBacklogRepository extends Mock implements BacklogRepository {}

void main() {
  const projectId = 'project-1';
  late MockBacklogRepository repository;

  final createdStory = UserStoryModel(
    id: 'doc-1',
    projectId: projectId,
    storyKey: 'US-057',
    title: 'Đăng nhập Google',
    description: 'Mô tả',
    priority: 'CAO',
    createdBy: 'uid-po',
    createdAt: DateTime(2026, 9, 29),
    updatedAt: DateTime(2026, 9, 29),
  );

  void stubCreate(Future<UserStoryModel> Function() answer) {
    when(() => repository.createUserStory(
          projectId: any(named: 'projectId'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          priority: any(named: 'priority'),
          deadline: any(named: 'deadline'),
        )).thenAnswer((_) => answer());
  }

  setUp(() => repository = MockBacklogRepository());

  blocTest<CreateUserStoryCubit, CreateUserStoryState>(
    'tạo thành công → Submitting → Success, gọi repository đúng tham số',
    build: () {
      stubCreate(() async => createdStory);
      return CreateUserStoryCubit(repository, projectId);
    },
    act: (cubit) => cubit.submit(
      title: 'Đăng nhập Google',
      description: 'Mô tả',
      priority: 'CAO',
      deadline: DateTime(2026, 10, 5),
    ),
    expect: () => [
      isA<CreateUserStorySubmitting>(),
      CreateUserStorySuccess(createdStory),
    ],
    verify: (_) {
      verify(() => repository.createUserStory(
            projectId: projectId,
            title: 'Đăng nhập Google',
            description: 'Mô tả',
            priority: 'CAO',
            deadline: DateTime(2026, 10, 5),
          )).called(1);
    },
  );

  blocTest<CreateUserStoryCubit, CreateUserStoryState>(
    'tiêu đề rỗng/chỉ khoảng trắng → Failure, KHÔNG gọi repository',
    build: () => CreateUserStoryCubit(repository, projectId),
    act: (cubit) =>
        cubit.submit(title: '   ', description: '', priority: 'CAO'),
    expect: () => [
      const CreateUserStoryFailure('Vui lòng nhập tiêu đề User Story'),
    ],
    verify: (_) => verifyNoMoreInteractions(repository),
  );

  blocTest<CreateUserStoryCubit, CreateUserStoryState>(
    'ưu tiên null hoặc không hợp lệ → Failure, KHÔNG gọi repository',
    build: () => CreateUserStoryCubit(repository, projectId),
    act: (cubit) async {
      await cubit.submit(title: 'A', description: '', priority: null);
      await cubit.submit(title: 'A', description: '', priority: 'HIGH');
    },
    expect: () => [
      const CreateUserStoryFailure('Vui lòng chọn độ ưu tiên hợp lệ'),
    ],
    verify: (_) => verifyNoMoreInteractions(repository),
  );

  blocTest<CreateUserStoryCubit, CreateUserStoryState>(
    'lỗi từ repository (vd. permission-denied) → Failure với thông báo dễ hiểu',
    build: () {
      stubCreate(() async => throw Exception(
          'Chỉ Product Owner hoặc Scrum Master mới được chỉnh sửa Product Backlog.'));
      return CreateUserStoryCubit(repository, projectId);
    },
    act: (cubit) =>
        cubit.submit(title: 'Story', description: '', priority: 'TB'),
    expect: () => [
      isA<CreateUserStorySubmitting>(),
      const CreateUserStoryFailure(
          'Chỉ Product Owner hoặc Scrum Master mới được chỉnh sửa Product Backlog.'),
    ],
  );

  blocTest<CreateUserStoryCubit, CreateUserStoryState>(
    'bấm Tạo nhiều lần liên tiếp → repository chỉ được gọi 1 lần',
    build: () {
      final completer = Completer<UserStoryModel>();
      stubCreate(() => completer.future);
      Future<void>.delayed(const Duration(milliseconds: 10),
          () => completer.complete(createdStory));
      return CreateUserStoryCubit(repository, projectId);
    },
    act: (cubit) async {
      final first =
          cubit.submit(title: 'Story', description: '', priority: 'TB');
      unawaited(cubit.submit(title: 'Story', description: '', priority: 'TB'));
      unawaited(cubit.submit(title: 'Story', description: '', priority: 'TB'));
      await first;
      // Sau khi đã thành công cũng không tạo thêm.
      await cubit.submit(title: 'Story', description: '', priority: 'TB');
    },
    expect: () => [
      isA<CreateUserStorySubmitting>(),
      CreateUserStorySuccess(createdStory),
    ],
    verify: (_) {
      verify(() => repository.createUserStory(
            projectId: any(named: 'projectId'),
            title: any(named: 'title'),
            description: any(named: 'description'),
            priority: any(named: 'priority'),
            deadline: any(named: 'deadline'),
          )).called(1);
    },
  );
}
