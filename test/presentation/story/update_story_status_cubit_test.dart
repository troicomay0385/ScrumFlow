import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/domain/usecases/story/update_story_status_usecase.dart';
import 'package:scrumflow/presentation/story/bloc/update_story_status_cubit.dart';

class MockUpdateStoryStatusUseCase extends Mock
    implements UpdateStoryStatusUseCase {}

void main() {
  late MockUpdateStoryStatusUseCase mockUseCase;
  late UpdateStoryStatusCubit cubit;

  setUp(() {
    mockUseCase = MockUpdateStoryStatusUseCase();
    cubit = UpdateStoryStatusCubit(useCase: mockUseCase);
  });

  tearDown(() {
    cubit.close();
  });

  group('UpdateStoryStatusCubit', () {
    test('trạng thái ban đầu là UpdateStoryStatusInitial', () {
      expect(cubit.state, equals(const UpdateStoryStatusInitial()));
    });

    blocTest<UpdateStoryStatusCubit, UpdateStoryStatusState>(
      'phát ra [Loading, Success] khi cập nhật trạng thái thành công',
      build: () {
        when(
          () => mockUseCase(
            projectId: 'proj-1',
            storyId: 'story-1',
            newStatus: 'Done',
          ),
        ).thenAnswer((_) async {});
        return cubit;
      },
      act: (c) => c.updateStatus(
        projectId: 'proj-1',
        storyId: 'story-1',
        newStatus: 'Done',
      ),
      expect: () => [
        const UpdateStoryStatusLoading(),
        const UpdateStoryStatusSuccess(newStatus: 'Done'),
      ],
    );

    blocTest<UpdateStoryStatusCubit, UpdateStoryStatusState>(
      'phát ra [Loading, Failure] khi không có quyền PO/SM',
      build: () {
        when(
          () => mockUseCase(
            projectId: 'proj-1',
            storyId: 'story-1',
            newStatus: 'Done',
          ),
        ).thenThrow(Exception('Chỉ PO/SM mới có quyền cập nhật trạng thái'));
        return cubit;
      },
      act: (c) => c.updateStatus(
        projectId: 'proj-1',
        storyId: 'story-1',
        newStatus: 'Done',
      ),
      expect: () => [
        const UpdateStoryStatusLoading(),
        const UpdateStoryStatusFailure('Chỉ PO/SM mới có quyền cập nhật trạng thái'),
      ],
    );

    test('reset() đưa trạng thái về Initial', () {
      cubit.emit(const UpdateStoryStatusSuccess(newStatus: 'Done'));
      expect(cubit.state, isA<UpdateStoryStatusSuccess>());

      cubit.reset();
      expect(cubit.state, equals(const UpdateStoryStatusInitial()));
    });
  });
}
