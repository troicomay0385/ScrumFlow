import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/data/repositories/backlog_repository.dart';
import 'package:scrumflow/presentation/backlog/bloc/delete_user_story_cubit.dart';
import 'package:scrumflow/presentation/backlog/bloc/delete_user_story_state.dart';

class MockBacklogRepository extends Mock implements BacklogRepository {}

void main() {
  const projectId = 'project-1';
  const storyId = 'story-123';
  late MockBacklogRepository repository;

  setUp(() => repository = MockBacklogRepository());

  blocTest<DeleteUserStoryCubit, DeleteUserStoryState>(
    'xóa thành công → Deleting → Success, gọi repository đúng tham số',
    build: () {
      when(() => repository.deleteUserStory(
            projectId: projectId,
            storyId: storyId,
          )).thenAnswer((_) async {});
      return DeleteUserStoryCubit(repository, projectId);
    },
    act: (cubit) => cubit.deleteStory(storyId),
    expect: () => [
      isA<DeleteUserStoryDeleting>(),
      const DeleteUserStorySuccess(storyId),
    ],
    verify: (_) {
      verify(() => repository.deleteUserStory(
            projectId: projectId,
            storyId: storyId,
          )).called(1);
    },
  );

  blocTest<DeleteUserStoryCubit, DeleteUserStoryState>(
    'lỗi từ repository (vd. không có quyền) → Failure với thông báo dễ hiểu',
    build: () {
      when(() => repository.deleteUserStory(
            projectId: projectId,
            storyId: storyId,
          )).thenThrow(Exception('Chỉ Product Owner hoặc Scrum Master mới được chỉnh sửa Product Backlog.'));
      return DeleteUserStoryCubit(repository, projectId);
    },
    act: (cubit) => cubit.deleteStory(storyId),
    expect: () => [
      isA<DeleteUserStoryDeleting>(),
      const DeleteUserStoryFailure('Chỉ Product Owner hoặc Scrum Master mới được chỉnh sửa Product Backlog.'),
    ],
  );

  blocTest<DeleteUserStoryCubit, DeleteUserStoryState>(
    'bấm Xóa nhiều lần liên tiếp → repository chỉ được gọi 1 lần (chống bấm lặp)',
    build: () {
      final completer = Completer<void>();
      when(() => repository.deleteUserStory(
            projectId: projectId,
            storyId: storyId,
          )).thenAnswer((_) => completer.future);
      return DeleteUserStoryCubit(repository, projectId);
    },
    act: (cubit) {
      cubit.deleteStory(storyId);
      cubit.deleteStory(storyId);
      cubit.deleteStory(storyId);
    },
    expect: () => [
      isA<DeleteUserStoryDeleting>(),
    ],
    verify: (_) {
      verify(() => repository.deleteUserStory(
            projectId: projectId,
            storyId: storyId,
          )).called(1);
    },
  );
}
