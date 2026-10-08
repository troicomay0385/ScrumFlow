import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/data/repositories/backlog_repository.dart';
import 'package:scrumflow/presentation/backlog/bloc/delete_user_story_cubit.dart';
import 'package:scrumflow/presentation/backlog/bloc/delete_user_story_state.dart';

class MockBacklogRepository extends Mock implements BacklogRepository {}

void main() {
  late MockBacklogRepository repository;
  late DeleteUserStoryCubit cubit;

  setUp(() {
    repository = MockBacklogRepository();
    cubit = DeleteUserStoryCubit(repository, 'p1');
  });

  tearDown(() {
    cubit.close();
  });

  group('DeleteUserStoryCubit (US-012)', () {
    test('Khởi tạo ban đầu ở trạng thái DeleteUserStoryIdle', () {
      expect(cubit.state, isA<DeleteUserStoryIdle>());
    });

    test('Xóa thành công phát ra Deleting rồi Success', () async {
      when(() => repository.deleteUserStory(
            projectId: 'p1',
            storyId: 's1',
          )).thenAnswer((_) async {});

      final future = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<DeleteUserStoryDeleting>(),
          predicate<DeleteUserStorySuccess>((s) => s.storyId == 's1'),
        ]),
      );

      await cubit.deleteStory('s1');
      await future;

      verify(() => repository.deleteUserStory(
            projectId: 'p1',
            storyId: 's1',
          )).called(1);
    });

    test('Xóa thất bại phát ra Deleting rồi Failure kèm message', () async {
      when(() => repository.deleteUserStory(
            projectId: 'p1',
            storyId: 's1',
          )).thenThrow(Exception('Permission denied'));

      final future = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<DeleteUserStoryDeleting>(),
          predicate<DeleteUserStoryFailure>(
            (f) => f.message.contains('Permission denied'),
          ),
        ]),
      );

      await cubit.deleteStory('s1');
      await future;
    });
  });
}
